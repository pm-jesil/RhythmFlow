import 'dart:collection';
import 'dart:io';
import 'package:music_feature_analyzer/music_feature_analyzer.dart';
import '../models/song/song_model.dart';
import '../logger/logger.dart';
import 'format_utils.dart';
import 'music_metadata_service.dart';
import 'song_cleanup_service.dart';
import 'permission_service.dart';

class FetchSongsService {
  static final AppLogger _logger = AppLogger('FetchSongsService');

  // Supported audio formats are now managed by FormatUtils

  // Video file extensions to exclude
  static const List<String> videoFormats = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp',
    '.ts',
    '.mts',
    '.m2ts',
    '.vob',
    '.ogv',
  ];

  // Minimum and maximum song duration filters
  static const Duration minDuration = Duration(seconds: 2);
  static const Duration maxDuration = Duration(hours: 1);



  /// OPTIMIZED: Fetch songs progressively with new flow and batch updates
  static Future<void> fetchAllSongsProgressive({
    required Function(List<Song>, bool, int) onProgress,
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
    Map<String, List<String>>? blockedFolders,
  }) async {
    _logger.i('🚀 Starting optimized progressive song fetching...');

    try {
      // Step 1: Get all song file paths first
      final songPaths = await fetchSongsPath(
        whitelistedFolders: whitelistedFolders,
        blockedFolders: blockedFolders,
        supportedFormats: supportedFormats,
      );

      if (songPaths.isEmpty) {
        _logger.w('⚠️ No song paths found');
        onProgress([], true, 0);
        return;
      }

      _logger.i('📋 Found ${songPaths.length} song paths, starting progressive metadata extraction...');

      // Step 2: Extract metadata in batches using music_feature_analyzer
      final List<Song> allSongs = [];
      const int batchSize = 10;
      int totalProcessed = 0;

      for (int i = 0; i < songPaths.length; i += batchSize) {
        final batchPaths = songPaths.skip(i).take(batchSize).toList();
        final batchNumber = (i ~/ batchSize) + 1;
        final totalBatches = (songPaths.length / batchSize).ceil();

        _logger.d('🔄 Processing batch $batchNumber/$totalBatches: ${batchPaths.length} files');

        final List<Song> batchSongs = [];
        try {
          final results = await MusicFeatureAnalyzer.extractMetadataBatch(batchPaths);
          for (final model in results) {
            final song = MusicMetadataService.songModelToSong(model);
            if (song != null) {
              batchSongs.add(song);
              allSongs.add(song);
            }
          }
        } catch (e) {
          _logger.w('⚠️ Error in metadata batch: $e');
        }

        final filteredBatch = _applyFilters(batchSongs);
        totalProcessed += filteredBatch.length;

        final isComplete = (i + batchSize) >= songPaths.length;
        onProgress(filteredBatch, isComplete, totalProcessed);

        _logger.d('📀 Batch $batchNumber completed: ${filteredBatch.length} songs (Total: $totalProcessed)');

        if (!isComplete) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Final progress update
      _logger.i('🎵 Progressive fetching completed: ${allSongs.length} total songs');
      onProgress([], true, totalProcessed);
      
    } catch (e) {
      _logger.e('❌ Error in optimized progressive song fetching', error: e);
      onProgress([], true, 0);
    }
  }

  /// OPTIMIZED: Fetch only new songs with new flow
  /// Returns a map with 'newSongs' and 'invalidSongIds' for comprehensive cleanup
  static Future<Map<String, dynamic>> fetchNewSongs(
    List<Song> existingSongs, {
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
    Map<String, List<String>>? blockedFolders,
  }) async {
    _logger.i('🆕 Starting optimized new songs fetch (excluding ${existingSongs.length} existing songs)');

    try {
      // Step 1: Get all song file paths first
      final songPaths = await fetchSongsPath(
        whitelistedFolders: whitelistedFolders,
        blockedFolders: blockedFolders,
        supportedFormats: supportedFormats,
      );

      if (songPaths.isEmpty) {
        _logger.w('⚠️ No song paths found');
        return {
          'newSongs': <Song>[],
          'invalidSongIds': <String>[],
        };
      }

      _logger.i('📋 Found ${songPaths.length} song paths, checking for new songs...');

      // Step 2: Validate existing song paths and create set for quick lookup
      final validatedExistingSongs = await _validateExistingSongs(existingSongs);
      final existingSongPaths = validatedExistingSongs.map((song) => song.path).toSet();
      
      // Find invalid songs that were removed from device
      final invalidSongIds = existingSongs
          .where((song) => !validatedExistingSongs.any((validSong) => validSong.id == song.id))
          .map((song) => song.id)
          .toList();
      
      if (invalidSongIds.isNotEmpty) {
        _logger.w('⚠️ Found ${invalidSongIds.length} invalid songs that need cleanup: $invalidSongIds');
      }
      
      final newSongPaths = songPaths.where((path) => !existingSongPaths.contains(path)).toList();

      if (newSongPaths.isEmpty) {
        _logger.i('✅ No new songs found');
        return {
          'newSongs': <Song>[],
          'invalidSongIds': invalidSongIds,
        };
      }

      _logger.i('🆕 Found ${newSongPaths.length} new song paths, extracting metadata...');

      // Step 3: Extract metadata in batches using music_feature_analyzer
      final List<Song> newSongs = [];
      const int batchSize = 10;

      for (int i = 0; i < newSongPaths.length; i += batchSize) {
        final batchPaths = newSongPaths.skip(i).take(batchSize).toList();
        _logger.d('🔄 Processing new songs batch ${(i ~/ batchSize) + 1}/${(newSongPaths.length / batchSize).ceil()}: ${batchPaths.length} files');

        try {
          final results = await MusicFeatureAnalyzer.extractMetadataBatch(batchPaths);
          for (final model in results) {
            final song = MusicMetadataService.songModelToSong(model);
            if (song != null) newSongs.add(song);
          }
        } catch (e) {
          _logger.w('⚠️ Error in new songs metadata batch: $e');
        }

        if (i + batchSize < newSongPaths.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Step 4: Apply filters to new songs
      final filteredNewSongs = _applyFilters(newSongs);
      _logger.i('✅ Found ${filteredNewSongs.length} new songs after filtering');

      return {
        'newSongs': filteredNewSongs,
        'invalidSongIds': invalidSongIds,
      };
    } catch (e) {
      _logger.e('❌ Error in optimized new songs fetch', error: e);
      return {
        'newSongs': <Song>[],
        'invalidSongIds': <String>[],
      };
    }
  }


  /// Get all folders recursively from whitelisted folders
  /// This function creates a comprehensive list of all subdirectories
  static Future<List<String>> getAllFoldersFromWhitelist(
    Map<String, List<String>> whitelistedFolders, {
    Map<String, List<String>>? blockedFolders,
  }) async {
    final List<String> allFolders = [];
    final platformKey = _resolvePlatformKey();
    final platformFolders = whitelistedFolders[platformKey] ?? [];
    final platformBlocked =
        (blockedFolders ?? const {})[platformKey] ?? <String>[];
    final blockedNormalized = <String>{
      ...platformBlocked.map(_normalizePath),
      ..._defaultBlockedFolders(platformKey).map(_normalizePath),
    };

    try {
      _logger.d(
        '🔍 Processing whitelisted folders for $platformKey: $platformFolders',
      );

      // Process each whitelisted folder recursively
      for (final whitelistFolder in platformFolders) {
        final normalizedFolder = _normalizePath(whitelistFolder);
        if (_isHiddenPath(normalizedFolder)) {
          _logger.d('⏭️ Skipping hidden folder: $normalizedFolder');
          continue;
        }

        if (_isBlockedPath(normalizedFolder, blockedNormalized)) {
          _logger.d('⏭️ Skipping blocked folder: $normalizedFolder');
          continue;
        }

        final directory = Directory(normalizedFolder);
        if (!await directory.exists()) {
          _logger.w('⚠️ Whitelist folder does not exist: $normalizedFolder');
          continue;
        }

        _logger.d('📁 Scanning whitelist folder: $normalizedFolder');

        // Add the whitelist folder itself
        allFolders.add(normalizedFolder);

        // Recursively find all subdirectories
        final subFolders = await _getAllSubdirectories(
          normalizedFolder,
          blockedNormalized,
        );
        allFolders.addAll(subFolders);

        _logger.d(
          '📂 Found ${subFolders.length} subdirectories in $normalizedFolder',
        );
      }

      // Remove duplicates and sort
      final uniqueFolders = allFolders.toSet().toList();
      uniqueFolders.sort();
      
      _logger.i('✅ Total folders to scan: ${uniqueFolders.length}');
      _logger.d('📋 All folders: $uniqueFolders');
      
      return uniqueFolders;
    } catch (e) {
      _logger.e('❌ Error getting folders from whitelist', error: e);
      return [];
    }
  }

  /// Recursively get all subdirectories from a given folder
  static Future<List<String>> _getAllSubdirectories(
    String folderPath,
    Set<String> blockedFolders,
  ) async {
    final List<String> subdirectories = [];
    final Queue<String> pending = Queue<String>();
    final String normalizedRoot = _normalizePath(folderPath);
    final Set<String> visited = {normalizedRoot};
    pending.add(normalizedRoot);

    while (pending.isNotEmpty) {
      final currentPath = pending.removeFirst();
      final directory = Directory(currentPath);

      try {
        await for (final entity in directory
            .list(followLinks: false)
            .handleError((error, stackTrace) {
          _logger.w(
            '⚠️ Error scanning subdirectories in $currentPath: $error',
            error: error,
            stackTrace: stackTrace,
          );
        }, test: (error) => error is FileSystemException)) {
          if (entity is Directory) {
            final normalizedPath = _normalizePath(entity.path);

            if (_isHiddenPath(normalizedPath)) {
              continue;
            }

            if (_isBlockedPath(normalizedPath, blockedFolders)) {
              _logger.d('⏭️ Skipping blocked subdirectory: $normalizedPath');
              continue;
            }

            if (visited.add(normalizedPath)) {
              subdirectories.add(normalizedPath);
              pending.add(normalizedPath);
            }
          }
        }
      } catch (e) {
        _logger.w('⚠️ Error scanning subdirectories in $currentPath: $e');
      }
    }

    return subdirectories;
  }


  /// PUBLIC FUNCTION: Fetch all song file paths from whitelisted folders
  /// This function finds all audio files in the comprehensive folder list
  static Future<List<String>> fetchSongsPath({
    Map<String, List<String>>? whitelistedFolders,
    Map<String, List<String>>? blockedFolders,
    List<String>? supportedFormats,
  }) async {
    _logger.i('🎵 Starting to fetch song paths from device...');

    try {
      // Check permissions first
      if (!await PermissionService.hasAllRequiredPermissions()) {
        _logger.w('❌ Permissions not granted, cannot fetch song paths');
        return [];
      }

      // Get comprehensive folder list from whitelist
      final allFolders = await getAllFoldersFromWhitelist(
        whitelistedFolders ?? {},
        blockedFolders: blockedFolders,
      );
      if (allFolders.isEmpty) {
        _logger.w('⚠️ No folders found in whitelist');
        return [];
      }

      final List<String> allSongPaths = [];
      final formats = supportedFormats ?? FormatUtils.defaultSupportedFormats;
      final platformKey = _resolvePlatformKey();
      final platformBlocked =
          (blockedFolders ?? const {})[platformKey] ?? <String>[];
      final blockedNormalized = <String>{
        ...platformBlocked.map(_normalizePath),
        ..._defaultBlockedFolders(platformKey).map(_normalizePath),
      };

      _logger.i('🔍 Scanning ${allFolders.length} folders for audio files...');

      // Process each folder to find audio files
      for (final folder in allFolders) {
        if (_isBlockedPath(folder, blockedNormalized)) {
          _logger.d('⏭️ Skipping blocked folder during scan: $folder');
          continue;
        }

        try {
          final directory = Directory(folder);
          if (!await directory.exists()) {
            _logger.w('⚠️ Folder does not exist: $folder');
            continue;
          }

          _logger.d('📁 Scanning folder: $folder');
          int fileCount = 0;

          await for (final entity in directory
              .list(recursive: false, followLinks: false)
              .handleError((error, stackTrace) {
            _logger.w(
              '⚠️ Error reading folder $folder: $error',
              error: error,
              stackTrace: stackTrace,
            );
          }, test: (error) => error is FileSystemException)) {
            if (entity is File) {
              final normalizedFilePath = _normalizePath(entity.path);

              if (_isHiddenPath(normalizedFilePath)) {
                continue;
              }

              if (_isBlockedPath(normalizedFilePath, blockedNormalized)) {
                continue;
              }

              final filePath = normalizedFilePath.toLowerCase();
              
              // Check if file is a supported audio format
              if (formats.any((format) => filePath.endsWith(format))) {
                // Skip video files
                if (!videoFormats.any((format) => filePath.endsWith(format))) {
                  allSongPaths.add(normalizedFilePath);
                  fileCount++;
                }
              }
            }
          }

          _logger.d('🎵 Found $fileCount audio files in $folder');
        } catch (e) {
          _logger.e('❌ Error scanning folder $folder', error: e);
        }
      }

      // Remove duplicates and sort
      final uniquePaths = allSongPaths.toSet().toList();
      uniquePaths.sort();

      _logger.i('✅ Found ${uniquePaths.length} unique audio files');
      return uniquePaths;
    } catch (e) {
      _logger.e('❌ Error fetching song paths', error: e);
      return [];
    }
  }

  /// Apply filters to song list
  static List<Song> _applyFilters(List<Song> songs) {
    _logger.d('Applying filters to ${songs.length} songs');

    // First apply basic filters
    final basicFilteredSongs = songs.where((song) {
      // Duration filter
      if (song.duration < minDuration || song.duration > maxDuration) {
        _logger.d(
          'Song filtered out due to duration: ${song.title} (${song.duration})',
        );
        return false;
      }

      // File size filter (optional - skip very small or very large files)
      if (song.fileSize != null) {
        const minFileSize = 1024 * 10; // 10 KB minimum
        const maxFileSize = 1024 * 1024 * 100; // 100 MB maximum

        if (song.fileSize! < minFileSize || song.fileSize! > maxFileSize) {
          _logger.d(
            'Song filtered out due to file size: ${song.title} (${song.fileSize} bytes)',
          );
          return false;
        }
      }

      // Title and artist filter (skip songs with empty or invalid metadata)
      if (song.title.isEmpty || song.artists.isEmpty) {
        _logger.d(
          'Song filtered out due to missing metadata: ${song.title} - ${song.artists.join(', ')}',
        );
        return false;
      }

      return true;
    }).toList();

    _logger.d('Songs after basic filtering: ${basicFilteredSongs.length}');

    // Then remove duplicates by title (exact or fuzzy matching)
    final uniqueSongs = _useFuzzyMatching 
        ? SongCleanupService.removeDuplicatesSongsFuzzy(basicFilteredSongs)
        : SongCleanupService.removeDuplicateSongsByTitle(basicFilteredSongs);
    _logger.d('Songs after duplicate removal: ${uniqueSongs.length}');

    return uniqueSongs;
  }





  /// Set duplicate detection mode
  static final bool _useFuzzyMatching = false;

  static List<String> _defaultBlockedFolders(String platformKey) {
    if (platformKey == 'android') {
      return const [
        '/storage/emulated/0/Android',
        '/storage/emulated/0/Android/data',
        '/storage/emulated/0/Android/obb',
        '/storage/emulated/0/Android/media',
        '/storage/emulated/0/MIUI',
        '/storage/emulated/0/LOST.DIR',
      ];
    }

    if (platformKey == 'ios') {
      return const [
        '/var/mobile/Media/DCIM',
        '/var/mobile/Media/PhotoData',
        '/var/mobile/Media/Books',
      ];
    }

    return const [];
  }

  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.length > 1) {
      normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    }
    return normalized;
  }

  static bool _isHiddenPath(String path) {
    final normalized = _normalizePath(path);
    final segments = normalized.split('/');
    for (final segment in segments) {
      if (segment.isEmpty) continue;
      if (segment.startsWith('.')) {
        return true;
      }
    }
    return false;
  }

  static bool _isBlockedPath(String path, Set<String> blockedFolders) {
    if (blockedFolders.isEmpty) return false;
    final normalized = _normalizePath(path);
    for (final blocked in blockedFolders) {
      if (normalized == blocked ||
          normalized.startsWith('$blocked/')) {
        return true;
      }
    }
    return false;
  }

  static String _resolvePlatformKey() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'android';
  }

  /// Validate existing songs to ensure their files still exist and are accessible
  /// This prevents processing songs that have been moved, deleted, or are inaccessible
  static Future<List<Song>> _validateExistingSongs(List<Song> existingSongs) async {
    _logger.i('🔍 Validating ${existingSongs.length} existing songs...');
    
    final List<Song> validSongs = [];
    final List<String> invalidPaths = [];
    
    for (final song in existingSongs) {
      try {
        final file = File(song.path);
        
        // Check if file exists
        if (!await file.exists()) {
          _logger.w('⚠️ Song file no longer exists: ${song.path}');
          invalidPaths.add(song.path);
          continue;
        }
        
        // Check if file is accessible (can read basic properties)
        try {
          final stat = await file.stat();
          if (stat.size < 1024) { // Less than 1KB is likely invalid
            _logger.w('⚠️ Song file too small (${stat.size} bytes): ${song.path}');
            invalidPaths.add(song.path);
            continue;
          }
        } catch (e) {
          _logger.w('⚠️ Cannot access song file: ${song.path} - $e');
          invalidPaths.add(song.path);
          continue;
        }
        
        // File is valid, keep it
        validSongs.add(song);
        
      } catch (e) {
        _logger.w('⚠️ Error validating song: ${song.path} - $e');
        invalidPaths.add(song.path);
      }
    }
    
    final removedCount = existingSongs.length - validSongs.length;
    if (removedCount > 0) {
      _logger.i('🗑️ Removed $removedCount invalid songs from existing list');
      _logger.d('Invalid paths: $invalidPaths');
    } else {
      _logger.i('✅ All existing songs are still valid');
    }
    
    return validSongs;
  }


}
