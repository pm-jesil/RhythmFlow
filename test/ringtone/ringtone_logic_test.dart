import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/ringtones/bloc/ringtone_editor_cubit.dart';
import 'package:rhythmflow/screens/ringtones/bloc/ringtone_library_bloc.dart';
import 'package:rhythmflow/utils/models/ringtone/ringtone_model.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/ringtone/audio_trimmer.dart';
import 'package:rhythmflow/utils/services/ringtone/ringtone_service.dart';

import 'audio_trimmer_test.dart' show mp3;

class MockStorage extends Mock implements Storage {}

Song localSong({String path = '/music/a.mp3', Duration duration = const Duration(minutes: 3)}) => Song(
  id: 'local_1',
  title: 'Local Song',
  artists: ['Local Artist'],
  albums: ['Album'],
  path: path,
  duration: duration,
);

Song onlineSong({bool download = true, int id = 77}) => JamendoMapper.track({
  'id': '$id',
  'name': 'Online Song',
  'artist_name': 'Jamendo Artist',
  'duration': 200,
  'audio': 'https://stream/$id',
  'audiodownload': download ? 'https://download/$id' : '',
  'audiodownload_allowed': download,
});

RingtoneItem item(String id, {String name = 'Tone', String path = '/r/tone.mp3'}) => RingtoneItem(
  id: id,
  name: name,
  path: path,
  uri: 'content://media/$id',
  sourceSongId: 's',
  songTitle: 'Song',
  artist: 'Artist',
  startMs: 1000,
  endMs: 31000,
  createdAtMs: 1,
);

/// Records platform calls; files go to [dir].
class FakePlatform {
  final Directory dir;
  final calls = <String>[];
  bool canWrite = false;
  Object? saveError;
  Object? setError;
  FakePlatform(this.dir);

  RingtonePlatform get platform => RingtonePlatform(
    save: ({required tempPath, required fileName, required title, required mimeType, artist}) async {
      calls.add('save:$fileName:$mimeType:$title:$artist');
      if (saveError != null) throw saveError!;
      final target = '${dir.path}/$fileName';
      await File(tempPath).copy(target);
      return (uri: 'content://media/1', path: target);
    },
    rename: ({uri, path, required fileName, required title}) async {
      calls.add('rename:$fileName');
      return (await File(path!).rename('${dir.path}/$fileName')).path;
    },
    delete: ({uri, path}) async {
      calls.add('delete:$uri');
      final f = File(path ?? '');
      if (f.existsSync()) f.deleteSync();
      return true;
    },
    canWriteSettings: () async => canWrite,
    openWriteSettings: () async => calls.add('openSettings'),
    setDefault: (uri, type) async {
      calls.add('set:$type:$uri');
      if (setError != null) throw setError!;
    },
    supportsSystemRingtones: true,
  );
}

void main() {
  late Directory dir;
  late FakePlatform fake;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rt_');
    fake = FakePlatform(Directory('${dir.path}/saved')..createSync());
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    AudioTrimmer.isAndroidOverride = false;
  });

  tearDown(() async {
    AudioTrimmer.isAndroidOverride = null;
    await dir.delete(recursive: true);
  });

  RingtoneService service({
    Future<void> Function(String url, String path, void Function(int, int) progress)? download,
    String? Function(String id)? downloadedPath,
    Future<bool> Function(String)? validate,
    RingtonePlatform? platform,
  }) =>
      RingtoneService(
        download: download ??
            (url, path, progress) async {
              progress(50, 100);
              await File(path).writeAsBytes(mp3(frames: 400));
              progress(100, 100);
            },
        validate: validate ?? (p) async => File(p).existsSync() && File(p).lengthSync() > 100,
        cacheDir: () async => dir,
        platform: platform ?? fake.platform,
        downloadedPath: downloadedPath,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

  group('rules', () {
    test('default selection: 30 s from the playing position, kept inside the song', () {
      const song = Duration(minutes: 3);
      expect(RingtoneService.defaultSelection(song), (Duration.zero, const Duration(seconds: 30)));
      expect(RingtoneService.defaultSelection(song, position: const Duration(seconds: 40)),
          (const Duration(seconds: 40), const Duration(seconds: 70)));
      expect(RingtoneService.defaultSelection(song, position: const Duration(seconds: 170)),
          (const Duration(seconds: 150), song));
      expect(RingtoneService.defaultSelection(const Duration(seconds: 12)),
          (Duration.zero, const Duration(seconds: 12)), reason: 'short song');
      expect(RingtoneService.defaultSelection(Duration.zero).$2, RingtoneService.defaultLength,
          reason: 'unknown length');
    });

    test('selection validation', () {
      const len = Duration(minutes: 3);
      expect(RingtoneService.validateSelection(Duration.zero, const Duration(seconds: 30), len), isNull);
      expect(RingtoneService.validateSelection(Duration.zero, const Duration(milliseconds: 900), len), contains('1 second'));
      expect(RingtoneService.validateSelection(Duration.zero, const Duration(seconds: 61), len), contains('60'));
      expect(RingtoneService.validateSelection(const Duration(seconds: -1), const Duration(seconds: 5), len), isNotNull);
      expect(RingtoneService.validateSelection(const Duration(seconds: 170), const Duration(seconds: 190), len), contains('after'));
      expect(RingtoneService.validateSelection(Duration.zero, const Duration(seconds: 20), Duration.zero), isNull,
          reason: 'unknown length is allowed');
    });

    test('names are cleaned, limited and made unique', () {
      expect(RingtoneService.sanitizeName('  My:/ring*tone?  '), 'My ring tone');
      expect(RingtoneService.sanitizeName('...'), 'Ringtone');
      expect(RingtoneService.sanitizeName('', fallback: 'Song ringtone'), 'Song ringtone');
      expect(RingtoneService.sanitizeName('x' * 100).length, RingtoneService.maxNameLength);
      expect(RingtoneService.sanitizeName('മലയാളം ടോൺ'), 'മലയാളം ടോൺ', reason: 'unicode kept');
      expect(RingtoneService.uniqueName('Tone', ['tone']), 'Tone (2)');
      expect(RingtoneService.uniqueName('Tone', ['Tone', 'Tone (2)']), 'Tone (3)');
      expect(RingtoneService.uniqueName('New', ['Tone']), 'New');
    });

    test('which songs can become ringtones', () {
      expect(RingtoneService.unavailableReason(localSong()), isNull);
      expect(RingtoneService.unavailableReason(localSong(path: '/a.flac')), contains('.flac'));
      expect(RingtoneService.unavailableReason(onlineSong()), isNull);
      expect(RingtoneService.unavailableReason(onlineSong(download: false)), contains('allow downloads'));
      final radio = Song(
        id: 'jmr_1', title: 'Radio', artists: ['Jamendo'], albums: const [], path: '',
        duration: Duration.zero, source: SongSources.jamendoRadio,
      );
      expect(RingtoneService.unavailableReason(radio), contains('radio'));
    });

    test('mime types', () {
      expect(RingtoneService.mimeFor('mp3'), 'audio/mpeg');
      expect(RingtoneService.mimeFor('wav'), 'audio/wav');
      expect(RingtoneService.mimeFor('m4a'), 'audio/mp4');
    });
  });

  group('prepareSource', () {
    test('local song uses its own file; a missing file is reported', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3());
      expect(await service().prepareSource(localSong(path: f.path)), f.path);
      await expectLater(
        service().prepareSource(localSong(path: '${dir.path}/gone.mp3')),
        throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('missing'))),
      );
    });

    test('Discover song is downloaded automatically with progress, then cached', () async {
      var downloads = 0;
      final progress = <double>[];
      final s = service(download: (url, path, p) async {
        downloads++;
        expect(url, 'https://download/77');
        p(25, 100);
        await File(path).writeAsBytes(mp3(frames: 200));
        p(100, 100);
      });
      final path = await s.prepareSource(onlineSong(), onProgress: progress.add);
      expect(File(path).existsSync(), isTrue);
      expect(path, endsWith('ringtone_src/77.mp3'));
      expect(progress.first, 0);
      expect(progress, containsAllInOrder([0.25, 1.0]));
      expect(File('$path.part').existsSync(), isFalse);

      // Second time: no download.
      final again = await s.prepareSource(onlineSong(), onProgress: progress.add);
      expect(again, path);
      expect(downloads, 1);
    });

    test('a song already downloaded to My Music is reused', () async {
      final f = File('${dir.path}/dl.mp3')..writeAsBytesSync(mp3());
      var downloads = 0;
      final s = service(
        downloadedPath: (id) => id == 'jm_77' ? f.path : null,
        download: (a, b, c) async => downloads++,
      );
      expect(await s.prepareSource(onlineSong()), f.path);
      expect(downloads, 0);
    });

    test('not-allowed downloads and radio fail before any network call', () async {
      var downloads = 0;
      final s = service(download: (a, b, c) async => downloads++);
      await expectLater(s.prepareSource(onlineSong(download: false)), throwsA(isA<RingtoneException>()));
      expect(downloads, 0);
    });

    test('an error page instead of audio is rejected and cleaned up', () async {
      final s = service(
        download: (url, path, p) async => File(path).writeAsStringSync('<html>error</html>'),
        validate: (p) async => false,
      );
      await expectLater(
        s.prepareSource(onlineSong()),
        throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('not available'))),
      );
      expect(Directory('${dir.path}/ringtone_src').listSync(), isEmpty);
    });

    test('offline / server errors become friendly messages', () async {
      final offline = service(download: (url, path, p) async {
        throw DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.connectionError);
      });
      await expectLater(offline.prepareSource(onlineSong()),
          throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('No internet'))));
      final server = service(download: (url, path, p) async {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: url), statusCode: 500),
        );
      });
      await expectLater(server.prepareSource(onlineSong()),
          throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('500'))));
      expect(File('${dir.path}/ringtone_src/77.mp3.part').existsSync(), isFalse);
    });

    test('only the last few downloaded songs are kept', () async {
      final s = service();
      for (var i = 1; i <= RingtoneService.cachedSources + 2; i++) {
        await s.prepareSource(onlineSong(id: i));
        // Make the order deterministic.
        File('${dir.path}/ringtone_src/$i.mp3').setLastModifiedSync(DateTime(2024, 1, 1, 0, i));
      }
      final left = Directory('${dir.path}/ringtone_src').listSync().length;
      expect(left, lessThanOrEqualTo(RingtoneService.cachedSources + 1));
    });
  });

  group('create / rename / delete / set as', () {
    late File source;
    setUp(() => source = File('${dir.path}/song.mp3')..writeAsBytesSync(mp3(frames: 2000)));

    test('creates an MP3 ringtone with the chosen part and metadata', () async {
      final song = localSong(path: source.path);
      final created = await service().create(
        song: song,
        sourcePath: source.path,
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 25),
        name: ' Morning: wake ',
      );
      expect(created.name, 'Morning wake');
      expect(created.path, '${fake.dir.path}/Morning wake.mp3');
      expect(created.uri, 'content://media/1');
      expect(created.startMs, 10000);
      expect(created.duration.inMilliseconds, closeTo(15000, 40));
      expect(created.sourceSongId, song.id);
      expect(created.fromOnline, isFalse);
      expect(fake.calls.single, 'save:Morning wake.mp3:audio/mpeg:Morning wake:Local Artist');
      expect(Mp3Cutter.totalDuration(File(created.path).readAsBytesSync()).inMilliseconds, closeTo(15000, 40));
      expect(Directory('${dir.path}/ringtone_work').listSync(), isEmpty, reason: 'temp file removed');
    });

    test('an invalid selection or unsupported file is refused with a message', () async {
      final s = service();
      await expectLater(
        s.create(song: localSong(path: source.path), sourcePath: source.path,
            start: Duration.zero, end: const Duration(seconds: 90), name: 'x'),
        throwsA(isA<RingtoneException>()),
      );
      await expectLater(
        s.create(song: localSong(path: '/a.ogg'), sourcePath: '/a.ogg',
            start: Duration.zero, end: const Duration(seconds: 5), name: 'x'),
        throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('.ogg'))),
      );
      expect(fake.calls, isEmpty);
    });

    test('a save failure is reported and leaves no temp files', () async {
      fake.saveError = PlatformException(code: 'save_failed', message: 'disk full');
      await expectLater(
        service().create(song: localSong(path: source.path), sourcePath: source.path,
            start: Duration.zero, end: const Duration(seconds: 5), name: 'x'),
        throwsA(isA<RingtoneException>().having((e) => e.message, 'm', contains('disk full'))),
      );
      expect(Directory('${dir.path}/ringtone_work').listSync(), isEmpty);
    });

    test('rename keeps the extension; same name is a no-op', () async {
      final s = service();
      final created = await s.create(song: localSong(path: source.path), sourcePath: source.path,
          start: Duration.zero, end: const Duration(seconds: 5), name: 'Old');
      final renamed = await s.rename(created, 'New / name');
      expect(renamed.name, 'New name');
      expect(renamed.path, '${fake.dir.path}/New name.mp3');
      expect(File(renamed.path).existsSync(), isTrue);
      expect(identical(await s.rename(renamed, 'New name'), renamed), isTrue);
      expect(await s.exists(renamed), isTrue);
      await s.delete(renamed);
      expect(await s.exists(renamed), isFalse);
    });

    test('set as ringtone: permission, success, failure, unsupported', () async {
      final s = service();
      final r = item('a');
      expect(await s.setAs(r, RingtoneUse.ringtone), RingtoneSetResult.needsPermission);
      fake.canWrite = true;
      expect(await s.setAs(r, RingtoneUse.alarm), RingtoneSetResult.done);
      expect(fake.calls.last, 'set:alarm:content://media/a');
      fake.setError = PlatformException(code: 'no_permission');
      expect(await s.setAs(r, RingtoneUse.ringtone), RingtoneSetResult.needsPermission);
      fake.setError = PlatformException(code: 'set_failed');
      expect(await s.setAs(r, RingtoneUse.notification), RingtoneSetResult.failed);

      final files = service(platform: RingtonePlatform.files(() async => dir));
      expect(await files.setAs(r, RingtoneUse.ringtone), RingtoneSetResult.unsupported);
    });

    test('files platform (non-Android) saves into Ringtones/ without clobbering', () async {
      final s = service(platform: RingtonePlatform.files(() async => dir));
      final a = await s.create(song: localSong(path: source.path), sourcePath: source.path,
          start: Duration.zero, end: const Duration(seconds: 2), name: 'Same');
      final b = await s.create(song: localSong(path: source.path), sourcePath: source.path,
          start: Duration.zero, end: const Duration(seconds: 2), name: 'Same');
      expect(a.path, '${dir.path}/Ringtones/Same.mp3');
      expect(b.path, '${dir.path}/Ringtones/Same (1).mp3');
      expect(a.uri, isNull);
    });
  });

  group('RingtoneLibraryBloc', () {
    test('add (newest first), update, mark default, remove', () async {
      final bloc = RingtoneLibraryBloc();
      bloc.add(RingtoneLibraryEvent.added(item('a')));
      bloc.add(RingtoneLibraryEvent.added(item('b')));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.items.map((i) => i.id), ['b', 'a']);
      bloc.add(RingtoneLibraryEvent.added(item('a', name: 'again')));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.items.map((i) => i.id), ['a', 'b'], reason: 'no duplicates');

      bloc.add(RingtoneLibraryEvent.updated(item('b', name: 'Renamed')));
      bloc.add(const RingtoneLibraryEvent.markedDefault(id: 'b', use: RingtoneUse.ringtone));
      bloc.add(const RingtoneLibraryEvent.markedDefault(id: 'a', use: RingtoneUse.alarm));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.byId('b')!.name, 'Renamed');
      expect(bloc.state.usesOf('b'), [RingtoneUse.ringtone]);
      expect(bloc.state.names, containsAll(['again', 'Renamed']));

      bloc.add(const RingtoneLibraryEvent.removed('b'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.count, 1);
      expect(bloc.state.defaults, {'alarm': 'a'});
      await bloc.close();
    });

    test('verify drops ringtones deleted outside the app', () async {
      final bloc = RingtoneLibraryBloc(exists: (i) async => i.id != 'gone');
      bloc.add(RingtoneLibraryEvent.added(item('gone')));
      bloc.add(RingtoneLibraryEvent.added(item('kept')));
      bloc.add(const RingtoneLibraryEvent.markedDefault(id: 'gone', use: RingtoneUse.ringtone));
      bloc.add(const RingtoneLibraryEvent.verify());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state.items.map((i) => i.id), ['kept']);
      expect(bloc.state.defaults, isEmpty);
      await bloc.close();
    });

    test('persists and restores; corrupt data is ignored', () async {
      final bloc = RingtoneLibraryBloc();
      final state = RingtoneLibraryState(items: [item('a', name: 'Ring')], defaults: const {'ringtone': 'a'});
      final json = jsonDecode(jsonEncode(bloc.toJson(state))) as Map<String, dynamic>;
      final restored = bloc.fromJson(json)!;
      expect(restored.items.single.name, 'Ring');
      expect(restored.items.single.endMs, 31000);
      expect(restored.items.single.uri, 'content://media/a');
      expect(restored.defaults, {'ringtone': 'a'});
      expect(bloc.fromJson({'items': [{'bad': 1}]}), isNull);
      expect(bloc.fromJson({}), const RingtoneLibraryState());
      await bloc.close();
    });
  });

  group('RingtoneEditorCubit', () {
    late RingtoneLibraryBloc library;
    setUp(() => library = RingtoneLibraryBloc());
    tearDown(() => library.close());

    RingtoneEditorCubit cubit(Song song, {RingtoneService? s, Duration? position}) =>
        RingtoneEditorCubit(song: song, service: s ?? service(), library: library, initialPosition: position);

    test('local song: ready with 30 s from where it was playing', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3());
      final c = cubit(localSong(path: f.path), position: const Duration(seconds: 60));
      await c.prepare();
      expect(c.state.phase, RingtoneEditorPhase.ready);
      expect(c.state.start, const Duration(seconds: 60));
      expect(c.state.end, const Duration(seconds: 90));
      expect(c.state.canSave, isTrue);
      expect(c.state.progress, isNull);
      await c.close();
    });

    test('Discover song: shows download progress, then ready', () async {
      final c = cubit(onlineSong());
      final progress = <double?>[];
      final sub = c.stream.listen((s) => progress.add(s.progress));
      await c.prepare();
      await sub.cancel();
      expect(progress.first, 0);
      expect(progress, contains(0.5));
      expect(c.state.phase, RingtoneEditorPhase.ready);
      expect(c.state.songLength, const Duration(seconds: 200));
      await c.close();
    });

    test('unavailable songs and failed downloads show an error (retry works)', () async {
      final radio = cubit(onlineSong(download: false));
      await radio.prepare();
      expect(radio.state.phase, RingtoneEditorPhase.error);
      expect(radio.state.error, contains('allow downloads'));
      await radio.close();

      var fail = true;
      final flaky = cubit(onlineSong(), s: service(download: (u, p, cb) async {
        if (fail) throw const SocketException('offline');
        await File(p).writeAsBytes(mp3());
      }));
      await flaky.prepare();
      expect(flaky.state.phase, RingtoneEditorPhase.error);
      expect(flaky.state.error, contains('No internet'));
      fail = false;
      await flaky.prepare();
      expect(flaky.state.phase, RingtoneEditorPhase.ready);
      await flaky.close();
    });

    test('trim handles keep the range valid (min 1 s, max 60 s, inside the song)', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3());
      final c = cubit(localSong(path: f.path)); // 3 min
      await c.prepare();
      c.setEnd(const Duration(seconds: 200));
      expect(c.state.end, const Duration(minutes: 3), reason: 'clamped to the song');
      expect(c.state.start, const Duration(seconds: 120), reason: 'start follows (max 60 s)');
      c.setStart(const Duration(seconds: 179, milliseconds: 800));
      expect(c.state.start, const Duration(seconds: 179));
      expect(c.state.length, RingtoneService.minLength);
      c.setStart(Duration.zero);
      expect(c.state.end, const Duration(seconds: 60));
      c.nudgeEnd(1);
      expect(c.state.end, const Duration(milliseconds: 60500));
      expect(c.state.start, const Duration(milliseconds: 500));
      c.nudgeStart(-1);
      c.nudgeStart(-1);
      expect(c.state.start, Duration.zero);
      c.setEnd(Duration.zero);
      expect(c.state.end, RingtoneService.minLength);
      expect(c.state.selectionError, isNull);
      await c.close();
    });

    test('real length from the player replaces a missing duration', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3());
      final c = cubit(localSong(path: f.path, duration: Duration.zero), position: const Duration(seconds: 50));
      await c.prepare();
      c.lengthDetected(const Duration(seconds: 70));
      expect(c.state.songLength, const Duration(seconds: 70));
      expect((c.state.start, c.state.end), (const Duration(seconds: 40), const Duration(seconds: 70)));
      c.lengthDetected(const Duration(seconds: 55));
      expect(c.state.end, const Duration(seconds: 55));
      await c.close();
    });

    test('save adds to My Ringtones with a unique name', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3(frames: 3000));
      library.add(RingtoneLibraryEvent.added(item('old', name: 'Local Song ringtone')));
      await Future<void>.delayed(Duration.zero);
      final c = cubit(localSong(path: f.path));
      await c.prepare();
      c.setEnd(const Duration(seconds: 5));
      final saved = await c.save('');
      await Future<void>.delayed(Duration.zero);
      expect(saved!.name, 'Local Song ringtone (2)');
      expect(c.state.phase, RingtoneEditorPhase.saved);
      expect(library.state.items.first.id, saved.id);
      expect(await c.save('again'), isNull, reason: 'nothing to save after saving');
      await c.close();
    });

    test('a failed save keeps the editor open with the error', () async {
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(mp3(frames: 3000));
      fake.saveError = PlatformException(code: 'x', message: 'no space');
      final c = cubit(localSong(path: f.path));
      await c.prepare();
      expect(await c.save('Tone'), isNull);
      expect(c.state.phase, RingtoneEditorPhase.ready);
      expect(c.state.saveError, contains('no space'));
      expect(library.state.items, isEmpty);
      c.nudgeStart(1);
      expect(c.state.saveError, isNull, reason: 'editing clears the error');
      await c.close();
    });
  });
}
