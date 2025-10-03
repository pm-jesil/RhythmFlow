import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/router/app_router.dart';
import '../../playlist_detail_screen/playlist_detail_screen.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/my_playlist/my_playlist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../screens/bloc/music_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../../widgets/custom_3d_card.dart';

/// Helper class containing common widgets and methods for Album, Artist, and Playlist screens
class AlbumArtistPlaylistHelper {
  /// Builds a common app bar for all three screens
  static PreferredSizeWidget buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white, // Will be overridden by context
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds a common search bar widget
  static Widget buildSearchBar({
    required TextEditingController controller,
    required String hintText,
    required BuildContext context,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Custom3DCard(
          enableAnimation: true,
          animationDelay: 0,
          animationDuration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          borderRadius: 12.r,
          backgroundColor: context.cardColor,
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: context.onSurfaceVariantColor,
                size: 20.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds loading state widget with fade transition
  static Widget buildLoadingState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: CircularProgressIndicator(color: context.primaryStart),
          ),
        ),
      ),
    );
  }

  /// Builds error state widget with fade transition
  static Widget buildErrorState({
    required BuildContext context,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: context.onSurfaceVariantColor,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(onPressed: onRetry, child: Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds empty state widget with fade transition
  static Widget buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                Icon(icon, color: context.onSurfaceVariantColor, size: 48.sp),
                SizedBox(height: 16.h),
                Text(
                  message,
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 16.sp,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.onSurfaceVariantColor.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds masonry grid layout with lazy loading and fade transitions
  static Widget buildMasonryGrid<T>({
    required List<T> items,
    required Widget Function(BuildContext context, int index) itemBuilder,
    int initialLoadCount = 15,
  }) {
    return SliverPadding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 0.h),
      sliver: SliverToBoxAdapter(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: MasonryGridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeInOut,
                child: itemBuilder(context, index),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds lazy loading masonry grid with initial batch and background loading
  static Widget buildLazyLoadingMasonryGrid<T>({
    required BuildContext context,
    required List<T> allItems,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required VoidCallback onLoadMore,
    int initialLoadCount = 15,
    bool isLoadingMore = false,
  }) {
    // Validate inputs to prevent glitches
    if (allItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Show initial batch immediately, or all items if loading is complete
    final itemsToShow = allItems.take(initialLoadCount).toList();
    final hasMoreItems = allItems.length > initialLoadCount;
    final showAllItems = !hasMoreItems || !isLoadingMore;

    return SliverPadding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 0.h),
      sliver: SliverToBoxAdapter(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            children: [
              // Items grid - shows initial batch or all items
              MasonryGridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                itemCount: showAllItems ? allItems.length : itemsToShow.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  // Additional safety check for index bounds
                  if (index >=
                      (showAllItems ? allItems.length : itemsToShow.length)) {
                    return const SizedBox.shrink();
                  }

                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeInOut,
                    child: itemBuilder(context, index),
                  );
                },
              ),

              // Loading indicator for remaining items
              if (hasMoreItems && isLoadingMore) ...[
                SizedBox(height: 16.h),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.primaryStart,
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds common card image section with fade transition
  static Widget buildCardImageSection({
    required Widget imageWidget,
    double aspectRatio = 1.0,
  }) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: imageWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds common card info section with fade transition
  static Widget buildCardInfoSection({
    required BuildContext context,
    required String title,
    required int songCount,
    required bool hasSongs,
    required VoidCallback? onPlay,
    String? subtitle,
    // Text styling parameters
    FontWeight? titleFontWeight,
    double? titleFontSize,
    Color? titleColor,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? context.onSurfaceColor,
                fontWeight: titleFontWeight ?? FontWeight.bold,
                fontSize: titleFontSize ?? 12.sp,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 8.h),

            // Song count and play button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Song count
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: context.onSurfaceVariantColor,
                        size: 10.sp,
                      ),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          songCount == 1 ? '1' : '$songCount',
                          style: TextStyle(
                            color: context.onSurfaceVariantColor,
                            fontSize: 9.sp,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Play All Button
                if (hasSongs && onPlay != null)
                  GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryStart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: context.primaryStart.withValues(alpha: 0.3),
                          width: 0.5.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: context.primaryStart,
                            size: 10.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: context.primaryStart,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Subtitle (for playlists)
            if (subtitle != null && subtitle.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.onSurfaceVariantColor.withValues(alpha: 0.7),
                  fontSize: 8.sp,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds common 3D card with fade transition
  static Widget buildCard({
    double? height,
    double? width,
    required Widget child,
    required VoidCallback? onTap,
    bool enableAnimation = true,
    int animationDelay = 0,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? margin,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300 + animationDelay),
      curve: Curves.easeInOut,
      child: Custom3DCard(
        height: height,
        width: width,
        margin: margin,
        enableAnimation: enableAnimation,
        animationDelay: animationDelay,
        animationDuration: const Duration(milliseconds: 600),
        boxShadow: boxShadow,
        onTap: onTap,
        child: child,
      ),
    );
  }

  /// Builds album art widget with common styling and fade transition
  static Widget buildAlbumArt({
    required BuildContext context,
    String? albumArt,
    required IconData defaultIcon,
    double defaultIconSize = 40.0,
    double borderRadius = 12.0,
    bool isNetworkImage = false,
    List<BoxShadow>? boxShadow,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: AlbumArtWidget(
        albumArt: albumArt,
        width: double.infinity,
        height: double.infinity,
        borderRadius: borderRadius,
        isNetworkImage: isNetworkImage,
        defaultIcon: defaultIcon,
        defaultIconSize: defaultIconSize,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: context.primaryStart.withValues(alpha: 0.3),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
      ),
    );
  }

  /// Common method to play songs
  static void playSongs({
    required BuildContext context,
    required List<Song> songs,
    required PlaylistSource playlistSource,
  }) {
    if (songs.isNotEmpty) {
      final songIds = songs.map((song) => song.id).toList();
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(
          songId: songIds.first,
          currentPlayList: songIds,
          playlistSource: playlistSource,
        ),
      );
    }
  }

  /// Common method to navigate to detail screen
  static void navigateToDetail({
    required BuildContext context,
    required PlaylistDetailType type,
    required String id,
    required String name,
    required int songCount,
    String? description,
    String? year,
    String? bio,
  }) {
    context.navigateToPlaylistDetail(
      type: type,
      id: id,
      name: name,
      description: description,
      year: year,
      bio: bio,
      songCount: songCount,
    );
  }

  /// New object-based navigation methods
  static void navigateToArtistDetail({
    required BuildContext context,
    required Artist artist,
  }) {
    final state = context.read<MusicBloc>().state;
    final artistSongs = getArtistSongs(artist, state.allSongs);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          type: PlaylistDetailType.artist,
          id: artist.id,
          name: artist.name,
          description: artist.bio,
          songCount: artistSongs.length,
          songs: artistSongs,
          coverImage: artist.image,
        ),
      ),
    );
  }

  static void navigateToAlbumDetail({
    required BuildContext context,
    required Album album,
  }) {
    final state = context.read<MusicBloc>().state;
    final albumSongs = getAlbumSongs(album, state.allSongs);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          type: PlaylistDetailType.album,
          id: album.id,
          name: album.name,
          description: album.description,
          year: album.year?.toString(),
          songCount: albumSongs.length,
          songs: albumSongs,
          coverImage: album.coverImage,
        ),
      ),
    );
  }

  static void navigateToPlaylistDetail({
    required BuildContext context,
    required MyPlaylist playlist,
  }) {
    final state = context.read<MusicBloc>().state;
    final playlistSongs = getPlaylistSongs(playlist, state.allSongs);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          type: PlaylistDetailType.playlist,
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          songCount: playlistSongs.length,
          songs: playlistSongs,
          coverImage: playlist.coverImage,
        ),
      ),
    );
  }

  /// Gets songs for an artist
  static List<Song> getArtistSongs(Artist artist, List<Song> allSongs) {
    try {
      if (artist.name.isEmpty || allSongs.isEmpty) {
        return [];
      }

      List<Song> artistSongs = [];
      if (artist.songIds.isNotEmpty) {
        artistSongs = allSongs
            .where((song) => artist.songIds.contains(song.id))
            .toList();
      }
      return artistSongs;
    } catch (e) {
      return [];
    }
  }

  /// Gets songs for an album
  static List<Song> getAlbumSongs(Album album, List<Song> allSongs) {
    try {
      if (album.name.isEmpty || allSongs.isEmpty) {
        return [];
      }

      List<Song> albumSongs = [];
      if (album.songIds.isNotEmpty) {
        albumSongs = allSongs
            .where((song) => album.songIds.contains(song.id))
            .toList();
      }
      return albumSongs;
    } catch (e) {
      return [];
    }
  }

  /// Gets songs for a playlist
  static List<Song> getPlaylistSongs(MyPlaylist playlist, List<Song> allSongs) {
    return allSongs
        .where((song) => playlist.songIds.contains(song.id))
        .toList();
  }

  /// Builds artist image with fallback and fade transition
  static Widget buildArtistImage({
    required BuildContext context,
    required Artist artist,
    required List<Song> artistSongs,
  }) {
    String? artistImage = artist.image;
    bool isNetworkImage = false;

    if (artistImage == null || artistImage.isEmpty) {
      artistImage = artistSongs.first.albumArt;
    }

    // Determine if it's a network image based on the URL
    if (artistImage != null && artistImage.isNotEmpty) {
      isNetworkImage =
          artistImage.startsWith('http://') ||
          artistImage.startsWith('https://');
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: buildAlbumArt(
        context: context,
        albumArt: artistImage,
        defaultIcon: Icons.person_rounded,
        defaultIconSize: 40.0,
        borderRadius: 12.r,
        isNetworkImage: isNetworkImage,
      ),
    );
  }

  /// Builds circular album art for albums with fade transition
  static Widget buildCircularAlbumArt({
    required BuildContext context,
    required Album album,
    required List<Song> albumSongs,
  }) {
    String? albumArt = album.coverImage;
    bool isNetworkImage = false;

    if (albumArt == null || albumArt.isEmpty) {
      albumArt = albumSongs.isNotEmpty ? albumSongs.first.albumArt : null;
    }

    // Determine if it's a network image based on the URL
    if (albumArt != null && albumArt.isNotEmpty) {
      isNetworkImage =
          albumArt.startsWith('http://') || albumArt.startsWith('https://');
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: ClipOval(
        child: buildAlbumArt(
          context: context,
          albumArt: albumArt,
          defaultIcon: Icons.album_rounded,
          defaultIconSize: 40.0,
          borderRadius: 0, // No border radius for circular clip
          isNetworkImage: isNetworkImage,
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds playlist image with fade transition
  static Widget buildPlaylistImage({
    required BuildContext context,
    required MyPlaylist playlist,
    required List<Song> playlistSongs,
  }) {
    String? albumArt = playlist.coverImage;
    bool isNetworkImage = false;

    if (albumArt == null || albumArt.isEmpty) {
      albumArt = playlistSongs.isNotEmpty ? playlistSongs.first.albumArt : null;
    }

    // Determine if it's a network image based on the URL
    if (albumArt != null && albumArt.isNotEmpty) {
      isNetworkImage =
          albumArt.startsWith('http://') || albumArt.startsWith('https://');
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: buildAlbumArt(
        context: context,
        albumArt: albumArt,
        defaultIcon: Icons.queue_music_rounded,
        defaultIconSize: 28.0,
        borderRadius: 8.r,
        isNetworkImage: isNetworkImage,
      ),
    );
  }

  /// Builds bottom padding for navigation
  static Widget buildBottomPadding() {
    return SliverToBoxAdapter(child: SizedBox(height: 150.h));
  }

  /// Helper method to trigger background loading after initial display
  static void triggerBackgroundLoading({
    required VoidCallback onLoadMore,
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Future.delayed(delay, () {
      try {
        onLoadMore();
      } catch (e) {
        // Silently handle any errors to prevent crashes
        debugPrint('Background loading error: $e');
      }
    }).catchError((error) {
      // Handle any Future errors
      debugPrint('Background loading Future error: $error');
    });
  }

  /// Helper method to check if lazy loading should be used
  static bool shouldUseLazyLoading<T>(List<T> items, int threshold) {
    return items.length > threshold;
  }
}
