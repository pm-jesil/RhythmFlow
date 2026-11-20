import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/core/theme/app_theme.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/screens/bottom_tab/screens/playlists_screen.dart';
import 'package:rhythmflow/screens/bottom_tab/widgets/song_context_menu.dart';
import 'package:rhythmflow/screens/online/bloc/online_library_bloc.dart';
import 'package:rhythmflow/screens/ringtones/bloc/ringtone_library_bloc.dart';
import 'package:rhythmflow/screens/ringtones/my_ringtones_screen.dart';
import 'package:rhythmflow/screens/ringtones/ringtone_actions.dart';
import 'package:rhythmflow/screens/ringtones/ringtone_editor_screen.dart';
import 'package:rhythmflow/screens/ringtones/ringtone_preview.dart';
import 'package:rhythmflow/utils/models/ringtone/ringtone_model.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/ringtone/audio_trimmer.dart';
import 'package:rhythmflow/utils/services/ringtone/ringtone_service.dart';

import 'audio_trimmer_test.dart' show mp3;
import 'ringtone_logic_test.dart' show FakePlatform, MockStorage, item, localSong, onlineSong;

class MockMusicBloc extends Mock implements MusicBloc {
  @override
  Future<void> close() async {}
}

class FakeMusicEvent extends Fake implements MusicEvent {}

class FakePreview implements RingtonePreview {
  final playing = StreamController<bool>.broadcast();
  final position = StreamController<Duration>.broadcast();
  final calls = <String>[];
  Duration? length = const Duration(minutes: 3);

  @override
  Stream<bool> get playingStream => playing.stream;
  @override
  Stream<Duration> get positionStream => position.stream;
  @override
  Future<Duration?> load(String source) async {
    calls.add('load:${source.split('/').last}');
    return length;
  }

  @override
  Future<void> play({Duration? start, Duration? end}) async {
    calls.add('play:${start?.inMilliseconds}-${end?.inMilliseconds}');
    playing.add(true);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    playing.add(false);
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  late Directory dir;
  late FakePlatform platform;
  late MockMusicBloc music;
  late RingtoneLibraryBloc ringtones;
  late OnlineLibraryBloc onlineLibrary;
  late AppSettingsBloc settings;
  late FakePreview preview;
  late Completer<void>? downloadGate;
  late List<FakePreview> previews;

  setUpAll(() => registerFallbackValue(FakeMusicEvent()));

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('rt_ui_');
    platform = FakePlatform(Directory('${dir.path}/saved')..createSync());
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    AudioTrimmer.isAndroidOverride = false;
    downloadGate = null;
    previews = [];
    RingtonePreview.factory = () {
      preview = FakePreview();
      previews.add(preview);
      return preview;
    };

    await getIt.reset();
    getIt.registerSingleton<RingtoneService>(RingtoneService(
      download: (url, path, progress) async {
        progress(30, 100);
        if (downloadGate != null) await downloadGate!.future;
        await File(path).writeAsBytes(mp3(frames: 8000));
        progress(100, 100);
      },
      validate: (p) async => File(p).existsSync(),
      cacheDir: () async => dir,
      platform: platform.platform,
    ));

    music = MockMusicBloc();
    when(() => music.state).thenReturn(MusicState.initial());
    when(() => music.stream).thenAnswer((_) => const Stream.empty());
    when(() => music.pauseIfPlaying()).thenReturn(true);
    when(() => music.audioPosition).thenReturn(Duration.zero);
    when(() => music.add(any())).thenReturn(null);
    ringtones = RingtoneLibraryBloc();
    onlineLibrary = OnlineLibraryBloc();
    settings = AppSettingsBloc();
  });

  tearDown(() async {
    RingtonePreview.factory = JustAudioRingtonePreview.new;
    AudioTrimmer.isAndroidOverride = null;
    await ringtones.close();
    await onlineLibrary.close();
    await settings.close();
    await getIt.reset();
    dir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<MusicBloc>.value(value: music),
        BlocProvider<AppSettingsBloc>.value(value: settings),
        BlocProvider<OnlineLibraryBloc>.value(value: onlineLibrary),
        BlocProvider<RingtoneLibraryBloc>.value(value: ringtones),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(theme: AppTheme.lightTheme, home: home),
      ),
    ));
  }

  /// Real file IO happens outside the fake clock.
  Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps (with real IO time) until [finder] matches, up to ~6 s.
  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  /// Route transitions (an indeterminate spinner never settles).
  Future<void> pumpRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  String text(WidgetTester tester, String key) =>
      (tester.widget(find.byKey(ValueKey(key))) as Text).data!;

  File localFile() => File('${dir.path}/song.mp3')..writeAsBytesSync(mp3(frames: 8000));

  group('ringtone editor', () {
    testWidgets('local song: pauses music, trims, previews, renames and saves', (tester) async {
      final song = localSong(path: localFile().path);
      await pump(tester, RingtoneEditorScreen(song: song));
      verify(() => music.pauseIfPlaying()).called(1);
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_trim')));
      await settle(tester, 2);

      expect(find.byKey(const ValueKey('ringtone_trim')), findsOneWidget);
      expect(text(tester, 'ringtone_length'), '0:30.0');
      expect(text(tester, 'start_value'), '0:00.0');
      expect(preview.calls, contains('load:song.mp3'));

      await tester.tap(find.byKey(const ValueKey('start_plus')));
      await tester.tap(find.byKey(const ValueKey('start_plus')));
      await tester.pump();
      expect(text(tester, 'start_value'), '0:01.0');
      await tester.tap(find.byKey(const ValueKey('end_minus')));
      await tester.pump();
      expect(text(tester, 'end_value'), '0:29.5');
      expect(text(tester, 'ringtone_length'), '0:28.5');

      await tester.tap(find.byKey(const ValueKey('ringtone_preview')));
      await tester.pump();
      expect(preview.calls.last, 'play:1000-29500');
      expect(find.text('Stop preview'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ringtone_preview')));
      await tester.pump();
      expect(preview.calls.last, 'stop');

      await tester.enterText(find.byKey(const ValueKey('ringtone_name')), 'Wake up');
      await tester.ensureVisible(find.byKey(const ValueKey('ringtone_save')));
      await tester.tap(find.byKey(const ValueKey('ringtone_save')));
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_saved')));
      expect(text(tester, 'ringtone_saved_name'), 'Wake up');
      final saved = ringtones.state.items.single;
      expect(saved.name, 'Wake up');
      expect(saved.startMs, 1000);
      expect(File(saved.path).existsSync(), isTrue);
    });

    testWidgets('Discover song: downloads automatically with progress first', (tester) async {
      downloadGate = Completer<void>();
      await pump(tester, RingtoneEditorScreen(song: onlineSong()));
      expect(find.byKey(const ValueKey('ringtone_preparing')), findsOneWidget);
      await pumpUntil(tester, find.textContaining('30%'));
      expect(find.byKey(const ValueKey('ringtone_save')), findsNothing);
      downloadGate!.complete();
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_trim')));
      await settle(tester, 2);
      expect(preview.calls.single, 'load:77.mp3');
    });

    testWidgets('songs that cannot be used show the reason without retry', (tester) async {
      await pump(tester, RingtoneEditorScreen(song: onlineSong(download: false)));
      await settle(tester, 2);
      expect(find.byKey(const ValueKey('ringtone_error')), findsOneWidget);
      expect(text(tester, 'ringtone_error_text'), contains('allow downloads'));
      expect(find.byKey(const ValueKey('ringtone_retry')), findsNothing);
    });

    testWidgets('a missing local file can be retried', (tester) async {
      final path = '${dir.path}/later.mp3';
      await pump(tester, RingtoneEditorScreen(song: localSong(path: path)));
      await settle(tester, 2);
      expect(text(tester, 'ringtone_error_text'), contains('missing'));
      File(path).writeAsBytesSync(mp3(frames: 3000));
      await tester.tap(find.byKey(const ValueKey('ringtone_retry')));
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_trim')));
    });

    testWidgets('closing the editor disposes the preview player', (tester) async {
      await pump(tester, Builder(
        builder: (context) => TextButton(
          onPressed: () => openRingtoneEditor(context, localSong(path: localFile().path)),
          child: const Text('open'),
        ),
      ));
      await tester.tap(find.text('open'));
      await pumpRoute(tester);
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_trim')));
      await tester.tap(find.byKey(const ValueKey('ringtone_close')));
      await pumpRoute(tester);
      expect(find.text('open'), findsOneWidget);
      expect(preview.calls.last, 'dispose');
    });

    testWidgets('openRingtoneEditor refuses radio with a message', (tester) async {
      final radio = Song(
        id: 'jmr_1', title: 'Radio', artists: ['Jamendo'], albums: const [], path: '',
        duration: Duration.zero, source: SongSources.jamendoRadio,
      );
      await pump(tester, Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => openRingtoneEditor(context, radio), child: const Text('open')),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(find.byType(RingtoneEditorScreen), findsNothing);
      expect(find.textContaining('radio'), findsOneWidget);
    });

    testWidgets('after saving: set as ringtone asks for permission, then works', (tester) async {
      await pump(tester, RingtoneEditorScreen(song: localSong(path: localFile().path)));
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_trim')));
      await tester.ensureVisible(find.byKey(const ValueKey('ringtone_save')));
      await tester.tap(find.byKey(const ValueKey('ringtone_save')));
      await pumpUntil(tester, find.byKey(const ValueKey('ringtone_saved')));

      await tester.tap(find.byKey(const ValueKey('set_as_ringtone')));
      await settle(tester, 2);
      expect(find.byKey(const ValueKey('ringtone_permission_dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ringtone_permission_open')));
      await settle(tester, 2);
      expect(platform.calls, contains('openSettings'));

      platform.canWrite = true;
      await tester.tap(find.byKey(const ValueKey('set_as_ringtone')));
      await settle(tester, 2);
      final id = ringtones.state.items.single.id;
      expect(ringtones.state.usesOf(id), [RingtoneUse.ringtone]);
      expect(platform.calls.last, startsWith('set:ringtone:content://'));

      await tester.tap(find.byKey(const ValueKey('ringtone_open_list')));
      await pumpRoute(tester);
      expect(find.byType(MyRingtonesScreen), findsOneWidget);
      expect(find.byKey(ValueKey('ringtone_$id')), findsOneWidget);
    });
  });

  group('My Ringtones', () {
    Future<RingtoneItem> addSaved(String id, String name) async {
      final f = File('${platform.dir.path}/$name.mp3')..writeAsBytesSync(mp3(frames: 300));
      final i = RingtoneItem(
        id: id, name: name, path: f.path, uri: 'content://media/$id', sourceSongId: 's',
        songTitle: 'Song', artist: 'Artist', startMs: 0, endMs: 7000, createdAtMs: 1,
      );
      ringtones.add(RingtoneLibraryEvent.added(i));
      await Future<void>.delayed(Duration.zero);
      return i;
    }

    testWidgets('empty state', (tester) async {
      await pump(tester, const MyRingtonesScreen());
      await settle(tester, 2);
      expect(find.byKey(const ValueKey('ringtones_empty')), findsOneWidget);
      expect(find.text('0 ringtones'), findsOneWidget);
    });

    testWidgets('list, preview, rename, set as and delete', (tester) async {
      await tester.runAsync(() async {
        await addSaved('a', 'First');
        await addSaved('b', 'Second');
      });
      await pump(tester, const MyRingtonesScreen());
      await settle(tester, 2);
      expect(find.text('2 ringtones'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      // Preview pauses the music and plays the file.
      await tester.tap(find.text('First'));
      await settle(tester, 2);
      verify(() => music.pauseIfPlaying()).called(1);
      expect(preview.calls, containsAllInOrder(['load:First.mp3', 'play:null-null']));
      await tester.tap(find.text('First'));
      await settle(tester, 2);
      expect(preview.calls.last, 'stop');

      // Rename to a taken name -> made unique.
      await tester.tap(find.byKey(const ValueKey('ringtone_menu_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('rename_field')), 'Second');
      await tester.tap(find.byKey(const ValueKey('rename_save')));
      await settle(tester, 4);
      expect(ringtones.state.byId('a')!.name, 'Second (2)');
      expect(File('${platform.dir.path}/Second (2).mp3').existsSync(), isTrue);

      // Set as alarm (permission already granted).
      platform.canWrite = true;
      await tester.tap(find.byKey(const ValueKey('ringtone_menu_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as alarm'));
      await settle(tester, 3);
      expect(ringtones.state.usesOf('b'), [RingtoneUse.alarm]);
      expect(find.textContaining('Alarm'), findsWidgets);

      // Delete with confirmation; cancel first.
      await tester.tap(find.byKey(const ValueKey('ringtone_menu_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ringtones.state.count, 2);
      await tester.tap(find.byKey(const ValueKey('ringtone_menu_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_confirm')));
      await settle(tester, 4);
      expect(ringtones.state.items.map((i) => i.id), ['a']);
      expect(ringtones.state.defaults, isEmpty);
      expect(File('${platform.dir.path}/Second.mp3').existsSync(), isFalse);
    });

    testWidgets('ringtones deleted outside the app disappear when the list opens', (tester) async {
      await tester.runAsync(() async {
        await ringtones.close();
        ringtones = RingtoneLibraryBloc(exists: getIt<RingtoneService>().exists);
        final gone = await addSaved('gone', 'Gone');
        await addSaved('kept', 'Kept');
        File(gone.path).deleteSync();
      });
      await pump(tester, const MyRingtonesScreen());
      await settle(tester, 4);
      expect(find.text('Kept'), findsOneWidget);
      expect(find.text('Gone'), findsNothing);
    });
  });

  group('My Ringtones tile', () {
    testWidgets('on the local Playlists tab with the count, opens the list', (tester) async {
      await tester.runAsync(() async {
        ringtones.add(RingtoneLibraryEvent.added(item('x')));
        await Future<void>.delayed(Duration.zero);
      });
      await pump(tester, const PlaylistsScreen());
      await settle(tester, 2);
      expect(find.byKey(const ValueKey('my_ringtones_tile')), findsOneWidget);
      expect(find.text('1 ringtone'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('my_ringtones_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(MyRingtonesScreen), findsOneWidget);
    });

    testWidgets('empty hint', (tester) async {
      await pump(tester, const Scaffold(body: MyRingtonesTile()));
      expect(find.text('Make one from any song in the player'), findsOneWidget);
    });
  });

  testWidgets('local song menu offers "Make Ringtone" without overflow', (tester) async {
    String? action;
    await pump(tester, Scaffold(
      body: SongContextMenu(
        songTitle: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        songId: 'local_1',
        position: const Offset(150, 700),
        size: const Size(80, 40),
        onMenuAction: (a, id, t, ar, al) => action = a,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Make Ringtone'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(action, 'ringtone');
  });

  test('formatClock', () {
    expect(formatClock(const Duration(minutes: 1, seconds: 5, milliseconds: 730), tenths: true), '1:05.7');
    expect(formatClock(const Duration(seconds: 9)), '0:09');
  });

  test('PlatformException code mapping stays stable', () {
    expect(PlatformException(code: 'no_permission').code, 'no_permission');
  });
}
