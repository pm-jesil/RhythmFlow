import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/discover_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/online_library_bloc.dart';
import 'package:rhythmflow/screens/widgets/playlist_source_helper.dart';
import 'package:rhythmflow/utils/models/playlist_source/playlist_source_model.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/jamendo/online_dependencies.dart';
import 'package:rhythmflow/utils/services/jamendo/online_song_registry.dart';
import 'package:rhythmflow/utils/services/library_storage.dart';
import 'package:rhythmflow/utils/services/remote_control_service.dart';

import 'online_blocs_test.dart' show fakeJamendo, repoFor, settle;

class MockAudioService extends Mock implements AudioService {}

class MockRemote extends Mock implements RemoteControlService {}

class MockSettings extends Mock implements AppSettingsBloc {}

class MockStorage extends Mock implements Storage {}

class FakeSettingsEvent extends Fake implements AppSettingsEvent {}

Song onlineSong(int i) => JamendoMapper.track({
  'id': '$i',
  'name': 'Online $i',
  'artist_name': 'Artist $i',
  'duration': 180,
  'audio': 'https://stream/$i',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService audio;
  late MockSettings settings;
  late StreamController<AppSettingsState> settingsStream;
  late AppSettingsState settingsState;
  late MusicBloc bloc;
  final played = <Song>[];

  setUpAll(() {
    registerFallbackValue(FakeSettingsEvent());
    registerFallbackValue(onlineSong(0));
  });

  setUp(() {
    OnlineSongRegistry.clear();
    OnlineQueues.clear();
    LibraryStorage.useBackend(null);
    played.clear();

    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    audio = MockAudioService();
    when(() => audio.playerStateStream).thenAnswer((_) => const Stream<PlayerState>.empty());
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.pause()).thenAnswer((_) async {});
    when(() => audio.resume()).thenAnswer((_) async {});
    when(
      () => audio.playSong(
        any(),
        playlistId: any(named: 'playlistId'),
        playlistSource: any(named: 'playlistSource'),
      ),
    ).thenAnswer((i) async => played.add(i.positionalArguments.first as Song));

    settingsState = AppSettingsState.initial().copyWith(isAiShuffleEnabled: false);
    settings = MockSettings();
    settingsStream = StreamController<AppSettingsState>.broadcast();
    when(() => settings.state).thenAnswer((_) => settingsState);
    when(() => settings.stream).thenAnswer((_) => settingsStream.stream);
    when(() => settings.add(any())).thenReturn(null);

    bloc = MusicBloc(audio, MockRemote(), settings);
  });

  tearDown(() async {
    await OnlineDependencies.disconnect();
    await bloc.close();
    await settingsStream.close();
  });

  List<Song> registerQueue(String key, int count) {
    final songs = [for (var i = 1; i <= count; i++) onlineSong(i)];
    OnlineQueues.register(key, 'Trending this week', songs);
    return songs;
  }

  test('a Discover list plays and queues exactly that list', () async {
    final songs = registerQueue('trending', 3);
    bloc.add(MusicEvent.playOrPauseSong(
      songId: songs[1].id,
      currentPlayList: songs.map((s) => s.id).toList(),
      playlistSource: PlaylistSource.online('trending'),
    ));
    await settle(80);

    expect(played.single.id, songs[1].id);
    expect(played.single.isOnline, isTrue);
    expect(bloc.state.myPlayerState.currentSongId, songs[1].id);
    expect(bloc.state.myPlayerState.playlistId, 'online_trending');
    expect(bloc.state.myPlayerState.currentPlayList, containsAll(songs.map((s) => s.id)));
    expect(bloc.state.allSongs, isEmpty, reason: 'online songs never enter the device library');
    expect(bloc.findSong(songs[0].id)?.title, 'Online 1');
  });

  test('next / previous move through online songs', () async {
    final songs = registerQueue('trending', 3);
    bloc.add(MusicEvent.playOrPauseSong(
      songId: songs[0].id,
      currentPlayList: songs.map((s) => s.id).toList(),
      playlistSource: PlaylistSource.online('trending'),
    ));
    await settle(80);
    bloc.add(const MusicEvent.playNext());
    await settle(80);
    expect(bloc.state.myPlayerState.currentSongId, songs[1].id);
    bloc.add(const MusicEvent.playPrevious());
    await settle(80);
    expect(bloc.state.myPlayerState.currentSongId, songs[0].id);
    expect(played.map((s) => s.id), [songs[0].id, songs[1].id, songs[0].id]);
  });

  test('shuffle off restores the Discover list order', () async {
    final songs = registerQueue('mix_pop', 6);
    final ids = songs.map((s) => s.id).toList();
    bloc.add(MusicEvent.playOrPauseSong(
      songId: ids.first,
      currentPlayList: ids,
      playlistSource: PlaylistSource.online('mix_pop'),
    ));
    await settle(80);
    bloc.add(MusicEvent.toggleShuffle(isShuffle: true, currentPlayList: ids));
    await settle(80);
    expect(bloc.state.myPlayerState.isShuffle, isTrue);
    bloc.add(MusicEvent.toggleShuffle(isShuffle: false, currentPlayList: ids));
    await settle(80);
    expect(bloc.state.myPlayerState.isShuffle, isFalse);
    expect(bloc.state.myPlayerState.currentPlayList, ids);
  });

  test('AI shuffle on an online queue falls back to a random order', () async {
    final songs = registerQueue('trending', 8);
    final ids = songs.map((s) => s.id).toList();
    bloc.add(MusicEvent.playOrPauseSong(
      songId: ids[2],
      currentPlayList: ids,
      playlistSource: PlaylistSource.online('trending'),
    ));
    await settle(80);
    bloc.add(MusicEvent.aiShuffle(currentSongId: ids[2], currentPlayList: ids));
    await settle(80);
    final queue = bloc.state.myPlayerState.currentPlayList;
    expect(queue.toSet(), ids.toSet());
    expect(queue.first, ids[2]);
  });

  test('randomOrderKeepingCurrent', () {
    final order = MusicBloc.randomOrderKeepingCurrent('b', ['a', 'b', 'c', 'd'], Random(1));
    expect(order.first, 'b');
    expect(order.toSet(), {'a', 'b', 'c', 'd'});
    expect(MusicBloc.randomOrderKeepingCurrent('x', ['a']), ['a']);
  });

  test('online queue survives a restart (songs + list order persisted)', () async {
    final songs = registerQueue('trending', 3);
    bloc.add(MusicEvent.playOrPauseSong(
      songId: songs[0].id,
      currentPlayList: songs.map((s) => s.id).toList(),
      playlistSource: PlaylistSource.online('trending'),
    ));
    await settle(80);
    final json = jsonDecode(jsonEncode(bloc.toJson(bloc.state)!)) as Map<String, dynamic>;
    expect(json['onlineQueueSongs'], hasLength(3));
    expect(json['onlineQueue']['key'], 'trending');

    OnlineSongRegistry.clear();
    OnlineQueues.clear();
    final restored = bloc.fromJson(json)!;
    expect(restored.myPlayerState.currentSongId, songs[0].id);
    expect(OnlineSongRegistry.get(songs[2].id)?.title, 'Online 3');
    expect(OnlineQueues.ids('trending'), songs.map((s) => s.id).toList());
  });

  test('local-only queues persist no online data', () {
    expect(MusicBloc.onlineQueueJson(bloc.state.myPlayerState), isEmpty);
  });

  test('history records online songs; region changes reach Discover', () async {
    final library = OnlineLibraryBloc();
    final discover = DiscoverBloc(repository: repoFor(fakeJamendo()));
    OnlineDependencies.connect(
      settings: settings,
      musicBloc: bloc,
      discover: discover,
      library: library,
    );
    final songs = registerQueue('trending', 2);
    bloc.add(MusicEvent.playOrPauseSong(
      songId: songs[0].id,
      currentPlayList: songs.map((s) => s.id).toList(),
      playlistSource: PlaylistSource.online('trending'),
    ));
    await settle(80);
    expect(library.state.recentlyPlayed.single.id, songs[0].id);

    settingsState = settingsState.copyWith(musicCountry: 'IN', musicLanguages: ['ml']);
    settingsStream.add(settingsState);
    await settle(150);
    expect(discover.state.country, 'IN');
    expect(discover.state.sections.keys, contains(DiscoverSectionIds.country));
    await library.close();
    await discover.close();
  });

  group('PlaylistSourceHelper with online sources', () {
    test('ids, songs, names and counts', () {
      final songs = registerQueue('k', 2);
      final source = PlaylistSource.online('k');
      expect(PlaylistSourceHelper.getPlaylistId(source), 'online_k');
      expect(PlaylistSourceHelper.getPlaylistSourceFromId('online_k'), source);
      expect(PlaylistSourceHelper.getPlaylistSongs(source, bloc.state).map((s) => s.id),
          songs.map((s) => s.id));
      expect(PlaylistSourceHelper.validatePlaylistSource(source, bloc.state), isTrue);
      expect(PlaylistSourceHelper.validatePlaylistSource(PlaylistSource.online('nope'), bloc.state), isFalse);
      expect(PlaylistSourceHelper.getPlaylistSourceTypeName(source), 'Discover');
      expect(PlaylistSourceHelper.getPlaylistSourceDisplayName(source, bloc.state), 'Trending this week');
      expect(PlaylistSourceHelper.getSongCount(source, bloc.state), 2);
      expect(source.source, Sources.online);
    });

    test('getSongsFromIds resolves online ids too, unknown ids still throw', () {
      final songs = registerQueue('k', 1);
      expect(PlaylistSourceHelper.getSongsFromIds([songs[0].id], const []).single.id, songs[0].id);
      expect(() => PlaylistSourceHelper.getSongsFromIds(['missing'], const []), throwsException);
    });
  });

  group('AudioService online playback', () {
    test('uses the resolver and reports songs without a URL as invalid', () async {
      final service = AudioService();
      final resolved = <String>[];
      AudioService.remoteUrlResolver = (song) async {
        resolved.add(song.id);
        return null;
      };
      Song? invalid;
      service.setInvalidSongCallback((song, _, _) => invalid = song);
      final song = onlineSong(5);
      await service.playSong(song);
      expect(resolved, [song.id]);
      expect(invalid?.id, song.id);
      AudioService.remoteUrlResolver = null;
      await service.dispose();
    });
  });
}
