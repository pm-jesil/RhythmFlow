import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:rhythmflow/screens/bottom_tab/widgets/album_artist_my_playlist_helper.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/custom_3d_card.dart';
import '../widgets/custom_tab_view_app_bar.dart';
import '../../../core/router/app_router.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../bloc/music_bloc.dart';
import '../../equalizer/bloc/equalizer_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../bottom_tab.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import '../../widgets/sorting_helper.dart';
import '../widgets/horizondal_scrolling_widget_home.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final AppLogger _logger = AppLogger('ForYouScreen');

  // Constants
  static const double _cardPadding = 12.0;
  static const double _sectionPadding = 16.0;
  static const double _itemSpacing = 8.0;
  static const double _borderRadius = 10.0;
  // Animation delays
  static const int _statsDelay = 0;
  static const int _recentlyAddedDelay = 1;
  static const int _topArtistsDelay = 2;
  static const int _topAlbumsDelay = 3;

  // Limits
  static const int _maxSongsPerSection = 3;

  // Additional spacing
  static const double _largeSpacing = 24.0;
  static const double _statCardHeight = 135.0;

  @override
  void initState() {
    super.initState();
    _logger.i('ForYouScreen initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final musicBloc = context.read<MusicBloc>();
      final currentState = musicBloc.state;
      final newHorizontalIndex =
          currentState.horizondalScrollingWidgetHomeIndex == 0 ? 1 : 0;
      musicBloc.add(
        MusicEvent.updateMusicBlocState(
          newState: currentState.copyWith(
            horizondalScrollingWidgetHomeIndex: newHorizontalIndex,
          ),
        ),
      );
      context.read<AppSettingsBloc>().add(
        const AppSettingsEvent.updateDailyQuote(),
      );
    });
  }

  List<Artist> _getTopArtists(List<Artist> artists) {
    final artistsWithPlayCount = artists
        .where((artist) => (artist.playCount ?? 0) > 0)
        .toList();
    return SortingHelper.sortArtistsByPlayCount(
      artistsWithPlayCount,
      ascending: false,
    );
  }

  List<Album> _getTopAlbums(List<Album> albums) {
    final albumsWithPlayCount = albums
        .where((album) => (album.playCount ?? 0) > 0)
        .toList();
    return SortingHelper.sortAlbumsByPlayCount(
      albumsWithPlayCount,
      ascending: false,
    );
  }

  Widget _buildEmptyStateCard(
    String title,
    String message,
    IconData icon,
    int animationDelay,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: _itemSpacing.h),
        Custom3DCard(
          width: double.infinity,
          enableAnimation: true,
          animationDelay: animationDelay,
          padding: EdgeInsets.all(_sectionPadding.w),
          backgroundColor: context.cardColor,
          child: Column(
            children: [
              Icon(icon, color: context.onSurfaceVariantColor, size: 48.sp),
              SizedBox(height: _itemSpacing.h),
              Text(
                message,
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int animationDelay,
    double? height,
    double? iconSize,
    double? fontSize,
  }) {
    return Custom3DCard(
      height: height ?? _statCardHeight.h,
      enableAnimation: true,
      animationDelay: animationDelay,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_cardPadding.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_borderRadius.r),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  offset: Offset(0, 2.h),
                  blurRadius: 4.r,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: (iconSize ?? 24).sp),
          ),
          SizedBox(height: _itemSpacing.h),
          Text(
            count.toString(),
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: (fontSize ?? 18).sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              shadows: [
                Shadow(
                  color: context.onSurfaceColor.withValues(alpha: 0.3),
                  offset: Offset(0, 1.h),
                  blurRadius: 2.r,
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.backgroundGradient,
        color: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomTabViewAppBar(
          title: 'For You',
          showSearchButton: false,
          showSettingsButton: true,
          onSettingsPressed: () => context.navigateToSettings(),
        ),
        body: BlocBuilder<MusicBloc, MusicState>(
          buildWhen: (previous, current) {
            return previous.allSongs.length != current.allSongs.length ||
                previous.artistList.length != current.artistList.length ||
                previous.albumList.length != current.albumList.length ||
                previous.horizondalScrollingWidgetHomeIndex !=
                    current.horizondalScrollingWidgetHomeIndex ||
                previous.myPlayerState.currentSongId !=
                    current.myPlayerState.currentSongId ||
                previous.myPlayerState.completedSongs !=
                    current.myPlayerState.completedSongs ||
                previous.myPlayerState.currentPlayList !=
                    current.myPlayerState.currentPlayList ||
                !identical(previous.allSongs, current.allSongs) ||
                !identical(previous.artistList, current.artistList) ||
                !identical(previous.albumList, current.albumList);
          },
          builder: (context, musicState) {
            return BlocBuilder<AppSettingsBloc, AppSettingsState>(
              buildWhen: (previous, current) {
                return previous.nickName != current.nickName ||
                    previous.currentQuoteIndex != current.currentQuoteIndex ||
                    previous.isAiShuffleEnabled != current.isAiShuffleEnabled;
              },
              builder: (context, appSettingsState) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  cacheExtent: 400,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(_sectionPadding.w),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildAnimatedWelcomeSection(),
                          SizedBox(height: _largeSpacing.h),
                          _buildQuickStats(musicState),
                          SizedBox(height: _largeSpacing.h),
                          _buildCustomizeEqualizerCard(),
                          SizedBox(height: _largeSpacing.h),
                          _buildQuiltedGrid(musicState, appSettingsState),
                          SizedBox(height: _largeSpacing.h),
                          _buildListenAgain(musicState),
                          SizedBox(height: _largeSpacing.h),
                          _buildHorizondalScrollingWidget(musicState),
                          SizedBox(height: _largeSpacing.h),
                          _buildTopAlbumsByPlayCount(musicState),
                          SizedBox(height: _largeSpacing.h),
                          _buildTopArtistsByPlayCount(musicState),
                          SizedBox(height: 150.h),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedWelcomeSection() {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, appSettingsState) {
        final nickName = appSettingsState.nickName ?? 'Music Lover';
        final quoteIndex = appSettingsState.currentQuoteIndex;
        final safeQuoteIndex = quoteIndex.clamp(
          0,
          AppConstants.musicQuotes.length - 1,
        );
        final selectedQuote = AppConstants.musicQuotes[safeQuoteIndex];

        return Custom3DCard(
          enableAnimation: true,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_cardPadding.w),
                    decoration: BoxDecoration(
                      gradient: context.primaryGradient,
                      borderRadius: BorderRadius.circular(_borderRadius.r),
                    ),
                    child: Icon(
                      CupertinoIcons.hand_raised,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: _cardPadding.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi there, $nickName! 👋',
                          style: TextStyle(
                            color: context.onSurfaceColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${AppConstants.appTagline}...',
                          style: TextStyle(
                            color: context.onSurfaceVariantColor,
                            fontSize: 12.sp,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<AppSettingsBloc>().add(
                    const AppSettingsEvent.updateDailyQuote(forceUpdate: true),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryStart.withValues(alpha: 0.1),
                        context.primaryEnd.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.primaryStart.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.0, 0.3),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      selectedQuote,
                      key: ValueKey<String>(selectedQuote),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(MusicState state) {
    final totalSongs = state.allSongs.length;
    final totalArtists = state.artistList.length;
    final totalAlbums = state.albumList.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Artists',
            count: totalArtists,
            icon: CupertinoIcons.person,
            color: context.primaryStart,
            onTap: () => _navigateToArtistsTab(),
            animationDelay: _statsDelay,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Songs',
            count: totalSongs,
            icon: CupertinoIcons.music_note,
            color: context.accentTeal,
            onTap: () => _navigateToSongsTab(),
            animationDelay: 1,
            height: 155.h,
            iconSize: 28,
            fontSize: 22,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Albums',
            count: totalAlbums,
            icon: CupertinoIcons.music_albums,
            color: context.accentGreen,
            onTap: () => _navigateToAlbumsTab(),
            animationDelay: 2,
          ),
        ),
      ],
    );
  }

  /// Attractive card that opens the Equalizer screen. On tap, enables equalizer
  /// and navigates immediately.
  Widget _buildCustomizeEqualizerCard() {
    return Custom3DCard(
      enableAnimation: true,
      animationDelay: 3,
      padding:
          EdgeInsets.zero, // Remove default padding so image expands to edge
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<EqualizerBloc>().add(
          const EqualizerEvent.persistEqualizerState(isEnabled: true),
        );
        context.navigateToEqualizer();
      },
      child: Container(
        height: 70.h, // Explicit slightly reduced height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius.r),
          image: const DecorationImage(
            image: AssetImage('assets/images/equalizer_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54, // Darken the image so text pops
              BlendMode.darken,
            ),
          ),
          border: Border.all(
            color: context.primaryStart.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryStart.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius.r),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                context.primaryStart.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.waveform,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Customize Equalizer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4.r,
                            offset: Offset(0, 1.h),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Tune your sound',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Song> _getListenAgainSongs(MusicState state) {
    final ps = state.myPlayerState;
    final songMap = {for (var s in state.allSongs) s.id: s};
    final recentIds = <String>[];
    if (ps.currentSongId != null) recentIds.add(ps.currentSongId!);
    for (var i = ps.completedSongs.length - 1; i >= 0; i--) {
      recentIds.add(ps.completedSongs[i]);
    }
    return recentIds
        .take(6)
        .map((id) => songMap[id])
        .whereType<Song>()
        .toList();
  }

  Widget _buildListenAgain(MusicState state) {
    final listenAgainSongs = _getListenAgainSongs(state);
    if (listenAgainSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Listen Again', listenAgainSongs.length, () {
          context.read<MusicBloc>().add(
            MusicEvent.changeSortingOrder(
              sortingIndex: 5,
              sortingList: state.allSongs.map((s) => s.id).toList(),
              playlistSource: PlaylistSource.allSongs(),
            ),
          );
          _navigateToTab(1);
        }),
        SizedBox(height: _itemSpacing.h),
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 200,
            itemCount: listenAgainSongs.length,
            itemBuilder: (context, index) {
              final song = listenAgainSongs[index];
              return RepaintBoundary(child: _buildListenAgainCard(song));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListenAgainCard(Song song) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: Offset(0, 2.h),
                      blurRadius: 6.r,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: AlbumArtWidget(
                    albumArt: song.albumArt,
                    borderRadius: 12.r,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              song.title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestions: first up to 10 most played songs, then fill remaining slots
  /// with random songs from all songs (not already in the list).
  List<Song> _getSuggestionSongsFromAllSongs(List<Song> allSongs) {
    const int targetCount = 10;
    if (allSongs.isEmpty) return [];

    // 1. Get most played songs (sorted by play count), take up to targetCount
    final mostPlayed = allSongs.where((s) => (s.playCount ?? 0) > 0).toList();
    final sortedMostPlayed = mostPlayed.isNotEmpty
        ? SortingHelper.sortByPlayCount(mostPlayed, ascending: false)
        : <Song>[];
    final result = sortedMostPlayed.take(targetCount).toList();
    final resultIds = result.map((s) => s.id).toSet();

    // 2. If fewer than 10, fill remaining slots with random songs from all songs
    if (result.length < targetCount) {
      final remainingSongs =
          allSongs.where((s) => !resultIds.contains(s.id)).toList()
            ..shuffle(Random());
      final needed = targetCount - result.length;
      for (int i = 0; i < needed && i < remainingSongs.length; i++) {
        result.add(remainingSongs[i]);
      }
    }

    return result;
  }

  Widget _buildQuiltedGrid(
    MusicState state,
    AppSettingsState appSettingsState,
  ) {
    final suggestionSongs = _getSuggestionSongsFromAllSongs(state.allSongs);
    final displaySongs = suggestionSongs.take(10).toList();

    if (displaySongs.isEmpty) {
      return _buildEmptyStateCard(
        appSettingsState.isAiShuffleEnabled
            ? 'AI Suggestions'
            : 'My Suggestions',
        'Start playing songs to see personalized suggestions here!',
        appSettingsState.isAiShuffleEnabled
            ? CupertinoIcons.sparkles
            : CupertinoIcons.lightbulb,
        0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _itemSpacing.h),
        SizedBox(
          height: 280.h,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              if (width <= 0 || height <= 0) {
                return const SizedBox.shrink();
              }
              return GridView.custom(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverQuiltedGridDelegate(
                  crossAxisCount: 4,
                  mainAxisSpacing: 4.w,
                  crossAxisSpacing: 4.w,
                  repeatPattern: QuiltedGridRepeatPattern.inverted,
                  pattern: [
                    QuiltedGridTile(2, 2),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 2),
                    QuiltedGridTile(1, 2),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                  ],
                ),
                childrenDelegate: SliverChildBuilderDelegate((context, index) {
                  if (index == 0) {
                    return _buildMySuggestionsCard(appSettingsState);
                  }
                  if (index >= 1 && index <= 4) {
                    final songIndex = index - 1;
                    if (songIndex < displaySongs.length) {
                      return _buildAlbumArtCard(displaySongs[songIndex]);
                    }
                    return _buildEmptyAlbumCard();
                  }
                  if (index >= 5 && index <= 8) {
                    final songIndex = index - 1;
                    if (songIndex < displaySongs.length) {
                      return _buildAlbumArtCard(displaySongs[songIndex]);
                    }
                    return _buildEmptyAlbumCard();
                  }
                  final songIndex = index - 1;
                  if (songIndex < displaySongs.length) {
                    return _buildAlbumArtCard(displaySongs[songIndex]);
                  }
                  return _buildEmptyAlbumCard();
                }, childCount: 11),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMySuggestionsCard(AppSettingsState appSettingsState) {
    final isAiEnabled = appSettingsState.isAiShuffleEnabled;
    final titleText = isAiEnabled ? 'AI' : 'My';
    final subtitleText = 'Suggestions';
    final icon = isAiEnabled
        ? CupertinoIcons.sparkles
        : CupertinoIcons.lightbulb;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [
                  context.primaryStart.withValues(alpha: 0.8),
                  context.primaryEnd.withValues(alpha: 0.9),
                ]
              : [
                  context.primaryStart.withValues(alpha: 0.6),
                  context.primaryEnd.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: context.primaryStart.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : context.primaryStart.withValues(alpha: 0.2),
            offset: Offset(0, 4.h),
            blurRadius: 8.r,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: context.isDark ? Colors.white : Colors.white,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              titleText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                  ),
                ],
              ),
            ),
            Text(
              subtitleText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtCard(Song song, {double? borderRadius}) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: Offset(0, 2.h),
              blurRadius: 4.r,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          child: AlbumArtWidget(
            albumArt: song.albumArt,
            borderRadius: borderRadius ?? 8.r,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAlbumCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.onSurfaceVariantColor.withValues(alpha: 0.1),
            context.onSurfaceVariantColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: context.onSurfaceVariantColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.music_note,
          color: context.onSurfaceVariantColor.withValues(alpha: 0.5),
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildHorizondalScrollingWidget(MusicState state) {
    return HorizondalScrollingWidgetHome(
      allSongs: state.allSongs,
      artistList: state.artistList,
      albumList: state.albumList,
      onRecentlyAddedPressed: () => _navigateToRecentlyAdded(),
      onMostPlayedPressed: () => _navigateToMostPlayed(),
      maxSongsPerSection: _maxSongsPerSection,
      animationDelay: _recentlyAddedDelay,
    );
  }

  Widget _buildTopArtistsByPlayCount(MusicState state) {
    final topArtists = _getTopArtists(state.artistList);

    if (topArtists.isEmpty) {
      return _buildEmptyStateCard(
        'Top Artists',
        'Start playing songs to see your top artists here!',
        CupertinoIcons.person,
        _topArtistsDelay,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Top Artists',
          topArtists.length,
          () => _navigateToTopArtists(),
        ),
        SizedBox(height: _itemSpacing.h),
        SizedBox(
          height: 205.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 200,
            itemCount: topArtists.take(6).length,
            itemBuilder: (context, index) {
              final artist = topArtists[index];
              return RepaintBoundary(
                child: _buildMediaCard(
                  mediaItem: artist,
                  allSongs: state.allSongs,
                  isAlbum: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopAlbumsByPlayCount(MusicState state) {
    final topAlbums = _getTopAlbums(state.albumList);

    if (topAlbums.isEmpty) {
      return _buildEmptyStateCard(
        'Top Albums',
        'Start playing songs to see your top albums here!',
        CupertinoIcons.music_albums,
        _topAlbumsDelay,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Top Albums',
          topAlbums.length,
          () => _navigateToTopAlbums(),
        ),
        SizedBox(height: _itemSpacing.h),
        SizedBox(
          height: 205.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 200,
            itemCount: topAlbums.take(6).length,
            itemBuilder: (context, index) {
              final album = topAlbums[index];
              return RepaintBoundary(
                child: _buildMediaCard(
                  mediaItem: album,
                  allSongs: state.allSongs,
                  isAlbum: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Convenience methods for specific types

  Widget _buildSectionHeader(String title, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: context.primaryStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: context.primaryStart,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: context.onSurfaceVariantColor,
                  size: 14.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playSong(Song song) {
    context.read<MusicBloc>().add(
      MusicEvent.playOrPauseSong(songId: song.id, currentPlayList: [song.id]),
    );
  }

  /// Unified method to build both artist and album cards
  Widget _buildMediaCard({
    required dynamic mediaItem, // Can be Artist or Album
    required List<Song> allSongs,
    required bool isAlbum,
  }) {
    List<Song> mediaSongs;
    String title;
    VoidCallback? onTap;
    VoidCallback? onPlay;
    Widget imageWidget;

    if (isAlbum) {
      final album = mediaItem as Album;
      mediaSongs = AlbumArtistPlaylistHelper.getAlbumSongs(album, allSongs);
      title = album.name.isNotEmpty ? album.name : 'Unknown Album';
      onTap = mediaSongs.isNotEmpty
          ? () => _navigateToAlbumDetail(album, mediaSongs)
          : null;
      onPlay = mediaSongs.isNotEmpty ? () => _playAlbum(mediaSongs) : null;

      // Album uses circular album art
      imageWidget = Center(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: AlbumArtistPlaylistHelper.buildCircularAlbumArt(
            context: context,
            album: album,
            albumSongs: mediaSongs,
          ),
        ),
      );
    } else {
      final artist = mediaItem as Artist;
      mediaSongs = AlbumArtistPlaylistHelper.getArtistSongs(artist, allSongs);
      title = artist.name;
      onTap = mediaSongs.isNotEmpty
          ? () => _navigateToArtistDetail(artist, mediaSongs)
          : null;
      onPlay = mediaSongs.isNotEmpty ? () => _playArtist(mediaSongs) : null;

      // Artist uses regular artist image
      imageWidget = AlbumArtistPlaylistHelper.buildArtistImage(
        context: context,
        artist: artist,
        artistSongs: mediaSongs,
      );
    }

    final songCount = mediaSongs.length;
    final hasSongs = songCount > 0;

    return AlbumArtistPlaylistHelper.buildCard(
      // height: 190.h,
      width: 140.w,
      boxShadow: [],
      margin: EdgeInsets.only(right: 10.w),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Section
          AlbumArtistPlaylistHelper.buildCardImageSection(
            imageWidget: imageWidget,
          ),

          SizedBox(height: 8.h),

          // Info Section
          AlbumArtistPlaylistHelper.buildCardInfoSection(
            context: context,
            title: title,
            songCount: songCount,
            hasSongs: hasSongs,
            onPlay: onPlay,
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

  void _playAlbum(List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.playSongs(
      context: context,
      songs: albumSongs,
      playlistSource: PlaylistSource.album(albumSongs.first.albums.first),
    );
  }

  void _navigateToArtistDetail(Artist artist, List<Song> artistSongs) {
    AlbumArtistPlaylistHelper.navigateToArtistDetail(
      context: context,
      artist: artist,
    );
  }

  void _navigateToAlbumDetail(Album album, List<Song> albumSongs) {
    AlbumArtistPlaylistHelper.navigateToAlbumDetail(
      context: context,
      album: album,
    );
  }

  void _navigateToRecentlyAdded() {
    _logger.i('Navigate to recently added songs');
    // Set sorting to 'Newest First' (index 0) before navigating
    context.read<MusicBloc>().add(
      MusicEvent.changeSortingOrder(
        sortingIndex: 0, // Newest First
        sortingList: context
            .read<MusicBloc>()
            .state
            .allSongs
            .map((s) => s.id)
            .toList(),
        playlistSource: PlaylistSource.allSongs(),
      ),
    );
    // Navigate to songs tab
    _navigateToTab(1); // Songs tab is index 1
  }

  void _navigateToMostPlayed() {
    _logger.i('Navigate to most played songs');
    // Set sorting to 'Most Played' (index 5) before navigating
    context.read<MusicBloc>().add(
      MusicEvent.changeSortingOrder(
        sortingIndex: 5, // Most Played
        sortingList: context
            .read<MusicBloc>()
            .state
            .allSongs
            .map((s) => s.id)
            .toList(),
        playlistSource: PlaylistSource.allSongs(),
      ),
    );
    // Navigate to songs tab so user sees the sorted list
    _navigateToTab(1); // Songs tab is index 1
  }

  void _navigateToTopArtists() {
    _logger.i('Navigate to top artists');
    // Navigate to artists tab and filter by top artists
    _navigateToTabWithFilter(3, 'top_artists', null); // Artists tab is index 3
  }

  void _navigateToTopAlbums() {
    _logger.i('Navigate to top albums');
    // Navigate to albums tab and filter by top albums
    _navigateToTabWithFilter(2, 'top_albums', null); // Albums tab is index 2
  }

  void _navigateToArtistsTab() {
    _logger.i('Navigate to artists tab');
    _navigateToTab(3); // Artists tab is index 3
  }

  void _navigateToSongsTab() {
    _logger.i('Navigate to songs tab');
    _navigateToTab(1); // Songs tab is index 1
  }

  void _navigateToAlbumsTab() {
    _logger.i('Navigate to albums tab');
    _navigateToTab(2); // Albums tab is index 2
  }

  /// Navigate to a specific tab
  void _navigateToTab(int tabIndex) {
    // Find the parent BottomTab widget and call its tab switching method
    final bottomTabState = context.findAncestorStateOfType<BottomTabState>();
    if (bottomTabState != null) {
      bottomTabState.onTabTapped(tabIndex);
    } else {
      _logger.w('Could not find BottomTab parent widget');
    }
  }

  /// Navigate to a specific tab with filter parameters
  void _navigateToTabWithFilter(
    int tabIndex,
    String filterType,
    String? filterValue,
  ) {
    // First navigate to the tab
    _navigateToTab(tabIndex);

    // Then set the filter in the MusicBloc
    context.read<MusicBloc>().add(
      MusicEvent.setNavigationFilter(
        filterType: filterType,
        filterValue: filterValue,
      ),
    );
  }
}
