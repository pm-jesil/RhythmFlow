import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/core/widgets/app_custom.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_appbar.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_bottom_knob_row.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_sliders_container.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';
import 'package:rhythmflow/utils/services/audio_effects_service.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/logger/logger.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen>
    with WidgetsBindingObserver {
  static final AppLogger _logger = AppLogger('EqualizerScreen');
  final AudioService _audioService = getIt<AudioService>();
  final AudioEffectsService _effectsService = getIt<AudioEffectsService>();
  bool _isLoading = true;
  String? _errorMessage;
  double _volumeLeft = 1.0;
  double _volumeRight = 1.0;
  String _selectedPresetId = 'flat';
  String _selectedPresetName = 'Flat';
  bool _currentPresetModified = false;
  ({String id, String name, List<double> gains})? _presetRemoving;

  bool _isSavedPreset(EqualizerState eqState) =>
      _selectedPresetId == (eqState.equalizerSavedPresetId ?? 'flat');

  bool _hasPendingSave(EqualizerState eqState) => !_isSavedPreset(eqState);

  void _setEqualizerOrientation() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _setDefaultOrientation() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setEqualizerOrientation();
    _applyStoredSettings();
    final v = _audioService.volume;
    _volumeLeft = (v.isNaN || v.isInfinite) ? 1.0 : v.clamp(0.0, 1.0);
    _volumeRight = (v.isNaN || v.isInfinite) ? 1.0 : v.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setDefaultOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;
    if (state == AppLifecycleState.paused) {
      _setDefaultOrientation();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) _setEqualizerOrientation();
    }
  }

  Future<void> _applyStoredSettings() async {
    _logger.d('_applyStoredSettings started');
    if (!Platform.isAndroid) {
      _logger.d('Not Android - skipping');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
      return;
    }
    final eq = _audioService.equalizer;
    if (eq == null) {
      _logger.w('Equalizer is null - audio handler may not be ready');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Equalizer not available';
        });
      }
      return;
    }
    try {
      final eqState = context.read<EqualizerBloc>().state;

      // ── 1. Restore EQ enabled state ───────────────────────────────────────
      await eq
          .setEnabled(eqState.isEqualizerEnabled)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('setEnabled timed out'),
          );
      _logger.d('Equalizer enabled state set: ${eqState.isEqualizerEnabled}');

      // ── 2. Restore band gains ─────────────────────────────────────────────
      if (eqState.equalizerBandGains != null &&
          eqState.equalizerBandGains!.isNotEmpty) {
        final params = await eq.parameters.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
            'eq.parameters timed out - play audio first',
          ),
        );
        for (var i = 0; i < params.bands.length; i++) {
          final stored = eqState.equalizerBandGains!['$i'];
          if (stored != null) {
            await params.bands[i].setGain(stored);
          }
        }
        _logger.d('Applied ${params.bands.length} band gains');
      }

      // ── 3. Restore ALL audio effects to hardware ──────────────────────────
      // This is critical: native effects reset when the audio session
      // re-initialises (e.g. on screen open). We must re-apply stored values.

      // 3a. Reverb (PresetReverb) — restored separately from Echo
      if (eqState.reverbEnabled &&
          eqState.reverbPreset != EqualizerReverbPresets.none) {
        await _effectsService.setReverbPreset(eqState.reverbPreset);
        await _effectsService.setReverbEnabled(true);
        _logger.d('Reverb restored: preset=${eqState.reverbPreset}');
      } else {
        await _effectsService.setReverbEnabled(false);
      }

      // 3b. Echo (EnvironmentalReverb), Virtualizer, Loudness, BassBoost
      await _applyEffectValues(
        eqState.echoStrength,
        eqState.virtualizerStrength,
        eqState.loudnessGainMb,
        eqState.bassBoostStrength,
      );
      _logger.d(
        'Effects restored: echo=${eqState.echoStrength} '
        'virt=${eqState.virtualizerStrength} '
        'loud=${eqState.loudnessGainMb} '
        'bass=${eqState.bassBoostStrength}',
      );
    } on TimeoutException catch (e) {
      _logger.w('Equalizer params timeout (play audio first): $e');
    } catch (e) {
      _logger.e('Error applying stored settings', error: e);
    } finally {
      if (mounted) {
        final eqState = context.read<EqualizerBloc>().state;
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _selectedPresetId = eqState.equalizerSavedPresetId ?? 'flat';
          _selectedPresetName = eqState.equalizerSavedPresetName ?? 'Flat';
        });
        _logger.d('_applyStoredSettings done, _isLoading=false');
      }
    }
  }

  List<double> _presetForBandCount(List<double> preset, int count) {
    if (preset.isEmpty) return List.filled(count, 0.0);
    if (preset.length >= count) return preset.sublist(0, count);
    if (count <= 1) return preset.length > 0 ? [preset[0]] : [0.0];
    final result = <double>[];
    for (var i = 0; i < count; i++) {
      final srcIdx = (i / (count - 1)) * (preset.length - 1);
      final lo = srcIdx.floor().clamp(0, preset.length - 1);
      final hi = (lo + 1).clamp(0, preset.length - 1);
      final frac = srcIdx - lo;
      result.add(preset[lo] * (1 - frac) + preset[hi] * frac);
    }
    return result;
  }

  List<double> _getPresetGains(String presetId, EqualizerState appState) {
    final custom = appState.equalizerCustomPresets ?? {};
    if (custom.containsKey(presetId)) {
      return List<double>.from(custom[presetId]!.gains);
    }
    return EqualizerBandPresets.getGains(presetId);
  }

  Future<void> _applyEffectValues(
    int echo,
    int virtualizer,
    int loudness,
    int bassBoost,
  ) async {
    if (echo > 0) {
      await _effectsService.setReverbPreset(EqualizerReverbPresets.none);
      await _effectsService.setEnvironmentalReverb(
        decayTime: 200 + (echo * 3),
        reverbLevel: -2000 + (echo * 20),
        reflectionsLevel: -1500 + (echo * 15),
      );
      await _effectsService.setEnvironmentalReverbEnabled(true);
    } else {
      await _effectsService.setEnvironmentalReverbEnabled(false);
    }
    await _effectsService.setVirtualizerStrength(virtualizer);
    await _effectsService.setVirtualizerEnabled(virtualizer > 0);
    await _audioService.setLoudnessGain(loudness);
    await _audioService.setLoudnessEnabled(loudness > 0);
    await _effectsService.setBassBoostStrength(bassBoost);
    await _effectsService.setBassBoostEnabled(bassBoost > 0);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return _buildIosPlaceholder();

    final eq = _audioService.equalizer;
    return BlocBuilder<EqualizerBloc, EqualizerState>(
      buildWhen: (p, c) =>
          p.isEqualizerEnabled != c.isEqualizerEnabled ||
          p.equalizerCustomPresets != c.equalizerCustomPresets ||
          p.equalizerBandGains != c.equalizerBandGains ||
          p.equalizerSavedPresetId != c.equalizerSavedPresetId,
      builder: (context, eqState) {
        // Compute whether the bottom action bar is currently visible.
        // When it is, we smoothly hide the AppBar to give sliders more space.
        final bottomBarVisible =
            _hasPendingSave(eqState) || _currentPresetModified;

        return Scaffold(
          backgroundColor: context.backgroundColor,
          resizeToAvoidBottomInset: false,
          // No appBar — we animate it inside the body so we can collapse it
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Animated App Bar ─────────────────────────────────────
                // AnimatedAlign collapses height to 0 when bottomBarVisible,
                // giving full extra space to the sliders below.
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    heightFactor: bottomBarVisible ? 0.0 : 1.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: bottomBarVisible ? 0.0 : 1.0,
                      child: EqualizerAppBar(
                        eq: eq,
                        onBack: () => Navigator.pop(context),
                        onAddPreset: eq != null
                            ? () => _showAddPresetDialog(eq, eqState)
                            : null,
                      ),
                    ),
                  ),
                ),
                // ── Body ─────────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              color: context.primaryStart,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : _buildBody(eq, eqState),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIosPlaceholder() {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: EqualizerAppBar(
        onBack: () => Navigator.pop(context),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.waveform,
                size: 30.sp,
                color: context.onSurfaceVariantColor.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'Equalizer',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Available on Android. iOS support coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 8.sp,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main body ───────────────────────────────────────────────────────────────

  Widget _buildBody(AndroidEqualizer? eq, EqualizerState eqState) {
    if (eq == null || _errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage ?? 'Equalizer not available',
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 12.sp,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return BlocBuilder<EqualizerBloc, EqualizerState>(
      buildWhen: (p, c) =>
          p.equalizerCustomPresets != c.equalizerCustomPresets ||
          p.equalizerBandGains != c.equalizerBandGains ||
          p.equalizerSavedPresetId != c.equalizerSavedPresetId ||
          p.reverbEnabled != c.reverbEnabled ||
          p.reverbPreset != c.reverbPreset ||
          p.echoEnabled != c.echoEnabled ||
          p.echoStrength != c.echoStrength ||
          p.virtualizerEnabled != c.virtualizerEnabled ||
          p.virtualizerStrength != c.virtualizerStrength ||
          p.loudnessEnabled != c.loudnessEnabled ||
          p.loudnessGainMb != c.loudnessGainMb ||
          p.bassBoostEnabled != c.bassBoostEnabled ||
          p.bassBoostStrength != c.bassBoostStrength,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final slidersMaxHeight = availableHeight * 0.42;
            final reservedForHeaderSpacersButton = availableHeight * 0.15;
            final spaceForBottomRow =
                (availableHeight -
                        reservedForHeaderSpacersButton -
                        slidersMaxHeight)
                    .clamp(0.0, double.infinity);
            final bottomRowHeight = [
              availableHeight * 0.44,
              165.h,
              spaceForBottomRow,
            ].reduce((a, b) => a < b ? a : b).clamp(70.h, 165.h);
            return Column(
              children: [
                EqualizerSectionHeaderRow(
                  onDefaultPressed: _onDefaultPressed,
                ),
                SizedBox(height: 4.h),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: slidersMaxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: EqualizerSlidersContainer(
                        eq: eq,
                        appState: state,
                        onGainChanged: () {
                          if (mounted) {
                            setState(() => _currentPresetModified = true);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: EqualizerBottomKnobRow(
                    eq: eq,
                    state: state,
                    height: bottomRowHeight,
                    volumeLeft: _volumeLeft,
                    volumeRight: _volumeRight,
                    onVolumeLeftChanged: (v) async {
                      setState(() => _volumeLeft = v);
                      final r = await _effectsService.setChannelVolumes(
                        left: _volumeLeft,
                        right: _volumeRight,
                      );
                      if (r != null) {
                        unawaited(_audioService.setVolume(r.globalVolume));
                      }
                    },
                    onVolumeRightChanged: (v) async {
                      setState(() => _volumeRight = v);
                      final r = await _effectsService.setChannelVolumes(
                        left: _volumeLeft,
                        right: _volumeRight,
                      );
                      if (r != null) {
                        unawaited(_audioService.setVolume(r.globalVolume));
                      }
                    },
                    selectedPresetId: _selectedPresetId,
                    presetRemoving: _presetRemoving,
                    onPresetSelected: (id, name, gains) =>
                        _applyPreset(eq, state, id, name, gains),
                    onPresetDeleteRequested: (id, name, gains) =>
                        _showDeleteConfirmDialog(eq, state, id, name, gains),
                    onReverbSelected: _onReverbSelected,
                  ),
                ),
                SizedBox(height: 4.h),
                EqualizerBottomSaveUpdateButton(
                  hasPendingSave: _hasPendingSave(state),
                  currentPresetModified: _currentPresetModified,
                  isCustomPreset: (state.equalizerCustomPresets ?? {})
                      .containsKey(_selectedPresetId),
                  onConfirmSelection: () => _onConfirmSelection(eq, state),
                  onUndo: () => _onUndo(eq, state),
                  onUpdate: () => _onUpdate(
                    eq,
                    state,
                    (state.equalizerCustomPresets ?? {})
                        .containsKey(_selectedPresetId),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onDefaultPressed() async {
    final eq = _audioService.equalizer;
    if (eq == null) return;
    final params = await eq.parameters;
    final bloc = context.read<EqualizerBloc>();

    // ── Instantly apply 0 to hardware bands and effects ───────────────────
    for (var i = 0; i < params.bands.length; i++) {
        await params.bands[i].setGain(0.0);
    }

    await _effectsService.setEnvironmentalReverbEnabled(false);
    await _effectsService.setReverbPreset(EqualizerReverbPresets.none);
    await _effectsService.setReverbEnabled(false);
    await _effectsService.setVirtualizerStrength(0);
    await _effectsService.setVirtualizerEnabled(false);
    await _effectsService.setBassBoostStrength(0);
    await _effectsService.setBassBoostEnabled(false);
    await _audioService.setLoudnessGain(0);
    await _audioService.setLoudnessEnabled(false);

    if (!mounted) return;

    // ── Instantly update state so sliders animate to 0 ────────────────────
    bloc.add(
      EqualizerEvent.persistEqualizerState(
        isEnabled: bloc.state.isEqualizerEnabled, // Keep current on/off state
        bandGains: {for (var i = 0; i < params.bands.length; i++) '$i': 0.0},
        presetId: 'flat',
        presetName: 'Flat',
      ),
    );
    bloc.add(
      const EqualizerEvent.persistAudioEffectsState(
        reverbEnabled: false,
        reverbPreset: EqualizerReverbPresets.none,
        echoEnabled: false,
        echoStrength: 0,
        virtualizerEnabled: false,
        virtualizerStrength: 0,
        loudnessEnabled: false,
        loudnessGainMb: 0,
        bassBoostEnabled: false,
        bassBoostStrength: 0,
      ),
    );
    setState(() {
      _selectedPresetId = 'flat';
      _selectedPresetName = 'Flat';
      _currentPresetModified = false;
    });
    AppCustom.showSettingsSavedToast(context);
  }

  Future<void> _applyPreset(
    AndroidEqualizer eq,
    EqualizerState appState,
    String presetId,
    String presetName,
    List<double> gains,
  ) async {
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    final adjustedGains = _presetForBandCount(gains, bandCount);
    final bloc = context.read<EqualizerBloc>();

    // ── Apply band gains to hardware immediately ──────────────────────────
    final newBandGains = <String, double>{};
    for (var i = 0; i < bandCount; i++) {
        final gain = adjustedGains[i].clamp(
            params.minDecibels,
            params.maxDecibels,
        );
        await params.bands[i].setGain(gain);
        newBandGains['$i'] = gain;
    }
    // Always enable EQ hardware when applying a preset so audio is affected.
    await eq.setEnabled(true);

    final isBuiltIn = !presetId.startsWith('custom_');

    // ── Apply effect values to hardware instantly (if built-in) ───────────
    if (isBuiltIn) {
        final fx = EqualizerPresetEffects.get(presetId);
        await _applyEffectValues(
            fx.echo,
            fx.virtualizer,
            fx.loudness,
            fx.bassBoost,
        );
        if (mounted) {
            bloc.add(
                EqualizerEvent.persistAudioEffectsState(
                    reverbEnabled: false,
                    reverbPreset: EqualizerReverbPresets.none,
                    echoEnabled: fx.echo > 0,
                    echoStrength: fx.echo,
                    virtualizerEnabled: fx.virtualizer > 0,
                    virtualizerStrength: fx.virtualizer,
                    loudnessEnabled: fx.loudness > 0,
                    loudnessGainMb: fx.loudness,
                    bassBoostEnabled: fx.bassBoost > 0,
                    bassBoostStrength: fx.bassBoost,
                ),
            );
        }
    }

    if (mounted) {
        // ── Apply band gains to state instantly so UI sliders animate ───────────
        bloc.add(
            EqualizerEvent.persistEqualizerState(
                isEnabled: true, // Preset inherently enables the EQ
                bandGains: newBandGains,
                presetId: presetId,
                presetName: presetName,
            ),
        );

        setState(() {
            _selectedPresetId = presetId;
            _selectedPresetName = presetName;
            _currentPresetModified = false;
        });
    }
  }

  Future<void> _onReverbSelected(int presetId) async {
    await _effectsService.setReverbPreset(presetId);
    await _effectsService.setReverbEnabled(
      presetId != EqualizerReverbPresets.none,
    );
    if (mounted) {
      context.read<EqualizerBloc>().add(
        EqualizerEvent.persistAudioEffectsState(
          reverbEnabled: presetId != EqualizerReverbPresets.none,
          reverbPreset: presetId,
          echoEnabled: false,
        ),
      );
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _onConfirmSelection(
    AndroidEqualizer eq,
    EqualizerState appState,
  ) async {
    final params = await eq.parameters;
    final bandGains = <String, double>{};
    for (var i = 0; i < params.bands.length; i++) {
      bandGains['$i'] = params.bands[i].gain;
    }
    if (!mounted) return;
    // Confirming a preset always enables the EQ — user is locking in an active sound.
    await eq.setEnabled(true);
    context.read<EqualizerBloc>().add(
      EqualizerEvent.persistEqualizerState(
        isEnabled: true,
        bandGains: bandGains,
        presetId: _selectedPresetId,
        presetName: _selectedPresetName,
      ),
    );
    setState(() {});
    AppCustom.showSettingsSavedToast(context);
  }

  Future<void> _onUndo(AndroidEqualizer eq, EqualizerState appState) async {
    final gains = _getPresetGains(_selectedPresetId, appState);
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    final adjustedGains = _presetForBandCount(gains, bandCount);
    for (var i = 0; i < bandCount; i++) {
      final gain = adjustedGains[i].clamp(
        params.minDecibels,
        params.maxDecibels,
      );
      await params.bands[i].setGain(gain);
    }
    if (!mounted) return;
    setState(() => _currentPresetModified = false);
    if (!_hasPendingSave(appState)) {
      final bandGains = <String, double>{};
      for (var i = 0; i < bandCount; i++) {
        bandGains['$i'] = adjustedGains[i].clamp(
          params.minDecibels,
          params.maxDecibels,
        );
      }
      context.read<EqualizerBloc>().add(
        EqualizerEvent.persistEqualizerState(
          isEnabled: appState.isEqualizerEnabled,
          bandGains: bandGains,
          presetId: _selectedPresetId,
          presetName: _selectedPresetName,
        ),
      );
    }
  }

  Future<void> _onUpdate(
    AndroidEqualizer eq,
    EqualizerState appState,
    bool isCustom,
  ) async {
    if (!isCustom) {
      await _showSaveAsNewPresetDialog(eq, appState);
      return;
    }
    final params = await eq.parameters;
    final gains = <double>[];
    for (var i = 0; i < params.bands.length; i++) {
      gains.add(params.bands[i].gain);
    }
    final bandGains = <String, double>{
      for (var i = 0; i < params.bands.length; i++) '$i': gains[i],
    };
    // Updating a preset always enables EQ — user is saving an active preset.
    await eq.setEnabled(true);
    context.read<EqualizerBloc>().add(
      EqualizerEvent.persistEqualizerState(
        isEnabled: true,
        bandGains: bandGains,
        presetId: _selectedPresetId,
        presetName: _selectedPresetName,
      ),
    );
    context.read<EqualizerBloc>().add(
      EqualizerEvent.updateEqualizerPresetGains(
        id: _selectedPresetId,
        name: _selectedPresetName,
        gains: gains,
      ),
    );
    if (mounted) {
      setState(() => _currentPresetModified = false);
      AppCustom.showSettingsSavedToast(context);
    }
  }

  /// When a built-in preset is selected and user has modified values, save
  /// current values as a new custom preset (built-in presets are never modified).
  Future<void> _showSaveAsNewPresetDialog(
    AndroidEqualizer eq,
    EqualizerState appState,
  ) async {
    final saved = await _showPresetNameDialog(
      context: context,
      title: 'Save as new preset',
      initialName: '',
      getGains: () async {
        final params = await eq.parameters;
        return [for (var b in params.bands) b.gain];
      },
      applyToHardware: false,
      eq: eq,
      appState: appState,
    );
    if (saved != null && mounted) {
      setState(() {
        _selectedPresetId = saved.id;
        _selectedPresetName = saved.name;
        _currentPresetModified = false;
      });
      AppCustom.showSettingsSavedToast(context);
    }
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _showAddPresetDialog(
    AndroidEqualizer eq,
    EqualizerState appState, {
    String? initialName,
  }) async {
    final saved = await _showPresetNameDialog(
      context: context,
      title: 'Add new preset',
      initialName: initialName ?? '',
      getGains: () async {
        final params = await eq.parameters;
        return _presetForBandCount(
          List<double>.from(EqualizerBandPresets.flat),
          params.bands.length,
        );
      },
      applyToHardware: true,
      eq: eq,
      appState: appState,
    );
    if (saved != null && mounted) {
      setState(() {
        _selectedPresetId = saved.id;
        _selectedPresetName = saved.name;
      });
    }
  }

  /// Shared preset name dialog (Add new / Save as new). Same UI and behavior.
  static Future<({String id, String name})?> _showPresetNameDialog({
    required BuildContext context,
    required String title,
    required String initialName,
    required Future<List<double>> Function() getGains,
    required bool applyToHardware,
    required AndroidEqualizer eq,
    required EqualizerState appState,
  }) async {
    final controller = TextEditingController(text: initialName);
    final formKey = GlobalKey<FormState>();
    return showDialog<({String id, String name})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: AlertDialog(
                backgroundColor: ctx.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                titlePadding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
                contentPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                title: Text(
                  title,
                  style: TextStyle(
                    color: ctx.onSurfaceColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      labelText: 'Preset name',
                      hintText: 'e.g. My Bass',
                      labelStyle: TextStyle(
                        fontSize: 8.sp,
                        fontFamily: 'Poppins',
                      ),
                      hintStyle: TextStyle(
                        fontSize: 8.sp,
                        fontFamily: 'Poppins',
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitPresetName(
                      ctx,
                      formKey,
                      controller,
                      getGains,
                      applyToHardware,
                      eq,
                      appState,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: ctx.onSurfaceVariantColor,
                        fontSize: 8.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _submitPresetName(
                      ctx,
                      formKey,
                      controller,
                      getGains,
                      applyToHardware,
                      eq,
                      appState,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: ctx.primaryStart,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _submitPresetName(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    TextEditingController controller,
    Future<List<double>> Function() getGains,
    bool applyToHardware,
    AndroidEqualizer eq,
    EqualizerState appState,
  ) async {
    if (formKey.currentState?.validate() != true) return;
    final name = controller.text.trim();
    final gains = await getGains();
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    if (gains.length != bandCount) return;
    if (applyToHardware) {
      for (var i = 0; i < bandCount; i++) {
        final gain = gains[i].clamp(
          params.minDecibels,
          params.maxDecibels,
        );
        await params.bands[i].setGain(gain);
      }
    }
    final bandGains = <String, double>{
      for (var i = 0; i < bandCount; i++) '$i': gains[i],
    };
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final bloc = ctx.read<EqualizerBloc>();
    bloc.add(
      EqualizerEvent.createEqualizerPreset(
        id: id,
        name: name,
        gains: gains,
      ),
    );
    bloc.add(
      EqualizerEvent.persistEqualizerState(
        isEnabled: bloc.state.isEqualizerEnabled,
        bandGains: bandGains,
        presetId: id,
        presetName: name,
      ),
    );
    if (ctx.mounted) {
      Navigator.pop(ctx, (id: id, name: name));
    }
  }

  Future<void> _showDeleteConfirmDialog(
    AndroidEqualizer eq,
    EqualizerState appState,
    String presetId,
    String presetName,
    List<double> gains,
  ) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.fromLTRB(
          12.w,
          0,
          12.w,
          12.h + MediaQuery.of(ctx).padding.bottom,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: context.primaryStart.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete Preset',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Are you sure you want to delete '$presetName'?",
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 9.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 9.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: context.primaryStart,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm == true && mounted) {
      final wasSelected = _selectedPresetId == presetId;
      context.read<EqualizerBloc>().add(
        EqualizerEvent.deleteEqualizerPreset(id: presetId),
      );
      if (wasSelected) {
        final params = await eq.parameters;
        final bandCount = params.bands.length;
        final flatGains = _presetForBandCount(EqualizerBandPresets.flat, bandCount);
        final bandGains = <String, double>{};
        for (var i = 0; i < bandCount; i++) {
          final gain = flatGains[i].clamp(
            params.minDecibels,
            params.maxDecibels,
          );
          await params.bands[i].setGain(gain);
          bandGains['$i'] = gain;
        }
        if (mounted) {
          context.read<EqualizerBloc>().add(
            EqualizerEvent.persistEqualizerState(
              isEnabled: appState.isEqualizerEnabled,
              bandGains: bandGains,
              presetId: 'flat',
              presetName: 'Flat',
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          if (wasSelected) {
            _selectedPresetId = 'flat';
            _selectedPresetName = 'Flat';
          }
          _presetRemoving = (
            id: presetId,
            name: presetName,
            gains: List<double>.from(gains),
          );
        });
        AppCustom.showSettingsSavedToast(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _presetRemoving = null);
        });
      }
    }
  }
}
