import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

import '../logger/logger.dart';

/// Native Android audio effects (Reverb, Echo, Virtualizer, BassBoost)
/// via Method Channel. Effects attach to ExoPlayer's audio session ID.
@singleton
class AudioEffectsService {
  static final AppLogger _logger = AppLogger('AudioEffectsService');

  static const _channel = MethodChannel('com.technexa.rhythmflow/audio_effects');

  StreamSubscription<int?>? _sessionSubscription;
  void Function()? _onEffectsReady;

  /// Register a callback to apply stored settings when effects are initialized.
  void registerOnEffectsReady(void Function() callback) {
    _onEffectsReady = callback;
  }

  void clearOnEffectsReady() {
    _onEffectsReady = null;
  }

  /// Call when AudioHandler is set. Subscribes to session ID stream.
  void setupSessionSync(AudioPlayer player) {
    if (!Platform.isAndroid) return;
    _sessionSubscription?.cancel();
    _sessionSubscription = player.androidAudioSessionIdStream.listen(
      (sessionId) async {
        if (sessionId != null && sessionId != 0) {
          try {
            final result = await initEffects(sessionId);
            _logger.d(
              'Audio effects initialized: reverb=${result?['reverbAvailable']}, '
              'virtualizer=${result?['virtualizerAvailable']}, '
              'bassBoost=${result?['bassBoostAvailable']}',
            );
            _onEffectsReady?.call();
          } catch (e) {
            _logger.w('Failed to init audio effects: $e');
          }
        } else {
          try {
            await releaseEffects();
            _logger.d('Audio effects released');
          } catch (e) {
            _logger.w('Failed to release audio effects: $e');
          }
        }
      },
      onError: (e) => _logger.w('Session stream error: $e'),
    );
  }

  /// Cancel session subscription (e.g. on dispose).
  void dispose() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    if (Platform.isAndroid) {
      releaseEffects().catchError((e) => _logger.w('Release on dispose: $e'));
    }
  }

  Future<Map<String, dynamic>?> initEffects(int sessionId) async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'initEffects',
      {'sessionId': sessionId},
    );
    return result?.map((k, v) => MapEntry(k.toString(), v));
  }

  Future<void> releaseEffects() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('releaseEffects');
  }

  Future<void> setReverbPreset(int preset) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setReverbPreset', {'preset': preset});
  }

  Future<void> setReverbEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setReverbEnabled', {'enabled': enabled});
  }

  Future<void> setEnvironmentalReverbEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setEnvironmentalReverbEnabled', {'enabled': enabled});
  }

  Future<void> setEnvironmentalReverb({
    int roomLevel = -6000,
    int reverbLevel = -6000,
    int decayTime = 200,
    int diffusion = 800,
    int density = 800,
    int reflectionsLevel = -2000,
    int reflectionsDelay = 20,
    int reverbDelay = 40,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setEnvironmentalReverb', {
      'roomLevel': roomLevel,
      'reverbLevel': reverbLevel,
      'decayTime': decayTime,
      'diffusion': diffusion,
      'density': density,
      'reflectionsLevel': reflectionsLevel,
      'reflectionsDelay': reflectionsDelay,
      'reverbDelay': reverbDelay,
    });
  }

  Future<void> setVirtualizerStrength(int strength) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod(
      'setVirtualizerStrength',
      {'strength': strength.clamp(0, 1000)},
    );
  }

  Future<void> setVirtualizerEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setVirtualizerEnabled', {'enabled': enabled});
  }

  Future<void> setBassBoostStrength(int strength) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod(
      'setBassBoostStrength',
      {'strength': strength.clamp(0, 1000)},
    );
  }

  Future<void> setBassBoostEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setBassBoostEnabled', {'enabled': enabled});
  }

  /// Retrieve the last-set L/R channel volumes from the native plugin.
  /// Returns null on non-Android or if the call fails.
  Future<({double left, double right})?> getChannelVolumes() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getChannelVolumes',
      );
      if (raw == null) return null;
      return (
        left:  (raw['left']  as num).toDouble(),
        right: (raw['right'] as num).toDouble(),
      );
    } catch (e) {
      _logger.w('getChannelVolumes failed: $e');
      return null;
    }
  }

  /// Set independent left/right channel volumes (0.0–1.0 each).
  ///
  /// Since just_audio/ExoPlayer exposes only a single [AudioPlayer.setVolume],
  /// this calls the native plugin to compute:
  ///   • [globalVolume] = max(left, right) — apply via AudioPlayer.setVolume()
  ///   • [leftGain] / [rightGain] — 1.0 for the louder channel, <1.0 for the quieter
  ///
  /// Returns null on non-Android or if the call fails.
  Future<({double globalVolume, double leftGain, double rightGain})?> setChannelVolumes({
    required double left,
    required double right,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'setChannelVolumes',
        {'left': left.clamp(0.0, 1.0), 'right': right.clamp(0.0, 1.0)},
      );
      if (raw == null) return null;
      return (
        globalVolume: (raw['globalVolume'] as num).toDouble(),
        leftGain:     (raw['leftGain']     as num).toDouble(),
        rightGain:    (raw['rightGain']    as num).toDouble(),
      );
    } catch (e) {
      _logger.w('setChannelVolumes failed: $e');
      return null;
    }
  }
}

