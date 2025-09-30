part of 'metadata_extractor.dart';

/// Core metadata extraction function without retry logic
Future<Song?> _extractMetadataCore(String filePath) async {
  if (!MetadataExtractor._initialized) {
    MetadataExtractor._logger.i('MetadataExtractor initializing on first use...');
    final initialized = await MetadataExtractor.initialize();
    if (!initialized) {
      MetadataExtractor._logger.e('Failed to initialize MetadataExtractor');
      return null;
    }
  }

  try {
    MetadataExtractor._logger.d('Extracting metadata from: $filePath');

    // Validate file
    if (!await _isValidAudioFile(filePath)) {
      MetadataExtractor._logger.w('Invalid audio file: $filePath');
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      MetadataExtractor._logger.w('File does not exist: $filePath');
      return null;
    }

    // Extract metadata using audiotags
    Tag? tag;
    try {
      tag = await AudioTags.read(filePath).timeout(const Duration(seconds: 5));
      if (tag != null) {
        MetadataExtractor._logger.d('Successfully read metadata with AudioTags from: $filePath');
      }
    } catch (e) {
      // Handle specific AudioTags errors gracefully
      if (e.toString().contains('MP4 Atom: "covr" atom has an unknown type')) {
        MetadataExtractor._logger.w('MP4 album art format not supported, continuing without album art: $filePath');
      } else if (e.toString().contains('Failed to load dynamic library') || 
                 e.toString().contains('audiotags.dll')) {
        MetadataExtractor._logger.w('Native AudioTags library not available - using fallback metadata extraction');
      } else {
        MetadataExtractor._logger.w('Failed to read metadata with AudioTags: $e');
        // For corrupted files, return null instead of continuing with fallback
        if (e.toString().contains('corrupted') || e.toString().contains('invalid')) {
          return null;
        }
      }
      // Continue with null tag - fallback metadata extraction will handle it
    }

    // Generate unique ID for the song
    final id = await _generateSongId(filePath);

    // Extract metadata fields with error handling
    final title = _extractTitle(tag, filePath);
    final artists = _extractArtistsSafely(tag, filePath);
    final albums = _extractAlbumsSafely(tag, filePath);
    
    // Use intelligent filename parsing to improve results when metadata is missing
    final filenameParsed = _parseFilenameForMissingData(filePath, artists, albums, title);
    final duration = _extractDurationSafely(tag);
    String? albumArt = await _extractAlbumArtSafely(filePath, tag);
    albumArt ??= await _findExternalAlbumArt(filePath);
    final genre = _extractGenreSafely(tag);
    final year = _extractYearSafely(tag);
    final trackNumber = _extractTrackNumberSafely(tag);
    final discNumber = _extractDiscNumberSafely(tag);
    final fileSize = await _getFileSize(filePath);
    final dateAdded = await _getFileCreationDate(filePath);

    final nonLatinTitle = _isLikelyNonLatin(filenameParsed.title);
    final resolvedArtists = nonLatinTitle
        ? (filenameParsed.artists.isNotEmpty ? filenameParsed.artists : ['Unknown Artist'])
        : _ensureArtists(filenameParsed.artists, filePath);
    final resolvedAlbums = nonLatinTitle
        ? (filenameParsed.albums.isNotEmpty ? filenameParsed.albums : ['Unknown Album'])
        : _ensureAlbums(filenameParsed.albums, filePath);

    final song = Song(
      id: id,
      title: filenameParsed.title,
      artists: resolvedArtists,
      albums: resolvedAlbums,
      path: filePath,
      duration: duration,
      albumArt: albumArt,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      composer: null,
      lyrics: null,
      bitrate: null,
      fileSize: fileSize,
      dateAdded: dateAdded,
      lastPlayed: null,
      playCount: 0,
      isFavorite: false,
      albumArtist: _cleanString(tag?.albumArtist),
    );

    MetadataExtractor._logger.d('Successfully extracted metadata for: $title by ${resolvedArtists.join(', ')}');
    return song;
  } catch (e, stackTrace) {
    MetadataExtractor._logger.e('Failed to extract metadata: $filePath', error: e, stackTrace: stackTrace);
    return null;
  }
}

/// Main metadata extraction function that orchestrates all the specialized extractors
Future<Song?> _extractMetadataWithRetry(String filePath, {int maxRetries = 2}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await _extractMetadataCore(filePath);
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

/// Legacy function wrappers for backward compatibility

Future<bool> _isValidAudioFile(String filePath) async {
  return MetadataUtils.isValidAudioFile(filePath);
}


bool _isAudioFile(String filePath) {
  return MetadataUtils.isAudioFile(filePath);
}

Future<String> _generateSongId(String filePath) async {
  return MetadataUtils.generateSongId(filePath);
}

String? _cleanString(String? input) {
  return MetadataUtils.cleanString(input);
}

String _extractTitle(Tag? tag, String filePath) {
  return MetadataUtils.extractTitle(tag, filePath);
}

bool _isLikelyNonLatin(String text) {
  return FilenameParser.isLikelyNonLatin(text);
}




List<String> _extractArtistsSafely(Tag? tag, String filePath) {
  return ArtistNameExtractor.extractArtistsSafely(tag, filePath);
}



List<String> _extractAlbumsSafely(Tag? tag, String filePath) {
  return AlbumNameExtractor.extractAlbumsSafely(tag, filePath);
}


List<String> _ensureArtists(List<String> artists, String filePath) {
  return ArtistNameExtractor.ensureArtists(artists, filePath);
}

List<String> _ensureAlbums(List<String> albums, String filePath) {
  return AlbumNameExtractor.ensureAlbums(albums, filePath);
}

/// Parse filename intelligently to fill missing metadata
({List<String> artists, List<String> albums, String title}) _parseFilenameForMissingData(
  String filePath, 
  List<String> existingArtists, 
  List<String> existingAlbums, 
  String existingTitle
) {
  try {
    final fileName = filePath.split('/').last.split('.').first;
    final cleanFileName = SharedValidation.cleanFilename(fileName);
    
    // Use intelligent parsing
    final parsed = SharedValidation.parseFilenameIntelligently(cleanFileName);
    
    // Only use filename parsing results if metadata is missing or poor quality
    final finalArtists = existingArtists.isEmpty || _isPoorQualityMetadata(existingArtists) 
        ? parsed.artists 
        : existingArtists;
    
    final finalAlbums = existingAlbums.isEmpty || _isPoorQualityMetadata(existingAlbums)
        ? parsed.albums 
        : existingAlbums;
    
    final finalTitle = existingTitle.isEmpty || _isPoorQualityTitle(existingTitle)
        ? parsed.title 
        : existingTitle;
    
    return (
      artists: finalArtists,
      albums: finalAlbums,
      title: finalTitle
    );
  } catch (e) {
    MetadataExtractor._logger.w('Error parsing filename for missing data: $filePath - $e');
    return (
      artists: existingArtists,
      albums: existingAlbums,
      title: existingTitle
    );
  }
}

/// Check if metadata is poor quality (generic or empty)
bool _isPoorQualityMetadata(List<String> metadata) {
  if (metadata.isEmpty) return true;
  
  const poorQualityIndicators = [
    'unknown', 'untitled', 'various', 'misc', 'other', 'n/a', 'na',
    'unknown artist', 'unknown album', 'unknown title'
  ];
  
  return metadata.any((item) => 
    poorQualityIndicators.any((indicator) => 
      item.toLowerCase().contains(indicator)
    )
  );
}

/// Check if title is poor quality
bool _isPoorQualityTitle(String title) {
  if (title.isEmpty) return true;
  
  const poorQualityIndicators = [
    'unknown', 'untitled', 'track', 'song', 'audio', 'music',
    'unknown title', 'untitled track'
  ];
  
  return poorQualityIndicators.any((indicator) => 
    title.toLowerCase().contains(indicator)
  );
}


Duration _extractDurationSafely(Tag? tag) {
  return MetadataUtils.extractDurationSafely(tag);
}

String? _extractGenreSafely(Tag? tag) {
  return MetadataUtils.extractGenreSafely(tag);
}

int? _extractYearSafely(Tag? tag) {
  return MetadataUtils.extractYearSafely(tag);
}

int? _extractTrackNumberSafely(Tag? tag) {
  return MetadataUtils.extractTrackNumberSafely(tag);
}

int? _extractDiscNumberSafely(Tag? tag) {
  return MetadataUtils.extractDiscNumberSafely(tag);
}

Future<String?> _extractAlbumArtSafely(String filePath, Tag? tag) async {
  return AlbumArtHandler.extractAlbumArtSafely(filePath, tag);
}

Future<String?> _extractAlbumArt(String filePath, Tag? tag) async {
  return AlbumArtHandler.extractAlbumArt(filePath, tag);
}

Future<String?> _findExternalAlbumArt(String filePath) async {
  return AlbumArtHandler.findExternalAlbumArt(filePath);
}


Future<int> _getFileSize(String filePath) async {
  return MetadataUtils.getFileSize(filePath);
}

Future<DateTime> _getFileCreationDate(String filePath) async {
  return MetadataUtils.getFileCreationDate(filePath);
}


// Functions moved to SharedValidation class to eliminate duplications


