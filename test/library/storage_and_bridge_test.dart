import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rhythmflow/utils/models/album/album_model.dart';
import 'package:rhythmflow/utils/models/artist/artist_model.dart';
import 'package:rhythmflow/utils/models/song_features/song_features.dart';
import 'package:rhythmflow/utils/services/library_storage.dart';
import 'package:rhythmflow/utils/services/media_store_bridge.dart';

import 'library_test_utils.dart';

LibrarySnapshot _snapshot(int songCount) {
  final songs = [
    for (var i = 0; i < songCount; i++)
      testSong(id: 's$i', title: 'Song $i').copyWith(
        fileModifiedAt: DateTime(2024, 1, 1, 12, 0, 0, 123),
        fileSize: 1000 + i,
        playCount: i,
      ),
  ];
  return LibrarySnapshot(
    songs: songs,
    albums: [
      Album(
        id: 'album_1',
        name: 'Album',
        songIds: songs.map((s) => s.id).toList(),
        createdAt: DateTime(2024),
      ),
    ],
    artists: [
      Artist(
        id: 'artist_1',
        name: 'Artist',
        songIds: songs.map((s) => s.id).toList(),
        createdAt: DateTime(2024),
      ),
    ],
    skippedFiles: const {'/m/beep.mp3': '10:20|filtered'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryStorage', () {
    late InMemoryLibraryStoreBackend backend;

    setUp(() {
      backend = InMemoryLibraryStoreBackend();
      LibraryStorage.useBackend(backend);
    });

    tearDown(() {
      LibraryStorage.useBackend(null);
      LibraryStorage.saveDebounce = const Duration(milliseconds: 1500);
    });

    test('not ready without a backend; load returns null', () {
      LibraryStorage.useBackend(null);
      expect(LibraryStorage.isReady, isFalse);
      expect(LibraryStorage.load(), isNull);
    });

    test('saveNow / load round trip keeps every field', () async {
      final snapshot = _snapshot(3);
      await LibraryStorage.saveNow(snapshot);
      expect(LibraryStorage.hasData, isTrue);

      final loaded = LibraryStorage.load()!;
      expect(loaded.songs, equals(snapshot.songs));
      expect(loaded.songs.first.fileModifiedAt, DateTime(2024, 1, 1, 12, 0, 0, 123));
      expect(loaded.albums, equals(snapshot.albums));
      expect(loaded.artists, equals(snapshot.artists));
      expect(loaded.skippedFiles, snapshot.skippedFiles);
    });

    test('songs with extracted features survive the round trip', () async {
      final song = testSong(id: 'f').copyWith(
        features: SongFeatures(
          tempo: 'Fast',
          beat: 'Strong',
          energy: 'High',
          instruments: const ['Guitar'],
          mood: 'Happy',
          yamnetInstruments: const ['Guitar'],
          hasVocals: true,
          estimatedGenre: 'Rock',
          yamnetEnergy: 0.8,
          moodTags: const ['upbeat'],
          tempoBpm: 128,
          beatStrength: 0.7,
          signalEnergy: 0.6,
          brightness: 0.5,
          danceability: 0.9,
          overallEnergy: 0.8,
          intensity: 0.7,
          spectralCentroid: 2000,
          spectralRolloff: 4000,
          zeroCrossingRate: 0.1,
          spectralFlux: 0.2,
          complexity: 0.3,
          valence: 0.6,
          arousal: 0.7,
          confidence: 0.95,
          analyzedAt: DateTime(2024, 5, 1),
          modelVersion: '1.0.0',
        ),
      );
      await LibraryStorage.saveNow(
        LibrarySnapshot(songs: [song], albums: const [], artists: const []),
      );
      final loaded = LibraryStorage.load()!.songs.single;
      expect(loaded.features?.tempoBpm, 128);
      expect(loaded.features?.instruments, ['Guitar']);
    });

    test('scheduleSave is debounced: many changes -> one write batch', () {
      fakeAsync((async) {
        LibraryStorage.saveDebounce = const Duration(seconds: 1);
        for (var i = 1; i <= 20; i++) {
          LibraryStorage.scheduleSave(_snapshot(i));
          async.elapse(const Duration(milliseconds: 100));
        }
        expect(backend.writeCount, 0, reason: 'nothing written while busy');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(backend.writeCount, 5, reason: 'one snapshot = 5 keys');
        expect(LibraryStorage.load()!.songs, hasLength(20));
      });
    });

    test('flush writes the pending snapshot immediately', () async {
      LibraryStorage.saveDebounce = const Duration(hours: 1);
      LibraryStorage.scheduleSave(_snapshot(2));
      expect(backend.writeCount, 0);
      await LibraryStorage.flush();
      expect(LibraryStorage.load()!.songs, hasLength(2));
      await LibraryStorage.flush(); // nothing pending -> no extra writes
      expect(backend.writeCount, 5);
    });

    test('corrupted data is ignored instead of crashing', () async {
      await backend.write('songs', '{not json');
      expect(LibraryStorage.load(), isNull);
    });

    test('clear removes the stored library', () async {
      await LibraryStorage.saveNow(_snapshot(1));
      await LibraryStorage.clear();
      expect(LibraryStorage.hasData, isFalse);
    });

    test('works with a real Hive box on disk', () async {
      final dir = await Directory.systemTemp.createTemp('hive_lib_');
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
      Hive.init(dir.path);
      LibraryStorage.useBackend(null);
      await LibraryStorage.init();
      expect(LibraryStorage.isReady, isTrue);

      await LibraryStorage.saveNow(_snapshot(4));
      await Hive.close();

      // Re-open like after an app restart.
      LibraryStorage.useBackend(null);
      Hive.init(dir.path);
      await LibraryStorage.init();
      final loaded = LibraryStorage.load()!;
      expect(loaded.songs, hasLength(4));
      expect(loaded.songs[2].playCount, 2);
    });
  });

  group('MediaStoreBridge', () {
    final calls = <MethodCall>[];

    setUp(() {
      MediaStoreBridge.resetForTesting();
      calls.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MediaStoreBridge.channel, null);
      MediaStoreBridge.resetForTesting();
    });

    void mockNative(Object? Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MediaStoreBridge.channel, (call) async {
            calls.add(call);
            return handler(call);
          });
    }

    test('change notifications are debounced into one callback', () {
      fakeAsync((async) {
        MediaStoreBridge.changeDebounce = const Duration(seconds: 3);
        var refreshes = 0;
        MediaStoreBridge.isAndroidOverride = false; // do not hit the channel
        MediaStoreBridge.startObserving(() => refreshes++);

        for (var i = 0; i < 10; i++) {
          MediaStoreBridge.handleMethodCall(
            const MethodCall('onMediaStoreChanged'),
          );
          async.elapse(const Duration(milliseconds: 200));
        }
        expect(refreshes, 0);
        async.elapse(const Duration(seconds: 3));
        expect(refreshes, 1);
      });
    });

    test('startObserving asks the native side on Android', () async {
      mockNative((_) => true);
      MediaStoreBridge.isAndroidOverride = true;
      await MediaStoreBridge.startObserving(() {});
      expect(calls.map((c) => c.method), ['startObserving']);
      await MediaStoreBridge.stopObserving();
      expect(calls.map((c) => c.method), ['startObserving', 'stopObserving']);
    });

    test('deleteAudioFile uses the native MediaStore delete on Android', () async {
      mockNative((call) => call.method == 'deleteAudioFile');
      MediaStoreBridge.isAndroidOverride = true;
      expect(await MediaStoreBridge.deleteAudioFile('/m/a.mp3'), isTrue);
      expect(calls.single.arguments, {'path': '/m/a.mp3'});
    });

    test('deleteAudioFile reports a cancelled system dialog as false', () async {
      mockNative((_) => false);
      MediaStoreBridge.isAndroidOverride = true;
      expect(await MediaStoreBridge.deleteAudioFile('/m/a.mp3'), isFalse);
    });

    test('deleteAudioFile surfaces native errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MediaStoreBridge.channel, (call) async {
            throw PlatformException(code: 'permission_denied');
          });
      MediaStoreBridge.isAndroidOverride = true;
      expect(
        () => MediaStoreBridge.deleteAudioFile('/m/a.mp3'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('deleteAudioFile deletes directly on other platforms', () async {
      final dir = await Directory.systemTemp.createTemp('del_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/a.mp3')..writeAsBytesSync([1]);
      MediaStoreBridge.isAndroidOverride = false;
      expect(await MediaStoreBridge.deleteAudioFile(file.path), isTrue);
      expect(file.existsSync(), isFalse);
    });
  });
}
