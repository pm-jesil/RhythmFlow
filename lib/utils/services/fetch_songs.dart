import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/song/song_model.dart';
import '../logger/logger.dart';
import 'metadata_extractor/metadata_extractor.dart';
import 'format_utils.dart';
import 'song_cleanup_service.dart';

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


  /// Request all required permissions for song fetching
  static Future<bool> requestAllRequiredPermissions() async {
    _logger.i('Requesting all required permissions');

    try {
      // First check if permissions are already granted
      final alreadyGranted = await _checkPermissions();
      if (alreadyGranted) {
        _logger.i('Permissions already granted');
        return true;
      }

      // Check Android version for appropriate permissions
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        _logger.d('Android version: $androidVersion');

        if (androidVersion >= 33) {
          // Android 13+ (API 33+)
          return await _requestAndroid13Permissions();
        } else if (androidVersion >= 30) {
          // Android 11+ (API 30-32)
          return await _requestAndroid11Permissions();
        } else {
          return await _requestLegacyAndroidPermissions();
        }
      } else if (Platform.isIOS) {
        return await _requestIOSPermissions();
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting permissions', error: e);
      // If permission request fails, check if we already have permissions
      _logger.i('Checking if permissions are already granted...');
      try {
        return await _checkPermissions();
      } catch (checkError) {
        _logger.e('Error checking permissions', error: checkError);
        return false;
      }
    }
  }

  /// Fetch all songs from device folders
  static Future<List<Song>> fetchAllSongs({List<String>? supportedFormats, Map<String, List<String>>? whitelistedFolders}) async {
    _logger.i('Starting to fetch all songs');

    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        _logger.w('Permissions not granted, cannot fetch songs');
        return [];
      }

      final List<Song> allSongs = [];
      final List<String> foldersToScan = await _getFoldersToScan(whitelistedFolders ?? {});

      for (final folder in foldersToScan) {
        _logger.d('Scanning folder: $folder');
        final songs = await scanFolderForSongs(folder, supportedFormats: supportedFormats);
        allSongs.addAll(songs);
        _logger.d('Found ${songs.length} songs in $folder');
      }

      // Apply filters
      final filteredSongs = _applyFilters(allSongs);
      _logger.i('Total songs after filtering: ${filteredSongs.length}');

      return filteredSongs;
    } catch (e) {
      _logger.e('Error fetching songs', error: e);
      return [];
    }
  }

  /// Fetch songs progressively with callback for each batch
  static Future<void> fetchAllSongsProgressive({
    required Function(List<Song>, bool, int) onProgress,
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
  }) async {
    _logger.i('🚀 Starting progressive song fetching...');

    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        _logger.w('Permissions not granted, cannot fetch songs');
        onProgress([], true, 0);
        return;
      }

      final List<Song> allSongs = [];
      final List<String> foldersToScan = await _getFoldersToScan(whitelistedFolders ?? {});
      const int batchSize = 10;
      int totalProcessed = 0;

      for (final folder in foldersToScan) {
        _logger.d('📁 Scanning folder: $folder');
        
        try {
          final directory = Directory(folder);
          if (!await directory.exists()) {
            _logger.w('Folder does not exist: $folder');
            continue;
          }

          final List<Song> folderSongs = [];
          int fileCount = 0;

          await for (final entity in directory.list(recursive: true)) {
            if (entity is File) {
              final song = await processFile(entity);
              if (song != null) {
                folderSongs.add(song);
                fileCount++;
                
                // Send progress update every 10 songs
                if (fileCount % batchSize == 0) {
                  totalProcessed += batchSize;
                  _logger.d('📀 Progress: $fileCount songs processed from $folder');
                  
                  // Apply filters to current batch
                  final filteredBatch = _applyFilters(folderSongs);
                  allSongs.addAll(filteredBatch);
                  
                  // Report progress
                  onProgress(filteredBatch, false, totalProcessed);
                  
                  // Small delay to prevent UI blocking
                  await Future.delayed(const Duration(milliseconds: 100));
                }
              }
            }
          }

          // Process remaining songs in the folder
          if (fileCount % batchSize != 0) {
            final remainingCount = fileCount % batchSize;
            totalProcessed += remainingCount;
            
            final filteredRemaining = _applyFilters(folderSongs);
            allSongs.addAll(filteredRemaining);
            
            _logger.d('📀 Final batch from $folder: $remainingCount songs');
            onProgress(filteredRemaining, false, totalProcessed);
          }

          _logger.d('✅ Completed folder $folder: $fileCount songs');
        } catch (e) {
          _logger.e('❌ Error scanning folder: $folder', error: e);
        }
      }

      // Final progress update
      _logger.i('🎵 Progressive fetching completed: ${allSongs.length} total songs');
      onProgress([], true, allSongs.length);
      
    } catch (e) {
      _logger.e('❌ Error in progressive song fetching', error: e);
      onProgress([], true, 0);
    }
  }

  /// Fetch only new songs (not present in existing songs list)
  static Future<List<Song>> fetchNewSongs(List<Song> existingSongs, {List<String>? supportedFormats, Map<String, List<String>>? whitelistedFolders}) async {
    _logger.i(
      'Starting to fetch new songs (excluding ${existingSongs.length} existing songs)',
    );

    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        _logger.w('Permissions not granted, cannot fetch songs');
        return [];
      }

      final List<Song> allSongs = [];
      final List<String> foldersToScan = await _getFoldersToScan(whitelistedFolders ?? {});

      for (final folder in foldersToScan) {
        _logger.d('Scanning folder: $folder');
        final songs = await scanFolderForSongs(folder, supportedFormats: supportedFormats);
        allSongs.addAll(songs);
        _logger.d('Found ${songs.length} songs in $folder');
      }

      // Apply filters
      final filteredSongs = _applyFilters(allSongs);
      _logger.i('Total songs after filtering: ${filteredSongs.length}');

      // Filter out songs that already exist
      final existingSongIds = existingSongs.map((song) => song.id).toSet();
      final newSongs = filteredSongs
          .where((song) => !existingSongIds.contains(song.id))
          .toList();

      _logger.i(
        'Found ${newSongs.length} new songs out of ${filteredSongs.length} total songs',
      );
      return newSongs;
    } catch (e) {
      _logger.e('Error fetching new songs', error: e);
      return [];
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 33) {
        return await _checkAndroid13Permissions();
      } else if (androidVersion >= 30) {
        return await _checkAndroid11Permissions();
      } else {
        return await _checkLegacyAndroidPermissions();
      }
    } else if (Platform.isIOS) {
      return await _checkIOSPermissions();
    }

    return false;
  }

  /// Get Android version
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt;
      }
    } catch (e) {
      _logger.e('Error getting Android version', error: e);
    }
    return 0;
  }

  /// Request permissions for Android 11+ (API 30+)
  static Future<bool> _requestAndroid11Permissions() async {
    _logger.d('Requesting Android 11+ permissions');

    try {
      // For Android 11+, we need MANAGE_EXTERNAL_STORAGE for full access
      // or use MediaStore API for media files only
      final storagePermission = await _requestPermissionWithTimeout(
        Permission.manageExternalStorage,
      );

      if (storagePermission.isGranted) {
        _logger.i('MANAGE_EXTERNAL_STORAGE permission granted');
        return true;
      } else if (storagePermission.isDenied) {
        _logger.w('MANAGE_EXTERNAL_STORAGE permission denied');
        return false;
      } else if (storagePermission.isPermanentlyDenied) {
        _logger.w('MANAGE_EXTERNAL_STORAGE permission permanently denied');
        await _showPermissionDialog(
          'Storage Permission Required',
          'This app needs access to your device storage to find and play music files. Please grant the permission in settings.',
        );
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting Android 11+ permissions', error: e);
      // If request fails, check if permission is already granted
      try {
        return await _checkAndroid11Permissions();
      } catch (checkError) {
        _logger.e('Error checking Android 11+ permissions', error: checkError);
        return false;
      }
    }
  }

  /// Request permissions for Android 13+ (API 33+)
  static Future<bool> _requestAndroid13Permissions() async {
    _logger.d('Requesting Android 13+ permissions');

    try {
      // For Android 13+, we need READ_MEDIA_AUDIO for audio files
      // Add timeout to prevent hanging
      final audioPermission = await _requestPermissionWithTimeout(
        Permission.audio,
      );

      if (audioPermission.isGranted) {
        _logger.i('READ_MEDIA_AUDIO permission granted');
        return true;
      } else if (audioPermission.isDenied) {
        _logger.w('READ_MEDIA_AUDIO permission denied');
        return false;
      } else if (audioPermission.isPermanentlyDenied) {
        _logger.w('READ_MEDIA_AUDIO permission permanently denied');
        await _showPermissionDialog(
          'Audio Permission Required',
          'This app needs access to your audio files to find and play music. Please grant the permission in settings.',
        );
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting Android 13+ permissions', error: e);
      // If request fails, check if permission is already granted
      try {
        return await _checkAndroid13Permissions();
      } catch (checkError) {
        _logger.e('Error checking Android 13+ permissions', error: checkError);
        return false;
      }
    }
  }

  /// Request legacy Android permissions (pre-Android 11)
  static Future<bool> _requestLegacyAndroidPermissions() async {
    _logger.d('Requesting legacy Android permissions');

    try {
      final storagePermission = await _requestPermissionWithTimeout(
        Permission.storage,
      );

      if (storagePermission.isGranted) {
        _logger.i('Storage permission granted');
        return true;
      } else if (storagePermission.isPermanentlyDenied) {
        _logger.w('Storage permission permanently denied');
        await _showPermissionDialog(
          'Storage Permission Required',
          'This app needs access to your device storage to find and play music files. Please grant the permission in settings.',
        );
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting legacy Android permissions', error: e);
      // If request fails, check if permission is already granted
      try {
        return await _checkLegacyAndroidPermissions();
      } catch (checkError) {
        _logger.e(
          'Error checking legacy Android permissions',
          error: checkError,
        );
        return false;
      }
    }
  }

  /// Request iOS permissions
  static Future<bool> _requestIOSPermissions() async {
    _logger.d('Requesting iOS permissions');

    // iOS doesn't require special permissions for accessing music files
    // The files are accessible through the app's sandbox
    _logger.i('iOS permissions not required for music access');
    return true;
  }

  /// Check Android 11+ permissions
  static Future<bool> _checkAndroid11Permissions() async {
    final storagePermission = await Permission.manageExternalStorage.status;
    return storagePermission.isGranted;
  }

  /// Check Android 13+ permissions
  static Future<bool> _checkAndroid13Permissions() async {
    final audioPermission = await Permission.audio.status;
    return audioPermission.isGranted;
  }

  /// Check legacy Android permissions
  static Future<bool> _checkLegacyAndroidPermissions() async {
    final storagePermission = await Permission.storage.status;
    return storagePermission.isGranted;
  }

  /// Check iOS permissions
  static Future<bool> _checkIOSPermissions() async {
    // iOS doesn't require special permissions for music access
    return true;
  }

  /// Show permission dialog with settings option
  static Future<void> _showPermissionDialog(
    String title,
    String message,
  ) async {
    // This method is called from the service layer
    // The actual dialog should be shown from the UI layer
    _logger.w('Permission Dialog: $title - $message');
    _logger.i('User should be prompted to open settings from UI layer');
  }

  /// Request permission with timeout to prevent hanging
  static Future<PermissionStatus> _requestPermissionWithTimeout(
    Permission permission,
  ) async {
    try {
      // Add a timeout of 10 seconds to prevent hanging
      return await permission.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w(
            'Permission request timed out for ${permission.toString()}',
          );
          return PermissionStatus.denied;
        },
      );
    } catch (e) {
      _logger.e(
        'Error requesting permission ${permission.toString()}',
        error: e,
      );
      return PermissionStatus.denied;
    }
  }

  /// Get folders to scan for music files
  static Future<List<String>> _getFoldersToScan(Map<String, List<String>> whitelistedFolders) async {
    final List<String> folders = [];

    // Use whitelisted folders from AppSettingsState
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final platformFolders = whitelistedFolders[platform] ?? [];
    folders.addAll(platformFolders);
    _logger.d('Using whitelisted folders for $platform: $platformFolders');

    // Filter out non-existent folders
    final existingFolders = <String>[];
    for (final folder in folders) {
      final directory = Directory(folder);
      if (await directory.exists()) {
        existingFolders.add(folder);
      }
    }

    _logger.d('Folders to scan: $existingFolders');
    return existingFolders;
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
        ? _removeDuplicatesSongsFuzzy(basicFilteredSongs)
        : _removeDuplicateSongsByTitle(basicFilteredSongs);
    _logger.d('Songs after duplicate removal: ${uniqueSongs.length}');

    return uniqueSongs;
  }

  /// Get list of supported audio formats
  static List<String> getSupportedFormats() {
    return List.from(FormatUtils.defaultSupportedFormats);
  }

  /// Remove duplicate songs by title, keeping the best version
  static List<Song> _removeDuplicateSongsByTitle(List<Song> songs) {
    return SongCleanupService.removeDuplicateSongsByTitle(songs);
  }


  /// Get filter settings
  static Map<String, dynamic> getFilterSettings() {
    return {
      'minDuration': minDuration.inSeconds,
      'maxDuration': maxDuration.inSeconds,
      'supportedFormats': FormatUtils.defaultSupportedFormats,
      'duplicateRemoval': true,
      'fuzzyMatching': false, // Set to true for more aggressive duplicate detection
    };
  }

  /// Set duplicate detection mode
  static bool _useFuzzyMatching = false;


  /// Get duplicate removal statistics (for debugging/monitoring)
  static Map<String, dynamic> getDuplicateRemovalStats(
    List<Song> originalSongs,
    List<Song> filteredSongs,
  ) {
    final duplicatesRemoved = originalSongs.length - filteredSongs.length;
    final duplicatePercentage = originalSongs.isNotEmpty
        ? (duplicatesRemoved / originalSongs.length * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'originalCount': originalSongs.length,
      'filteredCount': filteredSongs.length,
      'duplicatesRemoved': duplicatesRemoved,
      'duplicatePercentage': '$duplicatePercentage%',
    };
  }

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

  /// Alternative: More aggressive duplicate detection using fuzzy matching
  static List<Song> _removeDuplicatesSongsFuzzy(List<Song> songs) {
    return SongCleanupService.removeDuplicatesSongsFuzzy(songs);
  }


}
