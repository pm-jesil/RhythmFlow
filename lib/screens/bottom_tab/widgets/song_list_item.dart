import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/bloc/music_bloc.dart';
import '../../widgets/album_art_widget.dart';

class SongListItem extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String albumName;
  final Duration duration;
  final String? albumArtPath;
  final VoidCallback onTap;
  final VoidCallback onOpenMusicPlayer;
  final String songId;
  final bool isImmediatelySelected;

  const SongListItem({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.albumName,
    required this.duration,
    this.albumArtPath,
    required this.onTap,
    required this.onOpenMusicPlayer,
    required this.songId,
    this.isImmediatelySelected = false,
  });

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late List<Animation<double>> _waveAnimations;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Create wave animations for 3 bars
    _waveAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(
            index * 0.2, // Stagger the animations
            (index * 0.2) + 0.6,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(SongListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This ensures animations are controlled even when widget updates
    // The build method will handle the actual animation control
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _handleTileTap() {
    HapticFeedback.lightImpact();
    widget.onOpenMusicPlayer();
  }

  void _handlePlayButtonTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  // Control animations based on playing state
  void _controlAnimations(bool isPlaying, bool isCurrentSong) {
    if (isCurrentSong && isPlaying) {
      // Start animations when song is playing
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      // Stop animations when song is not playing or not current
      if (_waveController.isAnimating) {
        _waveController.stop();
        _waveController.reset(); // Reset to beginning
      }
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset(); // Reset to beginning
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final isCurrentlyPlaying = state.myPlayerState.currentSongId == widget.songId && state.myPlayerState.isPlaying;
        final isCurrentSong = state.myPlayerState.currentSongId == widget.songId;
        
        // Control animations based on playing state
        _controlAnimations(isCurrentlyPlaying, isCurrentSong);
        
        // Use immediate selection for instant feedback, fallback to BLoC state
        final isSelected = widget.isImmediatelySelected || isCurrentSong;

        return Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? context.primaryStart.withValues(alpha: 0.1)
                : context.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10.r), // Slightly reduced border radius
            border: Border.all(
              color: isSelected 
                  ? context.primaryStart.withValues(alpha: 0.3)
                  : context.onSurfaceColor.withValues(alpha: 0.1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: _handleTileTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h), // Reduced padding
                child: Row(
                  children: [
                    // Album Art
                    AlbumArtWidget(
                      albumArt: widget.albumArtPath,
                      size: 48.w,
                      borderRadius: 6.r,
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark 
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 1.h),
                        ),
                      ],
                      defaultIconSize: 20.0,
                    ),
                    
                    SizedBox(width: 12.w), // Reduced spacing between album art and text
                    
                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.songTitle,
                            style: TextStyle(
                              color: isSelected ? context.primaryStart : context.onSurfaceColor,
                              fontSize: 14.sp, // Reduced font size
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h), // Reduced spacing
                          Text(
                            widget.artistName,
                            style: TextStyle(
                              color: isSelected 
                                  ? context.primaryStart.withValues(alpha: 0.8)
                                  : context.onSurfaceVariantColor,
                              fontSize: 12.sp, // Reduced font size
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h), // Reduced spacing
                          Text(
                            widget.albumName,
                            style: TextStyle(
                              color: isSelected 
                                  ? context.primaryStart.withValues(alpha: 0.6)
                                  : context.onSurfaceVariantColor.withValues(alpha: 0.8),
                              fontSize: 10.sp, // Reduced font size
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 12.w), // Reduced spacing
                    
                    // Duration and Play Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(widget.duration),
                          style: TextStyle(
                            color: isSelected 
                                ? context.primaryStart
                                : context.onSurfaceVariantColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handlePlayButtonTap,
                          child: _buildPlayButton(context, isCurrentlyPlaying, isSelected),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(BuildContext context, bool isPlaying, bool isCurrentSong) {
    if (isCurrentSong && isPlaying) {
      // Show wave animation for currently playing song
      return AnimatedBuilder(
        animation: Listenable.merge([_waveController, _pulseController]),
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.primaryStart,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                  blurRadius: 8 + (_pulseController.value * 4),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildWaveAnimation(),
          );
        },
      );
    } else {
      // Show play arrow for all other songs (including selected but not playing)
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.primaryStart,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.primaryStart.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }
  }

  Widget _buildWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _waveAnimations[index],
          builder: (context, child) {
            return Container(
              width: 3,
              height: 12 * _waveAnimations[index].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

}
