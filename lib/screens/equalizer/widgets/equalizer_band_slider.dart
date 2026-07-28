import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';

/// Formats frequency for display (e.g. "60 Hz", "1.2k Hz").
String formatBandFrequency(double hz) {
  if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)}k Hz';
  return '${hz.round()} Hz';
}

/// Vertical equalizer band slider with premium animated fill, floating badge, and haptics.
///
/// **Band mode** (EQ frequency): provide [band], [minDb], [maxDb],
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
  final int? bandIndex;
  final VoidCallback? onGainChanged;

  /// When preset is applied, parent passes target gains so bands animate even
  /// if the band's gainStream doesn't emit. Null = use stream only.
  final double? targetGain;

  /// When user drags a band, notify parent so it can update its target list.
  final void Function(int bandIndex, double gain)? onBandGainChanged;

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
    this.bandIndex,
    this.onGainChanged,
    this.targetGain,
    this.onBandGainChanged,
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
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryOpacity;
  late Animation<Offset> _entrySlide;

  bool _isDragging = false;
  Timer? _badgeTimer;
  // Effect mode: displayed value (animates when preset changes)
  late double _smoothValue;
  // Band mode: displayed gain in dB (animates when preset applies new gains)
  double? _displayGain;
  late AnimationController _valueController;
  static const _valueAnimDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _smoothValue = widget.value ?? 0.0;
    if (widget._isBandMode && widget.band != null) {
      _displayGain = widget.band!.gain;
    }

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _valueController = AnimationController(
      vsync: this,
      duration: _valueAnimDuration,
    );

    Future.delayed(Duration(milliseconds: widget.staggerDelayMs), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void didUpdateWidget(covariant EqualizerBandSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._isBandMode && oldWidget.value != widget.value) {
      final target = (widget.value ?? 0.0).clamp(0.0, 1.0);
      _animateEffectValueTo(target);
    }
  }

  void _animateValueTo(
    double current,
    double target,
    void Function(double) onUpdate,
    double tolerance,
  ) {
    if ((current - target).abs() < tolerance) return;
    _valueController.stop();
    _valueController.reset();
    late void Function() listener;
    listener = () {
      if (!mounted) return;
      onUpdate(
        current +
            (target - current) *
                Curves.easeOutCubic.transform(_valueController.value),
      );
      if (_valueController.isCompleted) {
        _valueController.removeListener(listener);
        onUpdate(target);
      }
    };
    _valueController.addListener(listener);
    _valueController.forward();
  }

  void _animateEffectValueTo(double target) {
    _animateValueTo(
      _smoothValue,
      target,
      (val) => setState(() => _smoothValue = val),
      0.001,
    );
  }

  void _animateBandGainTo(double targetGain) {
    _animateValueTo(
      _displayGain ?? targetGain,
      targetGain,
      (val) => setState(() => _displayGain = val),
      0.01,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _valueController.dispose();
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
        final streamGain = snapshot.data ?? widget.band!.gain;
        // Parent can pass targetGain when preset is applied (stream may not emit).
        final targetGain = widget.targetGain ?? streamGain;
        _displayGain ??= targetGain;
        // Only schedule when target changed and we're not already animating
        // (otherwise every setState during animation would restart it).
        if ((_displayGain! - targetGain).abs() > 0.01 &&
            !_valueController.isAnimating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _animateBandGainTo(targetGain);
          });
        }
        final displayGain = _displayGain!;
        final range = (widget.maxDb! - widget.minDb!).clamp(0.001, 999.0);
        final t = ((displayGain - widget.minDb!) / range).clamp(0.0, 1.0);
        final label = '${displayGain.toStringAsFixed(1)} dB';
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
    return _buildSlider(context, t, label, (newT) {
      _valueController.stop();
      setState(() {
        _smoothValue = newT;
        _isDragging = true;
      });
      widget.onChanged?.call(newT);
      _startBadgeTimer();
    });
  }

  Widget _buildSlider(
    BuildContext context,
    double t,
    String badgeLabel,
    void Function(double) onValueChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.r, vertical: 4.r),
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
          SizedBox(height: 3.r),
          Text(
            widget.title,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 4.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              height: 1.0,
            ),
          ),
          if (widget.subtitle != null) ...[
            SizedBox(height: 1.r),
            Text(
              widget.subtitle!,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 3.5.sp,
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
    _valueController.stop();
    // newT=1 → top of slider → maxDb; newT=0 → bottom → minDb
    final gainValue = widget.minDb! + newT * (widget.maxDb! - widget.minDb!);
    if (mounted) setState(() => _displayGain = gainValue);
    widget.onBandGainChanged?.call(widget.bandIndex!, gainValue);
    await widget.band!.setGain(gainValue);
    if (!mounted) return;
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
    final trackW = 16.r;
    final bgW = 18.r;
    final h = availableHeight.clamp(28.r, double.infinity);
    final filledHeight = (t * h).clamp(4.r, h);
    final thumbH = 16.r;
    final thumbW = 19.r;
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
                  alpha: context.isDark ? 0.15 : 0.12,
                ),
                context.onSurfaceVariantColor.withValues(
                  alpha: context.isDark ? 0.25 : 0.18,
                ),
              ],
            ),
          ),
        ),

        // ── Filled (active) bar ───────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: isDragging ? trackW + 1.r : trackW,
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
                  alpha: isDragging ? 0.65 : 0.4,
                ),
                blurRadius: isDragging ? 12.r : 7.r,
                spreadRadius: isDragging ? 1 : 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: context.primaryEnd.withValues(alpha: 0.25),
                blurRadius: 4.r,
                offset: Offset(0, -1.r),
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
                  alpha: isDragging ? 0.9 : 0.55,
                ),
                width: isDragging ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(
                    alpha: isDragging ? 0.5 : 0.25,
                  ),
                  blurRadius: isDragging ? 8.r : 4.r,
                  spreadRadius: isDragging ? 1 : 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDark ? 0.45 : 0.18,
                  ),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.r),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 4.r,
                height: 1.5.r,
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
          bottom: thumbBottom + thumbH + 2.r,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDragging ? 1.0 : 0.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.r, vertical: 1.5.r),
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
