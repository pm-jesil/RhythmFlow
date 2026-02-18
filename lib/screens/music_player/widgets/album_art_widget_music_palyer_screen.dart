import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../utils/logger/logger.dart';
import '../../../core/theme/theme_extension.dart';
import '../../bottom_tab/bloc/music_bloc.dart';
import '../../../utils/models/song/song_model.dart';

class AlbumArtWidgetOnMusicPlayerScreen extends StatefulWidget {
  final Song currentSong;
  final List<Song> playlist;
  /// When set, uses this height so the player layout fits on small screens. Otherwise 280.h.
  final double? height;

  const AlbumArtWidgetOnMusicPlayerScreen({
    super.key,
    required this.currentSong,
    required this.playlist,
    this.height,
  });

  @override
  State<AlbumArtWidgetOnMusicPlayerScreen> createState() => _AlbumArtWidgetOnMusicPlayerScreenState();
}

class _AlbumArtWidgetOnMusicPlayerScreenState extends State<AlbumArtWidgetOnMusicPlayerScreen>
    with TickerProviderStateMixin {
  final AppLogger _logger = AppLogger('AlbumArtWidget');

  // Animation controllers
  late AnimationController _arcController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _arcAnimation;
  late Animation<double> _scaleAnimation;

  // Arc properties
  static const double _arcRadius = 180.0; // Increased radius for wider arc
  static const double _arcAngleSpacing = math.pi / 3; // 60 degrees between albums
  
  // Swipe state
  double _dragOffset = 0.0;
  double _currentArcAngle = 0.0; // Current position on the arc (0 = center)
  bool _isDragging = false;
  Song? _nextSong;
  Song? _previousSong;
  bool _isAnimating = false;
  /// When set, skip AnimatedSwitcher transition (song changed via swipe - album already visible).
  String? _lastSwipeTargetSongId;
  VoidCallback? _animationListenerRemove;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateAdjacentSongs();
  }

  @override
  void didUpdateWidget(AlbumArtWidgetOnMusicPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSong.id != widget.currentSong.id) {
      _updateAdjacentSongs();
      // Clear swipe-target after this frame (we skip transition this build, then clear)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lastSwipeTargetSongId = null;
      });
    }
  }

  void _initializeAnimations() {
    // Arc animation controller - smooth animation
    _arcController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Scale animation controller - smooth animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Arc animation for smooth transitions
    _arcAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _arcController,
      curve: Curves.easeOutQuart, // Smoother curve for arc movement
    ));

    // Scale animation for smooth scaling transitions
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic, // Smoother curve for scaling
    ));
  }

  void _updateAdjacentSongs() {
    if (widget.playlist.isEmpty) {
      _nextSong = null;
      _previousSong = null;
      return;
    }

    final currentIndex = widget.playlist.indexWhere(
      (song) => song.id == widget.currentSong.id,
    );

    if (currentIndex != -1) {
      // Get next song (for left swipe) - wrap to first if at end
      _nextSong = currentIndex < widget.playlist.length - 1
          ? widget.playlist[currentIndex + 1]
          : widget.playlist.first;

      // Get previous song (for right swipe) - wrap to last if at start
      _previousSong = currentIndex > 0
          ? widget.playlist[currentIndex - 1]
          : widget.playlist.last;
    } else {
      // Current song not in playlist (e.g. switched playlist) - clear to avoid stale data
      _nextSong = null;
      _previousSong = null;
    }
  }

  // Calculate position on arc based on angle (center album at angle 0 aligns with Stack center)
  Offset _calculateArcPosition(double angle) {
    final x = _arcRadius * math.sin(angle);
    final y = -_arcRadius * math.cos(angle) + _arcRadius;
    return Offset(x, y);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) return;
    
    _isDragging = true;
    _scaleController.forward();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isAnimating) return;

    setState(() {
      _dragOffset += details.delta.dx;
      
      // Check if trying to swipe right (previous song) when completedSongs is empty
      final musicState = context.read<MusicBloc>().state;
      if (_dragOffset > 0 && musicState.myPlayerState.completedSongs.isEmpty) {
        // Limit right swipe when no completed songs - provide resistance
        _dragOffset = (_dragOffset * 0.3).clamp(0.0, 50.0); // Reduce sensitivity and limit distance
      }
      
      // Convert drag to arc angle (more sensitive for better control)
      _currentArcAngle = (_dragOffset / 200.0) * _arcAngleSpacing;
      // Clamp the angle to reasonable limits
      _currentArcAngle = _currentArcAngle.clamp(-_arcAngleSpacing, _arcAngleSpacing);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging || _isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = 80.0; // Minimum drag distance to trigger swipe
    final velocityThreshold = 400.0;

    // Determine if swipe should trigger song change
    bool shouldSwipe = _dragOffset.abs() > threshold || velocity.abs() > velocityThreshold;
    
    if (shouldSwipe) {
      if (_dragOffset > 0) {
        // Swipe right - go to previous song
        // Check if completedSongs is empty - if so, disable previous song swipe
        final musicState = context.read<MusicBloc>().state;
        
        if (musicState.myPlayerState.completedSongs.isEmpty) {
          _logger.i('🚫 Previous song swipe disabled - no completed songs (will seek current song to beginning)');
          _resetToCenter();
          return;
        }
        _logger.i('✅ Previous song swipe enabled - ${musicState.myPlayerState.completedSongs.length} completed songs available');
        _performSwipeAction(_previousSong, true);
      } else {
        // Swipe left - go to next song
        _performSwipeAction(_nextSong, false);
      }
    } else {
      // Reset to center position
      _resetToCenter();
    }
  }

  void _performSwipeAction(Song? targetSong, bool isSwipeRight) {
    if (targetSong == null || _isAnimating) {
      _resetToCenter();
      return;
    }

    _isAnimating = true;
    HapticFeedback.mediumImpact();
    _logger.i('🎵 Swipe ${isSwipeRight ? 'right' : 'left'}: ${targetSong.title}');

    // Remember target so we can skip redundant AnimatedSwitcher transition
    final targetSongId = targetSong.id;

    // Animate to final position
    final targetAngle = isSwipeRight ? _arcAngleSpacing : -_arcAngleSpacing;
    
    _animateToAngle(targetAngle).then((_) {
      if (mounted) {
        // Set BEFORE song change so we skip AnimatedSwitcher when parent rebuilds
        _lastSwipeTargetSongId = targetSongId;
        if (isSwipeRight) {
          context.read<MusicBloc>().add(const MusicEvent.playPrevious());
        } else {
          context.read<MusicBloc>().add(const MusicEvent.playNext());
        }
      }
      
      // Reset after song change (do NOT reset _arcController here - it triggers stale listener)
      _resetAfterSongChange();
    });
  }

  Future<void> _animateToAngle(double targetAngle) async {
    // Remove previous listener to avoid leaks and stale updates
    _animationListenerRemove?.call();
    _animationListenerRemove = null;

    final startAngle = _currentArcAngle;
    final animation = Tween<double>(
      begin: startAngle,
      end: targetAngle,
    ).animate(_arcController);

    void listener() {
      if (mounted) {
        setState(() {
          _currentArcAngle = animation.value;
        });
      }
    }
    animation.addListener(listener);
    _animationListenerRemove = () => animation.removeListener(listener);

    _arcController.reset();
    await _arcController.forward();
    // Remove listener when done so _arcController.reset() elsewhere won't cause glitches
    _animationListenerRemove?.call();
    _animationListenerRemove = null;
  }

  void _resetToCenter() {
    _animateToAngle(0.0).then((_) {
      _scaleController.reverse();
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
        _isAnimating = false;
      });
    });
  }

  void _resetAfterSongChange() {
    // Don't call _arcController.reset() - it would trigger stale animation listener
    // and cause _currentArcAngle to jump. Listener is removed in _animateToAngle.forward().then.
    _scaleController.reverse();
    setState(() {
      _dragOffset = 0.0;
      _currentArcAngle = 0.0;
      _isDragging = false;
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _animationListenerRemove?.call();
    _animationListenerRemove = null;
    _arcController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive height: on small screens
    final double height;
    if (widget.height != null) {
      height = widget.height!;
    } else {
      final screenHeight = MediaQuery.sizeOf(context).height;
      final fixedHeights = 75.h + 110.h + 60.h + 80.h + 15.h + 50.h;
      const double safetyMargin = 16; // avoid RenderFlex overflow (rounding + .h vs actual layout)
      final available = screenHeight - 120 - safetyMargin; // top bar + safe area + margin
      height = (available - fixedHeights).clamp(140.0, 280.h).toDouble();
    }
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0.r),
      ),
      clipBehavior: Clip.hardEdge, // Ensure content stays within bounds
      child: GestureDetector(
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: AnimatedBuilder(
          animation: Listenable.merge([_arcAnimation, _scaleAnimation]),
          builder: (context, child) {
            return _buildArcContainer();
          },
        ),
      ),
    );
  }

  Widget _buildArcContainer() {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final isPreviousDisabled = state.myPlayerState.completedSongs.isEmpty;
        
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Background arc indicator hidden for cleaner UI
            // if (_isDragging) _buildArcIndicator(),
            
            // Current album art
            _buildAlbumAtAngle(widget.currentSong, _currentArcAngle, true),
            
            // Next album art (visible during left swipe)
            if (_nextSong != null && _currentArcAngle < -0.1)
              _buildAlbumAtAngle(_nextSong!, _currentArcAngle + _arcAngleSpacing, false),
              
            // Previous album art (visible during right swipe) - only if not disabled
            if (_previousSong != null && _currentArcAngle > 0.1 && !isPreviousDisabled)
              _buildAlbumAtAngle(_previousSong!, _currentArcAngle - _arcAngleSpacing, false),
              
          ],
        );
      },
    );
  }


  Widget _buildAlbumAtAngle(Song song, double angle, bool isCurrent) {
    final position = _calculateArcPosition(angle);
    
    // Calculate smooth scale based on angle position
    double scale;
    final angleProgress = (angle.abs() / _arcAngleSpacing).clamp(0.0, 1.0);
    
    if (isCurrent) {
      // Center album: scale down when moving away from center
      if (angle.abs() < 0.1) {
        // At center: always full size (180.r)
        scale = 1.0;
      } else {
        // Moving away from center: scale down (180.r to 165.r)
        scale = 1.0 - (angleProgress * 0.083); // 180.r to 165.r (0.917 scale)
      }
    } else {
      // Side albums: scale based on distance from center
      if (angle.abs() < 0.1) {
        // At center: full size (180.r) - this handles the transition when side album becomes center
        scale = 1.0;
      } else {
        // Away from center: smaller size (165.r)
        scale = 0.917; // 165.r equivalent (165/180 = 0.917)
      }
    }
    
    // Calculate opacity based on position (fade out albums that are too far)
    double opacity = 1.0;
    if (angle.abs() > _arcAngleSpacing * 0.7) {
      opacity = math.max(0.3, 1.0 - (angle.abs() - _arcAngleSpacing * 0.7) / (_arcAngleSpacing * 0.3));
    }

    return Transform.translate(
      offset: position,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: RepaintBoundary(child: _buildAlbumArt(song, isCurrent)),
        ),
      ),
    );
  }

  static const Duration _artTransitionDuration = Duration(milliseconds: 300);
  static const Curve _artTransitionCurve = Curves.easeOut;

  Widget _buildAlbumArt(Song song, bool isCurrent) {
    // When song changed via swipe, album is already visible - skip transition to avoid glitch
    final skipTransition = isCurrent && song.id == _lastSwipeTargetSongId;
    final transitionDuration = skipTransition ? Duration.zero : _artTransitionDuration;

    final hasValidArt = song.albumArt != null && song.albumArt!.trim().isNotEmpty;
    final Widget content = hasValidArt
        ? SizedBox(
            width: 180.r,
            height: 180.r,
            child: Image.file(
              File(song.albumArt!),
              width: 180.r,
              height: 180.r,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == null) return _buildDefaultAlbumArt(context);
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAlbumArt(context);
              },
            ),
          )
        : _buildDefaultAlbumArt(context);
    final Object switchKey = hasValidArt ? song.albumArt! : 'default';

    return Container(
      width: 180.r,
      height: 180.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
          BoxShadow(
            color: context.primaryStart.withValues(alpha: 0.2),
            blurRadius: 30.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: _artTransitionCurve,
          switchOutCurve: _artTransitionCurve,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: RepaintBoundary(child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(switchKey), child: content),
        ),
      ),
    );
  }

  /// Default album art: same look as shared AlbumArtWidget (gradient + centered icon).
  Widget _buildDefaultAlbumArt(BuildContext context) {
    const double size = 180.0; // .r applied below
    final double w = size.r;
    final double h = size.r;
    final double iconSize = (size * 0.5).r; // ~50% of container like AlbumArtWidget
    final double padding = (size * 0.12).r; // classic ~12% padding like AlbumArtWidget
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(
            Icons.music_note,
            size: iconSize,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

}
