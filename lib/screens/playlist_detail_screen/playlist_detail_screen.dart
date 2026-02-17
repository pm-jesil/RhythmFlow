import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/logger/logger.dart';
import '../../utils/models/playlist_source/playlist_source_model.dart';
import '../../utils/models/song/song_model.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../widgets/sorting_helper.dart';
import '../widgets/custom_music_floating_button.dart';
import '../widgets/album_art_widget.dart';
import '../../core/widgets/app_custom.dart';

enum PlaylistDetailType { album, artist, playlist }

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistDetailType type;
  final String id;
  final String name;
  final String? description;
  final String? year;
  final String? bio;
  final int songCount;
  final List<Song> songs;
  final String? coverImage;

  const PlaylistDetailScreen({
    super.key,
    required this.type,
    required this.id,
    required this.name,
    this.description,
    this.year,
    this.bio,
    required this.songCount,
    required this.songs,
    this.coverImage,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final AppLogger _logger = AppLogger('PlaylistDetailScreen');
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _filteredSongs = List.from(widget.songs);
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return CupertinoIcons.music_albums;
      case PlaylistDetailType.artist:
        return CupertinoIcons.person;
      case PlaylistDetailType.playlist:
        return CupertinoIcons.list_bullet;
    }
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return 'Album';
      case PlaylistDetailType.artist:
        return 'Artist';
      case PlaylistDetailType.playlist:
        return 'Playlist';
    }
  }

  PlaylistSource _getPlaylistSource() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return PlaylistSource.album(widget.id);
      case PlaylistDetailType.artist:
        return PlaylistSource.artist(widget.id);
      case PlaylistDetailType.playlist:
        return PlaylistSource.myPlaylist(widget.id);
    }
  }

  int _getAlbumCountForArtist() {
    if (widget.type != PlaylistDetailType.artist) return 0;
    final state = context.read<MusicBloc>().state;
    return state.albumList.where((album) => album.artistId == widget.id).length;
  }

  IconButton _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18.sp),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: context.backgroundGradient),
            child: BlocBuilder<MusicBloc, MusicState>(
              builder: (context, state) {
                // Update filtered songs when state changes
                if (_filteredSongs.isEmpty) {
                  _filteredSongs = List.from(widget.songs);
                }

                // Get cover image from first song or use default
                final coverImage = _filteredSongs.isNotEmpty
                    ? _filteredSongs.first.albumArt
                    : null;

                return CustomScrollView(
                  slivers: [
                    // Enhanced SliverAppBar with cover image background
                    SliverAppBar(
                      expandedHeight: 240.h,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      actions: [
                        // Only show edit and delete for my playlist items
                        if (widget.type == PlaylistDetailType.playlist) ...[
                          _buildActionButton(
                            context: context,
                            icon: CupertinoIcons.pencil,
                            onPressed: _showEditPlaylistDialog,
                          ),
                          _buildActionButton(
                            context: context,
                            icon: CupertinoIcons.delete,
                            onPressed: _showDeletePlaylistDialog,
                          ),
                        ],
                        // Sort button for all types
                        _buildActionButton(
                          context: context,
                          icon: CupertinoIcons.sort_down,
                          onPressed: _showSortingMenu,
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.primaryStart.withValues(alpha: 0.9),
                                context.primaryEnd.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Cover image background with blur effect
                              if (coverImage != null)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: FileImage(File(coverImage)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.3),
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Content overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      20.w,
                                      20.h,
                                      20.w,
                                      24.h,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Type Badge with improved design
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 8.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getTypeIcon(),
                                                color: Colors.white,
                                                size: 18.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                _getTypeTitle(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Poppins',
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 20.h),
                                        // Title with improved typography
                                        Text(
                                          widget.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 32.sp,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                            height: 1.2,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                offset: Offset(0, 2.h),
                                                blurRadius: 4.r,
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 12.h),
                                        // Description/Bio with better styling
                                        if (widget.description?.isNotEmpty ==
                                            true)
                                          Text(
                                            widget.description!,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.95,
                                              ),
                                              fontSize: 15.sp,
                                              fontFamily: 'Poppins',
                                              height: 1.4,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  offset: Offset(0, 1.h),
                                                  blurRadius: 2.r,
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        SizedBox(height: 16.h),
                                        // Enhanced Stats Row
                                        Wrap(
                                          spacing: 20.w,
                                          runSpacing: 8.h,
                                          children: [
                                            _buildStatItem(
                                              icon: CupertinoIcons.music_note,
                                              label:
                                                  '${widget.songCount} songs',
                                            ),
                                            if (widget.type ==
                                                PlaylistDetailType.artist)
                                              _buildStatItem(
                                                icon:
                                                    CupertinoIcons.music_albums,
                                                label:
                                                    '${_getAlbumCountForArtist()} albums',
                                              ),
                                            if (widget.year != null)
                                              _buildStatItem(
                                                icon: CupertinoIcons.calendar,
                                                label: widget.year!,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Compact Play All Button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: context.primaryGradient,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryStart.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),
                              onTap: _playAllSongs,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    // Play Icon
                                    Container(
                                      width: 36.w,
                                      height: 36.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          18.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.play_fill,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Text Content
                                    Expanded(
                                      child: Text(
                                        'Play All (${widget.songCount} songs)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                    // Enhanced Songs List
                    if (_filteredSongs.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.w),
                            child: Column(
                              children: [
                                Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: BoxDecoration(
                                    color: context.onSurfaceVariantColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(40.r),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.music_note_2,
                                    color: context.onSurfaceVariantColor,
                                    size: 40.sp,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'No songs found',
                                  style: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontSize: 18.sp,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Try adjusting your search',
                                  style: TextStyle(
                                    color: context.onSurfaceVariantColor
                                        .withValues(alpha: 0.7),
                                    fontSize: 14.sp,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final song = _filteredSongs[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: _buildEnhancedSongTile(
                                song,
                                false,
                                index + 1,
                              ),
                            );
                          }, childCount: _filteredSongs.length),
                        ),
                      ),

                    // Bottom padding for navigation
                    SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                  ],
                );
              },
            ),
          ),
          // Custom floating music button
          const CustomMusicFloatingButton(),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSongTile(Song song, bool isSelected, int index) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (previous, current) {
        final prevSongId = previous.myPlayerState.currentSongId;
        final currSongId = current.myPlayerState.currentSongId;
        final prevIsPlaying = previous.myPlayerState.isPlaying;
        final currIsPlaying = current.myPlayerState.isPlaying;

        return prevSongId != currSongId ||
            prevIsPlaying != currIsPlaying ||
            (prevSongId == song.id) != (currSongId == song.id);
      },
      builder: (context, state) {
        final isCurrentlyPlaying =
            state.myPlayerState.currentSongId == song.id &&
            state.myPlayerState.isPlaying;
        final isCurrentSong = state.myPlayerState.currentSongId == song.id;

        final isSelectedSong = isCurrentSong;

        return Container(
          decoration: BoxDecoration(
            color: isSelectedSong
                ? context.primaryStart.withValues(alpha: 0.12)
                : context.cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelectedSong
                  ? context.primaryStart.withValues(alpha: 0.4)
                  : context.onSurfaceColor.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: isSelectedSong
                ? [
                    BoxShadow(
                      color: context.primaryStart.withValues(alpha: 0.15),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => _playSong(song),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    // Album Art (default icon + gradient when no art; smooth transition to image)
                    AlbumArtWidget(
                      albumArt: song.albumArt,
                      width: 36.w,
                      height: 36.w,
                      borderRadius: 8.r,
                      boxShadow: isSelectedSong
                          ? [
                              BoxShadow(
                                color: context.primaryStart.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ]
                          : null,
                      defaultIconSize: 18.0,
                    ),

                    SizedBox(width: 10.w),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: isSelectedSong
                                  ? context.primaryStart
                                  : context.onSurfaceColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            song.artists.isNotEmpty
                                ? song.artists.first
                                : 'Unknown Artist',
                            style: TextStyle(
                              color: isSelectedSong
                                  ? context.primaryStart.withValues(alpha: 0.8)
                                  : context.onSurfaceVariantColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Duration and Play Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(song.duration),
                          style: TextStyle(
                            color: isSelectedSong
                                ? context.primaryStart
                                : context.onSurfaceVariantColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        _buildPlayButton(
                          context,
                          isCurrentlyPlaying,
                          isSelectedSong,
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

  Widget _buildPlayButton(
    BuildContext context,
    bool isPlaying,
    bool isSelected,
  ) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: isSelected
            ? context.primaryStart
            : context.onSurfaceVariantColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: context.primaryStart.withValues(alpha: 0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ]
            : null,
      ),
      child: Icon(
        isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
        color: isSelected ? Colors.white : context.onSurfaceVariantColor,
        size: 16.sp,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _playSong(Song song) {
    _logger.i("🎵 Playing song: ${song.title}");

    // CRITICAL: Don't set local _immediatelySelectedSongId here
    // Let the bloc state handle selection to prevent multiple songs being selected
    // The bloc will update currentSongId and trigger didChangeDependencies()

    // Play the song
    context.read<MusicBloc>().add(
      MusicEvent.playOrPauseSong(
        songId: song.id,
        currentPlayList: _filteredSongs.map((s) => s.id).toList(),
        playlistSource: _getPlaylistSource(),
      ),
    );
  }

  void _playAllSongs() {
    if (_filteredSongs.isNotEmpty) {
      _logger.i("🎵 Playing all songs from ${widget.name}");

      final songIds = _filteredSongs.map((song) => song.id).toList();
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(
          songId: songIds.first,
          currentPlayList: songIds,
          playlistSource: _getPlaylistSource(),
        ),
      );
    }
  }

  void _showSortingMenu() {
    SortingHelper.showSortingMenuWithCallback(
      context,
      onSortSelected: _applySortingToCurrentPlaylist,
    );
  }

  void _applySortingToCurrentPlaylist(int sortingIndex) {
    _logger.i(
      '🔄 Applying sorting to current playlist with index: $sortingIndex',
    );

    // Apply sorting to the current filtered songs using common helper
    final sortedSongs = SortingHelper.applySorting(
      _filteredSongs,
      sortingIndex,
    );

    // Update the filtered songs immediately
    setState(() {
      _filteredSongs = sortedSongs;
    });

    // Also update the bloc state for persistence
    context.read<MusicBloc>().add(
      MusicEvent.changeSortingOrder(
        sortingIndex: sortingIndex,
        sortingList: _filteredSongs.map((s) => s.id).toList(),
        playlistSource: _getPlaylistSource(),
      ),
    );
  }

  void _showEditPlaylistDialog() {
    final nameController = TextEditingController(text: widget.name);
    final descriptionController = TextEditingController(
      text: widget.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'Edit Playlist',
          style: TextStyle(color: context.onSurfaceColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: context.onSurfaceColor),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: context.onSurfaceVariantColor),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.onSurfaceVariantColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.primaryStart),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: context.onSurfaceColor),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: context.onSurfaceVariantColor),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.onSurfaceVariantColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.primaryStart),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _logger.i('Updating playlist: ${nameController.text}');

                context.read<MusicBloc>().add(
                  MusicEvent.addOrUpdateMyPlayList(
                    operation: MyPlaylistOperation.update,
                    playlistId: widget.id,
                    name: nameController.text,
                    description: descriptionController.text,
                  ),
                );

                Navigator.pop(context);
                AppCustom.success(
                  context,
                  'Playlist "${nameController.text}" updated!',
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog() {
    AppCustom.showDeleteConfirm(
      context: context,
      itemName: 'Playlist',
      customMessage:
          'Are you sure you want to delete "${widget.name}"? This action cannot be undone.',
      onConfirm: () {
        _logger.i('Deleting playlist: ${widget.name}');

        context.read<MusicBloc>().add(
          MusicEvent.addOrUpdateMyPlayList(
            operation: MyPlaylistOperation.delete,
            playlistId: widget.id,
          ),
        );

        Navigator.pop(context); // Go back to previous screen
        AppCustom.showPlaylistDeletedToast(context, widget.name);
      },
    );
  }
}
