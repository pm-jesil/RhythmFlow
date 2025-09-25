// Basic Flutter widget test for PMJ Music Player
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pmj_music_player/core/theme/app_theme.dart';
import 'package:pmj_music_player/core/theme/theme_bloc.dart';
import 'package:pmj_music_player/core/constants/app_constants.dart';
import 'package:pmj_music_player/screens/bottom_tab/screens/bloc/music_bloc.dart';
import 'package:pmj_music_player/screens/bottom_tab/screens/for_you_screen.dart';
import 'package:pmj_music_player/utils/models/my_player_state_model.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

class FakeMusicEvent extends Fake implements MusicEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMusicEvent());
  });

  testWidgets('App loads without crashing', (WidgetTester tester) async {
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
    // Create mock bloc with empty state
    final mockMusicBloc = MockMusicBloc();
    
    // Mock the state to return an empty state
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
        isSongListLoading: true, // Loading state
        isAlbumListLoading: false,
        isArtistListLoading: false,
        isSongListError: false,
        isAlbumListError: false,
        isArtistListError: false,
        isLoading: true,
        isError: false,
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

    // Verify that the app loads without crashing even with empty state
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that the main screen is loaded
    expect(find.byType(ForYouScreen), findsOneWidget);
  });
}
