import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Plays a part of a file, separately from the main music player (so the
/// queue, notification and history are not touched).
abstract class RingtonePreview {
  /// Replaced in tests.
  static RingtonePreview Function() factory = JustAudioRingtonePreview.new;

  Stream<bool> get playingStream;

  /// Position inside the played range.
  Stream<Duration> get positionStream;

  /// Loads a file path or `content://` uri; returns its length when known.
  Future<Duration?> load(String source);

  /// Plays [start]..[end] (the whole file when null) once.
  Future<void> play({Duration? start, Duration? end});
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioRingtonePreview implements RingtonePreview {
  final AudioPlayer _player = AudioPlayer(handleInterruptions: true);
  final StreamController<bool> _playing = StreamController.broadcast();
  StreamSubscription<PlayerState>? _sub;
  String? _loaded;

  JustAudioRingtonePreview() {
    _sub = _player.playerStateStream.listen((s) {
      final done = s.processingState == ProcessingState.completed;
      if (done) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      _playing.add(s.playing && !done);
    });
  }

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<Duration?> load(String source) async {
    if (_loaded == source) return _player.duration;
    _loaded = source;
    final uri = source.startsWith('content://') ? Uri.parse(source) : Uri.file(source);
    return _player.setAudioSource(AudioSource.uri(uri));
  }

  @override
  Future<void> play({Duration? start, Duration? end}) async {
    await _player.setClip(start: start, end: end);
    await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _playing.close();
    await _player.dispose();
  }
}
