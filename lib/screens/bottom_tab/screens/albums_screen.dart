import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rhythmflow/screens/bottom_tab/widgets/custom_tab_view_app_bar.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../bloc/music_bloc.dart';
import '../widgets/album_artist_my_playlist_helper.dart';
import '../../widgets/library_filter_helper.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final AppLogger _logger = AppLogger('AlbumsScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Album> _filteredAlbums = [];
  bool _isLoadingMore = false;
  bool _hasTriggeredBackgroundLoad = false;

  @override
  void initState() {
    super.initState();
    _logger.i('AlbumsScreen initialized');
    _searchController.addListener(_onSearchChanged);

    // Reset loading states when screen initializes
    _isLoadingMore = false;
    _hasTriggeredBackgroundLoad = false;
  }

  void _loadMoreAlbums() {
    if (!_isLoadingMore && _filteredAlbums.length > 15) {
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // The visible list is derived from bloc state in build(); just rebuild.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Column(
          children: [
            CustomTabViewAppBar(
              title: 'Albums',
              scrollController: _scrollController,
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: BlocBuilder<MusicBloc, MusicState>(
                builder: (context, state) {
                  // Always derive from the latest state so albums/artists added or
                  // removed by a library scan show up immediately.
                  _filteredAlbums = LibraryFilterHelper.filterAlbums(
                    state.albumList,
                    _searchController.text,
                  );

                  // Trigger background loading after initial display
                  if (_filteredAlbums.isNotEmpty &&
                      !_hasTriggeredBackgroundLoad &&
                      _filteredAlbums.length > 15 &&
                      !_isLoadingMore) {
                    _hasTriggeredBackgroundLoad = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        AlbumArtistPlaylistHelper.triggerBackgroundLoading(
                          onLoadMore: _loadMoreAlbums,
                          delay: const Duration(milliseconds: 500),
                        );
                      }
                    });
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Search Bar
                      // AlbumArtistPlaylistHelper.buildSearchBar(
                      //   controller: _searchController,
                      //   hintText: 'Search albums...',
                      //   context: context,
                      // ),

                      // Albums List
                      if (state.isAlbumListLoading)
                        AlbumArtistPlaylistHelper.buildLoadingState(context)
                      else if (state.isAlbumListError)
                        AlbumArtistPlaylistHelper.buildErrorState(
                          context: context,
                          errorMessage: 'Failed to load albums',
                          onRetry: () {
                            context.read<MusicBloc>().add(
                              const MusicEvent.fetchAndUpdateMetadata(
                                includeAlbums: true,
                                includeArtists: false,
                                isProgressive: false,
                              ),
                            );
                          },
                        )
                      else if (_filteredAlbums.isEmpty)
                        AlbumArtistPlaylistHelper.buildEmptyState(
                          context: context,
                          icon: Icons.album_outlined,
                          message: 'No albums found',
                        )
                      else if (AlbumArtistPlaylistHelper.shouldUseLazyLoading(
                        _filteredAlbums,
                        15,
                      ))
                        AlbumArtistPlaylistHelper.buildLazyLoadingMasonryGrid<
                          Album
                        >(
                          context: context,
                          allItems: _filteredAlbums,
                          itemBuilder: (context, index) {
                            final album = _filteredAlbums[index];
                            return _buildAlbumCard(album, state.allSongs);
                          },
                          onLoadMore: _loadMoreAlbums,
                          isLoadingMore: _isLoadingMore,
                          initialLoadCount: 15,
                        )
                      else
                        AlbumArtistPlaylistHelper.buildMasonryGrid<Album>(
                          items: _filteredAlbums,
                          itemBuilder: (context, index) {
                            final album = _filteredAlbums[index];
                            return _buildAlbumCard(album, state.allSongs);
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

  Widget _buildAlbumCard(Album album, List<Song> allSongs) {
    final albumSongs = AlbumArtistPlaylistHelper.getAlbumSongs(album, allSongs);
    final songCount = albumSongs.length;
    final hasSongs = songCount > 0;

    return AlbumArtistPlaylistHelper.buildCard(
      onTap: hasSongs ? () => _navigateToAlbumDetail(album, albumSongs) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album Art Section - Square container with circular image
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: Center(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AlbumArtistPlaylistHelper.buildCircularAlbumArt(
                  context: context,
                  album: album,
                  albumSongs: albumSongs,
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Album Info Section
          AlbumArtistPlaylistHelper.buildCardInfoSection(
            context: context,
            title: album.name.isNotEmpty ? album.name : 'Unknown Album',
            songCount: songCount,
            hasSongs: hasSongs,
            onPlay: hasSongs ? () => _playAlbum(albumSongs) : null,
          ),
        ],
      ),
    );
  }

  void _playAlbum(List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: albumSongs,
      playlistSource: PlaylistSource.album(albumSongs.first.albums.first),
    );
  }

  void _navigateToAlbumDetail(Album album, List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.navigateToAlbumDetail(
      context: context,
      album: album,
    );
  }
}
