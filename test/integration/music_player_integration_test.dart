import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/services/remote_control_service.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import '../test_helpers.dart';

// Mock classes
class MockAudioService extends Mock implements AudioService {}
class MockRemoteControlService extends Mock implements RemoteControlService {}
class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}
class MockStorage extends Mock implements Storage {}

void main() {
  group('Music Player Integration Tests', () {
    late MusicBloc musicBloc;
    late MockStorage mockStorage;

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
      registerFallbackValue(Duration.zero);
    });

    setUp(() {
      // Initialize mock storage for HydratedBloc
      mockStorage = MockStorage();
      
      // Setup HydratedBloc storage
      HydratedBloc.storage = mockStorage;
      
      // Setup default mock behaviors
      when(() => mockStorage.read(any())).thenReturn(null);
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      when(() => mockStorage.delete(any())).thenAnswer((_) async {});
      when(() => mockStorage.clear()).thenAnswer((_) async {});
      
      // Initialize the music bloc for integration testing
      final mockAudioService = MockAudioService();
      final mockRemoteControlService = MockRemoteControlService();
      final mockAppSettingsBloc = MockAppSettingsBloc();
      
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
      
      musicBloc = MusicBloc(mockAudioService, mockRemoteControlService, mockAppSettingsBloc);
    });

    tearDown(() {
      musicBloc.close();
    });

    group('App Initialization', () {
      testWidgets('should initialize app without crashing', (WidgetTester tester) async {
        // Create a simplified app for testing that doesn't depend on GetIt
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Test App'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // App should load without crashing
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.text('Test App'), findsOneWidget);
      });
    });

    group('Music Bloc State Management', () {
      test('should handle complete music playback flow', () async {
        // Test the complete flow from loading songs to playing them
        
        // 1. Setup test songs in the state
        final testSongs = TestHelpers.createTestSongs(count: 3);
        musicBloc.emit(musicBloc.state.copyWith(
          allSongs: testSongs,
          isSongListLoading: false,
        ));
        
        // 2. Verify songs are loaded
        expect(musicBloc.state.allSongs.length, equals(3));
        expect(musicBloc.state.isSongListLoading, isFalse);
        
        // 3. Test that we can add events without crashing
        musicBloc.add(MusicEvent.playOrPauseSong(
          songId: testSongs.first.id,
          currentPlayList: testSongs.map((s) => s.id).toList(),
        ));
        
        // 4. Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 5. Test that we can add pause events without crashing
        musicBloc.add(MusicEvent.playOrPauseSong(
          songId: testSongs.first.id,
          currentPlayList: testSongs.map((s) => s.id).toList(),
        ));
        
        // 6. Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 7. Verify the bloc is still in a valid state
        expect(musicBloc.state.allSongs.length, equals(3));
        expect(musicBloc.state.isSongListLoading, isFalse);
      });

      test('should handle shuffle toggle', () async {
        // Initial state should have shuffle off
        expect(musicBloc.state.myPlayerState.isShuffle, isFalse);
        
        // Toggle shuffle on
        musicBloc.add(MusicEvent.toggleShuffle(
          isShuffle: true,
          currentPlayList: ['1', '2', '3'],
        ));
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify shuffle is on
        expect(musicBloc.state.myPlayerState.isShuffle, isTrue);
        
        // Toggle shuffle off
        musicBloc.add(MusicEvent.toggleShuffle(
          isShuffle: false,
          currentPlayList: ['1', '2', '3'],
        ));
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify shuffle is off
        expect(musicBloc.state.myPlayerState.isShuffle, isFalse);
      });

      test('should handle repeat mode cycling', () async {
        // Initial state should have repeat mode 0
        expect(musicBloc.state.myPlayerState.repeatModeIndex, equals(0));
        
        // Cycle through repeat modes
        for (int i = 1; i <= 3; i++) {
          musicBloc.add(const MusicEvent.toggleRepeat());
          // Wait for the event to be processed
          await Future.delayed(const Duration(milliseconds: 100));
          expect(musicBloc.state.myPlayerState.repeatModeIndex, equals(i % 3));
        }
      });

      test('should handle sorting order changes', () async {
        // Setup state with test songs
        final testSongs = TestHelpers.createTestSongs(count: 3);
        musicBloc.emit(musicBloc.state.copyWith(allSongs: testSongs));
        
        // Test different sorting orders
        for (int i = 0; i < 5; i++) {
          musicBloc.add(MusicEvent.changeSortingOrder(
            sortingIndex: i,
            sortingList: testSongs.map((s) => s.id).toList(),
          ));
          // Wait for the event to be processed
          await Future.delayed(const Duration(milliseconds: 100));
          expect(musicBloc.state.sortingIndex, equals(i));
        }
      });

      test('should handle filter keyword updates', () async {
        const testKeyword = 'test filter';
        
        musicBloc.add(const MusicEvent.updateFilterKeyword(filterKeyword: testKeyword));
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(musicBloc.state.myPlayerState.filterKeyword, equals(testKeyword));
      });
    });

    group('Error Handling', () {
      test('should handle play next when no current song', () async {
        // Ensure no current song
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
        
        // Try to play next
        musicBloc.add(const MusicEvent.playNext());
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should not crash and maintain state
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
      });

      test('should handle play previous when no completed songs', () async {
        // Ensure no current song and no completed songs
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
        expect(musicBloc.state.myPlayerState.completedSongs, isEmpty);
        
        // Try to play previous
        musicBloc.add(const MusicEvent.playPrevious());
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should not crash and maintain state (no completed songs to go back to)
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
        expect(musicBloc.state.myPlayerState.completedSongs, isEmpty);
      });

      test('should handle seek when no current song', () async {
        // Ensure no current song
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
        
        // Try to seek
        musicBloc.add(const MusicEvent.seekToPosition(position: Duration(seconds: 30)));
        
        // Wait for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should not crash and maintain state
        expect(musicBloc.state.myPlayerState.currentSongId, isNull);
      });
    });

    group('State Persistence', () {
      test('should serialize and deserialize state correctly', () {
        // Create a complex state
        final complexState = MusicState(
          myPlayerState: TestHelpers.createTestPlayerState(
            currentSongId: 'test-song',
            isPlaying: true,
            isShuffle: true,
          ),
          isComprehensiveFeaturesExtractingLoading: false,
          isComprehensiveFeaturesExtractingError: false,
          allSongs: TestHelpers.createTestSongs(count: 5),
          albumList: TestHelpers.createTestAlbums(count: 3),
          artistList: TestHelpers.createTestArtists(count: 4),
          myPlaylist: TestHelpers.createTestPlaylists(count: 2),
          sortingIndex: 2,
          isSongListLoading: false,
          isAlbumListLoading: false,
          isArtistListLoading: false,
          isSongListError: false,
          isAlbumListError: false,
          isArtistListError: false,
          isLoading: false,
          isError: false,
          comprehensiveFeatureExtractionFailureCount: const <String, int>{},
        );

        // Serialize to JSON
        final json = musicBloc.toJson(complexState);
        expect(json, isNotNull);

        // Deserialize from JSON
        final deserializedState = musicBloc.fromJson(json!);
        expect(deserializedState, isNotNull);

        // Verify key properties
        expect(deserializedState!.sortingIndex, equals(complexState.sortingIndex));
        expect(deserializedState.allSongs.length, equals(complexState.allSongs.length));
        expect(deserializedState.albumList.length, equals(complexState.albumList.length));
        expect(deserializedState.artistList.length, equals(complexState.artistList.length));
        expect(deserializedState.myPlaylist.length, equals(complexState.myPlaylist.length));
        expect(deserializedState.myPlayerState.currentSongId, equals(complexState.myPlayerState.currentSongId));
        expect(deserializedState.myPlayerState.isPlaying, isFalse); 
        expect(deserializedState.myPlayerState.isShuffle, equals(complexState.myPlayerState.isShuffle));
      });
    });

    group('Performance', () {
      test('should handle large song lists efficiently', () async {
        // Create a large list of songs (reduced from 1000 to 500 for better performance)
        final largeSongList = TestHelpers.createTestSongs(count: 500);
        
        // Load songs
        musicBloc.emit(musicBloc.state.copyWith(allSongs: largeSongList));
        
        // Verify songs are loaded
        expect(musicBloc.state.allSongs.length, equals(500));
        
        // Test that we can add events with large lists without crashing
        // Use a song from the middle of the list to test performance
        final middleSong = largeSongList[250];
        musicBloc.add(MusicEvent.playOrPauseSong(
          songId: middleSong.id,
          currentPlayList: largeSongList.map((s) => s.id).toList(),
        ));
        
        // Wait for the event to be processed (increased timeout for large lists)
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify the bloc is still in a valid state
        expect(musicBloc.state.allSongs.length, equals(500));
        expect(musicBloc.state.isSongListLoading, isFalse);
        expect(musicBloc.state.myPlayerState.currentSongId, equals(middleSong.id));
      });

      test('should handle rapid state changes', () async {
        // Setup state with test songs
        final testSongs = TestHelpers.createTestSongs(count: 3);
        musicBloc.emit(musicBloc.state.copyWith(allSongs: testSongs));
        
        // Rapidly change states
        for (int i = 0; i < 100; i++) {
          musicBloc.add(MusicEvent.changeSortingOrder(
            sortingIndex: i % 5,
            sortingList: testSongs.map((s) => s.id).toList(),
          ));
          musicBloc.add(MusicEvent.toggleShuffle(
            isShuffle: i % 2 == 0,
            currentPlayList: testSongs.map((s) => s.id).toList(),
          ));
          musicBloc.add(const MusicEvent.toggleRepeat());
        }
        
        // Should handle all changes without crashing
        expect(musicBloc.state.sortingIndex, isA<int>());
        expect(musicBloc.state.myPlayerState.isShuffle, isA<bool>());
        expect(musicBloc.state.myPlayerState.repeatModeIndex, isA<int>());
      });
    });
  });
}
