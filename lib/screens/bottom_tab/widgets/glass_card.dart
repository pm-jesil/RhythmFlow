import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Container(
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? 
          (isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
        border: Border.all(
          color: isDark 
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.1),
          width: 1.w,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            spreadRadius: 0,
            offset: Offset(0, 4.h),
          ),
          if (isDark) ...[
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 20.r,
              spreadRadius: 0,
              offset: Offset(0, 2.h),
            ),
          ],
        ],
      ),
      child: child,
    );
  }
}
