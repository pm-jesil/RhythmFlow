import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../audio_header_validator.dart';
import '../media_store_bridge.dart';

/// Why a trim failed.
class TrimException implements Exception {
  final String message;
  final bool unsupportedFormat;
  const TrimException(this.message, {this.unsupportedFormat = false});

  @override
  String toString() => 'TrimException: $message';
}

/// Result of a trim.
class TrimResult {
  final String path;
  final Duration duration;
  final String extension; // without dot
  const TrimResult({required this.path, required this.duration, required this.extension});
}

/// Cuts a section out of an audio file without re-encoding.
///
/// * MP3: cut on MPEG frame boundaries in pure Dart (lossless, ~26 ms
///   precision). The leading ID3 tag and the Xing/Info header are dropped so
///   players compute the right duration.
/// * WAV: PCM bytes are cut on sample boundaries in pure Dart.
/// * AAC family (m4a, aac, m4b, 3ga, mp4) on Android: MediaExtractor +
///   MediaMuxer (lossless) through the platform channel.
/// * Anything else (FLAC, WMA, OGG, ...): [TrimException] with
///   `unsupportedFormat: true`.
class AudioTrimmer {
  AudioTrimmer._();

  static const Set<String> nativeFormats = {'m4a', 'aac', 'm4b', '3ga', 'mp4', 'alac'};

  /// Test hook: forces the platform for the native path.
  static bool? isAndroidOverride;
  static bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;

  static bool canTrim(String path) {
    final ext = AudioHeaderValidator.extensionOf(path);
    return ext == 'mp3' || ext == 'wav' || (_isAndroid && nativeFormats.contains(ext));
  }

  /// Extension of the trimmed file for [inputPath].
  static String outputExtension(String inputPath) {
    final ext = AudioHeaderValidator.extensionOf(inputPath);
    if (ext == 'mp3' || ext == 'wav') return ext;
    return 'm4a';
  }

  static Future<TrimResult> trim({
    required String inputPath,
    required String outputPathWithoutExtension,
    required Duration start,
    required Duration end,
  }) async {
    if (end <= start) throw const TrimException('End must be after start');
    final ext = AudioHeaderValidator.extensionOf(inputPath);
    final out = '$outputPathWithoutExtension.${outputExtension(inputPath)}';
    switch (ext) {
      case 'mp3':
        final bytes = await File(inputPath).readAsBytes();
        final cut = Mp3Cutter.cut(bytes, start, end);
        await File(out).writeAsBytes(cut.bytes, flush: true);
        return TrimResult(path: out, duration: cut.duration, extension: 'mp3');
      case 'wav':
        final bytes = await File(inputPath).readAsBytes();
        final cut = WavCutter.cut(bytes, start, end);
        await File(out).writeAsBytes(cut.bytes, flush: true);
        return TrimResult(path: out, duration: cut.duration, extension: 'wav');
      default:
        if (_isAndroid && nativeFormats.contains(ext)) {
          try {
            final ms = await MediaStoreBridge.trimAudio(
              inputPath: inputPath,
              outputPath: out,
              startMs: start.inMilliseconds,
              endMs: end.inMilliseconds,
            );
            return TrimResult(path: out, duration: Duration(milliseconds: ms), extension: 'm4a');
          } on PlatformException catch (e) {
            throw TrimException(
              e.message ?? 'Could not cut this file',
              unsupportedFormat: e.code == 'unsupported',
            );
          }
        }
        throw TrimException(
          '.$ext files can\'t be trimmed yet (MP3, WAV and M4A are supported)',
          unsupportedFormat: true,
        );
    }
  }
}

class CutResult {
  final Uint8List bytes;
  final Duration duration;
  const CutResult(this.bytes, this.duration);
}

/// One parsed MPEG audio frame.
class Mp3Frame {
  final int offset;
  final int length;
  final int sampleRate;
  final int samples;
  const Mp3Frame(this.offset, this.length, this.sampleRate, this.samples);

  Duration get duration => Duration(microseconds: samples * 1000000 ~/ sampleRate);
}

/// Lossless MP3 cutting on frame boundaries.
class Mp3Cutter {
  Mp3Cutter._();

  static const _bitratesV1 = [
    [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448], // L1
    [0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384], // L2
    [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320], // L3
  ];
  static const _bitratesV2 = [
    [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256], // L1
    [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160], // L2/L3
  ];
  static const _sampleRates = {
    3: [44100, 48000, 32000], // MPEG 1
    2: [22050, 24000, 16000], // MPEG 2
    0: [11025, 12000, 8000], // MPEG 2.5
  };

  /// Parses the frame header at [i], or returns null.
  static Mp3Frame? frameAt(Uint8List b, int i) {
    if (i + 4 > b.length) return null;
    if (b[i] != 0xFF || (b[i + 1] & 0xE0) != 0xE0) return null;
    final version = (b[i + 1] >> 3) & 0x03; // 0=2.5, 1=reserved, 2=2, 3=1
    final layerBits = (b[i + 1] >> 1) & 0x03; // 1=L3, 2=L2, 3=L1
    if (version == 1 || layerBits == 0) return null;
    final layer = 4 - layerBits; // 1, 2, 3
    final bitrateIndex = (b[i + 2] >> 4) & 0x0F;
    final rateIndex = (b[i + 2] >> 2) & 0x03;
    if (bitrateIndex == 0 || bitrateIndex == 15 || rateIndex == 3) return null;
    final padding = (b[i + 2] >> 1) & 0x01;
    final sampleRate = _sampleRates[version]![rateIndex];
    final kbps = version == 3
        ? _bitratesV1[layer - 1][bitrateIndex]
        : _bitratesV2[layer == 1 ? 0 : 1][bitrateIndex];
    final bitrate = kbps * 1000;
    int length;
    int samples;
    if (layer == 1) {
      length = (12 * bitrate ~/ sampleRate + padding) * 4;
      samples = 384;
    } else if (layer == 2 || version == 3) {
      length = 144 * bitrate ~/ sampleRate + padding;
      samples = 1152;
    } else {
      length = 72 * bitrate ~/ sampleRate + padding; // MPEG2/2.5 Layer 3
      samples = 576;
    }
    if (length < 4) return null;
    return Mp3Frame(i, length, sampleRate, samples);
  }

  /// Size of a leading ID3v2 tag (0 when none).
  static int id3v2Size(Uint8List b) {
    if (b.length < 10 || b[0] != 0x49 || b[1] != 0x44 || b[2] != 0x33) return 0;
    final size = (b[6] & 0x7F) << 21 | (b[7] & 0x7F) << 14 | (b[8] & 0x7F) << 7 | (b[9] & 0x7F);
    final footer = (b[5] & 0x10) != 0 ? 10 : 0;
    return 10 + size + footer;
  }

  static bool _isVbrHeader(Uint8List b, Mp3Frame f) {
    final end = (f.offset + f.length).clamp(0, b.length);
    for (var i = f.offset + 4; i + 4 <= end && i < f.offset + 64; i++) {
      final a = String.fromCharCodes(b.sublist(i, i + 4));
      if (a == 'Xing' || a == 'Info' || a == 'VBRI') return true;
    }
    return false;
  }

  /// All audio frames (VBR info frame excluded).
  static List<Mp3Frame> frames(Uint8List b) {
    final result = <Mp3Frame>[];
    var i = id3v2Size(b);
    // Ignore a trailing ID3v1 tag.
    var limit = b.length;
    if (limit >= 128 && b[limit - 128] == 0x54 && b[limit - 127] == 0x41 && b[limit - 126] == 0x47) {
      limit -= 128;
    }
    var first = true;
    while (i + 4 <= limit) {
      final f = frameAt(b, i);
      if (f == null || i + f.length > limit) {
        i++; // resync on junk
        continue;
      }
      // When resyncing, require the next frame to be valid too, to avoid
      // false sync words inside audio data.
      if (result.isEmpty && i + f.length + 4 <= limit && frameAt(b, i + f.length) == null) {
        i++;
        continue;
      }
      if (!(first && _isVbrHeader(b, f))) result.add(f);
      first = false;
      i += f.length;
    }
    return result;
  }

  static Duration totalDuration(Uint8List b) =>
      frames(b).fold(Duration.zero, (d, f) => d + f.duration);

  /// Frames whose start time is in [start, end).
  static CutResult cut(Uint8List bytes, Duration start, Duration end) {
    final all = frames(bytes);
    if (all.isEmpty) throw const TrimException('Not a valid MP3 file');
    final builder = BytesBuilder(copy: false);
    var t = Duration.zero;
    var kept = Duration.zero;
    for (final f in all) {
      if (t >= start && t < end) {
        builder.add(Uint8List.sublistView(bytes, f.offset, f.offset + f.length));
        kept += f.duration;
      }
      t += f.duration;
      if (t >= end) break;
    }
    if (kept == Duration.zero) throw const TrimException('The selection is outside the song');
    return CutResult(builder.toBytes(), kept);
  }
}

/// PCM WAV cutting on sample boundaries.
class WavCutter {
  WavCutter._();

  static CutResult cut(Uint8List b, Duration start, Duration end) {
    final data = ByteData.sublistView(b);
    if (b.length < 44 ||
        String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
      throw const TrimException('Not a valid WAV file');
    }
    Uint8List? fmt;
    int? dataOffset;
    int? dataSize;
    var i = 12;
    while (i + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(i, i + 4));
      final size = data.getUint32(i + 4, Endian.little);
      if (id == 'fmt ') fmt = Uint8List.fromList(b.sublist(i + 8, i + 8 + size));
      if (id == 'data') {
        dataOffset = i + 8;
        dataSize = size.clamp(0, b.length - dataOffset);
        break;
      }
      i += 8 + size + (size.isOdd ? 1 : 0);
    }
    if (fmt == null || dataOffset == null || dataSize == null) {
      throw const TrimException('WAV file has no audio data');
    }
    final fmtData = ByteData.sublistView(fmt);
    final byteRate = fmtData.getUint32(8, Endian.little);
    final blockAlign = fmtData.getUint16(12, Endian.little);
    if (byteRate == 0 || blockAlign == 0) throw const TrimException('Unsupported WAV');
    int toBytes(Duration d) {
      final raw = (d.inMicroseconds * byteRate ~/ 1000000);
      return (raw ~/ blockAlign * blockAlign).clamp(0, dataSize!);
    }

    final from = toBytes(start);
    final to = toBytes(end);
    if (to <= from) throw const TrimException('The selection is outside the song');
    final pcm = b.sublist(dataOffset + from, dataOffset + to);
    final out = BytesBuilder();
    final header = ByteData(12 + 8 + fmt.length + 8);
    void ascii(int at, String s) {
      for (var k = 0; k < 4; k++) {
        header.setUint8(at + k, s.codeUnitAt(k));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 4 + 8 + fmt.length + 8 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, fmt.length, Endian.little);
    final h = header.buffer.asUint8List();
    h.setRange(20, 20 + fmt.length, fmt);
    ascii(20 + fmt.length, 'data');
    header.setUint32(24 + fmt.length, pcm.length, Endian.little);
    out.add(h);
    out.add(pcm);
    return CutResult(
      out.toBytes(),
      Duration(microseconds: pcm.length * 1000000 ~/ byteRate),
    );
  }
}
