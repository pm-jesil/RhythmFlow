import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../screens/online/bloc/online_library_bloc.dart';
import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import '../media_store_bridge.dart';

typedef FileDownloader =
    Future<void> Function(
      String url,
      String savePath,
      void Function(int received, int total) onProgress,
    );
typedef TagWriter = Future<void> Function(String path, Song song, Uint8List? cover);
typedef CoverFetcher = Future<Uint8List?> Function(String url);
typedef AudioSaver = Future<String> Function(String tempPath, String fileName, Song song);

/// Downloads Discover songs that their artists allow to be downloaded and
/// saves them into the device music library (`Music/RhythmFlow`), where the
/// v1.1.1 library auto-update picks them up for "My Music".
class DownloadService {
  static final AppLogger _logger = AppLogger('DownloadService');

  final OnlineLibraryBloc library;
  final FileDownloader _download;
  final TagWriter _writeTags;
  final CoverFetcher _fetchCover;
  final AudioSaver _save;
  final Future<Directory> Function() _tempDir;

  /// Called after a song was saved (used to refresh "My Music").
  final VoidCallback? onSaved;

  final Set<String> _active = {};

  DownloadService({
    required this.library,
    FileDownloader? download,
    TagWriter? writeTags,
    CoverFetcher? fetchCover,
    AudioSaver? save,
    Future<Directory> Function()? tempDir,
    this.onSaved,
  }) : _download = download ?? _dioDownload,
       _writeTags = writeTags ?? _writeAudioTags,
       _fetchCover = fetchCover ?? _dioBytes,
       _save = save ?? _saveToMusicLibrary,
       _tempDir = tempDir ?? getTemporaryDirectory;

  bool isDownloading(String songId) => _active.contains(songId);

  /// `Artist - Title.mp3` with characters that are invalid in file names
  /// removed.
  static String fileNameFor(Song song) {
    String clean(String s) => s
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final artist = clean(song.artists.isEmpty ? '' : song.artists.first);
    final title = clean(song.title);
    var name = artist.isEmpty ? title : '$artist - $title';
    if (name.isEmpty) name = 'jamendo_${song.remoteId ?? song.id}';
    if (name.length > 120) name = name.substring(0, 120).trim();
    return '$name.mp3';
  }

  /// Starts a download. Returns the saved path, or null when it failed or
  /// was not allowed. Progress is reported through [library].
  Future<String?> download(Song song) async {
    if (!song.canDownload) {
      _emit(song, DownloadPhase.failed, error: 'Download not allowed for this song');
      return null;
    }
    if (!_active.add(song.id)) return null; // already running
    _emit(song, DownloadPhase.queued);

    final tempPath =
        '${(await _tempDir()).path}/rf_dl_${song.remoteId ?? song.id}.mp3';
    try {
      var lastReported = -1.0;
      await _download(song.downloadUrl!, tempPath, (received, total) {
        if (total <= 0) return;
        final progress = (received / total).clamp(0.0, 1.0);
        // Report at most every 2 % to keep the UI calm.
        if (progress - lastReported >= 0.02 || progress == 1.0) {
          lastReported = progress;
          _emit(song, DownloadPhase.downloading, progress: progress);
        }
      });

      Uint8List? cover;
      final art = song.albumArt;
      if (art != null && art.startsWith('http')) {
        try {
          cover = await _fetchCover(art);
        } catch (_) {}
      }
      try {
        await _writeTags(tempPath, song, cover);
      } catch (e) {
        _logger.w('⚠️ Could not write tags (file still saved): $e');
      }

      final savedPath = await _save(tempPath, fileNameFor(song), song);
      _emit(song, DownloadPhase.completed, progress: 1, localPath: savedPath);
      _logger.i('✅ Downloaded "${song.title}" -> $savedPath');
      onSaved?.call();
      return savedPath;
    } catch (e) {
      _logger.e('❌ Download failed for "${song.title}": $e');
      _emit(song, DownloadPhase.failed, error: _describe(e));
      return null;
    } finally {
      _active.remove(song.id);
      try {
        final temp = File(tempPath);
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
    }
  }

  void _emit(
    Song song,
    DownloadPhase phase, {
    double progress = 0,
    String? localPath,
    String? error,
  }) {
    library.add(
      OnlineLibraryEvent.downloadUpdated(
        songId: song.id,
        download: OnlineDownload(
          phase: phase,
          progress: progress,
          localPath: localPath,
          error: error,
          song: song,
        ),
      ),
    );
  }

  static String _describe(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError) return 'No internet connection';
      if (e.response?.statusCode != null) return 'Server error (${e.response!.statusCode})';
      return 'Network error';
    }
    if (e is FileSystemException) return 'Could not save the file';
    return 'Download failed';
  }

  // ==================== DEFAULT IMPLEMENTATIONS ====================

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  static Future<void> _dioDownload(
    String url,
    String savePath,
    void Function(int, int) onProgress,
  ) async {
    await _dio.download(url, savePath, onReceiveProgress: onProgress);
  }

  static Future<Uint8List?> _dioBytes(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  }

  static Future<void> _writeAudioTags(String path, Song song, Uint8List? cover) {
    return AudioTags.write(
      path,
      Tag(
        title: song.title,
        trackArtist: song.artists.isEmpty ? null : song.artists.first,
        album: song.albums.isEmpty ? null : song.albums.first,
        albumArtist: song.albumArtist ?? (song.artists.isEmpty ? null : song.artists.first),
        year: song.year,
        genre: song.genre,
        trackNumber: song.trackNumber,
        // Keep the Creative Commons licence with the file.
        lyrics: song.licenseUrl == null
            ? null
            : 'Licence: ${song.licenseUrl}\nSource: ${song.shareUrl ?? 'jamendo.com'}',
        pictures: [
          if (cover != null)
            Picture(
              pictureType: PictureType.coverFront,
              mimeType: MimeType.jpeg,
              bytes: cover,
            ),
        ],
      ),
    );
  }

  /// Android: MediaStore insert into Music/RhythmFlow (no storage permission
  /// needed on Android 10+). Other platforms: app documents folder.
  static Future<String> _saveToMusicLibrary(
    String tempPath,
    String fileName,
    Song song,
  ) async {
    if (Platform.isAndroid) {
      return MediaStoreBridge.saveAudioToMusic(
        tempPath: tempPath,
        fileName: fileName,
        title: song.title,
        artist: song.artists.isEmpty ? null : song.artists.first,
        album: song.albums.isEmpty ? null : song.albums.first,
      );
    }
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/Music/RhythmFlow',
    );
    await dir.create(recursive: true);
    final target = '${dir.path}/$fileName';
    await File(tempPath).copy(target);
    return target;
  }
}
