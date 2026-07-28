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
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_hero_tags.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_sliders_container.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_transition_shell.dart';
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
  static const _stageTransitionDuration = Duration(milliseconds: 320);
  static const _orientationSettleDuration = Duration(milliseconds: 360);
  static final AppLogger _logger = AppLogger('EqualizerScreen');
  final AudioService _audioService = getIt<AudioService>();
  final AudioEffectsService _effectsService = getIt<AudioEffectsService>();
  final HeroController _stageHeroController = HeroController();
  bool _isLoading = true;
  String? _errorMessage;
  double _volumeLeft = 1.0;
  double _volumeRight = 1.0;
  double _committedVolumeLeft = 1.0;
  double _committedVolumeRight = 1.0;
  String _selectedPresetId = 'flat';
  String _selectedPresetName = 'Flat';
  bool _currentPresetModified = false;
  ({String id, String name, List<double> gains})? _presetRemoving;

  /// Preview effect values shown in sliders while a preset is applied but not
  /// yet confirmed. Null means fall back to the persisted Bloc state.
  int? _previewEcho;
  int? _previewVirtualizer;
  int? _previewLoudness;
  int? _previewBassBoost;

  /// Target gains for each band so sliders animate on preset tap even if
  /// gainStream doesn't emit. Updated when preset is applied or user drags a band.
  List<double>? _targetBandGains;
  _EqualizerViewportStage _viewportStage = Platform.isAndroid
      ? _EqualizerViewportStage.portraitShell
      : _EqualizerViewportStage.landscapeContent;
  bool _entryTransitionStarted = false;

  bool _isSavedPreset(EqualizerState eqState) =>
      _selectedPresetId == (eqState.equalizerSavedPresetId ?? 'flat');

  /// True when there are unsaved changes: different preset selected or volume.
  bool _hasPendingSave(EqualizerState eqState) =>
      !_isSavedPreset(eqState) ||
      (_volumeLeft - _committedVolumeLeft).abs() > 0.001 ||
      (_volumeRight - _committedVolumeRight).abs() > 0.001;

  bool _isSelectedPresetCustom(EqualizerState eqState) =>
      (eqState.equalizerCustomPresets ?? {}).containsKey(_selectedPresetId);

  /// Returns the effective effect values: preview overrides if present,
  /// otherwise falls back to the last persisted bloc values.
  ({int echo, int virtualizer, int loudness, int bassBoost})
  _resolvedPendingEffects(EqualizerState appState) => (
    echo: _previewEcho ?? appState.echoStrength,
    virtualizer: _previewVirtualizer ?? appState.virtualizerStrength,
    loudness: _previewLoudness ?? appState.loudnessGainMb,
    bassBoost: _previewBassBoost ?? appState.bassBoostStrength,
  );

  void _commitSelectionToBloc({
    required EqualizerState appState,
    required Map<String, double> bandGains,
    String? presetId,
    String? presetName,
  }) {
    final effects = _resolvedPendingEffects(appState);
    context.read<EqualizerBloc>().add(
      EqualizerEvent.commitSelection(
        isEnabled: true,
        bandGains: bandGains,
        presetId: presetId ?? _selectedPresetId,
        presetName: presetName ?? _selectedPresetName,
        echoStrength: effects.echo,
        virtualizerStrength: effects.virtualizer,
        loudnessGainMb: effects.loudness,
        bassBoostStrength: effects.bassBoost,
      ),
    );
  }

  void _clearPendingUiAfterCommit() {
    _committedVolumeLeft = _volumeLeft;
    _committedVolumeRight = _volumeRight;
    _currentPresetModified = false;
    _previewEcho = null;
    _previewVirtualizer = null;
    _previewLoudness = null;
    _previewBassBoost = null;
  }

  static const _flatGainEpsilonDb = 0.08;
  static const _volumeFullEpsilon = 0.005;

  /// True when UI + hardware + persisted state already match Flat — no save needed.
  bool _isAlreadyFullyFlat(
    EqualizerState eqState,
    AndroidEqualizerParameters params,
  ) {
    if ((_volumeLeft - 1.0).abs() > _volumeFullEpsilon ||
        (_volumeRight - 1.0).abs() > _volumeFullEpsilon) {
      return false;
    }
    for (final b in params.bands) {
      if (b.gain.abs() > _flatGainEpsilonDb) return false;
    }
    final fx = _resolvedPendingEffects(eqState);
    if (fx.echo != 0 ||
        fx.virtualizer != 0 ||
        fx.loudness != 0 ||
        fx.bassBoost != 0) {
      return false;
    }
    final stored = eqState.equalizerBandGains;
    if (stored != null && stored.isNotEmpty) {
      for (final v in stored.values) {
        if (v.abs() > _flatGainEpsilonDb) return false;
      }
    }
    if (_selectedPresetId != 'flat') return false;
    if ((eqState.equalizerSavedPresetId ?? 'flat') != 'flat') return false;
    if (_currentPresetModified) return false;
    if (_hasPendingSave(eqState)) return false;
    return true;
  }

  /// L/R channel knobs at 100 % — matches [MasterVolumeKnob] display (0–100).
  Future<void> _setChannelVolumesToFull() async {
    const full = 1.0;
    final r = await _effectsService.setChannelVolumes(left: full, right: full);
    if (r != null) {
      unawaited(_audioService.setVolume(r.globalVolume));
    }
  }

  Future<void> _setEqualizerOrientation() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight])
        .timeout(const Duration(seconds: 2), onTimeout: () {
      _logger.w('setPreferredOrientations(landscape) timed out — continuing');
    });
  }

  Future<void> _setPortraitOrientation() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .timeout(const Duration(seconds: 2), onTimeout: () {
      _logger.w('setPreferredOrientations(portrait) timed out — continuing');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeSessionAndApply());
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startEntryTransition());
      });
    }
    final v = _audioService.volume;
    _volumeLeft = (v.isNaN || v.isInfinite) ? 1.0 : v.clamp(0.0, 1.0);
    _volumeRight = _volumeLeft;
    _committedVolumeLeft = _volumeLeft;
    _committedVolumeRight = _volumeRight;
    // Restore individual L/R values persisted in the native plugin across
    // screen open/close cycles (the plugin keeps them even when the Dart
    // screen is disposed).
    _effectsService.getChannelVolumes().then((vols) {
      if (mounted && vols != null) {
        setState(() {
          _volumeLeft = vols.left;
          _volumeRight = vols.right;
          _committedVolumeLeft = vols.left;
          _committedVolumeRight = vols.right;
        });
      }
    });
  }

  Future<void> _initializeSessionAndApply() async {
    context.read<EqualizerBloc>().add(const EqualizerEvent.initializeSession());
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _applyStoredSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_setPortraitOrientation());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;
    if (state == AppLifecycleState.paused) {
      unawaited(_setPortraitOrientation());
    } else if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      if (_viewportStage == _EqualizerViewportStage.landscapeContent) {
        unawaited(_setEqualizerOrientation());
      } else {
        unawaited(_setPortraitOrientation());
      }
    }
  }

  Future<void> _startEntryTransition() async {
    if (!Platform.isAndroid || _entryTransitionStarted) return;
    _entryTransitionStarted = true;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _isNavigating) return;
    // Do not block the viewport forever if the platform never completes
    // setPreferredOrientations (seen on some devices during rotation).
    unawaited(_setEqualizerOrientation());
    await Future<void>.delayed(_orientationSettleDuration);
    if (!mounted || _isNavigating) return;
    setState(() => _viewportStage = _EqualizerViewportStage.landscapeContent);
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

      // Show landscape body immediately; band/effect restore can be slow or
      // block on native — sliders area handles "play audio" / retry UX.
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // ── 2. Restore band gains ─────────────────────────────────────────────
      if (eqState.equalizerBandGains != null &&
          eqState.equalizerBandGains!.isNotEmpty) {
        try {
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
        } on TimeoutException catch (e) {
          _logger.w('Band restore skipped (params): $e');
        }
      }

      // ── 3. Restore audio effects (bounded) ───────────────────────────────
      await _applyEffectValues(
        eqState.echoStrength,
        eqState.virtualizerStrength,
        eqState.loudnessGainMb,
        eqState.bassBoostStrength,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.w(
            'Effects restore timed out — effects may apply when session is ready',
          );
        },
      );
      _logger.d(
        'Effects restored: echo=${eqState.echoStrength} '
        'virt=${eqState.virtualizerStrength} '
        'loud=${eqState.loudnessGainMb} '
        'bass=${eqState.bassBoostStrength}',
      );
    } on TimeoutException catch (e) {
      _logger.w('Equalizer setup timeout: $e');
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _logger.e('Error applying stored settings', error: e);
      if (mounted) setState(() => _isLoading = false);
    } finally {
      if (mounted) {
        try {
          final eqState = context.read<EqualizerBloc>().state;
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _selectedPresetId = eqState.equalizerSavedPresetId ?? 'flat';
            _selectedPresetName = eqState.equalizerSavedPresetName ?? 'Flat';
          });
        } catch (e) {
          _logger.w('Could not read EqualizerBloc in finally: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
        _logger.d('_applyStoredSettings done, _isLoading=false');
      }
    }
  }

  /// Returns gains for [presetId] from custom presets or built-in fallback.
  static List<double> _getPresetGains(
      String presetId, EqualizerState appState) {
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
    Future<void> tryEffect(String name, Future<void> Function() fn) async {
      try {
        await fn();
      } on PlatformException catch (e) {
        if (e.code == 'EFFECT_NOT_INIT') {
          _logger.w(
            'Effect $name not initialized yet (session not ready), skipping',
          );
        } else {
          _logger.e('Effect $name failed', error: e);
        }
      }
    }

    await tryEffect('EnvironmentalReverb', () async {
      if (echo > 0) {
        await _effectsService.setEnvironmentalReverb(
          // roomLevel: scale from silent (-6000) to -1600 as echo grows.
          // Without this the room component is silent and echo sounds weak.
          roomLevel: -6000 + (echo * 44),
          decayTime: 200 + (echo * 3),
          reverbLevel: -2000 + (echo * 20),
          reflectionsLevel: -1500 + (echo * 15),
        );
        await _effectsService.setEnvironmentalReverbEnabled(true);
      } else {
        await _effectsService.setEnvironmentalReverbEnabled(false);
      }
    });
    await tryEffect('Virtualizer', () async {
      await _effectsService.setVirtualizerStrength(virtualizer);
      await _effectsService.setVirtualizerEnabled(virtualizer > 0);
    });
    await tryEffect('Loudness', () async {
      await _audioService.setLoudnessGain(loudness);
      await _audioService.setLoudnessEnabled(loudness > 0);
    });
    await tryEffect('BassBoost', () async {
      await _effectsService.setBassBoostStrength(bassBoost);
      await _effectsService.setBassBoostEnabled(bassBoost > 0);
    });
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
        final isCustomPreset = _isSelectedPresetCustom(eqState);
        final showActionBar =
            eq != null && (_hasPendingSave(eqState) || _currentPresetModified);
        final actionPrimaryLabel = EqualizerActionBar.primaryLabelFor(
          currentPresetModified: _currentPresetModified,
          isCustomPreset: isCustomPreset,
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _navigateBack();
          },
          child: Scaffold(
            backgroundColor: context.backgroundColor,
            resizeToAvoidBottomInset: false,
            body: Navigator(
              observers: [_stageHeroController],
              onPopPage: (route, result) => false,
              pages: [
                _EqualizerStagePage(
                  key: ValueKey(_viewportStage),
                  child: _viewportStage == _EqualizerViewportStage.portraitShell
                      ? EqualizerPortraitTransitionShell(
                          onBack: _navigateBack,
                          showAddButton: eq != null,
                          showActionBar: showActionBar,
                          actionPrimaryLabel: actionPrimaryLabel,
                        )
                      : _buildLandscapeStage(
                          eq,
                          eqState,
                          showActionBar: showActionBar,
                          hasPendingSave: _hasPendingSave(eqState),
                          isCustomPreset: isCustomPreset,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeStage(
    AndroidEqualizer? eq,
    EqualizerState eqState, {
    required bool showActionBar,
    required bool hasPendingSave,
    required bool isCustomPreset,
  }) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          EqualizerTopBar(
            eq: eq,
            onBack: _navigateBack,
            onAddPreset: eq != null ? () => _showAddPresetDialog(eq) : null,
            showActionBar: showActionBar,
            hasPendingSave: hasPendingSave,
            currentPresetModified: _currentPresetModified,
            isCustomPreset: isCustomPreset,
            onConfirmSelection: () {
              if (eq == null) return;
              _onConfirmSelection(eq, context.read<EqualizerBloc>().state);
            },
            onUndo: () {
              if (eq == null) return;
              _onUndo(eq, context.read<EqualizerBloc>().state);
            },
            onUpdate: () {
              if (eq == null) return;
              final latestState = context.read<EqualizerBloc>().state;
              _onUpdate(eq, latestState, _isSelectedPresetCustom(latestState));
            },
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        color: context.primaryStart,
                        strokeWidth: 2.r,
                      ),
                    ),
                  )
                : _buildBody(eq),
          ),
        ],
      ),
    );
  }

  Widget _buildIosPlaceholder() {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: EqualizerAppBar(onBack: () => Navigator.pop(context)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.waveform,
                size: 30.sp,
                color: context.onSurfaceVariantColor.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.r),
              Text(
                'Equalizer',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.r),
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

  Widget _buildBody(AndroidEqualizer? eq) {
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
            final tight = availableHeight < 300.r;
            final minSlidersHeight = tight ? 56.r : 72.r;
            final bottomRowMin = tight ? 44.r : 52.r;
            final bottomRowMax = tight ? 88.r : 104.r;
            final headerPlusSpacers = tight ? 32.r : 40.r;
            final verticalSpacersTotal = tight ? 8.r : 12.r;

            final remaining =
                availableHeight - headerPlusSpacers - verticalSpacersTotal;
            final bottomRowHeight = (remaining - minSlidersHeight).clamp(
              bottomRowMin,
              bottomRowMax,
            );
            final naturalSlidersHeight = (remaining - bottomRowHeight).clamp(
              minSlidersHeight,
              double.infinity,
            );
            // Give sliders 90 % of natural height — the extra space freed by
            // the shorter app bar flows back into the frequency-bands container.
            final slidersMaxHeight = (naturalSlidersHeight * 0.90).clamp(
              minSlidersHeight,
              naturalSlidersHeight,
            );

            return Column(
              children: [
                Hero(
                  tag: EqualizerHeroTags.sectionHeader,
                  child: Material(
                    type: MaterialType.transparency,
                    child: EqualizerSectionHeaderRow(
                      onDefaultPressed: _onDefaultPressed,
                    ),
                  ),
                ),
                SizedBox(height: 4.r),
                // Align is required so ConstrainedBox(maxHeight) is respected
                // even when the surrounding Expanded would otherwise give
                // tight constraints that override it.
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: slidersMaxHeight),
                      child: Hero(
                        tag: EqualizerHeroTags.slidersCard,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.r),
                            child: EqualizerSlidersContainer(
                              eq: eq,
                              appState: state,
                              onGainChanged: () {
                                if (mounted) {
                                  setState(
                                    () => _currentPresetModified = true,
                                  );
                                }
                              },
                              targetBandGains: _targetBandGains,
                              onBandGainChanged: (bandIndex, gain) {
                                if (mounted &&
                                    _targetBandGains != null &&
                                    bandIndex < _targetBandGains!.length) {
                                  setState(
                                    () => _targetBandGains![bandIndex] = gain,
                                  );
                                }
                              },
                              onEffectChanged:
                                  ({
                                    echo,
                                    virtualizer,
                                    loudness,
                                    bassBoost,
                                  }) {
                                    if (mounted) {
                                      setState(() {
                                        if (echo != null) _previewEcho = echo;
                                        if (virtualizer != null) {
                                          _previewVirtualizer = virtualizer;
                                        }
                                        if (loudness != null) {
                                          _previewLoudness = loudness;
                                        }
                                        if (bassBoost != null) {
                                          _previewBassBoost = bassBoost;
                                        }
                                        _currentPresetModified = true;
                                      });
                                    }
                                  },
                              previewEcho: _previewEcho,
                              previewVirtualizer: _previewVirtualizer,
                              previewLoudness: _previewLoudness,
                              previewBassBoost: _previewBassBoost,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.r),
                Hero(
                  tag: EqualizerHeroTags.bottomRow,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24.r, 0, 24.r, 16.r),
                      child: EqualizerBottomKnobRow(
                        state: state,
                        height: bottomRowHeight,
                        volumeLeft: _volumeLeft,
                        volumeRight: _volumeRight,
                        onVolumeLeftChanged: (v) async {
                          setState(() {
                            _volumeLeft = v;
                            _currentPresetModified = true;
                          });
                          final r = await _effectsService.setChannelVolumes(
                            left: _volumeLeft,
                            right: _volumeRight,
                          );
                          if (r != null) {
                            unawaited(_audioService.setVolume(r.globalVolume));
                          }
                        },
                        onVolumeRightChanged: (v) async {
                          setState(() {
                            _volumeRight = v;
                            _currentPresetModified = true;
                          });
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
                            _deleteCustomPreset(eq, state, id, name, gains),
                      ),
                    ),
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
    final bloc = context.read<EqualizerBloc>();
    AndroidEqualizerParameters params;
    try {
      params = await eq.parameters.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('eq.parameters'),
      );
    } on TimeoutException {
      _logger.w('Default: eq.parameters timed out');
      return;
    }
    if (!mounted) return;

    final eqState = bloc.state;
    final bandCount = params.bands.length;
    final zeroGains = List<double>.filled(bandCount, 0.0);

    // Already Flat everywhere: only nudge UI animation (no native spam / toast).
    if (_isAlreadyFullyFlat(eqState, params)) {
      setState(() {
        _targetBandGains = List<double>.from(zeroGains);
        _clearPendingUiAfterCommit();
      });
      return;
    }

    for (var i = 0; i < bandCount; i++) {
      final g = params.bands[i].gain;
      if (g.abs() > _flatGainEpsilonDb) {
        await params.bands[i].setGain(0.0);
      }
    }

    // Always push effect chain to zero on a real reset — bloc can read 0 while
    // native effects are still active after a preview preset.
    await _applyEffectValues(0, 0, 0, 0);

    // L/R master knobs → 100 % (normalized 1.0), same as knob_widget top scale.
    await _setChannelVolumesToFull();

    if (!mounted) return;

    final bandGains = <String, double>{
      for (var i = 0; i < bandCount; i++) '$i': 0.0,
    };
    bloc.add(
      EqualizerEvent.commitSelection(
        isEnabled: eqState.isEqualizerEnabled,
        bandGains: bandGains,
        presetId: 'flat',
        presetName: 'Flat',
        echoStrength: 0,
        virtualizerStrength: 0,
        loudnessGainMb: 0,
        bassBoostStrength: 0,
      ),
    );
    setState(() {
      _selectedPresetId = 'flat';
      _selectedPresetName = 'Flat';
      _targetBandGains = List<double>.from(zeroGains);
      _volumeLeft = 1.0;
      _volumeRight = 1.0;
      _clearPendingUiAfterCommit();
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
    // Update chip selection immediately so UI reflects tap before async work.
    if (mounted) {
      setState(() {
        _selectedPresetId = presetId;
        _selectedPresetName = presetName;
        _currentPresetModified = false;
      });
    }
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    final adjustedGains = EqualizerBandPresets.forBandCount(gains, bandCount);

    // ── Apply band gains to hardware immediately ──────────────────────────
    for (var i = 0; i < bandCount; i++) {
      final gain = adjustedGains[i].clamp(
        params.minDecibels,
        params.maxDecibels,
      );
      await params.bands[i].setGain(gain);
    }
    // So band sliders animate to preset values even if gainStream doesn't emit.
    if (mounted) {
      setState(() => _targetBandGains = List<double>.from(adjustedGains));
    }
    // Always enable EQ hardware when applying a preset so audio is affected.
    await eq.setEnabled(true);

    // ── Apply preset effects to hardware for preview only ─────────────────
    // For built-in presets only. Do NOT persist to Bloc here.
    // Everything is saved permanently when user taps "Save".
    if (!presetId.startsWith('custom_')) {
      final fx = EqualizerPresetEffects.get(presetId);
      await _applyEffectValues(
        fx.echo,
        fx.virtualizer,
        fx.loudness,
        fx.bassBoost,
      );
      // Mirror effect values into local preview state so the effect sliders
      // immediately show the preset's values even before Bloc is updated.
      if (mounted) {
        setState(() {
          _previewEcho = fx.echo;
          _previewVirtualizer = fx.virtualizer;
          _previewLoudness = fx.loudness;
          _previewBassBoost = fx.bassBoost;
        });
      }
    } else {
      // Custom preset: no default effects — clear preview so sliders fall back
      // to the last persisted Bloc values.
      if (mounted) {
        setState(() {
          _previewEcho = null;
          _previewVirtualizer = null;
          _previewLoudness = null;
          _previewBassBoost = null;
        });
      }
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  bool _isNavigating = false;

  Future<void> _navigateBack() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final eqState = context.read<EqualizerBloc>().state;
    final shouldRevert = _hasPendingSave(eqState) || _currentPresetModified;

    if (Platform.isAndroid) {
      if (_viewportStage != _EqualizerViewportStage.portraitShell) {
        setState(() => _viewportStage = _EqualizerViewportStage.portraitShell);
        await Future<void>.delayed(_stageTransitionDuration);
      }
    }

    if (!mounted) return;

    if (shouldRevert) {
      await _revertHardware();
    }

    if (!mounted) return;

    if (Platform.isAndroid) {
      await _setPortraitOrientation();
      await Future<void>.delayed(_orientationSettleDuration);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Reverts hardware (band gains + effects) back to what is stored
  /// in Bloc — called when the user leaves without pressing "Save".
  Future<void> _revertHardware() async {
    final eq = _audioService.equalizer;
    if (eq == null) return;
    final saved = context.read<EqualizerBloc>().state;
    try {
      // Revert band gains to saved values.
      final params = await eq.parameters.timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('params timeout'),
      );
      final savedBandGainsMap = saved.equalizerBandGains;
      final targetGains =
          savedBandGainsMap != null && savedBandGainsMap.isNotEmpty
          ? List<double>.generate(
              params.bands.length,
              (i) => savedBandGainsMap['$i'] ?? 0.0,
            )
          : EqualizerBandPresets.forBandCount(
              _getPresetGains(saved.equalizerSavedPresetId ?? 'flat', saved),
              params.bands.length,
            );
      for (var i = 0; i < params.bands.length; i++) {
        final gain = targetGains[i].clamp(
          params.minDecibels,
          params.maxDecibels,
        );
        await params.bands[i].setGain(gain);
      }
      // Revert preset effects to saved values.
      await _applyEffectValues(
        saved.echoStrength,
        saved.virtualizerStrength,
        saved.loudnessGainMb,
        saved.bassBoostStrength,
      );
      final volumeResult = await _effectsService.setChannelVolumes(
        left: _committedVolumeLeft,
        right: _committedVolumeRight,
      );
      if (volumeResult != null) {
        unawaited(_audioService.setVolume(volumeResult.globalVolume));
      }
      if (mounted) {
        setState(() {
          _volumeLeft = _committedVolumeLeft;
          _volumeRight = _committedVolumeRight;
        });
      }
    } catch (_) {
      // Ignore errors during revert — we're leaving the screen anyway.
    }
  }

  Future<void> _onConfirmSelection(
    AndroidEqualizer eq,
    EqualizerState appState,
  ) async {
    // Always read hardware as ground truth (hardware was kept in sync during preview).
    final params = await eq.parameters;
    final bandGains = <String, double>{};
    for (var i = 0; i < params.bands.length; i++) {
      bandGains['$i'] = params.bands[i].gain;
    }
    if (!mounted) return;
    await eq.setEnabled(true);
    _commitSelectionToBloc(appState: appState, bandGains: bandGains);

    if (mounted) {
      setState(_clearPendingUiAfterCommit);
      AppCustom.showSettingsSavedToast(context);
    }
  }

  /// Undo always reverts ALL unsaved changes and returns to the last saved preset.
  Future<void> _onUndo(AndroidEqualizer eq, EqualizerState appState) async {
    final savedId = appState.equalizerSavedPresetId ?? 'flat';
    final savedName = appState.equalizerSavedPresetName ?? 'Flat';

    // Apply saved (persisted) band gains to hardware.
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    final savedBandGainsMap = appState.equalizerBandGains;
    final adjustedGains =
        savedBandGainsMap != null && savedBandGainsMap.isNotEmpty
        ? List<double>.generate(
            bandCount,
            (i) => savedBandGainsMap['$i'] ?? 0.0,
          )
        : EqualizerBandPresets.forBandCount(_getPresetGains(savedId, appState), bandCount);
    for (var i = 0; i < bandCount; i++) {
      final gain = adjustedGains[i].clamp(
        params.minDecibels,
        params.maxDecibels,
      );
      await params.bands[i].setGain(gain);
    }

    // Revert effects (echo/virtualizer/loudness/bassBoost) to saved state.
    await _applyEffectValues(
      appState.echoStrength,
      appState.virtualizerStrength,
      appState.loudnessGainMb,
      appState.bassBoostStrength,
    );
    final volumeResult = await _effectsService.setChannelVolumes(
      left: _committedVolumeLeft,
      right: _committedVolumeRight,
    );
    if (volumeResult != null) {
      unawaited(_audioService.setVolume(volumeResult.globalVolume));
    }

    if (!mounted) return;
    setState(() {
      _selectedPresetId = savedId;
      _selectedPresetName = savedName;
      _volumeLeft = _committedVolumeLeft;
      _volumeRight = _committedVolumeRight;
      _clearPendingUiAfterCommit();
      // Clear previews — hardware was reverted to saved Bloc values.
      // Target gains ensure the UI sliders animate smoothly back to saved positions
      _targetBandGains = List<double>.from(adjustedGains);
    });
  }

  Future<void> _onUpdate(
    AndroidEqualizer eq,
    EqualizerState appState,
    bool isSelectedCustom,
  ) async {
    final bloc = context.read<EqualizerBloc>();
    final params = await eq.parameters;
    final gains = <double>[for (var b in params.bands) b.gain];
    final bandGains = <String, double>{
      for (var i = 0; i < gains.length; i++) '$i': gains[i],
    };

    if (!isSelectedCustom) {
      // Built-in preset modified → prompt for a new name, save as custom.
      final saved = await _showPresetNameDialog(
        context: context,
        title: 'Save as new preset',
        initialName: '',
        getGains: () async => gains,
        applyToHardware: false,
        persistSelection: false,
        eq: eq,
      );
      if (saved == null) return;
      await eq.setEnabled(true);
      _commitSelectionToBloc(
        appState: appState,
        bandGains: bandGains,
        presetId: saved.id,
        presetName: saved.name,
      );
      if (!mounted) return;
      setState(() {
        _selectedPresetId = saved.id;
        _selectedPresetName = saved.name;
        _clearPendingUiAfterCommit();
      });
      AppCustom.showSettingsSavedToast(context);
      return;
    }

    // Custom preset modified → update gains in-place.
    await eq.setEnabled(true);
    bloc.add(EqualizerEvent.updateEqualizerPresetGains(
      id: _selectedPresetId,
      name: _selectedPresetName,
      gains: gains,
    ));
    _commitSelectionToBloc(appState: appState, bandGains: bandGains);
    if (mounted) {
      setState(_clearPendingUiAfterCommit);
      AppCustom.showSettingsSavedToast(context);
    }
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _showAddPresetDialog(
    AndroidEqualizer eq, {
    String? initialName,
  }) async {
    final saved = await _showPresetNameDialog(
      context: context,
      title: 'Add new preset',
      initialName: initialName ?? '',
      getGains: () async {
        final params = await eq.parameters;
        return EqualizerBandPresets.forBandCount(
          List<double>.from(EqualizerBandPresets.flat),
          params.bands.length,
        );
      },
      applyToHardware: true,
      eq: eq,
    );
    if (saved != null && mounted) {
      // Clear modified flag so the action bar doesn't linger after
      // a successful add — the new preset is already persisted by
      // _submitPresetName (persistSelection: true).
      setState(() {
        _selectedPresetId = saved.id;
        _selectedPresetName = saved.name;
        _currentPresetModified = false;
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
    bool persistSelection = true,
    required AndroidEqualizer eq,
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
                titlePadding: EdgeInsets.fromLTRB(16.r, 10.r, 16.r, 4.r),
                contentPadding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 8.r),
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
                        horizontal: 10.r,
                        vertical: 6.r,
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
                      persistSelection,
                      eq,
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
                      persistSelection,
                      eq,
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
    bool persistSelection,
    AndroidEqualizer eq,
  ) async {
    if (formKey.currentState?.validate() != true) return;
    final name = controller.text.trim();
    final bloc = ctx.read<EqualizerBloc>();
    final gains = await getGains();
    final params = await eq.parameters;
    final bandCount = params.bands.length;
    if (gains.length != bandCount) return;
    if (applyToHardware) {
      for (var i = 0; i < bandCount; i++) {
        final gain = gains[i].clamp(params.minDecibels, params.maxDecibels);
        await params.bands[i].setGain(gain);
      }
    }
    final bandGains = <String, double>{
      for (var i = 0; i < bandCount; i++) '$i': gains[i],
    };
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    bloc.add(
      EqualizerEvent.createEqualizerPreset(id: id, name: name, gains: gains),
    );
    if (persistSelection) {
      bloc.add(
        EqualizerEvent.persistEqualizerState(
          isEnabled: bloc.state.isEqualizerEnabled,
          bandGains: bandGains,
          presetId: id,
          presetName: name,
        ),
      );
    }
    if (ctx.mounted) {
      Navigator.pop(ctx, (id: id, name: name));
    }
  }

  Future<void> _deleteCustomPreset(
    AndroidEqualizer eq,
    EqualizerState appState,
    String presetId,
    String presetName,
    List<double> gains,
  ) async {
    if (!mounted) return;
    final wasSelected = _selectedPresetId == presetId;

    setState(() {
      _presetRemoving = (
        id: presetId,
        name: presetName,
        gains: List<double>.from(gains),
      );
      if (wasSelected) {
        _selectedPresetId = 'flat';
        _selectedPresetName = 'Flat';
      }
    });

    context.read<EqualizerBloc>().add(
      EqualizerEvent.deleteEqualizerPreset(id: presetId),
    );

    if (wasSelected) {
      final params = await eq.parameters;
      final bandCount = params.bands.length;
      final flatGains = EqualizerBandPresets.forBandCount(EqualizerBandPresets.flat, bandCount);
      final bandGains = <String, double>{};
      for (var i = 0; i < bandCount; i++) {
        final gain = flatGains[i].clamp(params.minDecibels, params.maxDecibels);
        await params.bands[i].setGain(gain);
        bandGains['$i'] = gain;
      }

      // Reset hardware effects to 0 so they match the fallback Flat preset.
      // Without this, audio keeps the old effect values while the UI shows 0.
      await _applyEffectValues(0, 0, 0, 0);

      if (mounted) {
        // Use commitSelection (not persistEqualizerState) so that effect
        // fields in the bloc are also updated to 0 atomically.
        context.read<EqualizerBloc>().add(
          EqualizerEvent.commitSelection(
            isEnabled: appState.isEqualizerEnabled,
            bandGains: bandGains,
            presetId: 'flat',
            presetName: 'Flat',
            echoStrength: 0,
            virtualizerStrength: 0,
            loudnessGainMb: 0,
            bassBoostStrength: 0,
          ),
        );
        setState(() {
          _targetBandGains = List<double>.from(flatGains);
          _previewEcho = 0;
          _previewVirtualizer = 0;
          _previewLoudness = 0;
          _previewBassBoost = 0;
          _currentPresetModified = false;
        });
      }
    }

    AppCustom.showSettingsSavedToast(context);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _presetRemoving = null);
    });
  }
}

enum _EqualizerViewportStage { portraitShell, landscapeContent }

class _EqualizerStagePage extends Page<void> {
  final Widget child;

  const _EqualizerStagePage({required this.child, required super.key});

  @override
  Route<void> createRoute(BuildContext context) {
    // The Navigator reuses this route for the same ValueKey across parent
    // setState calls, so the `pageBuilder` closure must NOT capture `child`
    // directly (it would become stale).  Instead we capture a `late` reference
    // to the route itself and read `route.settings.child` at call time.
    //
    // Flutter's Route._updateSettings already calls changedInternalState()
    // whenever the page object changes, which causes _ModalScope to rebuild
    // and invoke pageBuilder again — at which point route.settings has already
    // been updated to the latest _EqualizerStagePage with the fresh child.
    late final PageRouteBuilder<void> route;
    return route = PageRouteBuilder<void>(
      settings: this,
      transitionDuration: _EqualizerScreenState._stageTransitionDuration,
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder:
          (context, animation, secondaryAnimation) =>
              (route.settings as _EqualizerStagePage).child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(fade);
        final scale = Tween<double>(begin: 0.985, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
    );
  }
}
