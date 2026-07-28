import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/screens/equalizer/widgets/equalizer_band_slider.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';
import 'package:rhythmflow/utils/services/audio_effects_service.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/core/di/injection.dart';

/// Section header row with "Frequency Bands", "Effects", and Default button.
class EqualizerSectionHeaderRow extends StatelessWidget {
  const EqualizerSectionHeaderRow({super.key, required this.onDefaultPressed});

  final VoidCallback onDefaultPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.r),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.waveform,
            size: 8.sp,
            color: context.primaryStart,
          ),
          SizedBox(width: 3.r),
          Text(
            'Frequency Bands',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 7.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              letterSpacing: 0.4,
            ),
          ),
          if (Platform.isAndroid) ...[
            SizedBox(width: 6.r),
            Container(
              width: 1,
              height: 10.r,
              color: context.onSurfaceVariantColor.withValues(alpha: 0.3),
            ),
            SizedBox(width: 6.r),
            Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 8.sp,
              color: context.primaryStart,
            ),
            SizedBox(width: 3.r),
            Text(
              'Effects',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 7.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                letterSpacing: 0.4,
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onDefaultPressed,
            child: Text(
              'Default',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 7.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliders container: frequency band sliders + effect sliders (Echo, Virtual, Loud, Bass).
/// Features staggered entry animation and a deeper glow background.
class EqualizerSlidersContainer extends StatefulWidget {
  const EqualizerSlidersContainer({
    super.key,
    required this.eq,
    required this.appState,
    required this.onGainChanged,
    this.targetBandGains,
    this.onBandGainChanged,
    this.onEffectChanged,
    this.previewEcho,
    this.previewVirtualizer,
    this.previewLoudness,
    this.previewBassBoost,
  });

  final AndroidEqualizer eq;
  final EqualizerState appState;
  final VoidCallback onGainChanged;

  /// When preset is applied, parent passes these so band sliders animate even
  /// if gainStream doesn't emit. When user drags a band, parent updates this list.
  final List<double>? targetBandGains;
  final void Function(int bandIndex, double gain)? onBandGainChanged;

  /// Called when any effect slider (echo/virtual/loud/bass) is manually moved.
  /// The parent uses this to clear its local preview values.
  final void Function({
    int? echo,
    int? virtualizer,
    int? loudness,
    int? bassBoost,
  })?
  onEffectChanged;

  /// Preview values set when a built-in preset is applied but not yet confirmed.
  /// When non-null these override appState so sliders instantly show preset values.
  final int? previewEcho;
  final int? previewVirtualizer;
  final int? previewLoudness;
  final int? previewBassBoost;

  @override
  State<EqualizerSlidersContainer> createState() =>
      _EqualizerSlidersContainerState();
}

class _EqualizerSlidersContainerState extends State<EqualizerSlidersContainer>
    with SingleTickerProviderStateMixin {
  Future<AndroidEqualizerParameters>? _paramsFuture;
  late final AudioService _audioService;
  late final AudioEffectsService _effectsService;
  StreamSubscription<PlayerState>? _playerStateSub;
  DateTime? _lastParamsRetry;
  bool _paramsLoadComplete = false;

  // Controls the shimmer/scan glow on container entry
  late AnimationController _containerGlowController;
  late Animation<double> _containerGlow;

  Future<AndroidEqualizerParameters> _createParamsFuture() {
    return widget.eq.parameters.timeout(
      const Duration(seconds: 4),
      onTimeout: () =>
          throw TimeoutException('Equalizer params - play audio first'),
    );
  }

  void _assignParamsFuture(Future<AndroidEqualizerParameters> raw) {
    // Do not chain .then() + setState here — it can confuse [FutureBuilder]
    // subscription timing; mark success in the builder when [snapshot.hasData].
    _paramsFuture = raw;
  }

  void _reloadParamsFuture() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastParamsRetry != null &&
        now.difference(_lastParamsRetry!) <
            const Duration(milliseconds: 1200)) {
      return;
    }
    _lastParamsRetry = now;
    setState(() {
      _paramsLoadComplete = false;
      _assignParamsFuture(_createParamsFuture());
    });
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted || _paramsLoadComplete) return;
    final p = state.processingState;
    if (p == ProcessingState.ready ||
        p == ProcessingState.buffering ||
        state.playing) {
      _reloadParamsFuture();
    }
  }

  @override
  void initState() {
    super.initState();
    _audioService = getIt<AudioService>();
    _effectsService = getIt<AudioEffectsService>();
    _assignParamsFuture(_createParamsFuture());

    _playerStateSub = _audioService.player.playerStateStream.listen(
      _onPlayerState,
    );

    _containerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _containerGlow = CurvedAnimation(
      parent: _containerGlowController,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _containerGlowController.forward();
    });
  }

  @override
  void didUpdateWidget(covariant EqualizerSlidersContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eq != widget.eq) {
      _paramsLoadComplete = false;
      _assignParamsFuture(_createParamsFuture());
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _containerGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _containerGlow,
      builder: (context, child) {
        final glow = _containerGlow.value;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 6.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.surfaceColor,
                context.cardColor.withValues(alpha: context.isDark ? 0.4 : 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.primaryStart.withValues(
                alpha:
                    (context.isDark ? 0.25 : 0.18) +
                    glow * (context.isDark ? 0.20 : 0.12),
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (context.isDark ? Colors.black : context.primaryStart)
                    .withValues(alpha: context.isDark ? 0.18 : 0.06),
                blurRadius: 8.r + glow * 4,
                offset: Offset(0, 2.r),
              ),
              BoxShadow(
                color: context.primaryStart.withValues(alpha: glow * 0.12),
                blurRadius: 14.r,
                spreadRadius: glow * 1.5,
                offset: Offset(0, 1.r),
              ),
            ],
          ),
          child: child,
        );
      },
      child: FutureBuilder<AndroidEqualizerParameters>(
        future: _paramsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _paramsLoadComplete = true;
          } else if (snapshot.hasError) {
            _paramsLoadComplete = false;
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.waveform,
                      size: 22.r,
                      color: context.primaryStart.withValues(alpha: 0.65),
                    ),
                    SizedBox(height: 8.r),
                    Text(
                      'Start playing a song, then return to Equalizer to fine‑tune your sound.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontSize: 9.sp,
                        fontFamily: 'Poppins',
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 12.r),
                    TextButton(
                      onPressed: _reloadParamsFuture,
                      child: Text(
                        'Try again',
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
              ),
            );
          }
          if (!snapshot.hasData) {
            return _buildParamsLoadingSkeleton(context);
          }

          final params = snapshot.data!;
          final appState = widget.appState;
          final onGainChanged = widget.onGainChanged;

          // Compute stagger: band sliders get 0, 40, 80, ... ms
          // Effect sliders (Echo/Virtual/Loud/Bass) pick up from after bands
          final bandCount = params.bands.length;
          const staggerStep = 40;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < bandCount; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.r),
                    child: EqualizerBandSlider(
                      title: formatBandFrequency(
                        params.bands[i].centerFrequency,
                      ),
                      band: params.bands[i],
                      centerFrequency: params.bands[i].centerFrequency,
                      minDb: params.minDecibels,
                      maxDb: params.maxDecibels,
                      bandIndex: i,
                      onGainChanged: onGainChanged,
                      targetGain:
                          widget.targetBandGains != null &&
                              i < widget.targetBandGains!.length
                          ? widget.targetBandGains![i]
                          : null,
                      onBandGainChanged: widget.onBandGainChanged,
                      staggerDelayMs: i * staggerStep,
                    ),
                  ),
                ),
              if (Platform.isAndroid) ...[
                _buildDivider(context),
                _buildEffectSlider(
                  context: context,
                  title: 'Echo',
                  subtitle:
                      '${(widget.previewEcho ?? appState.echoStrength).round()}%',
                  value: (widget.previewEcho ?? appState.echoStrength) / 100,
                  formatDisplay: (v) => '${(v * 100).round()}%',
                  staggerDelayMs: bandCount * staggerStep,
                  onChanged: (v) async {
                    final strength = (v * 100).round().clamp(0, 100);
                    widget.onEffectChanged?.call(echo: strength);
                    if (strength > 0) {
                      await _effectsService.setEnvironmentalReverb(
                        roomLevel: -6000 + (strength * 40),
                        decayTime: 200 + (strength * 3),
                        reverbLevel: -2000 + (strength * 20),
                        reflectionsLevel: -1500 + (strength * 15),
                      );
                      await _effectsService.setEnvironmentalReverbEnabled(true);
                    } else {
                      await _effectsService.setEnvironmentalReverbEnabled(
                        false,
                      );
                    }
                  },
                ),
                _buildEffectSlider(
                  context: context,
                  title: 'Virtual',
                  subtitle:
                      '${(widget.previewVirtualizer ?? appState.virtualizerStrength).round()}',
                  value:
                      (widget.previewVirtualizer ??
                          appState.virtualizerStrength) /
                      1000,
                  formatDisplay: (v) => '${(v * 1000).round()}',
                  staggerDelayMs: (bandCount + 1) * staggerStep,
                  onChanged: (v) async {
                    final strength = (v * 1000).round().clamp(0, 1000);
                    widget.onEffectChanged?.call(virtualizer: strength);
                    await _effectsService.setVirtualizerStrength(strength);
                  },
                ),
                _buildEffectSlider(
                  context: context,
                  title: 'Loud',
                  subtitle:
                      '${((widget.previewLoudness ?? appState.loudnessGainMb) / 100).toStringAsFixed(1)}dB',
                  value:
                      (widget.previewLoudness ?? appState.loudnessGainMb) /
                      1200,
                  formatDisplay: (v) => '${(v * 12).toStringAsFixed(1)}dB',
                  staggerDelayMs: (bandCount + 2) * staggerStep,
                  onChanged: (v) async {
                    final gainMb = (v * 1200).round().clamp(0, 1200);
                    widget.onEffectChanged?.call(loudness: gainMb);
                    await _audioService.setLoudnessGain(gainMb);
                    await _audioService.setLoudnessEnabled(gainMb > 0);
                  },
                ),
                _buildEffectSlider(
                  context: context,
                  title: 'Bass',
                  subtitle:
                      '${(widget.previewBassBoost ?? appState.bassBoostStrength).round()}',
                  value:
                      (widget.previewBassBoost ?? appState.bassBoostStrength) /
                      1000,
                  formatDisplay: (v) => '${(v * 1000).round()}',
                  staggerDelayMs: (bandCount + 3) * staggerStep,
                  onChanged: (v) async {
                    final strength = (v * 1000).round().clamp(0, 1000);
                    widget.onEffectChanged?.call(bassBoost: strength);
                    await _effectsService.setBassBoostStrength(strength);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEffectSlider({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double value,
    required String Function(double) formatDisplay,
    required int staggerDelayMs,
    required ValueChanged<double> onChanged,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.r),
        child: EqualizerBandSlider(
          title: title,
          subtitle: subtitle,
          value: value,
          formatDisplay: formatDisplay,
          staggerDelayMs: staggerDelayMs,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.r, vertical: 4.r),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: context.primaryStart.withValues(alpha: 0.2),
      ),
    );
  }

  /// Pulse skeleton while [AndroidEqualizer.parameters] is resolving (retries
  /// when playback starts via [playerStateStream]).
  Widget _buildParamsLoadingSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final h = boundedH ? constraints.maxHeight : 96.r;
        final barMax = (h * 0.42).clamp(28.r, 72.r);
        final factors = [0.55, 0.85, 0.72, 0.95, 0.62, 0.78, 0.68];
        return AnimatedBuilder(
          animation: _containerGlowController,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(
              _containerGlowController.value,
            );
            final base = context.onSurfaceVariantColor.withValues(
              alpha: context.isDark ? 0.14 : 0.09,
            );
            final hi = Color.lerp(
              base,
              context.primaryStart.withValues(
                alpha: context.isDark ? 0.22 : 0.14,
              ),
              0.35 + t * 0.4,
            )!;
            final barsRow = Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < factors.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.r),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 14.r,
                          height: (barMax * factors[i]).clamp(12.r, barMax),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [hi, base],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            final header = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14.r,
                  height: 14.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primaryStart.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(width: 10.r),
                Flexible(
                  child: Text(
                    'Connecting to audio…',
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 8.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            );
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 10.r),
              child: boundedH
                  ? Column(
                      children: [
                        header,
                        SizedBox(height: 14.r),
                        Expanded(child: barsRow),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        header,
                        SizedBox(height: 14.r),
                        SizedBox(height: barMax, child: barsRow),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
