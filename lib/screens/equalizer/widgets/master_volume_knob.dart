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

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 30.w : 44.w;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.primaryStart.withValues(alpha: 0.15),
                blurRadius: 7.r,
                offset: Offset(0, 3.h),
              ),
              BoxShadow(
                color: context.onSurfaceColor.withValues(alpha: 0.08),
                blurRadius: 5.r,
                offset: Offset(0, 1.h),
              ),
            ],
          ),
          margin: EdgeInsets.only(top: widget.compact ? 2.r : 6.r),
          child: Knob(
            controller: _controller,
            width: size,
            height: size,
            style: KnobStyle(
              showLabels: true,
              showMinorTickLabels: true,
              tickOffset: 4,
              labelOffset: 8,
              minorTicksPerInterval: 4,
              labelStyle: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 4.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              pointerStyle: const PointerStyle(),
              controlStyle: ControlStyle(
                backgroundColor: context.isDark
                    ? const Color(0xFF2A2A32)
                    : const Color(0xFFE8ECF2),
                shadowColor: context.primaryStart.withValues(alpha: 0.4),
                glowColor: context.primaryStart.withValues(alpha: 0.25),
                tickStyle: ControlTickStyle(
                  count: 11,
                  margin: 12,
                  width: 1.2,
                  color: context.primaryStart.withValues(alpha: 0.6),
                ),
              ),
              majorTickStyle: MajorTickStyle(
                length: 10,
                thickness: 1.5,
                color: context.primaryStart.withValues(alpha: 0.7),
                highlightColor: context.primaryEnd,
              ),
              minorTickStyle: MinorTickStyle(
                length: 5,
                thickness: 1,
                color: context.primaryStart.withValues(alpha: 0.4),
                highlightColor: context.primaryStart.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          widget.label,
          style: TextStyle(
            color: context.primaryStart,
            fontSize: 7.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 0.5.h),
        ListenableBuilder(
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
            return Text(
              text,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 6.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            );
          },
        ),
      ],
    );
  }
}
