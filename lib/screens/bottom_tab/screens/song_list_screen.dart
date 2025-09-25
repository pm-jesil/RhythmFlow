import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../core/router/app_router.dart';
import 'bloc/music_bloc.dart';
import '../widgets/glass_card.dart';
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
  List<Song> _filteredSongs = [];
  String? _immediatelySelectedSongId;

  @override
  void initState() {
    super.initState();
    _logger.i('SongListScreen initialized');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update selected song when dependencies change (e.g., navigating back from music player)
    final musicState = context.read<MusicBloc>().state;
    final newSongId = musicState.myPlayerState.currentSongId;
    
    // Update if the song ID has actually changed (including clearing to null)
    if (newSongId != _immediatelySelectedSongId) {
      _logger.i(
        '🔄 Updating selected song ID on dependency change: $newSongId (was: $_immediatelySelectedSongId)',
      );
      // Use setState to trigger UI rebuild for selection changes
      setState(() {
        _immediatelySelectedSongId = newSongId;
      });
    }
  }

  @override
  void dispose() {
    // Clear filter keyword when leaving the screen
    if (_searchController.text.isNotEmpty) {
      context.read<MusicBloc>().add(
        const MusicEvent.updateFilterKeyword(filterKeyword: ''),
      );
    }
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredSongs(MusicState musicState) {
    // Only update if we have songs and they're different from current filtered songs
    if (musicState.allSongs.isEmpty) {
      _filteredSongs = [];
      return;
    }

    final query = _searchController.text.toLowerCase();
    List<Song> currentSongs = List<Song>.from(musicState.allSongs);

    List<Song> newFilteredSongs;
    if (query.isEmpty) {
      newFilteredSongs = currentSongs;
      // Removed verbose filtered songs logging
    } else {
      newFilteredSongs = currentSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artists.join(', ').toLowerCase().contains(query) ||
            song.albums.join(', ').toLowerCase().contains(query);
      }).toList();
      // Removed verbose filtered songs logging
    }

    // Only update if the filtered songs have actually changed
    if (_filteredSongs.length != newFilteredSongs.length ||
        !_areSongListsEqual(_filteredSongs, newFilteredSongs)) {
      _filteredSongs = newFilteredSongs;
      // Removed verbose filtered songs update logging
    }
  }

  /// Update selected song ID when bloc state changes (auto-advance, etc.)
  void _updateSelectedSongFromBloc(MusicState musicState) {
    final newSongId = musicState.myPlayerState.currentSongId;
    
    // Update if the song ID has actually changed (including clearing to null)
    if (newSongId != _immediatelySelectedSongId) {  
      _logger.i(
        '🔄 Updating selected song ID from bloc state: $newSongId (was: $_immediatelySelectedSongId)',
      );
      // Use setState to trigger UI rebuild for selection changes
      setState(() {
        _immediatelySelectedSongId = newSongId;
      });
    }
  }

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
      listener: (context, musicState) {
        // Handle state changes that require UI updates
        final newSongId = musicState.myPlayerState.currentSongId;
        
        // Update if the song ID has actually changed (including clearing to null)
        if (newSongId != _immediatelySelectedSongId) {
          _logger.i(
            '🔄 BlocListener: Updating selected song ID: $newSongId (was: $_immediatelySelectedSongId)',
          );
          // Use setState to trigger UI rebuild for selection changes
          setState(() {
            _immediatelySelectedSongId = newSongId;
          });
        }
      },
      child: BlocBuilder<MusicBloc, MusicState>(
        builder: (context, musicState) {
          // Update filtered songs when music state changes (including sorting)
          _updateFilteredSongs(musicState);
          // Update selected song ID without setState during build
          _updateSelectedSongFromBloc(musicState);

          return Container(
            decoration: BoxDecoration(gradient: context.backgroundGradient),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Songs',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _showSortingMenu,
                    icon: Icon(
                      Icons.sort, 
                      color: context.onSurfaceColor,
                      size: 20.sp,
                    ),
                  ),
                  const ThemeToggleButton(),
                ],
              ),
              body: Stack(
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

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.onSurfaceColor),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, or albums...',
                hintStyle: TextStyle(
                  color: context.onSurfaceColor.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.onSurfaceColor.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Songs List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredSongs.length,
            itemBuilder: (context, index) {
              final song = _filteredSongs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SongListItem(
                  songTitle: song.title,
                  artistName: song.artists.join(', '),
                  albumName: song.albums.join(', '),
                  duration: song.duration,
                  albumArtPath: song.albumArt,
                  songId: song.id,
                  isImmediatelySelected: _immediatelySelectedSongId == song.id,
                  onTap: () {
                    HapticFeedback.lightImpact();

                    // Immediate visual feedback
                    setState(() {
                      _immediatelySelectedSongId = song.id;
                    });

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

                    // Immediately update selected song for instant feedback
                    setState(() {
                      _immediatelySelectedSongId = song.id;
                    });

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
          ),
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
