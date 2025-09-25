part of 'metadata_extractor.dart';

/// Comprehensive artist name extraction from filenames and metadata
class ArtistNameExtractor {
  /// Extract artists from metadata tags with fallback to filename parsing
  static List<String> extractArtists(Tag? tag, String filePath) {
    final artists = <String>[];
    var artist = _cleanString(tag?.trackArtist);
    if (artist != null && artist.isNotEmpty) {
      artists.addAll(_splitArtists(artist));
    }
    if (artists.isEmpty) {
      // Try alternative artist properties that might exist
      final genericArtist = _cleanString(tag?.trackArtist) ?? 
                           _cleanString(tag?.albumArtist);
      if (genericArtist != null && genericArtist.isNotEmpty) {
        artists.addAll(_splitArtists(genericArtist));
      }
    }
    if (artists.isEmpty) {
      final albumArtist = _cleanString(tag?.albumArtist);
      if (albumArtist != null && albumArtist.isNotEmpty) {
        artists.addAll(_splitArtists(albumArtist));
      }
    }
    return artists.isEmpty ? ['Unknown Artist'] : artists;
  }

  /// Safe extraction of artists with error handling
  static List<String> extractArtistsSafely(Tag? tag, String filePath) {
    try {
      return extractArtists(tag, filePath);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting artists: $e');
      return ['Unknown Artist'];
    }
  }

  /// Ensure artists are extracted with filename fallback
  static List<String> ensureArtists(List<String> artists, String filePath) {
    final valid = artists
        .where((a) => a.trim().isNotEmpty && a.toLowerCase() != 'unknown artist')
        .toSet()
        .toList();
    if (valid.isNotEmpty) return valid;
    
    // Try to extract artist from filename
    final extractedArtists = extractArtistsFromFilename(filePath);
    if (extractedArtists.isNotEmpty) return extractedArtists;
    
    return [_guessArtistFromPath(filePath)];
  }

  /// Comprehensive filename parsing for artist extraction with improved context awareness
  static List<String> extractArtistsFromFilename(String filePath) {
    try {
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = _cleanFilename(fileName);
      
      // Use intelligent parsing that considers context and priority
      final parsed = _parseFilenameIntelligently(cleanFileName);
      
      if (parsed.artists.isNotEmpty) {
        return parsed.artists;
      }
      
      // Fallback patterns for edge cases
      return _extractArtistsWithFallbackPatterns(cleanFileName);
    } catch (e) {
      MetadataExtractor._logger.w('Error extracting artists from filename: $filePath - $e');
      return [];
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
          artists: _splitArtists(artistPart),
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
      
      if (_isValidArtistName(artistPart) && _isValidSongTitle(titlePart)) {
        return (
          artists: _splitArtists(artistPart),
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
      
      if (_isValidSongTitle(titlePart) && _isValidArtistName(artistPart)) {
        return (
          artists: _splitArtists(artistPart),
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
      
      if (_isValidArtistName(artistPart) && _isValidSongTitle(titlePart)) {
        return (
          artists: _splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    // Pattern 5: "Artist - Song Title (feat. OtherArtist)"
      match = RegExp(r'^(.+?)\s*[-–—]\s*(.+?)\s*\([^)]*feat[^)]*\)', caseSensitive: false).firstMatch(cleanFileName);
      if (match != null) {
      final artistPart = match.group(1)?.trim() ?? '';
      final titlePart = match.group(2)?.trim() ?? '';
      
      if (_isValidArtistName(artistPart) && _isValidSongTitle(titlePart)) {
        return (
          artists: _splitArtists(artistPart),
          albums: [],
          title: titlePart
        );
      }
    }
    
    return (artists: [], albums: [], title: cleanFileName);
  }

  /// Fallback patterns for edge cases
  static List<String> _extractArtistsWithFallbackPatterns(String cleanFileName) {
    // Try to extract from path-based context
    final pathBasedArtist = _extractArtistFromPathContext(cleanFileName);
    if (pathBasedArtist.isNotEmpty) {
      return pathBasedArtist;
    }
    
    // Last resort: use first part if it looks like an artist name
    final parts = cleanFileName.split(RegExp(r'[-–—_\s]+'));
    if (parts.isNotEmpty && _isValidArtistName(parts.first)) {
      return [parts.first];
    }
    
    return [];
  }

  /// Extract artist from path context (folder names, etc.)
  static List<String> _extractArtistFromPathContext(String fileName) {
    // This would be enhanced to look at folder structure
    // For now, return empty list
    return [];
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
      final c = _cleanString(p);
      if (c != null && c.isNotEmpty && c.toLowerCase() != 'unknown artist') {
        cleaned.add(c);
      }
    }
    return cleaned.isEmpty ? ['Unknown Artist'] : cleaned.toList();
  }

  /// Enhanced artist guessing from file path
  static String guessArtistFromPath(String filePath) {
    try {
      final pathParts = filePath.split('/');
      
      // Look for artist names in parent directories
      for (int i = pathParts.length - 2; i >= 0; i--) {
        final folderName = pathParts[i].trim();
        if (folderName.isNotEmpty && !_isCommonMusicFolderName(folderName)) {
          // Check if folder name looks like an artist name
          if (_isLikelyArtistName(folderName)) {
            return _cleanString(folderName) ?? 'Unknown Artist';
          }
        }
      }
      
      // Fallback: try to extract from filename
      final extractedArtists = extractArtistsFromFilename(filePath);
      if (extractedArtists.isNotEmpty) {
        return extractedArtists.first;
      }
      
      return 'Unknown Artist';
    } catch (e) {
      MetadataExtractor._logger.w('Error guessing artist from path: $filePath - $e');
      return 'Unknown Artist';
    }
  }

  /// Check if a string is likely an artist name
  static bool isLikelyArtistName(String text) {
    final lowerText = text.toLowerCase();
    
    // Common artist name indicators
    final artistIndicators = [
      'artist', 'band', 'group', 'singer', 'rapper', 'dj', 'producer'
    ];
    
    // If it contains artist indicators, it's likely an artist
    if (artistIndicators.any((indicator) => lowerText.contains(indicator))) {
      return true;
    }
    
    // If it's too short, it's probably not an artist
    if (text.length < 2) return false;
    
    // If it contains album/song indicators, it's probably not an artist
    if (_isLikelyAlbumName(text) || _isLikelySongTitle(text)) return false;
    
    // If it's a reasonable length and doesn't contain other indicators, it might be an artist
    return text.length >= 2 && text.length <= 50;
  }

  /// Check if a string contains common artist separators
  static bool containsArtistSeparators(String text) {
    final separators = ['&', ',', ';', '/', '\\', '+', 'x', '×', 'and', 'feat', 'featuring', 'ft'];
    final lowerText = text.toLowerCase();
    return separators.any((separator) => lowerText.contains(separator));
  }

  /// Check if a string contains featuring indicators
  static bool containsFeaturing(String text) {
    final featuring = ['feat', 'featuring', 'ft', 'with'];
    final lowerText = text.toLowerCase();
    return featuring.any((feat) => lowerText.contains(feat));
  }

  /// Check if a string contains collaboration indicators
  static bool containsCollaboration(String text) {
    final collaboration = ['x', '×', '&', 'and'];
    final lowerText = text.toLowerCase();
    return collaboration.any((collab) => lowerText.contains(collab));
  }
}
