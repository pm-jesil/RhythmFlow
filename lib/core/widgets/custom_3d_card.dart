import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme_extension.dart';

class Custom3DCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;
  
  // Animation parameters
  final bool enableAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final double animationBegin;
  final double animationEnd;
  final int animationDelay;

  const Custom3DCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.gradient,
    this.enableAnimation = false,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.animationBegin = 0.7,
    this.animationEnd = 1.01,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      height: height,
      width: width,
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? context.surfaceColor,
            gradient: gradient ?? context.backgroundGradient,
            borderRadius: BorderRadius.circular(borderRadius ?? 10.r),
            border: border ?? Border.all(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: boxShadow ?? [
              // Default 3D effect shadows
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: Offset(0, 4.h),
                blurRadius: 12.r,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: Offset(0, 2.h),
                blurRadius: 6.r,
                spreadRadius: 0,
              ),
              // Inner shadow effect
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                offset: Offset(0, -1.h),
                blurRadius: 2.r,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(12.r),
            child: child,
          ),
        ),
      ),
    );

    // Return animated or non-animated version
    if (enableAnimation) {
      return TweenAnimationBuilder<double>(
        duration: Duration(
          milliseconds: animationDuration.inMilliseconds + (animationDelay * 200),
        ),
        tween: Tween(begin: animationBegin, end: animationEnd),
        curve: animationCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: cardWidget,
            ),
          );
        },
      );
    } else {
      return cardWidget;
    }
  }
}
