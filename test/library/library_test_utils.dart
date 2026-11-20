import 'dart:io';
import 'dart:typed_data';

import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/fetch_songs.dart';

/// Tags the fake extractor returns for a file.
class FakeTags {
  final String title;
  final List<String> artists;
  final List<String> albums;
  final Duration duration;
  final String? albumArtist;
  final int? year;

  const FakeTags({
    required this.title,
    this.artists = const ['Artist'],
    this.albums = const ['Album'],
    this.duration = const Duration(minutes: 3),
    this.albumArtist,
    this.year,
  });
}

/// A temporary "device" with music folders, real files and a fake tag reader
/// that replaces the native `audiotags` library during tests.
class FakeMusicDevice {
  final Directory root;
  final Map<String, FakeTags> tags = {};
  final List<String> extractedPaths = [];
  bool permissionGranted = true;
  int permissionChecks = 0;

  FakeMusicDevice._(this.root);

  static Future<FakeMusicDevice> create() async {
    final root = await Directory.systemTemp.createTemp('rhythmflow_test_');
    final device = FakeMusicDevice._(root);
    device.install();
    return device;
  }

  String get musicDir => '${root.path}/Music';
  String get downloadDir => '${root.path}/Download';
  String get otherDir => '${root.path}/Other';

  Map<String, List<String>> whitelist({List<String>? folders}) => {
    'test': folders ?? [musicDir, downloadDir],
  };

  /// Points FetchSongsService at this device.
  void install() {
    FetchSongsService.resetForTesting();
    FetchSongsService.platformKey = 'test';
    FetchSongsService.batchDelay = Duration.zero;
    FetchSongsService.permissionChecker = () async {
      permissionChecks++;
      return permissionGranted;
    };
    FetchSongsService.extractor = _extract;
  }

  Future<Song?> _extract(String path) async {
    extractedPaths.add(path);
    final t = tags[path];
    if (t == null) return null;
    final stat = await File(path).stat();
    return Song(
      id: FetchSongsService.songIdFor(path, stat),
      title: t.title,
      artists: t.artists,
      albums: t.albums,
      path: path,
      duration: t.duration,
      albumArtist: t.albumArtist,
      year: t.year,
      fileSize: stat.size,
      dateAdded: stat.changed,
      playCount: 0,
      isFavorite: false,
    );
  }

  /// Writes a file that passes header validation (ID3 tag + padding) and
  /// registers its tags.
  Future<String> addSong(
    String relativePath,
    FakeTags tags, {
    int sizeBytes = 20 * 1024,
    DateTime? modified,
  }) async {
    final path = '${root.path}/$relativePath';
    await writeMp3(path, sizeBytes: sizeBytes, modified: modified);
    this.tags[path] = tags;
    return path;
  }

  /// Simulates editing the tags of a file (content + mtime change).
  Future<void> editSong(String path, FakeTags newTags) async {
    tags[path] = newTags;
    final file = File(path);
    final bytes = await file.readAsBytes();
    await file.writeAsBytes([...bytes, 0, 0, 0, 0], flush: true);
    final stat = await file.stat();
    await file.setLastModified(stat.modified.add(const Duration(seconds: 5)));
  }

  Future<void> deleteFile(String path) => File(path).delete();

  int extractionCount(String path) =>
      extractedPaths.where((p) => p == path).length;

  Future<void> dispose() async {
    FetchSongsService.resetForTesting();
    if (await root.exists()) await root.delete(recursive: true);
  }

  static Future<void> writeMp3(
    String path, {
    int sizeBytes = 20 * 1024,
    DateTime? modified,
    List<int>? header,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final data = Uint8List(sizeBytes);
    final head = header ?? const [0x49, 0x44, 0x33, 0x03, 0x00]; // "ID3"
    data.setRange(0, head.length, head);
    await file.writeAsBytes(data, flush: true);
    if (modified != null) await file.setLastModified(modified);
  }
}

Song testSong({
  required String id,
  String? title,
  List<String>? artists,
  List<String>? albums,
  String? path,
  Duration duration = const Duration(minutes: 3),
  String? albumArtist,
  String? albumArt,
  int? playCount,
}) {
  return Song(
    id: id,
    title: title ?? 'Song $id',
    artists: artists ?? const ['Artist'],
    albums: albums ?? const ['Album'],
    path: path ?? '/music/$id.mp3',
    duration: duration,
    albumArtist: albumArtist,
    albumArt: albumArt,
    playCount: playCount,
  );
}
