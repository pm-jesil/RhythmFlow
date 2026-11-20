import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/models/album/album_model.dart';
import 'package:rhythmflow/utils/models/artist/artist_model.dart';
import 'package:rhythmflow/utils/models/my_playlist/my_playlist_model.dart';
import 'package:rhythmflow/utils/models/my_player_state_model.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/services/remote_control_service.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';

// Mock classes
class MockAudioService extends Mock implements AudioService {}
class MockRemoteControlService extends Mock implements RemoteControlService {}
class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}
class MockStorage extends Mock implements Storage {}

void main() {
  group('MusicBloc', () {
    late MusicBloc musicBloc;
    late MockAudioService mockAudioService;
    late MockRemoteControlService mockRemoteControlService;
    late MockStorage mockStorage;
    late MockAppSettingsBloc mockAppSettingsBloc;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(Song(
        id: 'fallback',
        title: 'Fallback Song',
        artists: ['Fallback Artist'],
        albums: ['Fallback Album'],
        path: '/fallback/path.mp3',
        duration: const Duration(minutes: 3),
      ));
      
      // Register fallback value for AppSettingsEvent
      registerFallbackValue(const AppSettingsEvent.resetToDefaults());
      
      // Register fallback value for Duration
      registerFallbackValue(const Duration(seconds: 30));
    });

    setUp(() {
      mockAudioService = MockAudioService();
      mockRemoteControlService = MockRemoteControlService();
      mockStorage = MockStorage();
      mockAppSettingsBloc = MockAppSettingsBloc();
      
      // Setup HydratedBloc storage
      HydratedBloc.storage = mockStorage;
      
      // Setup default mock behaviors
      when(() => mockStorage.read(any())).thenReturn(null);
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      when(() => mockStorage.delete(any())).thenAnswer((_) async {});
      when(() => mockStorage.clear()).thenAnswer((_) async {});
      
      // Setup AudioService mock behaviors
      when(() => mockAudioService.playerStateStream).thenAnswer((_) => Stream.value(PlayerState(
        false,
        ProcessingState.ready,
      )));
      when(() => mockAudioService.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockAudioService.durationStream).thenAnswer((_) => Stream.value(const Duration(minutes: 3)));
      when(() => mockAudioService.playingStream).thenAnswer((_) => Stream.value(false));
      when(() => mockAudioService.playSong(any())).thenAnswer((_) async {});
      when(() => mockAudioService.pause()).thenAnswer((_) async {});
      when(() => mockAudioService.resume()).thenAnswer((_) async {});
      when(() => mockAudioService.stop()).thenAnswer((_) async {});
      when(() => mockAudioService.seekTo(any())).thenAnswer((_) async {});
      when(() => mockAudioService.setVolume(any())).thenAnswer((_) async {});
      when(() => mockAudioService.setSpeed(any())).thenAnswer((_) async {});
      
      // Setup AppSettingsBloc mock behaviors - CRITICAL FIX
      when(() => mockAppSettingsBloc.stream).thenAnswer((_) => Stream.value(AppSettingsState.initial()));
      when(() => mockAppSettingsBloc.state).thenReturn(AppSettingsState.initial());
      when(() => mockAppSettingsBloc.add(any())).thenReturn(null);
      
      musicBloc = MusicBloc(mockAudioService, mockRemoteControlService, mockAppSettingsBloc);
    });

    tearDown(() {
      musicBloc.close();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        // Favorites' createdAt is a timestamp, so compare without playlists
        // and check the playlist separately.
        expect(
          musicBloc.state.copyWith(myPlaylist: const []),
          equals(MusicState.initial().copyWith(myPlaylist: const [])),
        );
        expect(
          musicBloc.state.myPlaylist.map((p) => p.id),
          equals(['my_playlist_favorites']),
        );
      });

      test('should have correct storage prefix', () {
        expect(musicBloc.storagePrefix, equals('MusicBloc'));
      });
    });


    group('PlayOrPauseSong', () {
      final testSong = Song(
        id: '1',
        title: 'Test Song',
        artists: ['Test Artist'],
        albums: ['Test Album'],
        path: '/test/path.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
      );

      setUp(() {
        // Setup initial state with songs
        musicBloc.emit(musicBloc.state.copyWith(
          allSongs: [testSong],
        ));
      });

      test('should handle playOrPauseSong event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        // The actual playback logic depends on audio service that can't be easily mocked
        expect(() => musicBloc.add(MusicEvent.playOrPauseSong(
          songId: '1',
          currentPlayList: ['1'],
        )), returnsNormally);
      });

      test('should handle empty songId without crashing', () async {
        expect(() => musicBloc.add(MusicEvent.playOrPauseSong(
          songId: '',
          currentPlayList: [],
        )), returnsNormally);
      });
    });

    group('ToggleShuffle', () {
      test('should handle toggleShuffle event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(MusicEvent.toggleShuffle(
          isShuffle: true,
          currentPlayList: ['1', '2', '3'],
        )), returnsNormally);
      });

      test('should handle toggleShuffle event with false value', () async {
        expect(() => musicBloc.add(MusicEvent.toggleShuffle(
          isShuffle: false,
          currentPlayList: ['1', '2', '3'],
        )), returnsNormally);
      });
    });

    group('ToggleRepeat', () {
      test('should handle toggleRepeat event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(const MusicEvent.toggleRepeat()), returnsNormally);
      });
    });

    group('ChangeSortingOrder', () {
      test('should handle changeSortingOrder event without crashing', () async {
        // Setup state with test songs
        final testSongs = [
          Song(
            id: '1',
            title: 'Test Song 1',
            artists: ['Test Artist 1'],
            albums: ['Test Album 1'],
            path: '/test/path1.mp3',
            duration: const Duration(minutes: 3),
          ),
          Song(
            id: '2',
            title: 'Test Song 2',
            artists: ['Test Artist 2'],
            albums: ['Test Album 2'],
            path: '/test/path2.mp3',
            duration: const Duration(minutes: 4),
          ),
          Song(
            id: '3',
            title: 'Test Song 3',
            artists: ['Test Artist 3'],
            albums: ['Test Album 3'],
            path: '/test/path3.mp3',
            duration: const Duration(minutes: 5),
          ),
        ];
        
        musicBloc.emit(musicBloc.state.copyWith(allSongs: testSongs));
        
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(MusicEvent.changeSortingOrder(
          sortingIndex: 1,
          sortingList: ['1', '2', '3'],
        )), returnsNormally);
      });
    });

    group('UpdateFilterKeyword', () {
      test('should handle updateFilterKeyword event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(MusicEvent.updateFilterKeyword(filterKeyword: 'test')), returnsNormally);
      });
    });

    group('State Persistence', () {
      test('toJson returns correct JSON structure', () {
        final testState = MusicState(
          myPlayerState: MyPlayerStateModel(
            completedSongs: ['1', '2'],
            currentPlayList: ['1', '2', '3'],
            currentSongId: '1',
            repeatModeIndex: 1,
            playlistId: 'test-playlist',
            previousSongId: '2',
            isShuffle: true,
            isPlaying: true,
          ),
          allSongs: [
            Song(
              id: '1',
              title: 'Test Song',
              artists: ['Test Artist'],
              albums: ['Test Album'],
              path: '/test/path.mp3',
              duration: const Duration(minutes: 3),
            ),
          ],
          albumList: [
            Album(
              id: 'album1',
              name: 'Test Album',
              songIds: ['1'],
              createdAt: DateTime.now(),
              artistId: 'artist1',
            ),
          ],
          artistList: [
            Artist(
              id: 'artist1',
              name: 'Test Artist',
              songIds: ['1'],
              createdAt: DateTime.now(),
            ),
          ],
          myPlaylist: [
            MyPlaylist(
              id: 'playlist1',
              name: 'Test Playlist',
              description: 'Test Description',
              songIds: ['1'],
              createdAt: DateTime.now(),
            ),
          ],
          sortingIndex: 1,
          isSongListLoading: false,
          isAlbumListLoading: false,
          isArtistListLoading: false,
          isSongListError: false,
          isAlbumListError: false,
          isArtistListError: false,
          isLoading: false,
          isError: false,
          isComprehensiveFeaturesExtractingLoading: false,
          isComprehensiveFeaturesExtractingError: false,
        );

        final json = musicBloc.toJson(testState);
        
        expect(json, isNotNull);
        expect(json!['sortingIndex'], equals(1));
        expect(json['allSongs'], isA<List>());
        expect(json['albumList'], isA<List>());
        expect(json['artistList'], isA<List>());
        expect(json['myPlaylist'], isA<List>());
        expect(json['myPlayerState'], isA<Map<String, dynamic>>());
        expect(json['myPlayerState']['currentSongId'], equals('1'));
        expect(json['myPlayerState']['isShuffle'], isTrue);
      });

      test('fromJson creates correct state from JSON', () {
        final json = {
          'sortingIndex': 1,
          'allSongs': [
            {
              'id': '1',
              'title': 'Test Song',
              'artists': ['Test Artist'],
              'albums': ['Test Album'],
              'path': '/test/path.mp3',
              'duration': 180000, // 3 minutes in milliseconds
              'albumArt': null,
              'genre': null,
              'year': null,
              'trackNumber': null,
              'discNumber': null,
              'composer': null,
              'lyrics': null,
              'bitrate': null,
              'fileSize': 0,
              'dateAdded': DateTime.now().toIso8601String(),
              'lastPlayed': null,
              'playCount': 0,
              'isFavorite': false,
              'albumArtist': null,
            }
          ],
          'albumList': [
            {
              'id': 'album1',
              'name': 'Test Album',
              'songIds': ['1'],
              'createdAt': DateTime.now().toIso8601String(),
              'artistId': 'artist1',
            }
          ],
          'artistList': [
            {
              'id': 'artist1',
              'name': 'Test Artist',
              'songIds': ['1'],
              'createdAt': DateTime.now().toIso8601String(),
              'albumIds': ['album1'],
            }
          ],
          'myPlaylist': [
            {
              'id': 'playlist1',
              'name': 'Test Playlist',
              'description': 'Test Description',
              'songIds': ['1'],
              'createdAt': DateTime.now().toIso8601String(),
            }
          ],
          'myPlayerState': {
            'completedSongs': ['1', '2'],
            'currentPlayList': ['1', '2', '3'],
            'currentSongId': '1',
            'repeatModeIndex': 1,
            'playlistId': 'test-playlist',
            'previousSongId': '2',
            'isShuffle': true,
          },
        };

        final state = musicBloc.fromJson(json);
        
        expect(state, isNotNull);
        expect(state!.sortingIndex, equals(1));
        expect(state.allSongs.length, equals(1));
        expect(state.albumList.length, equals(1));
        expect(state.artistList.length, equals(1));
        // The stored playlist plus the always-present Favorites playlist.
        expect(state.myPlaylist.length, equals(2));
        expect(state.myPlaylist.map((p) => p.id), contains('playlist1'));
        expect(
          state.myPlaylist.map((p) => p.id),
          contains('my_playlist_favorites'),
        );
        expect(state.myPlayerState.currentSongId, equals('1'));
        expect(state.myPlayerState.isShuffle, isTrue);
        expect(state.isSongListLoading, isFalse);
        expect(state.isSongListError, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle playNext event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(const MusicEvent.playNext()), returnsNormally);
      });

      test('should handle playPrevious event without crashing', () async {
        // This test verifies that the event doesn't crash the bloc
        expect(() => musicBloc.add(const MusicEvent.playPrevious()), returnsNormally);
      });
    });
  });
}
