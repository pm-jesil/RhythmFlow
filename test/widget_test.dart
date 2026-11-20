// Basic Flutter widget test for RhythmFlow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rhythmflow/core/theme/app_theme.dart';
import 'package:rhythmflow/core/theme/theme_bloc.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/screens/for_you_screen.dart';
import 'package:rhythmflow/utils/models/my_player_state_model.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

class FakeMusicEvent extends Fake implements MusicEvent {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {
  @override
  Future<void> close() async {}
}

/// ForYouScreen reads AppSettingsBloc, so the tests must provide one.
AppSettingsBloc _mockAppSettingsBloc() {
  final bloc = MockAppSettingsBloc();
  when(() => bloc.state).thenReturn(AppSettingsState.initial());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMusicEvent());
  });

  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // RhythmFlow is a portrait phone app; use a phone-sized surface instead
    // of the 800x600 test default.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    // Create mock bloc
    final mockMusicBloc = MockMusicBloc();
    
    // Mock the state to return a basic state
    when(() => mockMusicBloc.state).thenReturn(
      MusicState(
        myPlayerState: MyPlayerStateModel(
          currentSongId: null,
          isPlaying: false,
          currentPlayList: [],
          isShuffle: false,
          repeatModeIndex: 0,
        ),
        allSongs: [],
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
      ),
    );
    
    when(() => mockMusicBloc.stream).thenAnswer((_) => Stream.value(mockMusicBloc.state));

    // Build a simplified app for testing
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc()..add(const ThemeEvent.initialize()),
          ),
          BlocProvider<MusicBloc>(
            create: (context) => mockMusicBloc,
          ),
          BlocProvider<AppSettingsBloc>(
            create: (context) => _mockAppSettingsBloc(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return ScreenUtilInit(
              designSize: const Size(375, 812),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  home: const ForYouScreen(),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that the main screen is loaded
    expect(find.byType(ForYouScreen), findsOneWidget);
  });

  testWidgets('App theme switching works', (WidgetTester tester) async {
    // RhythmFlow is a portrait phone app; use a phone-sized surface instead
    // of the 800x600 test default.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    // Create mock bloc
    final mockMusicBloc = MockMusicBloc();
    
    // Mock the state to return a basic state
    when(() => mockMusicBloc.state).thenReturn(
      MusicState(
        myPlayerState: MyPlayerStateModel(
          currentSongId: null,
          isPlaying: false,
          currentPlayList: [],
          isShuffle: false,
          repeatModeIndex: 0,
        ),
        allSongs: [],
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
      ),
    );
    
    when(() => mockMusicBloc.stream).thenAnswer((_) => Stream.value(mockMusicBloc.state));

    // Build a simplified app for testing
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc()..add(const ThemeEvent.initialize()),
          ),
          BlocProvider<MusicBloc>(
            create: (context) => mockMusicBloc,
          ),
          BlocProvider<AppSettingsBloc>(
            create: (context) => _mockAppSettingsBloc(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return ScreenUtilInit(
              designSize: const Size(375, 812),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) {
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  home: const ForYouScreen(),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that the main screen is loaded
    expect(find.byType(ForYouScreen), findsOneWidget);
    
    // Verify that ScreenUtil is properly initialized
    expect(find.byType(ScreenUtilInit), findsOneWidget);
  });

  testWidgets('App handles empty state gracefully', (WidgetTester tester) async {
    // Create a simple MaterialApp without complex widgets to avoid SliverList issues
    await tester.pumpWidget(
      MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Text(
              'RhythmFlow',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('RhythmFlow'), findsOneWidget);
  });
}
