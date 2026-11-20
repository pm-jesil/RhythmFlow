import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/fetch_songs.dart';
import 'package:rhythmflow/utils/services/format_utils.dart';
import 'package:rhythmflow/utils/services/metadata_extractor/metadata_extractor.dart';

import 'library_test_utils.dart';

/// End-to-end tests of the scanner against a real temporary folder tree.
void main() {
  late FakeMusicDevice device;

  setUp(() async {
    device = await FakeMusicDevice.create();
  });

  tearDown(() async {
    await device.dispose();
  });

  Future<List<Song>> fullScan({
    Map<String, List<String>>? whitelist,
    List<String>? formats,
  }) async {
    final songs = <Song>[];
    var completed = false;
    await FetchSongsService.fetchAllSongsProgressive(
      whitelistedFolders: whitelist ?? device.whitelist(),
      supportedFormats: formats ?? FormatUtils.defaultSupportedFormats,
      onProgress: (batch, isComplete, total) {
        songs.addAll(batch);
        if (isComplete) completed = true;
      },
    );
    expect(completed, isTrue, reason: 'scan must report completion');
    return songs;
  }

  Future<LibraryScanResult> rescan(
    List<Song> library, {
    Map<String, List<String>>? whitelist,
    List<String>? formats,
  }) {
    return FetchSongsService.scanLibrary(
      library,
      whitelistedFolders: whitelist ?? device.whitelist(),
      supportedFormats: formats ?? FormatUtils.defaultSupportedFormats,
    );
  }

  List<Song> apply(List<Song> library, LibraryScanResult r) {
    final updated = {for (final s in r.updatedSongs) s.id: s};
    return [
      for (final s in library)
        if (!r.invalidSongIds.contains(s.id)) updated[s.id] ?? s,
      ...r.newSongs,
    ];
  }

  group('path discovery', () {
    test('finds audio files recursively in all whitelisted folders', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await device.addSong('Music/Malayalam/Premam/b.mp3', const FakeTags(title: 'B'));
      await device.addSong('Download/c.mp3', const FakeTags(title: 'C'));
      await device.addSong('Other/not-whitelisted.mp3', const FakeTags(title: 'X'));

      final paths = await FetchSongsService.scanSongPaths(
        whitelistedFolders: device.whitelist(),
        supportedFormats: FormatUtils.defaultSupportedFormats,
      );
      expect(paths!.map((p) => p.split('/').last).toList()..sort(), [
        'a.mp3',
        'b.mp3',
        'c.mp3',
      ]);
    });

    test('ignores videos and formats that are not enabled', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await FakeMusicDevice.writeMp3('${device.musicDir}/clip.mp4');
      await FakeMusicDevice.writeMp3('${device.musicDir}/song.flac');
      await File('${device.musicDir}/notes.txt').writeAsString('x');

      final paths = await FetchSongsService.scanSongPaths(
        whitelistedFolders: device.whitelist(),
        supportedFormats: const ['.mp3'],
      );
      expect(paths!.map((p) => p.split('/').last), ['a.mp3']);
    });

    test('overlapping whitelisted folders do not produce duplicates', () async {
      await device.addSong('Music/Sub/a.mp3', const FakeTags(title: 'A'));
      final paths = await FetchSongsService.scanSongPaths(
        whitelistedFolders: device.whitelist(
          folders: [device.musicDir, '${device.musicDir}/Sub'],
        ),
        supportedFormats: const ['.mp3'],
      );
      expect(paths, hasLength(1));
    });

    test('returns null (scan impossible) without permission', () async {
      device.permissionGranted = false;
      expect(
        await FetchSongsService.scanSongPaths(
          whitelistedFolders: device.whitelist(),
        ),
        isNull,
      );
    });

    test('returns null when no whitelisted folder exists', () async {
      expect(
        await FetchSongsService.scanSongPaths(
          whitelistedFolders: device.whitelist(folders: ['/does/not/exist']),
        ),
        isNull,
      );
    });

    test('getAllFoldersFromWhitelist lists nested folders', () async {
      await device.addSong('Music/A/B/c.mp3', const FakeTags(title: 'C'));
      final folders = await FetchSongsService.getAllFoldersFromWhitelist(
        device.whitelist(folders: [device.musicDir]),
      );
      expect(folders, [
        device.musicDir,
        '${device.musicDir}/A',
        '${device.musicDir}/A/B',
      ]);
    });
  });

  group('first (full) scan', () {
    test('adds every song exactly once with file signature', () async {
      for (var i = 0; i < 23; i++) {
        await device.addSong('Music/s$i.mp3', FakeTags(title: 'Song $i'));
      }
      final songs = await fullScan();
      expect(songs, hasLength(23));
      expect(songs.map((s) => s.id).toSet(), hasLength(23));
      expect(songs.every((s) => s.fileModifiedAt != null), isTrue);
    });

    test('songs with unreadable duration are kept', () async {
      await device.addSong(
        'Music/recording.mp3',
        const FakeTags(title: 'Voice memo', duration: Duration.zero),
      );
      expect(await fullScan(), hasLength(1));
    });

    test('non-Latin titled songs are all kept', () async {
      const titles = ['മഴ', 'പൂമുത്തോളെ', 'तुम ही हो', 'கண்ணான கண்ணே'];
      for (var i = 0; i < titles.length; i++) {
        await device.addSong(
          'Music/$i.mp3',
          FakeTags(title: titles[i], artists: ['Artist $i']),
        );
      }
      expect(await fullScan(), hasLength(4));
    });

    test('a duplicate copy in another folder/batch is removed once', () async {
      for (var i = 0; i < 15; i++) {
        await device.addSong('Music/s$i.mp3', FakeTags(title: 'Song $i'));
      }
      // Same recording again in Download (sorted into a later batch).
      await device.addSong('Download/copy.mp3', const FakeTags(title: 'Song 3'));
      final songs = await fullScan();
      expect(songs, hasLength(15));
      // Exactly one of the two copies survives (first in path order).
      final copies = songs.where(
        (s) => s.path.endsWith('copy.mp3') || s.path.endsWith('/s3.mp3'),
      );
      expect(copies, hasLength(1));
    });

    test('very short clips are skipped', () async {
      await device.addSong(
        'Music/beep.mp3',
        const FakeTags(title: 'Beep', duration: Duration(milliseconds: 500)),
      );
      await device.addSong('Music/song.mp3', const FakeTags(title: 'Song'));
      final songs = await fullScan();
      expect(songs.map((s) => s.title), ['Song']);
    });

    test('mp3 with leading padding before the first frame is accepted', () async {
      final path = '${device.musicDir}/padded.mp3';
      await FakeMusicDevice.writeMp3(
        path,
        header: [...List<int>.filled(300, 0), 0xFF, 0xFB, 0x90, 0x64],
      );
      device.tags[path] = const FakeTags(title: 'Padded');
      expect(await fullScan(), hasLength(1));
    });

    test('permission missing: completes with no songs', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      device.permissionGranted = false;
      expect(await fullScan(), isEmpty);
    });
  });

  group('incremental scan (auto update)', () {
    test('new file is detected and only it is read', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final library = await fullScan();
      device.extractedPaths.clear();

      final b = await device.addSong('Download/b.mp3', const FakeTags(title: 'B'));
      final result = await rescan(library);
      expect(result.scanSucceeded, isTrue);
      expect(result.newSongs.map((s) => s.path), [b]);
      expect(result.invalidSongIds, isEmpty);
      expect(device.extractedPaths, [b], reason: 'existing songs not re-read');
    });

    test('deleted file is reported as invalid', () async {
      final a = await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await device.addSong('Music/b.mp3', const FakeTags(title: 'B'));
      final library = await fullScan();

      await device.deleteFile(a);
      final result = await rescan(library);
      final removedSong = library.firstWhere((s) => s.path == a);
      expect(result.invalidSongIds, [removedSong.id]);
      expect(apply(library, result), hasLength(1));
    });

    test('removing a folder from the whitelist removes its songs', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await device.addSong('Download/b.mp3', const FakeTags(title: 'B'));
      final library = await fullScan();
      expect(library, hasLength(2));

      final result = await rescan(
        library,
        whitelist: device.whitelist(folders: [device.musicDir]),
      );
      expect(apply(library, result).map((s) => s.title), ['A']);
    });

    test('disabling a format removes those songs', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final library = await fullScan();
      final result = await rescan(library, formats: const ['.flac']);
      expect(result.invalidSongIds, hasLength(1));
    });

    test('edited file is re-read but keeps id, play count and favourite', () async {
      final a = await device.addSong(
        'Music/a.mp3',
        const FakeTags(title: 'Old title', artists: ['Old Artist']),
      );
      final library = (await fullScan())
          .map((s) => s.copyWith(playCount: 9, isFavorite: true))
          .toList();
      final originalId = library.single.id;

      await device.editSong(
        a,
        const FakeTags(title: 'New title', artists: ['New Artist']),
      );
      final result = await rescan(library);
      expect(result.newSongs, isEmpty);
      expect(result.invalidSongIds, isEmpty);
      final updated = result.updatedSongs.single;
      expect(updated.id, originalId);
      expect(updated.title, 'New title');
      expect(updated.artists, ['New Artist']);
      expect(updated.playCount, 9);
      expect(updated.isFavorite, isTrue);

      // A second scan finds nothing to update any more.
      final again = await rescan(apply(library, result));
      expect(again.updatedSongs, isEmpty);
    });

    test('songs indexed by the old version are back-filled without re-reading', () async {
      final a = await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final stat = await File(a).stat();
      final legacy = Song(
        id: FetchSongsService.songIdFor(a, stat),
        title: 'A',
        artists: const ['Artist'],
        albums: const ['Album'],
        path: a,
        duration: const Duration(minutes: 3),
      );
      device.extractedPaths.clear();

      final result = await rescan([legacy]);
      expect(device.extractedPaths, isEmpty);
      expect(result.updatedSongs.single.fileModifiedAt, isNotNull);
      expect(result.updatedSongs.single.id, legacy.id);
    });

    test('legacy song whose file changed since indexing is re-read', () async {
      final a = await device.addSong('Music/a.mp3', const FakeTags(title: 'New'));
      final legacy = Song(
        id: 'id-from-an-older-file-version',
        title: 'Old',
        artists: const ['Artist'],
        albums: const ['Album'],
        path: a,
        duration: const Duration(minutes: 3),
      );
      final result = await rescan([legacy]);
      expect(result.updatedSongs.single.title, 'New');
      expect(result.updatedSongs.single.id, legacy.id);
    });

    test('permission lost: scan fails and nothing is removed', () async {
      await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final library = await fullScan();
      device.permissionGranted = false;
      final result = await rescan(library);
      expect(result.scanSucceeded, isFalse);
      expect(result.invalidSongIds, isEmpty);
    });

    test('all files deleted: every song is removed', () async {
      final a = await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final b = await device.addSong('Music/b.mp3', const FakeTags(title: 'B'));
      final library = await fullScan();
      await device.deleteFile(a);
      await device.deleteFile(b);
      final result = await rescan(library);
      expect(result.scanSucceeded, isTrue);
      expect(result.invalidSongIds, hasLength(2));
    });
  });

  group('skip cache', () {
    test('skipped files are not re-read on every scan', () async {
      final beep = await device.addSong(
        'Music/beep.mp3',
        const FakeTags(title: 'Beep', duration: Duration(seconds: 1)),
      );
      final library = await fullScan();
      expect(library, isEmpty);
      expect(device.extractionCount(beep), 1);

      await rescan(library);
      await rescan(library);
      expect(device.extractionCount(beep), 1);
    });

    test('a skipped file is re-evaluated after it changes', () async {
      final beep = await device.addSong(
        'Music/beep.mp3',
        const FakeTags(title: 'Beep', duration: Duration(seconds: 1)),
      );
      final library = await fullScan();
      await device.editSong(beep, const FakeTags(title: 'Real song'));
      final result = await rescan(library);
      expect(result.newSongs.map((s) => s.title), ['Real song']);
    });

    test('duplicate comes back when the original is deleted', () async {
      final original = await device.addSong(
        'Music/a.mp3',
        const FakeTags(title: 'Hello', artists: ['Adele']),
      );
      final copy = await device.addSong(
        'Music/b.mp3',
        const FakeTags(title: 'Hello', artists: ['Adele']),
      );
      final library = await fullScan();
      expect(library.map((s) => s.path), [original]);

      await device.deleteFile(original);
      final result = await rescan(library);
      expect(result.invalidSongIds, hasLength(1));
      expect(result.newSongs.map((s) => s.path), [copy]);
      expect(apply(library, result), hasLength(1));
    });

    test('cache can be persisted and restored', () async {
      await device.addSong(
        'Music/beep.mp3',
        const FakeTags(title: 'Beep', duration: Duration(seconds: 1)),
      );
      var changes = 0;
      FetchSongsService.onSkippedFilesChanged = () => changes++;
      await fullScan();
      expect(changes, greaterThan(0));
      final saved = Map<String, String>.from(FetchSongsService.skippedFiles);
      expect(saved, hasLength(1));

      FetchSongsService.clearSkippedFiles();
      expect(FetchSongsService.skippedFiles, isEmpty);
      FetchSongsService.restoreSkippedFiles(saved);
      expect(FetchSongsService.skippedFiles, saved);
    });
  });

  group('consistency', () {
    test('full scan and incremental scans give the same song count', () async {
      // Mixed library: duplicates across batches, non-Latin titles, unknown
      // durations and a short clip.
      for (var i = 0; i < 12; i++) {
        await device.addSong('Music/s$i.mp3', FakeTags(title: 'Song $i'));
      }
      await device.addSong('Music/x/m.mp3', const FakeTags(title: 'മഴ'));
      await device.addSong('Music/x/t.mp3', const FakeTags(title: 'கண்ணே'));
      await device.addSong(
        'Music/x/z.mp3',
        const FakeTags(title: 'Memo', duration: Duration.zero),
      );
      await device.addSong(
        'Music/x/beep.mp3',
        const FakeTags(title: 'Beep', duration: Duration(seconds: 1)),
      );
      await device.addSong('Download/dup.mp3', const FakeTags(title: 'Song 7'));

      final full = await fullScan();

      // Simulate a user whose library was built incrementally: start with one
      // song, then add the rest through incremental scans.
      FetchSongsService.clearSkippedFiles();
      var library = <Song>[full.first];
      library = apply(library, await rescan(library));
      library = apply(library, await rescan(library));

      expect(full, hasLength(15));
      expect(library, hasLength(full.length));
      expect(
        library.map((s) => s.path).toSet(),
        equals(full.map((s) => s.path).toSet()),
      );
    });

    test('songIdFor matches MetadataUtils.generateSongId', () async {
      final a = await device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final stat = await File(a).stat();
      expect(
        FetchSongsService.songIdFor(a, stat),
        await MetadataUtils.generateSongId(a),
      );
    });
  });

  group('mergeRefreshedSong', () {
    test('keeps identity and user data, takes new metadata', () {
      final old = testSong(id: 'keep', title: 'Old', playCount: 4)
          .copyWith(isFavorite: true, dateAdded: DateTime(2020));
      final fresh = testSong(id: 'other', title: 'Fresh', playCount: 0);
      final merged = FetchSongsService.mergeRefreshedSong(old, fresh);
      expect(merged.id, 'keep');
      expect(merged.title, 'Fresh');
      expect(merged.playCount, 4);
      expect(merged.isFavorite, isTrue);
      expect(merged.dateAdded, DateTime(2020));
    });
  });
}
