import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/services/media_store_bridge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';


import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/app_custom.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../bloc/music_bloc.dart';
import '../../music_player/widgets/playlist_selection_popup.dart';
import 'album_artist_my_playlist_helper.dart';

/// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Handles all song context menu actions
class SongContextMenuActions {
  static final AppLogger _logger = AppLogger('SongContextMenuActions');

  /// Main dispatcher for all menu actions
  static void handleMenuAction({
    required BuildContext context,
    required String action,
    required String songId,
    required String songTitle,
    required String artistName,
    required String albumName,
  }) {
    _logger.i('🎯 Menu action: $action for $songTitle');

    switch (action) {
      case 'share':
        _handleShareSong(context, songId, songTitle, artistName, albumName);
        break;
      case 'info':
        _handleShowSongInfo(context, songId, songTitle, artistName, albumName);
        break;
      case 'playlist':
        _handleAddToPlaylist(context, songId, songTitle, artistName, albumName);
        break;
      case 'album':
        _handleNavigateToAlbum(
          context,
          songId,
          songTitle,
          artistName,
          albumName,
        );
        break;
      case 'artist':
        _handleNavigateToArtist(
          context,
          songId,
          songTitle,
          artistName,
          albumName,
        );
        break;
      case 'delete':
        _handleDeleteSong(context, songId, songTitle);
        break;
      default:
        _logger.w('⚠️ Unknown menu action: $action');
    }
  }

  /// Handle song deletion
  static void _handleDeleteSong(
    BuildContext context,
    String songId,
    String songTitle,
  ) async {
    _logger.i('🗑️ Handling delete for song: $songTitle (ID: $songId)');

    // Capture context before async operations
    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();

    // Show confirmation dialog using AppCustom
    final shouldDelete = await AppCustom.showDeleteConfirm(
      context: currentContext,
      itemName: 'Song',
      customMessage:
          'Are you sure you want to delete "$songTitle" from your device? This will permanently remove the file and cannot be undone.',
    );

    if (shouldDelete != true) return;

    // Find the song to delete
    final musicState = musicBloc.state;
    final song = musicState.allSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => Song(
        id: songId,
        title: songTitle,
        artists: [],
        albums: [],
        duration: const Duration(seconds: 0),
        path: '',
      ),
    );

    if (song.path.isEmpty) {
      _logger.w('⚠️ Song path is empty, cannot delete file');
      AppCustom.error(currentContext, 'Cannot delete: Song path not found');
      return;
    }

    try {
      // Android 11+ shows the system "allow delete" dialog here.
      final deleted = await MediaStoreBridge.deleteAudioFile(song.path);
      if (deleted) {
        _logger.i('✅ File deleted successfully from device storage');

        // Remove the song (and every reference to it) directly instead of
        // rescanning the whole device.
        musicBloc.add(MusicEvent.removeSongs(songIds: [song.id]));

        if (currentContext.mounted) {
          AppCustom.showSongDeletedToast(currentContext, songTitle);
        }
      } else {
        _logger.w('⚠️ Delete cancelled or file not removed: ${song.path}');
        if (currentContext.mounted) {
          AppCustom.error(currentContext, 'Song was not deleted');
        }
      }
    } catch (e) {
      _logger.e('❌ Delete failed: $e');
      AppCustom.error(currentContext, 'Error deleting song: $e');
    }
  }

  /// Handle song sharing
  static void _handleShareSong(
    BuildContext context,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) async {
    _logger.i('📤 Sharing song: $songTitle');

    // Capture context before async operations
    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();

    try {
      final musicState = musicBloc.state;
      final song = musicState.allSongs.firstWhere(
        (s) => s.id == songId,
        orElse: () => Song(
          id: songId,
          title: songTitle,
          artists: [artistName],
          albums: [albumName],
          duration: const Duration(seconds: 0),
          path: '',
        ),
      );

      if (song.path.isNotEmpty && await File(song.path).exists()) {
        await Share.shareXFiles(
          [XFile(song.path)],
          text: 'Check out this song: "$songTitle" by $artistName',
          subject: '$songTitle - $artistName',
        );
      } else {
        await Share.share(
          'Check out this song: "$songTitle" by $artistName from album "$albumName"',
          subject: '$songTitle - $artistName',
        );
      }
    } catch (e) {
      _logger.e('Share failed: $e');
      AppCustom.error(currentContext, 'Error sharing song: $e');
    }
  }

  /// Handle showing song information
  static void _handleShowSongInfo(
    BuildContext context,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) {
    _logger.i('ℹ️ Showing song info: $songTitle');

    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();

    final musicState = musicBloc.state;
    final song = musicState.allSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => Song(
        id: songId,
        title: songTitle,
        artists: [artistName],
        albums: [albumName],
        duration: const Duration(seconds: 0),
        path: '',
      ),
    );

    AppCustom.showPopup(
      context: currentContext,
      title: 'Song Information',
      icon: Icons.info_outline,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(currentContext, 'Title', song.title),
            _buildInfoRow(currentContext, 'Artist', song.artists.join(', ')),
            _buildInfoRow(currentContext, 'Album', song.albums.join(', ')),
            _buildInfoRow(
              currentContext,
              'Duration',
              _formatDuration(song.duration),
            ),
            _buildInfoRow(
              currentContext,
              'File Path',
              song.path.isNotEmpty ? song.path : 'Not available',
            ),
            if (song.genre != null && song.genre!.isNotEmpty)
              _buildInfoRow(currentContext, 'Genre', song.genre!),
            if (song.year != null)
              _buildInfoRow(currentContext, 'Year', song.year.toString()),
            if (song.bitrate != null)
              _buildInfoRow(currentContext, 'Bitrate', '${song.bitrate} kbps'),
            if (song.fileSize != null)
              _buildInfoRow(
                currentContext,
                'File Size',
                song.formattedFileSize,
              ),
            if (song.trackNumber != null)
              _buildInfoRow(
                currentContext,
                'Track',
                song.trackNumber.toString(),
              ),
            if (song.composer != null && song.composer!.isNotEmpty)
              _buildInfoRow(currentContext, 'Composer', song.composer!),
            if (song.playCount != null)
              _buildInfoRow(
                currentContext,
                'Play Count',
                song.playCount.toString(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(currentContext),
          child: Text(
            'Close',
            style: TextStyle(
              color: currentContext.primaryStart,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Handle adding song to playlist
  static void _handleAddToPlaylist(
    BuildContext context,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) {
    _logger.i('📝 Adding to playlist: $songTitle');

    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();

    final musicState = musicBloc.state;
    final song = musicState.allSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => Song(
        id: songId,
        title: songTitle,
        artists: [artistName],
        albums: [albumName],
        duration: const Duration(seconds: 0),
        path: '',
      ),
    );

    AppCustom.showBottomSheet(
      context: currentContext,
      child: PlaylistSelectionPopup(song: song),
    );
  }

  /// Handle navigation to album with multiple match handling
  static void _handleNavigateToAlbum(
    BuildContext context,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) {
    _handleNavigateToMedia(
      context: context,
      mediaName: albumName,
      mediaType: 'album',
      logPrefix: '🎵',
    );
  }

  /// Handle navigation to artist with multiple match handling
  static void _handleNavigateToArtist(
    BuildContext context,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) {
    _handleNavigateToMedia(
      context: context,
      mediaName: artistName,
      mediaType: 'artist',
      logPrefix: '🎤',
    );
  }

  /// Generic navigation handler for both albums and artists
  static void _handleNavigateToMedia({
    required BuildContext context,
    required String mediaName,
    required String mediaType,
    required String logPrefix,
  }) {
    _logger.i('$logPrefix Navigating to $mediaType: $mediaName');

    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();
    final musicState = musicBloc.state;

    // Get matching items based on media type
    final matchingItems = _getMatchingItems(musicState, mediaName, mediaType);

    if (matchingItems.isEmpty) {
      _logger.w('⚠️ No ${mediaType}s found matching: $mediaName');
      AppCustom.warning(
        currentContext,
        'No ${mediaType}s found matching "$mediaName"',
      );
      return;
    }

    if (matchingItems.length == 1) {
      // Single match - navigate directly
      _logger.i('✅ Single $mediaType match found, navigating directly');
      _navigateToSpecificMedia(currentContext, matchingItems.first, mediaType);
    } else {
      // Multiple matches - show selection popup
      _logger.i(
        '🔍 Multiple $mediaType matches found (${matchingItems.length}), showing selection popup',
      );
      _showMediaSelectionPopup(
        currentContext,
        matchingItems,
        mediaName,
        mediaType,
      );
    }
  }

  /// Get matching items based on media type
  static List<dynamic> _getMatchingItems(
    MusicState musicState,
    String mediaName,
    String mediaType,
  ) {
    switch (mediaType) {
      case 'album':
        return musicState.albumList
            .where(
              (album) =>
                  album.name.toLowerCase().trim() ==
                  mediaName.toLowerCase().trim(),
            )
            .toList();
      case 'artist':
        return musicState.artistList
            .where(
              (artist) =>
                  artist.name.toLowerCase().trim() ==
                  mediaName.toLowerCase().trim(),
            )
            .toList();
      default:
        return [];
    }
  }

  /// Navigate to specific media item
  static void _navigateToSpecificMedia(
    BuildContext context,
    dynamic mediaItem,
    String mediaType,
  ) {
    switch (mediaType) {
      case 'album':
        AlbumArtistPlaylistHelper.navigateToAlbumDetail(
          context: context,
          album: mediaItem as Album,
        );
        break;
      case 'artist':
        AlbumArtistPlaylistHelper.navigateToArtistDetail(
          context: context,
          artist: mediaItem as Artist,
        );
        break;
    }
  }

  /// Show media selection popup for multiple matches
  static void _showMediaSelectionPopup(
    BuildContext context,
    List<dynamic> items,
    String mediaName,
    String mediaType,
  ) {
    // Limit to first 2 items as requested
    final displayItems = items.take(2).toList();

    AppCustom.showPopup(
      context: context,
      title: 'Multiple ${mediaType.capitalize()}s Found',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Found multiple ${mediaType}s named "$mediaName". Please select one:',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 16.h),
          ...displayItems.map(
            (item) => _buildMediaSelectionTile(context, item, mediaType),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.onSurfaceVariantColor),
          ),
        ),
      ],
    );
  }

  /// Build media selection tile with arrow (works for both albums and artists)
  static Widget _buildMediaSelectionTile(
    BuildContext context,
    dynamic mediaItem,
    String mediaType,
  ) {
    final musicBloc = context.read<MusicBloc>();
    final musicState = musicBloc.state;

    String name;
    String songCount;
    Widget imageWidget;

    if (mediaType == 'album') {
      final album = mediaItem as Album;
      final albumSongs = AlbumArtistPlaylistHelper.getAlbumSongs(
        album,
        musicState.allSongs,
      );
      name = album.name;
      songCount = '${albumSongs.length} songs';

      imageWidget = Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          color: context.primaryStart.withValues(alpha: 0.1),
        ),
        child: album.coverImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Image.network(
                  album.coverImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    CupertinoIcons.music_albums,
                    color: context.primaryStart,
                    size: 20.sp,
                  ),
                ),
              )
            : Icon(CupertinoIcons.music_albums, color: context.primaryStart, size: 20.sp),
      );
    } else {
      final artist = mediaItem as Artist;
      final artistSongs = AlbumArtistPlaylistHelper.getArtistSongs(
        artist,
        musicState.allSongs,
      );
      name = artist.name;
      songCount = '${artistSongs.length} songs';

      imageWidget = Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: context.primaryStart.withValues(alpha: 0.1),
        ),
        child: artist.image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Image.network(
                  artist.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    CupertinoIcons.person,
                    color: context.primaryStart,
                    size: 20.sp,
                  ),
                ),
              )
            : Icon(CupertinoIcons.person, color: context.primaryStart, size: 20.sp),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            _navigateToSpecificMedia(context, mediaItem, mediaType);
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: context.onSurfaceVariantColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Media image
                imageWidget,
                SizedBox(width: 12.w),
                // Media info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        songCount,
                        style: TextStyle(
                          color: context.onSurfaceVariantColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  CupertinoIcons.chevron_right,
                  color: context.onSurfaceVariantColor,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }







  /// Build info row for song information display
  static Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format duration for display
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
