import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/album/album_model.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/jamendo/jamendo_config.dart';
import '../../utils/services/jamendo/jamendo_models.dart';
import '../../utils/services/jamendo/jamendo_repository.dart';
import '../app_settings/bloc/app_settings_bloc.dart';
import '../bottom_tab/widgets/custom_tab_view_app_bar.dart';
import 'bloc/online_browse_bloc.dart';
import 'online_collection_screen.dart';
import 'widgets/online_widgets.dart';

/// Online Songs / Albums / Artists tab (Discover source).
class OnlineBrowseScreen extends StatelessWidget {
  const OnlineBrowseScreen({super.key, required this.kind});

  final OnlineBrowseKind kind;

  String get title => switch (kind) {
    OnlineBrowseKind.tracks => 'Songs',
    OnlineBrowseKind.albums => 'Albums',
    OnlineBrowseKind.artists => 'Artists',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Keyed by kind: a different tab always gets its own bloc.
      key: ValueKey('online_browse_${kind.name}'),
      create: (_) => OnlineBrowseBloc(
        repository: getIt<JamendoRepository>(),
        kind: kind,
      )..add(const OnlineBrowseEvent.started()),
      child: _OnlineBrowseView(title: title, kind: kind),
    );
  }
}

class _OnlineBrowseView extends StatefulWidget {
  const _OnlineBrowseView({required this.title, required this.kind});
  final String title;
  final OnlineBrowseKind kind;

  @override
  State<_OnlineBrowseView> createState() => _OnlineBrowseViewState();
}

class _OnlineBrowseViewState extends State<_OnlineBrowseView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        context.read<OnlineBrowseBloc>().add(const OnlineBrowseEvent.loadMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
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
              title: widget.title,
              showSearchButton: false,
              scrollController: _scroll,
            ),
            Expanded(
              child: BlocBuilder<OnlineBrowseBloc, OnlineBrowseState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    color: context.primaryStart,
                    onRefresh: () async {
                      final bloc = context.read<OnlineBrowseBloc>();
                      bloc.add(const OnlineBrowseEvent.refreshed());
                      await bloc.stream.firstWhere((s) => s.status != BrowseStatus.loading);
                    },
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
                          sliver: SliverToBoxAdapter(child: _controls(context, state)),
                        ),
                        if (state.isOffline && !state.isEmpty)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverToBoxAdapter(
                              child: OfflineBanner(
                                onSwitchToLocal: () => context.read<AppSettingsBloc>().add(
                                  const AppSettingsEvent.updateMusicSource(
                                    source: MusicSourceKeys.local,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ..._content(context, state),
                        SliverToBoxAdapter(child: SizedBox(height: 160.h)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, OnlineBrowseState state) {
    final bloc = context.read<OnlineBrowseBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('online_search'),
          controller: _search,
          onChanged: (q) => bloc.add(OnlineBrowseEvent.queryChanged(q)),
          textInputAction: TextInputAction.search,
          style: TextStyle(color: context.onSurfaceColor, fontFamily: 'Poppins', fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Search ${widget.title.toLowerCase()} on Jamendo',
            prefixIcon: Icon(CupertinoIcons.search, size: 18.sp),
            suffixIcon: state.isSearching
                ? IconButton(
                    icon: Icon(CupertinoIcons.clear_circled_solid, size: 18.sp),
                    onPressed: () {
                      _search.clear();
                      bloc.add(const OnlineBrowseEvent.queryChanged(''));
                    },
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: context.onSurfaceColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!state.isSearching) ...[
          SizedBox(height: 10.h),
          SizedBox(
            height: 34.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(context, 'Popular', state.sort == OnlineSort.popular && state.tag == null, () {
                  bloc.add(const OnlineBrowseEvent.tagChanged(null));
                  bloc.add(const OnlineBrowseEvent.sortChanged(OnlineSort.popular));
                }),
                _chip(context, 'Newest', state.sort == OnlineSort.newest && state.tag == null, () {
                  bloc.add(const OnlineBrowseEvent.tagChanged(null));
                  bloc.add(const OnlineBrowseEvent.sortChanged(OnlineSort.newest));
                }),
                if (widget.kind == OnlineBrowseKind.tracks)
                  for (final tag in [...JamendoConfig.moodTags, ...JamendoConfig.featuredGenres])
                    _chip(
                      context,
                      JamendoMix.titleFor(tag).replaceAll(' Mix', ''),
                      state.tag == tag,
                      () => bloc.add(OnlineBrowseEvent.tagChanged(state.tag == tag ? null : tag)),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? context.primaryGradient : null,
            color: selected ? null : context.onSurfaceColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : context.onSurfaceColor,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, OnlineBrowseState state) {
    if (state.showSkeleton) {
      return [_skeleton(context)];
    }
    if (state.status == BrowseStatus.failure && state.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.all(16.w),
          sliver: SliverToBoxAdapter(
            child: InlineRetry(
              height: 200.h,
              message: friendlyError(state.error),
              onRetry: () => context.read<OnlineBrowseBloc>().add(
                const OnlineBrowseEvent.started(force: true),
              ),
            ),
          ),
        ),
      ];
    }
    if (state.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.all(32.w),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                Icon(CupertinoIcons.search, size: 36.sp, color: context.onSurfaceVariantColor),
                SizedBox(height: 10.h),
                Text(
                  state.isSearching ? 'No results for "${state.query}"' : 'Nothing here yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.onSurfaceVariantColor, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      switch (widget.kind) {
        OnlineBrowseKind.tracks => _songList(context, state.songs, state),
        OnlineBrowseKind.albums => _grid(
          context,
          state.albums.length,
          (i) => _albumCard(context, state.albums[i]),
        ),
        OnlineBrowseKind.artists => _grid(
          context,
          state.artists.length,
          (i) => _artistCard(context, state.artists[i]),
        ),
      },
      if (state.isLoadingMore) _loadMoreSkeleton(context),
    ];
  }

  String get _queueKey => 'browse_${widget.kind.name}';

  Widget _songList(BuildContext context, List<Song> songs, OnlineBrowseState state) {
    final title = state.isSearching
        ? 'Search: ${state.query}'
        : state.tag != null
        ? JamendoMix.titleFor(state.tag!)
        : state.sort == OnlineSort.newest
        ? 'Newest songs'
        : 'Popular songs';
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      sliver: SliverList.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => OnlineSongTile(
          song: songs[i],
          onTap: () => playOnlineList(
            context,
            queueKey: _queueKey,
            title: title,
            songs: songs,
            startIndex: i,
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, int count, Widget Function(int i) builder) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.72,
        ),
        itemCount: count,
        itemBuilder: (context, i) => builder(i),
      ),
    );
  }

  Widget _albumCard(BuildContext context, Album album) => LayoutBuilder(
    builder: (context, c) => OnlineMediaCard(
      width: c.maxWidth,
      title: album.name,
      subtitle: album.artistName ?? '',
      imageUrl: album.coverImage,
      icon: CupertinoIcons.music_albums,
      onTap: () => openOnlineAlbum(context, album),
    ),
  );

  Widget _artistCard(BuildContext context, Artist artist) => LayoutBuilder(
    builder: (context, c) => OnlineMediaCard(
      width: c.maxWidth,
      circle: true,
      title: artist.name,
      subtitle: 'Artist',
      imageUrl: artist.image,
      icon: CupertinoIcons.person_fill,
      onTap: () => openOnlineArtist(context, artist),
    ),
  );

  Widget _skeleton(BuildContext context) {
    final sliver = switch (widget.kind) {
      OnlineBrowseKind.tracks => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        sliver: SliverList.builder(
          itemCount: 10,
          itemBuilder: (_, i) => OnlineSongTile(song: SkeletonData.songs(10)[i], onTap: () {}),
        ),
      ),
      OnlineBrowseKind.albums => _grid(
        context,
        9,
        (i) => _albumCard(context, SkeletonData.albums(9)[i]),
      ),
      OnlineBrowseKind.artists => _grid(
        context,
        9,
        (i) => _artistCard(context, SkeletonData.artists(9)[i]),
      ),
    };
    return Skeletonizer.sliver(effect: discoverShimmer(context), child: sliver);
  }

  Widget _loadMoreSkeleton(BuildContext context) {
    final songs = SkeletonData.songs(2);
    return Skeletonizer.sliver(
      effect: discoverShimmer(context),
      child: SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        sliver: SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) => OnlineSongTile(song: songs[i], onTap: () {}),
        ),
      ),
    );
  }
}
