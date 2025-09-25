import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
import 'package:pmj_music_player/utils/logger/logger.dart';
import 'package:pmj_music_player/utils/models/song/song_model.dart';

part 'metadata_extractor_helper.dart';
part 'fetch_artist_names_from_file.dart';
part 'fetch_album_names_from_file.dart';
part 'filename_parser.dart';
part 'album_art_handler.dart';
part 'metadata_utils.dart';
part 'metadata_parser.dart';

/// Professional metadata extractor for audio files using audiotags
/// Supports ID3v1, ID3v2, APE, Vorbis, iTunes/MP4, FLAC, and other formats
class MetadataExtractor {
  static final _logger = AppLogger('MetadataExtractor');
  static bool _initialized = false;

  /// Supported audio file extensions
  static const List<String> _supportedExtensions = [
    '.mp3', '.flac', '.m4a', '.mp4', '.aac', '.ogg', '.wav', '.wma', 
    '.opus', '.aiff', '.m4p', '.3gp', '.amr'
  ];

  /// ID3v1 genre mapping
  static const Map<String, String> _genreMap = {
    '0': 'Blues', '1': 'Classic Rock', '2': 'Country', '3': 'Dance', '4': 'Disco',
    '5': 'Funk', '6': 'Grunge', '7': 'Hip-Hop', '8': 'Jazz', '9': 'Metal',
    '10': 'New Age', '11': 'Oldies', '12': 'Other', '13': 'Pop', '14': 'R&B',
    '15': 'Rap', '16': 'Reggae', '17': 'Rock', '18': 'Techno', '19': 'Industrial',
    '20': 'Alternative', '21': 'Ska', '22': 'Death Metal', '23': 'Pranks',
    '24': 'Soundtrack', '25': 'Euro-Techno', '26': 'Ambient', '27': 'Trip-Hop',
    '28': 'Vocal', '29': 'Jazz+Funk', '30': 'Fusion', '31': 'Trance',
    '32': 'Classical', '33': 'Instrumental', '34': 'Acid', '35': 'House',
    '36': 'Game', '37': 'Sound Clip', '38': 'Gospel', '39': 'Noise',
    '40': 'AlternRock', '41': 'Bass', '42': 'Soul', '43': 'Punk', '44': 'Space',
    '45': 'Meditative', '46': 'Instrumental Pop', '47': 'Instrumental Rock',
    '48': 'Ethnic', '49': 'Gothic', '50': 'Darkwave', '51': 'Techno-Industrial',
    '52': 'Electronic', '53': 'Pop-Folk', '54': 'Eurodance', '55': 'Dream',
    '56': 'Southern Rock', '57': 'Comedy', '58': 'Cult', '59': 'Gangsta',
    '60': 'Top 40', '61': 'Christian Rap', '62': 'Pop/Funk', '63': 'Jungle',
    '64': 'Native American', '65': 'Cabaret', '66': 'New Wave', '67': 'Psychadelic',
    '68': 'Rave', '69': 'Showtunes', '70': 'Trailer', '71': 'Lo-Fi',
    '72': 'Tribal', '73': 'Acid Punk', '74': 'Acid Jazz', '75': 'Polka',
    '76': 'Retro', '77': 'Musical', '78': 'Rock & Roll', '79': 'Hard Rock',
  };

  /// Initialize metadata extractor
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      _logger.i('Initializing MetadataExtractor...');

      // Request Android permissions
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        _logger.d('Android version: $androidVersion');

        bool hasPermission = false;
        
        if (androidVersion >= 33) {
          hasPermission = await Permission.audio.isGranted;
          if (!hasPermission) {
            final status = await Permission.audio.request();
            hasPermission = status.isGranted;
          }
        } else if (androidVersion >= 30) {
          hasPermission = await Permission.manageExternalStorage.isGranted;
          if (!hasPermission) {
            final status = await Permission.manageExternalStorage.request();
            hasPermission = status.isGranted;
          }
        } else {
          hasPermission = await Permission.storage.isGranted;
          if (!hasPermission) {
            final status = await Permission.storage.request();
            hasPermission = status.isGranted;
          }
        }

        if (!hasPermission) {
          _logger.e('Required permissions not granted for Android $androidVersion');
          return false;
        }
        _logger.i('Android permissions granted');
      }

      _initialized = true;
      _logger.i('MetadataExtractor initialization completed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize MetadataExtractor', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Extract metadata from a single audio file
  static Future<Song?> extractMetadata(String filePath) async {
    return await _extractMetadataCore(filePath);
  }

  /// Extract metadata from multiple files with batch processing
  static Future<List<Song>> extractMetadataFromFiles(
    List<String> filePaths, {
    Function(int current, int total)? onProgress,
    int batchSize = 8,
  }) async {
    final songs = <Song>[];
    final total = filePaths.length;

    _logger.i('Extracting metadata from $total files...');

    for (int i = 0; i < filePaths.length; i += batchSize) {
      final batch = filePaths.skip(i).take(batchSize).toList();

      try {
        final batchResults = await Future.wait(
          batch.map((path) => _extractMetadataWithRetry(path)),
          eagerError: false,
        );

        final validSongs = batchResults.whereType<Song>().toList();
        songs.addAll(validSongs);

        final processed = i + batch.length;
        onProgress?.call(processed, total);
        _logger.d('Processed batch: $processed/$total (${validSongs.length} valid songs)');

        if (i + batchSize < filePaths.length) {
          await Future.delayed(const Duration(milliseconds: 30));
        }
      } catch (e) {
        _logger.e('Error processing batch starting at index $i: $e');
        for (final path in batch) {
          try {
            final song = await _extractMetadataWithRetry(path);
            if (song != null) songs.add(song);
          } catch (individualError) {
            _logger.w('Failed to process individual file: $path - $individualError');
          }
        }
      }
    }

    _logger.i('Successfully extracted metadata from ${songs.length}/$total files');
    return songs;
  }

  /// Extract metadata from directory
  static Future<List<Song>> extractMetadataFromDirectory(
    String directoryPath, {
    Function(int current, int total)? onProgress,
    bool recursive = true,
  }) async {
    _logger.i('Scanning directory: $directoryPath (recursive: $recursive)');

    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      _logger.w('Directory does not exist: $directoryPath');
      return [];
    }

    final audioFiles = <String>[];
    try {
      await for (final entity in directory.list(recursive: recursive, followLinks: false)) {
        if (entity is File && _isAudioFile(entity.path)) {
          audioFiles.add(entity.path);
        }
      }

      _logger.i('Found ${audioFiles.length} audio files in $directoryPath');
      if (audioFiles.isEmpty) return [];

      audioFiles.sort();
      return extractMetadataFromFiles(audioFiles, onProgress: onProgress);
    } catch (e, stackTrace) {
      _logger.e('Error reading directory $directoryPath', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Extract colors from album art using Material 3 ColorScheme
  static Future<Map<String, Color>> extractAlbumArtColors(String? albumArtPath) async {
    if (albumArtPath == null) return {};

    try {
      final file = File(albumArtPath);
      if (!await file.exists()) return {};

      _logger.d('Extracting colors from album art: $albumArtPath');

      final imageProvider = FileImage(file);
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.dark,
      );

      return {
        'primary': colorScheme.primary,
        'primaryContainer': colorScheme.primaryContainer,
        'secondary': colorScheme.secondary,
        'secondaryContainer': colorScheme.secondaryContainer,
        'tertiary': colorScheme.tertiary,
        'tertiaryContainer': colorScheme.tertiaryContainer,
        'surface': colorScheme.surface,
        'surfaceVariant': colorScheme.surfaceContainerHighest,
        'background': colorScheme.surface,
        'onPrimary': colorScheme.onPrimary,
        'onSurface': colorScheme.onSurface,
      };
    } catch (e, stackTrace) {
      _logger.e('Error extracting colors from album art: $albumArtPath', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Alternative color extraction using simple dominant color algorithm
  static Future<List<Color>> extractSimpleDominantColors(String? albumArtPath, {int maxColors = 5}) async {
    if (albumArtPath == null) return [];
    try {
      return [
        Colors.blue, Colors.purple, Colors.pink, Colors.orange, Colors.teal,
      ].take(maxColors).toList();
    } catch (e) {
      _logger.e('Error in simple color extraction: $e');
      return [];
    }
  }

  // === PRIVATE HELPER METHODS MOVED TO PART FILE ===

  // === PUBLIC UTILITY METHODS ===

  /// Get supported audio file extensions
  static List<String> get supportedExtensions => List.unmodifiable(_supportedExtensions);

  /// Get format group for a file
  static String getFormatGroup(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    const formatGroups = {
      'lossless': ['.flac', '.wav', '.aiff'],
      'lossy': ['.mp3', '.aac', '.ogg', '.opus', '.wma', '.amr'],
      'apple': ['.m4a', '.m4p'],
      'container': ['.mp4', '.3gp'],
    };

    for (final entry in formatGroups.entries) {
      if (entry.value.contains(extension)) return entry.key;
    }
    return 'unknown';
  }

  /// Check if format is lossless
  static bool isLosslessFormat(String filePath) => getFormatGroup(filePath) == 'lossless';

  /// Get quality description
  static String getQualityDescription(Song song) {
    final format = getFormatGroup(song.path);
    final bitrate = song.bitrate;

    if (format == 'lossless') return 'Lossless';
    if (bitrate == null) return 'Unknown Quality';
    if (bitrate >= 320) return 'High Quality (${bitrate}kbps)';
    if (bitrate >= 256) return 'Good Quality (${bitrate}kbps)';
    if (bitrate >= 192) return 'Standard Quality (${bitrate}kbps)';
    if (bitrate >= 128) return 'Acceptable Quality (${bitrate}kbps)';
    return 'Low Quality (${bitrate}kbps)';
  }

  /// Get file information
  static Map<String, dynamic> getFileInfo(Song song) {
    return {
      'format': getFormatGroup(song.path),
      'extension': song.path.split('.').last,
      'isLossless': isLosslessFormat(song.path),
      'quality': getQualityDescription(song),
      'fileSize': song.formattedFileSize,
      'duration': song.formattedDuration,
      'hasAlbumArt': song.hasAlbumArt,
      'bitrate': song.bitrate != null ? '${song.bitrate}kbps' : 'Unknown',
    };
  }

  /// Validate and repair song metadata
  static Future<Song> validateAndRepairSong(Song song) async {
    try {
      final file = File(song.path);
      if (!await file.exists()) {
        _logger.w('Song file no longer exists: ${song.path}');
        return song.copyWith(title: '${song.title} [FILE MISSING]');
      }

      // Check if metadata needs repair
      bool needsRepair = song.title.isEmpty || song.artists.isEmpty || song.albums.isEmpty;
      
      if (needsRepair) {
        _logger.d('Repairing missing metadata for: ${song.path}');
        
        // Extract metadata from filename as fallback
        final title = song.title.isEmpty ? _extractTitle(null, song.path) : song.title;
        final artists = song.artists.isEmpty ? _extractArtistsSafely(null, song.path) : song.artists;
        final albums = song.albums.isEmpty ? _extractAlbumsSafely(null, song.path) : song.albums;
        
        // Ensure we have at least some metadata
        final repairedTitle = title.isEmpty ? 'Unknown Title' : title;
        final repairedArtists = artists.isEmpty ? ['Unknown Artist'] : artists;
        final repairedAlbums = albums.isEmpty ? ['Unknown Album'] : albums;
        
        _logger.d('Repaired metadata - Title: $repairedTitle, Artists: $repairedArtists, Albums: $repairedAlbums');
        
        return song.copyWith(
          title: repairedTitle,
          artists: repairedArtists,
          albums: repairedAlbums,
        );
      }

      // Handle album art repair
      String? validAlbumArt = song.albumArt;
      if (song.albumArt != null) {
        final artFile = File(song.albumArt!);
        if (!await artFile.exists()) {
          _logger.d('Album art file missing, will be re-extracted: ${song.albumArt}');
          validAlbumArt = null;
        }
      }

      if (validAlbumArt == null && await file.exists()) {
        try {
          final tag = await AudioTags.read(song.path);
          if (tag != null) {
            validAlbumArt = await _extractAlbumArt(song.path, tag);
            if (validAlbumArt != null) {
              _logger.d('Re-extracted album art for: ${song.title}');
            }
          }
        } catch (e) {
          _logger.w('Failed to re-extract album art for: ${song.title} - $e');
        }
      }

      return song.copyWith(albumArt: validAlbumArt);
    } catch (e) {
      _logger.e('Error validating song: ${song.title} - $e');
      return song;
    }
  }

  /// Cleanup unused album art
  static Future<void> cleanupAlbumArt(List<Song> currentSongs) async {
    try {
      _logger.i('Starting album art cleanup...');

      final appDir = await getApplicationDocumentsDirectory();
      final albumArtDir = Directory('${appDir.path}/album_art');

      if (!await albumArtDir.exists()) {
        _logger.d('Album art directory does not exist, nothing to clean up');
        return;
      }

      final currentArtPaths = currentSongs
          .where((song) => song.albumArt != null)
          .map((song) => song.albumArt!)
          .toSet();

      int deletedCount = 0;
      int totalSize = 0;

      await for (final file in albumArtDir.list()) {
        if (file is File && !currentArtPaths.contains(file.path)) {
          try {
            final stat = await file.stat();
            totalSize += stat.size;
            await file.delete();
            deletedCount++;
            _logger.d('Deleted unused album art: ${file.path.split('/').last}');
          } catch (e) {
            _logger.w('Failed to delete album art file: ${file.path} - $e');
          }
        }
      }

      _logger.i(
        'Album art cleanup completed: deleted $deletedCount files, freed ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
    } catch (e, stackTrace) {
      _logger.e('Error during album art cleanup', error: e, stackTrace: stackTrace);
    }
  }

  /// Get comprehensive library statistics
  static Map<String, dynamic> getLibraryStats(List<Song> songs) {
    final stats = <String, dynamic>{
      'totalSongs': songs.length,
      'totalDuration': songs.fold<Duration>(Duration.zero, (sum, song) => sum + song.duration),
      'totalSize': songs.fold<int>(0, (sum, song) => sum + (song.fileSize ?? 0)),
      'formats': <String, int>{},
      'genres': <String, int>{},
      'years': <int, int>{},
      'artists': <String, int>{},
      'albums': <String, int>{},
      'withAlbumArt': songs.where((s) => s.hasAlbumArt).length,
      'averageBitrate': 0,
      'losslessCount': 0,
    };

    for (final song in songs) {
      final format = getFormatGroup(song.path);
      stats['formats'][format] = (stats['formats'][format] ?? 0) + 1;

      if (isLosslessFormat(song.path)) stats['losslessCount']++;

      if (song.genre != null) {
        stats['genres'][song.genre!] = (stats['genres'][song.genre!] ?? 0) + 1;
      }

      if (song.year != null) {
        stats['years'][song.year!] = (stats['years'][song.year!] ?? 0) + 1;
      }
    }

    final allArtists = <String>{};
    final allAlbums = <String>{};
    for (final song in songs) {
      allArtists.addAll(song.artists);
      allAlbums.addAll(song.albums);
    }

    stats['uniqueArtists'] = allArtists.length;
    stats['uniqueAlbums'] = allAlbums.length;

    final songsWithBitrate = songs.where((s) => s.bitrate != null);
    if (songsWithBitrate.isNotEmpty) {
      stats['averageBitrate'] = songsWithBitrate.map((s) => s.bitrate!).reduce((a, b) => a + b) ~/ songsWithBitrate.length;
    }

    return stats;
  }

  /// Get initialization status
  static bool get isInitialized => _initialized;

  /// Validate if a file is a valid audio file
  static Future<bool> isValidAudioFile(String filePath) async => await _isValidAudioFile(filePath);

  /// Force re-initialization
  static Future<bool> reinitialize() async {
    _initialized = false;
    return await initialize();
  }
}