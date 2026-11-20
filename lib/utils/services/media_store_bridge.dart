import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logger/logger.dart';

/// Dart side of the MediaStore bridge implemented in `MainActivity.kt`.
class MediaStoreBridge {
  MediaStoreBridge._();

  static final AppLogger _logger = AppLogger('MediaStoreBridge');

  static const MethodChannel channel = MethodChannel(
    'com.technexa.rhythmflow/media_store',
  );

  /// MediaStore changes arrive in bursts (a download writes the file, then
  /// updates it). They are collapsed into one callback.
  static Duration changeDebounce = const Duration(seconds: 3);

  static VoidCallback? _onChanged;
  static Timer? _debounceTimer;
  static bool _observing = false;

  /// Test hook: forces the platform used by [deleteAudioFile] / observing.
  @visibleForTesting
  static bool? isAndroidOverride;

  static bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;

  /// Start listening for audio files being added / changed / removed.
  static Future<void> startObserving(VoidCallback onChanged) async {
    _onChanged = onChanged;
    if (!_isAndroid || _observing) return;
    channel.setMethodCallHandler(handleMethodCall);
    try {
      await channel.invokeMethod<bool>('startObserving');
      _observing = true;
      _logger.i('👀 Observing MediaStore audio changes');
    } catch (e) {
      _logger.w('⚠️ MediaStore observing unavailable: $e');
    }
  }

  static Future<void> stopObserving() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _onChanged = null;
    if (!_observing) return;
    _observing = false;
    try {
      await channel.invokeMethod<bool>('stopObserving');
    } catch (_) {}
  }

  /// Handles calls coming from the native side.
  @visibleForTesting
  static Future<dynamic> handleMethodCall(MethodCall call) async {
    if (call.method == 'onMediaStoreChanged') {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(changeDebounce, () {
        _debounceTimer = null;
        _onChanged?.call();
      });
    }
    return null;
  }

  @visibleForTesting
  static void resetForTesting() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _onChanged = null;
    _observing = false;
    isAndroidOverride = null;
    changeDebounce = const Duration(seconds: 3);
  }

  /// Saves a downloaded song into `Music/RhythmFlow` and returns its final
  /// path (Android). Throws [PlatformException] on failure.
  static Future<String> saveAudioToMusic({
    required String tempPath,
    required String fileName,
    String? title,
    String? artist,
    String? album,
  }) async {
    final path = await channel.invokeMethod<String>('saveAudioToMusic', {
      'tempPath': tempPath,
      'fileName': fileName,
      'title': title,
      'artist': artist,
      'album': album,
    });
    if (path == null || path.isEmpty) {
      throw PlatformException(code: 'save_failed', message: 'No path returned');
    }
    return path;
  }

  /// Deletes an audio file. Returns `true` when the file is gone, `false`
  /// when the user cancelled the system confirmation. Throws on errors.
  ///
  /// On Android 11+ this shows the system "Allow RhythmFlow to delete this
  /// audio file?" dialog - a plain `File.delete()` is not permitted there for
  /// files the app did not create.
  static Future<bool> deleteAudioFile(String path) async {
    if (_isAndroid) {
      try {
        final deleted = await channel.invokeMethod<bool>(
          'deleteAudioFile',
          {'path': path},
        );
        return deleted ?? false;
      } on MissingPluginException {
        // Fall back to a direct delete below.
      }
    }
    final file = File(path);
    if (await file.exists()) await file.delete();
    return !await file.exists();
  }

  // ==================== RINGTONES ====================

  /// Lossless AAC/M4A cut (MediaExtractor + MediaMuxer). Returns the kept
  /// duration in ms. Throws [PlatformException] (`unsupported` for non-AAC).
  static Future<int> trimAudio({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
  }) async {
    final ms = await channel.invokeMethod<int>('trimAudio', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'startMs': startMs,
      'endMs': endMs,
    });
    return ms ?? endMs - startMs;
  }

  /// Saves a ringtone file into `Ringtones/RhythmFlow` and marks it as a
  /// ringtone / notification / alarm sound. Returns `(uri, path)`.
  static Future<({String uri, String path})> saveRingtone({
    required String tempPath,
    required String fileName,
    required String title,
    required String mimeType,
    String? artist,
  }) async {
    final result = await channel.invokeMapMethod<String, dynamic>('saveRingtone', {
      'tempPath': tempPath,
      'fileName': fileName,
      'title': title,
      'mimeType': mimeType,
      'artist': artist,
    });
    final uri = result?['uri'] as String?;
    if (uri == null || uri.isEmpty) {
      throw PlatformException(code: 'save_failed', message: 'No uri returned');
    }
    return (uri: uri, path: (result?['path'] as String?) ?? '');
  }

  /// Whether the app may change the default ringtone ("Modify system
  /// settings").
  static Future<bool> canWriteSettings() async =>
      await channel.invokeMethod<bool>('canWriteSettings') ?? false;

  /// Opens the system "Modify system settings" screen for this app.
  static Future<void> openWriteSettings() => channel.invokeMethod<bool>('openWriteSettings');

  /// [type] is `ringtone`, `notification` or `alarm`. Throws a
  /// [PlatformException] with code `no_permission` without the permission.
  static Future<void> setDefaultRingtone(String uri, String type) =>
      channel.invokeMethod<bool>('setDefaultRingtone', {'uri': uri, 'type': type});

  /// Renames a ringtone file the app created. Returns the new path.
  static Future<String> renameRingtone({
    String? uri,
    String? path,
    required String fileName,
    required String title,
  }) async {
    final newPath = await channel.invokeMethod<String>('renameRingtone', {
      'uri': uri,
      'path': path,
      'fileName': fileName,
      'title': title,
    });
    return newPath ?? path ?? '';
  }

  static Future<bool> deleteRingtone({String? uri, String? path}) async =>
      await channel.invokeMethod<bool>('deleteRingtone', {'uri': uri, 'path': path}) ?? false;
}
