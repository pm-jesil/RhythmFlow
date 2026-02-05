import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/logger/logger.dart';
import '../../utils/services/app_initialization_service.dart';
import 'screens/song_list_screen.dart';
import 'screens/for_you_screen.dart';
import 'screens/albums_screen.dart';
import 'screens/artists_screen.dart';
import 'screens/playlists_screen.dart';
import '../music_player/pop_up_music_player_widget.dart';

class BottomTab extends StatefulWidget {
  final int initialTabIndex;

  const BottomTab({super.key, this.initialTabIndex = 0});

  @override
  State<BottomTab> createState() => BottomTabState();
}

class BottomTabState extends State<BottomTab> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;
  late PageController _pageController;

  final AppLogger _logger = AppLogger('BottomTab');

  static const double navigationBarBorderRadius = 30.0;
  static const double iconScaleMin = 0.8;
  static const double iconScaleMax = 1.0;
  static const double scaleAnimationMax = 1.0;

  final List<IconData> _iconList = [
    CupertinoIcons.house,
    CupertinoIcons.music_note,
    CupertinoIcons.music_albums,
    CupertinoIcons.person,
    CupertinoIcons.list_bullet,
  ];

  final List<String> _tabLabels = [
    TabLabels.forYou,
    TabLabels.songs,
    TabLabels.albums,
    TabLabels.artists,
    TabLabels.playlists,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: widget.initialTabIndex);
    _logger.i(
      'BottomTab initializing with index: $_selectedIndex',
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOutCubic),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: scaleAnimationMax, end: 0.95)
        .animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _iconController.forward();
    _textController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppInitializationService.initializeApp(context).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const ForYouScreen();
      case 1:
        return const SongListScreen();
      case 2:
        return const AlbumsScreen();
      case 3:
        return const ArtistsScreen();
      case 4:
        return const PlaylistsScreen();
      default:
        return const ForYouScreen();
    }
  }

  void _syncTabUiToIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _scaleController.forward().then((_) => _scaleController.reverse());
    _iconController.reset();
    _textController.reset();
    _slideController.reset();
    Future.wait([
      _iconController.forward(),
      _textController.forward(),
      _slideController.forward(),
    ]);
  }

  void onTabTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    _syncTabUiToIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _onPageChanged(int index) {
    _syncTabUiToIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            dragStartBehavior: DragStartBehavior.down,
            physics: const _SmoothPageScrollPhysics(),
            itemCount: _iconList.length,
            itemBuilder: (context, index) {
              return _PageTransitionWrapper(
                pageIndex: index,
                controller: _pageController,
                child: _getScreen(index),
              );
            },
          ),
          const PopUpMusicPlayerWidget(),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 8.h,
            left: 16.w,
            right: 16.w,
            child: _buildTopNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      height: 55.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(navigationBarBorderRadius.r),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : context.onSurfaceColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(
          color: context.onSurfaceColor.withValues(alpha: 0.1),
          width: 0.5.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(navigationBarBorderRadius.r),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(
            side: BorderSide.none,
            borderRadius: Radius.circular(navigationBarBorderRadius.r),
          ),
          settings: LiquidGlassSettings(
            thickness: 10.0,
            blur: 3.r,
            glassColor: context.isDark
                ? const Color.fromARGB(38, 255, 255, 255)
                : const Color.fromARGB(59, 26, 25, 25),
          ),
          glassContainsChild: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _iconList.length,
              (index) => _buildTabItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _iconAnimation,
          _textAnimation,
          _scaleAnimation,
          _slideAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : scaleAnimationMax,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 13.w : 11.w,
                vertical: isSelected ? 5.h : 4.h,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? context.primaryGradient : null,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: isSelected
                        ? iconScaleMin +
                              (_iconAnimation.value *
                                  (iconScaleMax - iconScaleMin))
                        : iconScaleMax,
                    child: Transform.rotate(
                      angle: isSelected ? _iconAnimation.value * 0.1 : 0.0,
                      child: Icon(
                        _iconList[index],
                        color: isSelected
                            ? Colors.white
                            : context.onSurfaceColor.withValues(alpha: 0.7),
                        size: isSelected ? 24.sp : 22.sp,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 8.w),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: Text(
                          _tabLabels[index],
                          style: context.text.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wraps each page with scale + fade based on scroll position for an
/// attractive, smooth transition when swiping or animating between tabs.
class _PageTransitionWrapper extends StatelessWidget {
  const _PageTransitionWrapper({
    required this.pageIndex,
    required this.controller,
    required this.child,
  });

  final int pageIndex;
  final PageController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.position.hasContentDimensions) return child!;
        final page = controller.page ?? pageIndex.toDouble();
        final delta = (page - pageIndex).abs().clamp(0.0, 1.0);
        final scale = 1.0 - (delta * 0.04);
        final opacity = (1.0 - (delta * 0.15)).clamp(0.0, 1.0);
        return Transform.scale(
          alignment: Alignment.center,
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Makes horizontal tab swipe feel smoother: page follows finger more
/// and a light swipe is enough to move to the next tab. Keeps PageScrollPhysics
/// so pages still snap correctly.
class _SmoothPageScrollPhysics extends PageScrollPhysics {
  const _SmoothPageScrollPhysics({super.parent});

  @override
  _SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SmoothPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * 1.2;
  }
}
