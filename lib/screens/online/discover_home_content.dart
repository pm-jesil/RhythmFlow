import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/theme/theme_extension.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/jamendo/jamendo_api_client.dart';
import '../../utils/services/jamendo/region_models.dart';
import '../app_settings/bloc/app_settings_bloc.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import 'bloc/discover_bloc.dart';
import 'bloc/online_library_bloc.dart';
import 'online_collection_screen.dart';
import 'widgets/discover_feature_widgets.dart';
import 'widgets/discover_gate.dart';
import 'widgets/taste_picker.dart';
import 'widgets/discover_setup_dialog.dart';
import 'widgets/online_widgets.dart';

/// Discover home (online "For You"): shown under the greeting card and the
/// source switch when Discover is selected.
class DiscoverHomeContent extends StatefulWidget {
  const DiscoverHomeContent({super.key});

  @override
  State<DiscoverHomeContent> createState() => _DiscoverHomeContentState();
}

class _DiscoverHomeContentState extends State<DiscoverHomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (!mounted) return;
    final settings = context.read<AppSettingsBloc>().state;
    final discover = context.read<DiscoverBloc>();
    if (!settings.isDiscoverReady) return; // setup form is shown instead
    if (discover.state.country != settings.musicCountry ||
        discover.state.languages.join(',') != settings.musicLanguages.join(',') ||
        discover.state.tastes.join(',') != settings.musicTastes.join(',')) {
      discover.add(
        DiscoverEvent.regionChanged(
          country: settings.musicCountry,
          languages: settings.musicLanguages,
          tastes: settings.musicTastes,
        ),
      );
    } else {
      // Served from cache when fresh, so this is cheap.
      discover.add(const DiscoverEvent.loadHome());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsBloc>().state;
    return BlocBuilder<DiscoverBloc, DiscoverState>(
      builder: (context, state) {
        if (state.notConfigured) return const _NotConfigured();
        // Only signed-in users who finished the setup see Discover.
        if (!settings.isDiscoverReady) {
          return const DiscoverGate(fullScreen: false, child: SizedBox.shrink());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isOffline)
              OfflineBanner(
                onSwitchToLocal: () => context.read<AppSettingsBloc>().add(
                  const AppSettingsEvent.updateMusicSource(source: MusicSourceKeys.local),
                ),
              ),
            _RegionChip(settings: settings),
            SizedBox(height: 10.h),
            VibeChipsRow(
              tastes: settings.musicTastes,
              onEdit: () => _editVibes(context, settings.musicTastes),
            ),
            SizedBox(height: 18.h),
            const _RecentlyPlayedShelf(),
            if (state.isInitialLoading)
              const DiscoverHomeSkeleton()
            else
              for (final section in state.orderedSections) ...[
                DiscoverSectionView(section: section),
                SizedBox(height: 22.h),
              ],
            const JamendoAttribution(),
          ],
        );
      },
    );
  }
}

Future<void> _editVibes(BuildContext context, List<String> current) async {
  final picked = await showTastePicker(context, selected: current);
  if (picked != null && context.mounted) {
    context.read<AppSettingsBloc>().add(AppSettingsEvent.updateMusicTastes(tastes: picked));
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.settings});
  final AppSettingsState settings;

  @override
  Widget build(BuildContext context) {
    final country = MusicRegions.countryByAlpha2(settings.musicCountry);
    final language = settings.musicLanguages.isEmpty
        ? null
        : MusicRegions.languageByCode(settings.musicLanguages.first);
    final hasRegion = country != null && language != null;
    final label = hasRegion
        ? '${country.flag}  ${country.name} · ${language.name}'
            '${settings.musicLanguages.length > 1 ? ' +${settings.musicLanguages.length - 1}' : ''}'
        : 'Personalise Discover';
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        key: const ValueKey('discover_region_chip'),
        onPressed: () => showDiscoverSetupDialog(context, editing: hasRegion),
        avatar: Icon(
          hasRegion ? CupertinoIcons.slider_horizontal_3 : CupertinoIcons.sparkles,
          size: 16.sp,
          color: context.primaryStart,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: context.primaryStart.withValues(alpha: 0.08),
        side: BorderSide(color: context.primaryStart.withValues(alpha: 0.25)),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _RecentlyPlayedShelf extends StatelessWidget {
  const _RecentlyPlayedShelf();

  @override
  Widget build(BuildContext context) {
    final recent = context.select<OnlineLibraryBloc, List<Song>>(
      (b) => b.state.recentlyPlayed,
    );
    final songs = recent.where((s) => !s.isRadio).take(15).toList();
    if (songs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnlineSectionHeader(title: 'Jump back in', subtitle: 'Recently played'),
          QuickAccessGrid(queueKey: 'recent', title: 'Recently played', songs: songs),
        ],
      ),
    );
  }
}

/// One Discover section with its own loading / error state.
class DiscoverSectionView extends StatelessWidget {
  const DiscoverSectionView({super.key, required this.section});
  final DiscoverSection section;

  @override
  Widget build(BuildContext context) {
    final header = OnlineSectionHeader(
      title: section.title,
      subtitle: section.subtitle,
      onSeeAll: section.kind == DiscoverSectionKind.tracks && section.songs.length > 4
          ? () => openOnlineSongList(
              context,
              queueKey: 'section_${section.id}',
              title: section.title,
              songs: section.songs,
              description: section.subtitle,
            )
          : null,
    );

    Widget body;
    if (section.isEmpty && section.isLoading) {
      body = switch (section.style) {
        SectionStyle.hero => const _HeroSkeleton(),
        SectionStyle.chart => const _ChartSkeleton(),
        SectionStyle.shelf => _ShelfSkeleton(circle: section.kind == DiscoverSectionKind.artists),
      };
    } else if (section.isEmpty && section.hasError) {
      body = InlineRetry(
        height: 150.h,
        message: friendlyError(section.error ?? JamendoErrorKind.unknown),
        onRetry: () => context.read<DiscoverBloc>().add(
          DiscoverEvent.refreshSection(sectionId: section.id),
        ),
      );
    } else if (section.isEmpty) {
      return const SizedBox.shrink();
    } else {
      body = switch (section.kind) {
        DiscoverSectionKind.tracks when section.style == SectionStyle.hero => HeroCarousel(
          queueKey: 'section_${section.id}',
          title: section.title,
          songs: section.songs,
        ),
        DiscoverSectionKind.tracks when section.style == SectionStyle.chart => RankedChart(
          queueKey: 'section_${section.id}',
          title: section.title,
          songs: section.songs,
        ),
        DiscoverSectionKind.tracks => _SongShelf(
          queueKey: 'section_${section.id}',
          title: section.title,
          songs: section.songs,
        ),
        DiscoverSectionKind.albums => HorizontalShelf(
          itemCount: section.albums.length,
          itemBuilder: (context, i) {
            final album = section.albums[i];
            return OnlineMediaCard(
              title: album.name,
              subtitle: album.artistName ?? '',
              imageUrl: album.coverImage,
              icon: CupertinoIcons.music_albums,
              onTap: () => openOnlineAlbum(context, album),
            );
          },
        ),
        DiscoverSectionKind.artists => HorizontalShelf(
          height: 150.h,
          itemCount: section.artists.length,
          itemBuilder: (context, i) {
            final artist = section.artists[i];
            return OnlineMediaCard(
              width: 100.w,
              circle: true,
              title: artist.name,
              subtitle: 'Artist',
              imageUrl: artist.image,
              icon: CupertinoIcons.person_fill,
              onTap: () => openOnlineArtist(context, artist),
            );
          },
        ),
        DiscoverSectionKind.mixes => HorizontalShelf(
          height: 96.h,
          itemCount: section.mixes.length,
          itemBuilder: (context, i) => OnlineMixCard(
            width: 150.w,
            mix: section.mixes[i],
            onTap: () => openOnlineMix(context, section.mixes[i]),
          ),
        ),
        DiscoverSectionKind.radios => HorizontalShelf(
          height: 170.h,
          itemCount: section.radios.length,
          itemBuilder: (context, i) => RadioCard(width: 116.w, radio: section.radios[i]),
        ),
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: body),
      ],
    );
  }
}

class _SongShelf extends StatelessWidget {
  const _SongShelf({
    required this.queueKey,
    required this.title,
    required this.songs,
  });

  final String queueKey;
  final String title;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final currentId = context.select<MusicBloc, String?>(
      (b) => b.state.myPlayerState.currentSongId,
    );
    return HorizontalShelf(
      height: 186.h,
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        return OnlineMediaCard(
          width: 132.w,
          title: song.title,
          subtitle: song.artists.first,
          imageUrl: song.albumArt,
          icon: CupertinoIcons.music_note,
          isActive: currentId == song.id,
          onTap: () => playOnlineList(
            context,
            queueKey: queueKey,
            title: title,
            songs: songs,
            startIndex: i,
          ),
        );
      },
    );
  }
}

class _ShelfSkeleton extends StatelessWidget {
  const _ShelfSkeleton({this.circle = false});
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final songs = SkeletonData.songs(4);
    return Skeletonizer(
      effect: discoverShimmer(context),
      child: HorizontalShelf(
        height: circle ? 150.h : 186.h,
        itemCount: songs.length,
        itemBuilder: (_, i) => OnlineMediaCard(
          width: circle ? 100.w : 132.w,
          circle: circle,
          title: songs[i].title,
          subtitle: songs[i].artists.first,
          imageUrl: null,
          icon: CupertinoIcons.music_note,
          onTap: () {},
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: discoverShimmer(context),
      child: Skeleton.leaf(
        child: Container(
          height: 190.h,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(22.r),
          ),
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: discoverShimmer(context),
      child: RankedChart(
        queueKey: 'skeleton',
        title: '',
        songs: SkeletonData.songs(8),
      ),
    );
  }
}

/// Full-page skeleton with the same rhythm as the real Discover home.
class DiscoverHomeSkeleton extends StatelessWidget {
  const DiscoverHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: discoverShimmer(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnlineSectionHeader(title: 'Featured for you', subtitle: 'Loading'),
          const _HeroSkeleton(),
          SizedBox(height: 22.h),
          for (final circle in [false, true, false]) ...[
            const OnlineSectionHeader(title: 'Loading section', subtitle: 'Finding great music'),
            _ShelfSkeleton(circle: circle),
            SizedBox(height: 22.h),
          ],
        ],
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: context.onSurfaceColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.gear_alt, color: context.primaryStart, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            'Discover is not configured in this build',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Run with --dart-define-from-file=config/jamendo.json',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
