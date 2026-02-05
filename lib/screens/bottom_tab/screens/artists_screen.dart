import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../bloc/music_bloc.dart';
import '../widgets/album_artist_my_playlist_helper.dart';
import '../../../screens/widgets/sorting_helper.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final AppLogger _logger = AppLogger('ArtistsScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasTriggeredBackgroundLoad = false;

  @override
  void initState() {
    super.initState();
    _logger.i('ArtistsScreen initialized');
    _searchController.addListener(_onSearchChanged);
    _isLoadingMore = false;
    _hasTriggeredBackgroundLoad = false;
  }

  void _loadMoreArtists() {
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

  /// Base list: top artists by play count when coming from "Top Artists", else all.
  List<Artist> _getDisplayBaseList(MusicState state) {
    if (state.navigationFilterType == 'top_artists') {
      final withPlays = state.artistList
          .where((a) => (a.playCount ?? 0) > 0)
          .toList();
      return SortingHelper.sortArtistsByPlayCount(withPlays, ascending: false);
    }
    return state.artistList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Column(
          children: [
            CustomTabViewAppBar(
              title: 'Artists',
              scrollController: _scrollController,
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: BlocBuilder<MusicBloc, MusicState>(
                buildWhen: (previous, current) {
                  return previous.artistList.length != current.artistList.length ||
                      previous.isArtistListLoading != current.isArtistListLoading ||
                      previous.isArtistListError != current.isArtistListError ||
                      previous.navigationFilterType != current.navigationFilterType ||
                      !identical(previous.artistList, current.artistList);
                },
                builder: (context, state) {
                  final baseList = _getDisplayBaseList(state);
                  final query = _searchController.text.toLowerCase();
                  final displayList = query.isEmpty
                      ? baseList
                      : baseList
                          .where((a) =>
                              a.name.toLowerCase().contains(query))
                          .toList();

                  if (displayList.isNotEmpty &&
                      !_hasTriggeredBackgroundLoad &&
                      displayList.length > 15 &&
                      !_isLoadingMore) {
                    _hasTriggeredBackgroundLoad = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        AlbumArtistPlaylistHelper.triggerBackgroundLoading(
                          onLoadMore: _loadMoreArtists,
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
                      if (state.isArtistListLoading)
                        AlbumArtistPlaylistHelper.buildLoadingState(context)
                      else if (state.isArtistListError)
                        AlbumArtistPlaylistHelper.buildErrorState(
                          context: context,
                          errorMessage: 'Failed to load artists',
                          onRetry: () {
                            context.read<MusicBloc>().add(
                              const MusicEvent.fetchAndUpdateMetadata(
                                includeAlbums: false,
                                includeArtists: true,
                                isProgressive: false,
                              ),
                            );
                          },
                        )
                      else if (displayList.isEmpty)
                        AlbumArtistPlaylistHelper.buildEmptyState(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          message:
                              state.navigationFilterType == 'top_artists'
                                  ? 'No artists with plays yet'
                                  : 'No artists found',
                        )
                      else if (AlbumArtistPlaylistHelper.shouldUseLazyLoading(
                        displayList,
                        15,
                      ))
                        AlbumArtistPlaylistHelper.buildLazyLoadingMasonryGrid<
                          Artist
                        >(
                          context: context,
                          allItems: displayList,
                          itemBuilder: (context, index) {
                            final artist = displayList[index];
                            return RepaintBoundary(
                              child: _buildArtistCard(artist, state.allSongs),
                            );
                          },
                          onLoadMore: _loadMoreArtists,
                          isLoadingMore: _isLoadingMore,
                          initialLoadCount: 15,
                        )
                      else
                        AlbumArtistPlaylistHelper.buildMasonryGrid<Artist>(
                          items: displayList,
                          itemBuilder: (context, index) {
                            final artist = displayList[index];
                            return RepaintBoundary(
                              child: _buildArtistCard(artist, state.allSongs),
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

  Widget _buildArtistCard(Artist artist, List<Song> allSongs) {
    final artistSongs = AlbumArtistPlaylistHelper.getArtistSongs(
      artist,
      allSongs,
    );
    final songCount = artistSongs.length;
    final hasSongs = songCount > 0;

    return AlbumArtistPlaylistHelper.buildCard(
      onTap: hasSongs
          ? () => _navigateToArtistDetail(artist, artistSongs)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: AlbumArtistPlaylistHelper.buildArtistImage(
              context: context,
              artist: artist,
              artistSongs: artistSongs,
            ),
          ),

          SizedBox(height: 8.h),
          AlbumArtistPlaylistHelper.buildCardInfoSection(
            context: context,
            title: artist.name,
            songCount: songCount,
            hasSongs: hasSongs,
            onPlay: hasSongs ? () => _playArtist(artistSongs) : null,
          ),
        ],
      ),
    );
  }

  void _playArtist(List<Song> artistSongs) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: artistSongs,
      playlistSource: PlaylistSource.artist(artistSongs.first.artists.first),
    );
  }

  void _navigateToArtistDetail(Artist artist, List<Song> artistSongs) {
    AlbumArtistPlaylistHelper.navigateToArtistDetail(
      context: context,
      artist: artist,
    );
  }
}
