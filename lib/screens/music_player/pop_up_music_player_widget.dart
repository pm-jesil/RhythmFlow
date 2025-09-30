import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../utils/logger/logger.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/router/app_router.dart';
import '../bottom_tab/screens/bloc/music_bloc.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/custom_scrolling_text.dart';

class PopUpMusicPlayerWidget extends StatefulWidget {
  const PopUpMusicPlayerWidget({super.key});

  @override
  State<PopUpMusicPlayerWidget> createState() => _PopUpMusicPlayerWidgetState();
}

class _PopUpMusicPlayerWidgetState extends State<PopUpMusicPlayerWidget>
    with TickerProviderStateMixin {
  final AppLogger _logger = AppLogger('PopUpMusicPlayerWidget');

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _contentController;

  double _dragOffset = 0.0;
  static bool _hasAnimatedIn = false;
  String? _lastSongId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 150), // Faster content updates
      vsync: this,
    );

    // Initialize animations based on current state
    _initializeAnimations();
  }

  void _initializeAnimations() {
    if (!_isInitialized) {
      _isInitialized = true;

      // Check if we should animate in or show immediately
      if (!_hasAnimatedIn) {
        // First time ever - animate from bottom
        _slideController.forward();
        _scaleController.forward();
        _hasAnimatedIn = true;
      } else {
        // Already animated in before - show immediately
        _slideController.value = 1.0;
        _scaleController.value = 1.0;
      }
    }
  }

  // Force show mini player immediately
  void _forceShowMiniPlayer() {
    _slideController.value = 1.0;
    _scaleController.value = 1.0;
    _hasAnimatedIn = true;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final previousOffset = _dragOffset;
    setState(() {
      _dragOffset += details.delta.dy;
    });

    // Haptic feedback when crossing the threshold
    if (previousOffset <= 20 && _dragOffset > 20) {
      HapticFeedback.lightImpact();
    }

    // Haptic feedback when crossing the clear threshold
    if (previousOffset <= 30 && _dragOffset > 30) {
      HapticFeedback.mediumImpact();
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset < -30) {
      // Dragged up - threshold to trigger transition to full music player with hero animation
      HapticFeedback.mediumImpact();
      _logger.i('Dragging up to show full music player');

      // Navigate to full music player with hero animation
      context.navigateToPlaySong('');
    } else if (_dragOffset > 30) {
      // Dragged down - threshold to close popup and clear music
      HapticFeedback.mediumImpact();
      _logger.i('Dragging down to close popup and clear current song');

      // Clear current song and playlist immediately
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(isForceStop: true),
      );
      _logger.i('Current song and playlist cleared immediately');

      // Animate out the popup after clearing
      _slideController.reverse().then((_) {
        _logger.i('Pop-up music player hidden after drag down');
      });
    }

    // Reset drag offset
    setState(() {
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        // Only show mini player when music is playing or paused
        if (state.myPlayerState.currentSongId == null) {
          return const SizedBox.shrink();
        }

        // Ensure mini player is visible when state changes to playing/paused
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _forceShowMiniPlayer();
        });

        // Get current song using bloc helper
        final currentSong = context.read<MusicBloc>().currentSong;
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        // Handle content update animation only
        if (_lastSongId != null && _lastSongId != currentSong.id) {
          // Song changed - animate content update
          _lastSongId = currentSong.id;
          _contentController.forward().then((_) {
            _contentController.reverse();
          });
        } else {
          // First song or same song - set the ID
          _lastSongId ??= currentSong.id;
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_slideController, _contentController]),
          builder: (context, child) {
            return Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 73.h,
              left: 16.w,
              right: 16.w,
              child: Transform.translate(
                offset: Offset(
                  0,
                  (1 - _slideController.value) * 100 + _dragOffset,
                ),
                child: Opacity(opacity: _slideController.value, child: child),
              ),
            );
          },
          child: GestureDetector(
            onVerticalDragUpdate: _handleVerticalDragUpdate,
            onVerticalDragEnd: _handleVerticalDragEnd,
            child: Hero(
              tag: 'music_player_hero', // Hero tag for animation
              child: Transform.translate(
                offset: Offset(
                  0,
                  _dragOffset > 0 ? _dragOffset * 0.5 : -_dragOffset * 0.3,
                ),
                child: Transform.scale(
                  scale: _dragOffset > 0 ? (1.0 - (_dragOffset * 0.002)) : 1.0,
                  child: Container(
                    height: 65.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark
                              ? Colors.black.withValues(
                                  alpha: _dragOffset > 0 ? 0.2 : 0.3,
                                )
                              : context.onSurfaceColor.withValues(
                                  alpha: _dragOffset > 0 ? 0.08 : 0.05,
                                ),
                          blurRadius: _dragOffset > 0 ? 35.r : 25.r,
                          offset: Offset(0, _dragOffset > 0 ? 15.h : 10.h),
                        ),
                        BoxShadow(
                          color:
                              (_dragOffset > 0
                                      ? context.error
                                      : context.primaryStart)
                                  .withValues(
                                    alpha: _dragOffset > 0 ? 0.25 : 0,
                                  ),
                          blurRadius: _dragOffset > 0 ? 45.r : 35.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: LiquidGlass(
                        shape: LiquidRoundedSuperellipse(
                          side: BorderSide.none,
                          borderRadius: Radius.circular(16.r),
                        ),
                        settings: LiquidGlassSettings(
                          thickness: 10.0,
                          blur: 3.r,
                          glassColor: context.isDark
                              ? const Color.fromARGB(38, 255, 255, 255)
                              : const Color.fromARGB(59, 26, 25, 25),
                        ),
                        glassContainsChild: false,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.navigateToPlaySong('');
                            },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h, // Reduced padding
                                  ),
                                  child: Row(
                                    children: [
                                      // Album Art - Improved display
                                      Container(
                                        width: 50.w,
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.isDark
                                                  ? Colors.black.withValues(
                                                      alpha: 0.4,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.2,
                                                    ),
                                              blurRadius: 8.r,
                                              offset: Offset(0, 4.h),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          child: Stack(
                                            children: [
                                              // Album art with better error handling
                                              AlbumArtWidget(
                                                albumArt: currentSong.albumArt,
                                                width: 50.w,
                                                height: 50.h,
                                                borderRadius: 12.r,
                                                defaultIconSize: 15.r,
                                              ),

                                              // Glass overlay
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      context.onSurfaceColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 12.w),

                                      // Song Info - Animated content update
                                      Expanded(
                                        child: AnimatedBuilder(
                                          animation: _contentController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale:
                                                  1.0 +
                                                  (_contentController.value *
                                                      0.05),
                                              child: Opacity(
                                                opacity:
                                                    1.0 -
                                                    (_contentController.value *
                                                        0.3),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CustomScrollingText(
                                                      text: currentSong.title,
                                                      color: context.onSurfaceColor,
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w600,
                                                      cardWidth: MediaQuery.of(context).size.width - 100.w, // Account for album art and controls
                                                      isTitleScrolling: true,
                                                      height: 16.h,
                                                    ),
                                                    SizedBox(
                                                      height: 1.h,
                                                    ), // Reduced spacing
                                                    Text(
                                                      currentSong.artists.join(
                                                        ', ',
                                                      ),
                                                      style: TextStyle(
                                                        color: context
                                                            .onSurfaceColor
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        fontSize: 11
                                                            .sp, // Reduced font size
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      SizedBox(width: 12.w),

                                      // Play/Pause Button - Optimized for immediate response
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          // Add immediate visual feedback by toggling animation
                                          if (_pulseController.status ==
                                              AnimationStatus.forward) {
                                            _pulseController.stop();
                                          } else {
                                            _pulseController.repeat(
                                              reverse: true,
                                            );
                                          }

                                          context.read<MusicBloc>().add(
                                            MusicEvent.playOrPauseSong(
                                              songId: state
                                                  .myPlayerState
                                                  .currentSongId!,
                                              currentPlayList: context
                                                  .read<MusicBloc>()
                                                  .state
                                                  .myPlayerState
                                                  .currentPlayList,
                                            ),
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ), // Fast animation
                                          width: 40.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            color: context.primaryStart,
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            // Simplified shadow for better performance
                                            boxShadow: [
                                              BoxShadow(
                                                color: context.primaryStart
                                                    .withValues(
                                                      alpha: 0.25,
                                                    ), // Reduced alpha
                                                blurRadius: 6.r, // Reduced blur
                                                offset: Offset(
                                                  0,
                                                  2.h,
                                                ), // Reduced offset
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 120,
                                              ), // Fast icon transition
                                              child: Icon(
                                                state.myPlayerState.isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                key: ValueKey(
                                                  'popup_player_${state.myPlayerState.isPlaying}',
                                                ), // Unique key for popup player
                                                color: Colors.white,
                                                size: 20.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
