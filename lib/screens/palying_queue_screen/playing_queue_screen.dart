import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/playlist_source_helper.dart';
import '../../../core/widgets/app_custom.dart';

class PlayingQueueScreen extends StatefulWidget {
  const PlayingQueueScreen({super.key});

  @override
  State<PlayingQueueScreen> createState() => _PlayingQueueScreenState();
}

class _PlayingQueueScreenState extends State<PlayingQueueScreen> {
  static final AppLogger _logger = AppLogger('PlayingQueueScreen');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: context.onSurfaceColor,
              size: 28.sp,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.queue_music, color: context.primaryStart, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Playing Queue',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                _showQueueOptions(context);
              },
              icon: Icon(
                Icons.more_vert,
                color: context.onSurfaceColor,
                size: 20.sp,
              ),
            ),
          ],
        ),
        body: BlocBuilder<MusicBloc, MusicState>(
          builder: (context, state) {
            if (state.myPlayerState.currentPlayList.isEmpty) {
              return _buildEmptyQueue();
            }

            return _buildQueueList(state);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 64.sp,
            color: context.onSurfaceVariantColor,
          ),
          SizedBox(height: 16.h),
          Text(
            'No songs in queue',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start playing music to see the queue',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(MusicState state) {
    final currentSongId = state.myPlayerState.currentSongId;
    final currentPlayList = state.myPlayerState.currentPlayList;
    final completedSongs = state.myPlayerState.completedSongs;

    // Get songs from current playlist in the same order (excluding completed songs)
    final queueSongs = <Song>[];
    Song? currentSong;

    for (final songId in currentPlayList) {
      // Skip completed songs - they won't be shown in the queue
      if (!completedSongs.contains(songId)) {
        try {
          // Queues can hold Discover (online) songs, which are not in
          // allSongs; resolve through the bloc.
          final song = context.read<MusicBloc>().findSong(songId) ??
              (throw StateError('missing'));
          if (songId == currentSongId) {
            currentSong = song;
          }
          queueSongs.add(
            song,
          ); // Add all songs (including current) to maintain order
        } catch (e) {
          _logger.w('Song not found in library or Discover: $songId');
        }
      }
    }

    return Column(
      children: [
        // Queue Info
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: context.primaryStart,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '${queueSongs.length + (currentSong != null ? 1 : 0)} songs in queue',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              if (state.myPlayerState.completedSongs.isNotEmpty)
                Text(
                  '${state.myPlayerState.completedSongs.length} completed',
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 12.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),

        // Fixed Current Playing Song
        if (currentSong != null)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildCurrentPlayingTile(currentSong, state),
          ),

        // Up Next Label
        if (queueSongs.length > 1)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.queue_music,
                  color: context.primaryStart,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Up Next',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

        // Remaining Songs List (excluding current song)
        Expanded(
          child: queueSongs.length <= 1
              ? Center(
                  child: Text(
                    'No more songs in queue',
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: queueSongs.length - 1, // Exclude current song
                  onReorder: (oldIndex, newIndex) {
                    _reorderQueueSongs(
                      state,
                      oldIndex + 1,
                      newIndex + 1,
                    ); // +1 because current song is at index 0
                  },
                  itemBuilder: (context, index) {
                    final song =
                        queueSongs[index + 1]; // Skip current song (index 0)

                    return _buildQueueSongTile(
                      key: ValueKey(song.id),
                      song: song,
                      index: index + 1, // +1 because current song is at index 0
                      isCurrentSong: false,
                      state: state,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCurrentPlayingTile(Song song, MusicState state) {
    return Container(
      decoration: BoxDecoration(
        color: context.primaryStart.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryStart.withValues(alpha: 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryStart.withValues(alpha: 0.25),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            _logger.d("🎵 Tapping current playing song: ${song.title}");

            // Play the selected song
            context.read<MusicBloc>().add(
              MusicEvent.playOrPauseSong(
                songId: song.id,
                currentPlayList: state.myPlayerState.currentPlayList,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              children: [
                // Now Playing Icon
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: context.primaryStart,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: context.onSurfaceColor,
                    size: 16.sp,
                  ),
                ),

                SizedBox(width: 12.w),

                // Album Art
                AlbumArtWidget(
                  albumArt: song.albumArt,
                  width: 48.w,
                  height: 48.h,
                  borderRadius: 8.r,
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                  defaultIcon: Icons.play_arrow,
                  defaultIconSize: 24.sp,
                ),

                SizedBox(width: 12.w),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        style: TextStyle(
                          color: context.primaryStart,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        song.title,
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        song.primaryArtist,
                        style: TextStyle(
                          color: context.onSurfaceVariantColor,
                          fontSize: 14.sp,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Duration
                Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 14.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueSongTile({
    Key? key,
    required Song song,
    required int index,
    required bool isCurrentSong,
    required MusicState state,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: isCurrentSong
            ? context.isDark
                  ? context.primaryStart.withValues(alpha: 0.15)
                  : context.primaryStart.withValues(alpha: 0.15)
            : context.isDark
            ? context.onSurfaceColor.withValues(alpha: 0.08)
            : context.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCurrentSong
              ? context.isDark
                    ? context.primaryStart.withValues(alpha: 0.4)
                    : context.primaryStart.withValues(alpha: 0.4)
              : context.isDark
              ? context.onSurfaceColor.withValues(alpha: 0.08)
              : context.onSurfaceColor.withValues(alpha: 0.08),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: () {
            _logger.d("🎵 Tapping song in queue: ${song.title}");

            // Play the selected song
            context.read<MusicBloc>().add(
              MusicEvent.playOrPauseSong(
                songId: song.id,
                currentPlayList: state.myPlayerState.currentPlayList,
                playlistSource: PlaylistSourceHelper.getPlaylistSourceFromId(
                  state.myPlayerState.playlistId,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                // Reorder Handle (only show if not current song and not first)
                if (!isCurrentSong && index > 0)
                  Container(
                    width: 35.w,
                    height: 35.h,
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: context.primaryStart.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: context.primaryStart.withValues(alpha: 0.25),
                        width: 1.w,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.drag_handle,
                        color: context.primaryStart,
                        size: 20.sp,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 32.w),

                // Album Art
                AlbumArtWidget(
                  albumArt: song.albumArt,
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
                  defaultIcon: isCurrentSong
                      ? Icons.play_arrow
                      : Icons.music_note,
                  defaultIconSize: 20.sp,
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
                          color: isCurrentSong
                              ? context.primaryStart
                              : context.onSurfaceColor,
                          fontSize: 14.sp,
                          fontWeight: isCurrentSong
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        song.primaryArtist,
                        style: TextStyle(
                          color: isCurrentSong
                              ? context.primaryStart.withValues(alpha: 0.8)
                              : context.onSurfaceVariantColor,
                          fontSize: 12.sp,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Duration
                Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    color: isCurrentSong
                        ? context.primaryStart
                        : context.onSurfaceVariantColor,
                    fontSize: 12.sp,
                    fontFamily: 'Poppins',
                  ),
                ),

                SizedBox(width: 8.w),

                // Remove from Queue Button
                IconButton(
                  onPressed: () {
                    _removeSongFromQueue(context, song, state);
                  },
                  icon: Icon(Icons.close, color: context.error, size: 20.sp),
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQueueOptions(BuildContext context) {
    AppCustom.showBottomSheet(
      context: context,
      title: 'Queue Options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.shuffle,
              color: context.primaryStart,
              size: 24.sp,
            ),
            title: Text(
              'Shuffle Queue',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontFamily: 'Poppins',
                fontSize: 16.sp,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              final currentPlayList = context
                  .read<MusicBloc>()
                  .state
                  .myPlayerState
                  .currentPlayList;
              // Create a new shuffled list (shuffle() returns void, so we need to copy first)
              final shuffledQueue = List<String>.from(currentPlayList);
              shuffledQueue.shuffle();

              context.read<MusicBloc>().add(
                MusicEvent.updateMusicBlocState(
                  newState: context.read<MusicBloc>().state.copyWith(
                    myPlayerState: context
                        .read<MusicBloc>()
                        .state
                        .myPlayerState
                        .copyWith(
                          currentPlayList: shuffledQueue,
                          isShuffle: true,
                        ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.clear_all, color: context.error, size: 24.sp),
            title: Text(
              'Clear Queue',
              style: TextStyle(
                color: context.error,
                fontFamily: 'Poppins',
                fontSize: 16.sp,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _clearQueue(context);
            },
          ),
        ],
      ),
    );
  }

  void _reorderQueueSongs(MusicState state, int oldIndex, int newIndex) {
    _logger.d("🔄 Reordering queue: $oldIndex → $newIndex");

    final currentPlayList = List<String>.from(
      state.myPlayerState.currentPlayList,
    );
    final completedSongs = state.myPlayerState.completedSongs;

    // Get all non-completed songs in their current order
    final activeSongIds = currentPlayList
        .where((id) => !completedSongs.contains(id))
        .toList();

    if (oldIndex < activeSongIds.length && newIndex < activeSongIds.length) {
      // Adjust newIndex for ReorderableListView behavior
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Reorder the active songs (excluding completed)
      final item = activeSongIds.removeAt(oldIndex);
      activeSongIds.insert(newIndex, item);

      // Rebuild the full playlist maintaining the order of active songs
      final newPlayList = <String>[];

      // Add active songs in their new order
      newPlayList.addAll(activeSongIds);

      // Add completed songs at the end (they won't be visible in the queue)
      for (final songId in currentPlayList) {
        if (completedSongs.contains(songId)) {
          newPlayList.add(songId);
        }
      }

      // Update the player state
      final updatedQueue = state.myPlayerState.copyWith(
        currentPlayList: newPlayList,
      );
      context.read<MusicBloc>().add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(myPlayerState: updatedQueue),
        ),
      );

      _logger.d("✅ Queue reordered: $activeSongIds");
    }
  }

  void _removeSongFromQueue(BuildContext context, Song song, MusicState state) {
    _logger.d("🗑️ Removing song from queue: ${song.title}");

    // Add song to completed songs and remove from current playlist
    final currentPlayList = List<String>.from(
      state.myPlayerState.currentPlayList,
    );
    final completedSongs = List<String>.from(
      state.myPlayerState.completedSongs,
    );

    // Remove from current playlist
    currentPlayList.remove(song.id);

    // Add to completed songs (avoid duplication)
    if (!completedSongs.contains(song.id)) {
      completedSongs.add(song.id);
    }

    // Update the player state
    final updatedQueue = state.myPlayerState.copyWith(
      currentPlayList: currentPlayList,
      completedSongs: completedSongs,
    );

    context.read<MusicBloc>().add(
      MusicEvent.updateMusicBlocState(
        newState: state.copyWith(myPlayerState: updatedQueue),
      ),
    );

    _logger.d(
      "✅ Song removed from queue and added to completed: ${song.title}",
    );
  }

  void _clearQueue(BuildContext context) {
    AppCustom.showConfirm(
      context: context,
      title: 'Clear Queue',
      message: 'Are you sure you want to clear the playing queue?',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      confirmColor: context.error,
      onConfirm: () {
        context.read<MusicBloc>().add(
          MusicEvent.updateMusicBlocState(
            newState: context.read<MusicBloc>().state.copyWith(
              myPlayerState: context
                  .read<MusicBloc>()
                  .state
                  .myPlayerState
                  .copyWith(currentPlayList: [], completedSongs: []),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
