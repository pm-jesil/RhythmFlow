import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';

class WaveCard extends StatefulWidget {
  const WaveCard({super.key});

  @override
  State<WaveCard> createState() => WaveCardState();
}

class WaveCardState extends State<WaveCard>
    with SingleTickerProviderStateMixin {
  late String _bgImage;

  static const _darkImages = [
    'assets/images/equalizer_bg_dark1.jpg',
    'assets/images/equalizer_bg_dark2.png',
    'assets/images/equalizer_bg_dark3.jpg',
  ];

  static const _lightImages = [
    'assets/images/equalizer_bg_light1.jpg',
    'assets/images/equalizer_bg_light2.jpg',
    'assets/images/equalizer_bg_light3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomImage();
  }

  void _pickRandomImage() {
    _bgImage = _darkImages[Random().nextInt(_darkImages.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick image set that matches the current theme
    final images = context.isDark ? _darkImages : _lightImages;
    _bgImage = images[Random().nextInt(images.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final textPrimary = context.onSurfaceColor;
    final textSecondary = context.onSurfaceVariantColor;
    final primaryColor = context.primaryStart;

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        image: DecorationImage(
          image: AssetImage(_bgImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            isDark
                ? Colors.black.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.55),
            isDark ? BlendMode.darken : BlendMode.lighten,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.60),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.waveform,
                color: primaryColor,
                size: 24.sp,
              ),
            ),

            SizedBox(width: 14.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Customize Equalizer',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Tune your sound',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.w,
                ),
              ),
              child: Icon(
                CupertinoIcons.chevron_right,
                color: textSecondary,
                size: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
