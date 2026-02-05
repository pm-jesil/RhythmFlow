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
import '../../../screens/widgets/sorting_helper.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final AppLogger _logger = AppLogger('AlbumsScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasTriggeredBackgroundLoad = false;

  @override
  void initState() {
    super.initState();
    _logger.i('AlbumsScreen initialized');
    _searchController.addListener(_onSearchChanged);
    _isLoadingMore = false;
    _hasTriggeredBackgroundLoad = false;
  }

  void _loadMoreAlbums() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
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
    setState(() {});
  }

  /// Base list: top albums by play count when coming from "Top Albums", else all.
  List<Album> _getDisplayBaseList(MusicState state) {
    if (state.navigationFilterType == 'top_albums') {
      final withPlays = state.albumList
          .where((a) => (a.playCount ?? 0) > 0)
          .toList();
      return SortingHelper.sortAlbumsByPlayCount(withPlays, ascending: false);
    }
    return state.albumList;
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
                buildWhen: (previous, current) {
                  return previous.albumList.length != current.albumList.length ||
                      previous.isAlbumListLoading != current.isAlbumListLoading ||
                      previous.isAlbumListError != current.isAlbumListError ||
                      previous.navigationFilterType != current.navigationFilterType ||
                      !identical(previous.albumList, current.albumList);
                },
                builder: (context, state) {
                  final baseList = _getDisplayBaseList(state);
                  final query = _searchController.text.toLowerCase();
                  final displayList = query.isEmpty
                      ? baseList
                      : baseList
                          .where((a) => a.name.toLowerCase().contains(query))
                          .toList();

                  if (displayList.isNotEmpty &&
                      !_hasTriggeredBackgroundLoad &&
                      displayList.length > 15 &&
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
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 400,
                    slivers: [
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
                      else if (displayList.isEmpty)
                        AlbumArtistPlaylistHelper.buildEmptyState(
                          context: context,
                          icon: Icons.album_outlined,
                          message: state.navigationFilterType == 'top_albums'
                              ? 'No albums with plays yet'
                              : 'No albums found',
                        )
                      else if (AlbumArtistPlaylistHelper.shouldUseLazyLoading(
                        displayList,
                        15,
                      ))
                        AlbumArtistPlaylistHelper.buildLazyLoadingMasonryGrid<
                          Album
                        >(
                          context: context,
                          allItems: displayList,
                          itemBuilder: (context, index) {
                            final album = displayList[index];
                            return RepaintBoundary(
                              child: _buildAlbumCard(album, state.allSongs),
                            );
                          },
                          onLoadMore: _loadMoreAlbums,
                          isLoadingMore: _isLoadingMore,
                          initialLoadCount: 15,
                        )
                      else
                        AlbumArtistPlaylistHelper.buildMasonryGrid<Album>(
                          items: displayList,
                          itemBuilder: (context, index) {
                            final album = displayList[index];
                            return RepaintBoundary(
                              child: _buildAlbumCard(album, state.allSongs),
                            );
                          },
                        ),
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
