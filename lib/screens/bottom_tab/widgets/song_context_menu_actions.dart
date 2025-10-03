import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/app_custom.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/services/permission_service.dart';
import '../../../utils/services/ringtone_service.dart';
import '../screens/bloc/music_bloc.dart';
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
        _handleNavigateToAlbum(context, songId, songTitle, artistName, albumName);
        break;
      case 'artist':
        _handleNavigateToArtist(context, songId, songTitle, artistName, albumName);
        break;
      case 'ringtone':
        _handleSetRingtone(context, songId, songTitle, artistName, albumName);
        break;
      case 'delete':
        _handleDeleteSong(context, songId, songTitle);
        break;
      default:
        _logger.w('⚠️ Unknown menu action: $action');
    }
  }

  /// Handle song deletion
  static void _handleDeleteSong(BuildContext context, String songId, String songTitle) async {
    _logger.i('🗑️ Handling delete for song: $songTitle (ID: $songId)');

    // Capture context before async operations
    final currentContext = context;
    final musicBloc = currentContext.read<MusicBloc>();

    // Show confirmation dialog using AppCustom
    final shouldDelete = await AppCustom.showDeleteConfirm(
      context: currentContext,
      itemName: 'Song',
      customMessage: 'Are you sure you want to delete "$songTitle" from your device? This will permanently remove the file and cannot be undone.',
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
      // Delete the file
      final file = File(song.path);
      if (await file.exists()) {
        await file.delete();
        _logger.i('✅ File deleted successfully from device storage');

        // Refresh song list
        _logger.i('🔄 Refreshing song list to remove deleted song');
        musicBloc.add(const MusicEvent.fetchAndUpdateSongs(isForce: true));

        // Show success toast
        AppCustom.showSongDeletedToast(currentContext, songTitle);
      } else {
        _logger.w('⚠️ File does not exist at path: ${song.path}');
        AppCustom.error(currentContext, 'Cannot delete: File not found on device');
      }
    } catch (e) {
      _logger.e('❌ Delete failed: $e');
      AppCustom.error(currentContext, 'Error deleting song: $e');
    }
  }

  /// Handle song sharing
  static void _handleShareSong(BuildContext context, String songId, String songTitle, String artistName, String albumName) async {
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
  static void _handleShowSongInfo(BuildContext context, String songId, String songTitle, String artistName, String albumName) {
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
            _buildInfoRow(currentContext, 'Duration', _formatDuration(song.duration)),
            _buildInfoRow(currentContext, 'File Path', song.path.isNotEmpty ? song.path : 'Not available'),
            if (song.genre != null && song.genre!.isNotEmpty) _buildInfoRow(currentContext, 'Genre', song.genre!),
            if (song.year != null) _buildInfoRow(currentContext, 'Year', song.year.toString()),
            if (song.bitrate != null) _buildInfoRow(currentContext, 'Bitrate', '${song.bitrate} kbps'),
            if (song.fileSize != null) _buildInfoRow(currentContext, 'File Size', song.formattedFileSize),
            if (song.trackNumber != null) _buildInfoRow(currentContext, 'Track', song.trackNumber.toString()),
            if (song.composer != null && song.composer!.isNotEmpty) _buildInfoRow(currentContext, 'Composer', song.composer!),
            if (song.playCount != null) _buildInfoRow(currentContext, 'Play Count', song.playCount.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(currentContext),
          child: Text('Close', style: TextStyle(color: currentContext.primaryStart, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  /// Handle adding song to playlist
  static void _handleAddToPlaylist(BuildContext context, String songId, String songTitle, String artistName, String albumName) {
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
  static void _handleNavigateToAlbum(BuildContext context, String songId, String songTitle, String artistName, String albumName) {
    _handleNavigateToMedia(
      context: context,
      mediaName: albumName,
      mediaType: 'album',
      logPrefix: '🎵',
    );
  }

  /// Handle navigation to artist with multiple match handling
  static void _handleNavigateToArtist(BuildContext context, String songId, String songTitle, String artistName, String albumName) {
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
      AppCustom.warning(currentContext, 'No ${mediaType}s found matching "$mediaName"');
      return;
    }
    
    if (matchingItems.length == 1) {
      // Single match - navigate directly
      _logger.i('✅ Single $mediaType match found, navigating directly');
      _navigateToSpecificMedia(currentContext, matchingItems.first, mediaType);
    } else {
      // Multiple matches - show selection popup
      _logger.i('🔍 Multiple $mediaType matches found (${matchingItems.length}), showing selection popup');
      _showMediaSelectionPopup(currentContext, matchingItems, mediaName, mediaType);
    }
  }

  /// Get matching items based on media type
  static List<dynamic> _getMatchingItems(MusicState musicState, String mediaName, String mediaType) {
    switch (mediaType) {
      case 'album':
        return musicState.albumList
            .where((album) => album.name.toLowerCase().trim() == mediaName.toLowerCase().trim())
            .toList();
      case 'artist':
        return musicState.artistList
            .where((artist) => artist.name.toLowerCase().trim() == mediaName.toLowerCase().trim())
            .toList();
      default:
        return [];
    }
  }

  /// Navigate to specific media item
  static void _navigateToSpecificMedia(BuildContext context, dynamic mediaItem, String mediaType) {
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
  static void _showMediaSelectionPopup(BuildContext context, List<dynamic> items, String mediaName, String mediaType) {
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
          ...displayItems.map((item) => _buildMediaSelectionTile(context, item, mediaType)),
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
  static Widget _buildMediaSelectionTile(BuildContext context, dynamic mediaItem, String mediaType) {
    final musicBloc = context.read<MusicBloc>();
    final musicState = musicBloc.state;
    
    String name;
    String songCount;
    Widget imageWidget;
    
    if (mediaType == 'album') {
      final album = mediaItem as Album;
      final albumSongs = AlbumArtistPlaylistHelper.getAlbumSongs(album, musicState.allSongs);
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
                    Icons.album,
                    color: context.primaryStart,
                    size: 20.sp,
                  ),
                ),
              )
            : Icon(
                Icons.album,
                color: context.primaryStart,
                size: 20.sp,
              ),
      );
    } else {
      final artist = mediaItem as Artist;
      final artistSongs = AlbumArtistPlaylistHelper.getArtistSongs(artist, musicState.allSongs);
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
                    Icons.person,
                    color: context.primaryStart,
                    size: 20.sp,
                  ),
                ),
              )
            : Icon(
                Icons.person,
                color: context.primaryStart,
                size: 20.sp,
              ),
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
                  Icons.arrow_forward_ios,
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

  /// Handle setting song as ringtone with comprehensive user scenarios
  static void _handleSetRingtone(BuildContext context, String songId, String songTitle, String artistName, String albumName) async {
    _logger.i('🔔 Setting ringtone: $songTitle');
    
    final currentContext = context;
    
    try {
      // SCENARIO 1: Check if device supports ringtone setting
      if (!await _checkDeviceSupport(currentContext)) {
        return;
      }

      // SCENARIO 2: Get song details with comprehensive fallback
      final song = await _getSongDetails(currentContext, songId, songTitle, artistName, albumName);
      if (song == null) {
        return;
      }

      // SCENARIO 3: Validate song file exists and is accessible
      if (!await _validateSongFile(currentContext, song)) {
        return;
      }

      // SCENARIO 4: Check file format compatibility
      if (!await _checkFileFormat(currentContext, song)) {
        return;
      }

      // SCENARIO 5: Show enhanced ringtone selection dialog
      await _showRingtoneSelectionDialog(currentContext, song);
      
    } catch (e) {
      _logger.e('❌ Error setting ringtone: $e');
      AppCustom.error(currentContext, 'Error setting ringtone: $e');
    }
  }

  /// Check if device supports ringtone setting
  static Future<bool> _checkDeviceSupport(BuildContext context) async {
    try {
      final deviceSupport = await PermissionService.checkDeviceSupport();
      if (!deviceSupport) {
        AppCustom.warning(context, 'Ringtone setting is only available on Android devices.');
        return false;
      }
      return true;
    } catch (e) {
      _logger.e('❌ Error checking device support: $e');
      AppCustom.error(context, 'Error checking device compatibility');
      return false;
    }
  }

  /// Get song details with comprehensive fallback
  static Future<Song?> _getSongDetails(BuildContext context, String songId, String songTitle, String artistName, String albumName) async {
    try {
      final musicBloc = context.read<MusicBloc>();
      final musicState = musicBloc.state;
      
      // Try to find song in current state
      Song? song = musicState.allSongs.where((s) => s.id == songId).firstOrNull;
      
      if (song == null) {
        _logger.w('⚠️ Song not found in current state, creating fallback');
        // Create fallback song with provided details
        song = Song(
          id: songId,
          title: songTitle,
          artists: artistName.isNotEmpty ? [artistName] : ['Unknown Artist'],
          albums: albumName.isNotEmpty ? [albumName] : ['Unknown Album'],
          duration: const Duration(seconds: 0),
          path: '',
        );
        
        // Try to find by title if ID doesn't match
        final songByTitle = musicState.allSongs.where((s) => s.title.toLowerCase() == songTitle.toLowerCase()).firstOrNull;
        if (songByTitle != null) {
          song = songByTitle;
          _logger.i('✅ Found song by title: ${song.title}');
        }
      }

      if (song.path.isEmpty) {
        AppCustom.error(context, 'Cannot set ringtone: Song file path not available');
        return null;
      }

      return song;
    } catch (e) {
      _logger.e('❌ Error getting song details: $e');
      AppCustom.error(context, 'Error retrieving song information');
      return null;
    }
  }

  /// Validate song file exists and is accessible
  static Future<bool> _validateSongFile(BuildContext context, Song song) async {
    try {
      final file = File(song.path);
      
      if (!await file.exists()) {
        _logger.w('⚠️ Song file not found: ${song.path}');
        AppCustom.error(context, 'Cannot set ringtone: Song file not found on device');
        return false;
      }

      // Check file size (too small might be corrupted)
      final fileSize = await file.length();
      if (fileSize < 1024) { // Less than 1KB
        _logger.w('⚠️ Song file too small: ${fileSize} bytes');
        AppCustom.error(context, 'Cannot set ringtone: Song file appears to be corrupted or empty');
        return false;
      }

      // Check if file is readable
      try {
        await file.openRead().first;
      } catch (e) {
        _logger.w('⚠️ Song file not readable: $e');
        AppCustom.error(context, 'Cannot set ringtone: Song file is not accessible');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('❌ Error validating song file: $e');
      AppCustom.error(context, 'Error validating song file');
      return false;
    }
  }

  /// Check file format compatibility
  static Future<bool> _checkFileFormat(BuildContext context, Song song) async {
    try {
      final filePath = song.path.toLowerCase();
      final supportedFormats = ['.mp3', '.wav', '.ogg', '.m4a', '.aac'];
      
      final hasSupportedFormat = supportedFormats.any((format) => filePath.endsWith(format));
      
      if (!hasSupportedFormat) {
        _logger.w('⚠️ Unsupported file format: ${song.path}');
        AppCustom.warning(
          context, 
          'This file format may not work as a ringtone. Supported formats: MP3, WAV, OGG, M4A, AAC'
        );
        // Don't return false, let user try anyway
      }

      return true;
    } catch (e) {
      _logger.e('❌ Error checking file format: $e');
      return true; // Don't block on format check errors
    }
  }

  /// Show enhanced ringtone selection dialog
  static Future<void> _showRingtoneSelectionDialog(BuildContext context, Song song) async {
    await AppCustom.showPopup(
      context: context,
      title: 'Set as Ringtone',
      icon: Icons.ring_volume,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song info header
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: context.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: context.primaryStart.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.artists.isNotEmpty)
                  Text(
                    song.artists.join(', '),
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'Choose how to set this song:',
            style: TextStyle(
              color: context.onSurfaceVariantColor, 
              fontSize: 14.sp, 
              fontWeight: FontWeight.w500
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Ringtone options
          _buildRingtoneOption(context, Icons.phone, 'Ringtone', 'Set as default ringtone', () => _setRingtoneType(context, song, 'ringtone')),
          _buildRingtoneOption(context, Icons.notifications, 'Notification', 'Set as notification sound', () => _setRingtoneType(context, song, 'notification')),
          _buildRingtoneOption(context, Icons.alarm, 'Alarm', 'Set as alarm sound', () => _setRingtoneType(context, song, 'alarm')),
          
          SizedBox(height: 8.h),
          
          // Info text
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: context.onSurfaceColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: context.onSurfaceVariantColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'You may need to grant permission to modify system settings',
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel', 
            style: TextStyle(
              color: context.onSurfaceVariantColor, 
              fontSize: 14.sp, 
              fontWeight: FontWeight.w600
            )
          ),
        ),
      ],
    );
  }

  /// Build ringtone option widget
  static Widget _buildRingtoneOption(BuildContext ctx, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: ctx.primaryStart, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: ctx.onSurfaceColor, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: ctx.onSurfaceVariantColor, fontSize: 12.sp)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: ctx.onSurfaceVariantColor, size: 16.sp),
            ],
          ),
        ),
      ),
    );
  }

  /// Set ringtone type (ringtone, notification, alarm)
  static void _setRingtoneType(BuildContext dialogContext, Song song, String type) async {
    Navigator.pop(dialogContext); // Close the selection dialog
    
    final currentContext = dialogContext;
    
    try {
      _logger.i('🔔 Setting $type for: ${song.title}');
      
      // Check if WRITE_SETTINGS permission is granted
      if (!await _checkWriteSettingsPermission(currentContext)) {
        _logger.w('⚠️ WRITE_SETTINGS permission not granted');
        return;
      }
      
      // Show loading popup
      await AppCustom.showLoadingPopup(
        context: currentContext,
        message: 'Setting $type...',
      );

      // Set the ringtone based on type
      bool success = false;
      String typeName = '';
      
      switch (type) {
        case 'ringtone':
          success = await RingtoneService.setAsRingtone(
            filePath: song.path,
            songTitle: song.title,
          );
          typeName = 'ringtone';
          break;
        case 'notification':
          success = await RingtoneService.setAsNotification(
            filePath: song.path,
            songTitle: song.title,
          );
          typeName = 'notification sound';
          break;
        case 'alarm':
          success = await RingtoneService.setAsAlarm(
            filePath: song.path,
            songTitle: song.title,
          );
          typeName = 'alarm sound';
          break;
      }

      // Close loading popup
      Navigator.pop(currentContext);

      if (success) {
        _logger.i('✅ Successfully set $typeName: ${song.title}');
        AppCustom.showRingtoneSetToast(currentContext, song.title, typeName);
      } else {
        _logger.w('⚠️ Failed to set $typeName: ${song.title}');
        AppCustom.error(currentContext, 'Failed to set $typeName. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }
      
      _logger.e('❌ Error setting $type: $e');
      AppCustom.error(currentContext, 'Error setting $type: $e');
    }
  }

  /// Check and request WRITE_SETTINGS permission
  static Future<bool> _checkWriteSettingsPermission(BuildContext context) async {
    try {
      // Check if permission is already granted
      if (await PermissionService.checkWriteSettingsPermission()) {
        return true;
      }

      // Show permission request dialog
      final shouldRequest = await AppCustom.showConfirm(
        context: context,
        title: 'Permission Required',
        message: 'To set ringtones, this app needs permission to modify system settings. This is a security feature to protect your device.',
        confirmText: 'Open Settings',
        cancelText: 'Cancel',
      );

      if (shouldRequest == true) {
        // Open system settings for WRITE_SETTINGS permission
        await PermissionService.requestWriteSettingsPermission(context);
        
        // Check again after user returns
        if (await PermissionService.checkWriteSettingsPermission()) {
          AppCustom.success(context, 'Permission granted! You can now set ringtones.');
          return true;
        } else {
          AppCustom.warning(context, 'Permission not granted. You cannot set ringtones without this permission.');
          return false;
        }
      } else {
        AppCustom.info(context, 'Permission required to set ringtones. You can enable it later in Settings.');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error checking WRITE_SETTINGS permission: $e');
      AppCustom.error(context, 'Error checking permission: $e');
      return false;
    }
  }

  /// Build info row for song information display
  static Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text('$label:', style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: context.onSurfaceColor, fontSize: 12.sp, fontWeight: FontWeight.w400)),
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
