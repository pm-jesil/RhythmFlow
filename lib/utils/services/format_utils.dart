/// Supported audio formats for song scanning. Used by FetchSongsService.
class FormatUtils {
  /// Default supported audio file extensions (used when no app settings context).
  static const List<String> defaultSupportedFormats = [
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg',
    '.wma',
    '.opus',
    '.aiff',
    '.alac',
    '.m4b',
    '.m4p',
    '.amr',
    '.3ga',
  ];
}
