import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import 'equalizer_appbar.dart';
import 'equalizer_hero_tags.dart';

/// Portrait-stage shell: same top-bar cross-fade/slide as [EqualizerTopBar],
/// hero targets for sliders/header/bottom, full width (no narrow column in landscape).
class EqualizerPortraitTransitionShell extends StatefulWidget {
  final VoidCallback onBack;
  final bool showAddButton;
  final bool showActionBar;
  final String actionPrimaryLabel;

  const EqualizerPortraitTransitionShell({
    super.key,
    required this.onBack,
    required this.showAddButton,
    required this.showActionBar,
    required this.actionPrimaryLabel,
  });

  @override
  State<EqualizerPortraitTransitionShell> createState() =>
      _EqualizerPortraitTransitionShellState();
}

class _EqualizerPortraitTransitionShellState
    extends State<EqualizerPortraitTransitionShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = Curves.easeInOut.transform(_pulseController.value);
          final baseColor = context.onSurfaceVariantColor.withValues(
            alpha: context.isDark ? 0.18 : 0.10,
          );
          final highlightColor = Color.lerp(
            baseColor,
            context.primaryStart.withValues(
              alpha: context.isDark ? 0.28 : 0.18,
            ),
            0.55 + (pulse * 0.25),
          )!;

          return Padding(
            padding: EdgeInsets.fromLTRB(18.r, 6.r, 18.r, 18.r),
            child: Column(
              children: [
                SizedBox(
                  height: EqualizerTopBar.heightFor(context),
                  child: _buildTopBarStack(context),
                ),
                SizedBox(height: 12.r),
                Hero(
                  tag: EqualizerHeroTags.sectionHeader,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _buildSectionHeader(context),
                  ),
                ),
                SizedBox(height: 10.r),
                Expanded(
                  child: Hero(
                    tag: EqualizerHeroTags.slidersCard,
                    child: Material(
                      type: MaterialType.transparency,
                      child: _buildSlidersSkeleton(
                        context,
                        baseColor,
                        highlightColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.r),
                Hero(
                  tag: EqualizerHeroTags.bottomRow,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _buildBottomSkeleton(
                      context,
                      baseColor,
                      highlightColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Mirrors [EqualizerTopBar]: app bar vs action bar, same durations/curves.
  Widget _buildTopBarStack(BuildContext context) {
    final show = widget.showActionBar;
    final barH = EqualizerTopBar.heightFor(context);
    const curve = Curves.easeOutCubic;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          AnimatedSlide(
            duration: EqualizerHeroTags.topBarSwitchDuration,
            curve: curve,
            offset: show ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: EqualizerHeroTags.topBarFadeDuration,
              curve: Curves.easeOut,
              opacity: show ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: show,
                child: HeroMode(
                  enabled: !show,
                  child: _buildAppBarRow(context),
                ),
              ),
            ),
          ),
          AnimatedSlide(
            duration: EqualizerHeroTags.topBarSwitchDuration,
            curve: curve,
            offset: show ? Offset.zero : const Offset(0, -1),
            child: AnimatedOpacity(
              duration: EqualizerHeroTags.topBarFadeDuration,
              curve: Curves.easeOut,
              opacity: show ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !show,
                child: HeroMode(
                  enabled: show,
                  child: _buildActionBarContent(context, barH),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarRow(BuildContext context) {
    final placeholderWidth = 52.r;
    return Row(
      children: [
        Hero(
          tag: EqualizerHeroTags.backButton,
          child: Material(
            type: MaterialType.transparency,
            child: _buildChromeButton(
              context,
              icon: CupertinoIcons.back,
              onPressed: widget.onBack,
              iconColor: context.onSurfaceColor,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Hero(
              tag: EqualizerHeroTags.title,
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  'Equalizer',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ),
        widget.showAddButton
            ? Hero(
                tag: EqualizerHeroTags.addButton,
                child: Material(
                  type: MaterialType.transparency,
                  child: IgnorePointer(
                    child: _buildChromeButton(
                      context,
                      icon: CupertinoIcons.add,
                      onPressed: () {},
                      iconColor: context.primaryStart,
                    ),
                  ),
                ),
              )
            : SizedBox(width: placeholderWidth),
      ],
    );
  }

  /// Same chrome as [EqualizerActionBar] (non-interactive on shell — transition only).
  Widget _buildActionBarContent(BuildContext context, double barHeight) {
    final compact = barHeight < 58.r;
    final hPad = compact ? 14.r : 18.r;
    final vPad = compact ? 5.r : 7.r;
    final btnVPad = compact ? 4.r : 6.r;
    final radius = compact ? 8.r : 10.r;
    final gap = compact ? 6.r : 8.r;
    final fontSize = compact ? 7.sp : 8.sp;
    final minH = compact ? 22.r : 26.r;

    return SizedBox(
      height: barHeight,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: context.backgroundColor.withValues(alpha: 0.97),
            border: Border(
              bottom: BorderSide(
                color: context.primaryStart.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryStart.withValues(alpha: 0.07),
                blurRadius: 12.r,
                offset: Offset(0, 4.r),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 40,
                child: Hero(
                  tag: EqualizerHeroTags.actionUndoButton,
                  child: Material(
                    type: MaterialType.transparency,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.onSurfaceVariantColor,
                        side: BorderSide(
                          color: context.primaryStart.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                        padding: EdgeInsets.symmetric(vertical: btnVPad),
                        minimumSize: Size.fromHeight(minH),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                      child: Text(
                        'Undo',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 60,
                child: Hero(
                  tag: EqualizerHeroTags.actionPrimaryButton,
                  child: Material(
                    type: MaterialType.transparency,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.primaryStart, context.primaryEnd],
                        ),
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryStart.withValues(alpha: 0.28),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.r),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: FilledButton(
                          key: ValueKey(widget.actionPrimaryLabel),
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: btnVPad),
                            minimumSize: Size.fromHeight(minH),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                          ),
                          child: Text(
                            widget.actionPrimaryLabel,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChromeButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 10.sp),
      iconSize: 15.r,
      padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 8.r),
      style: IconButton.styleFrom(
        minimumSize: Size(44.r, 44.r),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.r),
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
          const Spacer(),
          Text(
            'Default',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 7.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidersSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 160.r;
        final bandH = short ? 56.r : 90.r;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 18.r,
            vertical: short ? 10.r : 16.r,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.surfaceColor,
                context.cardColor.withValues(
                  alpha: context.isDark ? 0.42 : 0.68,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.primaryStart.withValues(
                alpha: context.isDark ? 0.24 : 0.14,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryStart.withValues(
                  alpha: context.isDark ? 0.10 : 0.05,
                ),
                blurRadius: 12.r,
                offset: Offset(0, 4.r),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, _) {
              final factors = [0.56, 0.82, 0.70, 0.92, 0.62];
              final labelReserve = 18.r;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pulseBlock(
                    width: 104.r,
                    height: 8.r,
                    radius: 999.r,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: short ? 10.r : 16.r),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bandConstraints) {
                        final rawMax =
                            bandConstraints.maxHeight - labelReserve;
                        final cap = bandH * 0.95;
                        final maxBar = rawMax < 8.r
                            ? 8.r
                            : (rawMax > cap ? cap : rawMax);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < factors.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.r),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _pulseBlock(
                                        width: 18.r,
                                        height: (maxBar * factors[i]).clamp(
                                          6.r,
                                          maxBar,
                                        ),
                                        radius: 999.r,
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                      SizedBox(height: 8.r),
                                      _pulseBlock(
                                        width: 26.r,
                                        height: 7.r,
                                        radius: 999.r,
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: short ? 8.r : 14.r),
                  Row(
                    children: [
                      for (final width in [54.r, 46.r, 44.r, 50.r])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.r),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _pulseBlock(
                                  width: 18.r,
                                  height: short ? 28.r : 40.r,
                                  radius: 999.r,
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                                SizedBox(height: 8.r),
                                _pulseBlock(
                                  width: width,
                                  height: 7.r,
                                  radius: 999.r,
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    final h = 118.r;
    return SizedBox(
      height: h,
      child: Row(
        children: [
          _buildKnobSkeleton(context, 'L', baseColor, highlightColor),
          SizedBox(width: 10.r),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 12.r),
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(
                  alpha: context.isDark ? 0.62 : 0.80,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: context.onSurfaceVariantColor.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.music_note_list,
                        size: 8.sp,
                        color: context.primaryStart,
                      ),
                      SizedBox(width: 4.r),
                      Text(
                        'PRESETS',
                        style: TextStyle(
                          color: context.onSurfaceVariantColor,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.35,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.r),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final width in [48.r, 72.r, 56.r, 64.r, 52.r])
                              Padding(
                                padding: EdgeInsets.only(right: 8.r, top: 2.r),
                                child: _pulseBlock(
                                  width: width,
                                  height: 22.r,
                                  radius: 999.r,
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.r),
          _buildKnobSkeleton(context, 'R', baseColor, highlightColor),
        ],
      ),
    );
  }

  Widget _buildKnobSkeleton(
    BuildContext context,
    String label,
    Color baseColor,
    Color highlightColor,
  ) {
    return SizedBox(
      width: 84.r,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pulseBlock(
            width: 54.r,
            height: 54.r,
            radius: 999.r,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          SizedBox(height: 10.r),
          Text(
            label,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseBlock({
    required double width,
    required double height,
    required double radius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
        ),
      ),
    );
  }
}
