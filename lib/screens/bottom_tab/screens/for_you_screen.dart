import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pmj_music_player/core/constants/app_constants.dart';
import 'package:pmj_music_player/screens/bottom_tab/widgets/album_artist_my_playlist_helper.dart';
import '../../../core/theme/theme_extension.dart';
import '../../widgets/custom_3d_card.dart';
import '../../widgets/custom_tab_view_app_bar.dart';
import '../../../core/router/app_router.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../playlist_detail_screen/playlist_detail_screen.dart';
import 'bloc/music_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../bottom_tab.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final AppLogger _logger = AppLogger('ForYouScreen');

  // Constants
  static const double _cardPadding = 12.0;
  static const double _sectionPadding = 16.0;
  static const double _itemSpacing = 8.0;
  static const double _borderRadius = 10.0;
  static const double _rankIndicatorSize = 24.0;
  static const double _albumArtSize = 48.0;
  static const double _iconSize = 20.0;
  // Animation delays
  static const int _statsDelay = 0;
  static const int _recentlyAddedDelay = 1;
  static const int _topArtistsDelay = 2;
  static const int _topAlbumsDelay = 3;

  // Limits
  static const int _maxSongsPerSection = 3;

  // Additional spacing
  static const double _largeSpacing = 24.0;
  static const double _extraLargeSpacing = 30.0;
  static const double _statCardHeight = 135.0;

  @override
  void initState() {
    super.initState();
    _logger.i('ForYouScreen initialized');
  }

  // Helper methods for data processing
  List<Song> _getMostPlayedSongs(List<Song> songs) {
    return songs.where((song) => (song.playCount ?? 0) > 0).toList()
      ..sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
  }

  List<Song> _getRecentlyAddedSongs(List<Song> songs) {
    return songs.where((song) => song.dateAdded != null).toList()..sort(
      (a, b) => (b.dateAdded ?? DateTime(1970)).compareTo(
        a.dateAdded ?? DateTime(1970),
      ),
    );
  }

  List<Artist> _getTopArtists(List<Artist> artists) {
    return artists.where((artist) => (artist.playCount ?? 0) > 0).toList()
      ..sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
  }

  List<Album> _getTopAlbums(List<Album> albums) {
    return albums.where((album) => (album.playCount ?? 0) > 0).toList()
      ..sort((a, b) => (b.playCount ?? 0).compareTo(a.playCount ?? 0));
  }

  // Helper methods for common UI components
  Widget _buildRankIndicator(int rank) {
    return Container(
      width: _rankIndicatorSize.w,
      height: _rankIndicatorSize.w,
      decoration: BoxDecoration(
        gradient: rank <= 3
            ? context.primaryGradient
            : LinearGradient(
                colors: [
                  context.onSurfaceVariantColor,
                  context.onSurfaceVariantColor,
                ],
              ),
        borderRadius: BorderRadius.circular(_borderRadius.r),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank <= 3 ? Colors.white : context.onSurfaceColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildPlayCountBadge(int playCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.primaryStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$playCount plays',
        style: TextStyle(
          color: context.primaryStart,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(
    String title,
    String message,
    IconData icon,
    int animationDelay,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: _itemSpacing.h),
        Custom3DCard(
          enableAnimation: true,
          animationDelay: animationDelay,
          padding: EdgeInsets.all(_sectionPadding.w),
          backgroundColor: context.cardColor,
          child: Column(
            children: [
              Icon(icon, color: context.onSurfaceVariantColor, size: 48.sp),
              SizedBox(height: _itemSpacing.h),
              Text(
                message,
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int animationDelay,
    double? height,
    double? iconSize,
    double? fontSize,
  }) {
    return Custom3DCard(
      height: height ?? _statCardHeight.h,
      enableAnimation: true,
      animationDelay: animationDelay,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_cardPadding.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_borderRadius.r),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  offset: Offset(0, 2.h),
                  blurRadius: 4.r,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: (iconSize ?? 24).sp),
          ),
          SizedBox(height: _itemSpacing.h),
          Text(
            count.toString(),
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: (fontSize ?? 18).sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              shadows: [
                Shadow(
                  color: context.onSurfaceColor.withValues(alpha: 0.3),
                  offset: Offset(0, 1.h),
                  blurRadius: 2.r,
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.backgroundGradient,
        color: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomTabViewAppBar(
          title: 'For You',
          showSearchButton: false,
          showSettingsButton: true,
          onSettingsPressed: () => context.navigateToSettings(),
        ),
        body: BlocBuilder<MusicBloc, MusicState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // Content
                SliverPadding(
                  padding: EdgeInsets.all(_sectionPadding.w),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome Section
                      _buildAnimatedWelcomeSection(),
                      SizedBox(height: _largeSpacing.h),

                      // Quick Stats
                      _buildAnimatedQuickStats(state),
                      SizedBox(height: _largeSpacing.h),

                      // Quilted Grid Layout
                      _buildQuiltedGrid(state),
                      SizedBox(height: _largeSpacing.h),

                      // Recently Added
                      _buildRecentlyAdded(state),
                      SizedBox(height: _largeSpacing.h),

                      // Top Albums (by play count)
                      _buildTopAlbumsByPlayCount(state),
                      SizedBox(height: _largeSpacing.h),

                      // Top Artists (by play count)
                      _buildTopArtistsByPlayCount(state),
                      SizedBox(height: 150.h),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedWelcomeSection() {
    return Custom3DCard(
      enableAnimation: true,
      animationDuration: const Duration(milliseconds: 2000),
      animationBegin: 0.98,
      animationEnd: 1.02,
      padding: EdgeInsets.symmetric(
        horizontal: _sectionPadding.w,
        vertical: _extraLargeSpacing.h,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_cardPadding.w),
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(_borderRadius.r),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: _cardPadding.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to PMJ Music',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Discover your music journey',
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 14.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(MusicState state) {
    final totalSongs = state.allSongs.length;
    final totalArtists = state.artistList.length;
    final totalAlbums = state.albumList.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Artists',
            count: totalArtists,
            icon: Icons.person_rounded,
            color: context.primaryStart,
            onTap: () => _navigateToArtistsTab(),
            animationDelay: _statsDelay,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Songs',
            count: totalSongs,
            icon: Icons.music_note_rounded,
            color: context.accentTeal,
            onTap: () => _navigateToSongsTab(),
            animationDelay: 1,
            height: 155.h,
            iconSize: 28,
            fontSize: 22,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Albums',
            count: totalAlbums,
            icon: Icons.album_rounded,
            color: context.accentGreen,
            onTap: () => _navigateToAlbumsTab(),
            animationDelay: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedQuickStats(MusicState state) {
    return _buildQuickStats(state);
  }

  Widget _buildQuiltedGrid(MusicState state) {
    final mostPlayedSongs = _getMostPlayedSongs(state.allSongs);

    if (mostPlayedSongs.isEmpty) {
      return _buildEmptyStateCard(
        'My Suggestions',
        'Start playing songs to see personalized suggestions here!',
        Icons.lightbulb_outline_rounded,
        0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _itemSpacing.h),
        SizedBox(
          height: 280.h, // Fixed height for the quilted grid
          child: GridView.custom(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverQuiltedGridDelegate(
              crossAxisCount: 4,
              mainAxisSpacing: 4.w,
              crossAxisSpacing: 4.w,
              repeatPattern: QuiltedGridRepeatPattern.inverted,
              pattern: [
                QuiltedGridTile(
                  2,
                  2,
                ), // Top-Left (Dark Blue-Green) - "My Suggestions"
                QuiltedGridTile(1, 1), // Top-Middle (Orange)
                QuiltedGridTile(1, 1), // Top-Right (Teal)
                QuiltedGridTile(1, 2), // Middle-Right (Light Orange)
                QuiltedGridTile(1, 2), // Middle-Left (Red-Orange)
                QuiltedGridTile(1, 1), // Bottom-Right small 1
                QuiltedGridTile(1, 1), // Bottom-Right small 2
                QuiltedGridTile(1, 1), // Bottom-Right small 3
                QuiltedGridTile(1, 1), // Bottom-Right small 4
                QuiltedGridTile(1, 1), // Bottom-Left (Yellow)
                QuiltedGridTile(1, 1), // Bottom-Middle (Dark Blue-Green)
              ],
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  // First card - "My Suggestions" text (large tile)
                  return _buildMySuggestionsCard();
                } else if (index >= 1 && index <= 4) {
                  // Top row small tiles and middle-right tile (indices 1-4)
                  final songIndex = index - 1;
                  if (songIndex < mostPlayedSongs.length) {
                    return _buildAlbumArtCard(mostPlayedSongs[songIndex]);
                  }
                  return _buildEmptyAlbumCard();
                } else if (index >= 5 && index <= 8) {
                  // Bottom-right 4 small containers (indices 5-8)
                  final songIndex = index - 1;
                  if (songIndex < mostPlayedSongs.length) {
                    return _buildAlbumArtCard(mostPlayedSongs[songIndex]);
                  }
                  return _buildEmptyAlbumCard();
                } else {
                  // Bottom-left and bottom-middle tiles (indices 9-10)
                  final songIndex = index - 1;
                  if (songIndex < mostPlayedSongs.length) {
                    return _buildAlbumArtCard(mostPlayedSongs[songIndex]);
                  }
                  return _buildEmptyAlbumCard();
                }
              },
              childCount: 7, // 1 for "My Suggestions" + 10 for album art tiles
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMySuggestionsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [
                  context.primaryStart.withValues(alpha: 0.8),
                  context.primaryEnd.withValues(alpha: 0.9),
                ]
              : [
                  context.primaryStart.withValues(alpha: 0.6),
                  context.primaryEnd.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: context.primaryStart.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : context.primaryStart.withValues(alpha: 0.2),
            offset: Offset(0, 4.h),
            blurRadius: 8.r,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: context.isDark ? Colors.white : Colors.white,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'My',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                  ),
                ],
              ),
            ),
            Text(
              'Suggestions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtCard(Song song, {double? borderRadius}) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: Offset(0, 2.h),
              blurRadius: 4.r,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          child: AlbumArtWidget(
            albumArt: song.albumArt,
            borderRadius: borderRadius ?? 8.r,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAlbumCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.onSurfaceVariantColor.withValues(alpha: 0.1),
            context.onSurfaceVariantColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: context.onSurfaceVariantColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: context.onSurfaceVariantColor.withValues(alpha: 0.5),
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildRecentlyAdded(MusicState state) {
    final recentSongs = _getRecentlyAddedSongs(state.allSongs);

    if (recentSongs.isEmpty) {
      return _buildEmptyStateCard(
        'Recently Added',
        'No recently added songs found.',
        Icons.new_releases_rounded,
        _recentlyAddedDelay,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Recently Added',
          recentSongs.length,
          () => _navigateToRecentlyAdded(),
        ),
        SizedBox(height: _itemSpacing.h),
        ...recentSongs.take(_maxSongsPerSection).toList().asMap().entries.map((
          entry,
        ) {
          final index = entry.key;
          final song = entry.value;
          return Column(
            children: [
              _buildSongItem(song),
              if (index < _maxSongsPerSection - 1)
                SizedBox(height: _itemSpacing.h),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTopArtistsByPlayCount(MusicState state) {
    final topArtists = _getTopArtists(state.artistList);

    if (topArtists.isEmpty) {
      return _buildEmptyStateCard(
        'Top Artists',
        'Start playing songs to see your top artists here!',
        Icons.person_rounded,
        _topArtistsDelay,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Top Artists',
          topArtists.length,
          () => _navigateToTopArtists(),
        ),
        SizedBox(height: _itemSpacing.h),
        // Use horizontal scrollable row
        SizedBox(
          height: 190.h, // Fixed height for the horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topArtists.take(6).length,
            itemBuilder: (context, index) {
              final artist = topArtists[index];
              return _buildMediaCard(
                mediaItem: artist,
                allSongs: state.allSongs,
                isAlbum: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopAlbumsByPlayCount(MusicState state) {
    final topAlbums = _getTopAlbums(state.albumList);

    if (topAlbums.isEmpty) {
      return _buildEmptyStateCard(
        'Top Albums',
        'Start playing songs to see your top albums here!',
        Icons.album_rounded,
        _topAlbumsDelay,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Top Albums',
          topAlbums.length,
          () => _navigateToTopAlbums(),
        ),
        SizedBox(height: _itemSpacing.h),
        // Use horizontal scrollable row
        SizedBox(
          height: 190.h, // Fixed height for the horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topAlbums.take(6).length,
            itemBuilder: (context, index) {
              final album = topAlbums[index];
              return _buildMediaCard(
                mediaItem: album,
                allSongs: state.allSongs,
                isAlbum: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaItem({
    required String title,
    required String subtitle,
    required String? albumArt,
    required VoidCallback onTap,
    required IconData actionIcon,
    int? rank,
    int? playCount,
    int? animationDelay,
    Duration? animationDuration,
    double? borderRadius,
    bool isNetworkImage = false,
  }) {
    if (albumArt != null && albumArt.isNotEmpty) {
      isNetworkImage =
          albumArt.startsWith('http://') || albumArt.startsWith('https://');
    }
    return Custom3DCard(
      enableAnimation: true,
      animationDelay: animationDelay ?? _recentlyAddedDelay,
      animationDuration: animationDuration ?? AppConstants.longAnimation,
      padding: EdgeInsets.symmetric(horizontal: _cardPadding.w, vertical: 8.h),
      borderRadius: _borderRadius.r,
      onTap: onTap,
      backgroundColor: context.cardColor,
      child: Row(
        children: [
          // Rank indicator (only for ranked items)
          if (rank != null) ...[
            _buildRankIndicator(rank),
            SizedBox(width: _cardPadding.w),
          ],
          AlbumArtWidget(
            albumArt: albumArt,
            width: _albumArtSize.w,
            height: _albumArtSize.h,
            borderRadius: (borderRadius ?? 8).r,
            isNetworkImage: isNetworkImage,
            defaultIcon: Icons.music_note_rounded,
            defaultIconSize: _iconSize,
          ),
          SizedBox(width: _cardPadding.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontSize: 12.sp,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Play count badge (only for items with play count)
                    if (rank != null && (playCount ?? 0) > 0) ...[
                      SizedBox(width: _itemSpacing.w),
                      _buildPlayCountBadge(playCount ?? 0),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: _itemSpacing.w),
          Icon(
            actionIcon,
            color: context.onSurfaceVariantColor,
            size: _iconSize.sp,
          ),
        ],
      ),
    );
  }

  // Convenience methods for specific types
  Widget _buildSongItem(
    Song song, {
    int? rank,
    int? animationDelay,
    Duration? animationDuration,
  }) {
    return _buildMediaItem(
      title: song.displayTitle,
      subtitle: song.displayArtist,
      albumArt: song.albumArt,
      onTap: () => _playSong(song),
      actionIcon: Icons.play_arrow_rounded,
      rank: rank,
      playCount: song.playCount,
      animationDelay: animationDelay,
      animationDuration: animationDuration,
      borderRadius: 8,
    );
  }

  Widget _buildSectionHeader(String title, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: context.primaryStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$count',
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
          ],
        ),
      ),
    );
  }

  void _playSong(Song song) {
    context.read<MusicBloc>().add(
      MusicEvent.playOrPauseSong(songId: song.id, currentPlayList: [song.id]),
    );
  }

  /// Unified method to build both artist and album cards
  Widget _buildMediaCard({
    required dynamic mediaItem, // Can be Artist or Album
    required List<Song> allSongs,
    required bool isAlbum,
  }) {
    List<Song> mediaSongs;
    String title;
    VoidCallback? onTap;
    VoidCallback? onPlay;
    Widget imageWidget;

    if (isAlbum) {
      final album = mediaItem as Album;
      mediaSongs = AlbumArtistPlaylistHelper.getAlbumSongs(album, allSongs);
      title = album.name.isNotEmpty ? album.name : 'Unknown Album';
      onTap = mediaSongs.isNotEmpty
          ? () => _navigateToAlbumDetail(album, mediaSongs)
          : null;
      onPlay = mediaSongs.isNotEmpty ? () => _playAlbum(mediaSongs) : null;

      // Album uses circular album art
      imageWidget = Center(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: AlbumArtistPlaylistHelper.buildCircularAlbumArt(
            context: context,
            album: album,
            albumSongs: mediaSongs,
          ),
        ),
      );
    } else {
      final artist = mediaItem as Artist;
      mediaSongs = AlbumArtistPlaylistHelper.getArtistSongs(artist, allSongs);
      title = artist.name;
      onTap = mediaSongs.isNotEmpty
          ? () => _navigateToArtistDetail(artist, mediaSongs)
          : null;
      onPlay = mediaSongs.isNotEmpty ? () => _playArtist(mediaSongs) : null;

      // Artist uses regular artist image
      imageWidget = AlbumArtistPlaylistHelper.buildArtistImage(
        context: context,
        artist: artist,
        artistSongs: mediaSongs,
      );
    }

    final songCount = mediaSongs.length;
    final hasSongs = songCount > 0;

    return AlbumArtistPlaylistHelper.buildCard(
      height: 190.h,
      width: 140.w,
      boxShadow: [],
      margin: EdgeInsets.only(right: 10.w),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Section
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: imageWidget,
          ),

          SizedBox(height: 8.h),

          // Info Section
          AlbumArtistPlaylistHelper.buildCardInfoSection(
            context: context,
            title: title,
            songCount: songCount,
            hasSongs: hasSongs,
            onPlay: onPlay,
          ),
        ],
      ),
    );
  }

  void _playArtist(List<Song> artistSongs) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: artistSongs,
      playlistSource: PlaylistSource.artist(artistSongs.first.artists.first),
    );
  }

  void _playAlbum(List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: albumSongs,
      playlistSource: PlaylistSource.album(albumSongs.first.albums.first),
    );
  }

  void _navigateToArtistDetail(Artist artist, List<Song> artistSongs) {
    AlbumArtistPlaylistHelper.navigateToDetail(
      context: context,
      type: PlaylistDetailType.artist,
      id: artist.id,
      name: artist.name,
      songCount: artistSongs.length,
      bio: artist.bio,
    );
  }

  void _navigateToAlbumDetail(Album album, List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.navigateToDetail(
      context: context,
      type: PlaylistDetailType.album,
      id: album.id,
      name: album.name,
      songCount: albumSongs.length,
      bio: null,
    );
  }

  void _navigateToRecentlyAdded() {
    _logger.i('Navigate to recently added songs');
    // Navigate to songs tab and filter by recently added
    _navigateToTabWithFilter(1, 'recently_added', null); // Songs tab is index 1
  }

  void _navigateToTopArtists() {
    _logger.i('Navigate to top artists');
    // Navigate to artists tab and filter by top artists
    _navigateToTabWithFilter(3, 'top_artists', null); // Artists tab is index 3
  }

  void _navigateToTopAlbums() {
    _logger.i('Navigate to top albums');
    // Navigate to albums tab and filter by top albums
    _navigateToTabWithFilter(2, 'top_albums', null); // Albums tab is index 2
  }

  void _navigateToArtistsTab() {
    _logger.i('Navigate to artists tab');
    _navigateToTab(3); // Artists tab is index 3
  }

  void _navigateToSongsTab() {
    _logger.i('Navigate to songs tab');
    _navigateToTab(1); // Songs tab is index 1
  }

  void _navigateToAlbumsTab() {
    _logger.i('Navigate to albums tab');
    _navigateToTab(2); // Albums tab is index 2
  }

  /// Navigate to a specific tab
  void _navigateToTab(int tabIndex) {
    // Find the parent BottomTab widget and call its tab switching method
    final bottomTabState = context.findAncestorStateOfType<BottomTabState>();
    if (bottomTabState != null) {
      bottomTabState.onTabTapped(tabIndex);
    } else {
      _logger.w('Could not find BottomTab parent widget');
    }
  }

  /// Navigate to a specific tab with filter parameters
  void _navigateToTabWithFilter(
    int tabIndex,
    String filterType,
    String? filterValue,
  ) {
    // First navigate to the tab
    _navigateToTab(tabIndex);

    // Then set the filter in the MusicBloc
    context.read<MusicBloc>().add(
      MusicEvent.setNavigationFilter(
        filterType: filterType,
        filterValue: filterValue,
      ),
    );
  }
}
