import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import 'bloc/music_bloc.dart';
import '../widgets/album_artist_my_playlist_helper.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final AppLogger _logger = AppLogger('ArtistsScreen');
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Artist> _filteredArtists = [];
  bool _isLoadingMore = false;
  bool _hasTriggeredBackgroundLoad = false;

  @override
  void initState() {
    super.initState();
    _logger.i('ArtistsScreen initialized');
    _searchController.addListener(_onSearchChanged);

    // Reset loading states when screen initializes
    _isLoadingMore = false;
    _hasTriggeredBackgroundLoad = false;
  }

  void _loadMoreArtists() {
    if (!_isLoadingMore && _filteredArtists.length > 15) {
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
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredArtists = context.read<MusicBloc>().state.artistList;
      } else {
        _filteredArtists = context
            .read<MusicBloc>()
            .state
            .artistList
            .where((artist) => artist.name.toLowerCase().contains(query))
            .toList();
      }
    });
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
            Expanded(
              child: BlocBuilder<MusicBloc, MusicState>(
                builder: (context, state) {
                  // Update filtered artists when state changes
                  if (_filteredArtists.isEmpty && state.artistList.isNotEmpty) {
                    _filteredArtists = state.artistList;
                  }

                  // Trigger background loading after initial display
                  if (_filteredArtists.isNotEmpty &&
                      !_hasTriggeredBackgroundLoad &&
                      _filteredArtists.length > 15 &&
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
                    slivers: [
                      // Artists List
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
                      else if (_filteredArtists.isEmpty)
                        AlbumArtistPlaylistHelper.buildEmptyState(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          message: 'No artists found',
                        )
                      else if (AlbumArtistPlaylistHelper.shouldUseLazyLoading(
                        _filteredArtists,
                        15,
                      ))
                        AlbumArtistPlaylistHelper.buildLazyLoadingMasonryGrid<
                          Artist
                        >(
                          context: context,
                          allItems: _filteredArtists,
                          itemBuilder: (context, index) {
                            final artist = _filteredArtists[index];
                            return _buildArtistCard(artist, state.allSongs);
                          },
                          onLoadMore: _loadMoreArtists,
                          isLoadingMore: _isLoadingMore,
                          initialLoadCount: 15,
                        )
                      else
                        AlbumArtistPlaylistHelper.buildMasonryGrid<Artist>(
                          items: _filteredArtists,
                          itemBuilder: (context, index) {
                            final artist = _filteredArtists[index];
                            return _buildArtistCard(artist, state.allSongs);
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
          // Artist Image Section
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: AlbumArtistPlaylistHelper.buildArtistImage(
              context: context,
              artist: artist,
              artistSongs: artistSongs,
            ),
          ),

          SizedBox(height: 8.h),

          // Artist Info Section
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
