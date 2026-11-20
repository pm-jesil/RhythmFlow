import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/core/theme/app_theme.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/screens/for_you_screen.dart';
import 'package:rhythmflow/screens/online/bloc/discover_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/online_browse_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/online_library_bloc.dart';
import 'package:rhythmflow/screens/online/online_browse_screen.dart';
import 'package:rhythmflow/screens/online/online_playlists_screen.dart';
import 'package:rhythmflow/screens/online/widgets/discover_setup_dialog.dart';
import 'package:rhythmflow/screens/online/widgets/region_pickers.dart';
import 'package:rhythmflow/screens/widgets/music_source_switch.dart';
import 'package:rhythmflow/utils/models/playlist_source/playlist_source_model.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_repository.dart';
import 'package:rhythmflow/utils/services/jamendo/online_song_registry.dart';
import 'package:rhythmflow/utils/services/jamendo/region_models.dart';

import 'jamendo_data_layer_test.dart' show FakeTransport, envelope;
import 'online_blocs_test.dart' show fakeJamendo, repoFor;

class MockStorage extends Mock implements Storage {}

class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

class FakeMusicEvent extends Fake implements MusicEvent {}

/// Fake Jamendo without network images (no image plugins in tests).
FakeTransport uiJamendo() {
  final t = fakeJamendo();
  final base = t.handler!;
  t.handler = (uri) {
    if (uri.path.endsWith('/radios/')) {
      return envelope([
        {'id': 1, 'name': 'bestof', 'dispname': 'Best Of Jamendo Radio', 'image': ''},
        {'id': 2, 'name': 'pop', 'dispname': 'Pop Radio', 'image': ''},
      ]);
    }
    return base(uri);
  };
  return t;
}

void main() {
  late AppSettingsBloc settings;
  late DiscoverBloc discover;
  late OnlineLibraryBloc library;
  late MockMusicBloc music;
  late FakeTransport jamendo;
  final musicEvents = <MusicEvent>[];

  setUpAll(() => registerFallbackValue(FakeMusicEvent()));

  setUp(() async {
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    OnlineSongRegistry.clear();
    OnlineQueues.clear();

    jamendo = uiJamendo();
    final repo = repoFor(jamendo);
    await getIt.reset();
    getIt.registerSingleton<JamendoRepository>(repo);

    settings = AppSettingsBloc();
    discover = DiscoverBloc(repository: repo);
    library = OnlineLibraryBloc();
    music = MockMusicBloc();
    musicEvents.clear();
    when(() => music.state).thenReturn(MusicState.initial());
    when(() => music.stream).thenAnswer((_) => const Stream.empty());
    when(() => music.add(any())).thenAnswer((i) => musicEvents.add(i.positionalArguments.first as MusicEvent));
    DiscoverSetupDialog.minSetupTime = const Duration(milliseconds: 50);
    DiscoverSetupDialog.doneTime = const Duration(milliseconds: 50);
    OnlineBrowseBloc.queryDebounce = const Duration(milliseconds: 20);
  });

  tearDown(() async {
    await settings.close();
    await discover.close();
    await library.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppSettingsBloc>.value(value: settings),
          BlocProvider<MusicBloc>.value(value: music),
          BlocProvider<DiscoverBloc>.value(value: discover),
          BlocProvider<OnlineLibraryBloc>.value(value: library),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(theme: AppTheme.lightTheme, home: child),
        ),
      ),
    );
  }

  /// Lets bloc futures (fake network) complete between frames.
  Future<void> settle(WidgetTester tester, [int rounds = 10]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void setRegion() {
    settings.add(const AppSettingsEvent.updateMusicRegion(country: 'IN', languages: ['ml']));
  }

  testWidgets('source switch toggles My Music / Discover', (tester) async {
    await pump(tester, const Scaffold(body: Center(child: MusicSourceSwitch())));
    expect(settings.state.isOnlineSource, isTrue, reason: 'Discover is the default');
    expect(find.text('My Music'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('source_local')));
    await settle(tester, 2);
    expect(settings.state.isOnlineSource, isFalse);

    await tester.tap(find.byKey(const ValueKey('source_online')));
    await settle(tester, 2);
    expect(settings.state.isOnlineSource, isTrue);
  });

  testWidgets('For You shows Discover sections, then local content in My Music', (tester) async {
    setRegion();
    await pump(tester, const ForYouScreen());
    await settle(tester, 15);

    expect(find.byType(MusicSourceSwitch), findsOneWidget);
    expect(find.textContaining('Top in India'), findsOneWidget);
    expect(find.text('Malayalam picks'), findsOneWidget);
    expect(find.text('Trending this week'), findsOneWidget);
    expect(find.byKey(const ValueKey('discover_region_chip')), findsOneWidget);
    expect(find.textContaining('India · Malayalam'), findsOneWidget);

    // Tap the first trending card -> plays that Discover list.
    await tester.ensureVisible(find.text('popularity_week 0').first);
    await tester.pump();
    await tester.tap(find.text('popularity_week 0').first);
    await tester.pump();
    final play = musicEvents.lastWhere(
      (e) => e.maybeWhen(playOrPauseSong: (_, _, _, _) => true, orElse: () => false),
    );
    play.maybeWhen(
      playOrPauseSong: (songId, playList, isForceStop, source) {
        expect(source, PlaylistSource.online('section_${DiscoverSectionIds.trending}'));
        expect(playList, hasLength(3));
      },
      orElse: () => fail('expected playOrPauseSong, got $play'),
    );

    // Scroll back to the top where the switch is.
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 4000));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('source_local')));
    await settle(tester, 3);
    expect(find.textContaining('Top in India'), findsNothing);
    expect(find.text('Artists'), findsWidgets, reason: 'local quick stats are back');
  });

  testWidgets('first time on Discover: setup popup, setting up, then closes', (tester) async {
    await pump(tester, const ForYouScreen());
    await settle(tester, 3);

    // Popup is shown because no country / language is set yet.
    expect(find.byKey(const ValueKey('setup_submit')), findsOneWidget);
    // Pre-selected from the test locale (en_US).
    expect(find.textContaining('United States'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('setup_submit')));
    await tester.pump();
    expect(find.text('Setting up your music player'), findsOneWidget);
    expect(find.textContaining('Finding artists from United States'), findsOneWidget);

    await settle(tester, 20);
    expect(find.text('Setting up your music player'), findsNothing);
    expect(find.byType(DiscoverSetupDialog), findsNothing, reason: 'popup closed');
    expect(settings.state.musicCountry, 'US');
    expect(settings.state.musicLanguages, ['en']);
    expect(find.textContaining('Top in United States'), findsOneWidget);
    expect(find.byType(ForYouScreen), findsOneWidget, reason: 'screen underneath not popped');
  });

  testWidgets('"Not now" closes the popup without saving', (tester) async {
    await pump(tester, Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDiscoverSetupDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('setup_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverSetupDialog), findsNothing);
    expect(settings.state.hasMusicRegion, isFalse);
  });

  testWidgets('country picker searches and returns the choice', (tester) async {
    MusicCountry? picked;
    await pump(tester, Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => picked = await showCountryPicker(context),
            child: const Text('pick'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your country'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'indi');
    await tester.pumpAndSettle();
    expect(find.text('India'), findsOneWidget);
    expect(find.text('France'), findsNothing);
    await tester.tap(find.text('India'));
    await tester.pumpAndSettle();
    expect(picked?.alpha2, 'IN');
  });

  testWidgets('language picker keeps selection order (first = primary)', (tester) async {
    List<String>? picked;
    await pump(tester, Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => picked = await showLanguagePicker(context),
            child: const Text('pick'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Malayalam'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tamil');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamil'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Done'));
    await tester.pumpAndSettle();
    expect(picked, ['ml', 'ta']);
  });

  testWidgets('online Songs tab: skeleton, list, search, play', (tester) async {
    await pump(tester, const OnlineBrowseScreen(kind: OnlineBrowseKind.tracks));
    // First frame: skeleton rows shaped like the real list.
    expect(find.text('Loading a great song'), findsWidgets, reason: 'skeleton rows');

    await settle(tester, 5);
    expect(find.text('popularity_week 0'), findsOneWidget);
    expect(find.text('Loading a great song'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('online_search')), 'love');
    await settle(tester, 6);
    expect(find.text('love 0'), findsOneWidget);

    await tester.tap(find.text('love 1'));
    await tester.pump();
    final play = musicEvents.last;
    play.maybeWhen(
      playOrPauseSong: (songId, playList, isForceStop, source) {
        expect(source, PlaylistSource.online('browse_tracks'));
        expect(OnlineSongRegistry.get(songId!)?.title, 'love 1');
      },
      orElse: () => fail('expected playOrPauseSong'),
    );
  });

  testWidgets('online Albums and Artists tabs show grids', (tester) async {
    await pump(tester, const OnlineBrowseScreen(kind: OnlineBrowseKind.albums));
    await settle(tester, 5);
    expect(find.text('Album 0'), findsOneWidget);

    await pump(tester, const OnlineBrowseScreen(kind: OnlineBrowseKind.artists));
    await settle(tester, 5);
    expect(find.text('Artist 0'), findsOneWidget);
  });

  testWidgets('online Playlists tab: library, mixes and radio', (tester) async {
    await pump(tester, const OnlinePlaylistsScreen());
    await settle(tester, 5);
    expect(find.text('Liked songs'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);
    expect(find.text('Downloaded'), findsOneWidget);
    expect(find.text('Pop Mix'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await settle(tester, 2);
    expect(find.text('Best Of Jamendo'), findsOneWidget);
    await tester.tap(find.text('Best Of Jamendo'));
    await tester.pump();
    musicEvents.last.maybeWhen(
      playOrPauseSong: (songId, playList, isForceStop, source) {
        expect(songId, 'jmr_1');
        expect(OnlineSongRegistry.get(songId!)!.isRadio, isTrue);
      },
      orElse: () => fail('expected radio playback'),
    );
  });
}
