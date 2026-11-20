import 'dart:io';

/// Shared, pure audio-header validation used by both the folder scanner and
/// the metadata extractor so they can never disagree about a file.
///
/// The previous implementation only looked at the first 12 bytes, which
/// rejected valid MP3s that start with padding / junk bytes before the first
/// frame, and FLAC files that carry an ID3 tag before the `fLaC` marker.
class AudioHeaderValidator {
  AudioHeaderValidator._();

  /// How many bytes from the start of the file are inspected.
  static const int headerProbeSize = 4096;

  /// Reads the first [headerProbeSize] bytes of [filePath] and validates them.
  static Future<bool> isValidFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final stat = await file.stat();
      if (stat.size < 1024) return false;
      final bytes = <int>[];
      await for (final chunk in file.openRead(0, headerProbeSize)) {
        bytes.addAll(chunk);
      }
      return isValidHeader(bytes, extensionOf(filePath));
    } catch (_) {
      return false;
    }
  }

  /// Lower-case extension without the dot (`song.MP3` -> `mp3`).
  static String extensionOf(String filePath) {
    final name = filePath.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Validates [header] (the first bytes of a file) for [extension]
  /// (with or without a leading dot, any case).
  static bool isValidHeader(List<int> header, String extension) {
    final ext = extension.startsWith('.')
        ? extension.substring(1).toLowerCase()
        : extension.toLowerCase();
    if (header.length < 4) return false;

    switch (ext) {
      case 'mp3':
        if (_startsWithId3(header)) return true;
        return _findMp3FrameSync(header) >= 0;
      case 'flac':
        if (_matchesAt(header, 0, const [0x66, 0x4C, 0x61, 0x43])) return true;
        // Some taggers prepend an ID3v2 tag to FLAC files.
        return _startsWithId3(header);
      case 'ogg':
      case 'opus':
        return _matchesAt(header, 0, const [0x4F, 0x67, 0x67, 0x53]);
      case 'wav':
        return _matchesAt(header, 0, const [0x52, 0x49, 0x46, 0x46]);
      case 'm4a':
      case 'm4p':
      case 'm4b':
      case 'mp4':
      case 'alac':
        return header.length >= 8 &&
            _matchesAt(header, 4, const [0x66, 0x74, 0x79, 0x70]);
      default:
        // Formats without a reliable magic number: trust the extension.
        return true;
    }
  }

  static bool _startsWithId3(List<int> h) =>
      _matchesAt(h, 0, const [0x49, 0x44, 0x33]);

  static bool _matchesAt(List<int> h, int offset, List<int> magic) {
    if (h.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (h[offset + i] != magic[i]) return false;
    }
    return true;
  }

  /// Returns the index of the first plausible MPEG audio frame header, or -1.
  ///
  /// A frame header is 11 set sync bits followed by a valid version, layer,
  /// bitrate and sample-rate index. Checking those fields avoids false
  /// positives on runs of 0xFF bytes.
  static int _findMp3FrameSync(List<int> h) {
    for (var i = 0; i + 3 < h.length; i++) {
      if (h[i] != 0xFF || (h[i + 1] & 0xE0) != 0xE0) continue;
      final version = (h[i + 1] >> 3) & 0x03; // 01 is reserved
      final layer = (h[i + 1] >> 1) & 0x03; // 00 is reserved
      final bitrate = (h[i + 2] >> 4) & 0x0F; // 1111 is invalid
      final sampleRate = (h[i + 2] >> 2) & 0x03; // 11 is reserved
      if (version == 0x01 || layer == 0x00) continue;
      if (bitrate == 0x0F || sampleRate == 0x03) continue;
      return i;
    }
    return -1;
  }
}
