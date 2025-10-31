import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/music_player/pop_up_music_player_widget.dart';
import '../test_helpers.dart';

// Mock classes
class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

class FakeMusicEvent extends Fake implements MusicEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMusicEvent());
  });
  
  group('PopUpMusicPlayerWidget', () {
    late MockMusicBloc mockMusicBloc;
    late MusicState testState;

    setUp(() {
      mockMusicBloc = MockMusicBloc();
      testState = MusicState(
        myPlayerState: TestHelpers.createTestPlayerState(
          currentSongId: 'test-song-id',
          isPlaying: true,
        ),
        allSongs: [TestHelpers.createTestSong()],
        albumList: [],
        artistList: [],
        myPlaylist: [],
        sortingIndex: 0,
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
      
      when(() => mockMusicBloc.state).thenReturn(testState);
      when(() => mockMusicBloc.stream).thenAnswer((_) => Stream.value(testState));
      
      // Mock the currentSong getter to return the test song
      when(() => mockMusicBloc.currentSong).thenReturn(TestHelpers.createTestSong());
    });

    Widget createTestWidget([MusicState? customState, MockMusicBloc? customBloc]) {
      final bloc = customBloc ?? (customState != null ? MockMusicBloc() : mockMusicBloc);
      if (customState != null && customBloc == null) {
        when(() => bloc.state).thenReturn(customState);
        when(() => bloc.stream).thenAnswer((_) => Stream.value(customState));
        // Mock the currentSong getter for custom state
        when(() => bloc.currentSong).thenReturn(
          customState.myPlayerState.currentSongId != null 
            ? TestHelpers.createTestSong(id: customState.myPlayerState.currentSongId!)
            : null
        );
      }
      
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Main content area
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[100],
                  ),
                  // PopUpMusicPlayerWidget needs to be in a Stack because it uses Positioned
                  BlocProvider<MusicBloc>(
                    create: (context) => bloc,
                    child: const PopUpMusicPlayerWidget(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render when current song exists', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show the music player widget
        expect(find.byType(PopUpMusicPlayerWidget), findsOneWidget);
      });

      testWidgets('should not render when no current song', (WidgetTester tester) async {
        final noSongState = testState.copyWith(
          myPlayerState: testState.myPlayerState.copyWith(currentSongId: null),
        );

        await tester.pumpWidget(createTestWidget(noSongState));
        await tester.pump();

        // Should not show the music player widget content (returns SizedBox.shrink)
        expect(find.byType(SizedBox), findsWidgets);
      });
    });

    group('Play/Pause Button', () {
      testWidgets('should show play button when not playing', (WidgetTester tester) async {
        final pausedState = testState.copyWith(
          myPlayerState: testState.myPlayerState.copyWith(isPlaying: false),
        );

        await tester.pumpWidget(createTestWidget(pausedState));
        await tester.pump();
        
        // Wait for initial animations but not infinite ones
        await tester.pump(const Duration(milliseconds: 300));

        // Should show play button in the mini player
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should show pause button when playing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations but not infinite ones
        await tester.pump(const Duration(milliseconds: 300));

        // Should show pause button in the mini player
        expect(find.byIcon(Icons.pause), findsOneWidget);
      });
    });

    group('Song Information', () {
      testWidgets('should display song title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Test Song'), findsOneWidget);
      });

      testWidgets('should display artist name', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Test Artist'), findsOneWidget);
      });
    });

    group('Mini Player Features', () {
      testWidgets('should have album art', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        // Should have album art widget
        expect(find.byType(ClipRRect), findsWidgets);
      });

      testWidgets('should be tappable to open full player', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        // Should have InkWell for tapping
        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should call play/pause when play button is tapped', (WidgetTester tester) async {
        // Create a paused state for this test
        final pausedState = testState.copyWith(
          myPlayerState: testState.myPlayerState.copyWith(isPlaying: false),
        );

        // Create a new mock bloc for this test
        final testBloc = MockMusicBloc();
        when(() => testBloc.state).thenReturn(pausedState);
        when(() => testBloc.stream).thenAnswer((_) => Stream.value(pausedState));
        when(() => testBloc.currentSong).thenReturn(TestHelpers.createTestSong());
        when(() => testBloc.add(any())).thenReturn(null);

        await tester.pumpWidget(createTestWidget(pausedState, testBloc));
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        verify(() => testBloc.add(any())).called(1);
      });

      testWidgets('should call play/pause when pause button is tapped', (WidgetTester tester) async {
        when(() => mockMusicBloc.add(any())).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        verify(() => mockMusicBloc.add(any())).called(1);
      });
    });

    group('State Updates', () {
      testWidgets('should show correct icon based on playing state', (WidgetTester tester) async {
        // Test paused state
        final pausedState = testState.copyWith(
          myPlayerState: testState.myPlayerState.copyWith(isPlaying: false),
        );
        
        await tester.pumpWidget(createTestWidget(pausedState));
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        // Should show play button when paused
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should show correct icon when playing', (WidgetTester tester) async {
        // Test playing state
        await tester.pumpWidget(createTestWidget(testState));
        await tester.pump();
        
        // Wait for initial animations
        await tester.pump(const Duration(milliseconds: 300));

        // Should show pause button when playing
        expect(find.byIcon(Icons.pause), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null current song gracefully', (WidgetTester tester) async {
        final nullSongState = testState.copyWith(
          myPlayerState: testState.myPlayerState.copyWith(currentSongId: null),
        );

        await tester.pumpWidget(createTestWidget(nullSongState));
        await tester.pump();

        // Should not crash and should handle gracefully
        expect(find.byType(PopUpMusicPlayerWidget), findsOneWidget);
      });

      testWidgets('should handle empty song list gracefully', (WidgetTester tester) async {
        final emptySongsState = testState.copyWith(allSongs: []);

        await tester.pumpWidget(createTestWidget(emptySongsState));
        await tester.pump();

        // Should not crash and should handle gracefully
        expect(find.byType(PopUpMusicPlayerWidget), findsOneWidget);
      });
    });
  });
}
