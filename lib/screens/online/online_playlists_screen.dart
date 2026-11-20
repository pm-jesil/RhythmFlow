import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/jamendo/jamendo_models.dart';
import '../../utils/services/jamendo/jamendo_repository.dart';
import '../bottom_tab/widgets/custom_tab_view_app_bar.dart';
import '../widgets/custom_3d_card.dart';
import 'bloc/discover_bloc.dart';
import 'bloc/online_library_bloc.dart';
import 'online_collection_screen.dart';
import 'widgets/online_widgets.dart';

/// Online Playlists tab: the user's own online collection, curated mixes
/// and live radio.
class OnlinePlaylistsScreen extends StatefulWidget {
  const OnlinePlaylistsScreen({super.key});

  @override
  State<OnlinePlaylistsScreen> createState() => _OnlinePlaylistsScreenState();
}

class _OnlinePlaylistsScreenState extends State<OnlinePlaylistsScreen> {
  final ScrollController _scroll = ScrollController();
  late Future<List<JamendoRadio>> _radios;

  @override
  void initState() {
    super.initState();
    _radios = _loadRadios();
  }

  Future<List<JamendoRadio>> _loadRadios() {
    // Reuse the Discover row when it is already loaded.
    final section = context.read<DiscoverBloc>().state.sections[DiscoverSectionIds.radio];
    if (section != null && section.radios.isNotEmpty) {
      return Future.value(section.radios);
    }
    return getIt<JamendoRepository>().radios();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mixes = getIt<JamendoRepository>().mixes();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Column(
          children: [
            CustomTabViewAppBar(title: 'Playlists', showSearchButton: false, scrollController: _scroll),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 160.h),
                children: [
                  const OnlineSectionHeader(title: 'Your library', subtitle: 'Saved on this device'),
                  const _LibraryTiles(),
                  SizedBox(height: 22.h),
                  const OnlineSectionHeader(title: 'Curated mixes', subtitle: 'Featured by Jamendo'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mixes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 1.75,
                    ),
                    itemBuilder: (context, i) => LayoutBuilder(
                      builder: (context, c) => OnlineMixCard(
                        width: c.maxWidth,
                        mix: mixes[i],
                        onTap: () => openOnlineMix(context, mixes[i]),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  const OnlineSectionHeader(title: 'Live radio', subtitle: '24/7 stations'),
                  FutureBuilder<List<JamendoRadio>>(
                    future: _radios,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return InlineRetry(
                          height: 140.h,
                          message: friendlyError(snapshot.error),
                          onRetry: () => setState(() => _radios = getIt<JamendoRepository>().radios()),
                        );
                      }
                      final loading = !snapshot.hasData;
                      final radios = snapshot.data ??
                          List.generate(
                            6,
                            (i) => JamendoRadio(id: '$i', name: 'radio', displayName: 'Radio station', image: ''),
                          );
                      return Skeletonizer(
                        enabled: loading,
                        effect: discoverShimmer(context),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: radios.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14.h,
                            crossAxisSpacing: 10.w,
                            childAspectRatio: 0.74,
                          ),
                          itemBuilder: (context, i) => LayoutBuilder(
                            builder: (context, c) => RadioCard(
                              width: c.maxWidth,
                              radio: radios[i],
                              loading: loading,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const JamendoAttribution(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTiles extends StatelessWidget {
  const _LibraryTiles();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineLibraryBloc, OnlineLibraryState>(
      builder: (context, state) {
        final downloaded = state.downloads.values
            .where((d) => d.phase == DownloadPhase.completed && d.song != null)
            .map((d) => d.song!)
            .toList();
        return Column(
          children: [
            _tile(
              context,
              key: const ValueKey('library_liked'),
              icon: CupertinoIcons.heart_fill,
              title: 'Liked songs',
              songs: state.likedSongs,
              queueKey: 'liked',
              emptyHint: 'Tap ♡ on any Discover song',
            ),
            SizedBox(height: 10.h),
            _tile(
              context,
              key: const ValueKey('library_recent'),
              icon: CupertinoIcons.clock_fill,
              title: 'Recently played',
              songs: state.recentlyPlayed.where((s) => !s.isRadio).toList(),
              queueKey: 'recent',
              emptyHint: 'Songs you play on Discover show up here',
            ),
            SizedBox(height: 10.h),
            _tile(
              context,
              key: const ValueKey('library_downloads'),
              icon: CupertinoIcons.arrow_down_circle_fill,
              title: 'Downloaded',
              songs: downloaded,
              queueKey: 'downloads',
              emptyHint: 'Downloads are saved to My Music',
            ),
          ],
        );
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String title,
    required List<Song> songs,
    required String queueKey,
    required String emptyHint,
  }) {
    final empty = songs.isEmpty;
    return Custom3DCard(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      onTap: empty
          ? null
          : () => openOnlineSongList(context, queueKey: queueKey, title: title, songs: songs),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  empty ? emptyHint : '${songs.length} song${songs.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 11.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (!empty)
            IconButton(
              tooltip: 'Play',
              onPressed: () => playOnlineList(context, queueKey: queueKey, title: title, songs: songs),
              icon: Icon(CupertinoIcons.play_circle_fill, color: context.primaryStart, size: 30.sp),
            ),
        ],
      ),
    );
  }
}
