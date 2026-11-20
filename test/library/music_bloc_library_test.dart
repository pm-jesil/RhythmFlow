import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/utils/models/my_player_state_model.dart';
import 'package:rhythmflow/utils/models/my_playlist/my_playlist_model.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/services/fetch_songs.dart';
import 'package:rhythmflow/utils/services/library_storage.dart';
import 'package:rhythmflow/utils/services/remote_control_service.dart';

import 'library_test_utils.dart';

class MockAudioService extends Mock implements AudioService {}

class MockRemoteControlService extends Mock implements RemoteControlService {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

class MockStorage extends Mock implements Storage {}

class FakeAppSettingsEvent extends Fake implements AppSettingsEvent {}

class _SettingsHolder {
  AppSettingsState value;
  _SettingsHolder(this.value);
}

/// Drives a real MusicBloc against a temporary folder tree.
class Harness {
  final FakeMusicDevice device;
  final MusicBloc bloc;
  final MockAudioService audio;
  final MockAppSettingsBloc settings;
  final StreamController<AppSettingsState> settingsStream;
  final _SettingsHolder _settings;
  final InMemoryLibraryStoreBackend storage;

  AppSettingsState get settingsState => _settings.value;
  set settingsState(AppSettingsState value) => _settings.value = value;

  Harness._(
    this.device,
    this.bloc,
    this.audio,
    this.settings,
    this.settingsStream,
    this._settings,
    this.storage,
  );

  static Future<Harness> create({bool withLibraryStorage = true}) async {
    final device = await FakeMusicDevice.create();

    final storage = InMemoryLibraryStoreBackend();
    LibraryStorage.useBackend(withLibraryStorage ? storage : null);
    LibraryStorage.saveDebounce = const Duration(milliseconds: 10);

    final hydrated = MockStorage();
    when(() => hydrated.read(any())).thenReturn(null);
    when(() => hydrated.write(any(), any())).thenAnswer((_) async {});
    when(() => hydrated.delete(any())).thenAnswer((_) async {});
    when(() => hydrated.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = hydrated;

    final audio = MockAudioService();
    when(() => audio.playerStateStream).thenAnswer(
      (_) => const Stream<PlayerState>.empty(),
    );
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.pause()).thenAnswer((_) async {});

    final holder = _SettingsHolder(
      AppSettingsState.initial().copyWith(
        whiteListFolder: {
          'android': const [],
          'ios': const [],
          'test': [device.musicDir, device.downloadDir],
        },
      ),
    );
    final settings = MockAppSettingsBloc();
    final settingsStream = StreamController<AppSettingsState>.broadcast();
    // MusicBloc reads the settings state in its constructor, so stub first.
    when(() => settings.state).thenAnswer((_) => holder.value);
    when(() => settings.stream).thenAnswer((_) => settingsStream.stream);
    when(() => settings.add(any())).thenReturn(null);

    final bloc = MusicBloc(audio, MockRemoteControlService(), settings);
    return Harness._(device, bloc, audio, settings, settingsStream, holder, storage);
  }

  /// Emits new settings like the real AppSettingsBloc would.
  void updateSettings(AppSettingsState next) {
    settingsState = next;
    settingsStream.add(next);
  }

  Future<void> scan({bool force = true}) async {
    bloc.add(MusicEvent.fetchAndUpdateSongs(isForce: force));
    await settle();
  }

  /// Waits until no scan is running and the event queue is drained.
  Future<void> settle({Duration timeout = const Duration(seconds: 10)}) async {
    final deadline = DateTime.now().add(timeout);
    var idleRounds = 0;
    while (idleRounds < 5) {
      if (DateTime.now().isAfter(deadline)) {
        fail('MusicBloc did not settle in time');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final busy = bloc.isScanning || bloc.state.isSongListLoading;
      idleRounds = busy ? 0 : idleRounds + 1;
    }
  }

  List<String> get titles => bloc.state.allSongs.map((s) => s.title).toList()..sort();

  Future<void> dispose() async {
    await bloc.close();
    await settingsStream.close();
    LibraryStorage.useBackend(null);
    LibraryStorage.saveDebounce = const Duration(milliseconds: 1500);
    MusicBloc.autoRefreshMinInterval = const Duration(seconds: 10);
    await device.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeAppSettingsEvent());
  });

  late Harness h;

  setUp(() async {
    h = await Harness.create();
  });

  tearDown(() async {
    await h.dispose();
  });

  /// Every album/artist count must add up to the library size and every
  /// referenced song must exist.
  void expectConsistentCounts(MusicState state) {
    final ids = state.allSongs.map((s) => s.id).toSet();
    final albumTotal = state.albumList.fold<int>(0, (n, a) => n + a.songIds.length);
    final artistTotal = state.artistList.fold<int>(0, (n, a) => n + a.songIds.length);
    expect(albumTotal, state.allSongs.length, reason: 'album counts');
    expect(artistTotal, state.allSongs.length, reason: 'artist counts');
    for (final album in state.albumList) {
      expect(album.songIds, isNotEmpty, reason: 'no empty albums');
      expect(ids.containsAll(album.songIds), isTrue);
    }
    for (final artist in state.artistList) {
      expect(artist.songIds, isNotEmpty, reason: 'no empty artists');
      expect(ids.containsAll(artist.songIds), isTrue);
    }
  }

  group('first scan', () {
    test('fills songs, albums and artists with consistent counts', () async {
      await h.device.addSong(
        'Music/a1.mp3',
        const FakeTags(title: 'A1', artists: ['Adele'], albums: ['25'], albumArtist: 'Adele'),
      );
      await h.device.addSong(
        'Music/a2.mp3',
        const FakeTags(title: 'A2', artists: ['Adele'], albums: ['25'], albumArtist: 'Adele'),
      );
      await h.device.addSong(
        'Download/q.mp3',
        const FakeTags(title: 'Q', artists: ['Queen'], albums: ['Hits'], albumArtist: 'Queen'),
      );

      await h.scan(force: false);

      expect(h.titles, ['A1', 'A2', 'Q']);
      expect(h.bloc.state.albumList.map((a) => a.name).toList()..sort(), ['25', 'Hits']);
      expect(h.bloc.state.artistList.map((a) => a.name).toList()..sort(), ['Adele', 'Queen']);
      expect(h.bloc.state.isSongListLoading, isFalse);
      expect(h.bloc.state.appSettingsFetchSong, isFalse);
      expectConsistentCounts(h.bloc.state);
      verify(() => h.settings.add(any())).called(greaterThanOrEqualTo(1));
    });
  });

  group('auto update', () {
    test('a newly downloaded song appears with its new album', () async {
      MusicBloc.autoRefreshMinInterval = Duration.zero;
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A', albums: ['One']));
      await h.scan();
      expect(h.bloc.state.albumList, hasLength(1));

      await h.device.addSong(
        'Download/new.mp3',
        const FakeTags(title: 'New', albums: ['Two'], albumArtist: 'X'),
      );
      h.bloc.requestAutoRefresh(reason: 'test');
      await h.settle();

      expect(h.titles, ['A', 'New']);
      expect(h.bloc.state.albumList.map((a) => a.name).toList()..sort(), ['One', 'Two']);
      expectConsistentCounts(h.bloc.state);
    });

    test('a deleted song disappears from songs, albums, playlists and queue', () async {
      final a = await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A', albums: ['Solo']));
      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'B', albums: ['Other']));
      await h.scan();
      final songA = h.bloc.state.allSongs.firstWhere((s) => s.title == 'A');
      final songB = h.bloc.state.allSongs.firstWhere((s) => s.title == 'B');

      // Put A in a playlist and in the queue.
      final playlist = MyPlaylist(
        id: 'p1',
        name: 'Mix',
        description: '',
        songIds: [songA.id, songB.id],
        createdAt: DateTime(2024),
      );
      h.bloc.add(
        MusicEvent.updateMusicBlocState(
          newState: h.bloc.state.copyWith(
            myPlaylist: [...h.bloc.state.myPlaylist, playlist],
            myPlayerState: h.bloc.state.myPlayerState.copyWith(
              currentPlayList: [songA.id, songB.id],
            ),
          ),
        ),
      );
      await h.settle();

      await h.device.deleteFile(a);
      await h.scan();

      final state = h.bloc.state;
      expect(h.titles, ['B']);
      expect(state.albumList.map((x) => x.name), ['Other']);
      expect(state.myPlaylist.firstWhere((p) => p.id == 'p1').songIds, [songB.id]);
      expect(state.myPlayerState.currentPlayList, [songB.id]);
      expectConsistentCounts(state);
    });

    test('an edited song keeps its id and play count, album follows the tag', () async {
      final a = await h.device.addSong(
        'Music/a.mp3',
        const FakeTags(title: 'A', albums: ['Old Album']),
      );
      await h.scan();
      final id = h.bloc.state.allSongs.single.id;
      h.bloc.add(
        MusicEvent.updateMusicBlocState(
          newState: h.bloc.state.copyWith(
            allSongs: [h.bloc.state.allSongs.single.copyWith(playCount: 5)],
          ),
        ),
      );
      await h.settle();

      await h.device.editSong(a, const FakeTags(title: 'A', albums: ['New Album']));
      await h.scan();

      final song = h.bloc.state.allSongs.single;
      expect(song.id, id);
      expect(song.playCount, 5);
      expect(h.bloc.state.albumList.single.name, 'New Album');
      expectConsistentCounts(h.bloc.state);
    });

    test('non-forced fetch respects the refresh time gap, forced does not', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.scan();
      h.settingsState = h.settingsState.copyWith(
        lastUpdateMusicLibrary: DateTime.now(),
      );
      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'B'));

      final checksBefore = h.device.permissionChecks;
      await h.scan(force: false);
      expect(h.device.permissionChecks, checksBefore, reason: 'skipped');
      expect(h.titles, ['A']);

      await h.scan(force: true);
      expect(h.titles, ['A', 'B']);
    });

    test('permission revoked: library is kept and last-update not touched', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.scan();
      clearInteractions(h.settings);

      h.device.permissionGranted = false;
      await h.scan();
      expect(h.titles, ['A']);
      verifyNever(() => h.settings.add(any()));
    });
  });

  group('settings changes', () {
    test('removing a folder in settings rescans and removes its songs', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.device.addSong('Download/b.mp3', const FakeTags(title: 'B'));
      await h.scan();
      expect(h.titles, ['A', 'B']);

      h.updateSettings(
        h.settingsState.copyWith(
          whiteListFolder: {
            ...h.settingsState.whiteListFolder,
            'test': [h.device.musicDir],
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await h.settle();

      expect(h.titles, ['A']);
      expectConsistentCounts(h.bloc.state);
    });

    test('adding a folder in settings rescans and adds its songs', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.device.addSong('Other/c.mp3', const FakeTags(title: 'C'));
      await h.scan();
      expect(h.titles, ['A']);

      h.updateSettings(
        h.settingsState.copyWith(
          whiteListFolder: {
            ...h.settingsState.whiteListFolder,
            'test': [h.device.musicDir, h.device.downloadDir, h.device.otherDir],
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await h.settle();
      expect(h.titles, ['A', 'C']);
    });

    test('unrelated settings changes do not trigger a scan', () async {
      await h.scan();
      final checks = h.device.permissionChecks;
      h.updateSettings(h.settingsState.copyWith(playbackSpeed: 1.5));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await h.settle();
      expect(h.device.permissionChecks, checks);
    });

    test('librarySettingsSignature ignores folder/format order', () {
      final base = AppSettingsState.initial();
      final reordered = base.copyWith(
        whiteListFolder: {
          'ios': base.whiteListFolder['ios']!.reversed.toList(),
          'android': base.whiteListFolder['android']!.reversed.toList(),
        },
        supportedAudioFormats: base.supportedAudioFormats.reversed.toList(),
      );
      expect(
        MusicBloc.librarySettingsSignature(reordered),
        MusicBloc.librarySettingsSignature(base),
      );
      expect(
        MusicBloc.librarySettingsSignature(
          base.copyWith(supportedAudioFormats: const ['.mp3']),
        ),
        isNot(MusicBloc.librarySettingsSignature(base)),
      );
    });
  });

  group('concurrency', () {
    test('many simultaneous scan requests run at most one follow-up scan', () async {
      for (var i = 0; i < 30; i++) {
        await h.device.addSong('Music/s$i.mp3', FakeTags(title: 'S$i'));
      }
      final before = h.device.permissionChecks;
      for (var i = 0; i < 6; i++) {
        h.bloc.add(const MusicEvent.fetchAndUpdateSongs(isForce: true));
      }
      await h.settle();
      final scans = h.device.permissionChecks - before;
      expect(scans, inInclusiveRange(1, 2));
      expect(h.bloc.state.allSongs, hasLength(30));
      expect(h.bloc.state.allSongs.map((s) => s.id).toSet(), hasLength(30));
      expectConsistentCounts(h.bloc.state);
    });

    test('requestAutoRefresh merges bursts into a trailing refresh', () async {
      MusicBloc.autoRefreshMinInterval = const Duration(milliseconds: 300);
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      final before = h.device.permissionChecks;

      h.bloc.requestAutoRefresh();
      await h.settle();
      for (var i = 0; i < 5; i++) {
        h.bloc.requestAutoRefresh();
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await h.settle();

      expect(h.device.permissionChecks - before, 2);
    });

    test('trailing refresh picks up a file added during the quiet period', () async {
      MusicBloc.autoRefreshMinInterval = const Duration(milliseconds: 300);
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      h.bloc.requestAutoRefresh();
      await h.settle();

      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'B'));
      h.bloc.requestAutoRefresh(); // inside the interval -> deferred
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await h.settle();
      expect(h.titles, ['A', 'B']);
    });
  });

  group('removeSongs / updateSongDuration events', () {
    test('removeSongs cleans every reference and rebuilds albums', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A', albums: ['X']));
      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'B', albums: ['Y']));
      await h.scan();
      final a = h.bloc.state.allSongs.firstWhere((s) => s.title == 'A');

      h.bloc.add(MusicEvent.removeSongs(songIds: [a.id]));
      await h.settle();

      expect(h.titles, ['B']);
      expect(h.bloc.state.albumList.map((x) => x.name), ['Y']);
      expectConsistentCounts(h.bloc.state);
      verifyNever(() => h.audio.stop());
    });

    test('removing the current song stops playback', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.scan();
      final a = h.bloc.state.allSongs.single;
      h.bloc.add(
        MusicEvent.updateMusicBlocState(
          newState: h.bloc.state.copyWith(
            myPlayerState: h.bloc.state.myPlayerState.copyWith(
              currentSongId: a.id,
              currentPlayList: [a.id],
              isPlaying: true,
            ),
          ),
        ),
      );
      await h.settle();

      h.bloc.add(MusicEvent.removeSongs(songIds: [a.id]));
      await h.settle();
      verify(() => h.audio.stop()).called(1);
      expect(h.bloc.state.myPlayerState.currentSongId, isNull);
      expect(h.bloc.state.myPlayerState.isPlaying, isFalse);
    });

    test('updateSongDuration only fills unknown durations', () async {
      await h.device.addSong(
        'Music/a.mp3',
        const FakeTags(title: 'Unknown', duration: Duration.zero),
      );
      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'Known'));
      await h.scan();
      final unknown = h.bloc.state.allSongs.firstWhere((s) => s.title == 'Unknown');
      final known = h.bloc.state.allSongs.firstWhere((s) => s.title == 'Known');

      h.bloc.add(MusicEvent.updateSongDuration(
        songId: unknown.id,
        duration: const Duration(seconds: 245),
      ));
      h.bloc.add(MusicEvent.updateSongDuration(
        songId: known.id,
        duration: const Duration(seconds: 1),
      ));
      await h.settle();

      Song byId(String id) => h.bloc.state.allSongs.firstWhere((s) => s.id == id);
      expect(byId(unknown.id).duration, const Duration(seconds: 245));
      expect(byId(known.id).duration, const Duration(minutes: 3));
    });
  });

  group('applyScanResult', () {
    test('keeps play counts that changed while the scan was running', () {
      final song = testSong(id: '1', title: 'Old', playCount: 10);
      final state = MusicState.initial().copyWith(allSongs: [song]);
      final scanned = song.copyWith(title: 'New', playCount: 3);
      final next = MusicBloc.applyScanResult(
        state,
        LibraryScanResult(updatedSongs: [scanned]),
      );
      expect(next.allSongs.single.title, 'New');
      expect(next.allSongs.single.playCount, 10);
    });

    test('adds new songs without duplicating ids', () {
      final a = testSong(id: 'a');
      final state = MusicState.initial().copyWith(allSongs: [a]);
      final next = MusicBloc.applyScanResult(
        state,
        LibraryScanResult(newSongs: [a, testSong(id: 'b')]),
      );
      expect(next.allSongs.map((s) => s.id), ['a', 'b']);
    });
  });

  group('persistence', () {
    test('library is written to LibraryStorage, not into hydrated JSON', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.scan();
      await LibraryStorage.flush();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(LibraryStorage.load()!.songs.map((s) => s.title), ['A']);
      expect(LibraryStorage.load()!.albums, hasLength(1));

      final json = h.bloc.toJson(h.bloc.state)!;
      expect(json.containsKey('allSongs'), isFalse);
      expect(json['libraryInStorage'], isTrue);
    });

    test('position updates do not rewrite the library', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.scan();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final writes = h.storage.writeCount;

      for (var i = 0; i < 10; i++) {
        h.bloc.add(MusicEvent.updateLastPosition(position: Duration(seconds: i)));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(h.storage.writeCount, writes);
    });

    test('fromJson restores the library from LibraryStorage', () async {
      await LibraryStorage.saveNow(
        LibrarySnapshot(
          songs: [testSong(id: 'x', title: 'Stored')],
          albums: const [],
          artists: const [],
          skippedFiles: const {'/m/z.mp3': '1:2|filtered'},
        ),
      );
      final restored = h.bloc.fromJson({
        'sortingIndex': 2,
        'myPlaylist': const [],
        'myPlayerState': const {'currentSongId': 'x'},
        'libraryInStorage': true,
      })!;
      expect(restored.allSongs.single.title, 'Stored');
      expect(restored.sortingIndex, 2);
      expect(FetchSongsService.skippedFiles, {'/m/z.mp3': '1:2|filtered'});
    });

    test('legacy hydrated library is migrated into LibraryStorage', () async {
      expect(LibraryStorage.hasData, isFalse);
      final restored = h.bloc.fromJson({
        'allSongs': [testSong(id: 'legacy', title: 'Legacy').toJson()],
        'albumList': const [],
        'artistList': const [],
        'myPlaylist': const [],
        'myPlayerState': const {},
      })!;
      expect(restored.allSongs.single.id, 'legacy');
      await LibraryStorage.flush();
      expect(LibraryStorage.load()!.songs.single.id, 'legacy');
    });

    test('without LibraryStorage the library stays in hydrated JSON', () async {
      LibraryStorage.useBackend(null);
      final state = MusicState.initial().copyWith(allSongs: [testSong(id: 'a')]);
      final json = h.bloc.toJson(state)!;
      expect(json['allSongs'], hasLength(1));
      final restored = h.bloc.fromJson(json)!;
      expect(restored.allSongs.single.id, 'a');
    });

    test('old hashCode-based album/artist queue ids are migrated', () {
      expect(MusicBloc.migrateLegacyPlaylistId('album_album_123456'), 'all_songs');
      expect(MusicBloc.migrateLegacyPlaylistId('artist_artist_-98765'), 'all_songs');
      expect(
        MusicBloc.migrateLegacyPlaylistId('album_album_0123456789abcdef'),
        'album_album_0123456789abcdef',
      );
      expect(MusicBloc.migrateLegacyPlaylistId('my_playlist_p1'), 'my_playlist_p1');
      expect(MusicBloc.migrateLegacyPlaylistId('all_songs'), 'all_songs');
      expect(MusicBloc.migrateLegacyPlaylistId(null), isNull);
    });
  });

  group('shuffle revert', () {
    test('falls back to all songs when the source album no longer exists', () async {
      await h.device.addSong('Music/a.mp3', const FakeTags(title: 'A'));
      await h.device.addSong('Music/b.mp3', const FakeTags(title: 'B'));
      await h.scan();
      final ids = h.bloc.state.allSongs.map((s) => s.id).toList();
      h.bloc.add(
        MusicEvent.updateMusicBlocState(
          newState: h.bloc.state.copyWith(
            myPlayerState: MyPlayerStateModel(
              playlistId: 'album_album_doesnotexist00',
              currentPlayList: ids.reversed.toList(),
              currentSongId: ids.last,
              isShuffle: true,
            ),
          ),
        ),
      );
      await h.settle();

      h.bloc.add(MusicEvent.toggleShuffle(isShuffle: false, currentPlayList: ids));
      await h.settle();
      expect(h.bloc.state.myPlayerState.isShuffle, isFalse);
    });
  });
}
