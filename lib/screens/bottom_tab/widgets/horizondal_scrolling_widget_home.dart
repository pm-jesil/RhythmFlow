import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pmj_music_player/screens/bottom_tab/bloc/music_bloc.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/logger/logger.dart';
import '../../widgets/sorting_helper.dart';
import '../../widgets/album_art_widget.dart';

class HorizondalScrollingWidgetHome extends StatefulWidget {
  final List<Song> allSongs;
  final List<Artist> artistList;
  final List<Album> albumList;
  final VoidCallback? onRecentlyAddedPressed;
  final VoidCallback? onMostPlayedPressed;
  final int maxSongsPerSection;
  final int animationDelay;

  const HorizondalScrollingWidgetHome({
    super.key,
    required this.allSongs,
    required this.artistList,
    required this.albumList,
    this.onRecentlyAddedPressed,
    this.onMostPlayedPressed,
    this.maxSongsPerSection = 3,
    this.animationDelay = 0,
  });

  @override
  State<HorizondalScrollingWidgetHome> createState() =>
      _HorizondalScrollingWidgetHomeState();
}

class _HorizondalScrollingWidgetHomeState
    extends State<HorizondalScrollingWidgetHome> {
  final AppLogger _logger = AppLogger('HorizondalScrollingWidgetHome');
  PageController? _pageController;

  // Helper methods for data processing
  List<Song> _getMostPlayedSongs(List<Song> songs) {
    final songsWithPlayCount = songs
        .where((song) => (song.playCount ?? 0) > 0)
        .toList();
    return SortingHelper.sortByPlayCount(songsWithPlayCount, ascending: false);
  }

  List<Song> _getRecentlyAddedSongs(List<Song> songs) {
    final songsWithDate = songs
        .where((song) => song.dateAdded != null)
        .toList();
    return SortingHelper.sortByDateAdded(songsWithDate, newestFirst: true);
  }

  void _updateCurrentWidgetIndex(int index) {
    _logger.i('🔄 Updating current widget index to: $index');
    context.read<MusicBloc>().add(
      MusicEvent.updateMusicBlocState(
        newState: context.read<MusicBloc>().state.copyWith(
          horizondalScrollingWidgetHomeIndex: index,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the current index from MusicBloc
    final currentIndex = context.read<MusicBloc>().state.horizondalScrollingWidgetHomeIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentSongs = _getRecentlyAddedSongs(widget.allSongs);
    final mostPlayedSongs = _getMostPlayedSongs(widget.allSongs);

    return SizedBox(
      height: 300.h, // Fixed height for PageView
      child: PageView.builder(
        controller: _pageController,
        itemCount: 2,
        onPageChanged: (index) => _updateCurrentWidgetIndex(index),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Recently Added
            return _buildSongListSection(
              context: context,
              title: 'Recently Added',
              songs: recentSongs,
              onViewAllPressed: widget.onRecentlyAddedPressed,
              emptyStateIcon: Icons.new_releases_rounded,
              emptyStateMessage: 'No recently added songs found.',
            );
          } else {
            // Most Played
            return _buildSongListSection(
              context: context,
              title: 'Most Played',
              songs: mostPlayedSongs,
              onViewAllPressed: widget.onMostPlayedPressed,
              emptyStateIcon: Icons.trending_up_rounded,
              emptyStateMessage:
                  'Start playing songs to see your most played here!',
            );
          }
        },
      ),
    );
  }

  Widget _buildSongListSection({
    required BuildContext context,
    required String title,
    required List<Song> songs,
    VoidCallback? onViewAllPressed,
    required IconData emptyStateIcon,
    required String emptyStateMessage,
  }) {
    if (songs.isEmpty) {
      return _buildEmptyStateCard(
        context: context,
        title: title,
        emptyStateIcon: emptyStateIcon,
        emptyStateMessage: emptyStateMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          title: title,
          onViewAllPressed: onViewAllPressed,
        ),
        SizedBox(height: 8.h),
        ...songs.take(widget.maxSongsPerSection).toList().asMap().entries.map((
          entry,
        ) {
          final index = entry.key;
          final song = entry.value;
          return Column(
            children: [
              _buildSongItem(context: context, song: song),
              if (index < widget.maxSongsPerSection - 1) SizedBox(height: 8.h),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyStateCard({
    required BuildContext context,
    required String title,
    required IconData emptyStateIcon,
    required String emptyStateMessage,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.surfaceColor.withValues(alpha: 0.3),
            context.surfaceColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.onSurfaceColor.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            emptyStateIcon,
            size: 48.sp,
            color: context.onSurfaceColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: context.text.titleMedium?.copyWith(
              color: context.onSurfaceColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            emptyStateMessage,
            style: context.text.bodyMedium?.copyWith(
              color: context.onSurfaceColor.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    VoidCallback? onViewAllPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
        ),
        if (onViewAllPressed != null)
          GestureDetector(
            onTap: onViewAllPressed,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: context.primaryStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: context.primaryStart,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.onSurfaceVariantColor,
                  size: 14.sp,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSongItem({required BuildContext context, required Song song}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.onSurfaceColor.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Album art
          AlbumArtWidget(
            albumArt: song.albumArt,
            width: 48.w,
            height: 48.w,
            borderRadius: 8.r,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  song.artists.isNotEmpty
                      ? song.artists.first
                      : 'Unknown Artist',
                  style: context.text.bodySmall?.copyWith(
                    color: context.onSurfaceColor.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Play count or date info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: context.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              song.playCount != null ? '${song.playCount} plays' : 'New',
              style: context.text.bodySmall?.copyWith(
                color: context.primaryStart,
                fontWeight: FontWeight.w500,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
