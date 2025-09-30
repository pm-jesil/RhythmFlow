import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../core/router/app_router.dart';
import 'bloc/music_bloc.dart';
import '../widgets/song_list_item.dart';
import '../widgets/song_list_widget.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final AppLogger _logger = AppLogger('SongListScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    if (_searchController.text.isNotEmpty) {
      context.read<MusicBloc>().add(
        const MusicEvent.updateFilterKeyword(filterKeyword: ''),
      );
    }
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFilteredSongs(MusicState musicState) {
    if (musicState.allSongs.isEmpty) {
      _filteredSongs = [];
      return;
    }

    final query = _searchController.text.toLowerCase();
    List<Song> currentSongs = List<Song>.from(musicState.allSongs);

    List<Song> newFilteredSongs;
    if (query.isEmpty) {
      newFilteredSongs = currentSongs;
    } else {
      newFilteredSongs = currentSongs.where((song) {
        final title = song.title.toLowerCase();
        if (title.contains(query)) return true;
        
        final artists = song.artists.join(', ').toLowerCase();
        if (artists.contains(query)) return true;
        
        final albums = song.albums.join(', ').toLowerCase();
        return albums.contains(query);
      }).toList();
    }

    // Only update if the filtered songs have actually changed
    if (_filteredSongs.length != newFilteredSongs.length ||
        !_areSongListsEqual(_filteredSongs, newFilteredSongs)) {
      _filteredSongs = newFilteredSongs;
    }
  }

  // Removed _updateSelectedSongFromBloc - no longer needed since we only use bloc state

  bool _areSongListsEqual(List<Song> list1, List<Song> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    _logger.d('Search query changed: "$query"');

    // Update bloc state with filter keyword
    context.read<MusicBloc>().add(
      MusicEvent.updateFilterKeyword(filterKeyword: query),
    );

    final musicState = context.read<MusicBloc>().state;
    _updateFilteredSongs(musicState);
    setState(() {});
  }

  void _showSortingMenu() {
    SongListWidget.showSortingMenu(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MusicBloc, MusicState>(
      listenWhen: (previous, current) {
        // Only listen when song ID actually changes
        return previous.myPlayerState.currentSongId != current.myPlayerState.currentSongId;
      },
      listener: (context, musicState) {
        // No longer needed - bloc state changes automatically trigger rebuilds
        // Selection is now handled purely by bloc state
      },
      child: BlocBuilder<MusicBloc, MusicState>(
        buildWhen: (previous, current) {
          // Only rebuild when songs list or loading state changes
          return previous.allSongs.length != current.allSongs.length ||
                 previous.isSongListLoading != current.isSongListLoading ||
                 previous.isSongListError != current.isSongListError;
        },
        builder: (context, musicState) {
          // Update filtered songs when music state changes (including sorting)
          _updateFilteredSongs(musicState);
          // No longer need to update selected song - handled by bloc state

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: context.backgroundGradient),
              child: Column(
                children: [
                  CustomTabViewAppBar(
                    title: 'Songs',
                    showSortButton: true,
                    onSortPressed: _showSortingMenu,
                    scrollController: _scrollController,
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildContent(musicState),
                        // Floating shuffle button
                        BlocBuilder<MusicBloc, MusicState>(
                          builder: (context, state) {
                            final showMiniPlayer = state.myPlayerState.currentSongId != null;
                            // Position above pop-up music player when visible, otherwise above bottom tab
                            final bottomPosition = showMiniPlayer 
                                ? MediaQuery.of(context).padding.bottom + 16.h + 60.h + 16.h + 70.h + 16.h // Above pop-up music player
                                : MediaQuery.of(context).padding.bottom + 16.h + 60.h + 16.h; // Above bottom tab

                            return Positioned(
                              bottom: bottomPosition,
                              right: 16.w,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: context.primaryGradient,
                                  borderRadius: BorderRadius.circular(28.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.primaryStart.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28.r),
                                    onTap: () {
                                      if (_filteredSongs.isNotEmpty) {
                                        // Enable shuffle and play random song
                                        final randomSong =
                                            _filteredSongs[DateTime.now()
                                                    .millisecondsSinceEpoch %
                                                _filteredSongs.length];
            context.read<MusicBloc>().add(
              MusicEvent.toggleShuffle(
                isShuffle: true,
                isAutoStart: true,
                currentPlayList: _filteredSongs.map((song) => song.id).toList(),
                playlistSource: PlaylistSource.allSongs(),
              ),
            );
                                        context.read<MusicBloc>().add(
                                          MusicEvent.playOrPauseSong(
                                            songId: randomSong.id,
                                            currentPlayList: _filteredSongs.map((song) => song.id).toList(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28.r),
                                      ),
                                      child: Icon(
                                        Icons.shuffle,
                                        color: Colors.white,
                                        size: 24.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildContent(MusicState musicState) {

    if (musicState.isSongListLoading && musicState.allSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.primaryStart),
            SizedBox(height: 16.h),
            Text(
              'Loading songs...',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 16.sp,
                fontFamily: 'Poppins',
              ),
            ),
            if (musicState.songLoadingProgress > 0) ...[
              SizedBox(height: 8.h),
              Text(
                'Found ${musicState.songLoadingProgress} songs so far...',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (musicState.isSongListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: context.error, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              'Error loading songs',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Song List Loading Error ...',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.read<MusicBloc>().add(const MusicEvent.loadAllSongsProgressive());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Search Bar
        // AlbumArtistPlaylistHelper.buildSearchBar(
        //   controller: _searchController,
        //   hintText: 'Search songs, artists, or albums...',
        //   context: context,
        // ),

        // Songs List - Optimized with better performance
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _filteredSongs[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: SongListItem(
                    key: ValueKey(song.id), // Use song ID as key for better performance
                    songTitle: song.title,
                    artistName: song.artists.join(', '),
                    albumName: song.albums.join(', '),
                    duration: song.duration,
                    albumArtPath: song.albumArt,
                    songId: song.id,
                    isImmediatelySelected: false, // CRITICAL: Don't use local state for selection
                    onTap: () {
                      HapticFeedback.lightImpact();

                      // CRITICAL: Don't set local selection state here
                      // Let the bloc state handle selection to prevent multiple songs being selected

                      _logger.i(
                        'Play/Pause Song - ID: ${song.id}, Title: ${song.title}, Artist: ${song.artists.join(', ')}, Album: ${song.albums.join(', ')}',
                      );

                      // Toggle play/pause for the current song
                      context.read<MusicBloc>().add(
                        MusicEvent.playOrPauseSong(
                          songId: song.id,
                          currentPlayList: _filteredSongs.map((song) => song.id).toList(),
                        ),
                      );
                    },
                    onOpenMusicPlayer: () {
                      _logger.i(
                        'Open Music Player - ID: ${song.id}, Title: ${song.title}',
                      );

                      // CRITICAL: Don't set local selection state here
                      // Let the bloc state handle selection to prevent multiple songs being selected

                      _logger.d("🎵 Tapping song: ${song.title} | Current: ${musicState.myPlayerState.currentSongId}");

                      // Always use playOrPauseSong - it handles all cases internally
                      // Pass allSongs to maintain proper order in currentPlayList
                      context.read<MusicBloc>().add(
                        MusicEvent.playOrPauseSong(
                          songId: song.id,
                          currentPlayList: _filteredSongs.map((song) => song.id).toList(),
                          playlistSource: PlaylistSource.allSongs(), // Indicate this is from all songs screen
                        ),
                      );

                      // Navigate to music player screen
                      context.navigateToPlaySong('');
                    },
                  ),
                );
              },
              childCount: _filteredSongs.length,
              // Performance optimizations
              addAutomaticKeepAlives: false, // Don't keep items alive when scrolled away
              addRepaintBoundaries: true, // Add repaint boundaries for better performance
              addSemanticIndexes: false, // Disable semantic indexes for better performance
            ),
          ),
        ),

        // Bottom padding for navigation
        SliverToBoxAdapter(
          child: SizedBox(height: 100.h),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            color: context.onSurfaceColor.withValues(alpha: 0.5),
            size: 80.sp,
          ),
          SizedBox(height: 24.h),
          Text(
            'No Music Found',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Your music library is empty',
            style: TextStyle(
              color: context.onSurfaceColor.withValues(alpha: 0.7),
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MusicBloc>().add(const MusicEvent.loadAllSongsProgressive());
            },
            icon: const Icon(Icons.sync),
            label: const Text('Fetch Songs from Storage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
