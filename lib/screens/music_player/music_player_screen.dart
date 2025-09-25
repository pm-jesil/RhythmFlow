import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'dart:async';

import '../../../utils/logger/logger.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/router/app_router.dart';
import '../bottom_tab/screens/bloc/music_bloc.dart';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/services/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';
import 'widgets/album_art_widget_music_palyer_screen.dart';

// Main Music Player Screen (now just a placeholder since we use modal)
class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen is no longer used since we use modal popup
    // But keeping it for backward compatibility
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 64,
                color: context.onSurfaceColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Music Player',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the popup player instead',
                style: TextStyle(
                  color: context.onSurfaceColor.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Popup Music Player Modal
class MusicPlayerModal extends StatefulWidget {
  final AudioService audioService;

  const MusicPlayerModal({super.key, required this.audioService});

  @override
  State<MusicPlayerModal> createState() => _MusicPlayerModalState();

  static void show(BuildContext context, {required AudioService audioService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: false,
      builder: (context) => MusicPlayerModal(audioService: audioService),
    );
  }

  /// Alternative method to show modal with GetIt (for backward compatibility)
  static void showWithGetIt(BuildContext context) {
    final audioService = GetIt.instance<AudioService>();
    show(context, audioService: audioService);
  }
}

class _MusicPlayerModalState extends State<MusicPlayerModal>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AppLogger _logger = AppLogger('MusicPlayerModal');

  late AnimationController _slideController;

  // Progress tracking variables
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Timer? _syncTimer;

  // Getter for easy access to audio service
  AudioService get audioService => widget.audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.i('🎯 MusicPlayerModal initialized');

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Start entry animation
    _slideController.forward().then((_) {
      _logger.i('🎬 Animation completed - forcing sync');
      _forceImmediateSync();
    });

    // Initialize progress tracking
    _initializeProgressTracking();

    // IMMEDIATE state sync - don't wait for timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.i('🚀 Immediate state sync on first frame');
      _syncUIWithAudioService();
    });

    // Start periodic sync check - more frequent for better responsiveness
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _syncUIWithAudioService();
      }
    });

    // Log initial state
    _logProgressState('Init');
    _logRealTimeAudioState('Init');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _slideController.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.i('📱 App resumed - forcing immediate sync');
      _forceImmediateSync();
    }
  }

  /// Initialize progress tracking with audio service streams
  void _initializeProgressTracking() {
    _logger.i('🎯 Initializing progress tracking...');

    // Use injected audio service instance
    _logger.i('✅ Using injected audio service instance');

    // Listen to position updates with debouncing for smooth UI
    _positionSubscription = audioService.positionStream
        .debounceTime(const Duration(milliseconds: 100))
        .listen((position) {
          if (!_isSeeking && mounted) {
            // Only log when position changes significantly (every 15 seconds)
            if ((position.inSeconds % 15 == 0) &&
                (position.inSeconds != _currentPosition.inSeconds)) {
              _logger.i(
                '📊 Position update: ${position.inSeconds}s / ${_totalDuration.inSeconds}s | Progress: ${_totalDuration.inMilliseconds > 0 ? (position.inMilliseconds / _totalDuration.inMilliseconds * 100).toStringAsFixed(1) : "0.0"}%',
              );
            }
            setState(() {
              _currentPosition = position;
            });
          }
        });

    // Listen to duration updates
    _durationSubscription = audioService.durationStream.listen((duration) {
      if (mounted) {
        // Only log when duration changes
        if (duration.inSeconds != _totalDuration.inSeconds) {
          _logger.i(
            '⏱️ Duration changed: ${duration.inSeconds}s (was: ${_totalDuration.inSeconds}s)',
          );
        }

        // Safety check: ensure duration is valid
        if (duration.inMilliseconds > 0) {
          setState(() {
            _totalDuration = duration;
          });
        } else {
          _logger.w(
            '⚠️ Invalid duration received: ${duration.inMilliseconds}ms, keeping previous value',
          );
        }
      }
    });

    _logger.i('🎯 Progress tracking initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        // Force sync when bloc state changes (song changes, play/pause, etc.)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isSeeking) {
            _syncUIWithAudioService();
          }
        });

        if (state.myPlayerState.currentSongId == null) {
          _logger.w(
            '⚠️ Invalid state - closing modal | currentSongId: ${state.myPlayerState.currentSongId}',
          );
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        final currentSong = context.read<MusicBloc>().currentSong;
        if (currentSong == null) {
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _slideController.value) * 100),
              child: Hero(
                tag: 'music_player_hero', // Same hero tag for animation
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primaryStart.withValues(alpha: 0.1),
                            context.primaryEnd.withValues(alpha: 0.05),
                            context.primaryStart.withValues(alpha: 0.08),
                            context.primaryEnd.withValues(alpha: 0.12),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            // Drag Handle
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: context.onSurfaceColor.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),

                            // App Bar with Optimized Padding
                            Container(
                              margin: EdgeInsets.only(top: 10.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: context.onSurfaceColor,
                                      size: 28.sp,
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        context.navigateToPlayingQueue();
                                      },
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.queue_music,
                                              color: context.primaryStart,
                                              size: 18.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Playing queue',
                                              style: TextStyle(
                                                color: context.onSurfaceColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: context.onSurfaceColor,
                                      size: 24.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Content
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(height: 75.h),
                                  // Album Art Section - Enhanced with Swipe Animation
                                  AlbumArtWidgetOnMusicPlayerScreen(
                                    currentSong: currentSong,
                                    playlist: context
                                        .read<MusicBloc>()
                                        .currentPlayListSongs,
                                  ),

                                  // Song Info Section - Optimized Height
                                  songInfoWidget(currentSong, context),

                                  // Progress Bar Section - Optimized Height
                                  Container(
                                    height: 60.h, // Optimized height
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Progress Bar with Glass Effect
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: context.isDark
                                                    ? Colors.black.withValues(
                                                        alpha: 0.3,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                blurRadius: 8.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            child: SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                    activeTrackColor:
                                                        context.primaryStart,
                                                    inactiveTrackColor: context
                                                        .onSurfaceColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    thumbColor:
                                                        context.primaryStart,
                                                    trackHeight: 2.h,
                                                    thumbShape:
                                                        RoundSliderThumbShape(
                                                          enabledThumbRadius:
                                                              8.r,
                                                        ),
                                                    overlayShape:
                                                        RoundSliderOverlayShape(
                                                          overlayRadius: 20.r,
                                                        ),
                                                  ),
                                              child: Slider(
                                                value: _calculateSliderValue(),
                                                onChanged: _handleSeek,
                                                onChangeEnd: _handleSeekEnd,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Time Display with Simple Text
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  _currentPosition,
                                                ),
                                                style: TextStyle(
                                                  color: context.primaryStart,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(_totalDuration),
                                                style: TextStyle(
                                                  color: context.onSurfaceColor
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Controls Section - Optimized Height
                                  Container(
                                    height: 80.h, // Optimized height
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Main Control Row
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Repeat Button
                                            _buildRepeatButton(context, state),

                                            SizedBox(width: 15.w),

                                            // Previous Button
                                            _buildEnhancedControlButton(
                                              icon: Icons.skip_previous,
                                              onPressed: () {
                                                context.read<MusicBloc>().add(
                                                  const MusicEvent.playPrevious(),
                                                );
                                              },
                                              size: 45.w,
                                            ),

                                            SizedBox(width: 10.w),

                                            // Enhanced Play/Pause Button - Optimized for immediate response
                                            GestureDetector(
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                _logger.i(
                                              '🎵 Play/Pause button tapped | Current state: isPlaying=${state.myPlayerState.isPlaying} | currentSongId=${state.myPlayerState.currentSongId}',
                                                );

                                                // Log current progress state before action
                                                _logProgressState(
                                                  'Before Play/Pause',
                                                );
                                                _logRealTimeAudioState(
                                                  'Before Play/Pause',
                                                );

                                                final songId = state
                                                    .myPlayerState
                                                    .currentSongId!;
                                                final songTitle =
                                                    currentSong.title;

                                                _logger.i(
                                                  '📤 Sending playOrPause event | Song ID: $songId | Song Title: "$songTitle" | Playlist size: ${state.myPlayerState.currentPlayList.length}',
                                                );

                                                context.read<MusicBloc>().add(
                                                  MusicEvent.playOrPauseSong(
                                                    songId: songId,
                                                    currentPlayList: context
                                                        .read<MusicBloc>()
                                                        .state.myPlayerState.currentPlayList,
                                                  ),
                                                );

                                                _logger.i(
                                                  '✅ PlayOrPause event sent to bloc',
                                                );
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ), // Smooth but fast animation
                                                width: 68.w,
                                                height: 68.h,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      context.primaryGradient,
                                                  shape: BoxShape.circle,
                                                  // Simplified shadows for better performance
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: context
                                                          .primaryStart
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius:
                                                          15.r, // Reduced blur
                                                      spreadRadius:
                                                          1.r, // Reduced spread
                                                      offset: Offset(
                                                        0,
                                                        6.h,
                                                      ), // Reduced offset
                                                    ),
                                                    BoxShadow(
                                                      color: context.isDark
                                                          ? Colors.black
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                      blurRadius:
                                                          8.r, // Reduced blur
                                                      offset: Offset(
                                                        0,
                                                        3.h,
                                                      ), // Reduced offset
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: AnimatedSwitcher(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ), // Fast icon transition
                                                    child: Icon(
                                                      state.myPlayerState.isPlaying
                                                          ? Icons.pause
                                                          : Icons.play_arrow,
                                                      key: ValueKey(
                                                        state.myPlayerState.isPlaying,
                                                      ), // Ensure proper animation
                                                      color: Colors.white,
                                                      size: 32.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 10.w),

                                            // Next Button
                                            _buildEnhancedControlButton(
                                              icon: Icons.skip_next,
                                              onPressed: () {
                                                context.read<MusicBloc>().add(
                                                  const MusicEvent.playNext(),
                                                );
                                              },
                                              size: 45.w,
                                            ),

                                            SizedBox(width: 15.w),

                                            // Shuffle Button
                                            _buildEnhancedControlButton(
                                              icon: Icons.shuffle,
                                              onPressed: () {
                                                context.read<MusicBloc>().add(
                                                  MusicEvent.toggleShuffle(
                                                    isShuffle: !state.myPlayerState.isShuffle,
                                                    currentPlayList: context
                                                        .read<MusicBloc>()
                                                        .state.myPlayerState.currentPlayList,
                                                  ),
                                                );
                                              },
                                              isActive: state.myPlayerState.isShuffle,
                                              size: 37.w,
                                            ),
                                          ],
                                        ),
                                      ],
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
            );
          },
        );
      },
    );
  }

  Container songInfoWidget(Song currentSong, BuildContext context) {
    return Container(
      height: 110.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut, // Simple and smooth curve
            ),
            child: child,
          );
        },
        child: Column(
          key: ValueKey(currentSong.id), // Unique key for each song
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentSong.title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Poppins',
                shadows: [
                  Shadow(
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 2.h),
                    blurRadius: 4.r,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 3.h), // Reduced spacing

            Text(
              currentSong.artists.join(', '),
              style: TextStyle(
                color: context.onSurfaceColor.withValues(alpha: 0.8),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),

            SizedBox(height: 3.h), // Reduced spacing

            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: context.primaryStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: context.primaryStart.withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Text(
                currentSong.albums.join(', '),
                style: TextStyle(
                  color: context.primaryStart,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatButton(BuildContext context, MusicState state) {
    final repeatMode = state.myPlayerState.repeatModeIndex;
    final isActive = repeatMode > 0;

    IconData icon;
    String tooltip;

    switch (repeatMode) {
      case 0:
        icon = Icons.repeat;
        tooltip = 'Repeat Off';
        break;
      case 1:
        icon = Icons.repeat_one;
        tooltip = 'Repeat One';
        break;
      case 2:
        icon = Icons.repeat;
        tooltip = 'Loop';
        break;
      default:
        icon = Icons.repeat;
        tooltip = 'Repeat Off';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<MusicBloc>().add(const MusicEvent.toggleRepeat());
      },
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 37.w,
          height: 37.w,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryStart.withValues(alpha: 0.3),
                      context.primaryEnd.withValues(alpha: 0.2),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.onSurfaceColor.withValues(alpha: 0.15),
                      context.onSurfaceColor.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular((37.w / 2).r),
            border: Border.all(
              color: isActive
                  ? context.primaryStart.withValues(alpha: 0.6)
                  : context.onSurfaceColor.withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? context.primaryStart.withValues(alpha: 0.2)
                    : context.isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 6.r,
                offset: Offset(0, 1.h),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive
                  ? context.primaryStart
                  : context.onSurfaceColor.withValues(alpha: 0.9),
              size: (37.w * 0.5).sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), // Faster animation
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.primaryStart.withValues(alpha: 0.3),
                    context.primaryEnd.withValues(alpha: 0.2),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.onSurfaceColor.withValues(alpha: 0.15),
                    context.onSurfaceColor.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular((size / 2).r),
          border: Border.all(
            color: isActive
                ? context.primaryStart.withValues(alpha: 0.6)
                : context.onSurfaceColor.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
          // Simplified shadow for better performance
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? context.primaryStart.withValues(alpha: 0.2)
                  : context.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 6.r, // Reduced blur radius
              offset: Offset(0, 1.h), // Reduced offset
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive
                ? context.primaryStart
                : context.onSurfaceColor.withValues(alpha: 0.9),
            size: (size * 0.5).sp,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Handle seeking without haptic feedback
  void _handleSeek(double value) {
    final newPosition = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).round(),
    );

    _logger.i(
      '🔍 Seek started | Value: $value | New position: ${newPosition.inSeconds}s | Total duration: ${_totalDuration.inSeconds}s | Progress: ${(value * 100).toStringAsFixed(1)}%',
    );

    setState(() {
      _isSeeking = true;
      _currentPosition = newPosition;
    });

    _logger.i(
      '📱 UI updated during seek | Position: ${_currentPosition.inSeconds}s | Seeking: $_isSeeking',
    );
  }

  /// Handle seek completion
  void _handleSeekEnd(double value) {
    final seekPosition = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).round(),
    );

    _logger.i(
      '🔍 Seek completed | Value: $value | Position: ${seekPosition.inSeconds}s | Total duration: ${_totalDuration.inSeconds}s',
    );
    _logger.i(
      '📱 Current UI position: ${_currentPosition.inSeconds}s | Seeking flag: $_isSeeking',
    );

    context.read<MusicBloc>().add(
      MusicEvent.seekToPosition(position: seekPosition),
    );
    _logger.i(
      '📤 Seek event sent to bloc | Position: ${seekPosition.inSeconds}s',
    );

    // Reset seeking flag after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
        _logger.i('📱 Seeking flag reset to false after delay');
      } else {
        _logger.i('⏸️ Seeking flag reset skipped - widget not mounted');
      }
    });
  }

  /// Log current progress state for debugging
  void _logProgressState(String context) {
    _logger.i(
      '📊 Progress State [$context] | Position: ${_currentPosition.inSeconds}s | Duration: ${_totalDuration.inSeconds}s | Progress: ${_totalDuration.inMilliseconds > 0 ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds * 100).toStringAsFixed(1) : "0.0"}% | Seeking: $_isSeeking',
    );
  }

  /// Get real-time data from audio service
  void _logRealTimeAudioState(String context) {
    final actualPosition = audioService.position;
    final actualDuration = audioService.duration;

    // Removed verbose real-time audio state logging - only log when there are issues

    // Check for state mismatch
    if (actualPosition.inSeconds != _currentPosition.inSeconds) {
      _logger.w(
        '⚠️ Position mismatch! Audio: ${actualPosition.inSeconds}s | UI: ${_currentPosition.inSeconds}s',
      );
    }
    if (actualDuration.inSeconds != _totalDuration.inSeconds) {
      _logger.w(
        '⚠️ Duration mismatch! Audio: ${actualDuration.inSeconds}s | UI: ${_totalDuration.inSeconds}s',
      );
    }
  }

  /// Sync UI state with audio service state
  void _syncUIWithAudioService() {
    if (!_isSeeking) {
      final actualPosition = audioService.position;
      final actualDuration = audioService.duration;

      // Always sync if there's any difference (more aggressive)
      if (actualPosition.inSeconds != _currentPosition.inSeconds ||
          actualDuration.inSeconds != _totalDuration.inSeconds) {
        setState(() {
          _currentPosition = actualPosition;
          _totalDuration = actualDuration;
        });
      }
    }
  }

  /// Force immediate sync (for navigation scenarios)
  void _forceImmediateSync() {
    _logger.i('⚡ Force immediate sync requested');

    final actualPosition = audioService.position;
    final actualDuration = audioService.duration;

    setState(() {
      _currentPosition = actualPosition;
      _totalDuration = actualDuration;
      _isSeeking = false; // Reset seeking flag if stuck
    });

    _logger.i(
      '⚡ Force sync completed | Position: ${actualPosition.inSeconds}s | Duration: ${actualDuration.inSeconds}s',
    );
  }

  /// Safely calculate slider value to prevent crashes
  double _calculateSliderValue() {
    // Handle edge cases when duration is 0 or invalid
    if (_totalDuration.inMilliseconds <= 0) {
      _logger.d('📊 Slider: Duration is 0 or invalid, returning 0.0');
      return 0.0;
    }

    // Calculate progress percentage
    final progress =
        _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;

    // Ensure value is within valid range [0.0, 1.0]
    final clampedValue = progress.clamp(0.0, 1.0);

    // Log if value was clamped
    if (progress != clampedValue) {
      _logger.w(
        '⚠️ Slider: Progress value clamped from $progress to $clampedValue',
      );
    }

    // Removed verbose slider logging - only log when there are issues

    return clampedValue;
  }
}
