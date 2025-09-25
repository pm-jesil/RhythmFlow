import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/song/song_model.dart';
import '../logger/logger.dart';
import 'metadata_extractor/metadata_extractor.dart';

class FetchSongsService {
  static final AppLogger _logger = AppLogger('FetchSongsService');

  // Supported audio formats (excludes video files)
  static const List<String> supportedFormats = [
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg',
    '.wma',
    '.opus',
    '.aiff',
    '.alac',
    '.m4b',
    '.m4p',
    '.amr',
    '.3ga',
  ];

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

  // Default music folders for different platforms
  static const Map<String, List<String>> defaultMusicFolders = {
    'android': [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
    ],
    'ios': [
      '/var/mobile/Media/iTunes_Control/Music',
      '/var/mobile/Media/Music',
    ],
  };

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
  static Future<List<Song>> fetchAllSongs() async {
    _logger.i('Starting to fetch all songs');

    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        _logger.w('Permissions not granted, cannot fetch songs');
        return [];
      }

      final List<Song> allSongs = [];
      final List<String> foldersToScan = await _getFoldersToScan();

      for (final folder in foldersToScan) {
        _logger.d('Scanning folder: $folder');
        final songs = await _scanFolderForSongs(folder);
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
      final List<String> foldersToScan = await _getFoldersToScan();
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
              final song = await _processFile(entity);
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
  static Future<List<Song>> fetchNewSongs(List<Song> existingSongs) async {
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
      final List<String> foldersToScan = await _getFoldersToScan();

      for (final folder in foldersToScan) {
        _logger.d('Scanning folder: $folder');
        final songs = await _scanFolderForSongs(folder);
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
  static Future<List<String>> _getFoldersToScan() async {
    final List<String> folders = [];

    if (Platform.isAndroid) {
      // Add default Android music folders
      folders.addAll(defaultMusicFolders['android']!);

      // Add external storage directories if available
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          folders.add(externalDir.path);
        }
      } catch (e) {
        _logger.w('Could not get external storage directory', error: e);
      }
    } else if (Platform.isIOS) {
      // Add default iOS music folders
      folders.addAll(defaultMusicFolders['ios']!);

      // Add app documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        folders.add(appDir.path);
      } catch (e) {
        _logger.w('Could not get app documents directory', error: e);
      }
    }

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
  static Future<List<Song>> _scanFolderForSongs(String folderPath) async {
    final List<Song> songs = [];

    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        _logger.w('Folder does not exist: $folderPath');
        return songs;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final song = await _processFile(entity);
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
  static Future<Song?> _processFile(File file) async {
    try {
      final path = file.path.toLowerCase();

      // Check if file is a video format (exclude)
      if (videoFormats.any((format) => path.endsWith(format))) {
        _logger.d('⏭️ Skipping video file: ${file.path}');
        return null;
      }

      // Check if file is a supported audio format
      if (!supportedFormats.any((format) => path.endsWith(format))) {
        return null;
      }

      // Skip invalid audio files
      if (!await MetadataExtractor.isValidAudioFile(file.path)) {
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
    return List.from(supportedFormats);
  }

  /// Remove duplicate songs by title, keeping the best version
  static List<Song> _removeDuplicateSongsByTitle(List<Song> songs) {
    _logger.d('Removing duplicate songs by title from ${songs.length} songs');

    final Map<String, Song> uniqueSongs = {};
    int duplicatesRemoved = 0;

    for (final song in songs) {
      final normalizedTitle = _normalizeTitle(song.title);

      if (uniqueSongs.containsKey(normalizedTitle)) {
        // Found a duplicate - keep the better version
        final existingSong = uniqueSongs[normalizedTitle]!;
        final betterSong = _selectBetterSong(existingSong, song);

        if (betterSong != existingSong) {
          _logger.d(
            'Replacing duplicate: "${existingSong.title}" with better version: "${song.title}"',
          );
          uniqueSongs[normalizedTitle] = betterSong;
        } else {
          _logger.d(
            'Keeping existing song: "${existingSong.title}", removing duplicate: "${song.title}"',
          );
        }

        duplicatesRemoved++;
      } else {
        // First occurrence of this title
        uniqueSongs[normalizedTitle] = song;
      }
    }

    _logger.i(
      'Removed $duplicatesRemoved duplicate songs, kept ${uniqueSongs.length} unique songs',
    );
    return uniqueSongs.values.toList();
  }

  /// Enhanced normalization that handles multiple languages
  static String _normalizeTitle(String title) {
    if (title.isEmpty) return '';

    String normalized = title.toLowerCase().trim();

    // Remove common prefixes/suffixes in multiple languages
    final commonPrefixes = [
      'the ', 'a ', 'an ', // English
      'la ', 'le ', 'les ', 'un ', 'une ', // French
      'el ', 'la ', 'los ', 'las ', 'un ', 'una ', // Spanish
      'der ', 'die ', 'das ', 'ein ', 'eine ', // German
      'il ', 'lo ', 'la ', 'gli ', 'le ', 'un ', 'una ', // Italian
      'o ', 'a ', 'os ', 'as ', 'um ', 'uma ', // Portuguese
      'де ', 'ла ', 'ле ', // Russian (Cyrillic)
    ];

    for (final prefix in commonPrefixes) {
      if (normalized.startsWith(prefix)) {
        normalized = normalized.substring(prefix.length);
        break; // Only remove one prefix
      }
    }

    // Remove special characters and extra spaces while preserving Unicode
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u017F\u0400-\u04FF\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Remove common suffixes
    final commonSuffixes = [
      ' remix', ' remaster', ' remastered', ' extended', ' radio edit',
      ' acoustic', ' live', ' demo', ' instrumental', ' karaoke',
      ' cover', ' version', ' mix', ' edit',
    ];

    for (final suffix in commonSuffixes) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length).trim();
        break; // Only remove one suffix
      }
    }

    return normalized;
  }

  /// Enhanced song comparison that considers multiple factors
  static Song _selectBetterSong(Song song1, Song song2) {
    // Quality indicators (higher score = better quality)
    int getQualityScore(Song song) {
      int score = 0;

      // File size preference (larger usually means better quality)
      if (song.fileSize != null) {
        score += (song.fileSize! / 1000000).round(); // MB as score
      }

      // Bitrate preference
      if (song.bitrate != null) {
        score += (song.bitrate! / 32).round(); // Bitrate/32 as score
      }

      // Duration preference (not too short, not too long)
      final durationSeconds = song.duration.inSeconds;
      if (durationSeconds >= 30 && durationSeconds <= 600) { // 30s to 10min
        score += 10;
      } else if (durationSeconds < 30) {
        score -= 5; // Penalty for very short songs
      }

      // Prefer songs with more metadata
      if (song.artists.isNotEmpty) score += 2;
      if (song.albums.isNotEmpty) score += 2;
      if (song.genre != null && song.genre!.isNotEmpty) score += 1;
      if (song.year != null && song.year! > 0) score += 1;

      // Prefer lossless formats
      final extension = song.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'flac':
        case 'wav':
        case 'aiff':
          score += 15;
          break;
        case 'mp3':
          score += 10;
          break;
        case 'aac':
        case 'm4a':
          score += 8;
          break;
        case 'ogg':
          score += 6;
          break;
        default:
          score += 3;
      }

      // Penalty for songs with suspicious patterns in title
      final title = song.title.toLowerCase();
      if (title.contains('sample') || title.contains('preview')) {
        score -= 10;
      }
      if (title.length < 3) {
        score -= 5; // Very short titles are suspicious
      }

      return score;
    }

    final score1 = getQualityScore(song1);
    final score2 = getQualityScore(song2);

    _logger.d('Song quality scores: "${song1.title}" = $score1, "${song2.title}" = $score2');

    // If scores are very close, prefer the one added later (usually means it's newer)
    if ((score1 - score2).abs() <= 2) {
      if (song1.dateAdded != null && song2.dateAdded != null) {
        return song1.dateAdded!.isAfter(song2.dateAdded!) ? song1 : song2;
      }
      // If dates are null, prefer song1 as default
      return song1;
    }

    return score1 > score2 ? song1 : song2;
  }

  /// Get filter settings
  static Map<String, dynamic> getFilterSettings() {
    return {
      'minDuration': minDuration.inSeconds,
      'maxDuration': maxDuration.inSeconds,
      'supportedFormats': supportedFormats,
      'duplicateRemoval': true,
      'fuzzyMatching': false, // Set to true for more aggressive duplicate detection
    };
  }

  /// Set duplicate detection mode
  static bool _useFuzzyMatching = false;

  /// Enable or disable fuzzy matching for duplicate detection
  static void setFuzzyMatching(bool enabled) {
    _useFuzzyMatching = enabled;
    _logger.i('Fuzzy matching ${enabled ? 'enabled' : 'disabled'} for duplicate detection');
  }

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

  /// Alternative: More aggressive duplicate detection using fuzzy matching
  static List<Song> _removeDuplicatesSongsFuzzy(List<Song> songs) {
    _logger.d('Removing duplicate songs using fuzzy matching from ${songs.length} songs');

    final List<Song> uniqueSongs = [];
    int duplicatesRemoved = 0;

    for (final song in songs) {
      bool isDuplicate = false;

      for (int i = 0; i < uniqueSongs.length; i++) {
        if (_areSongsSimilar(uniqueSongs[i], song)) {
          // Found a potential duplicate
          final betterSong = _selectBetterSong(uniqueSongs[i], song);
          
          if (betterSong != uniqueSongs[i]) {
            _logger.d('Replacing fuzzy duplicate: "${uniqueSongs[i].title}" with "${song.title}"');
            uniqueSongs[i] = betterSong;
          } else {
            _logger.d('Keeping existing song, removing fuzzy duplicate: "${song.title}"');
          }
          
          isDuplicate = true;
          duplicatesRemoved++;
          break;
        }
      }

      if (!isDuplicate) {
        uniqueSongs.add(song);
      }
    }

    _logger.i('Fuzzy matching removed $duplicatesRemoved duplicates, kept ${uniqueSongs.length} unique songs');
    return uniqueSongs;
  }

  /// Check if two songs are similar enough to be considered duplicates
  static bool _areSongsSimilar(Song song1, Song song2) {
    // Normalize titles for comparison
    final title1 = _normalizeTitle(song1.title);
    final title2 = _normalizeTitle(song2.title);

    // Exact match after normalization
    if (title1 == title2) return true;

    // Fuzzy matching using Levenshtein distance
    final similarity = _calculateStringSimilarity(title1, title2);
    
    // Consider similar if:
    // 1. Very high string similarity (>90%)
    // 2. Same artist and high similarity (>80%)
    // 3. Same duration (±5 seconds) and good similarity (>70%)
    
    if (similarity > 0.9) return true;
    
    if (similarity > 0.8 && 
        song1.artists.join(', ').toLowerCase() == song2.artists.join(', ').toLowerCase()) {
      return true;
    }

    if (similarity > 0.7 && 
        (song1.duration.inSeconds - song2.duration.inSeconds).abs() <= 5) {
      return true;
    }

    return false;
  }

  /// Calculate string similarity using Levenshtein distance
  static double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final int len1 = s1.length;
    final int len2 = s2.length;
    
    // Create a matrix for dynamic programming
    List<List<int>> matrix = List.generate(
      len1 + 1, 
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final maxLength = len1 > len2 ? len1 : len2;
    return 1.0 - (matrix[len1][len2] / maxLength);
  }
}
