part of 'metadata_extractor.dart';

/// General metadata extraction utilities and helpers
class MetadataUtils {
  /// Clean and normalize string input
  static String? cleanString(String? input) {
    if (input == null || input.isEmpty) return null;
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\uFFFD'), '')
        .trim();
  }

  /// Extract title from metadata or filename
  static String extractTitle(Tag? tag, String filePath) {
    final title = cleanString(tag?.title);
    if (title != null && title.isNotEmpty) return title;
    return FilenameParser.extractTitleFromFilename(filePath);
  }

  /// Extract duration from metadata
  static Duration extractDuration(Tag? tag) {
    final duration = tag?.duration;
    if (duration != null && duration > 0) {
      return Duration(seconds: duration);
    }
    return Duration.zero;
  }

  /// Safe extraction of duration with error handling
  static Duration extractDurationSafely(Tag? tag) {
    try {
      return extractDuration(tag);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting duration: $e');
      return Duration.zero;
    }
  }

  /// Extract genre from metadata with mapping
  static String? extractGenreSafely(Tag? tag) {
    try {
      final genre = cleanString(tag?.genre);
      if (genre == null || genre.isEmpty) return null;
      final numericGenre = int.tryParse(genre);
      if (numericGenre != null && MetadataExtractor._genreMap.containsKey(numericGenre.toString())) {
        return MetadataExtractor._genreMap[numericGenre.toString()];
      }
      var cleanGenre = genre
          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'\s*\[[^\]]*\]'), '')
          .split(RegExp(r'[;,/]'))
          .first
          .trim();
      cleanGenre = cleanGenre
          .split(' ')
          .map((word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word)
          .join(' ');
      return cleanGenre.isEmpty ? null : cleanGenre;
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting genre: $e');
      return null;
    }
  }

  /// Extract year from metadata
  static int? extractYearSafely(Tag? tag) {
    try {
      final year = tag?.year;
      if (year != null && year > 1900 && year <= DateTime.now().year + 1) {
        return year;
      }
      return null;
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting year: $e');
      return null;
    }
  }

  /// Extract track number from metadata
  static int? extractTrackNumberSafely(Tag? tag) {
    try {
      final track = tag?.trackNumber;
      if (track != null && track > 0 && track <= 999) return track;
      return null;
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting track number: $e');
      return null;
    }
  }

  /// Extract disc number from metadata
  static int? extractDiscNumberSafely(Tag? tag) {
    try {
      final disc = tag?.discNumber;
      if (disc != null && disc > 0 && disc <= 99) return disc;
      return null;
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting disc number: $e');
      return null;
    }
  }

  /// Get file size
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      MetadataExtractor._logger.w('Failed to get file size for: $filePath - $e');
      return 0;
    }
  }

  /// Get file creation/modification date
  static Future<DateTime> getFileCreationDate(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      MetadataExtractor._logger.w('Failed to get file date for: $filePath - $e');
      return DateTime.now();
    }
  }

  /// Generate unique song ID
  static Future<String> generateSongId(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      final combined = '$filePath${stat.size}${stat.modified.millisecondsSinceEpoch}';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 16);
    } catch (e) {
      final bytes = utf8.encode('$filePath${DateTime.now().millisecondsSinceEpoch}');
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 16);
    }
  }

  /// Create fallback song when metadata extraction fails
  static Future<Song> createFallbackSong(String filePath) async {
    MetadataExtractor._logger.d('Creating fallback song for: $filePath');
    final id = await generateSongId(filePath);
    final title = FilenameParser.extractTitleFromFilename(filePath);
    final fileSize = await getFileSize(filePath);
    final dateAdded = await getFileCreationDate(filePath);
    final artist = ArtistNameExtractor.guessArtistFromPath(filePath);
    final album = AlbumNameExtractor.guessAlbumFromPath(filePath);
    return Song(
      id: id,
      title: title,
      artists: [artist],
      albums: [album],
      path: filePath,
      duration: Duration.zero,
      albumArt: null,
      genre: null,
      year: null,
      trackNumber: null,
      discNumber: null,
      composer: null,
      lyrics: null,
      bitrate: null,
      fileSize: fileSize,
      dateAdded: dateAdded,
      lastPlayed: null,
      playCount: 0,
      isFavorite: false,
      albumArtist: null,
    );
  }

  /// Extract metadata with retry mechanism
  static Future<Song?> extractMetadataWithRetry(String filePath, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await MetadataExtractor.extractMetadata(filePath);
      } catch (e) {
        if (attempt == maxRetries) {
          MetadataExtractor._logger.e('Failed to extract metadata after $maxRetries attempts: $filePath - $e');
          return null;
        } else {
          MetadataExtractor._logger.w('Attempt ${attempt + 1} failed for $filePath, retrying... - $e');
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        }
      }
    }
    return null;
  }

  /// Validate if file is a valid audio file
  static Future<bool> isValidAudioFile(String filePath) async {
    if (!isAudioFile(filePath)) return false;

    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      if (stat.size < 1024) return false;

      final bytes = await file.openRead(0, 12).first;
      return validateAudioHeader(bytes, filePath.split('.').last.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  /// Check if file extension is supported audio format
  static bool isAudioFile(String filePath) {
    final extension = '.${filePath.split('.').last.toLowerCase()}';
    return MetadataExtractor._supportedExtensions.contains(extension);
  }

  /// Validate audio file header
  static bool validateAudioHeader(List<int> header, String extension) {
    if (header.length < 4) return false;

    switch (extension) {
      case 'mp3':
        // ID3v2 tag
        if (header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) return true;
        // MP3 frame header - more strict validation
        if (header[0] == 0xFF && (header[1] & 0xE0) == 0xE0) {
          // Additional validation: check that it's not all 0xFF bytes
          if (header[1] == 0xFF && header[2] == 0xFF && header[3] == 0xFF) return false;
          return true;
        }
        return false;
      case 'flac':
        return header[0] == 0x66 && header[1] == 0x4C && header[2] == 0x61 && header[3] == 0x43;
      case 'ogg':
        return header[0] == 0x4F && header[1] == 0x67 && header[2] == 0x67 && header[3] == 0x53;
      case 'wav':
        return header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46;
      case 'm4a':
      case 'm4p':
      case 'mp4':
        return header.length >= 8 && header[4] == 0x66 && header[5] == 0x74 && 
               header[6] == 0x79 && header[7] == 0x70;
      default:
        return true;
    }
  }

  /// Get Android version for platform-specific operations
  static Future<int> getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt;
      }
    } catch (e) {
      MetadataExtractor._logger.e('Error getting Android version', error: e);
    }
    return 0;
  }
}
