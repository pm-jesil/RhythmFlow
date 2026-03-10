import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const EqualizerSectionHeaderRow({
    super.key,
    required this.onDefaultPressed,
  });

  final VoidCallback onDefaultPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.waveform,
            size: 8.sp,
            color: context.primaryStart,
          ),
          SizedBox(width: 3.w),
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
            SizedBox(width: 6.w),
            Container(
              width: 1,
              height: 10.h,
              color: context.onSurfaceVariantColor.withValues(alpha: 0.3),
            ),
            SizedBox(width: 6.w),
            Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 8.sp,
              color: context.primaryStart,
            ),
            SizedBox(width: 3.w),
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
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
  });

  final AndroidEqualizer eq;
  final EqualizerState appState;
  final VoidCallback onGainChanged;

  @override
  State<EqualizerSlidersContainer> createState() =>
      _EqualizerSlidersContainerState();
}

class _EqualizerSlidersContainerState extends State<EqualizerSlidersContainer>
    with SingleTickerProviderStateMixin {
  Future<AndroidEqualizerParameters>? _paramsFuture;
  late final AudioService _audioService;
  late final AudioEffectsService _effectsService;

  // Controls the shimmer/scan glow on container entry
  late AnimationController _containerGlowController;
  late Animation<double> _containerGlow;

  @override
  void initState() {
    super.initState();
    _audioService = getIt<AudioService>();
    _effectsService = getIt<AudioEffectsService>();
    _paramsFuture = widget.eq.parameters.timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          throw TimeoutException('Equalizer params - play audio first'),
    );

    _containerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _containerGlow = CurvedAnimation(
      parent: _containerGlowController,
      curve: Curves.easeOut,
    );
    // Slight delay so sliders animate first
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _containerGlowController.forward();
    });
  }

  @override
  void didUpdateWidget(covariant EqualizerSlidersContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eq != widget.eq) {
      _paramsFuture = widget.eq.parameters.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Equalizer params - play audio first'),
      );
    }
  }

  @override
  void dispose() {
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
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
                alpha: (context.isDark ? 0.25 : 0.18) + glow * (context.isDark ? 0.20 : 0.12),
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (context.isDark ? Colors.black : context.primaryStart)
                    .withValues(alpha: context.isDark ? 0.18 : 0.06),
                blurRadius: 8.r + glow * 4,
                offset: Offset(0, 2.h),
              ),
              BoxShadow(
                color: context.primaryStart.withValues(alpha: glow * 0.12),
                blurRadius: 14.r,
                spreadRadius: glow * 1.5,
                offset: Offset(0, 1.h),
              ),
            ],
          ),
          child: child,
        );
      },
      child: FutureBuilder<AndroidEqualizerParameters>(
        future: _paramsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Text(
                  'Play audio first to enable equalizer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 10.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  color: context.primaryStart,
                  strokeWidth: 2,
                ),
              ),
            );
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
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: EqualizerBandSlider(
                      title: formatBandFrequency(params.bands[i].centerFrequency),
                      band: params.bands[i],
                      centerFrequency: params.bands[i].centerFrequency,
                      minDb: params.minDecibels,
                      maxDb: params.maxDecibels,
                      bloc: context.read<EqualizerBloc>(),
                      bandIndex: i,
                      onGainChanged: onGainChanged,
                      staggerDelayMs: i * staggerStep,
                    ),
                  ),
                ),
              if (Platform.isAndroid) ...[
                _buildDivider(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: EqualizerBandSlider(
                      title: 'Echo',
                      subtitle: '${appState.echoStrength.round()}%',
                      value: appState.echoStrength / 100,
                      formatDisplay: (v) => '${(v * 100).round()}%',
                      staggerDelayMs: bandCount * staggerStep,
                      onChanged: (v) async {
                        final strength = (v * 100).round().clamp(0, 100);
                        if (strength > 0) {
                          // Disable PresetReverb hardware-only (not clearing
                          // its persisted chip state) so Environmental Reverb
                          // can take over for the echo effect.
                          await _effectsService.setReverbEnabled(false);
                          await _effectsService.setEnvironmentalReverb(
                            decayTime: 200 + (strength * 3),
                            reverbLevel: -2000 + (strength * 20),
                            reflectionsLevel: -1500 + (strength * 15),
                          );
                          await _effectsService
                              .setEnvironmentalReverbEnabled(true);
                        } else {
                          await _effectsService
                              .setEnvironmentalReverbEnabled(false);
                        }
                        if (context.mounted) {
                          context.read<EqualizerBloc>().add(
                                EqualizerEvent.persistAudioEffectsState(
                                  echoEnabled: strength > 0,
                                  echoStrength: strength,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: EqualizerBandSlider(
                      title: 'Virtual',
                      subtitle: '${appState.virtualizerStrength.round()}',
                      value: appState.virtualizerStrength / 1000,
                      formatDisplay: (v) => '${(v * 1000).round()}',
                      staggerDelayMs: (bandCount + 1) * staggerStep,
                      onChanged: (v) async {
                        final strength = (v * 1000).round().clamp(0, 1000);
                        await _effectsService.setVirtualizerStrength(strength);
                        await _effectsService
                            .setVirtualizerEnabled(strength > 0);
                        if (context.mounted) {
                          context.read<EqualizerBloc>().add(
                                EqualizerEvent.persistAudioEffectsState(
                                  virtualizerStrength: strength,
                                  virtualizerEnabled: strength > 0,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: EqualizerBandSlider(
                      title: 'Loud',
                      subtitle:
                          '${(appState.loudnessGainMb / 100).toStringAsFixed(1)}dB',
                      value: appState.loudnessGainMb / 1200,
                      formatDisplay: (v) =>
                          '${(v * 12).toStringAsFixed(1)}dB',
                      staggerDelayMs: (bandCount + 2) * staggerStep,
                      onChanged: (v) async {
                        final gainMb = (v * 1200).round().clamp(0, 1200);
                        await _audioService.setLoudnessGain(gainMb);
                        await _audioService.setLoudnessEnabled(gainMb > 0);
                        if (context.mounted) {
                          context.read<EqualizerBloc>().add(
                                EqualizerEvent.persistAudioEffectsState(
                                  loudnessGainMb: gainMb,
                                  loudnessEnabled: gainMb > 0,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: EqualizerBandSlider(
                      title: 'Bass',
                      subtitle: '${appState.bassBoostStrength.round()}',
                      value: appState.bassBoostStrength / 1000,
                      formatDisplay: (v) => '${(v * 1000).round()}',
                      staggerDelayMs: (bandCount + 3) * staggerStep,
                      onChanged: (v) async {
                        final strength = (v * 1000).round().clamp(0, 1000);
                        await _effectsService.setBassBoostStrength(strength);
                        await _effectsService
                            .setBassBoostEnabled(strength > 0);
                        if (context.mounted) {
                          context.read<EqualizerBloc>().add(
                                EqualizerEvent.persistAudioEffectsState(
                                  bassBoostStrength: strength,
                                  bassBoostEnabled: strength > 0,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: context.primaryStart.withValues(alpha: 0.2),
      ),
    );
  }
}
