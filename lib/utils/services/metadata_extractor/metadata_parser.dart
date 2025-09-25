part of 'metadata_extractor.dart';

/// Shared metadata parsing utilities with intelligent context awareness
class MetadataParser {
  /// Parse filename intelligently and return all components
  static ({List<String> artists, List<String> albums, String title}) parseFilenameIntelligently(String cleanFileName) {
    // Pattern 1: "Artist - Album - Song Title" (most specific and reliable)
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
    
    // Pattern 5: "Song Title (Album Name)"
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
    
    // Pattern 6: "Song Title [Album Name]"
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
    
    // Pattern 7: "Artist - Song Title (feat. OtherArtist)"
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
    
    // Fallback: return the filename as title
    return (artists: [], albums: [], title: cleanFileName);
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
  static List<String> _splitArtists(String artistString) {
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
}
