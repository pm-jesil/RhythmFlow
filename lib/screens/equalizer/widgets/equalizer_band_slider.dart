import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';
import 'package:rhythmflow/screens/equalizer/bloc/equalizer_bloc.dart';

/// Formats frequency for display (e.g. "60 Hz", "1.2k Hz").
String formatBandFrequency(double hz) {
  if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)}k Hz';
  return '${hz.round()} Hz';
}

/// Vertical equalizer band slider with premium animated fill, floating badge, and haptics.
///
/// **Band mode** (EQ frequency): provide [band], [minDb], [maxDb], [bloc],
/// [bandIndex], [onGainChanged].
///
/// **Effect mode** (Echo/Virtual/Loud/Bass): provide [value], [onChanged],
/// [formatDisplay].
class EqualizerBandSlider extends StatefulWidget {
  final String title;
  final String? subtitle;

  // Band mode (EQ frequency band)
  final AndroidEqualizerBand? band;
  final double? centerFrequency;
  final double? minDb;
  final double? maxDb;
  final EqualizerBloc? bloc;
  final int? bandIndex;
  final VoidCallback? onGainChanged;

  // Effect mode
  final double? value;
  final ValueChanged<double>? onChanged;
  final String Function(double)? formatDisplay;

  /// Stagger delay for entry animation (ms per slider index)
  final int staggerDelayMs;

  const EqualizerBandSlider({
    super.key,
    required this.title,
    this.subtitle,
    this.band,
    this.centerFrequency,
    this.minDb,
    this.maxDb,
    this.bloc,
    this.bandIndex,
    this.onGainChanged,
    this.value,
    this.onChanged,
    this.formatDisplay,
    this.staggerDelayMs = 0,
  });

  bool get _isBandMode => band != null;

  @override
  State<EqualizerBandSlider> createState() => _EqualizerBandSliderState();
}

class _EqualizerBandSliderState extends State<EqualizerBandSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryOpacity;
  late Animation<Offset> _entrySlide;

  bool _isDragging = false;
  Timer? _badgeTimer;
  // For smooth spring animation in effect mode
  late double _smoothValue;

  @override
  void initState() {
    super.initState();
    _smoothValue = widget.value ?? 0.0;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.staggerDelayMs), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void didUpdateWidget(covariant EqualizerBandSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._isBandMode && oldWidget.value != widget.value) {
      // Animate smoothly to new value for effect sliders
      setState(() => _smoothValue = widget.value ?? 0.0);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _startBadgeTimer() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isDragging = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryOpacity,
      child: SlideTransition(
        position: _entrySlide,
        child: widget._isBandMode ? _buildBandMode() : _buildEffectMode(),
      ),
    );
  }

  Widget _buildBandMode() {
    return StreamBuilder<double>(
      stream: widget.band!.gainStream,
      initialData: widget.band!.gain,
      builder: (context, snapshot) {
        final gain = snapshot.data ?? widget.band!.gain;
        final range = (widget.maxDb! - widget.minDb!).clamp(0.001, 999.0);
        final t = ((gain - widget.minDb!) / range).clamp(0.0, 1.0);
        final label = '${gain.toStringAsFixed(1)} dB';
        return _buildSlider(
          context,
          t,
          label,
          (newT) => _handleBandDrag(context, newT),
        );
      },
    );
  }

  Widget _buildEffectMode() {
    final t = _smoothValue.clamp(0.0, 1.0);
    final label = widget.formatDisplay != null
        ? widget.formatDisplay!(t)
        : '${(t * 100).round()}%';
    return _buildSlider(
      context,
      t,
      label,
      (newT) {
        setState(() {
          _smoothValue = newT;
          _isDragging = true;
        });
        widget.onChanged?.call(newT);
        _startBadgeTimer();
      },
    );
  }

  Widget _buildSlider(
    BuildContext context,
    double t,
    String badgeLabel,
    void Function(double) onValueChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) {
                    setState(() => _isDragging = true);
                    HapticFeedback.lightImpact();
                  },
                  onVerticalDragUpdate: (d) {
                    final ly = d.localPosition.dy;
                    final newT = (1 - ly / h).clamp(0.0, 1.0);
                    HapticFeedback.selectionClick();
                    onValueChanged(newT);
                    if (!_isDragging) setState(() => _isDragging = true);
                    _startBadgeTimer();
                  },
                  onVerticalDragEnd: (_) => _startBadgeTimer(),
                  onTapDown: (d) {
                    final ly = d.localPosition.dy;
                    final newT = (1 - ly / h).clamp(0.0, 1.0);
                    HapticFeedback.lightImpact();
                    setState(() => _isDragging = true);
                    onValueChanged(newT);
                    _startBadgeTimer();
                  },
                  child: _PremiumSliderTrack(
                    t: t,
                    isDragging: _isDragging,
                    badgeLabel: badgeLabel,
                    availableHeight: h,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            widget.title,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 6.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              height: 1.0,
            ),
          ),
          if (widget.subtitle != null) ...[
            SizedBox(height: 1.h),
            Text(
              widget.subtitle!,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 4.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleBandDrag(BuildContext context, double newT) async {
    // newT=1 → top of slider → maxDb; newT=0 → bottom → minDb
    final gainValue = widget.minDb! + newT * (widget.maxDb! - widget.minDb!);
    await widget.band!.setGain(gainValue);
    final state = widget.bloc!.state;
    final existing = Map<String, double>.from(state.equalizerBandGains ?? {});
    existing['${widget.bandIndex}'] = gainValue;
    widget.bloc!.add(
      EqualizerEvent.persistEqualizerState(
        isEnabled: state.isEqualizerEnabled,
        bandGains: existing,
      ),
    );
    widget.onGainChanged?.call();
  }
}

// ── Premium Slider Track ──────────────────────────────────────────────────────

class _PremiumSliderTrack extends StatelessWidget {
  final double t;
  final bool isDragging;
  final String badgeLabel;
  final double availableHeight;

  const _PremiumSliderTrack({
    required this.t,
    required this.isDragging,
    required this.badgeLabel,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final trackW = 7.w;
    final bgW = 9.w;
    final h = availableHeight.clamp(28.0, double.infinity);
    final filledHeight = (t * h).clamp(3.0, h);
    final thumbH = 14.h;
    final thumbW = 12.w;
    // Position thumb so its center sits at the fill top
    final thumbBottom = (filledHeight - thumbH / 2).clamp(0.0, h - thumbH);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // ── Track background ──────────────────────────────────────────────
        Container(
          width: bgW,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.r),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.onSurfaceVariantColor.withValues(
                    alpha: context.isDark ? 0.15 : 0.12),
                context.onSurfaceVariantColor.withValues(
                    alpha: context.isDark ? 0.25 : 0.18),
              ],
            ),
          ),
        ),

        // ── Filled (active) bar ───────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: isDragging ? trackW + 1.w : trackW,
          height: filledHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [context.primaryStart, context.primaryEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryStart.withValues(
                    alpha: isDragging ? 0.65 : 0.4),
                blurRadius: isDragging ? 12.r : 7.r,
                spreadRadius: isDragging ? 1 : 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: context.primaryEnd.withValues(alpha: 0.25),
                blurRadius: 4.r,
                offset: Offset(0, -1.h),
              ),
            ],
          ),
        ),

        // ── Thumb (pill shape) ────────────────────────────────────────────
        Positioned(
          bottom: thumbBottom,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: thumbW,
            height: thumbH,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFF3A3A50), const Color(0xFF252535)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFE8ECF2)],
              ),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: context.primaryStart.withValues(
                    alpha: isDragging ? 0.9 : 0.55),
                width: isDragging ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(
                      alpha: isDragging ? 0.5 : 0.25),
                  blurRadius: isDragging ? 8.r : 4.r,
                  spreadRadius: isDragging ? 1 : 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: context.isDark ? 0.45 : 0.18),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 4.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: context.primaryStart.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1.r),
                ),
              ),
            ),
          ),
        ),

        // ── Floating dB badge ─────────────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          bottom: thumbBottom + thumbH + 2.h,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDragging ? 1.0 : 0.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.primaryStart, context.primaryEnd],
                ),
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryStart.withValues(alpha: 0.4),
                    blurRadius: 6.r,
                  ),
                ],
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 4.5.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
