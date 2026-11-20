import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/services/audio_header_validator.dart';
import 'package:rhythmflow/utils/services/ringtone/audio_trimmer.dart';

/// MPEG-1 Layer III, 128 kbps, 44.1 kHz, no padding: 417 bytes, 1152 samples.
Uint8List mp3Frame({int fill = 0, bool padding = false}) {
  final len = 417 + (padding ? 1 : 0);
  final f = Uint8List(len)..fillRange(4, len, fill);
  f[0] = 0xFF;
  f[1] = 0xFB;
  f[2] = 0x90 | (padding ? 0x02 : 0);
  f[3] = 0x64;
  return f;
}

Uint8List id3(int bodySize) {
  final b = Uint8List(10 + bodySize);
  b.setAll(0, [0x49, 0x44, 0x33, 4, 0, 0]);
  b[6] = (bodySize >> 21) & 0x7F;
  b[7] = (bodySize >> 14) & 0x7F;
  b[8] = (bodySize >> 7) & 0x7F;
  b[9] = bodySize & 0x7F;
  return b;
}

Uint8List mp3({int frames = 100, int id3Body = 0, bool xing = false, bool id3v1 = false}) {
  final b = BytesBuilder();
  if (id3Body > 0) b.add(id3(id3Body));
  if (xing) {
    final f = mp3Frame();
    f.setAll(36, 'Xing'.codeUnits);
    b.add(f);
  }
  for (var i = 0; i < frames; i++) {
    b.add(mp3Frame(fill: i % 250 + 1, padding: i % 3 == 0));
  }
  if (id3v1) {
    final t = Uint8List(128)..setAll(0, 'TAG'.codeUnits);
    b.add(t);
  }
  return b.toBytes();
}

Uint8List wav({int seconds = 4, int rate = 8000, int channels = 1, int bits = 16, bool extraChunk = false}) {
  final blockAlign = channels * bits ~/ 8;
  final pcm = Uint8List(seconds * rate * blockAlign);
  for (var i = 0; i < pcm.length; i++) {
    pcm[i] = i % 256;
  }
  final extra = extraChunk ? 8 + 5 + 1 : 0; // odd size gets a pad byte
  final h = ByteData(44 + extra);
  void ascii(int at, String s) => s.codeUnits.asMap().forEach((k, c) => h.setUint8(at + k, c));
  ascii(0, 'RIFF');
  h.setUint32(4, 36 + extra + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little);
  h.setUint16(22, channels, Endian.little);
  h.setUint32(24, rate, Endian.little);
  h.setUint32(28, rate * blockAlign, Endian.little);
  h.setUint16(32, blockAlign, Endian.little);
  h.setUint16(34, bits, Endian.little);
  var at = 36;
  if (extraChunk) {
    ascii(36, 'LIST');
    h.setUint32(40, 5, Endian.little);
    at = 36 + 14;
  }
  ascii(at, 'data');
  h.setUint32(at + 4, pcm.length, Endian.little);
  return (BytesBuilder()..add(h.buffer.asUint8List())..add(pcm)).toBytes();
}

const frameMicros = 1152 * 1000000 ~/ 44100; // 26122 us

void main() {
  group('Mp3Cutter', () {
    test('parses frame headers (length, sample rate, duration)', () {
      final f = Mp3Cutter.frameAt(mp3Frame(), 0)!;
      expect(f.length, 417);
      expect(f.sampleRate, 44100);
      expect(f.duration.inMicroseconds, frameMicros);
      expect(Mp3Cutter.frameAt(mp3Frame(padding: true), 0)!.length, 418);
    });

    test('rejects invalid headers', () {
      expect(Mp3Cutter.frameAt(Uint8List.fromList([0, 1, 2, 3]), 0), isNull);
      expect(Mp3Cutter.frameAt(Uint8List.fromList([0xFF, 0xFB, 0xF0, 0]), 0), isNull, reason: 'bitrate 15');
      expect(Mp3Cutter.frameAt(Uint8List.fromList([0xFF, 0xFB, 0x9C, 0]), 0), isNull, reason: 'rate 3');
      expect(Mp3Cutter.frameAt(Uint8List.fromList([0xFF, 0xEB, 0x90, 0]), 0), isNull, reason: 'reserved version');
    });

    test('MPEG-2 layer III frame is 576 samples', () {
      // 0xF3 = MPEG2 L3, bitrate idx 8 (64 kbps), 22050 Hz
      final f = Mp3Cutter.frameAt(Uint8List.fromList([0xFF, 0xF3, 0x80, 0x64, ...List.filled(400, 0)]), 0)!;
      expect(f.samples, 576);
      expect(f.sampleRate, 22050);
      expect(f.length, 72 * 64000 ~/ 22050);
    });

    test('skips ID3v2, Xing header and ID3v1', () {
      final b = mp3(frames: 50, id3Body: 300, xing: true, id3v1: true);
      final frames = Mp3Cutter.frames(b);
      expect(frames, hasLength(50));
      expect(frames.first.offset, 310 + 417);
      expect(Mp3Cutter.id3v2Size(b), 310);
    });

    test('total duration of 100 frames', () {
      expect(Mp3Cutter.totalDuration(mp3()).inMicroseconds, 100 * frameMicros);
    });

    test('cuts whole frames inside the range', () {
      final b = mp3(frames: 200, id3Body: 100, xing: true);
      final cut = Mp3Cutter.cut(b, const Duration(milliseconds: 1000), const Duration(milliseconds: 2000));
      final frames = Mp3Cutter.frames(cut.bytes);
      // frames starting at t in [1000ms, 2000ms): 38 frames (39th starts at 1018.7ms ...)
      final expected = List.generate(200, (i) => i * frameMicros)
          .where((t) => t >= 1000000 && t < 2000000)
          .length;
      expect(frames, hasLength(expected));
      expect(cut.duration.inMicroseconds, expected * frameMicros);
      expect(cut.bytes.sublist(0, 3), isNot([0x49, 0x44, 0x33]), reason: 'no ID3 in the output');
      expect(AudioHeaderValidator.isValidHeader(cut.bytes.sublist(0, 64), 'mp3'), isTrue);
    });

    test('a range past the end keeps the tail', () {
      final cut = Mp3Cutter.cut(mp3(frames: 100), const Duration(seconds: 2), const Duration(seconds: 30));
      expect(Mp3Cutter.frames(cut.bytes).length, 100 - (2000000 / frameMicros).ceil());
    });

    test('a range entirely after the song fails', () {
      expect(
        () => Mp3Cutter.cut(mp3(frames: 10), const Duration(seconds: 5), const Duration(seconds: 6)),
        throwsA(isA<TrimException>()),
      );
    });

    test('non-MP3 bytes fail', () {
      expect(() => Mp3Cutter.cut(Uint8List(5000), Duration.zero, const Duration(seconds: 1)),
          throwsA(isA<TrimException>()));
    });

    test('resyncs after junk between frames', () {
      final b = BytesBuilder()
        ..add(mp3(frames: 20))
        ..add(Uint8List.fromList([1, 2, 3, 0xFF, 7]))
        ..add(mp3(frames: 20));
      expect(Mp3Cutter.frames(b.toBytes()), hasLength(40));
    });
  });

  group('WavCutter', () {
    test('cuts on sample boundaries with a valid header', () {
      final cut = WavCutter.cut(wav(), const Duration(milliseconds: 1000), const Duration(milliseconds: 2500));
      final d = ByteData.sublistView(cut.bytes);
      expect(String.fromCharCodes(cut.bytes.sublist(0, 4)), 'RIFF');
      expect(d.getUint32(4, Endian.little), cut.bytes.length - 8);
      expect(d.getUint32(40, Endian.little), 1500 * 16); // 16000 B/s * 1.5 s
      expect(cut.duration, const Duration(milliseconds: 1500));
      // first sample of the cut = byte 16000 of the PCM
      expect(cut.bytes[44], 16000 % 256);
      expect(AudioHeaderValidator.isValidHeader(cut.bytes.sublist(0, 44), 'wav'), isTrue);
    });

    test('handles extra chunks before data and stereo block alignment', () {
      final cut = WavCutter.cut(
        wav(channels: 2, extraChunk: true),
        const Duration(microseconds: 333333),
        const Duration(seconds: 1),
      );
      final pcmLen = cut.bytes.length - 44;
      expect(pcmLen % 4, 0);
    });

    test('clamps the end and rejects empty ranges / bad files', () {
      final cut = WavCutter.cut(wav(seconds: 2), const Duration(seconds: 1), const Duration(seconds: 9));
      expect(cut.duration, const Duration(seconds: 1));
      expect(() => WavCutter.cut(wav(seconds: 2), const Duration(seconds: 3), const Duration(seconds: 4)),
          throwsA(isA<TrimException>()));
      expect(() => WavCutter.cut(Uint8List(100), Duration.zero, const Duration(seconds: 1)),
          throwsA(isA<TrimException>()));
    });
  });

  group('AudioTrimmer', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('trim_'));
    tearDown(() async {
      AudioTrimmer.isAndroidOverride = null;
      await dir.delete(recursive: true);
    });

    test('trims an mp3 file to disk', () async {
      final input = File('${dir.path}/song.mp3')..writeAsBytesSync(mp3(frames: 300, id3Body: 50));
      final r = await AudioTrimmer.trim(
        inputPath: input.path,
        outputPathWithoutExtension: '${dir.path}/out',
        start: const Duration(seconds: 1),
        end: const Duration(seconds: 3),
      );
      expect(r.path, '${dir.path}/out.mp3');
      expect(r.extension, 'mp3');
      expect(r.duration.inMilliseconds, closeTo(2000, 30));
      expect(await AudioHeaderValidator.isValidFile(r.path), isTrue);
    });

    test('trims a wav file to disk', () async {
      final input = File('${dir.path}/song.WAV')..writeAsBytesSync(wav());
      final r = await AudioTrimmer.trim(
        inputPath: input.path,
        outputPathWithoutExtension: '${dir.path}/out',
        start: Duration.zero,
        end: const Duration(seconds: 1),
      );
      expect(r.extension, 'wav');
      expect(r.duration, const Duration(seconds: 1));
    });

    test('formats: mp3/wav everywhere, m4a only on Android, flac never', () {
      AudioTrimmer.isAndroidOverride = false;
      expect(AudioTrimmer.canTrim('/a.mp3'), isTrue);
      expect(AudioTrimmer.canTrim('/a.wav'), isTrue);
      expect(AudioTrimmer.canTrim('/a.m4a'), isFalse);
      expect(AudioTrimmer.canTrim('/a.flac'), isFalse);
      AudioTrimmer.isAndroidOverride = true;
      expect(AudioTrimmer.canTrim('/a.m4a'), isTrue);
      expect(AudioTrimmer.canTrim('/a.flac'), isFalse);
      expect(AudioTrimmer.outputExtension('/a.aac'), 'm4a');
    });

    test('unsupported format and inverted range throw', () async {
      AudioTrimmer.isAndroidOverride = false;
      await expectLater(
        AudioTrimmer.trim(
          inputPath: '/x.flac',
          outputPathWithoutExtension: '${dir.path}/o',
          start: Duration.zero,
          end: const Duration(seconds: 1),
        ),
        throwsA(isA<TrimException>().having((e) => e.unsupportedFormat, 'unsupported', isTrue)),
      );
      await expectLater(
        AudioTrimmer.trim(
          inputPath: '/x.mp3',
          outputPathWithoutExtension: '${dir.path}/o',
          start: const Duration(seconds: 2),
          end: const Duration(seconds: 1),
        ),
        throwsA(isA<TrimException>()),
      );
    });
  });
}
