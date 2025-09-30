import 'dart:io';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_extension.dart';
import '../bottom_tab/screens/bloc/music_bloc.dart';

class CustomMusicFloatingButton extends StatefulWidget {
  const CustomMusicFloatingButton({super.key});

  @override
  State<CustomMusicFloatingButton> createState() =>
      _CustomMusicFloatingButtonState();
}

class _CustomMusicFloatingButtonState extends State<CustomMusicFloatingButton>
    with TickerProviderStateMixin {
  static const _kToggleDuration = Duration(milliseconds: 300);
  static const _kRotationDuration = Duration(seconds: 5);

  // Animation controllers
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _tapController;

  double _rotation = 0;
  double _tapScale = 1.0;

  void _updateRotation() {
    if (mounted) {
      _rotation = _rotationController.value * 2 * pi;
    }
  }
  
  void _updateTapScale() {
    if (mounted) {
      _tapScale = 1.0 - (_tapController.value * 0.15);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize rotation controller for wave animation
    _rotationController =
        AnimationController(vsync: this, duration: _kRotationDuration)
          ..addListener(() {
            if (mounted) setState(_updateRotation);
          })
          ..repeat();

    // Initialize pulse controller for breathing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initialize tap controller for zoom animation
    _tapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 150),
        )..addListener(() {
          if (mounted) setState(_updateTapScale);
        });
  }

  @override
  void dispose() {
    // Stop all animations before disposing
    _rotationController.stop();
    _pulseController.stop();
    _tapController.stop();

    // Dispose all controllers
    _rotationController.dispose();
    _pulseController.dispose();
    _tapController.dispose();

    super.dispose();
  }

  void _onToggle({
    required bool isPlaying,
    required String currentSongId,
    required List<String> currentPlayList,
  }) {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Trigger tap zoom animation
    _tapController.forward().then((_) {
      if (mounted) {
        _tapController.reverse();
      }
    });

    // Toggle play/pause based on current state
    // IMPORTANT: currentSongId should NEVER become null during play/pause toggle
    // Only isPlaying state should change, keeping the button visible
    if (isPlaying) {
      // If currently playing, pause the song (keep currentSongId, just change isPlaying to false)
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(
          songId: currentSongId,
          currentPlayList: currentPlayList,
        ),
      );
    } else {
      // If currently paused, resume the song (keep currentSongId, change isPlaying to true)
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(
          songId: currentSongId,
          currentPlayList: currentPlayList,
        ),
      );
    }
  }

  Widget _buildIcon({
    required bool isPlaying,
    required String currentSongId,
    required List<String> currentPlayList,
  }) {
    return SizedBox.expand(
      key: ValueKey('floating_button_$isPlaying'),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24.sp,
        ),
        onPressed: () => _onToggle(
          isPlaying: isPlaying,
          currentSongId: currentSongId,
          currentPlayList: currentPlayList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final currentSongId = state.myPlayerState.currentSongId;
        final isPlaying = state.myPlayerState.isPlaying;

        // CRITICAL: Only hide if currentSongId is null (user explicitly stopped/cleared music)
        // The button should ALWAYS be visible when there's a currentSongId, regardless of isPlaying state
        // This ensures the button never disappears during play/pause toggles
        if (currentSongId == null) return const SizedBox.shrink();

        // Find current song from allSongs list with proper error handling
        try {
          final currentSong = state.allSongs.firstWhere(
            (song) => song.id == currentSongId,
          );

          return Positioned(
          bottom: 100.h,
          right: 20.w,
          child: GestureDetector(
            onTap: () {
              // Check if widget is still mounted before handling tap
              if (!mounted) return;
              
              // Trigger zoom animation
              _onToggle(
                isPlaying: isPlaying,
                currentSongId: currentSongId,
                currentPlayList: state.myPlayerState.currentPlayList,
              );
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      _tapScale *
                      (isPlaying ? 1.0 + (_pulseController.value * 0.1) : 1.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 60.w,
                      minHeight: 60.h,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated waves
                        Blob(
                          color: context.primaryStart.withValues(alpha: 0.4),
                          scale: 1.0,
                          rotation: _rotation,
                        ),
                        Blob(
                          color: context.primaryEnd.withValues(alpha: 0.3),
                          scale: 1.0,
                          rotation: _rotation * 2 - 30,
                        ),
                        Blob(
                          color: context.primaryStart.withValues(alpha: 0.1),
                          scale: 1.0,
                          rotation: _rotation * 3 - 45,
                        ),
                        Blob(
                          color: context.primaryStart.withValues(alpha: 0.2),
                          scale: 1.0,
                          rotation: _rotation + 10,
                        ),

                        // Album art background
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryStart.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: currentSong.albumArt != null && 
                                   currentSong.albumArt!.isNotEmpty
                                ? Image.file(
                                    File(currentSong.albumArt!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildDefaultBackground(context),
                                  )
                                : _buildDefaultBackground(context),
                          ),
                        ),

                        // Play/Pause button
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.3),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: _kToggleDuration,
                            child: _buildIcon(
                              isPlaying: isPlaying,
                              currentSongId: currentSongId,
                              currentPlayList:
                                  state.myPlayerState.currentPlayList,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        } catch (e) {
          // If song not found, return empty widget
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildDefaultBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 24.sp),
    );
  }
}

class Blob extends StatelessWidget {
  final double rotation;
  final double scale;
  final Color color;

  const Blob({
    super.key,
    required this.color,
    this.rotation = 0,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 70.w,
          height: 70.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(150.r),
              topRight: Radius.circular(240.r),
              bottomLeft: Radius.circular(220.r),
              bottomRight: Radius.circular(180.r),
            ),
          ),
        ),
      ),
    );
  }
}
