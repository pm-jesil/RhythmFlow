import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/core/constants/app_enums.dart';
import 'package:rhythmflow/screens/music_player/widgets/album_art_widget_music_palyer_screen.dart';
import 'dart:ui';
import 'dart:async';

import '../../../utils/logger/logger.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/router/app_router.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';
import 'widgets/playlist_selection_popup.dart';
import '../widgets/custom_scrolling_text.dart';
import '../../core/widgets/app_custom.dart';

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
    with TickerProviderStateMixin {
  final AppLogger _logger = AppLogger('MusicPlayerModal');

  late AnimationController _slideController;

  // Progress tracking variables
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Timer? _syncTimer;

  // Sliding options variables
  double _optionsSlideOffset = 0.0;
  int _currentSlideIndex = 0;
  bool _showAllOptions = false;
  bool _isDragging = false;
  double _dragStartOffset = 0.0;
  double _totalDragDistance = 0.0;
  final double _dragThreshold = 30.0;

  // Getter for easy access to audio service
  AudioService get audioService => widget.audioService;

  @override
  void initState() {
    super.initState();
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

    // Sync position/duration from audio service immediately so first frame shows correct values (avoids mismatch on open)
    final initialPosition = audioService.position;
    final initialDuration = audioService.duration;
    if (initialDuration.inMilliseconds > 0) {
      _currentPosition = initialPosition;
      _totalDuration = initialDuration;
    }

    // Log initial state
    _logProgressState('Init');
    _logRealTimeAudioState('Init');
  }

  @override
  void dispose() {
    _slideController.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
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
                                      color: context.isDark
                                          ? context.onSurfaceColor
                                          : Colors.white70,
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
                                            Container(
                                              padding: EdgeInsets.all(6.r),
                                              decoration: BoxDecoration(
                                                color: context.primaryStart
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Icon(
                                                Icons.queue_music,
                                                color: context.primaryStart,
                                                size: 18.sp,
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Playing queue',
                                                    style: TextStyle(
                                                      color: context.isDark
                                                          ? context.onSurfaceColor
                                                          : Colors.white,
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                      letterSpacing: 0.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    _nextSongSubtitle(context.read<MusicBloc>().state),
                                                    style: TextStyle(
                                                      color: context.isDark
                                                          ? context.onSurfaceColor
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : Colors.white
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                      fontSize: 10.sp,
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
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

                            // Content - use LayoutBuilder so album art height fits exactly (fixes 3.8px overflow)
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const double overflowSafety = 8;
                                  final maxH = constraints.maxHeight - overflowSafety;
                                  final fixed = 75.h + 110.h + 60.h + 80.h + 15.h + 50.h;
                                  final albumArtH = (maxH - fixed).clamp(140.0, 280.h).toDouble();
                                  return Column(
                                    children: [
                                      SizedBox(height: 75.h),
                                      AlbumArtWidgetOnMusicPlayerScreen(
                                        currentSong: currentSong,
                                        playlist: context
                                            .read<MusicBloc>()
                                            .currentPlayListSongs,
                                        height: albumArtH,
                                      ),
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
                                                    inactiveTrackColor:
                                                        context.isDark
                                                        ? context.onSurfaceColor
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : Colors.white
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
                                                  color: context.isDark
                                                      ? context.onSurfaceColor
                                                            .withValues(
                                                              alpha: 0.8,
                                                            )
                                                      : Colors.white,
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
                                              icon:
                                                  CupertinoIcons.backward_fill,
                                              onPressed: () {
                                                context.read<MusicBloc>().add(
                                                  const MusicEvent.playPrevious(),
                                                );
                                              },
                                              size: 45.w,
                                            ),

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
                                                        .state
                                                        .myPlayerState
                                                        .currentPlayList,
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
                                                    ),
                                                    child: Icon(
                                                      state
                                                              .myPlayerState
                                                              .isPlaying
                                                          ? CupertinoIcons
                                                                .pause_fill
                                                          : CupertinoIcons
                                                                .play_fill,
                                                      key: ValueKey(
                                                        'main_player_modal_${state.myPlayerState.currentSongId}_${state.myPlayerState.isPlaying}',
                                                      ),
                                                      color: Colors.white,
                                                      size: 32.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Next Button
                                            _buildEnhancedControlButton(
                                              icon: CupertinoIcons.forward_fill,
                                              onPressed: () {
                                                context.read<MusicBloc>().add(
                                                  const MusicEvent.playNext(),
                                                );
                                              },
                                              size: 45.w,
                                            ),

                                            SizedBox(width: 15.w),

                                            // Shuffle Button
                                            BlocBuilder<AppSettingsBloc, AppSettingsState>(
                                              builder: (context, appSettingsState) {
                                                final isAiShuffleEnabled = appSettingsState.isAiShuffleEnabled;
                                                final isShuffleActive = state.myPlayerState.isShuffle;
                                                final noShuffleActive = !isAiShuffleEnabled && !isShuffleActive;

                                                return _buildEnhancedControlButton(
                                                  child: _buildShuffleIcon(
                                                    isAi: isAiShuffleEnabled,
                                                    isNormal: isShuffleActive,
                                                    size: 37.w,
                                                  ),
                                                  onPressed: () {
                                                    final musicBloc = context.read<MusicBloc>();
                                                    final appSettingsBloc = context.read<AppSettingsBloc>();
                                                    final currentPlayList = musicBloc.state.myPlayerState.currentPlayList;
                                                    final currentSongId = musicBloc.state.myPlayerState.currentSongId;

                                                    if (isAiShuffleEnabled) {
                                                      // AI → Normal: disable AI, then enable regular shuffle (auto-start)
                                                      appSettingsBloc.add(
                                                        AppSettingsEvent.updateAiShuffle(isEnabled: false),
                                                      );

                                                      musicBloc.add(
                                                        MusicEvent.toggleShuffle(
                                                          isShuffle: true,
                                                          currentPlayList: currentPlayList,
                                                        ),
                                                      );
                                                    } else if (isShuffleActive) {
                                                      // Normal → None: disable regular shuffle
                                                      musicBloc.add(
                                                        MusicEvent.toggleShuffle(
                                                          isShuffle: false,
                                                          currentPlayList: currentPlayList,
                                                        ),
                                                      );
                                                    } else {
                                                      // None → AI: enable AI and trigger AI shuffle
                                                      appSettingsBloc.add(
                                                        AppSettingsEvent.updateAiShuffle(isEnabled: true),
                                                      );

                                                      if (currentSongId != null) {
                                                        musicBloc.add(
                                                          MusicEvent.aiShuffle(
                                                            currentSongId: currentSongId,
                                                            currentPlayList: currentPlayList,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  isActive: !noShuffleActive,
                                                  size: 37.w,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 15.h),
                                  // Right-aligned Sliding Bottom Options Section with Swipe Gestures
                                  Container(
                                    height: 50.h,
                                    margin: EdgeInsets.only(
                                      left: 20.w,
                                    ), // Only left margin, no right margin
                                    child: Stack(
                                      children: [
                                        // Playing Queue Button - Positioned on the left
                                        AnimatedPositioned(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          left: _showAllOptions
                                              ? -60.w
                                              : 0.w, // Move left when expanded, show when collapsed
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity: _showAllOptions
                                                ? 0.0
                                                : 1.0,
                                            child: Container(
                                              width: 40.r,
                                              height: 40.r,
                                              margin: EdgeInsets.only(
                                                left: 10.w,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    context.isDark
                                                        ? context.primaryStart
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    context.isDark
                                                        ? context.primaryStart
                                                              .withValues(
                                                                alpha: 0.08,
                                                              )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(22.r),
                                                border: Border.all(
                                                  color: context.isDark
                                                      ? context.primaryStart
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )
                                                      : Colors.white.withValues(
                                                          alpha: 0.3,
                                                        ),
                                                  width: 1.w,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: context.isDark
                                                        ? context.primaryStart
                                                              .withValues(
                                                                alpha: 0.2,
                                                              )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                    blurRadius: 8.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  // Navigate to playing queue screen
                                                  context
                                                      .navigateToPlayingQueue();
                                                },
                                                icon: Icon(
                                                  CupertinoIcons.list_bullet,
                                                  color: context.isDark
                                                      ? context.primaryStart
                                                      : Colors.white,
                                                  size: 20.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Main Options Container - Positioned on the right
                                        AnimatedPositioned(
                                          duration: _isDragging
                                              ? const Duration(
                                                  milliseconds: 0,
                                                ) // No animation during drag
                                              : const Duration(
                                                  milliseconds: 300,
                                                ), // Smooth animation when snapping
                                          curve: _isDragging
                                              ? Curves
                                                    .linear // Linear during drag
                                              : Curves
                                                    .easeOutCubic, // Smooth cubic curve for snapping
                                          right: _optionsSlideOffset,
                                          child: GestureDetector(
                                            onPanStart: (details) {
                                              // Start of drag gesture
                                              _handleDragStart();
                                            },
                                            onPanUpdate: (details) {
                                              // Handle horizontal drag gestures
                                              _handleDragGesture(
                                                details.delta.dx,
                                              );
                                            },
                                            onPanEnd: (details) {
                                              // Handle drag end
                                              _handleDragEnd(
                                                details
                                                    .velocity
                                                    .pixelsPerSecond
                                                    .dx,
                                              );
                                            },
                                            onTap: () {
                                              // Single tap to toggle expand/collapse
                                              _toggleExpandCollapse();
                                            },
                                            child: Container(
                                              height: 45.h,
                                              width: _showAllOptions
                                                  ? MediaQuery.of(
                                                          context,
                                                        ).size.width -
                                                        20.w // Full width minus left margin when expanded
                                                  : 140.w, // Show 3 icons initially (2 + arrow)
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    context.onSurfaceColor
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    context.onSurfaceColor
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    22.r,
                                                  ),
                                                  topLeft: Radius.circular(
                                                    22.r,
                                                  ),
                                                ),
                                                border: Border.all(
                                                  color: context.onSurfaceColor
                                                      .withValues(alpha: 0.1),
                                                  width: 1.w,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: context.isDark
                                                        ? Colors.black
                                                              .withValues(
                                                                alpha: 0.3,
                                                              )
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                    blurRadius: 8.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  // Left Arrow Button (part of main container) - Dynamic appearance
                                                  _buildDynamicLeftButton(
                                                    isExpanded: _showAllOptions,
                                                    onPressed: () {
                                                      if (_showAllOptions) {
                                                        // If expanded, collapse back to 3 icons
                                                        _collapseOptions();
                                                      } else {
                                                        // If collapsed, expand to show all options
                                                        _slideOptionsLeft();
                                                      }
                                                    },
                                                  ),

                                                  // Favorite Button
                                                  _buildCompactBottomButton(
                                                    icon: CupertinoIcons.heart,
                                                    activeIcon: CupertinoIcons
                                                        .heart_fill,
                                                    onPressed: () {
                                                      _toggleFavorite(
                                                        context,
                                                        currentSong,
                                                      );
                                                    },
                                                    isActive: _isFavorite(
                                                      currentSong,
                                                    ),
                                                  ),

                                                  // Playlist Button
                                                  _buildCompactBottomButton(
                                                    icon: CupertinoIcons.add,
                                                    onPressed: () {
                                                      _showCreatePlaylistDialog(
                                                        context,
                                                        currentSong,
                                                      );
                                                    },
                                                  ),

                                                  // Playback Settings Button (hidden initially)
                                                  if (_showAllOptions)
                                                    _buildCompactBottomButton(
                                                      icon: CupertinoIcons
                                                          .speedometer,
                                                      onPressed: () {
                                                        _showPlaybackSpeedDialog(
                                                          context,
                                                        );
                                                      },
                                                    ),

                                                  // Sleep Timer Button (hidden initially)
                                                  if (_showAllOptions)
                                                    _buildCompactBottomButton(
                                                      icon: CupertinoIcons.moon,
                                                      onPressed: () {
                                                        _showSleepTimerDialog(
                                                          context,
                                                        );
                                                      },
                                                    ),

                                                  // Auto Play Button (hidden initially)
                                                  if (_showAllOptions)
                                                    _buildCompactBottomButton(
                                                      icon: Icons
                                                          .play_circle_outline,
                                                      activeIcon: Icons
                                                          .play_circle_filled,
                                                      onPressed: () {
                                                        _toggleAutoplay(
                                                          context,
                                                        );
                                                      },
                                                      isActive:
                                                          _isAutoplayEnabled(),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                  );
                                },
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
            CustomScrollingText(
              text: currentSong.title,
              color: context.isDark ? context.onSurfaceColor : Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              cardWidth:
                  MediaQuery.of(context).size.width -
                  40.w, // Account for padding
              isTitleScrolling: true,
              height: 24.h,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h), // Reduced spacing

            Text(
              currentSong.artists.join(', '),
              style: TextStyle(
                color: context.isDark
                    ? context.onSurfaceColor.withValues(alpha: 0.8)
                    : Colors.white,
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
        icon = CupertinoIcons.repeat;
        tooltip = 'Repeat Off';
        break;
      case 1:
        icon = CupertinoIcons.repeat_1;
        tooltip = 'Repeat One';
        break;
      case 2:
        icon = CupertinoIcons.repeat;
        tooltip = 'Loop';
        break;
      default:
        icon = CupertinoIcons.repeat;
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
                      context.isDark
                          ? context.primaryStart.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.3),
                      context.isDark
                          ? context.primaryEnd.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.isDark
                          ? context.onSurfaceColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.15),
                      context.isDark
                          ? context.onSurfaceColor.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular((37.w / 2).r),
            border: Border.all(
              color: isActive
                  ? context.isDark
                        ? context.primaryStart.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.6)
                  : context.isDark
                  ? context.onSurfaceColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? context.isDark
                          ? context.primaryStart.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2)
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
              color: isActive ? context.primaryStart : Colors.white,
              size: (37.w * 0.5).sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedControlButton({
    IconData? icon,
    required VoidCallback onPressed,
    Widget? child,
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
                    context.isDark
                        ? context.onSurfaceColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.15),
                    context.isDark
                        ? context.onSurfaceColor.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular((size / 2).r),
          border: Border.all(
            color: isActive
                ? context.isDark
                      ? context.primaryStart.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.6)
                : context.isDark
                ? context.onSurfaceColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
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
        child:
            child ??
            Center(
              child: Icon(
                icon,
                color: isActive
                    ? context.primaryStart
                    : context.isDark
                    ? context.onSurfaceColor.withValues(alpha: 0.9)
                    : Colors.white,
                size: (size * 0.5).sp,
              ),
            ),
      ),
    );
  }

  /// Build shuffle icon with states: AI, Normal, None (crossed out)
  Widget _buildShuffleIcon({
    required bool isAi,
    required bool isNormal,
    required double size,
  }) {
    if (isAi) {
      return Center(
        child: Icon(
          CupertinoIcons.sparkles,
          color: context.primaryStart,
          size: (size * 0.5).sp,
        ),
      );
    }

    if (isNormal) {
      return Center(
        child: Icon(
          CupertinoIcons.shuffle,
          color: context.primaryStart,
          size: (size * 0.5).sp,
        ),
      );
    }

    // None: show shuffle with a diagonal cross line in inactive color
    final Color baseColor = context.isDark
        ? context.onSurfaceColor.withValues(alpha: 0.9)
        : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          CupertinoIcons.shuffle,
          color: baseColor,
          size: (size * 0.5).sp,
        ),
        Transform.rotate(
          angle: 0.8, // approx 45 degrees
          child: Container(
            width: (size * 0.55).w,
            height: 2.h,
            color: baseColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Format duration for sleep timer (minutes to human readable format)
  String _formatSleepTimerDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  // ==================== APP SETTINGS HELPER METHODS ====================

  void _updatePlaybackSettings(
    bool autoPlayNext,
    bool showNotifications,
    double playbackSpeed,
  ) {
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updatePlaybackSettings(
        autoPlayNext: autoPlayNext,
        showNotifications: showNotifications,
        playbackSpeed: playbackSpeed,
      ),
    );
  }

  void _updateSleepTimer(int minutes, bool isEnabled) {
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateSleepTimer(minutes: minutes, isEnabled: isEnabled),
    );
  }

  Widget _buildNativeSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.primaryStart, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: context.primaryStart,
            inactiveColor: context.onSurfaceVariantColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// Build native switch tile for settings
  Widget _buildNativeSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.onSurfaceColor.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: context.primaryStart, size: 22.sp),
        title: Text(
          title,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: context.primaryStart,
        inactiveThumbColor: context.onSurfaceColor.withValues(alpha: 0.3),
        inactiveTrackColor: context.onSurfaceColor.withValues(alpha: 0.1),
      ),
    );
  }

  /// Toggle autoplay setting (simple on/off)
  void _toggleAutoplay(BuildContext context) {
    HapticFeedback.lightImpact();
    final isEnabled = _isAutoplayEnabled();

    // Toggle the autoplay setting
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updatePlaybackSettings(
        autoPlayNext: !isEnabled,
        showNotifications: context
            .read<AppSettingsBloc>()
            .state
            .showNotifications,
        playbackSpeed: context.read<AppSettingsBloc>().state.playbackSpeed,
      ),
    );

    _logger.i('🔄 Autoplay toggled: ${!isEnabled}');

    AppCustom.success(
      context,
      'Auto Play ${!isEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Check if autoplay is enabled
  bool _isAutoplayEnabled() {
    return context.read<AppSettingsBloc>().state.autoPlayNext;
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

    // Log only significant mismatches (e.g. > 1s) to avoid noise on init or minor drift
    if ((actualPosition.inSeconds - _currentPosition.inSeconds).abs() > 1) {
      _logger.w(
        '⚠️ Position mismatch! Audio: ${actualPosition.inSeconds}s | UI: ${_currentPosition.inSeconds}s',
      );
    }
    if ((actualDuration.inSeconds - _totalDuration.inSeconds).abs() > 1) {
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
      return 0.0;
    }

    // Calculate progress (floating point can slightly exceed 1.0 near end of track)
    final progress =
        _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;

    // Clamp to [0.0, 1.0] - no log spam; slight overshoot is normal
    return progress.clamp(0.0, 1.0);
  }

  /// Build dynamic left button that changes appearance based on expanded state
  Widget _buildDynamicLeftButton({
    required bool isExpanded,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 35.w,
        height: 35.w,
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.isDark
                  ? context.onSurfaceColor.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.1),
              context.isDark
                  ? context.onSurfaceColor.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(17.r),
          border: Border.all(
            color: context.isDark
                ? context.onSurfaceColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 3.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isExpanded
                  ? CupertinoIcons.chevron_right
                  : CupertinoIcons.chevron_left,
              key: ValueKey('options_chevron_${isExpanded ? 'forward' : 'back'}'),
              color: context.isDark
                  ? context.onSurfaceColor.withValues(alpha: 0.8)
                  : Colors.white,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact bottom button for sliding options
  Widget _buildCompactBottomButton({
    required IconData icon,
    IconData? activeIcon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 35.w, // Reduced size
        height: 35.w, // Reduced size
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.isDark
                        ? context.primaryStart.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2),
                    context.isDark
                        ? context.primaryEnd.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.15),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.isDark
                        ? context.onSurfaceColor.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.1),
                    context.isDark
                        ? context.onSurfaceColor.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(
            17.r,
          ), // Adjusted for smaller size
          border: Border.all(
            color: isActive
                ? context.isDark
                      ? context.primaryStart.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.4)
                : context.isDark
                ? context.onSurfaceColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? context.isDark
                        ? context.primaryStart.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2)
                  : context.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 3.r, // Reduced blur
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isActive && activeIcon != null ? activeIcon : icon,
            color: isActive
                ? context.isDark
                      ? context.primaryStart
                      : Colors.white
                : context.isDark
                ? context.onSurfaceColor.withValues(alpha: 0.8)
                : Colors.white,
            size: 16.sp, // Reduced icon size
          ),
        ),
      ),
    );
  }

  /// Handle drag start with enhanced initialization
  void _handleDragStart() {
    _isDragging = true;
    _dragStartOffset = _optionsSlideOffset;
    _totalDragDistance = 0.0;
    _logger.i('🖱️ Drag gesture started at offset: $_dragStartOffset');
  }

  /// Handle horizontal drag gestures with enhanced responsiveness
  void _handleDragGesture(double deltaX) {
    _totalDragDistance += deltaX.abs(); // Track total drag distance

    if (_showAllOptions) {
      // Smooth dragging when all options are visible
      final newOffset = _dragStartOffset + deltaX;
      final maxOffset = 0.0;
      final minOffset = -(MediaQuery.of(context).size.width - 20.w - 140.w);

      // Apply smooth clamping with resistance at edges
      final clampedOffset = _applySmoothClamping(
        newOffset,
        minOffset,
        maxOffset,
      );

      setState(() {
        _optionsSlideOffset = clampedOffset;
      });
    } else {
      // Enhanced expansion logic based on drag direction and distance
      if (_totalDragDistance > _dragThreshold) {
        if (deltaX < 0) {
          // Drag left to expand and show more options
          _expandAndShowOptions();
        } else if (deltaX > 0) {
          // Drag right - could be used for other actions in the future
          _logger.i('🖱️ Dragged right - no action defined');
        }
      }
    }
  }

  /// Expand options and show all icons
  void _expandAndShowOptions() {
    setState(() {
      _showAllOptions = true;
      _optionsSlideOffset = 0.0;
      _isDragging = false;
      _totalDragDistance = 0.0;
    });
    _logger.i('🖱️ Expanded options - all icons now visible');
  }

  /// Apply smooth clamping with resistance at edges
  double _applySmoothClamping(double value, double min, double max) {
    if (value < min) {
      // Apply resistance when dragging beyond left edge
      final overshoot = min - value;
      return min - (overshoot * 0.3); // 30% resistance
    } else if (value > max) {
      // Apply resistance when dragging beyond right edge
      final overshoot = value - max;
      return max + (overshoot * 0.3); // 30% resistance
    }
    return value;
  }

  /// Handle drag end with enhanced snapping logic
  void _handleDragEnd(double velocity) {
    _isDragging = false;

    if (_showAllOptions) {
      const velocityThreshold = 60.0;
      const snapDistance = 40.0;

      // Check if user made a significant drag gesture
      if (_totalDragDistance > _dragThreshold) {
        if (velocity.abs() > velocityThreshold) {
          // Fast swipe - velocity-based snapping
          if (velocity > 0) {
            // Swipe right - go to previous position
            _smoothSlideToPosition(_currentSlideIndex + 1);
          } else {
            // Swipe left - go to next position
            _smoothSlideToPosition(_currentSlideIndex - 1);
          }
        } else {
          // Slow drag - position-based snapping
          final currentOffset = _optionsSlideOffset;

          if (currentOffset < -snapDistance) {
            _smoothSlideToPosition(_currentSlideIndex - 1);
          } else if (currentOffset > snapDistance) {
            _smoothSlideToPosition(_currentSlideIndex + 1);
          } else {
            // Snap back to current position
            _smoothSlideToPosition(_currentSlideIndex);
          }
        }
      } else {
        // Small drag - snap back to current position
        _smoothSlideToPosition(_currentSlideIndex);
      }
    } else {
      // If not expanded and drag was too small, reset
      if (_totalDragDistance < _dragThreshold) {
        _logger.i('🖱️ Small drag gesture - no action taken');
      }
    }

    // Reset drag tracking
    _totalDragDistance = 0.0;
  }

    /// Subtitle for app bar: "Next - [next song title]" or "Next - End of list"
  String _nextSongSubtitle(MusicState state) {
    final playList = state.myPlayerState.currentPlayList;
    final currentId = state.myPlayerState.currentSongId;
    final completed = state.myPlayerState.completedSongs.toSet();
    if (playList.isEmpty || currentId == null) return 'Next - End of list';
    final currentIndex = playList.indexOf(currentId);
    if (currentIndex < 0 || currentIndex >= playList.length - 1) {
      return 'Next - End of list';
    }
    for (int i = currentIndex + 1; i < playList.length; i++) {
      final id = playList[i];
      if (!completed.contains(id)) {
        try {
          final nextSong = state.allSongs.firstWhere((s) => s.id == id);
          final title = nextSong.title.trim().isEmpty ? 'Unknown' : nextSong.title;
          return 'Next - $title';
        } catch (_) {}
      }
    }
    return 'Next - End of list';
  }

  /// Smooth slide to specific position with animation
  void _smoothSlideToPosition(int targetIndex) {
    // Clamp target index to valid range
    final clampedIndex = targetIndex.clamp(0, 2);

    if (clampedIndex != _currentSlideIndex) {
      setState(() {
        _currentSlideIndex = clampedIndex;
        _optionsSlideOffset = _currentSlideIndex * -60.w;
      });
      _logger.i('🎯 Smooth sliding to position: $clampedIndex');
    } else {
      // Snap back to current position
      _snapToCurrentPosition();
    }
  }

  /// Toggle expand/collapse on single tap
  void _toggleExpandCollapse() {
    if (_showAllOptions) {
      _collapseOptions();
    } else {
      _expandAndShowOptions();
    }
  }

  /// Snap to current position
  void _snapToCurrentPosition() {
    setState(() {
      _optionsSlideOffset = _currentSlideIndex * -60.w;
    });
  }

  /// Collapse options back to initial 3-icon state
  void _collapseOptions() {
    setState(() {
      _showAllOptions = false;
      _currentSlideIndex = 0;
      _optionsSlideOffset = 0.0;
    });
    _logger.i('🔽 Collapsing options back to 3-icon state');
  }

  /// Slide options to the left (auto-expand to show all options)
  void _slideOptionsLeft() {
    if (!_showAllOptions) {
      // Auto-expand to show all options
      setState(() {
        _showAllOptions = true;
        _optionsSlideOffset = 0.0; // Right-aligned, no offset initially
      });
      _logger.i('⬅️ Auto-expanding to show all options');
    } else {
      // Manual slide left
      if (_currentSlideIndex > 0) {
        setState(() {
          _currentSlideIndex--;
          _optionsSlideOffset = _currentSlideIndex * -60.w;
        });
        _logger.i('⬅️ Sliding options left to index: $_currentSlideIndex');
      }
    }
  }

  /// Check if song is favorite
  bool _isFavorite(Song song) {
    // Check if song is in favorites playlist
    final favoritesPlaylist = context
        .read<MusicBloc>()
        .state
        .myPlaylist
        .where((playlist) => playlist.id == 'my_playlist_favorites')
        .firstOrNull;

    return favoritesPlaylist?.songIds.contains(song.id) ?? false;
  }

  /// Toggle favorite status for a song
  void _toggleFavorite(BuildContext context, Song song) {
    HapticFeedback.lightImpact();
    _logger.i('❤️ Toggle favorite for song: ${song.title}');

    // Use the new playlist event to toggle favorite
    context.read<MusicBloc>().add(
      MusicEvent.addOrUpdateMyPlayList(
        operation: MyPlaylistOperation.toggleFavorite,
        songId: song.id,
      ),
    );

    AppCustom.success(
      context,
      _isFavorite(song) ? 'Removed from favorites' : 'Added to favorites',
    );
  }

  /// Show comprehensive playlist selection popup
  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    HapticFeedback.lightImpact();
    _logger.i('📝 Show playlist selection popup for song: ${song.title}');

    AppCustom.showBottomSheet(
      context: context,
      child: PlaylistSelectionPopup(song: song),
    );
  }

  /// Show playback speed dialog with only progress bar
  void _showPlaybackSpeedDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    _logger.i('⚡ Show playback speed dialog');

    AppCustom.showBottomSheet(
      context: context,
      title: 'Playback Speed',
      height: 230.h,
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          return _buildNativeSliderTile(
            icon: CupertinoIcons.speedometer,
            title: 'Playback Speed',
            subtitle: '${settingsState.playbackSpeed.toStringAsFixed(1)}x',
            value: settingsState.playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) => _updatePlaybackSettings(
              settingsState.autoPlayNext,
              settingsState.showNotifications,
              value,
            ),
          );
        },
      ),
    );
  }

  /// Show sleep timer dialog with toggle and progress bar
  void _showSleepTimerDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    _logger.i('😴 Show sleep timer dialog');

    AppCustom.showBottomSheet(
      context: context,
      title: 'Sleep Timer',
      height: 330.h,
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sleep Timer Toggle Switch
              _buildNativeSwitchTile(
                icon: CupertinoIcons.moon,
                title: 'Sleep Timer',
                subtitle: settingsState.isSleepTimerEnabled
                    ? 'Timer is active'
                    : 'Timer is disabled',
                value: settingsState.isSleepTimerEnabled,
                onChanged: (value) =>
                    _updateSleepTimer(settingsState.sleepTimerMinutes, value),
              ),

              // Only show slider when timer is enabled
              if (settingsState.isSleepTimerEnabled) ...[
                SizedBox(height: 16.h),
                _buildNativeSliderTile(
                  icon: CupertinoIcons.timer,
                  title: 'Timer Duration',
                  subtitle: _formatSleepTimerDuration(
                    settingsState.sleepTimerMinutes,
                  ),
                  value: settingsState.sleepTimerMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  onChanged: (value) => _updateSleepTimer(
                    value.round(),
                    settingsState.isSleepTimerEnabled,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}