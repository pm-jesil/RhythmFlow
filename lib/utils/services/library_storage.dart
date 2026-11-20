import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../logger/logger.dart';
import '../models/album/album_model.dart';
import '../models/artist/artist_model.dart';
import '../models/song/song_model.dart';

/// Key/value backend used by [LibraryStorage]. Hive in the app, in-memory in
/// tests.
abstract class LibraryStoreBackend {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class HiveLibraryStoreBackend implements LibraryStoreBackend {
  final Box<String> _box;
  HiveLibraryStoreBackend(this._box);

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> clear() => _box.clear();
}

class InMemoryLibraryStoreBackend implements LibraryStoreBackend {
  final Map<String, String> data = {};
  int writeCount = 0;

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    data[key] = value;
  }

  @override
  Future<void> clear() async => data.clear();
}

/// The persisted music library (songs, albums, artists, scan skip cache).
class LibrarySnapshot {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final Map<String, String> skippedFiles;

  const LibrarySnapshot({
    required this.songs,
    required this.albums,
    required this.artists,
    this.skippedFiles = const {},
  });
}

/// Stores the (potentially large) music library outside of HydratedBloc.
///
/// HydratedBloc serialises the *whole* state on every emit (every position
/// update, play count, feature-extraction result, scan batch...). With a
/// few thousand songs that meant megabytes of JSON encoding on the UI isolate
/// several times per minute. The library is now written here, debounced, and
/// only when it actually changed.
class LibraryStorage {
  LibraryStorage._();

  static final AppLogger _logger = AppLogger('LibraryStorage');

  static const String boxName = 'rhythmflow_library';
  static const String _songsKey = 'songs';
  static const String _albumsKey = 'albums';
  static const String _artistsKey = 'artists';
  static const String _skippedKey = 'skipped_files';
  static const String _versionKey = 'version';
  static const String currentVersion = '1';

  static Duration saveDebounce = const Duration(milliseconds: 1500);

  static LibraryStoreBackend? _backend;
  static Timer? _debounceTimer;
  static LibrarySnapshot? _pending;

  static bool get isReady => _backend != null;

  /// Opens the Hive box. Hive must already be initialised (`Hive.init`).
  static Future<void> init() async {
    if (_backend != null) return;
    try {
      final box = await Hive.openBox<String>(boxName);
      _backend = HiveLibraryStoreBackend(box);
      _logger.i('✅ Library storage ready (${box.length} keys)');
    } catch (e) {
      _logger.e('❌ Could not open library storage', error: e);
    }
  }

  @visibleForTesting
  static void useBackend(LibraryStoreBackend? backend) {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pending = null;
    _backend = backend;
  }

  /// True when a library was saved before.
  static bool get hasData => _backend?.read(_songsKey) != null;

  /// Synchronously loads the stored library (null when none / unreadable).
  static LibrarySnapshot? load() {
    final backend = _backend;
    if (backend == null) return null;
    try {
      final songsJson = backend.read(_songsKey);
      if (songsJson == null) return null;
      final songs = (jsonDecode(songsJson) as List)
          .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final albums = _decodeList(
        backend.read(_albumsKey),
        (e) => Album.fromJson(e),
      );
      final artists = _decodeList(
        backend.read(_artistsKey),
        (e) => Artist.fromJson(e),
      );
      final skippedRaw = backend.read(_skippedKey);
      final skipped = skippedRaw == null
          ? <String, String>{}
          : Map<String, String>.from(jsonDecode(skippedRaw) as Map);
      return LibrarySnapshot(
        songs: songs,
        albums: albums,
        artists: artists,
        skippedFiles: skipped,
      );
    } catch (e) {
      _logger.e('❌ Stored library is unreadable, ignoring it', error: e);
      return null;
    }
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return <T>[];
    return (jsonDecode(raw) as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Schedules a debounced save. Repeated calls within [saveDebounce] only
  /// write the last snapshot.
  static void scheduleSave(LibrarySnapshot snapshot) {
    if (_backend == null) return;
    _pending = snapshot;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(saveDebounce, () {
      unawaited(flush());
    });
  }

  /// Writes a pending snapshot immediately (e.g. when the app goes to the
  /// background).
  static Future<void> flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final snapshot = _pending;
    _pending = null;
    if (snapshot != null) await saveNow(snapshot);
  }

  static Future<void> saveNow(LibrarySnapshot snapshot) async {
    final backend = _backend;
    if (backend == null) return;
    try {
      await backend.write(
        _songsKey,
        jsonEncode(snapshot.songs.map((s) => s.toJson()).toList()),
      );
      await backend.write(
        _albumsKey,
        jsonEncode(snapshot.albums.map((a) => a.toJson()).toList()),
      );
      await backend.write(
        _artistsKey,
        jsonEncode(snapshot.artists.map((a) => a.toJson()).toList()),
      );
      await backend.write(_skippedKey, jsonEncode(snapshot.skippedFiles));
      await backend.write(_versionKey, currentVersion);
      _logger.d('💾 Library saved (${snapshot.songs.length} songs)');
    } catch (e) {
      _logger.e('❌ Failed to save library', error: e);
    }
  }

  static Future<void> clear() async {
    _debounceTimer?.cancel();
    _pending = null;
    await _backend?.clear();
  }
}
