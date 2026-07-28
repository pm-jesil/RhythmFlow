import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../widgets/custom_3d_card.dart';

class ForYouAppIntroWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const ForYouAppIntroWidget({super.key, required this.onComplete});

  @override
  State<ForYouAppIntroWidget> createState() => _ForYouAppIntroWidgetState();
}

class _ForYouAppIntroWidgetState extends State<ForYouAppIntroWidget>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  late final AnimationController _heroController;
  Timer? _previewPulseTimer;
  Timer? _autoNextTimer;
  int _currentPage = 0;
  bool _previewPulse = false;

  final List<_IntroFeatureData> _features = const [
    _IntroFeatureData(
      title: 'Equalizer Tuning',
      subtitle:
          'Shape bass, mids, and treble with live controls and instant audio preview.',
      icon: CupertinoIcons.slider_horizontal_3,
      cardTag: 'eq',
      locationHint: 'For You -> Customize Equalizer',
    ),
    _IntroFeatureData(
      title: 'AI And Normal Shuffle',
      subtitle:
          'Switch between smart AI suggestions and classic random shuffle anytime.',
      icon: CupertinoIcons.shuffle,
      cardTag: 'shuffle',
      locationHint: 'Settings -> AI Shuffle',
    ),
    _IntroFeatureData(
      title: 'Swipe In Player',
      subtitle:
          'Swipe left or right on the now-playing artwork to jump tracks quickly.',
      icon: CupertinoIcons.arrow_left_right,
      cardTag: 'swipe',
      locationHint: 'Now Playing Screen',
    ),
    _IntroFeatureData(
      title: 'Long-Press Actions',
      subtitle:
          'Long press a song row to open quick actions like share, info, and playlist.',
      icon: Icons.touch_app,
      cardTag: 'longPress',
      locationHint: 'Songs List',
    ),
    _IntroFeatureData(
      title: 'Settings Control',
      subtitle:
          'Adjust theme, sleep timer, AI analysis, and equalizer preferences.',
      icon: CupertinoIcons.gear_alt_fill,
      cardTag: 'settings',
      locationHint: 'Settings Screen',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _startPreviewPulse();
    _scheduleAutoNext();
  }

  void _startPreviewPulse() {
    _previewPulseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _previewPulse = !_previewPulse);
    });
  }

  // Schedule auto-advance to next card after 6 seconds.
  // Cancelled and rescheduled on any manual page change or Next tap.
  void _scheduleAutoNext() {
    _autoNextTimer?.cancel();
    // Don't auto-advance on the last card - user must tap Explore App.
    if (_currentPage >= _features.length - 1) return;
    _autoNextTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || !_pageController.hasClients) return;
      if (_currentPage >= _features.length - 1) return;
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _previewPulseTimer?.cancel();
    _heroController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextOrComplete() async {
    _autoNextTimer?.cancel();
    if (_currentPage < _features.length - 1) {
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _heroController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.sizeOf(context);
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : screenSize.width;
            final availableHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : screenSize.height * 0.82;
            final compactDialog =
                availableHeight < 620.h || availableWidth < 320.w;
            final cardWidth = availableWidth < 300.w ? availableWidth : 300.w;
            final cardPadding = compactDialog ? 12.w : 14.w;
            final pageHeight =
                (availableHeight * (compactDialog ? 0.42 : 0.46))
                    .clamp(220.h, 280.h)
                    .toDouble();

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Custom3DCard(
                    enableAnimation: true,
                    animationDelay: 0,
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactDialog ? 9.w : 10.w,
                            vertical: compactDialog ? 4.h : 5.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.primaryStart.withValues(alpha: 0.18),
                                context.primaryEnd.withValues(alpha: 0.14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(
                              color: context.primaryStart.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            'App Intro',
                            style: TextStyle(
                              color: context.onSurfaceColor,
                              fontSize: compactDialog ? 10.5.sp : 11.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(height: compactDialog ? 8.h : 10.h),
                        Text(
                          'Explore RhythmFlow Features',
                          style: TextStyle(
                            color: context.onSurfaceColor,
                            fontSize: compactDialog ? 16.5.sp : 18.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Swipe cards or tap Next to continue',
                          style: TextStyle(
                            color: context.onSurfaceVariantColor,
                            fontSize: compactDialog ? 12.sp : 12.5.sp,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: compactDialog ? 12.h : 14.h),
                        SizedBox(
                          height: pageHeight,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _features.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                              _scheduleAutoNext();
                            },
                            itemBuilder: (context, index) {
                              final feature = _features[index];
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: _FeatureCard(
                                  feature: feature,
                                  isActive: index == _currentPage,
                                  pulse: _previewPulse,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: compactDialog ? 10.h : 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _features.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: EdgeInsets.symmetric(horizontal: 3.w),
                              width: index == _currentPage ? 16.w : 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999.r),
                                color: index == _currentPage
                                    ? context.primaryStart
                                    : context.onSurfaceVariantColor.withValues(
                                        alpha: 0.35,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compactDialog ? 12.h : 14.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _nextOrComplete,
                            style: FilledButton.styleFrom(
                              backgroundColor: context.primaryStart,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: compactDialog ? 14.w : 16.w,
                                vertical: compactDialog ? 9.h : 10.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                            ),
                            child: Text(
                              _currentPage == _features.length - 1
                                  ? 'Explore App'
                                  : 'Next',
                              style: TextStyle(
                                fontSize: compactDialog ? 11.5.sp : 12.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _IntroFeatureData feature;
  final bool isActive;
  final bool pulse;

  const _FeatureCard({
    required this.feature,
    required this.isActive,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      transform: Matrix4.diagonal3Values(
        isActive ? 1.0 : 0.97,
        isActive ? 1.0 : 0.97,
        1.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [
                  context.primaryStart.withValues(alpha: 0.2),
                  context.surfaceColor.withValues(alpha: 0.96),
                ]
              : [
                  context.primaryStart.withValues(alpha: 0.12),
                  context.primaryEnd.withValues(alpha: 0.06),
                ],
        ),
        border: Border.all(
          color: context.primaryStart.withValues(alpha: isActive ? 0.38 : 0.2),
          width: isActive ? 1.2.w : 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.primaryStart.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    feature.icon,
                    color: context.primaryStart,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    feature.title,
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              feature.subtitle,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 11.5.sp,
                fontFamily: 'Poppins',
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: context.primaryStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: context.primaryStart.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                feature.locationHint,
                style: TextStyle(
                  color: context.primaryStart,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: _FeaturePreviewPlaceholder(
                tag: feature.cardTag,
                pulse: pulse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePreviewPlaceholder extends StatelessWidget {
  final String tag;
  final bool pulse;

  const _FeaturePreviewPlaceholder({required this.tag, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final pulseAlpha = pulse ? 0.28 : 0.14;
    final previewCanvas = _previewCanvasSize();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: context.onSurfaceColor.withValues(
          alpha: context.isDark ? 0.08 : 0.05,
        ),
        border: Border.all(color: context.primaryStart.withValues(alpha: 0.22)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18.w,
            top: -20.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryStart.withValues(alpha: pulseAlpha),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: previewCanvas.width,
                  height: previewCanvas.height,
                  child: _mockByTag(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Size _previewCanvasSize() {
    switch (tag) {
      case 'eq':
        return Size(188.w, 118.h);
      case 'shuffle':
        return Size(188.w, 102.h);
      case 'swipe':
        return Size(188.w, 122.h);
      case 'longPress':
        return Size(188.w, 110.h);
      case 'settings':
      default:
        return Size(188.w, 98.h);
    }
  }

  Widget _mockByTag(BuildContext context) {
    switch (tag) {
      case 'eq':
        return _buildEqualizerPreview(context);
      case 'shuffle':
        return _buildShufflePreview(context);
      case 'swipe':
        return _buildSwipePreview(context);
      case 'longPress':
        return _buildLongPressPreview(context);
      case 'settings':
      default:
        return _buildSettingsPreview(context);
    }
  }

  Widget _buildEqualizerPreview(BuildContext context) {
    final barHeights = pulse
        ? [18.0, 26.0, 34.0, 20.0, 30.0, 24.0, 32.0]
        : [32.0, 22.0, 28.0, 34.0, 20.0, 30.0, 18.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewHeader(context, CupertinoIcons.waveform, 'Equalizer'),
        SizedBox(height: 8.h),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              barHeights.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 220 + (index * 35)),
                    curve: Curves.easeOutCubic,
                    height: barHeights[index].h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          context.primaryStart.withValues(alpha: 0.82),
                          context.primaryStart.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _mockChip(context, 'Rock', true),
            SizedBox(width: 6.w),
            _mockChip(context, 'Hall', false),
          ],
        ),
      ],
    );
  }

  Widget _buildShufflePreview(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 108;
        final showAnalysisRow = constraints.maxHeight >= (compact ? 98 : 122);
        final headerGap = compact ? 4.h : 8.h;
        final rowGap = compact ? 3.h : 6.h;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _previewHeader(
              context,
              CupertinoIcons.shuffle,
              'Shuffle',
              compact: compact,
            ),
            SizedBox(height: headerGap),
            _mockSwitchRow(
              context,
              icon: CupertinoIcons.sparkles,
              title: 'Enable AI Shuffle',
              enabled: pulse,
              compact: compact,
            ),
            SizedBox(height: rowGap),
            _mockSwitchRow(
              context,
              icon: CupertinoIcons.shuffle,
              title: 'Enable Normal Shuffle',
              enabled: !pulse,
              compact: compact,
            ),
            if (showAnalysisRow) ...[
              SizedBox(height: rowGap),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: compact ? 4.h : 7.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: context.onSurfaceVariantColor.withValues(alpha: 0.12),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.chart_bar,
                      size: compact ? 9.sp : 10.sp,
                      color: context.primaryStart,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Music Features Analysis',
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: compact ? 8.8.sp : 9.5.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: compact ? 8.sp : 9.sp,
                      color: context.onSurfaceVariantColor,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSwipePreview(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 110;
        final centerSize = compact ? 56.r : 72.r;
        final sideSize = compact ? 42.r : 52.r;
        final movingToRight = pulse;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _previewHeader(
              context,
              Icons.queue_music,
              'Now Playing',
              compact: compact,
            ),
            SizedBox(height: compact ? 4.h : 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: compact ? 4.h : 6.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: context.primaryStart.withValues(alpha: 0.12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.queue_music,
                    size: compact ? 9.sp : 10.sp,
                    color: context.primaryStart,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Playing queue',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: compact ? 8.8.sp : 9.5.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: compact ? 8.sp : 9.sp,
                    color: context.onSurfaceVariantColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 4.h : 8.h),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: const Alignment(-0.75, -0.2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: movingToRight ? 0.65 : 0.28,
                      child: _swipeAlbumPreviewCard(
                        context,
                        size: sideSize,
                        isSide: true,
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.75, -0.2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: movingToRight ? 0.28 : 0.65,
                      child: _swipeAlbumPreviewCard(
                        context,
                        size: sideSize,
                        isSide: true,
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: movingToRight
                        ? const Alignment(0.18, -0.2)
                        : const Alignment(-0.18, -0.2),
                    child: _swipeAlbumPreviewCard(
                      context,
                      size: centerSize,
                      isSide: false,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: compact ? 3.h : 4.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999.r),
                        color: context.onSurfaceVariantColor.withValues(
                          alpha: 0.13,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_left_right,
                            size: compact ? 8.sp : 9.sp,
                            color: context.primaryStart,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movingToRight
                                ? 'Swipe right - Previous'
                                : 'Swipe left - Next',
                            style: TextStyle(
                              color: context.onSurfaceColor,
                              fontSize: compact ? 8.1.sp : 8.8.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLongPressPreview(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _mockSongRow(context, highlighted: true),
            SizedBox(height: 7.h),
            _mockSongRow(context, highlighted: false),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            offset: pulse ? Offset.zero : const Offset(0.06, 0.03),
            child: Container(
              width: 125.w,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: context.primaryStart.withValues(alpha: 0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _contextActionRow(
                    context,
                    Icons.playlist_add,
                    'Add to Playlist',
                  ),
                  SizedBox(height: 6.h),
                  _contextActionRow(
                    context,
                    Icons.info_outline,
                    'View Song Info',
                  ),
                  SizedBox(height: 6.h),
                  _contextActionRow(context, Icons.share, 'Share Song'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPreview(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 110;
        final showPlaybackSpeedRow =
            constraints.maxHeight >= (compact ? 116 : 136);
        final headerGap = compact ? 3.h : 8.h;
        final rowGap = compact ? 3.h : 6.h;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _previewHeader(
              context,
              CupertinoIcons.gear_alt_fill,
              'Settings',
              compact: compact,
            ),
            SizedBox(height: headerGap),
            _mockSettingRow(
              context,
              icon: CupertinoIcons.moon,
              title: 'Dark Mode',
              trailing: _smallSwitch(context, pulse),
              compact: compact,
            ),
            SizedBox(height: rowGap),
            _mockDualSettingOptionsRow(context, compact: compact),
            if (showPlaybackSpeedRow) ...[
              SizedBox(height: rowGap),
              _mockSettingRow(
                context,
                icon: CupertinoIcons.speedometer,
                title: 'Playback Speed',
                trailing: Text(
                  '1.0x',
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: compact ? 8.6.sp : 9.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
                compact: compact,
              ),
            ],
            SizedBox(height: rowGap),
            _mockSettingRow(
              context,
              icon: CupertinoIcons.waveform,
              title: 'Equalizer',
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: compact ? 8.sp : 9.sp,
                color: context.onSurfaceVariantColor,
              ),
              compact: compact,
            ),
          ],
        );
      },
    );
  }

  Widget _mockDualSettingOptionsRow(
    BuildContext context, {
    bool compact = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: _mockQuickOptionChip(
            context,
            icon: CupertinoIcons.moon_stars,
            label: 'Sleep Timer',
            compact: compact,
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: _mockQuickOptionChip(
            context,
            icon: CupertinoIcons.chart_bar,
            label: 'AI Analysis',
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _mockQuickOptionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.w : 8.w,
        vertical: compact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: context.onSurfaceVariantColor.withValues(alpha: 0.11),
        border: Border.all(color: context.primaryStart.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 8.5.sp : 9.5.sp,
            color: context.primaryStart,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: compact ? 8.3.sp : 8.9.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewHeader(
    BuildContext context,
    IconData icon,
    String title, {
    bool compact = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: context.primaryStart, size: compact ? 9.sp : 10.sp),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: compact ? 9.2.sp : 10.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _mockSwitchRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool enabled,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7.w : 8.w,
        vertical: compact ? 4.h : 7.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: context.onSurfaceVariantColor.withValues(alpha: 0.11),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 9.sp : 10.sp, color: context.primaryStart),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: compact ? 8.6.sp : 9.3.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _smallSwitch(context, enabled),
        ],
      ),
    );
  }

  Widget _smallSwitch(BuildContext context, bool enabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 26.w,
      height: 14.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        color: enabled
            ? context.primaryStart.withValues(alpha: 0.8)
            : context.onSurfaceVariantColor.withValues(alpha: 0.35),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 8.w,
          height: 8.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _mockSongRow(BuildContext context, {required bool highlighted}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: highlighted
            ? context.primaryStart.withValues(alpha: 0.12)
            : context.onSurfaceVariantColor.withValues(alpha: 0.12),
        border: Border.all(
          color: highlighted
              ? context.primaryStart.withValues(alpha: 0.3)
              : context.onSurfaceVariantColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: context.primaryStart.withValues(alpha: 0.2),
            ),
            child: Icon(
              CupertinoIcons.music_note,
              size: 9.sp,
              color: context.primaryStart,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Container(
              height: 8.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                color: context.onSurfaceVariantColor.withValues(alpha: 0.42),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Icon(
            Icons.play_arrow_rounded,
            size: 11.sp,
            color: context.primaryStart,
          ),
        ],
      ),
    );
  }

  Widget _contextActionRow(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 10.sp, color: context.primaryStart),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 8.8.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _mockChip(BuildContext context, String text, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        color: active
            ? context.primaryStart.withValues(alpha: 0.22)
            : context.onSurfaceVariantColor.withValues(alpha: 0.15),
        border: Border.all(
          color: active
              ? context.primaryStart.withValues(alpha: 0.5)
              : context.onSurfaceVariantColor.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 8.8.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _swipeAlbumPreviewCard(
    BuildContext context, {
    required double size,
    required bool isSide,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      scale: isSide ? 0.92 : 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryStart.withValues(alpha: isSide ? 0.22 : 0.3),
              context.primaryEnd.withValues(alpha: isSide ? 0.14 : 0.2),
            ],
          ),
          border: Border.all(
            color: context.primaryStart.withValues(alpha: isSide ? 0.22 : 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSide ? 0.08 : 0.14),
              blurRadius: isSide ? 5.r : 8.r,
              offset: Offset(0, isSide ? 1.h : 2.h),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.music_note_2,
          color: context.primaryStart.withValues(alpha: isSide ? 0.75 : 0.92),
          size: isSide ? 14.sp : 18.sp,
        ),
      ),
    );
  }

  Widget _mockSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7.w : 8.w,
        vertical: compact ? 4.h : 7.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: context.onSurfaceVariantColor.withValues(alpha: 0.11),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 9.sp : 10.sp, color: context.primaryStart),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: compact ? 8.6.sp : 9.3.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _IntroFeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String cardTag;
  final String locationHint;

  const _IntroFeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cardTag,
    required this.locationHint,
  });
}
