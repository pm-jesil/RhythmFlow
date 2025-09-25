part of 'metadata_extractor.dart';

/// General filename parsing utilities and helpers
class FilenameParser {
  /// Extract title from filename with comprehensive pattern matching
  static String extractTitleFromFilename(String filePath) {
    try {
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = cleanFilename(fileName);
      
      // Pattern 1: "Artist - Song Title"
      var match = RegExp(r'^(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 2: "Artist _ Song Title" (underscore separator)
      match = RegExp(r'^(.+?)\s*_\s*(.+)$').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 3: "Song Title by Artist"
      match = RegExp(r'^(.+?)\s+by\s+(.+)$', caseSensitive: false).firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(1)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 4: "Artist - Album - Song Title"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(3)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 5: "Artist - Song Title (feat. OtherArtist)"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\([^)]*feat[^)]*\)', caseSensitive: false).firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 6: "Artist - Song Title [Official Video]"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\[[^\]]*\]').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 7: "Artist - Song Title (Official Video)"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\([^)]*Official[^)]*\)', caseSensitive: false).firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 8: "Artist - Song Title - Album Name"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Pattern 9: "Artist - Song Title (Year)"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\(\d{4}\)').firstMatch(cleanFileName);
      if (match != null) {
        final titlePart = match.group(2)?.trim();
        if (titlePart != null && titlePart.isNotEmpty) {
          return cleanTitle(titlePart);
        }
      }
      
      // Fallback: use the entire filename as title
      return cleanTitle(cleanFileName);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting title from filename: $filePath - $e');
      return 'Unknown Title';
    }
  }

  /// Clean filename by removing common prefixes and suffixes
  static String cleanFilename(String fileName) {
    return fileName
        .replaceFirst(RegExp(r'^\d+\.?\s*'), '') // Remove track numbers
        .replaceFirst(RegExp(r'^\d+\s*-\s*'), '') // Remove track numbers with dash
        .replaceAll(RegExp(r'\[CD\d+\]', caseSensitive: false), '') // Remove CD numbers
        .replaceAll(RegExp(r'\(Disc\s+\d+\)', caseSensitive: false), '') // Remove disc numbers
        .replaceAll(RegExp(r'\[(Official|Explicit|Clean|Radio Edit|Video|Lyric|HD|4K|1080p|720p)\]', caseSensitive: false), '') // Remove video tags
        .replaceAll(RegExp(r'\((Official|Explicit|Clean|Radio Edit|Video|Lyric|HD|4K|1080p|720p)\)', caseSensitive: false), '') // Remove video tags
        .replaceAll(RegExp(r'\[(MP3|FLAC|AAC|WAV|OGG|M4A)_\d+K\]', caseSensitive: false), '') // Remove quality tags
        .replaceAll(RegExp(r'\((MP3|FLAC|AAC|WAV|OGG|M4A)_\d+K\)', caseSensitive: false), '') // Remove quality tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Clean and format song title
  static String cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\[(Official|Explicit|Clean|Radio Edit|Video|Lyric|HD|4K|1080p|720p)\]', caseSensitive: false), '') // Remove video tags
        .replaceAll(RegExp(r'\((Official|Explicit|Clean|Radio Edit|Video|Lyric|HD|4K|1080p|720p)\)', caseSensitive: false), '') // Remove video tags
        .replaceAll(RegExp(r'\[(MP3|FLAC|AAC|WAV|OGG|M4A)_\d+K\]', caseSensitive: false), '') // Remove quality tags
        .replaceAll(RegExp(r'\((MP3|FLAC|AAC|WAV|OGG|M4A)_\d+K\)', caseSensitive: false), '') // Remove quality tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Check if a string is likely a song title (not an album name)
  static bool isLikelySongTitle(String text) {
    final lowerText = text.toLowerCase();
    
    // Common song title indicators
    final songIndicators = [
      'song', 'track', 'music', 'video', 'lyric', 'official', 'explicit', 'clean',
      'radio edit', 'remix', 'cover', 'version', 'feat', 'featuring', 'ft',
      'hd', '4k', '1080p', '720p', 'mp3', 'flac', 'aac', 'wav'
    ];
    
    return songIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check if a string is likely non-Latin (contains Unicode characters)
  static bool isLikelyNonLatin(String text) {
    if (text.isEmpty) return false;
    for (final codeUnit in text.codeUnits) {
      final c = codeUnit;
      final isLatin = (c >= 0x0000 && c <= 0x024F);
      if (!isLatin) return true;
    }
    return false;
  }

  /// Check if a folder name is a common music folder
  static bool isCommonMusicFolderName(String folderName) {
    const commonNames = {
      'music', 'audio', 'songs', 'tracks', 'mp3', 'flac', 'downloads',
      'download', 'my music', 'sounds', 'media', 'multimedia', 'entertainment',
    };
    return commonNames.contains(folderName);
  }
}
