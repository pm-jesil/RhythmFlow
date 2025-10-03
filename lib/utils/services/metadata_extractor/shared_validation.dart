part of 'metadata_extractor.dart';

/// Extension to capitalize strings
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

/// Shared validation utilities to eliminate duplications across metadata extractor files
class SharedValidation {
  /// Enhanced validation for artist names
  static bool isValidArtistName(String text) {
    if (text.isEmpty || text.length < 2) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains song/album indicators
    if (containsSongIndicators(lowerText) || containsAlbumIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains artist indicators
    if (containsArtistIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 2 && text.length <= 50 && !containsProblematicPatterns(text);
  }

  /// Enhanced validation for album names
  static bool isValidAlbumName(String text) {
    if (text.isEmpty || text.length < 3) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains song/artist indicators
    if (containsSongIndicators(lowerText) || containsArtistIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains album indicators
    if (containsAlbumIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 3 && text.length <= 50 && !containsProblematicPatterns(text);
  }

  /// Enhanced validation for song titles
  static bool isValidSongTitle(String text) {
    if (text.isEmpty || text.length < 2) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains artist/album indicators
    if (containsArtistIndicators(lowerText) || containsAlbumIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains song indicators
    if (containsSongIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 2 && text.length <= 100 && !containsProblematicPatterns(text);
  }

  /// Unified validation function with type flag
  static bool isValidMetadataName(String text, String metadataType) {
    switch (metadataType.toLowerCase()) {
      case 'artist':
        return isValidArtistName(text);
      case 'album':
        return isValidAlbumName(text);
      case 'song':
        return isValidSongTitle(text);
      default:
        return text.length >= 2 && text.length <= 100 && !containsProblematicPatterns(text);
    }
  }

  /// Unified separator detection with type flag
  static bool containsSeparators(String text, String metadataType) {
    final lowerText = text.toLowerCase();
    
    switch (metadataType.toLowerCase()) {
      case 'artist':
        final artistSeparators = ['&', ',', ';', '/', '\\', '+', 'x', '×', 'and', 'feat', 'featuring', 'ft', 'with', 'vs'];
        return artistSeparators.any((separator) => lowerText.contains(separator));
      case 'album':
        final albumSeparators = ['&', ',', ';', '/', '\\', '+', 'and'];
        return albumSeparators.any((separator) => lowerText.contains(separator));
      default:
        final defaultSeparators = ['&', ',', ';', '/', '\\', '+', 'and'];
        return defaultSeparators.any((separator) => lowerText.contains(separator));
    }
  }

  /// Check for song-specific indicators
  static bool containsSongIndicators(String lowerText) {
    const songIndicators = [
      'song', 'track', 'music', 'video', 'lyric', 'official', 'explicit', 'clean',
      'radio edit', 'remix', 'cover', 'version', 'feat', 'featuring', 'ft',
      'hd', '4k', '1080p', '720p', 'mp3', 'flac', 'aac', 'wav', 'single'
    ];
    return songIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for album-specific indicators
  static bool containsAlbumIndicators(String lowerText) {
    const albumIndicators = [
      'album', 'ep', 'single', 'compilation', 'collection', 'greatest hits',
      'best of', 'anthology', 'soundtrack', 'ost', 'original soundtrack',
      'deluxe', 'edition', 'remastered', 'remaster'
    ];
    return albumIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for artist-specific indicators
  static bool containsArtistIndicators(String lowerText) {
    const artistIndicators = [
      'artist', 'band', 'group', 'singer', 'rapper', 'dj', 'producer',
      'feat', 'featuring', 'ft', 'with', 'and', '&', 'x', '×'
    ];
    return artistIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for problematic patterns that suggest incorrect parsing
  static bool containsProblematicPatterns(String text) {
    final problematicPatterns = [
      RegExp(r'\d{4}'), // Years
      RegExp(r'\[.*\]'), // Brackets
      RegExp(r'\(.*\)'), // Parentheses
      RegExp(r'\.(mp3|flac|wav|aac|m4a)$', caseSensitive: false), // File extensions
    ];
    return problematicPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Split artist string into multiple artists
  static List<String> splitArtists(String artistString) {
    if (artistString.isEmpty) return ['Unknown Artist'];

    var normalized = artistString
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^by\s+', caseSensitive: false), '');

    normalized = normalized.replaceAll(
      RegExp(r'\s*[\(\[]?\s*(feat\.?|featuring|ft\.?|with)\s*[\)\]]?\s*', caseSensitive: false),
      ' | ',
    );

    final replacements = {
      RegExp(r'\s*&\s*'): ' | ',
      RegExp(r'\s+and\s+', caseSensitive: false): ' | ',
      RegExp(r'\s*,\s*'): ' | ',
      RegExp(r'\s*;\s*'): ' | ',
      RegExp(r'\s*/\s*'): ' | ',
      RegExp(r'\s*\\\s*'): ' | ',
      RegExp(r'\s*\+\s*'): ' | ',
      RegExp(r'\s*[x×]\s*', caseSensitive: false): ' | ',
      RegExp(r'\s*\|\|\s*'): ' | ',
      RegExp(r'\s*\|\s*'): ' | ',
    };
    replacements.forEach((regex, value) {
      normalized = normalized.replaceAll(regex, value);
    });

    final parts = normalized
        .split('|')
        .map((p) => p.trim())
        .map((p) => p.replaceAll(RegExp(r'''^[\(\[\{\"'`]+'''), ''))
        .map((p) => p.replaceAll(RegExp(r'''[\)\]\\}\"'`]+$'''), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    final cleaned = <String>{};
    for (final p in parts) {
      final c = MetadataUtils.cleanString(p);
      if (c != null && c.isNotEmpty && c.toLowerCase() != 'unknown artist') {
        cleaned.add(c);
      }
    }
    return cleaned.isEmpty ? ['Unknown Artist'] : cleaned.toList();
  }

  /// Generic safe extraction function with error handling
  static T extractSafely<T>(
    T Function() extractFunction,
    T fallbackValue,
    String errorContext,
  ) {
    try {
      return extractFunction();
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting $errorContext: $e');
      return fallbackValue;
    }
  }

  /// Unified metadata extraction with type flag
  static List<String> extractMetadataSafely(
    Tag? tag,
    String filePath,
    String metadataType, {
    String Function(Tag?)? extractor,
    List<String> Function(String)? fallbackExtractor,
  }) {
    try {
      if (tag != null && extractor != null) {
        final result = extractor(tag);
        if (result.isNotEmpty) {
          return [result];
        }
      }
      
      if (fallbackExtractor != null) {
        return fallbackExtractor(filePath);
      }
      
      return ['Unknown ${metadataType.capitalize()}'];
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting $metadataType: $e');
      return ['Unknown ${metadataType.capitalize()}'];
    }
  }

  /// Generic ensure function with fallback logic for metadata
  static List<String> ensureMetadata(
    List<String> existingMetadata,
    String filePath,
    String metadataType, // 'artist' or 'album'
    String Function(String) guessFromPath,
    List<String> Function(String) extractFromFilename,
  ) {
    final valid = existingMetadata
        .where((item) => item.trim().isNotEmpty && 
                        item.toLowerCase() != 'unknown $metadataType')
        .toSet()
        .toList();
    if (valid.isNotEmpty) return valid;
    
    // Try to extract from filename
    final extracted = extractFromFilename(filePath);
    if (extracted.isNotEmpty) return extracted;
    
    // Fallback to path guessing
    return [guessFromPath(filePath)];
  }

  /// Generic guess from path function
  static String guessFromPath(
    String filePath,
    String metadataType, // 'artist' or 'album'
    bool Function(String) isLikelyFunction,
  ) {
    try {
      final pathParts = filePath.split('/');
      
      // Look for metadata in parent directories
      for (int i = pathParts.length - 2; i >= 0; i--) {
        final folderName = pathParts[i].trim();
        if (folderName.isNotEmpty && !_isCommonMusicFolderName(folderName)) {
          // Check if folder name looks like the metadata type
          if (isLikelyFunction(folderName)) {
            return MetadataUtils.cleanString(folderName) ?? 'Unknown $metadataType';
          }
        }
      }
      
      // Fallback: try to extract from filename
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = _cleanFilename(fileName);
      final parsed = parseFilenameIntelligently(cleanFileName);
      
      if (metadataType == 'artist' && parsed.artists.isNotEmpty) {
        return parsed.artists.first;
      } else if (metadataType == 'album' && parsed.albums.isNotEmpty) {
        return parsed.albums.first;
      }
      
      return 'Unknown $metadataType';
    } catch (e) {
      MetadataExtractor._logger.w('Error guessing $metadataType from path: $filePath - $e');
      return 'Unknown $metadataType';
    }
  }

  /// Generic isLikely function for different metadata types
  static bool isLikelyMetadata(String text, String metadataType) {
    final lowerText = text.toLowerCase();
    
    // Common metadata indicators
    final metadataIndicators = {
      'artist': ['artist', 'band', 'group', 'singer', 'rapper', 'dj', 'producer'],
      'album': ['album', 'ep', 'single', 'compilation', 'collection', 'greatest hits',
                'best of', 'anthology', 'soundtrack', 'ost', 'original soundtrack'],
      'song': ['song', 'track', 'music', 'video', 'lyric', 'official', 'explicit', 'clean',
               'radio edit', 'remix', 'cover', 'version', 'feat', 'featuring', 'ft'],
    };
    
    // If it contains metadata indicators, it's likely that type
    if (metadataIndicators[metadataType]?.any((indicator) => lowerText.contains(indicator)) == true) {
      return true;
    }
    
    // If it's too short, it's probably not valid metadata
    if (text.length < 2) return false;
    
    // If it contains other metadata indicators, it's probably not this type
    for (final type in metadataIndicators.keys) {
      if (type != metadataType) {
        if (metadataIndicators[type]?.any((indicator) => lowerText.contains(indicator)) == true) {
          return false;
        }
      }
    }
    
    // If it's a reasonable length and doesn't contain other indicators, it might be valid
    return text.length >= 2 && text.length <= 100;
  }

  // Helper functions for the generic functions
  static String _cleanFilename(String fileName) {
    return FilenameParser.cleanFilename(fileName);
  }

  /// Public clean filename function
  static String cleanFilename(String fileName) {
    return FilenameParser.cleanFilename(fileName);
  }

  static bool _isCommonMusicFolderName(String folderName) {
    const commonFolders = [
      'music', 'songs', 'audio', 'tracks', 'playlist', 'albums', 'artists',
      'downloads', 'download', 'media', 'files', 'documents', 'storage'
    ];
    return commonFolders.contains(folderName.toLowerCase());
  }

  /// Intelligent filename parsing that considers context and semantic meaning
  static ({List<String> artists, List<String> albums, String title}) parseFilenameIntelligently(String cleanFileName) {
    // Pattern 1: "Artist - Album - Song Title" (most specific and reliable)
    var match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
    if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      final titlePart = match.group(3)?.trim() ?? '';
      
      if (isValidArtistName(artistPart) && isValidAlbumName(albumPart) && isValidSongTitle(titlePart)) {
        return (
          artists: splitArtists(artistPart),
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 2: "Artist - Song Title" (common pattern)
    match = RegExp(r'^(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
    if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final titlePart = match.group(2)?.trim() ?? '';
      
      if (isValidArtistName(artistPart) && isValidSongTitle(titlePart)) {
        return (
          artists: splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    // Pattern 3: "Song Title by Artist"
    match = RegExp(r'^(.+?)\s+by\s+(.+)$', caseSensitive: false).firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final artistPart = match.group(2)?.trim() ?? '';
      
      if (isValidSongTitle(titlePart) && isValidArtistName(artistPart)) {
        return (
          artists: splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    // Pattern 4: "Artist _ Song Title" (underscore separator)
    match = RegExp(r'^(.+?)\s*_\s*(.+)$').firstMatch(cleanFileName);
    if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final titlePart = match.group(2)?.trim() ?? '';
      
      if (isValidArtistName(artistPart) && isValidSongTitle(titlePart)) {
        return (
          artists: splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    // Pattern 5: "Song Title (Album Name)"
    match = RegExp(r'^(.+?)\s*\((.+?)\)').firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      
      if (isValidSongTitle(titlePart) && isValidAlbumName(albumPart)) {
        return (
          artists: [],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 6: "Song Title [Album Name]"
    match = RegExp(r'^(.+?)\s*\[(.+?)\]').firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      
      if (isValidSongTitle(titlePart) && isValidAlbumName(albumPart)) {
        return (
          artists: [],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 7: "Artist - Song Title (feat. OtherArtist)"
    match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\([^)]*feat[^)]*\)', caseSensitive: false).firstMatch(cleanFileName);
    if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final titlePart = match.group(2)?.trim() ?? '';
      
      if (isValidArtistName(artistPart) && isValidSongTitle(titlePart)) {
        return (
          artists: splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    // Fallback: return the filename as title
    return (artists: [], albums: [], title: cleanFileName);
  }
}
