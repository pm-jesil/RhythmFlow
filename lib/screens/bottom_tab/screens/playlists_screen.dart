import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pmj_music_player/core/constants/app_enums.dart';
import '../../../core/theme/theme_extension.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/my_playlist/my_playlist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import 'bloc/music_bloc.dart';
import '../widgets/glass_card.dart';
import '../../widgets/album_art_widget.dart';
import '../widgets/album_artist_my_playlist_helper.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final AppLogger _logger = AppLogger('PlaylistsScreen');
  final ScrollController _scrollController = ScrollController();
  List<MyPlaylist> _filteredPlaylists = [];
  bool _isLoadingMore = false;
  bool _hasTriggeredBackgroundLoad = false;

  @override
  void initState() {
    super.initState();
    _logger.i('PlaylistsScreen initialized');

    // Reset loading states when screen initializes
    _isLoadingMore = false;
    _hasTriggeredBackgroundLoad = false;
  }

  void _loadMorePlaylists() {
    if (!_isLoadingMore && _filteredPlaylists.length > 15) {
      setState(() {
        _isLoadingMore = true;
      });

      // Simulate background loading with proper error handling
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Column(
          children: [
            CustomTabViewAppBar(
              title: 'My Playlists',
              showSearchButton: false,
              scrollController: _scrollController,
            ),
            Expanded(
              child: BlocBuilder<MusicBloc, MusicState>(
                builder: (context, state) {
                  // Update filtered playlists when state changes
                  if (_filteredPlaylists.isEmpty &&
                      state.myPlaylist.isNotEmpty) {
                    _filteredPlaylists = state.myPlaylist;
                  } else if (state.myPlaylist.length !=
                      _filteredPlaylists.length) {
                    // Update when playlist count changes (new playlist added/deleted)
                    _filteredPlaylists = state.myPlaylist;
                  } else {
                    // Always update filtered playlists to reflect any changes in playlist data
                    // (e.g., when songs are added/removed from playlists)
                    _filteredPlaylists = state.myPlaylist;
                  }

                  // Trigger background loading after initial display
                  if (_filteredPlaylists.isNotEmpty &&
                      !_hasTriggeredBackgroundLoad &&
                      _filteredPlaylists.length > 15 &&
                      !_isLoadingMore) {
                    _hasTriggeredBackgroundLoad = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        AlbumArtistPlaylistHelper.triggerBackgroundLoading(
                          onLoadMore: _loadMorePlaylists,
                          delay: const Duration(milliseconds: 500),
                        );
                      }
                    });
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Create Playlist Button
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: GlassCard(
                            child: ListTile(
                              leading: AlbumArtWidget(
                                albumArt: null,
                                width: 50.w,
                                height: 50.h,
                                borderRadius: 8.r,
                                defaultIcon: Icons.add_rounded,
                                defaultIconSize: 24.0,
                              ),
                              title: Text(
                                'Create New Playlist',
                                style: TextStyle(
                                  color: context.onSurfaceColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              subtitle: Text(
                                'Add your favorite songs to a playlist',
                                style: TextStyle(
                                  color: context.onSurfaceVariantColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: context.onSurfaceVariantColor,
                                size: 16.sp,
                              ),
                              onTap: () {
                                _showCreatePlaylistDialog();
                              },
                            ),
                          ),
                        ),
                      ),

                      // SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                      // Playlists List
                      if (_filteredPlaylists.isEmpty)
                        AlbumArtistPlaylistHelper.buildEmptyState(
                          context: context,
                          icon: Icons.queue_music_outlined,
                          message: 'No playlists found',
                          subtitle: 'Create your first playlist to get started',
                        )
                      else if (AlbumArtistPlaylistHelper.shouldUseLazyLoading(
                        _filteredPlaylists,
                        15,
                      ))
                        AlbumArtistPlaylistHelper.buildLazyLoadingMasonryGrid<
                          MyPlaylist
                        >(
                          context: context,
                          allItems: _filteredPlaylists,
                          itemBuilder: (context, index) {
                            final playlist = _filteredPlaylists[index];
                            return _buildPlaylistCard(playlist, state.allSongs);
                          },
                          onLoadMore: _loadMorePlaylists,
                          isLoadingMore: _isLoadingMore,
                          initialLoadCount: 15,
                        )
                      else
                        AlbumArtistPlaylistHelper.buildMasonryGrid<MyPlaylist>(
                          items: _filteredPlaylists,
                          itemBuilder: (context, index) {
                            final playlist = _filteredPlaylists[index];
                            return _buildPlaylistCard(playlist, state.allSongs);
                          },
                        ),

                      // Bottom padding for navigation
                      AlbumArtistPlaylistHelper.buildBottomPadding(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(MyPlaylist playlist, List<Song> allSongs) {
    final playlistSongs = AlbumArtistPlaylistHelper.getPlaylistSongs(
      playlist,
      allSongs,
    );
    final songCount = playlistSongs.length;
    final hasSongs = songCount > 0;

    return AlbumArtistPlaylistHelper.buildCard(
      onTap: hasSongs
          ? () => _navigateToPlaylistDetail(playlist, playlistSongs)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Playlist Album Art Section
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: AlbumArtistPlaylistHelper.buildPlaylistImage(
              context: context,
              playlist: playlist,
              playlistSongs: playlistSongs,
            ),
          ),

          SizedBox(height: 8.h),

          // Playlist Info Section
          AlbumArtistPlaylistHelper.buildCardInfoSection(
            context: context,
            title: playlist.name,
            songCount: songCount,
            hasSongs: hasSongs,
            onPlay: hasSongs
                ? () => _playPlaylist(playlistSongs, playlist.id)
                : null,
            subtitle: playlist.description,
          ),
        ],
      ),
    );
  }

  void _playPlaylist(List<Song> playlistSongs, String playlistId) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: playlistSongs,
      playlistSource: PlaylistSource.myPlaylist(playlistId),
    );
  }

  void _navigateToPlaylistDetail(
    MyPlaylist playlist,
    List<Song> playlistSongs,
  ) {
    AlbumArtistPlaylistHelper.navigateToPlaylistDetail(
      context: context,
      playlist: playlist,
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'Create Playlist',
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
                _logger.i('Creating playlist: ${nameController.text}');

                // Create playlist using the new event
                context.read<MusicBloc>().add(
                  MusicEvent.addOrUpdateMyPlayList(
                    operation: MyPlaylistOperation.create,
                    name: nameController.text,
                    description: descriptionController.text,
                  ),
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${nameController.text}" created!'),
                    backgroundColor: context.primaryStart,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
