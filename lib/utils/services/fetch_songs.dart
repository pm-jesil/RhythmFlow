import 'dart:io';
import '../models/song/song_model.dart';
import '../logger/logger.dart';
import 'metadata_extractor/metadata_extractor.dart';
import 'format_utils.dart';
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
  }) async {
    _logger.i('🚀 Starting optimized progressive song fetching...');

    try {
      // Step 1: Get all song file paths first
      final songPaths = await fetchSongsPath(
        whitelistedFolders: whitelistedFolders,
        supportedFormats: supportedFormats,
      );

      if (songPaths.isEmpty) {
        _logger.w('⚠️ No song paths found');
        onProgress([], true, 0);
        return;
      }

      _logger.i('📋 Found ${songPaths.length} song paths, starting progressive metadata extraction...');

      // Step 2: Process metadata extraction in batches of 10
      final List<Song> allSongs = [];
      const int batchSize = 10;
      int totalProcessed = 0;

      for (int i = 0; i < songPaths.length; i += batchSize) {
        final batch = songPaths.skip(i).take(batchSize).toList();
        final batchNumber = (i ~/ batchSize) + 1;
        final totalBatches = (songPaths.length / batchSize).ceil();
        
        _logger.d('🔄 Processing batch $batchNumber/$totalBatches: ${batch.length} files');

        final List<Song> batchSongs = [];

        // Process each file in the batch
        for (final filePath in batch) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              final song = await processFile(file, supportedFormats: supportedFormats);
              if (song != null) {
                batchSongs.add(song);
                allSongs.add(song);
              }
            }
          } catch (e) {
            _logger.w('⚠️ Error processing file $filePath: $e');
          }
        }

        // Apply filters to current batch
        final filteredBatch = _applyFilters(batchSongs);
        totalProcessed += filteredBatch.length;

        // Report progress for this batch
        final isComplete = (i + batchSize) >= songPaths.length;
        onProgress(filteredBatch, isComplete, totalProcessed);

        _logger.d('📀 Batch $batchNumber completed: ${filteredBatch.length} songs (Total: $totalProcessed)');

        // Small delay to prevent UI blocking
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
  static Future<Map<String, dynamic>> fetchNewSongs(List<Song> existingSongs, {List<String>? supportedFormats, Map<String, List<String>>? whitelistedFolders}) async {
    _logger.i('🆕 Starting optimized new songs fetch (excluding ${existingSongs.length} existing songs)');

    try {
      // Step 1: Get all song file paths first
      final songPaths = await fetchSongsPath(
        whitelistedFolders: whitelistedFolders,
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

      // Step 3: Process metadata extraction for new songs only
      final List<Song> newSongs = [];
      const int batchSize = 10;
      
      for (int i = 0; i < newSongPaths.length; i += batchSize) {
        final batch = newSongPaths.skip(i).take(batchSize).toList();
        _logger.d('🔄 Processing new songs batch ${(i ~/ batchSize) + 1}/${(newSongPaths.length / batchSize).ceil()}: ${batch.length} files');

        // Process each file in the batch
        for (final filePath in batch) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              final song = await processFile(file, supportedFormats: supportedFormats);
              if (song != null) {
                newSongs.add(song);
              }
            }
          } catch (e) {
            _logger.w('⚠️ Error processing new file $filePath: $e');
          }
        }

        // Small delay to prevent UI blocking
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
  static Future<List<String>> getAllFoldersFromWhitelist(Map<String, List<String>> whitelistedFolders) async {
    final List<String> allFolders = [];
    
    try {
      // Get platform-specific whitelisted folders
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final platformFolders = whitelistedFolders[platform] ?? [];
      _logger.d('🔍 Processing whitelisted folders for $platform: $platformFolders');

      // Process each whitelisted folder recursively
      for (final whitelistFolder in platformFolders) {
        final directory = Directory(whitelistFolder);
      if (await directory.exists()) {
          _logger.d('📁 Scanning whitelist folder: $whitelistFolder');
          
          // Add the whitelist folder itself
          allFolders.add(whitelistFolder);
          
          // Recursively find all subdirectories
          final subFolders = await _getAllSubdirectories(whitelistFolder);
          allFolders.addAll(subFolders);
          
          _logger.d('📂 Found ${subFolders.length} subdirectories in $whitelistFolder');
        } else {
          _logger.w('⚠️ Whitelist folder does not exist: $whitelistFolder');
        }
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
  static Future<List<String>> _getAllSubdirectories(String folderPath) async {
    final List<String> subdirectories = [];
    
    try {
      final directory = Directory(folderPath);
      await for (final entity in directory.list(recursive: true)) {
        if (entity is Directory) {
          subdirectories.add(entity.path);
        }
      }
    } catch (e) {
      _logger.w('⚠️ Error scanning subdirectories in $folderPath: $e');
    }
    
    return subdirectories;
  }


  /// PUBLIC FUNCTION: Fetch all song file paths from whitelisted folders
  /// This function finds all audio files in the comprehensive folder list
  static Future<List<String>> fetchSongsPath({
    Map<String, List<String>>? whitelistedFolders,
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
      final allFolders = await getAllFoldersFromWhitelist(whitelistedFolders ?? {});
      if (allFolders.isEmpty) {
        _logger.w('⚠️ No folders found in whitelist');
        return [];
      }

      final List<String> allSongPaths = [];
      final formats = supportedFormats ?? FormatUtils.defaultSupportedFormats;

      _logger.i('🔍 Scanning ${allFolders.length} folders for audio files...');

      // Process each folder to find audio files
      for (final folder in allFolders) {
        try {
          final directory = Directory(folder);
          if (!await directory.exists()) {
            _logger.w('⚠️ Folder does not exist: $folder');
            continue;
          }

          _logger.d('📁 Scanning folder: $folder');
          int fileCount = 0;

          await for (final entity in directory.list(recursive: false)) {
            if (entity is File) {
              final filePath = entity.path.toLowerCase();
              
              // Check if file is a supported audio format
              if (formats.any((format) => filePath.endsWith(format))) {
                // Skip video files
                if (!videoFormats.any((format) => filePath.endsWith(format))) {
                  allSongPaths.add(entity.path);
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

  /// Scan a folder for music files
  static Future<List<Song>> scanFolderForSongs(String folderPath, {List<String>? supportedFormats}) async {
    final List<Song> songs = [];

    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        _logger.w('Folder does not exist: $folderPath');
        return songs;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final song = await processFile(entity, supportedFormats: supportedFormats);
          if (song != null) {
            songs.add(song);
          }
        }
      }
    } catch (e) {
      _logger.e('Error scanning folder: $folderPath', error: e);
    }

    return songs;
  }

  /// Process a file to extract song information using enhanced metadata extraction
  static Future<Song?> processFile(File file, {List<String>? supportedFormats}) async {
    try {
      final path = file.path.toLowerCase();

      // Check if file is a video format (exclude)
      if (videoFormats.any((format) => path.endsWith(format))) {
        _logger.d('⏭️ Skipping video file: ${file.path}');
        return null;
      }

      // Use provided formats or default
      final formats = supportedFormats ?? FormatUtils.defaultSupportedFormats;

      // Check if file is a supported audio format
      if (!formats.any((format) => path.endsWith(format))) {
        return null;
      }

      // Skip invalid audio files (using provided formats)
      if (!await _isValidAudioFileWithFormats(file.path, formats)) {
        _logger.d('Skipping invalid audio file: ${file.path}');
        return null;
      }

      // Use enhanced metadata extraction
      final song = await MetadataExtractor.extractMetadata(file.path);

      return song;
    } catch (e) {
      _logger.e('Error processing file: ${file.path}', error: e);
      return null;
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



  /// Validate if file is a valid audio file using provided formats
  static Future<bool> _isValidAudioFileWithFormats(String filePath, List<String> supportedFormats) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      if (stat.size < 1024) return false;

      // Check if file extension is in supported formats
      final extension = '.${filePath.split('.').last.toLowerCase()}';
      if (!supportedFormats.contains(extension)) return false;

      // Basic header validation for common formats
      final bytes = await file.openRead(0, 12).first;
      return _validateAudioHeader(bytes, extension);
    } catch (e) {
      return false;
    }
  }

  /// Validate audio file header for common formats
  static bool _validateAudioHeader(List<int> header, String extension) {
    if (header.length < 4) return false;

    switch (extension) {
      case '.mp3':
        // ID3v2 tag or MP3 frame header
        if (header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) return true;
        if (header[0] == 0xFF && (header[1] & 0xE0) == 0xE0) return true;
        return false;
      case '.flac':
        return header[0] == 0x66 && header[1] == 0x4C && header[2] == 0x61 && header[3] == 0x43;
      case '.ogg':
        return header[0] == 0x4F && header[1] == 0x67 && header[2] == 0x67 && header[3] == 0x53;
      case '.wav':
        return header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46;
      case '.m4a':
      case '.m4p':
        return header.length >= 8 && header[4] == 0x66 && header[5] == 0x74 && 
               header[6] == 0x79 && header[7] == 0x70;
      default:
        return true; // For other formats, assume valid if extension matches
    }
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
