import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import '../../../core/widgets/custom_popup.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../widgets/custom_tab_view_app_bar.dart';
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

class _SongListScreenState extends State<SongListScreen>
    with WidgetsBindingObserver {
  final AppLogger _logger = AppLogger('SongListScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Song> _filteredSongs = [];
  bool _autoFetchEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFetchSongsIfNeeded(initialRequest: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNotificationPermissionDialog();
    });
  }

  /// On Android, if notification permission is not granted and rejection count
  /// < 2, show a short popup. Enable → system permission dialog or Settings;
  /// Cancel / Maybe later → update count, no request.
  Future<void> _maybeShowNotificationPermissionDialog() async {
    if (!Platform.isAndroid) return;
    if (!mounted) return;
    final hasPermission = await PermissionService.hasNotificationPermission();
    if (hasPermission) return;
    if (!mounted) return;
    final rejectedCount = context
        .read<AppSettingsBloc>()
        .state
        .notificationPermissionRejectedCount;
    if (rejectedCount >= 2) return;
    if (!mounted) return;
    final result = await CustomPopup.showNotificationPermissionDialog(context);
    if (!mounted) return;
    final appSettingsBloc = context.read<AppSettingsBloc>();
    if (result == CustomPopup.notificationPermissionResultEnable) {
      await PermissionService.requestNotificationPermissionForPlayback();
      if (!mounted) return;
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else if (result == CustomPopup.notificationPermissionResultMaybeLater) {
      appSettingsBloc.add(
        const AppSettingsEvent.updateNotificationPermissionRejectedCount(
          value: 2,
        ),
      );
    } else if (result == CustomPopup.notificationPermissionResultCancel) {
      final current = appSettingsBloc.state.notificationPermissionRejectedCount;
      appSettingsBloc.add(
        AppSettingsEvent.updateNotificationPermissionRejectedCount(
          value: (current + 1).clamp(0, 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_searchController.text.isNotEmpty) {
      context.read<MusicBloc>().add(
        const MusicEvent.updateFilterKeyword(filterKeyword: ''),
      );
    }
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoFetchSongsIfNeeded();
    }
  }

  Future<void> _autoFetchSongsIfNeeded({bool initialRequest = false}) async {
    if (!_autoFetchEnabled) return;

    final musicBloc = context.read<MusicBloc>();
    final musicState = musicBloc.state;

    if (musicState.allSongs.isNotEmpty) {
      _autoFetchEnabled = false;
      return;
    }

    if (musicState.isSongListLoading) {
      return;
    }

    _logger.i('Checking permissions for automatic song fetch...');

    final hasPermissions = await PermissionService.hasAllRequiredPermissions();

    if (!mounted) return;

    if (hasPermissions) {
      _logger.i(
        'Permissions already granted and song list empty - auto fetching songs',
      );
      musicBloc.add(const MusicEvent.fetchAndUpdateSongs());
      _autoFetchEnabled = false;
      return;
    }

    if (!initialRequest) {
      return;
    }

    final granted = await PermissionService.requestAllRequiredPermissions(
      context,
    );

    if (!mounted) return;

    if (granted && musicBloc.state.allSongs.isEmpty) {
      _logger.i('Permissions granted on request - auto fetching songs');
      musicBloc.add(const MusicEvent.fetchAndUpdateSongs());
      _autoFetchEnabled = false;
    }
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

    if (_filteredSongs.length != newFilteredSongs.length ||
        !_areSongListsEqual(_filteredSongs, newFilteredSongs)) {
      _filteredSongs = newFilteredSongs;
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

  /// Fetches songs from storage after ensuring required permissions.
  Future<void> _handleFetchSongsFromStorage() async {
    _logger.i('User requested to fetch songs from storage');
    try {
      final hasPermissions =
          await PermissionService.hasAllRequiredPermissions();

      if (hasPermissions) {
        _logger.i('Permissions granted, proceeding with fetch');
        context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs());
      } else {
        _logger.w('Permissions not granted, requesting permissions');
        final granted = await PermissionService.requestAllRequiredPermissions(
          context,
        );

        if (granted) {
          _logger.i('Permissions granted after request, proceeding with fetch');
          context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs());
        } else {
          _logger.w('Permissions denied, showing permission required dialog');
          await PermissionService.showPermissionRequiredDialog(context);
        }
      }
    } catch (e) {
      _logger.e('Error handling fetch songs request: $e');
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
    return BlocBuilder<MusicBloc, MusicState>(
        buildWhen: (previous, current) {
          if (previous.allSongs.length != current.allSongs.length ||
              previous.isSongListLoading != current.isSongListLoading ||
              previous.isSongListError != current.isSongListError ||
              previous.sortingIndex != current.sortingIndex) {
            return true;
          }
          if (identical(previous.allSongs, current.allSongs)) return false;
          return !_areSongListsEqual(previous.allSongs, current.allSongs);
        },
        builder: (context, musicState) {
          _updateFilteredSongs(musicState);
          if (!musicState.isSongListLoading &&
              musicState.allSongs.isEmpty &&
              !_autoFetchEnabled) {
            _autoFetchEnabled = true;
            _logger.d('Auto-fetch re-enabled - song list is empty');
          }

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
                  SizedBox(height: 10.h),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildContent(musicState),
                        BlocBuilder<MusicBloc, MusicState>(
                          builder: (context, state) {
                            final showMiniPlayer =
                                state.myPlayerState.currentSongId != null;
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
                                        final appSettingsBloc = context
                                            .read<AppSettingsBloc>();
                                        final musicBloc = context
                                            .read<MusicBloc>();
                                        final appSettingsState =
                                            appSettingsBloc.state;
                                        final musicState = musicBloc.state;

                                        final isAiShuffleEnabled =
                                            appSettingsState.isAiShuffleEnabled;
                                        final isNormalShuffleEnabled =
                                            musicState.myPlayerState.isShuffle;
                                        final bool useAiShuffle =
                                            isAiShuffleEnabled ||
                                            !isNormalShuffleEnabled;
                                        final randomIndex =
                                            DateTime.now()
                                                .millisecondsSinceEpoch %
                                            _filteredSongs.length;
                                        final randomSong =
                                            _filteredSongs[randomIndex];
                                        final allSongIds = _filteredSongs
                                            .map((song) => song.id)
                                            .toList();

                                        if (useAiShuffle) {
                                          if (isNormalShuffleEnabled) {
                                            musicBloc.add(
                                              MusicEvent.toggleShuffle(
                                                isShuffle: false,
                                                currentPlayList: allSongIds,
                                              ),
                                            );
                                          }
                                          if (!isAiShuffleEnabled) {
                                            appSettingsBloc.add(
                                              AppSettingsEvent.updateAiShuffle(
                                                isEnabled: true,
                                              ),
                                            );
                                          }
                                          musicBloc.add(
                                            MusicEvent.playOrPauseSong(
                                              songId: randomSong.id,
                                              currentPlayList: allSongIds,
                                              playlistSource:
                                                  PlaylistSource.allSongs(),
                                            ),
                                          );
                                        } else {
                                          if (isAiShuffleEnabled) {
                                            appSettingsBloc.add(
                                              AppSettingsEvent.updateAiShuffle(
                                                isEnabled: false,
                                              ),
                                            );
                                          }
                                          if (!isNormalShuffleEnabled) {
                                            musicBloc.add(
                                              MusicEvent.toggleShuffle(
                                                isShuffle: true,
                                                isAutoStart: false,
                                                currentPlayList: allSongIds,
                                              ),
                                            );
                                          }
                                          musicBloc.add(
                                            MusicEvent.playOrPauseSong(
                                              songId: randomSong.id,
                                              currentPlayList: allSongIds,
                                              playlistSource:
                                                  PlaylistSource.allSongs(),
                                            ),
                                          );
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
                                      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
                                        builder: (context, appSettingsState) {
                                          return BlocBuilder<
                                            MusicBloc,
                                            MusicState
                                          >(
                                            builder: (context, musicState) {
                                              final bool isAi = appSettingsState
                                                  .isAiShuffleEnabled;
                                              final bool isNormal = musicState
                                                  .myPlayerState
                                                  .isShuffle;
                                              final bool showAiIcon =
                                                  isAi || (!isAi && !isNormal);

                                              if (showAiIcon) {
                                                return Icon(
                                                  CupertinoIcons.sparkles,
                                                  color: Colors.white,
                                                  size: 24.sp,
                                                );
                                              }
                                              return Icon(
                                                  CupertinoIcons.shuffle,
                                                  color: Colors.white,
                                                  size: 24.sp,
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 400,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 0.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _filteredSongs[index];
                return RepaintBoundary(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: SongListItem(
                      key: ValueKey(song.id),
                      songTitle: song.title,
                      artistName: song.artists.join(', '),
                      albumName: song.albums.join(', '),
                      duration: song.duration,
                      albumArtPath: song.albumArt,
                      songId: song.id,
                      isImmediatelySelected: false,
                      onTap: () {
                        HapticFeedback.lightImpact();
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
                        context.read<MusicBloc>().add(
                          MusicEvent.playOrPauseSong(
                            songId: song.id,
                            currentPlayList: _filteredSongs
                                .map((song) => song.id)
                                .toList(),
                            playlistSource: PlaylistSource.allSongs(),
                          ),
                        );
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
                  ),
                );
              },
              childCount: _filteredSongs.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
            ),
          ),
        ),
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
