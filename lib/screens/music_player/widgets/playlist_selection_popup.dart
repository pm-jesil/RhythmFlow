import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../utils/logger/logger.dart';
import '../../../../utils/models/song/song_model.dart';
import '../../../../utils/models/my_playlist/my_playlist_model.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/constants/app_enums.dart';
import '../../bottom_tab/screens/bloc/music_bloc.dart';
import '../../../core/widgets/app_custom.dart';

/// Comprehensive playlist selection popup widget
class PlaylistSelectionPopup extends StatefulWidget {
  final Song song;

  const PlaylistSelectionPopup({super.key, required this.song});

  @override
  State<PlaylistSelectionPopup> createState() => _PlaylistSelectionPopupState();
}

class _PlaylistSelectionPopupState extends State<PlaylistSelectionPopup> {
  final AppLogger _logger = AppLogger('PlaylistSelectionPopup');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Set<String> _selectedPlaylists = <String>{};
  final Set<String> _initialSelectedPlaylists = <String>{};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Check which playlists already contain this song and pre-select them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSongPresentPlaylist();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add,
                  color: context.primaryStart,
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Add to Playlist',
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: context.onSurfaceVariantColor,
                    size: 22.sp,
                  ),
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                ),
              ],
            ),
          ),

          // Scrollable Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Column(
                children: [
                  // Create playlist expansion tile
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.surfaceColor,
                          context.surfaceColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.primaryStart.withValues(alpha: 0.2),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : context.primaryStart.withValues(alpha: 0.1),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      childrenPadding: EdgeInsets.zero,
                      shape: Border(),
                      title: Text(
                        'Create New Playlist',
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      subtitle: Text(
                        'Add to a new playlist',
                        style: TextStyle(
                          color: context.onSurfaceVariantColor,
                          fontSize: 11.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      leading: Icon(
                        Icons.add_circle_outline,
                        color: context.primaryStart,
                        size: 20.sp,
                      ),
                      onExpansionChanged: (expanded) {
                        // Handle expansion state if needed
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Playlist Name',
                                  labelStyle: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontFamily: 'Poppins',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: context.surfaceColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.onSurfaceColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.w,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.onSurfaceColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.w,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.primaryStart,
                                      width: 2.w,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                style: TextStyle(
                                  color: context.onSurfaceColor,
                                  fontFamily: 'Poppins',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description (Optional)',
                                  labelStyle: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontFamily: 'Poppins',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: context.surfaceColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.onSurfaceColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.w,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.onSurfaceColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.w,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: context.primaryStart,
                                      width: 2.w,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                style: TextStyle(
                                  color: context.onSurfaceColor,
                                  fontFamily: 'Poppins',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                              ),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _isCreating
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              context.primaryStart.withValues(
                                                alpha: 0.6,
                                              ),
                                              context.primaryEnd.withValues(
                                                alpha: 0.6,
                                              ),
                                            ],
                                          )
                                        : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              context.primaryStart,
                                              context.primaryEnd,
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.primaryStart.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isCreating
                                        ? null
                                        : _createPlaylist,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                    ),
                                    child: _isCreating
                                        ? SizedBox(
                                            height: 18.h,
                                            width: 18.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Create & Add Song',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Available playlists
                  BlocBuilder<MusicBloc, MusicState>(
                    builder: (context, state) {
                      final playlists = state.myPlaylist.toList();

                      if (playlists.isEmpty) {
                        return SizedBox(
                          height: 200.h,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.queue_music_outlined,
                                  color: context.onSurfaceVariantColor,
                                  size: 48.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No playlists available',
                                  style: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontSize: 16.sp,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Create your first playlist above',
                                  style: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontSize: 14.sp,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Available Playlists',
                                style: TextStyle(
                                  color: context.onSurfaceColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const Spacer(),
                              if (_selectedPlaylists.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.primaryStart.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: context.primaryStart.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.5.w,
                                    ),
                                  ),
                                  child: Text(
                                    '${_selectedPlaylists.length} selected',
                                    style: TextStyle(
                                      color: context.primaryStart,
                                      fontSize: 11.sp,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              final isSelected = _selectedPlaylists.contains(
                                playlist.id,
                              );

                              return Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      context.surfaceColor,
                                      context.surfaceColor.withValues(
                                        alpha: 0.94,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: context.onSurfaceColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    width: 0.5.w,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedPlaylists.remove(playlist.id);
                                      } else {
                                        _selectedPlaylists.add(playlist.id);
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                  title: Text(
                                    playlist.name,
                                    style: TextStyle(
                                      color: context.onSurfaceColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${playlist.songCount} songs',
                                    style: TextStyle(
                                      color: context.onSurfaceVariantColor,
                                      fontSize: 11.sp,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: context.primaryStart,
                                          size: 20.sp,
                                        )
                                      : Icon(
                                          Icons.queue_music,
                                          color: context.onSurfaceVariantColor,
                                          size: 18.sp,
                                        ),
                                  dense: true,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Fixed Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.onSurfaceColor.withValues(alpha: 0.1),
                        context.onSurfaceColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.onSurfaceVariantColor.withValues(
                        alpha: 0.3,
                      ),
                      width: 1.w,
                    ),
                  ),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _hasChanges()
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [context.primaryStart, context.primaryEnd],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.onSurfaceColor.withValues(alpha: 0.3),
                              context.onSurfaceColor.withValues(alpha: 0.2),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: _hasChanges()
                        ? [
                            BoxShadow(
                              color: context.primaryStart.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _hasChanges() ? _addToSelectedPlaylists : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _hasChanges()
                          ? Colors.white
                          : context.onSurfaceVariantColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      _getButtonText(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createPlaylist() async {
    if (_nameController.text.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      _logger.i('📝 Creating playlist: ${_nameController.text}');

      // Create playlist with the current song
      context.read<MusicBloc>().add(
        MusicEvent.addOrUpdateMyPlayList(
          operation: MyPlaylistOperation.create,
          name: _nameController.text,
          description: _descriptionController.text,
          songIds: [widget.song.id],
        ),
      );

      // Clear form
      _nameController.clear();
      _descriptionController.clear();

      // Form cleared, expansion tile will auto-collapse

      AppCustom.showPlaylistCreatedToast(context, _nameController.text);
    } catch (e) {
      _logger.e('❌ Failed to create playlist', error: e);
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  /// Check if there are any changes from the initial state
  bool _hasChanges() {
    return !_setsEqual(_selectedPlaylists, _initialSelectedPlaylists);
  }

  /// Helper function to compare two sets for equality
  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  /// Get button text - always "Save"
  String _getButtonText() {
    return 'Save';
  }

  /// Check which playlists already contain the current song and pre-select them
  void _checkSongPresentPlaylist() {
    final state = context.read<MusicBloc>().state;
    final playlists = state.myPlaylist.toList();

    _logger.i('🔍 Checking song presence in ${playlists.length} playlists');

    final Set<String> playlistsWithSong = <String>{};

    for (final playlist in playlists) {
      if (playlist.songIds.contains(widget.song.id)) {
        playlistsWithSong.add(playlist.id);
        _logger.d('✅ Song found in playlist: ${playlist.name}');
      }
    }

    if (playlistsWithSong.isNotEmpty) {
      setState(() {
        _selectedPlaylists.addAll(playlistsWithSong);
        _initialSelectedPlaylists.addAll(playlistsWithSong);
      });
      _logger.i(
        '📋 Pre-selected ${playlistsWithSong.length} playlists that already contain this song',
      );
    }
  }

  void _addToSelectedPlaylists() {
    if (!_hasChanges()) {
      _logger.i('ℹ️ No changes detected, skipping update');
      return;
    }

    _logger.i('➕ Processing ${_selectedPlaylists.length} playlist selections');

    // Use the initial state to determine changes
    final Set<String> playlistsToAddTo = _selectedPlaylists.difference(
      _initialSelectedPlaylists,
    );
    final Set<String> playlistsToRemoveFrom = _initialSelectedPlaylists
        .difference(_selectedPlaylists);

    _logger.i('➕ Adding to ${playlistsToAddTo.length} playlists');
    _logger.i('➖ Removing from ${playlistsToRemoveFrom.length} playlists');

    // Add song to new playlists
    for (final playlistId in playlistsToAddTo) {
      context.read<MusicBloc>().add(
        MusicEvent.addOrUpdateMyPlayList(
          operation: MyPlaylistOperation.addSong,
          playlistId: playlistId,
          songId: widget.song.id,
        ),
      );
    }

    // Remove song from deselected playlists
    for (final playlistId in playlistsToRemoveFrom) {
      context.read<MusicBloc>().add(
        MusicEvent.addOrUpdateMyPlayList(
          operation: MyPlaylistOperation.removeSong,
          playlistId: playlistId,
          songId: widget.song.id,
        ),
      );
    }

    Navigator.of(context).pop();

    // Show appropriate success message
    String message;
    if (playlistsToAddTo.isNotEmpty && playlistsToRemoveFrom.isNotEmpty) {
      message =
          'Song updated in ${playlistsToAddTo.length + playlistsToRemoveFrom.length} playlists';
    } else if (playlistsToAddTo.isNotEmpty) {
      message =
          'Song added to ${playlistsToAddTo.length} playlist${playlistsToAddTo.length == 1 ? '' : 's'}!';
    } else if (playlistsToRemoveFrom.isNotEmpty) {
      if (_selectedPlaylists.isEmpty && _initialSelectedPlaylists.isNotEmpty) {
        message = 'Song removed from all playlists!';
      } else {
        message =
            'Song removed from ${playlistsToRemoveFrom.length} playlist${playlistsToRemoveFrom.length == 1 ? '' : 's'}!';
      }
    } else {
      message = 'No changes made';
    }

    AppCustom.success(context, message);
  }
}
