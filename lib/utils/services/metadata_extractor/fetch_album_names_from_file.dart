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
    return SharedValidation.extractSafely(
      () => extractAlbums(tag, filePath),
      ['Unknown Album'],
      'albums',
    );
  }

  /// Ensure albums are extracted with filename fallback
  static List<String> ensureAlbums(List<String> albums, String filePath) {
    return SharedValidation.ensureMetadata(
      albums,
      filePath,
      'album',
      (path) => guessAlbumFromPath(path),
      (path) => [extractAlbumFromFilename(path)].where((a) => a != null && a.isNotEmpty).cast<String>().toList(),
    );
  }

  /// Comprehensive filename parsing for album extraction with improved context awareness
  static String? extractAlbumFromFilename(String filePath) {
    try {
      final fileName = filePath.split('/').last.split('.').first;
      final cleanFileName = SharedValidation.cleanFilename(fileName);
      
      // Use intelligent parsing that considers context and priority
      final parsed = SharedValidation.parseFilenameIntelligently(cleanFileName);
      
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

  // Filename parsing moved to SharedValidation class to eliminate duplications

  /// Fallback patterns for edge cases
  static String? _extractAlbumWithFallbackPatterns(String cleanFileName) {

    
    // Last resort: look for album indicators in the filename
    final parts = cleanFileName.split(RegExp(r'[-–—_\s]+'));
    for (final part in parts) {
      if (SharedValidation.isValidAlbumName(part) && _hasStrongAlbumIndicators(part)) {
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

  // Validation functions moved to SharedValidation class to eliminate duplications

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
    return SharedValidation.guessFromPath(
      filePath,
      'album',
      (text) => isLikelyAlbumName(text),
    );
  }

  /// Check if a string is likely an album name
  static bool isLikelyAlbumName(String text) {
    return SharedValidation.isLikelyMetadata(text, 'album');
  }

  /// Check if a string contains common album separators
  static bool containsAlbumSeparators(String text) {
    final separators = ['&', ',', ';', '/', '\\', '+', 'and'];
    final lowerText = text.toLowerCase();
    return separators.any((separator) => lowerText.contains(separator));
  }
}
