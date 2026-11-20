// Lock screen / notification session: the RhythmFlowAudioHandler that
// audio_service drives, and AudioService.playSong / resume on top of it.
//
// Regression tests for:
//  * notification vanishing after one song failed to load (idle -> audio_service
//    stops the foreground service; Android 12+ can't restart it from the
//    background),
//  * lock-screen pause restarting the song (awaited just_audio play()),
//  * play counts credited to the wrong song,
//  * swiping the app away disposing the player under a live notification.
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/audio_handler.dart';
import 'package:rhythmflow/utils/services/audio_service.dart' as rf;
import 'package:rhythmflow/utils/services/play_count_tracking_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeAudioSource extends Fake implements AudioSource {}

/// A just_audio player double with real streams and just_audio's play()
/// semantics: the future completes only when playback pauses or stops.
class PlayerRig {
  final player = MockAudioPlayer();
  final events = StreamController<PlaybackEvent>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final states = StreamController<PlayerState>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  bool playing = false;
  ProcessingState processing = ProcessingState.idle;
  Completer<void>? playCall;
  int playCalls = 0, pauseCalls = 0, stopCalls = 0, disposeCalls = 0;
  Object? loadError;

  PlayerRig() {
    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    when(() => player.durationStream).thenAnswer((_) => durations.stream);
    when(() => player.playerStateStream).thenAnswer((_) => states.stream);
    when(() => player.positionStream).thenAnswer((_) => positions.stream);
    when(() => player.playingStream).thenAnswer((_) => const Stream.empty());
    when(() => player.playing).thenAnswer((_) => playing);
    when(() => player.processingState).thenAnswer((_) => processing);
    when(() => player.playerState).thenAnswer((_) => PlayerState(playing, processing));
    when(() => player.position).thenReturn(Duration.zero);
    when(() => player.bufferedPosition).thenReturn(Duration.zero);
    when(() => player.duration).thenReturn(const Duration(minutes: 3));
    when(() => player.speed).thenReturn(1.0);
    when(() => player.play()).thenAnswer((_) {
      playCalls++;
      playing = true;
      processing = ProcessingState.ready;
      playCall = Completer<void>();
      return playCall!.future; // completes on pause/stop, like just_audio
    });
    when(() => player.pause()).thenAnswer((_) async {
      pauseCalls++;
      playing = false;
      if (playCall?.isCompleted == false) playCall!.complete();
    });
    when(() => player.stop()).thenAnswer((_) async {
      stopCalls++;
      playing = false;
      processing = ProcessingState.idle;
      if (playCall?.isCompleted == false) playCall!.complete();
    });
    when(() => player.seek(any())).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async => disposeCalls++);
    when(() => player.setAudioSource(any())).thenAnswer((_) async {
      if (loadError != null) {
        processing = ProcessingState.idle;
        throw loadError!;
      }
      processing = ProcessingState.ready;
      return const Duration(minutes: 3);
    });
    when(() => player.audioSource).thenReturn(null);
  }

  void emit() => events.add(PlaybackEvent(processingState: processing));
}

Future<void> tick() => Future<void>.delayed(Duration.zero);

MediaItem item(String id, {Duration? duration}) =>
    MediaItem(id: id, title: 'Song $id', duration: duration);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(Duration.zero);
  });

  late PlayerRig rig;
  late RhythmFlowAudioHandler handler;
  setUp(() {
    rig = PlayerRig();
    handler = RhythmFlowAudioHandler(player: rig.player);
  });

  group('processing state mapping', () {
    test('idle only after an explicit stop or before anything was loaded', () {
      AudioProcessingState map(ProcessingState s, {bool stopped = false, bool media = true}) =>
          RhythmFlowAudioHandler.mapProcessingState(s, stopped: stopped, hasMediaItem: media);
      expect(map(ProcessingState.idle, stopped: true), AudioProcessingState.idle);
      expect(map(ProcessingState.idle, media: false), AudioProcessingState.idle);
      expect(map(ProcessingState.idle), AudioProcessingState.buffering,
          reason: 'a song failed to load: keep the session and notification');
      expect(map(ProcessingState.loading), AudioProcessingState.loading);
      expect(map(ProcessingState.buffering), AudioProcessingState.buffering);
      expect(map(ProcessingState.ready), AudioProcessingState.ready);
      expect(map(ProcessingState.completed), AudioProcessingState.completed);
    });

    test('a failed song never reports idle while a song is current', () async {
      await handler.updateMediaItem(item('1'));
      rig.playing = true;
      rig.processing = ProcessingState.idle; // load error
      rig.emit();
      await tick();
      expect(handler.playbackState.value.processingState, isNot(AudioProcessingState.idle));
      expect(handler.playbackState.value.playing, isTrue);
    });

    test('player errors keep the stream alive and the session up', () async {
      await handler.updateMediaItem(item('1'));
      rig.events.addError(PlayerException(404, 'Not found', null));
      await tick();
      expect(handler.playbackState.value.processingState, isNot(AudioProcessingState.idle));
      rig.processing = ProcessingState.ready;
      rig.emit();
      await tick();
      expect(handler.playbackState.value.processingState, AudioProcessingState.ready);
    });

    test('explicit stop reports idle (notification removed) and a new song starts over', () async {
      await handler.updateMediaItem(item('1'));
      await handler.stop();
      expect(handler.isStopped, isTrue);
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
      await handler.updateMediaItem(item('2'));
      expect(handler.isStopped, isFalse);
    });
  });

  group('lock screen / notification buttons', () {
    test('play returns at once and tells the app exactly once', () async {
      var onPlay = 0, onPause = 0;
      handler.setPlayPauseCallbacks(onPlay: () => onPlay++, onPause: () => onPause++);
      await handler.play().timeout(const Duration(seconds: 1));
      expect(rig.playCalls, 1);
      expect(onPlay, 1);

      // Pause from the lock screen: the old code fired onPlay here (its
      // awaited play() completed) and the app resumed the song.
      await handler.pause();
      await tick();
      expect(onPlay, 1, reason: 'no late "play" after pausing');
      expect(onPause, 1);
      expect(rig.playing, isFalse);
    });

    test('play / pause controls follow the player; compact view has 3 buttons', () async {
      await handler.updateMediaItem(item('1'));
      expect(handler.playbackState.value.controls[1].action, MediaAction.play);
      rig.playing = true;
      rig.emit();
      await tick();
      final state = handler.playbackState.value;
      expect(state.controls[1].action, MediaAction.pause);
      expect(state.controls.first.action, MediaAction.skipToPrevious);
      expect(state.controls[2].action, MediaAction.skipToNext);
      expect(state.androidCompactActionIndices, [0, 1, 2]);
      expect(state.systemActions, containsAll([MediaAction.seek, MediaAction.custom]));
    });

    test('skip, shuffle and repeat buttons reach the app', () async {
      final calls = <String>[];
      handler.setSkipCallbacks(onNext: () => calls.add('next'), onPrevious: () => calls.add('prev'));
      handler.setShuffleRepeatCallbacks(onShuffle: () => calls.add('shuffle'), onRepeat: () => calls.add('repeat'));
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.customAction('Shuffle');
      await handler.customAction(RhythmFlowAudioHandler.repeatActionId);
      await handler.customAction('unknown');
      expect(calls, ['next', 'prev', 'shuffle', 'repeat']);
    });

    test('shuffle / repeat icons and labels follow the app state', () async {
      String icon(int i) => handler.playbackState.value.controls[i].androidIcon;
      await handler.updateMediaItem(item('1'));
      expect(icon(3), 'drawable/ic_shuffle_off');
      expect(icon(4), 'drawable/ic_repeat_off');
      handler.updateShuffleState(true);
      expect(icon(3), 'drawable/ic_shuffle');
      handler.updateAiShuffleState(true);
      expect(icon(3), 'drawable/ic_shuffle_ai');
      expect(handler.playbackState.value.controls[3].label, 'AI Shuffle');
      handler.updateRepeatState(1);
      expect(icon(4), 'drawable/ic_repeat_one');
      handler.updateRepeatState(2);
      expect(icon(4), 'drawable/ic_repeat_all');
    });

    test('seek goes to the player', () async {
      await handler.seek(const Duration(seconds: 42));
      verify(() => rig.player.seek(const Duration(seconds: 42))).called(1);
    });
  });

  group('media item', () {
    test('missing duration is filled from the player (lock-screen seek bar)', () async {
      await handler.updateMediaItem(item('1'));
      rig.durations.add(const Duration(seconds: 200));
      await tick();
      expect(handler.mediaItem.value!.duration, const Duration(seconds: 200));
    });

    test('a close-enough duration is left alone; a wrong one is corrected', () async {
      await handler.updateMediaItem(item('1', duration: const Duration(seconds: 200)));
      rig.durations.add(const Duration(milliseconds: 200900));
      await tick();
      expect(handler.mediaItem.value!.duration, const Duration(seconds: 200));
      rig.durations.add(const Duration(seconds: 260));
      await tick();
      expect(handler.mediaItem.value!.duration, const Duration(seconds: 260));
      rig.durations.add(null);
      await tick();
      expect(handler.mediaItem.value!.duration, const Duration(seconds: 260));
    });

    test('clearMediaItem removes it', () async {
      await handler.updateMediaItem(item('1'));
      await handler.clearMediaItem();
      expect(handler.mediaItem.value, isNull);
    });
  });

  group('app swiped away from Recents', () {
    test('while playing: keeps playing, player not disposed', () async {
      await handler.updateMediaItem(item('1'));
      await handler.play();
      await handler.onTaskRemoved();
      expect(rig.disposeCalls, 0);
      expect(rig.stopCalls, 0);
      expect(rig.playing, isTrue);
    });

    test('while paused: ends the session so no dead notification stays', () async {
      await handler.updateMediaItem(item('1'));
      await handler.onTaskRemoved();
      expect(rig.stopCalls, 1);
      expect(rig.disposeCalls, 0);
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
    });
  });

  group('AudioService on top of the handler', () {
    late rf.AudioService service;
    final songs = <String>[];

    Song local(String id) => Song(
      id: id, title: 'Song $id', artists: ['A'], albums: ['B'],
      path: '/definitely/missing/$id.mp3', duration: const Duration(minutes: 3),
    );
    Song online(String id) => Song(
      id: 'jm_$id', title: 'Online $id', artists: ['A'], albums: const [], path: '',
      duration: const Duration(minutes: 3), source: SongSources.jamendo, streamUrl: 'https://s/$id',
    );

    setUp(() {
      service = rf.AudioService()..setAudioHandler(handler);
      songs.clear();
      rf.AudioService.remoteUrlResolver = null;
      PlayCountTrackingService.stopTracking();
      PlayCountTrackingService.onUpdatePlayCount = songs.add;
    });
    tearDown(() async {
      PlayCountTrackingService.stopTracking();
      PlayCountTrackingService.onUpdatePlayCount = null;
      await service.dispose();
    });

    test('playSong returns while the song plays; play count goes to that song', () async {
      await service.playSong(online('1')).timeout(const Duration(seconds: 1));
      expect(rig.playCalls, 1);
      expect(PlayCountTrackingService.trackedSongId, 'jm_1', reason: 'tracking starts with playback');
      expect(handler.mediaItem.value!.id, 'jm_1');
      expect(handler.isStopped, isFalse);

      PlayCountTrackingService.updatePosition(const Duration(seconds: 80)); // 44 %
      expect(songs, ['jm_1']);

      await service.playSong(online('2')).timeout(const Duration(seconds: 1));
      PlayCountTrackingService.updatePosition(const Duration(seconds: 30)); // 17 %
      expect(songs, ['jm_1'], reason: 'song 2 not credited yet, song 1 not credited twice');
      PlayCountTrackingService.updatePosition(const Duration(seconds: 100));
      expect(songs, ['jm_1', 'jm_2']);
    });

    test('a song that fails to load is reported and the session survives', () async {
      Song? invalid;
      service.setInvalidSongCallback((s, _, _) => invalid = s);
      await service.playSong(online('1'));
      rig.loadError = PlayerException(404, 'gone', null);
      await service.playSong(online('2'));
      expect(invalid?.id, 'jm_2');
      rig.emit();
      await tick();
      expect(handler.playbackState.value.processingState, isNot(AudioProcessingState.idle),
          reason: 'notification must stay for the next song');
    });

    test('a missing local file is skipped without touching the player', () async {
      Song? invalid;
      service.setInvalidSongCallback((s, _, _) => invalid = s);
      await service.playSong(local('x'));
      expect(invalid?.id, 'x');
      expect(rig.playCalls, 0);
    });

    test('resume returns at once and refreshes the notification item', () async {
      await service.playSong(online('1'));
      await service.pause();
      await handler.clearMediaItem();
      await service.resume().timeout(const Duration(seconds: 1));
      expect(rig.playCalls, 2);
      expect(handler.mediaItem.value?.id, 'jm_1');
    });

    test('stop ends the session: idle, item cleared, tracking stopped', () async {
      await service.playSong(online('1'));
      await service.stop();
      expect(handler.mediaItem.value, isNull);
      expect(PlayCountTrackingService.trackedSongId, isNull);
      rig.emit();
      await tick();
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
    });
  });
}
