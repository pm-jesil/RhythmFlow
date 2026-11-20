import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/song/song_model.dart';
import '../logger/logger.dart';
import 'audio_header_validator.dart';
import 'metadata_extractor/metadata_extractor.dart';
import 'format_utils.dart';
import 'song_cleanup_service.dart';
import 'permission_service.dart';

/// Extracts a [Song] from an audio file. Replaceable in tests.
typedef SongExtractor = Future<Song?> Function(String filePath);

/// Returns whether storage permission is granted. Replaceable in tests.
typedef PermissionChecker = Future<bool> Function();

/// Why a file was skipped during a scan (stored in the skip cache).
class SkipReason {
  SkipReason._();
  static const String duplicate = 'duplicate';
  static const String filtered = 'filtered';
  static const String unreadable = 'unreadable';
}

/// Result of an incremental library scan.
class LibraryScanResult {
  /// Newly discovered songs (already filtered and de-duplicated).
  final List<Song> newSongs;

  /// IDs of library songs that are no longer present in the scanned folders
  /// (deleted, moved, folder removed from the whitelist, format disabled).
  final List<String> invalidSongIds;

  /// Existing songs whose file changed and whose metadata was re-read (or
  /// whose file signature was back-filled). Same IDs as before.
  final List<Song> updatedSongs;

  /// False when the device could not be scanned (no permission, no folders);
  /// callers must then keep the library untouched.
  final bool scanSucceeded;

  const LibraryScanResult({
    this.newSongs = const [],
    this.invalidSongIds = const [],
    this.updatedSongs = const [],
    this.scanSucceeded = true,
  });

  static const LibraryScanResult failed = LibraryScanResult(
    scanSucceeded: false,
  );

  /// Backward compatible map form used by older callers/tests.
  Map<String, dynamic> toMap() => {
    'newSongs': newSongs,
    'invalidSongIds': invalidSongIds,
    'updatedSongs': updatedSongs,
    'scanSucceeded': scanSucceeded,
  };
}

class FetchSongsService {
  static final AppLogger _logger = AppLogger('FetchSongsService');

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

  /// Songs with a *known* duration shorter than this are ignored (UI sounds,
  /// notification tones). Songs whose duration could not be read (zero) are
  /// kept; the real duration is filled in when they are first played.
  static const Duration minDuration = Duration(seconds: 2);

  /// Files smaller than this are not real songs.
  static const int minFileSizeBytes = 10 * 1024;

  /// Number of files processed between progress callbacks.
  static const int batchSize = 10;

  // ==================== INJECTABLE DEPENDENCIES ====================

  static SongExtractor extractor = MetadataExtractor.extractMetadata;
  static PermissionChecker permissionChecker =
      PermissionService.hasAllRequiredPermissions;

  /// Key of the whitelist map used on this platform.
  static String platformKey = Platform.isAndroid ? 'android' : 'ios';

  /// Delay between batches so the UI isolate stays responsive.
  static Duration batchDelay = const Duration(milliseconds: 30);

  // ==================== SKIP CACHE ====================

  /// path -> "size:mtimeMs|reason" for files that were processed but not added
  /// to the library (duplicates, too short, unreadable). They are not
  /// re-processed on every scan unless the file changes. Persisted by
  /// LibraryStorage.
  static final Map<String, String> _skippedFiles = {};

  static Map<String, String> get skippedFiles =>
      Map.unmodifiable(_skippedFiles);

  static void restoreSkippedFiles(Map<String, String> entries) {
    _skippedFiles
      ..clear()
      ..addAll(entries);
  }

  static void clearSkippedFiles() => _skippedFiles.clear();

  /// Optional listener invoked whenever the skip cache changes.
  static VoidCallback? onSkippedFilesChanged;

  @visibleForTesting
  static void resetForTesting() {
    extractor = MetadataExtractor.extractMetadata;
    permissionChecker = PermissionService.hasAllRequiredPermissions;
    platformKey = Platform.isAndroid ? 'android' : 'ios';
    batchDelay = const Duration(milliseconds: 30);
    onSkippedFilesChanged = null;
    _skippedFiles.clear();
  }

  static String fileSignature(FileStat stat) =>
      '${stat.size}:${stat.modified.millisecondsSinceEpoch}';

  /// Same formula as `MetadataUtils.generateSongId`, computed from an
  /// already available [FileStat].
  static String songIdFor(String filePath, FileStat stat) {
    final combined =
        '$filePath${stat.size}${stat.modified.millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(combined)).toString().substring(0, 16);
  }

  // ==================== PUBLIC SCAN API ====================

  /// First (full) scan. Reports accepted songs batch by batch.
  ///
  /// `onProgress(batchSongs, isComplete, totalAccepted)`.
  static Future<void> fetchAllSongsProgressive({
    required void Function(List<Song>, bool, int) onProgress,
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
  }) async {
    _logger.i('🚀 Starting progressive song scan...');
    try {
      final paths = await scanSongPaths(
        whitelistedFolders: whitelistedFolders,
        supportedFormats: supportedFormats,
      );
      if (paths == null || paths.isEmpty) {
        onProgress([], true, 0);
        return;
      }
      _pruneSkipCache(paths.toSet());

      int total = 0;
      await _processNewPaths(
        paths,
        existingForDedup: const [],
        supportedFormats: supportedFormats,
        onBatch: (batch, isComplete) {
          total += batch.length;
          onProgress(batch, isComplete, total);
        },
      );
      _logger.i('🎵 Progressive scan completed: $total songs');
    } catch (e) {
      _logger.e('❌ Error in progressive song scan', error: e);
      onProgress([], true, 0);
    }
  }

  /// Incremental scan against the current library.
  static Future<LibraryScanResult> scanLibrary(
    List<Song> existingSongs, {
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
  }) async {
    _logger.i('🆕 Incremental scan (${existingSongs.length} songs in library)');
    try {
      final paths = await scanSongPaths(
        whitelistedFolders: whitelistedFolders,
        supportedFormats: supportedFormats,
      );
      if (paths == null) return LibraryScanResult.failed;

      final pathSet = paths.toSet();
      _pruneSkipCache(pathSet);

      final invalidSongIds = <String>[];
      final updatedSongs = <Song>[];
      final keptExisting = <Song>[];

      for (final song in existingSongs) {
        if (!pathSet.contains(song.path)) {
          invalidSongIds.add(song.id);
          continue;
        }
        FileStat stat;
        try {
          stat = await File(song.path).stat();
          if (stat.type == FileSystemEntityType.notFound) {
            invalidSongIds.add(song.id);
            continue;
          }
        } catch (_) {
          invalidSongIds.add(song.id);
          continue;
        }

        final refreshed = await _refreshIfModified(
          song,
          stat,
          supportedFormats: supportedFormats,
        );
        if (refreshed != null) {
          updatedSongs.add(refreshed);
          keptExisting.add(refreshed);
        } else {
          keptExisting.add(song);
        }
      }

      // A removed song may have had duplicates that were skipped; let them
      // be considered again so the recording does not disappear.
      if (invalidSongIds.isNotEmpty) {
        _removeSkipEntries(SkipReason.duplicate);
      }

      final existingPaths = existingSongs.map((s) => s.path).toSet();
      final candidatePaths = paths
          .where((p) => !existingPaths.contains(p))
          .toList();

      final newSongs = <Song>[];
      await _processNewPaths(
        candidatePaths,
        existingForDedup: keptExisting,
        supportedFormats: supportedFormats,
        onBatch: (batch, _) => newSongs.addAll(batch),
      );

      _logger.i(
        '✅ Incremental scan: +${newSongs.length} new, '
        '-${invalidSongIds.length} removed, ~${updatedSongs.length} updated',
      );
      return LibraryScanResult(
        newSongs: newSongs,
        invalidSongIds: invalidSongIds,
        updatedSongs: updatedSongs,
      );
    } catch (e) {
      _logger.e('❌ Error in incremental scan', error: e);
      return LibraryScanResult.failed;
    }
  }

  /// Backward compatible wrapper around [scanLibrary].
  static Future<Map<String, dynamic>> fetchNewSongs(
    List<Song> existingSongs, {
    List<String>? supportedFormats,
    Map<String, List<String>>? whitelistedFolders,
  }) async {
    final result = await scanLibrary(
      existingSongs,
      supportedFormats: supportedFormats,
      whitelistedFolders: whitelistedFolders,
    );
    return result.toMap();
  }

  // ==================== PATH DISCOVERY ====================

  /// Lists all audio files inside the whitelisted folders (recursively).
  ///
  /// Returns `null` when scanning was not possible (permission missing or no
  /// whitelisted folder exists) so that callers never wipe the library
  /// because of a transient problem.
  static Future<List<String>?> scanSongPaths({
    Map<String, List<String>>? whitelistedFolders,
    List<String>? supportedFormats,
  }) async {
    if (!await permissionChecker()) {
      _logger.w('❌ Permissions not granted, cannot scan');
      return null;
    }

    final roots = (whitelistedFolders ?? const {})[platformKey] ?? const [];
    final formats = (supportedFormats ?? FormatUtils.defaultSupportedFormats)
        .map((f) => f.toLowerCase())
        .toSet();

    final existingRoots = <String>[];
    for (final root in roots) {
      if (await Directory(root).exists()) {
        existingRoots.add(root);
      } else {
        _logger.w('⚠️ Whitelisted folder does not exist: $root');
      }
    }
    if (existingRoots.isEmpty) {
      _logger.w('⚠️ No whitelisted folder exists');
      return null;
    }

    final found = <String>{};
    for (final root in existingRoots) {
      await _walk(Directory(root), formats, found);
    }
    final result = found.toList()..sort();
    _logger.i('✅ Found ${result.length} audio files');
    return result;
  }

  /// Public, list-returning variant kept for backward compatibility.
  static Future<List<String>> fetchSongsPath({
    Map<String, List<String>>? whitelistedFolders,
    List<String>? supportedFormats,
  }) async {
    return await scanSongPaths(
          whitelistedFolders: whitelistedFolders,
          supportedFormats: supportedFormats,
        ) ??
        <String>[];
  }

  /// Get all folders recursively from whitelisted folders.
  static Future<List<String>> getAllFoldersFromWhitelist(
    Map<String, List<String>> whitelistedFolders,
  ) async {
    final folders = <String>{};
    for (final root in whitelistedFolders[platformKey] ?? const <String>[]) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      folders.add(root);
      await _collectDirectories(dir, folders);
    }
    return folders.toList()..sort();
  }

  static Future<void> _collectDirectories(
    Directory dir,
    Set<String> out,
  ) async {
    List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } catch (_) {
      return;
    }
    for (final entity in entries) {
      if (entity is Directory) {
        out.add(entity.path);
        await _collectDirectories(entity, out);
      }
    }
  }

  /// Recursive walk that tolerates unreadable sub-folders (a single
  /// permission error no longer aborts the whole folder tree).
  static Future<void> _walk(
    Directory dir,
    Set<String> formats,
    Set<String> out,
  ) async {
    List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } catch (e) {
      _logger.w('⚠️ Cannot list ${dir.path}: $e');
      return;
    }
    for (final entity in entries) {
      if (entity is Directory) {
        await _walk(entity, formats, out);
      } else if (entity is File && isSupportedAudioPath(entity.path, formats)) {
        out.add(entity.path);
      }
    }
  }

  /// True when [path] has one of [formats] and is not a video file.
  static bool isSupportedAudioPath(String path, Iterable<String> formats) {
    final ext = '.${AudioHeaderValidator.extensionOf(path)}';
    if (ext == '.') return false;
    if (videoFormats.contains(ext)) return false;
    return formats.contains(ext);
  }

  // ==================== FILE PROCESSING ====================

  static Future<void> _processNewPaths(
    List<String> paths, {
    required List<Song> existingForDedup,
    required List<String>? supportedFormats,
    required void Function(List<Song> batch, bool isComplete) onBatch,
  }) async {
    if (paths.isEmpty) {
      onBatch(const [], true);
      return;
    }

    final kept = List<Song>.from(existingForDedup);
    for (int i = 0; i < paths.length; i += batchSize) {
      final batchPaths = paths.skip(i).take(batchSize);
      final extracted = <Song>[];

      for (final path in batchPaths) {
        FileStat stat;
        try {
          stat = await File(path).stat();
        } catch (_) {
          continue;
        }
        if (stat.type == FileSystemEntityType.notFound) continue;
        final signature = fileSignature(stat);
        if (_isSkipped(path, signature)) continue;

        final song = await processFile(
          File(path),
          supportedFormats: supportedFormats,
        );
        if (song == null) {
          _markSkipped(path, signature, SkipReason.unreadable);
          continue;
        }
        final normalized = normalizeSong(song).copyWith(
          fileModifiedAt: stat.modified,
          fileSize: song.fileSize ?? stat.size,
        );
        if (!passesBasicFilters(normalized)) {
          _markSkipped(path, signature, SkipReason.filtered);
          continue;
        }
        extracted.add(normalized);
      }

      final dedup = SongCleanupService.filterDuplicatesAgainst(kept, extracted);
      for (final dropped in dedup.dropped) {
        final signature = dropped.fileModifiedAt != null
            ? '${dropped.fileSize}:${dropped.fileModifiedAt!.millisecondsSinceEpoch}'
            : '';
        _markSkipped(dropped.path, signature, SkipReason.duplicate);
      }
      kept.addAll(dedup.accepted);

      final isComplete = i + batchSize >= paths.length;
      onBatch(dedup.accepted, isComplete);
      if (!isComplete && batchDelay > Duration.zero) {
        await Future.delayed(batchDelay);
      }
    }
  }

  /// Re-reads metadata of [song] when its file changed since it was indexed.
  /// Returns the updated song (same ID and user data) or `null` when nothing
  /// changed.
  static Future<Song?> _refreshIfModified(
    Song song,
    FileStat stat, {
    required List<String>? supportedFormats,
  }) async {
    final modifiedMs = stat.modified.millisecondsSinceEpoch;

    if (song.fileModifiedAt == null) {
      // Indexed by an older version: the ID encodes size + mtime at the time.
      if (songIdFor(song.path, stat) == song.id) {
        return song.copyWith(fileModifiedAt: stat.modified, fileSize: stat.size);
      }
    } else if (song.fileModifiedAt!.millisecondsSinceEpoch == modifiedMs &&
        (song.fileSize == null || song.fileSize == stat.size)) {
      return null; // unchanged
    }

    _logger.i('✏️ File changed, re-reading tags: ${song.path}');
    final fresh = await processFile(
      File(song.path),
      supportedFormats: supportedFormats,
    );
    if (fresh == null) {
      // Keep the old metadata but remember the new signature so we do not
      // retry on every scan.
      return song.copyWith(fileModifiedAt: stat.modified, fileSize: stat.size);
    }
    return mergeRefreshedSong(song, normalizeSong(fresh)).copyWith(
      fileModifiedAt: stat.modified,
      fileSize: stat.size,
    );
  }

  /// Keeps identity and user data of [old] while taking the file metadata of
  /// [fresh].
  static Song mergeRefreshedSong(Song old, Song fresh) {
    return fresh.copyWith(
      id: old.id,
      playCount: old.playCount,
      lastPlayed: old.lastPlayed,
      isFavorite: old.isFavorite,
      myPlaylistIds: old.myPlaylistIds,
      dateAdded: old.dateAdded ?? fresh.dateAdded,
      features: old.features,
      audioEmbedding: old.audioEmbedding,
      updatedAt: DateTime.now(),
    );
  }

  /// Process a file to extract song information.
  static Future<Song?> processFile(
    File file, {
    List<String>? supportedFormats,
  }) async {
    try {
      final formats = (supportedFormats ?? FormatUtils.defaultSupportedFormats)
          .map((f) => f.toLowerCase());
      if (!isSupportedAudioPath(file.path, formats)) return null;
      if (!await AudioHeaderValidator.isValidFile(file.path)) {
        _logger.d('Skipping invalid audio file: ${file.path}');
        return null;
      }
      return await extractor(file.path);
    } catch (e) {
      _logger.e('Error processing file: ${file.path}', error: e);
      return null;
    }
  }

  /// Scan a folder for music files (not used by the library scan).
  static Future<List<Song>> scanFolderForSongs(
    String folderPath, {
    List<String>? supportedFormats,
  }) async {
    final songs = <Song>[];
    final dir = Directory(folderPath);
    if (!await dir.exists()) return songs;
    final paths = <String>{};
    await _walk(
      dir,
      (supportedFormats ?? FormatUtils.defaultSupportedFormats)
          .map((f) => f.toLowerCase())
          .toSet(),
      paths,
    );
    for (final path in paths.toList()..sort()) {
      final song = await processFile(File(path), supportedFormats: supportedFormats);
      if (song != null) songs.add(song);
    }
    return songs;
  }

  // ==================== FILTERS ====================

  /// Fills missing title / artist / album instead of dropping the song.
  static Song normalizeSong(Song song) {
    final title = song.title.trim().isNotEmpty
        ? song.title
        : _fileBaseName(song.path);
    final artists = song.artists.where((a) => a.trim().isNotEmpty).toList();
    final albums = song.albums.where((a) => a.trim().isNotEmpty).toList();
    return song.copyWith(
      title: title,
      artists: artists.isEmpty ? const ['Unknown Artist'] : artists,
      albums: albums.isEmpty ? const ['Unknown Album'] : albums,
    );
  }

  /// Basic sanity filters. Unknown (zero) duration and long files are kept.
  static bool passesBasicFilters(Song song) {
    if (song.fileSize != null && song.fileSize! < minFileSizeBytes) {
      return false;
    }
    if (song.duration > Duration.zero && song.duration < minDuration) {
      return false;
    }
    return true;
  }

  static String _fileBaseName(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // ==================== SKIP CACHE HELPERS ====================

  static bool _isSkipped(String path, String signature) {
    final entry = _skippedFiles[path];
    if (entry == null) return false;
    return entry.split('|').first == signature;
  }

  static void _markSkipped(String path, String signature, String reason) {
    _skippedFiles[path] = '$signature|$reason';
    onSkippedFilesChanged?.call();
  }

  static void _removeSkipEntries(String reason) {
    final before = _skippedFiles.length;
    _skippedFiles.removeWhere((_, v) => v.endsWith('|$reason'));
    if (_skippedFiles.length != before) onSkippedFilesChanged?.call();
  }

  static void _pruneSkipCache(Set<String> presentPaths) {
    final before = _skippedFiles.length;
    _skippedFiles.removeWhere((path, _) => !presentPaths.contains(path));
    if (_skippedFiles.length != before) onSkippedFilesChanged?.call();
  }
}
