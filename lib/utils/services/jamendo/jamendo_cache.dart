import 'dart:convert';

import 'package:hive/hive.dart';

import '../../logger/logger.dart';
import '../library_storage.dart';
import 'jamendo_api_client.dart';

/// Response cache for the Jamendo API: memory + Hive box `jamendo_cache`.
///
/// Entries keep their timestamp so callers can use fresh data (within TTL)
/// and fall back to stale data when offline.
class JamendoCache {
  static final AppLogger _logger = AppLogger('JamendoCache');
  static const String boxName = 'jamendo_cache';

  /// Hard cap on persisted entries; oldest are evicted first.
  static const int maxEntries = 300;

  final LibraryStoreBackend? _backend;
  final Map<String, _Entry> _memory = {};
  final DateTime Function() _now;

  JamendoCache({LibraryStoreBackend? backend, DateTime Function()? now})
    : _backend = backend,
      _now = now ?? DateTime.now;

  /// Opens the Hive-backed cache (Hive must be initialised).
  static Future<JamendoCache> open() async {
    try {
      final box = await Hive.openBox<String>(boxName);
      return JamendoCache(backend: HiveLibraryStoreBackend(box));
    } catch (e) {
      _logger.w('⚠️ Persistent Jamendo cache unavailable, memory only: $e');
      return JamendoCache();
    }
  }

  JamendoResponse? read(String key, {Duration? maxAge}) {
    final entry = _memory[key] ?? _load(key);
    if (entry == null) return null;
    if (maxAge != null && _now().difference(entry.savedAt) > maxAge) {
      return null;
    }
    return entry.response;
  }

  Future<void> write(String key, JamendoResponse response) async {
    final entry = _Entry(_now(), response);
    _memory[key] = entry;
    if (_memory.length > maxEntries) {
      final oldest = _memory.entries.reduce(
        (a, b) => a.value.savedAt.isBefore(b.value.savedAt) ? a : b,
      );
      _memory.remove(oldest.key);
    }
    try {
      await _backend?.write(key, jsonEncode(entry.toJson()));
    } catch (e) {
      _logger.w('⚠️ Could not persist cache entry: $e');
    }
  }

  Future<void> clear() async {
    _memory.clear();
    await _backend?.clear();
  }

  _Entry? _load(String key) {
    final raw = _backend?.read(key);
    if (raw == null) return null;
    try {
      final entry = _Entry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _memory[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }
}

class _Entry {
  final DateTime savedAt;
  final JamendoResponse response;
  _Entry(this.savedAt, this.response);

  Map<String, dynamic> toJson() => {
    't': savedAt.millisecondsSinceEpoch,
    'n': response.next,
    'r': response.results,
  };

  factory _Entry.fromJson(Map<String, dynamic> json) => _Entry(
    DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
    JamendoResponse(
      (json['r'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      next: json['n'] as String?,
    ),
  );
}
