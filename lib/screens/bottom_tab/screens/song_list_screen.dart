import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../core/router/app_router.dart';
import '../bloc/music_bloc.dart';
import '../widgets/song_list_item.dart';
import '../widgets/song_list_widget.dart';
import '../../../utils/services/permission_service.dart';
import '../../../core/widgets/app_custom.dart';
import '../widgets/song_context_menu_actions.dart';

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

    // Request all required permissions on first entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllRequiredPermissions(context);
    });
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

    // Apply search filter (no navigation filters needed - sorting handles everything)
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

  void _handleMenuAction(
    String action,
    String songId,
    String songTitle,
    String artistName,
    String albumName,
  ) {
    SongContextMenuActions.handleMenuAction(
      context: context,
      action: action,
      songId: songId,
      songTitle: songTitle,
      artistName: artistName,
      albumName: albumName,
    );
  }

  /// Handle fetch songs from storage with permission check
  Future<void> _handleFetchSongsFromStorage() async {
    _logger.i('🎵 User requested to fetch songs from storage');

    try {
      // Check permissions first
      final hasPermissions =
          await PermissionService.hasAllRequiredPermissions();

      if (hasPermissions) {
        _logger.i('✅ Permissions granted, proceeding with fetch');
        context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs());
      } else {
        _logger.w('❌ Permissions not granted, requesting permissions');

        // Request permissions with user-friendly dialog
        final granted = await PermissionService.requestAllRequiredPermissions(
          context,
        );

        if (granted) {
          _logger.i(
            '✅ Permissions granted after request, proceeding with fetch',
          );
          context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs());
        } else {
          _logger.w('❌ Permissions denied, showing permission required dialog');
          await PermissionService.showPermissionRequiredDialog(context);
        }
      }
    } catch (e) {
      _logger.e('❌ Error handling fetch songs request: $e');
      // Show error message to user
      if (mounted) {
        AppCustom.error(context, 'Error checking permissions: $e');
      }
    }
  }

  void _showSortingMenu() {
    SongListWidget.showSortingMenu(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MusicBloc, MusicState>(
      listenWhen: (previous, current) {
        // Only listen when song ID actually changes
        return previous.myPlayerState.currentSongId !=
            current.myPlayerState.currentSongId;
      },
      listener: (context, musicState) {
        // No longer needed - bloc state changes automatically trigger rebuilds
        // Selection is now handled purely by bloc state
      },
      child: BlocBuilder<MusicBloc, MusicState>(
        buildWhen: (previous, current) {
          // Rebuild when songs list, loading state, or sorting changes
          return previous.allSongs.length != current.allSongs.length ||
              previous.isSongListLoading != current.isSongListLoading ||
              previous.isSongListError != current.isSongListError ||
              previous.sortingIndex != current.sortingIndex ||
              !_areSongListsEqual(previous.allSongs, current.allSongs);
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
                            final showMiniPlayer =
                                state.myPlayerState.currentSongId != null;
                            // Position above pop-up music player when visible, otherwise above bottom tab
                            final bottomPosition = showMiniPlayer
                                ? MediaQuery.of(context).padding.bottom +
                                      16.h +
                                      60.h +
                                      16.h +
                                      60.h
                                : MediaQuery.of(context).padding.bottom +
                                      16.h +
                                      60.h;

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
                                        final appSettingsState = context
                                            .read<AppSettingsBloc>()
                                            .state;
                                        final musicState = context
                                            .read<MusicBloc>()
                                            .state;
                                        final isShuffleActive = musicState.myPlayerState.isShuffle;

                                        if (appSettingsState.isAiShuffleEnabled) {
                                          // AI shuffle is enabled - disable it
                                          context.read<AppSettingsBloc>().add(
                                            AppSettingsEvent.updateAiShuffle(
                                              isEnabled: false,
                                            ),
                                          );
                                        } else if (isShuffleActive) {
                                          // Regular shuffle is enabled - disable it
                                          context.read<MusicBloc>().add(
                                            MusicEvent.toggleShuffle(
                                              isShuffle: false,
                                              currentPlayList: musicState
                                                  .myPlayerState
                                                  .currentPlayList,
                                            ),
                                          );
                                        } else {
                                          // Both are disabled - check last used shuffle type
                                          final shuffleHistory = appSettingsState.shuffleHistory;
                                          if (shuffleHistory.isNotEmpty) {
                                            final lastShuffleType = shuffleHistory.first;
                                            if (lastShuffleType == 'ai_shuffle') {
                                              // Enable AI shuffle and play random song
                                              context.read<AppSettingsBloc>().add(
                                                AppSettingsEvent.updateAiShuffle(
                                                  isEnabled: true,
                                                ),
                                              );
                                              
                                              final randomSong = _filteredSongs[DateTime.now()
                                                  .millisecondsSinceEpoch % _filteredSongs.length];
                                              
                                              context.read<MusicBloc>().add(
                                                MusicEvent.playOrPauseSong(
                                                  songId: randomSong.id,
                                                  currentPlayList: _filteredSongs
                                                      .map((song) => song.id)
                                                      .toList(),
                                                  playlistSource: PlaylistSource.allSongs(),
                                                ),
                                              );
                                            } else {
                                              // Enable regular shuffle and play random song
                                              final randomSong = _filteredSongs[DateTime.now()
                                                  .millisecondsSinceEpoch % _filteredSongs.length];
                                              
                                              context.read<MusicBloc>().add(
                                                MusicEvent.toggleShuffle(
                                                  isShuffle: true,
                                                  isAutoStart: true,
                                                  currentPlayList: _filteredSongs
                                                      .map((song) => song.id)
                                                      .toList(),
                                                  playlistSource: PlaylistSource.allSongs(),
                                                ),
                                              );
                                              
                                              context.read<MusicBloc>().add(
                                                MusicEvent.playOrPauseSong(
                                                  songId: randomSong.id,
                                                  currentPlayList: _filteredSongs
                                                      .map((song) => song.id)
                                                      .toList(),
                                                ),
                                              );
                                            }
                                          } else {
                                            // No history - default to regular shuffle
                                            final randomSong = _filteredSongs[DateTime.now()
                                                .millisecondsSinceEpoch % _filteredSongs.length];
                                            
                                            context.read<MusicBloc>().add(
                                              MusicEvent.toggleShuffle(
                                                isShuffle: true,
                                                isAutoStart: true,
                                                currentPlayList: _filteredSongs
                                                    .map((song) => song.id)
                                                    .toList(),
                                                playlistSource: PlaylistSource.allSongs(),
                                              ),
                                            );
                                            
                                            context.read<MusicBloc>().add(
                                              MusicEvent.playOrPauseSong(
                                                songId: randomSong.id,
                                                currentPlayList: _filteredSongs
                                                    .map((song) => song.id)
                                                    .toList(),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          28.r,
                                        ),
                                      ),
                                      child:
                                          BlocBuilder<
                                            AppSettingsBloc,
                                            AppSettingsState
                                          >(
                                            builder:
                                                (context, appSettingsState) {
                                                  return BlocBuilder<MusicBloc, MusicState>(
                                                    builder: (context, musicState) {
                                                      final bool isAi = appSettingsState.isAiShuffleEnabled;
                                                      final bool isNormal = musicState.myPlayerState.isShuffle;

                                                      if (isAi) {
                                                        return Icon(
                                                          CupertinoIcons.sparkles,
                                                          color: Colors.white,
                                                          size: 24.sp,
                                                        );
                                                      }
                                                      if (isNormal) {
                                                        return Icon(
                                                          CupertinoIcons.shuffle,
                                                          color: Colors.white,
                                                          size: 24.sp,
                                                        );
                                                      }

                                                      // None: show shuffle with cross line (inactive)
                                                      return Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          Icon(
                                                            CupertinoIcons.shuffle,
                                                            color: Colors.white,
                                                            size: 24.sp,
                                                          ),
                                                          Transform.rotate(
                                                            angle: 0.8,
                                                            child: Container(
                                                              width: 18.w,
                                                              height: 2.h,
                                                              color: Colors.white.withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
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
              onPressed: () => _handleFetchSongsFromStorage(),
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
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: SongListItem(
                    key: ValueKey(
                      song.id,
                    ), // Use song ID as key for better performance
                    songTitle: song.title,
                    artistName: song.artists.join(', '),
                    albumName: song.albums.join(', '),
                    duration: song.duration,
                    albumArtPath: song.albumArt,
                    songId: song.id,
                    isImmediatelySelected:
                        false, // CRITICAL: Don't use local state for selection
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
                          currentPlayList: _filteredSongs
                              .map((song) => song.id)
                              .toList(),
                        ),
                      );
                    },
                    onOpenMusicPlayer: () {
                      _logger.i(
                        'Open Music Player - ID: ${song.id}, Title: ${song.title}',
                      );

                      // CRITICAL: Don't set local selection state here
                      // Let the bloc state handle selection to prevent multiple songs being selected

                      _logger.d(
                        "🎵 Tapping song: ${song.title} | Current: ${musicState.myPlayerState.currentSongId}",
                      );

                      // Always use playOrPauseSong - it handles all cases internally
                      // Pass allSongs to maintain proper order in currentPlayList
                      context.read<MusicBloc>().add(
                        MusicEvent.playOrPauseSong(
                          songId: song.id,
                          currentPlayList: _filteredSongs
                              .map((song) => song.id)
                              .toList(),
                          playlistSource:
                              PlaylistSource.allSongs(), // Indicate this is from all songs screen
                        ),
                      );

                      // Navigate to music player screen
                      context.navigateToPlaySong('');
                    },
                    onMenuAction:
                        (action, songId, songTitle, artistName, albumName) {
                          _handleMenuAction(
                            action,
                            songId,
                            songTitle,
                            artistName,
                            albumName,
                          );
                        },
                  ),
                );
              },
              childCount: _filteredSongs.length,
              // Performance optimizations
              addAutomaticKeepAlives:
                  false, // Don't keep items alive when scrolled away
              addRepaintBoundaries:
                  true, // Add repaint boundaries for better performance
              addSemanticIndexes:
                  false, // Disable semantic indexes for better performance
            ),
          ),
        ),

        // Bottom padding for navigation
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
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
            onPressed: () => _handleFetchSongsFromStorage(),
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
