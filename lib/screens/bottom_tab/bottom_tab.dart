import 'package:flutter/material.dart';
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

  final AppLogger _logger = AppLogger('BottomTab');

  static const double navigationBarBorderRadius = 30.0;
  static const double iconScaleMin = 0.8;
  static const double iconScaleMax = 1.0;
  static const double scaleAnimationMax = 1.0;
  static const double shadowOpacity = 0.15;
  static const double backdropBlurSigma = 25.0;

  final List<IconData> _iconList = [
    Icons.home_rounded,
    Icons.music_note_rounded,
    Icons.album_rounded,
    Icons.person_rounded,
    Icons.queue_music_rounded,
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
    _logger.i(
      '💡 BottomTab: 🎵 Initializing BottomTab with initial index: $_selectedIndex',
    );

    // Initialize animation controllers with faster durations
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

    // Initialize animations
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

    // Start animations
    _iconController.forward();
    _textController.forward();
    _slideController.forward();

    // Initialize app with all required data (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Run initialization in background without blocking UI
        AppInitializationService.initializeApp(context).catchError((error) {
          // Silently handle initialization errors to prevent UI blocking
        });
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const ForYouScreen(),
    const SongListScreen(),
    const AlbumsScreen(),
    const ArtistsScreen(),
    const PlaylistsScreen(),
  ];

  void onTabTapped(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.lightImpact();
      _logger.i('👉 User tapped on tab index: $index');

      // Instant tab switch - no delays
      setState(() {
        _selectedIndex = index;
      });

      // Quick scale animation for visual feedback (non-blocking)
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });

      // Reset and start animations (non-blocking)
      _iconController.reset();
      _textController.reset();
      _slideController.reset();

      _iconController.forward();
      _textController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _screens[_selectedIndex],

          // Pop-up Music Player Widget (appears on all screens)
          const PopUpMusicPlayerWidget(),

          // Bottom navigation overlay
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
        // Little shadow on bottom
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : context.onSurfaceColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
        // Little border on all sides
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
                  // Icon with smooth animation
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

                  // Text with slide animation
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
