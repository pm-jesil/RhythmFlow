import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';
import 'package:rhythmflow/utils/services/audio_effects_service.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';

/// Applies persisted equalizer and audio effects settings on app startup
/// and when settings change.
class EqualizerInitializer extends StatefulWidget {
  final Widget child;

  const EqualizerInitializer({super.key, required this.child});

  @override
  State<EqualizerInitializer> createState() => _EqualizerInitializerState();
}

class _EqualizerInitializerState extends State<EqualizerInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyStoredSettings());
    if (Platform.isAndroid) {
      getIt<AudioEffectsService>().registerOnEffectsReady(() {
        if (mounted) _applyStoredSettings();
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      getIt<AudioEffectsService>().clearOnEffectsReady();
    }
    super.dispose();
  }

  /// Re-apply when bloc state changes (e.g. after hydration or reset from Settings)
  void _onSettingsChanged(BuildContext context, EqualizerState state) {
    _applyStoredSettings();
  }

  Future<void> _applyStoredSettings() async {
    if (!Platform.isAndroid) return;

    final eqState = getIt<EqualizerBloc>().state;
    final audioService = getIt<AudioService>();

    // Equalizer
    final eq = audioService.equalizer;
    if (eq != null) {
      try {
        await eq.setEnabled(eqState.isEqualizerEnabled);
        if (eqState.equalizerBandGains != null &&
            eqState.equalizerBandGains!.isNotEmpty) {
          final params = await eq.parameters;
          for (var i = 0; i < params.bands.length; i++) {
            final stored = eqState.equalizerBandGains!['$i'];
            if (stored != null) {
              await params.bands[i].setGain(stored);
            }
          }
        }
      } catch (_) {
        // Ignore - equalizer params may not be ready before first audio
      }
    }

    // Loudness (just_audio expects dB; we store mB, so dB = mB/100)
    final le = audioService.loudnessEnhancer;
    if (le != null) {
      try {
        await le.setTargetGain(eqState.loudnessGainMb / 100.0);
        await le.setEnabled(eqState.loudnessEnabled);
      } catch (_) {}
    }

    // Native effects (echo, virtualizer, bass boost)
    final effectsService = getIt<AudioEffectsService>();
    try {
      if (eqState.echoEnabled && eqState.echoStrength > 0) {
        await effectsService.setEnvironmentalReverb(
          decayTime: 200 + (eqState.echoStrength * 3),
          reverbLevel: -2000 + (eqState.echoStrength * 20),
          reflectionsLevel: -1500 + (eqState.echoStrength * 15),
        );
        await effectsService.setEnvironmentalReverbEnabled(true);
      } else {
        await effectsService.setEnvironmentalReverbEnabled(false);
      }

      await effectsService.setVirtualizerStrength(eqState.virtualizerStrength);
      await effectsService.setVirtualizerEnabled(eqState.virtualizerEnabled);

      await effectsService.setBassBoostStrength(eqState.bassBoostStrength);
      await effectsService.setBassBoostEnabled(eqState.bassBoostEnabled);
    } catch (_) {
      // Effects may not be initialized yet (no audio session)
    }
  }

  bool _listenWhen(EqualizerState prev, EqualizerState curr) {
    return prev.isEqualizerEnabled != curr.isEqualizerEnabled ||
        prev.equalizerBandGains != curr.equalizerBandGains ||
        prev.echoEnabled != curr.echoEnabled ||
        prev.echoStrength != curr.echoStrength ||
        prev.virtualizerEnabled != curr.virtualizerEnabled ||
        prev.virtualizerStrength != curr.virtualizerStrength ||
        prev.loudnessEnabled != curr.loudnessEnabled ||
        prev.loudnessGainMb != curr.loudnessGainMb ||
        prev.bassBoostEnabled != curr.bassBoostEnabled ||
        prev.bassBoostStrength != curr.bassBoostStrength;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EqualizerBloc, EqualizerState>(
      listenWhen: _listenWhen,
      listener: _onSettingsChanged,
      child: widget.child,
    );
  }
}
