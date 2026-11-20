import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/screens/widgets/library_filter_helper.dart';
import 'package:rhythmflow/utils/models/album/album_model.dart';
import 'package:rhythmflow/utils/models/artist/artist_model.dart';
import 'package:rhythmflow/utils/services/album_art_cleanup.dart';
import 'package:rhythmflow/utils/services/audio_header_validator.dart';
import 'package:rhythmflow/utils/services/fetch_songs.dart';
import 'package:rhythmflow/utils/services/music_service.dart';

import 'library_test_utils.dart';

void main() {
  group('AudioHeaderValidator', () {
    test('accepts MP3 with ID3 tag', () {
      expect(
        AudioHeaderValidator.isValidHeader([0x49, 0x44, 0x33, 3, 0], 'mp3'),
        isTrue,
      );
    });

    test('accepts MP3 whose first frame is preceded by padding', () {
      final header = List<int>.filled(600, 0, growable: true)
        ..addAll([0xFF, 0xFB, 0x90, 0x64, 0x00]);
      expect(AudioHeaderValidator.isValidHeader(header, '.MP3'), isTrue);
    });

    test('rejects MP3 that is only 0xFF bytes or random data', () {
      expect(
        AudioHeaderValidator.isValidHeader(List<int>.filled(64, 0xFF), 'mp3'),
        isFalse,
      );
      expect(
        AudioHeaderValidator.isValidHeader(List<int>.filled(64, 0x41), 'mp3'),
        isFalse,
      );
    });

    test('accepts FLAC with fLaC marker or a leading ID3 tag', () {
      expect(
        AudioHeaderValidator.isValidHeader([0x66, 0x4C, 0x61, 0x43], 'flac'),
        isTrue,
      );
      expect(
        AudioHeaderValidator.isValidHeader([0x49, 0x44, 0x33, 4], 'flac'),
        isTrue,
      );
    });

    test('validates OGG/OPUS, WAV and MP4 family magic numbers', () {
      const ogg = [0x4F, 0x67, 0x67, 0x53];
      expect(AudioHeaderValidator.isValidHeader(ogg, 'ogg'), isTrue);
      expect(AudioHeaderValidator.isValidHeader(ogg, 'opus'), isTrue);
      expect(
        AudioHeaderValidator.isValidHeader([0x52, 0x49, 0x46, 0x46], 'wav'),
        isTrue,
      );
      const mp4 = [0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70];
      for (final ext in ['m4a', 'm4b', 'm4p', 'alac']) {
        expect(AudioHeaderValidator.isValidHeader(mp4, ext), isTrue);
      }
      expect(
        AudioHeaderValidator.isValidHeader([0, 0, 0, 0, 0, 0, 0, 0], 'm4a'),
        isFalse,
      );
    });

    test('trusts the extension for formats without magic numbers', () {
      expect(AudioHeaderValidator.isValidHeader([1, 2, 3, 4], 'amr'), isTrue);
    });

    test('isValidFile rejects tiny or missing files', () async {
      final dir = await Directory.systemTemp.createTemp('hdr_');
      addTearDown(() => dir.delete(recursive: true));
      final tiny = File('${dir.path}/tiny.mp3')
        ..writeAsBytesSync([0x49, 0x44, 0x33]);
      expect(await AudioHeaderValidator.isValidFile(tiny.path), isFalse);
      expect(
        await AudioHeaderValidator.isValidFile('${dir.path}/missing.mp3'),
        isFalse,
      );
      final ok = '${dir.path}/ok.mp3';
      await FakeMusicDevice.writeMp3(ok);
      expect(await AudioHeaderValidator.isValidFile(ok), isTrue);
    });

    test('extensionOf handles case, folders with dots and no extension', () {
      expect(AudioHeaderValidator.extensionOf('/a/b/Song.MP3'), 'mp3');
      expect(AudioHeaderValidator.extensionOf('/a.dir/song'), '');
      expect(AudioHeaderValidator.extensionOf('/a/song.'), '');
    });
  });

  group('FetchSongsService filters', () {
    test('keeps songs with unknown (zero) duration', () {
      final song = testSong(id: '1', duration: Duration.zero);
      expect(FetchSongsService.passesBasicFilters(song), isTrue);
    });

    test('drops known very short clips (< 2 s)', () {
      final song = testSong(id: '1', duration: const Duration(seconds: 1));
      expect(FetchSongsService.passesBasicFilters(song), isFalse);
    });

    test('keeps long files (DJ mixes, audiobooks) and big files', () {
      final song = testSong(id: '1', duration: const Duration(hours: 3))
          .copyWith(fileSize: 500 * 1024 * 1024);
      expect(FetchSongsService.passesBasicFilters(song), isTrue);
    });

    test('drops files under 10 KB', () {
      final song = testSong(id: '1').copyWith(fileSize: 5 * 1024);
      expect(FetchSongsService.passesBasicFilters(song), isFalse);
    });

    test('normalizeSong fills missing title/artist/album instead of dropping', () {
      final song = testSong(
        id: '1',
        title: '  ',
        artists: const [],
        albums: const [''],
        path: '/music/My Recording.wav',
      );
      final normalized = FetchSongsService.normalizeSong(song);
      expect(normalized.title, 'My Recording');
      expect(normalized.artists, ['Unknown Artist']);
      expect(normalized.albums, ['Unknown Album']);
    });

    test('isSupportedAudioPath excludes videos and disabled formats', () {
      const formats = ['.mp3', '.m4a'];
      expect(FetchSongsService.isSupportedAudioPath('/a/b.MP3', formats), isTrue);
      expect(FetchSongsService.isSupportedAudioPath('/a/b.mp4', formats), isFalse);
      expect(FetchSongsService.isSupportedAudioPath('/a/b.flac', formats), isFalse);
      expect(FetchSongsService.isSupportedAudioPath('/a/noext', formats), isFalse);
    });
  });

  group('MusicService album grouping', () {
    test('same album name by different album artists = two albums', () {
      final songs = [
        testSong(id: '1', albums: ['Greatest Hits'], albumArtist: 'Queen'),
        testSong(id: '2', albums: ['Greatest Hits'], albumArtist: 'ABBA'),
        testSong(id: '3', albums: ['Greatest Hits'], albumArtist: 'Queen'),
      ];
      final albums = MusicService.fetchAlbumList(songs);
      expect(albums, hasLength(2));
      final queen = albums.firstWhere((a) => a.songIds.contains('1'));
      expect(queen.songIds, ['1', '3']);
    });

    test('soundtrack with many singers in one folder stays one album', () {
      final songs = [
        testSong(id: '1', albums: ['Premam'], artists: ['Vineeth'], path: '/m/Premam/1.mp3'),
        testSong(id: '2', albums: ['Premam'], artists: ['Rajesh'], path: '/m/Premam/2.mp3'),
        testSong(id: '3', albums: ['Premam'], artists: ['Shabareesh'], path: '/m/Premam/3.mp3'),
      ];
      final albums = MusicService.fetchAlbumList(songs);
      expect(albums, hasLength(1));
      expect(albums.single.songIds, hasLength(3));
    });

    test('same album name in two folders without album artist = two albums', () {
      final songs = [
        testSong(id: '1', albums: ['Hits'], path: '/m/A/1.mp3'),
        testSong(id: '2', albums: ['Hits'], path: '/m/B/2.mp3'),
      ];
      expect(MusicService.fetchAlbumList(songs), hasLength(2));
    });

    test('all "Unknown Album" songs form a single album', () {
      final songs = [
        testSong(id: '1', albums: ['Unknown Album'], path: '/a/1.mp3'),
        testSong(id: '2', albums: [], path: '/b/2.mp3'),
      ];
      final albums = MusicService.fetchAlbumList(songs);
      expect(albums, hasLength(1));
      expect(albums.single.name, 'Unknown Album');
      expect(albums.single.songIds, ['1', '2']);
    });

    test('album IDs are stable and not based on String.hashCode', () {
      final song = testSong(id: '1', albums: ['Thriller'], albumArtist: 'MJ');
      final id1 = MusicService.albumIdForSong(song);
      final id2 = MusicService.albumIdForSong(song.copyWith(id: '2'));
      expect(id1, id2);
      expect(id1, matches(RegExp(r'^album_[0-9a-f]{16}$')));
      expect(id1, isNot('album_${'Thriller'.hashCode}'));
    });

    test('rebuilding drops removed songs and empty albums (correct counts)', () {
      final songs = [
        testSong(id: '1', albums: ['A'], albumArtist: 'X'),
        testSong(id: '2', albums: ['A'], albumArtist: 'X'),
        testSong(id: '3', albums: ['B'], albumArtist: 'X'),
      ];
      final before = MusicService.fetchAlbumList(songs);
      expect(before, hasLength(2));

      final after = MusicService.fetchAlbumList([songs[0]], before);
      expect(after, hasLength(1));
      expect(after.single.songIds, ['1']);
    });

    test('empty song list produces no albums/artists (not the stale list)', () {
      final stale = [
        Album(id: 'x', name: 'Old', songIds: const ['1'], createdAt: DateTime(2020)),
      ];
      expect(MusicService.fetchAlbumList(const [], stale), isEmpty);
      final staleArtists = [
        Artist(id: 'y', name: 'Old', songIds: const ['1'], createdAt: DateTime(2020)),
      ];
      expect(MusicService.fetchArtistList(const [], staleArtists), isEmpty);
    });

    test('preserves cover image and createdAt of existing albums', () {
      final songs = [testSong(id: '1', albums: ['A'], albumArtist: 'X')];
      final first = MusicService.fetchAlbumList(songs).single;
      final customised = first.copyWith(
        coverImage: '/cover.png',
        createdAt: DateTime(2020),
        playCount: 7,
      );
      final rebuilt = MusicService.fetchAlbumList(
        [...songs, testSong(id: '2', albums: ['A'], albumArtist: 'X')],
        [customised],
      ).single;
      expect(rebuilt.coverImage, '/cover.png');
      expect(rebuilt.createdAt, DateTime(2020));
      expect(rebuilt.playCount, 7);
      expect(rebuilt.songIds, ['1', '2']);
    });
  });

  group('MusicService artist grouping', () {
    test('groups artists case-insensitively with stable IDs', () {
      final songs = [
        testSong(id: '1', artists: ['A.R. Rahman']),
        testSong(id: '2', artists: ['a.r. rahman']),
        testSong(id: '3', artists: ['Ilaiyaraaja']),
      ];
      final artists = MusicService.fetchArtistList(songs);
      expect(artists, hasLength(2));
      final rahman = artists.firstWhere((a) => a.songIds.contains('1'));
      expect(rahman.songIds, ['1', '2']);
      expect(rahman.id, MusicService.artistIdForName('A.R. RAHMAN'));
    });

    test('total songs across artists equals library size', () {
      final songs = [
        for (var i = 0; i < 30; i++) testSong(id: '$i', artists: ['Artist ${i % 4}']),
      ];
      final artists = MusicService.fetchArtistList(songs);
      expect(artists, hasLength(4));
      expect(artists.fold<int>(0, (n, a) => n + a.songIds.length), 30);
      final albums = MusicService.fetchAlbumList(songs);
      expect(albums.fold<int>(0, (n, a) => n + a.songIds.length), 30);
    });
  });

  group('AlbumArtCleanup', () {
    test('only deletes cached art not used by remaining songs', () {
      final removed = [
        testSong(id: '1', albumArt: '/docs/album_art/1.jpg'),
        testSong(id: '2', albumArt: '/docs/album_art/shared.jpg'),
        testSong(id: '3', albumArt: '/storage/Music/cover.jpg'), // user file
        testSong(id: '4'),
      ];
      final remaining = [testSong(id: '5', albumArt: '/docs/album_art/shared.jpg')];
      expect(
        AlbumArtCleanup.orphanedArtPaths(
          removedSongs: removed,
          remainingSongs: remaining,
        ),
        ['/docs/album_art/1.jpg'],
      );
    });

    test('deleteOrphanedArt removes the files from disk', () async {
      final dir = await Directory.systemTemp.createTemp('art_');
      addTearDown(() => dir.delete(recursive: true));
      final artDir = Directory('${dir.path}/album_art')..createSync();
      final art = File('${artDir.path}/1.jpg')..writeAsBytesSync([1, 2, 3]);
      final deleted = await AlbumArtCleanup.deleteOrphanedArt(
        removedSongs: [testSong(id: '1', albumArt: art.path)],
        remainingSongs: const [],
      );
      expect(deleted, 1);
      expect(art.existsSync(), isFalse);
    });
  });

  group('LibraryFilterHelper (Albums / Artists tabs)', () {
    final albums = [
      Album(id: '1', name: 'Thriller', songIds: const ['a'], createdAt: DateTime(2020)),
      Album(id: '2', name: 'Bad', songIds: const ['b'], createdAt: DateTime(2020)),
    ];

    test('empty query returns the latest list itself', () {
      expect(identical(LibraryFilterHelper.filterAlbums(albums, ''), albums), isTrue);
      expect(identical(LibraryFilterHelper.filterAlbums(albums, '  '), albums), isTrue);
    });

    test('filters case-insensitively', () {
      expect(
        LibraryFilterHelper.filterAlbums(albums, 'THRI').map((a) => a.id),
        ['1'],
      );
      final artists = [
        Artist(id: '1', name: 'Queen', songIds: const ['a'], createdAt: DateTime(2020)),
      ];
      expect(LibraryFilterHelper.filterArtists(artists, 'que'), hasLength(1));
      expect(LibraryFilterHelper.filterArtists(artists, 'zzz'), isEmpty);
    });
  });
}
