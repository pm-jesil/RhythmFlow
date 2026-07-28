import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:knob_widget/knob_widget.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';

/// Safe value for knob (0-100), never NaN/Infinity - knob_widget crashes on bad values
double _safeKnobValue(double v) {
  if (v.isNaN || v.isInfinite || v < 0) return 0.0;
  if (v > 1) return 100.0;
  return (v * 100).clamp(0.0, 100.0);
}

/// Master volume knob using knob_widget (classic hardware-style).
/// [value] and [onChanged] use 0.0-1.0 range.
/// [formatDisplay] optionally customizes the value text (e.g. for dB).
class MasterVolumeKnob extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String Function(double normalizedValue)? formatDisplay;
  final bool compact;

  const MasterVolumeKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.formatDisplay,
    this.compact = false,
  });

  @override
  State<MasterVolumeKnob> createState() => _MasterVolumeKnobState();
}

class _MasterVolumeKnobState extends State<MasterVolumeKnob> {
  late KnobController _controller;
  bool _isSyncingFromParent = false;

  @override
  void initState() {
    super.initState();
    _controller = KnobController(
      initial: _safeKnobValue(widget.value),
      minimum: 0,
      maximum: 100,
      startAngle: -45, // bottom-left (0) - left to right along bottom
      endAngle: 225, // bottom-right (100) = 180° + 45° = 225°
      precision: 1, // allow intermediate values (e.g. 47.5)
    );
    _controller.addOnValueChangedListener(_onValueChanged);
  }

  @override
  void didUpdateWidget(covariant MasterVolumeKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.001) {
      final targetValue = _safeKnobValue(widget.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isSyncingFromParent = true;
          _controller.setCurrentValue(targetValue);
          _isSyncingFromParent = false;
        }
      });
    }
  }

  void _onValueChanged(double value) {
    if (_isSyncingFromParent) return;
    if (mounted) {
      HapticFeedback.lightImpact();
      widget.onChanged((value / 100).clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    _controller.removeOnValueChangedListener(_onValueChanged);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildKnob(double size) {
    // KnobTickPainter draws ticks starting AT the circle edge and going outward,
    // so they extend beyond the Knob widget's declared size×size bounding box.
    // We wrap the whole Stack in a SizedBox that is larger by the tick overhang
    // on each side so the FittedBox scales against the correct natural size.
    //
    // tickOverhang = tickOffset(2.r) + majorTickLength(8) + margin(4)
    final tickOverhang = 2.r + 14.0;
    final outerSize = size + 2 * tickOverhang;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        // Clip.none so the tick marks that bleed into the overhang area remain visible.
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Shadow ring behind the inner dial ────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(
                    alpha: context.isDark ? 0.14 : 0.22,
                  ),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.r),
                ),
                BoxShadow(
                  color: context.isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : context.onSurfaceColor.withValues(alpha: 0.06),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.r),
                ),
              ],
            ),
          ),
          // ── Knob widget (dial + outer tick ring) ─────────────────────────────
          Knob(
            controller: _controller,
            width: size,
            height: size,
            style: KnobStyle(
              showLabels: true,
              showMinorTickLabels: true,
              tickOffset: 2.r,
              labelOffset: 0,
              minorTicksPerInterval: 4,
              labelStyle: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 4.5.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              pointerStyle: const PointerStyle(),
              controlStyle: ControlStyle(
                backgroundColor: context.cardColor,
                shadowColor: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.35 : 0.42,
                ),
                glowColor: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.2 : 0.28,
                ),
                tickStyle: ControlTickStyle(
                  count: 11,
                  margin: 12,
                  width: 1.2.r,
                  color: context.primaryStart.withValues(
                    alpha: context.isDark ? 0.55 : 0.62,
                  ),
                ),
              ),
              majorTickStyle: MajorTickStyle(
                length: 8,
                thickness: 1.5,
                color: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.65 : 0.72,
                ),
                highlightColor: context.primaryEnd,
              ),
              minorTickStyle: MinorTickStyle(
                length: 4,
                thickness: 1,
                color: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.38 : 0.45,
                ),
                highlightColor: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.55 : 0.62,
                ),
              ),
            ),
          ),
          // ── Value + channel label centered on the inner dial ──────────────────
          // IgnorePointer so knob gestures still reach the Knob widget below.
          IgnorePointer(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final normalized = (_controller.value.current / 100).clamp(
                  0.0,
                  1.0,
                );
                final text = widget.formatDisplay != null
                    ? widget.formatDisplay!(normalized)
                    : _controller.value.current.toStringAsFixed(
                        _controller.value.current ==
                                _controller.value.current.roundToDouble()
                            ? 0
                            : 1,
                      );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 6.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        height: 1.1,
                      ),
                    ),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: context.primaryStart,
                        fontSize: 5.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.1,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 88.r : 110.r;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;
        if (maxH.isFinite && maxH > 0 && maxW.isFinite && maxW > 0) {
          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: _buildKnob(size),
          );
        }
        return _buildKnob(size);
      },
    );
  }
}
