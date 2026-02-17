import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/music_bloc.dart';
import '../../widgets/album_art_widget.dart';
import 'song_context_menu.dart';

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
  final Function(String action, String songId, String songTitle, String artistName, String albumName)? onMenuAction;

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
    this.onMenuAction,
  });

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  AnimationController? _waveController;
  AnimationController? _pulseController;
  List<Animation<double>>? _waveAnimations;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _ensurePlayingAnimations() {
    if (_waveController != null) return;
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController!,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.6,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  void _disposePlayingAnimations() {
    _waveController?.dispose();
    _waveController = null;
    _pulseController?.dispose();
    _pulseController = null;
    _waveAnimations = null;
  }

  @override
  void dispose() {
    _disposePlayingAnimations();
    _scaleController.dispose();
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

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _showContextMenu();
  }

  void _handleLongPressStart() {
    HapticFeedback.lightImpact();
    _scaleController.forward();
  }

  void _handleLongPressEnd() {
    _scaleController.reverse();
  }

  void _handleLongPressCancel() {
    _scaleController.reverse();
  }

  void _showContextMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => SongContextMenu(
        songTitle: widget.songTitle,
        artistName: widget.artistName,
        albumName: widget.albumName,
        songId: widget.songId,
        position: position,
        size: size,
        onMenuAction: widget.onMenuAction,
      ),
    );
  }

  void _controlAnimations(bool isPlaying, bool isCurrentSong) {
    if (isCurrentSong && isPlaying) {
      _ensurePlayingAnimations();
      if (!_waveController!.isAnimating) {
        _waveController!.repeat();
      }
      if (!_pulseController!.isAnimating) {
        _pulseController!.repeat(reverse: true);
      }
    } else {
      if (_waveController?.isAnimating ?? false) {
        _waveController!.stop();
        _waveController!.reset();
      }
      if (_pulseController?.isAnimating ?? false) {
        _pulseController!.stop();
        _pulseController!.reset();
      }
      if (!isCurrentSong && _waveController != null) {
        _disposePlayingAnimations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (previous, current) {
        final prevSongId = previous.myPlayerState.currentSongId;
        final currSongId = current.myPlayerState.currentSongId;
        final prevIsPlaying = previous.myPlayerState.isPlaying;
        final currIsPlaying = current.myPlayerState.isPlaying;
        return prevSongId != currSongId ||
            prevIsPlaying != currIsPlaying ||
            (prevSongId == widget.songId) != (currSongId == widget.songId);
      },
      builder: (context, state) {
        final isCurrentlyPlaying = state.myPlayerState.currentSongId == widget.songId &&
            state.myPlayerState.isPlaying;
        final isCurrentSong = state.myPlayerState.currentSongId == widget.songId;
        _controlAnimations(isCurrentlyPlaying, isCurrentSong);
        final isSelected = isCurrentSong;
        final isScaleAnimating = _scaleController.isAnimating;

        // When not scaling (idle), avoid AnimatedBuilder + Transform for smoother list scrolling
        if (!isScaleAnimating && _scaleAnimation.value == 1.0) {
          return _buildTileContent(context, isSelected, isCurrentlyPlaying, 1.0);
        }
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildTileContent(
                context,
                isSelected,
                isCurrentlyPlaying,
                _scaleAnimation.value,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    bool isSelected,
    bool isCurrentlyPlaying, [
    double scaleValue = 1.0,
  ]) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? context.primaryStart.withValues(alpha: 0.1)
            : context.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isSelected
              ? context.primaryStart.withValues(alpha: 0.3)
              : context.onSurfaceColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.1 + (1 - scaleValue) * 0.1,
            ),
            blurRadius: 8 + (1 - scaleValue) * 4,
            offset: Offset(0, 2 + (1 - scaleValue) * 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _handleTileTap,
          onLongPress: _handleLongPress,
          onLongPressStart: (_) => _handleLongPressStart(),
          onLongPressEnd: (_) => _handleLongPressEnd(),
          onLongPressCancel: () => _handleLongPressCancel(),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: _handleTileTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              child: Row(
                children: [
                  AlbumArtWidget(
                    albumArt: widget.albumArtPath,
                    width: 40.w,
                    height: 40.h,
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
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.songTitle,
                          style: TextStyle(
                            color: isSelected
                                ? context.primaryStart
                                : context.onSurfaceColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.artistName,
                          style: TextStyle(
                            color: isSelected
                                ? context.primaryStart.withValues(alpha: 0.8)
                                : context.onSurfaceVariantColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
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
                        child: _buildPlayButton(
                          context,
                          isCurrentlyPlaying,
                          isSelected,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(
    BuildContext context,
    bool isPlaying,
    bool isCurrentSong,
  ) {
    if (isCurrentSong && isPlaying && _waveController != null && _pulseController != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([_waveController!, _pulseController!]),
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.primaryStart,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryStart.withValues(
                    alpha: 0.3 + (_pulseController!.value * 0.2),
                  ),
                  blurRadius: 8 + (_pulseController!.value * 4),
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
    final animations = _waveAnimations;
    if (animations == null || animations.length < 3) {
      return const Icon(Icons.music_note, color: Colors.white, size: 20);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: animations[index],
          builder: (context, child) {
            return Container(
              width: 3,
              height: 12 * animations[index].value,
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
