import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../logger/logger.dart';
import '../../models/ringtone/ringtone_model.dart';
import '../../models/song/song_model.dart';
import '../audio_header_validator.dart';
import '../jamendo/download_service.dart' show FileDownloader;
import '../media_store_bridge.dart';
import 'audio_trimmer.dart';

/// A user-facing ringtone error.
class RingtoneException implements Exception {
  final String message;
  const RingtoneException(this.message);
  @override
  String toString() => message;
}

enum RingtoneSetResult { done, needsPermission, unsupported, failed }

typedef Trimmer =
    Future<TrimResult> Function({
      required String inputPath,
      required String outputPathWithoutExtension,
      required Duration start,
      required Duration end,
    });
typedef RingtoneSaver =
    Future<({String uri, String path})> Function({
      required String tempPath,
      required String fileName,
      required String title,
      required String mimeType,
      String? artist,
    });

/// Platform operations behind ringtones (MediaStore on Android, a folder in
/// the app documents elsewhere). Replaced by fakes in tests.
class RingtonePlatform {
  final RingtoneSaver save;
  final Future<String> Function({String? uri, String? path, required String fileName, required String title}) rename;
  final Future<bool> Function({String? uri, String? path}) delete;
  final Future<bool> Function() canWriteSettings;
  final Future<void> Function() openWriteSettings;
  final Future<void> Function(String uri, String type) setDefault;
  final bool supportsSystemRingtones;

  const RingtonePlatform({
    required this.save,
    required this.rename,
    required this.delete,
    required this.canWriteSettings,
    required this.openWriteSettings,
    required this.setDefault,
    required this.supportsSystemRingtones,
  });

  static RingtonePlatform get android => const RingtonePlatform(
    save: MediaStoreBridge.saveRingtone,
    rename: MediaStoreBridge.renameRingtone,
    delete: MediaStoreBridge.deleteRingtone,
    canWriteSettings: MediaStoreBridge.canWriteSettings,
    openWriteSettings: MediaStoreBridge.openWriteSettings,
    setDefault: MediaStoreBridge.setDefaultRingtone,
    supportsSystemRingtones: true,
  );

  /// Files in `<documents>/Ringtones`; cannot become the system ringtone.
  static RingtonePlatform files(Future<Directory> Function() root) => RingtonePlatform(
    save: ({required tempPath, required fileName, required title, required mimeType, artist}) async {
      final dir = Directory('${(await root()).path}/Ringtones');
      await dir.create(recursive: true);
      final target = RingtoneService.uniqueFile(dir.path, fileName);
      await File(tempPath).copy(target);
      return (uri: '', path: target);
    },
    rename: ({uri, path, required fileName, required title}) async {
      final from = File(path!);
      final target = '${from.parent.path}/$fileName';
      if (target == path) return path;
      if (await File(target).exists()) {
        throw const RingtoneException('A ringtone with that name already exists');
      }
      return (await from.rename(target)).path;
    },
    delete: ({uri, path}) async {
      final f = File(path ?? '');
      if (await f.exists()) await f.delete();
      return true;
    },
    canWriteSettings: () async => false,
    openWriteSettings: () async {},
    setDefault: (uri, type) async {},
    supportsSystemRingtones: false,
  );
}

/// Prepares songs (downloads Discover songs automatically), cuts the chosen
/// part and saves / renames / deletes / sets ringtones.
class RingtoneService {
  static final AppLogger _logger = AppLogger('RingtoneService');

  static const Duration minLength = Duration(seconds: 1);
  static const Duration maxLength = Duration(seconds: 60);
  static const Duration defaultLength = Duration(seconds: 30);
  static const int maxNameLength = 60;

  /// How many downloaded Discover songs are kept for re-editing.
  static const int cachedSources = 3;

  final FileDownloader _download;
  final Future<bool> Function(String path) _validate;
  final Future<Directory> Function() _cacheDir;
  final Trimmer _trim;
  final RingtonePlatform platform;

  /// Path of a Discover song the user already downloaded (if any).
  final String? Function(String songId)? downloadedPath;

  final DateTime Function() _now;

  RingtoneService({
    FileDownloader? download,
    Future<bool> Function(String path)? validate,
    Future<Directory> Function()? cacheDir,
    Trimmer? trim,
    RingtonePlatform? platform,
    this.downloadedPath,
    DateTime Function()? now,
  }) : _download = download ?? _dioDownload,
       _validate = validate ?? AudioHeaderValidator.isValidFile,
       _cacheDir = cacheDir ?? getTemporaryDirectory,
       _trim = trim ?? AudioTrimmer.trim,
       _now = now ?? DateTime.now,
       platform = platform ??
           (Platform.isAndroid
               ? RingtonePlatform.android
               : RingtonePlatform.files(getApplicationDocumentsDirectory));

  // ==================== RULES ====================

  /// Why a song can't be used, or null.
  static String? unavailableReason(Song song) {
    if (song.isRadio) return 'Live radio can\'t be made into a ringtone';
    if (song.isOnline && !song.canDownload) {
      return 'The artist doesn\'t allow downloads of this song, so it can\'t be made into a ringtone';
    }
    if (!song.isOnline && !AudioTrimmer.canTrim(song.path)) {
      final ext = AudioHeaderValidator.extensionOf(song.path);
      return '.$ext songs can\'t be trimmed yet (MP3, WAV and M4A are supported)';
    }
    return null;
  }

  /// The starting selection: 30 s from [position] (or from the start), kept
  /// inside the song.
  static (Duration, Duration) defaultSelection(Duration songLength, {Duration? position}) {
    if (songLength <= Duration.zero) return (Duration.zero, defaultLength);
    final length = songLength < defaultLength ? songLength : defaultLength;
    var start = position ?? Duration.zero;
    if (start < Duration.zero) start = Duration.zero;
    if (start + length > songLength) start = songLength - length;
    return (start, start + length);
  }

  /// Error message for a selection, or null when it is fine.
  static String? validateSelection(Duration start, Duration end, Duration songLength) {
    if (start < Duration.zero) return 'Start can\'t be before the song';
    if (songLength > Duration.zero && end > songLength + const Duration(milliseconds: 500)) {
      return 'End is after the song';
    }
    final length = end - start;
    if (length < minLength) return 'Pick at least 1 second';
    if (length > maxLength) return 'Ringtones can be at most 60 seconds';
    return null;
  }

  /// A safe display / file name; falls back to "<title> ringtone".
  static String sanitizeName(String raw, {String fallback = 'Ringtone'}) {
    String clean(String s) => s
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^\.+|\.+$'), '')
        .trim();
    var name = clean(raw);
    if (name.isEmpty) name = clean(fallback);
    if (name.isEmpty) name = 'Ringtone';
    if (name.length > maxNameLength) name = name.substring(0, maxNameLength).trim();
    return name;
  }

  /// [name], or "name (2)", "name (3)"... when taken (case-insensitive).
  static String uniqueName(String name, Iterable<String> taken) {
    final lower = taken.map((n) => n.toLowerCase()).toSet();
    if (!lower.contains(name.toLowerCase())) return name;
    var n = 2;
    while (lower.contains('$name ($n)'.toLowerCase())) {
      n++;
    }
    return '$name ($n)';
  }

  static String uniqueFile(String dir, String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    final ext = dot > 0 ? fileName.substring(dot) : '';
    var target = '$dir/$fileName';
    var n = 1;
    while (File(target).existsSync()) {
      target = '$dir/$base ($n)$ext';
      n++;
    }
    return target;
  }

  static String mimeFor(String extension) => switch (extension) {
    'wav' => 'audio/wav',
    'm4a' => 'audio/mp4',
    _ => 'audio/mpeg',
  };

  // ==================== SOURCE ====================

  Future<Directory> _sourceDir() async {
    final dir = Directory('${(await _cacheDir()).path}/ringtone_src');
    await dir.create(recursive: true);
    return dir;
  }

  /// A local file for [song]. Local songs use their file; Discover songs
  /// reuse a finished download or are downloaded automatically into a
  /// cache (progress 0..1 via [onProgress]).
  Future<String> prepareSource(Song song, {void Function(double progress)? onProgress}) async {
    final reason = unavailableReason(song);
    if (reason != null) throw RingtoneException(reason);

    if (!song.isOnline) {
      if (!await File(song.path).exists()) {
        throw const RingtoneException('This song file is missing from your device');
      }
      return song.path;
    }

    final downloaded = downloadedPath?.call(song.id);
    if (downloaded != null && downloaded.isNotEmpty && await File(downloaded).exists()) {
      return downloaded;
    }

    final dir = await _sourceDir();
    final key = (song.remoteId ?? song.id).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final target = File('${dir.path}/$key.mp3');
    if (await target.exists() && await _validate(target.path)) {
      onProgress?.call(1);
      await target.setLastModified(_now());
      return target.path;
    }

    final part = File('${target.path}.part');
    try {
      onProgress?.call(0);
      await _download(song.downloadUrl!, part.path, (received, total) {
        if (total > 0) onProgress?.call((received / total).clamp(0.0, 1.0));
      });
      if (!await _validate(part.path)) {
        throw const RingtoneException('This song is not available right now');
      }
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      onProgress?.call(1);
      await _pruneSources(dir, keep: target.path);
      return target.path;
    } on RingtoneException {
      rethrow;
    } on DioException catch (e) {
      throw RingtoneException(
        e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout
            ? 'No internet connection. Connect and try again'
            : 'Could not download the song (${e.response?.statusCode ?? 'network error'})',
      );
    } on SocketException {
      throw const RingtoneException('No internet connection. Connect and try again');
    } catch (e) {
      _logger.e('❌ Preparing "${song.title}" failed: $e');
      throw const RingtoneException('Could not download the song');
    } finally {
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _pruneSources(Directory dir, {required String keep}) async {
    try {
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp3')).toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      for (final f in files.skip(cachedSources)) {
        if (f.path != keep) await f.delete();
      }
    } catch (_) {}
  }

  // ==================== CREATE / EDIT ====================

  Future<RingtoneItem> create({
    required Song song,
    required String sourcePath,
    required Duration start,
    required Duration end,
    required String name,
    Duration? songLength,
  }) async {
    final error = validateSelection(start, end, songLength ?? song.duration);
    if (error != null) throw RingtoneException(error);
    final safeName = sanitizeName(name, fallback: '${song.displayTitle} ringtone');

    final work = Directory('${(await _cacheDir()).path}/ringtone_work');
    await work.create(recursive: true);
    final stamp = _now().millisecondsSinceEpoch;
    TrimResult? trimmed;
    try {
      try {
        trimmed = await _trim(
          inputPath: sourcePath,
          outputPathWithoutExtension: '${work.path}/rt_$stamp',
          start: start,
          end: end,
        );
      } on TrimException catch (e) {
        throw RingtoneException(e.message);
      }
      final ext = trimmed.extension;
      ({String uri, String path}) saved;
      try {
        saved = await platform.save(
          tempPath: trimmed.path,
          fileName: '$safeName.$ext',
          title: safeName,
          mimeType: mimeFor(ext),
          artist: song.artists.isEmpty ? null : song.artists.first,
        );
      } on PlatformException catch (e) {
        throw RingtoneException('Could not save the ringtone (${e.message ?? e.code})');
      } on FileSystemException {
        throw const RingtoneException('Could not save the ringtone');
      }
      final kept = trimmed.duration;
      _logger.i('🔔 Ringtone "$safeName" saved -> ${saved.path}');
      return RingtoneItem(
        id: 'rt_$stamp',
        name: safeName,
        path: saved.path,
        uri: saved.uri.isEmpty ? null : saved.uri,
        sourceSongId: song.id,
        songTitle: song.displayTitle,
        artist: song.displayArtist,
        albumArt: song.albumArt,
        startMs: start.inMilliseconds,
        endMs: start.inMilliseconds + (kept > Duration.zero ? kept : end - start).inMilliseconds,
        createdAtMs: stamp,
        fromOnline: song.isOnline,
      );
    } finally {
      final p = trimmed?.path;
      if (p != null) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  Future<RingtoneItem> rename(RingtoneItem item, String newName) async {
    final name = sanitizeName(newName, fallback: item.name);
    if (name == item.name) return item;
    final ext = item.extension.isEmpty ? 'mp3' : item.extension;
    try {
      final path = await platform.rename(
        uri: item.uri,
        path: item.path.isEmpty ? null : item.path,
        fileName: '$name.$ext',
        title: name,
      );
      return item.copyWith(name: name, path: path.isEmpty ? item.path : path);
    } on PlatformException catch (e) {
      throw RingtoneException(e.message ?? 'Could not rename the ringtone');
    } on FileSystemException {
      throw const RingtoneException('Could not rename the ringtone');
    }
  }

  Future<void> delete(RingtoneItem item) async {
    try {
      await platform.delete(uri: item.uri, path: item.path.isEmpty ? null : item.path);
    } on PlatformException catch (e) {
      throw RingtoneException(e.message ?? 'Could not delete the ringtone');
    }
  }

  /// Sets [item] as the phone's ringtone / notification / alarm sound.
  Future<RingtoneSetResult> setAs(RingtoneItem item, RingtoneUse use) async {
    if (!platform.supportsSystemRingtones || item.uri == null) {
      return RingtoneSetResult.unsupported;
    }
    try {
      if (!await platform.canWriteSettings()) return RingtoneSetResult.needsPermission;
      await platform.setDefault(item.uri!, use.name);
      return RingtoneSetResult.done;
    } on PlatformException catch (e) {
      if (e.code == 'no_permission') return RingtoneSetResult.needsPermission;
      _logger.e('❌ Could not set ringtone: ${e.message}');
      return RingtoneSetResult.failed;
    }
  }

  Future<void> openPermissionSettings() => platform.openWriteSettings();

  /// Whether the ringtone file is still on the device.
  Future<bool> exists(RingtoneItem item) async {
    if (item.path.isEmpty) return item.uri != null;
    return File(item.path).exists();
  }

  static final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(minutes: 5)),
  );

  static Future<void> _dioDownload(String url, String savePath, void Function(int, int) onProgress) =>
      _dio.download(url, savePath, onReceiveProgress: onProgress);
}
