import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/online/bloc/online_library_bloc.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/jamendo/download_service.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/media_store_bridge.dart';

class MockStorage extends Mock implements Storage {}

Song downloadable({String id = '1', bool allowed = true}) => JamendoMapper.track({
  'id': id,
  'name': 'Song/With:Bad*Chars?',
  'artist_name': 'The Artist',
  'album_name': 'An Album',
  'duration': 120,
  'audio': 'https://stream/$id',
  'audiodownload': 'https://download/$id',
  'audiodownload_allowed': allowed,
  'image': 'https://img/$id',
  'license_ccurl': 'http://creativecommons.org/licenses/by/3.0/',
});

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late OnlineLibraryBloc library;
  final saved = <String>[];
  final tagged = <String>[];

  setUp(() async {
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    temp = await Directory.systemTemp.createTemp('dl_');
    library = OnlineLibraryBloc();
    saved.clear();
    tagged.clear();
  });

  tearDown(() async {
    await library.close();
    await temp.delete(recursive: true);
  });

  DownloadService service({
    FileDownloader? download,
    AudioSaver? save,
    VoidCallback? onSaved,
  }) => DownloadService(
    library: library,
    tempDir: () async => temp,
    download: download ??
        (url, path, progress) async {
          for (var i = 1; i <= 10; i++) {
            progress(i * 100, 1000);
          }
          await File(path).writeAsBytes(List.filled(1000, 1));
        },
    fetchCover: (_) async => Uint8List.fromList([1, 2, 3]),
    writeTags: (path, song, cover) async => tagged.add('${song.title}|${cover?.length}'),
    save: save ??
        (tempPath, fileName, song) async {
          final target = '${temp.path}/$fileName';
          await File(tempPath).copy(target);
          saved.add(target);
          return target;
        },
    onSaved: onSaved,
  );

  test('file names are safe and readable', () {
    expect(DownloadService.fileNameFor(downloadable()), 'The Artist - Song With Bad Chars.mp3');
    final noArtist = downloadable().copyWith(artists: const []);
    expect(DownloadService.fileNameFor(noArtist), 'Song With Bad Chars.mp3');
  });

  test('downloads, tags, saves, reports progress and refreshes My Music', () async {
    var refreshed = 0;
    final phases = <DownloadPhase>[];
    final sub = library.stream.listen((s) {
      final d = s.downloads['jm_1'];
      if (d != null && (phases.isEmpty || phases.last != d.phase)) phases.add(d.phase);
    });
    final path = await service(onSaved: () => refreshed++).download(downloadable());
    await settle();

    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(tagged.single, 'Song/With:Bad*Chars?|3');
    expect(phases, [DownloadPhase.queued, DownloadPhase.downloading, DownloadPhase.completed]);
    final done = library.state.downloads['jm_1']!;
    expect(done.localPath, path);
    expect(done.progress, 1);
    expect(refreshed, 1);
    expect(temp.listSync().whereType<File>().where((f) => f.path.contains('rf_dl_')), isEmpty,
        reason: 'temporary file is removed');
    await sub.cancel();
  });

  test('songs the artist does not allow are never downloaded', () async {
    var called = false;
    final path = await service(
      download: (_, _, _) async => called = true,
    ).download(downloadable(allowed: false));
    await settle();
    expect(path, isNull);
    expect(called, isFalse);
    expect(library.state.downloads['jm_1']!.phase, DownloadPhase.failed);
  });

  test('network failure is reported and cleaned up', () async {
    final path = await service(
      download: (_, path, _) async {
        await File(path).writeAsString('partial');
        throw const SocketException('offline');
      },
    ).download(downloadable());
    await settle();
    expect(path, isNull);
    final d = library.state.downloads['jm_1']!;
    expect(d.phase, DownloadPhase.failed);
    expect(saved, isEmpty);
    expect(temp.listSync().whereType<File>(), isEmpty);
  });

  test('a second tap while downloading does not start another download', () async {
    final gate = Completer<void>();
    var downloads = 0;
    final s = service(
      download: (_, path, _) async {
        downloads++;
        await gate.future;
        await File(path).writeAsBytes([1]);
      },
    );
    final first = s.download(downloadable());
    await settle();
    expect(s.isDownloading('jm_1'), isTrue);
    expect(await s.download(downloadable()), isNull);
    gate.complete();
    await first;
    expect(downloads, 1);
    expect(s.isDownloading('jm_1'), isFalse);
  });

  test('tag writing failure still saves the song', () async {
    final s = DownloadService(
      library: library,
      tempDir: () async => temp,
      download: (_, path, _) async => File(path).writeAsBytes([1, 2]),
      fetchCover: (_) async => null,
      writeTags: (_, _, _) async => throw Exception('unsupported'),
      save: (tempPath, name, _) async {
        final target = '${temp.path}/$name';
        await File(tempPath).copy(target);
        return target;
      },
    );
    expect(await s.download(downloadable()), isNotNull);
  });

  test('MediaStoreBridge.saveAudioToMusic calls the native side', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MediaStoreBridge.channel, (call) async {
          calls.add(call);
          return '/storage/emulated/0/Music/RhythmFlow/a.mp3';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MediaStoreBridge.channel, null),
    );
    final path = await MediaStoreBridge.saveAudioToMusic(
      tempPath: '/tmp/x.mp3',
      fileName: 'a.mp3',
      title: 'A',
    );
    expect(path, endsWith('/Music/RhythmFlow/a.mp3'));
    expect(calls.single.method, 'saveAudioToMusic');
    expect((calls.single.arguments as Map)['fileName'], 'a.mp3');
  });
}
