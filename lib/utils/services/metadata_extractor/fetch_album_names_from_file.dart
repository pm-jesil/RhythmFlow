part of 'metadata_extractor.dart';

/// Comprehensive album name extraction from filenames and metadata
class AlbumNameExtractor {
  /// Extract albums from metadata tags with fallback to filename parsing
  static List<String> extractAlbums(Tag? tag, String filePath) {
    final album = _cleanString(tag?.album);
    if (album != null && album.isNotEmpty) {
      return splitAlbums(album);
    }
    return ['Unknown Album'];
  }

  /// Safe extraction of albums with error handling
  static List<String> extractAlbumsSafely(Tag? tag, String filePath) {
    try {
      return extractAlbums(tag, filePath);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting albums: $e');
      return ['Unknown Album'];
    }
  }

  /// Ensure albums are extracted with filename fallback
  static List<String> ensureAlbums(List<String> albums, String filePath) {
    final valid = albums
        .where((a) => a.trim().isNotEmpty && a.toLowerCase() != 'unknown album')
        .toSet()
        .toList();
    if (valid.isNotEmpty) return valid;
    
    // Try to extract album from filename
    final extractedAlbum = extractAlbumFromFilename(filePath);
    if (extractedAlbum != null && extractedAlbum.isNotEmpty) return [extractedAlbum];
    
    return [_guessAlbumFromPath(filePath)];
  }

  /// Comprehensive filename parsing for album extraction with improved context awareness
  static String? extractAlbumFromFilename(String filePath) {
    try {
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = _cleanFilename(fileName);
      
      // Use intelligent parsing that considers context and priority
      final parsed = _parseFilenameIntelligently(cleanFileName);
      
      if (parsed.albums.isNotEmpty) {
        return parsed.albums.first;
      }
      
      // Fallback patterns for edge cases
      return _extractAlbumWithFallbackPatterns(cleanFileName);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting album from filename: $filePath - $e');
      return null;
    }
  }

  /// Intelligent filename parsing that considers context and semantic meaning
  static ({List<String> artists, List<String> albums, String title}) _parseFilenameIntelligently(String cleanFileName) {
    // Pattern 1: "Artist - Album - Song Title" (most specific)
    var match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
    if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      final titlePart = match.group(3)?.trim() ?? '';
      
      if (_isValidArtistName(artistPart) && _isValidAlbumName(albumPart) && _isValidSongTitle(titlePart)) {
        return (
          artists: [artistPart],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 2: "Song Title (Album Name)"
    match = RegExp(r'^(.+?)\s*\((.+?)\)').firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      
      if (_isValidSongTitle(titlePart) && _isValidAlbumName(albumPart)) {
        return (
          artists: [],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 3: "Song Title [Album Name]"
    match = RegExp(r'^(.+?)\s*\[(.+?)\]').firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      
      if (_isValidSongTitle(titlePart) && _isValidAlbumName(albumPart)) {
        return (
          artists: [],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    // Pattern 4: "Song Title - Album Name" (less reliable, needs validation)
    match = RegExp(r'^(.+?)\s*[-–—]\s*(.+)$').firstMatch(cleanFileName);
    if (match != null) {
      final titlePart = match.group(1)?.trim() ?? '';
      final albumPart = match.group(2)?.trim() ?? '';
      
      // Only accept if the second part clearly looks like an album name
      if (_isValidSongTitle(titlePart) && _isValidAlbumName(albumPart) && _hasStrongAlbumIndicators(albumPart)) {
        return (
          artists: [],
          albums: [albumPart],
          title: titlePart
        );
      }
    }
    
    return (artists: [], albums: [], title: cleanFileName);
  }

  /// Fallback patterns for edge cases
  static String? _extractAlbumWithFallbackPatterns(String cleanFileName) {

    
    // Last resort: look for album indicators in the filename
    final parts = cleanFileName.split(RegExp(r'[-–—_\s]+'));
    for (final part in parts) {
      if (_isValidAlbumName(part) && _hasStrongAlbumIndicators(part)) {
        return part;
      }
    }
    
    return null;
  }

  /// Check if a string has strong album indicators (more reliable)
  static bool _hasStrongAlbumIndicators(String text) {
    final lowerText = text.toLowerCase();
    const strongAlbumIndicators = [
      'album', 'ep', 'compilation', 'collection', 'greatest hits',
      'best of', 'anthology', 'soundtrack', 'ost', 'original soundtrack',
      'deluxe', 'edition', 'remastered', 'remaster'
    ];
    return strongAlbumIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Enhanced validation for artist names
  static bool _isValidArtistName(String text) {
    if (text.isEmpty || text.length < 2) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains song/album indicators
    if (_containsSongIndicators(lowerText) || _containsAlbumIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains artist indicators
    if (_containsArtistIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 2 && text.length <= 50 && !_containsProblematicPatterns(text);
  }

  /// Enhanced validation for album names
  static bool _isValidAlbumName(String text) {
    if (text.isEmpty || text.length < 3) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains song/artist indicators
    if (_containsSongIndicators(lowerText) || _containsArtistIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains album indicators
    if (_containsAlbumIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 3 && text.length <= 50 && !_containsProblematicPatterns(text);
  }

  /// Enhanced validation for song titles
  static bool _isValidSongTitle(String text) {
    if (text.isEmpty || text.length < 2) return false;
    
    final lowerText = text.toLowerCase();
    
    // Reject if it contains artist/album indicators
    if (_containsArtistIndicators(lowerText) || _containsAlbumIndicators(lowerText)) {
      return false;
    }
    
    // Accept if it contains song indicators
    if (_containsSongIndicators(lowerText)) {
      return true;
    }
    
    // Accept if it's a reasonable length and doesn't contain problematic patterns
    return text.length >= 2 && text.length <= 100 && !_containsProblematicPatterns(text);
  }

  /// Check for song-specific indicators
  static bool _containsSongIndicators(String lowerText) {
    const songIndicators = [
      'song', 'track', 'music', 'video', 'lyric', 'official', 'explicit', 'clean',
      'radio edit', 'remix', 'cover', 'version', 'feat', 'featuring', 'ft',
      'hd', '4k', '1080p', '720p', 'mp3', 'flac', 'aac', 'wav', 'single'
    ];
    return songIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for album-specific indicators
  static bool _containsAlbumIndicators(String lowerText) {
    const albumIndicators = [
      'album', 'ep', 'single', 'compilation', 'collection', 'greatest hits',
      'best of', 'anthology', 'soundtrack', 'ost', 'original soundtrack',
      'deluxe', 'edition', 'remastered', 'remaster'
    ];
    return albumIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for artist-specific indicators
  static bool _containsArtistIndicators(String lowerText) {
    const artistIndicators = [
      'artist', 'band', 'group', 'singer', 'rapper', 'dj', 'producer',
      'feat', 'featuring', 'ft', 'with', 'and', '&', 'x', '×'
    ];
    return artistIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Check for problematic patterns that suggest incorrect parsing
  static bool _containsProblematicPatterns(String text) {
    final problematicPatterns = [
      RegExp(r'\d{4}'), // Years
      RegExp(r'\[.*\]'), // Brackets
      RegExp(r'\(.*\)'), // Parentheses
      RegExp(r'\.(mp3|flac|wav|aac|m4a)$', caseSensitive: false), // File extensions
    ];
    return problematicPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Split album string into multiple albums
  static List<String> splitAlbums(String albumString) {
    if (albumString.isEmpty) return ['Unknown Album'];

    var normalized = albumString
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^from\s+', caseSensitive: false), '');

    // Common album separators
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
      final c = _cleanString(p);
      if (c != null && c.isNotEmpty && c.toLowerCase() != 'unknown album') {
        cleaned.add(c);
      }
    }
    return cleaned.isEmpty ? ['Unknown Album'] : cleaned.toList();
  }

  /// Enhanced album guessing from file path
  static String guessAlbumFromPath(String filePath) {
    try {
      final pathParts = filePath.split('/');
      
      // Look for album names in parent directories
      for (int i = pathParts.length - 2; i >= 0; i--) {
        final folderName = pathParts[i].trim();
        if (folderName.isNotEmpty && !_isCommonMusicFolderName(folderName)) {
          // Check if folder name looks like an album name
          if (isLikelyAlbumName(folderName)) {
            return _cleanString(folderName) ?? 'Unknown Album';
          }
        }
      }
      
      // Fallback: try to extract from filename
      final extractedAlbum = extractAlbumFromFilename(filePath);
      if (extractedAlbum != null && extractedAlbum.isNotEmpty) {
        return extractedAlbum;
      }
      
      return 'Unknown Album';
    } catch (e) {
      MetadataExtractor._logger.w('Error guessing album from path: $filePath - $e');
      return 'Unknown Album';
    }
  }

  /// Check if a string is likely an album name
  static bool isLikelyAlbumName(String text) {
    final lowerText = text.toLowerCase();
    
    // Common album name indicators
    final albumIndicators = [
      'album', 'ep', 'single', 'compilation', 'collection', 'greatest hits',
      'best of', 'anthology', 'soundtrack', 'ost', 'original soundtrack'
    ];
    
    // If it contains album indicators, it's likely an album
    if (albumIndicators.any((indicator) => lowerText.contains(indicator))) {
      return true;
    }
    
    // If it's too short, it's probably not an album
    if (text.length < 3) return false;
    
    // If it contains song indicators, it's probably not an album
    if (_isLikelySongTitle(text)) return false;
    
    // If it's a reasonable length and doesn't contain song indicators, it might be an album
    return text.length >= 3 && text.length <= 50;
  }

  /// Check if a string contains common album separators
  static bool containsAlbumSeparators(String text) {
    final separators = ['&', ',', ';', '/', '\\', '+', 'and'];
    final lowerText = text.toLowerCase();
    return separators.any((separator) => lowerText.contains(separator));
  }
}
