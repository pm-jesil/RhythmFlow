import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/core/theme/app_theme.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/screens/albums_screen.dart';
import 'package:rhythmflow/screens/bottom_tab/screens/artists_screen.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/music_service.dart';

import 'library_test_utils.dart';

class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

/// Regression test for "new albums / artists do not appear after a scan".
///
/// The Albums and Artists tabs used to cache their list the first time it
/// became non-empty, so a scan that added or removed albums was not shown
/// until the app restarted.
void main() {
  late MockMusicBloc bloc;
  late StreamController<MusicState> states;
  late MusicState current;

  MusicState libraryState(List<Song> songs) => MusicState.initial().copyWith(
    allSongs: songs,
    albumList: MusicService.fetchAlbumList(songs),
    artistList: MusicService.fetchArtistList(songs),
  );

  setUp(() {
    bloc = MockMusicBloc();
    states = StreamController<MusicState>.broadcast();
    current = MusicState.initial();
    when(() => bloc.state).thenAnswer((_) => current);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
  });

  tearDown(() => states.close());

  Future<void> pumpTab(WidgetTester tester, Widget tab) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<MusicBloc>.value(
        value: bloc,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) =>
              MaterialApp(theme: AppTheme.lightTheme, home: tab),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, MusicState next) async {
    current = next;
    states.add(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  final queen = testSong(id: 'q', title: 'Q', artists: ['Queen'], albums: ['Hits'], albumArtist: 'Queen');
  final adele = testSong(id: 'a', title: 'A', artists: ['Adele'], albums: ['25'], albumArtist: 'Adele');
  final abba = testSong(id: 'b', title: 'B', artists: ['ABBA'], albums: ['Gold'], albumArtist: 'ABBA');

  testWidgets('Albums tab shows albums added and removed by a scan', (tester) async {
    current = libraryState([queen]);
    await pumpTab(tester, const AlbumsScreen());
    expect(find.text('Hits'), findsOneWidget);
    expect(find.text('25'), findsNothing);

    // Scan finds two more albums.
    await emit(tester, libraryState([queen, adele, abba]));
    expect(find.text('Hits'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);

    // Queen's file is deleted -> its album disappears.
    await emit(tester, libraryState([adele, abba]));
    expect(find.text('Hits'), findsNothing);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('Artists tab shows artists added and removed by a scan', (tester) async {
    current = libraryState([queen]);
    await pumpTab(tester, const ArtistsScreen());
    expect(find.text('Queen'), findsOneWidget);

    await emit(tester, libraryState([queen, adele]));
    expect(find.text('Adele'), findsOneWidget);

    await emit(tester, libraryState([adele]));
    expect(find.text('Queen'), findsNothing);
    expect(find.text('Adele'), findsOneWidget);
  });

  testWidgets('Albums tab shows the empty state once the last album is gone', (tester) async {
    current = libraryState([queen]);
    await pumpTab(tester, const AlbumsScreen());
    expect(find.text('Hits'), findsOneWidget);

    await emit(tester, libraryState(const []));
    expect(find.text('Hits'), findsNothing);
    expect(find.text('No albums found'), findsOneWidget);
  });
}
