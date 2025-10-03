part of 'metadata_extractor.dart';

/// Comprehensive artist name extraction from filenames and metadata
class ArtistNameExtractor {
  /// Extract artists from metadata tags with fallback to filename parsing
  static List<String> extractArtists(Tag? tag, String filePath) {
    final artists = <String>[];
    var artist = _cleanString(tag?.trackArtist);
    if (artist != null && artist.isNotEmpty) {
      artists.addAll(SharedValidation.splitArtists(artist));
    }
    if (artists.isEmpty) {
      // Try alternative artist properties that might exist
      final genericArtist = _cleanString(tag?.trackArtist) ?? 
                           _cleanString(tag?.albumArtist);
      if (genericArtist != null && genericArtist.isNotEmpty) {
        artists.addAll(SharedValidation.splitArtists(genericArtist));
      }
    }
    if (artists.isEmpty) {
      final albumArtist = _cleanString(tag?.albumArtist);
      if (albumArtist != null && albumArtist.isNotEmpty) {
        artists.addAll(SharedValidation.splitArtists(albumArtist));
      }
    }
    return artists.isEmpty ? ['Unknown Artist'] : artists;
  }

  /// Safe extraction of artists with error handling
  static List<String> extractArtistsSafely(Tag? tag, String filePath) {
    return SharedValidation.extractSafely(
      () => extractArtists(tag, filePath),
      ['Unknown Artist'],
      'artists',
    );
  }

  /// Ensure artists are extracted with filename fallback
  static List<String> ensureArtists(List<String> artists, String filePath) {
    return SharedValidation.ensureMetadata(
      artists,
      filePath,
      'artist',
      (path) => guessArtistFromPath(path),
      (path) => extractArtistsFromFilename(path),
    );
  }

  /// Comprehensive filename parsing for artist extraction with improved context awareness
  static List<String> extractArtistsFromFilename(String filePath) {
    try {
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = SharedValidation.cleanFilename(fileName);
      
      // Use intelligent parsing that considers context and priority
      final parsed = SharedValidation.parseFilenameIntelligently(cleanFileName);
      
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

  // Filename parsing moved to SharedValidation class to eliminate duplications

  /// Fallback patterns for edge cases
  static List<String> _extractArtistsWithFallbackPatterns(String cleanFileName) {
    // Try to extract from path-based context
    final pathBasedArtist = _extractArtistFromPathContext(cleanFileName);
    if (pathBasedArtist.isNotEmpty) {
      return pathBasedArtist;
    }
    
    // Last resort: use first part if it looks like an artist name
    final parts = cleanFileName.split(RegExp(r'[-–—_\s]+'));
    if (parts.isNotEmpty && SharedValidation.isValidArtistName(parts.first)) {
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

  // Validation functions moved to SharedValidation class to eliminate duplications

  // Artist splitting moved to SharedValidation class to eliminate duplications

  /// Enhanced artist guessing from file path
  static String guessArtistFromPath(String filePath) {
    return SharedValidation.guessFromPath(
      filePath,
      'artist',
      (text) => isLikelyArtistName(text),
    );
  }

  /// Check if a string is likely an artist name
  static bool isLikelyArtistName(String text) {
    return SharedValidation.isLikelyMetadata(text, 'artist');
  }

  /// Check if a string contains common artist separators
  static bool containsArtistSeparators(String text) {
    return SharedValidation.containsSeparators(text, 'artist');
  }

}
