import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/app_custom.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/download_service.dart';
import '../../../utils/services/jamendo/jamendo_models.dart';
import '../../../utils/services/jamendo/online_song_registry.dart';
import '../../bottom_tab/bloc/music_bloc.dart';
import '../../widgets/art_image.dart';
import '../../widgets/custom_3d_card.dart';
import '../bloc/online_library_bloc.dart';
import '../../ringtones/ringtone_actions.dart' show openRingtoneEditor;

// ==================== PLAYBACK ====================

/// Plays [songs] (a Discover list) starting at [startIndex]. The list is
/// registered so the queue, shuffle-revert and "playing from" label work.
void playOnlineList(
  BuildContext context, {
  required String queueKey,
  required String title,
  required List<Song> songs,
  int startIndex = 0,
}) {
  if (songs.isEmpty) return;
  HapticFeedback.selectionClick();
  OnlineQueues.register(queueKey, title, songs);
  final index = startIndex.clamp(0, songs.length - 1);
  context.read<MusicBloc>().add(
    MusicEvent.playOrPauseSong(
      songId: songs[index].id,
      currentPlayList: songs.map((s) => s.id).toList(),
      playlistSource: PlaylistSource.online(queueKey),
    ),
  );
}

/// Plays a live radio station.
void playRadio(BuildContext context, JamendoRadio radio) {
  playOnlineList(
    context,
    queueKey: 'radio_${radio.id}',
    title: radio.displayName,
    songs: [radio.toSong()],
  );
}

// ==================== SKELETON ====================

/// Shimmer used by every Discover loading skeleton.
ShimmerEffect discoverShimmer(BuildContext context) => ShimmerEffect(
  baseColor: context.onSurfaceColor.withValues(alpha: context.isDark ? 0.10 : 0.07),
  highlightColor: context.onSurfaceColor.withValues(alpha: context.isDark ? 0.20 : 0.15),
  duration: const Duration(milliseconds: 1400),
);

/// Placeholder data with realistic lengths, rendered as bones while loading
/// so the skeleton has exactly the shape of the real screen.
class SkeletonData {
  SkeletonData._();

  static List<Song> songs([int count = 8]) => [
    for (var i = 0; i < count; i++)
      Song(
        id: 'skeleton_$i',
        title: i.isEven ? 'Loading a great song' : 'Another fine track',
        artists: const ['Artist name'],
        albums: const ['Album title'],
        path: '',
        duration: const Duration(minutes: 3, seconds: 24),
        source: SongSources.jamendo,
      ),
  ];

  static List<Album> albums([int count = 8]) => [
    for (var i = 0; i < count; i++)
      Album(
        id: 'skeleton_album_$i',
        name: 'Album title',
        songIds: const [],
        createdAt: DateTime(2024),
        artistName: 'Artist name',
        source: SongSources.jamendo,
      ),
  ];

  static List<Artist> artists([int count = 8]) => [
    for (var i = 0; i < count; i++)
      Artist(
        id: 'skeleton_artist_$i',
        name: 'Artist name',
        songIds: const [],
        createdAt: DateTime(2024),
        source: SongSources.jamendo,
      ),
  ];
}

// ==================== ARTWORK ====================

class OnlineArtwork extends StatelessWidget {
  const OnlineArtwork({
    super.key,
    required this.url,
    required this.icon,
    this.radius,
    this.circle = false,
  });

  final String? url;
  final IconData icon;
  final double? radius;
  final bool circle;

  Widget _fallback(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: context.primaryGradient),
    child: Center(
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28.sp),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final image = (url == null || url!.isEmpty)
        ? _fallback(context)
        : ArtImage(path: url!, fallback: _fallback);
    if (circle) return ClipOval(child: image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 14.r),
      child: image,
    );
  }
}

// ==================== SECTION HEADER ====================

class OnlineSectionHeader extends StatelessWidget {
  const OnlineSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 11.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: context.primaryStart,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, size: 14.sp),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== CARDS ====================

/// Square artwork card with title + subtitle (songs, albums, mixes, radio).
class OnlineMediaCard extends StatelessWidget {
  const OnlineMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.onTap,
    this.width,
    this.isActive = false,
    this.circle = false,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;
  final bool isActive;
  final bool circle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 132.w;
    return SizedBox(
      width: w,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // In fixed-height shelves / grid cells the artwork takes the space
            // left by the two text lines, so the card can never overflow.
            final bounded = constraints.hasBoundedHeight;
            final art = _artwork(context, w);
            return Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: circle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (bounded)
                  Flexible(
                    child: Align(
                      alignment: circle ? Alignment.topCenter : Alignment.topLeft,
                      child: AspectRatio(aspectRatio: 1, child: art),
                    ),
                  )
                else
                  SizedBox(width: w, height: w, child: art),
                SizedBox(height: 8.h),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: circle ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: isActive ? context.primaryStart : context.onSurfaceColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: circle ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 11.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _artwork(BuildContext context, double w) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: (isActive ? context.primaryStart : Colors.black)
                    .withValues(alpha: isActive ? 0.45 : 0.15),
                blurRadius: isActive ? 14.r : 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: OnlineArtwork(url: imageUrl, icon: icon, radius: 16.r, circle: circle),
        ),
        if (isActive) Positioned(right: 8.w, bottom: 8.h, child: _NowPlayingDot()),
        if (badge != null)
          Positioned(
            left: 8.w,
            top: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Radio station card that highlights itself while playing.
class RadioCard extends StatelessWidget {
  const RadioCard({super.key, required this.radio, this.width, this.loading = false});

  final JamendoRadio radio;
  final double? width;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final playing = !loading &&
        context.select<MusicBloc, bool>(
          (b) => b.state.myPlayerState.currentSongId == JamendoMapper.radioSongId(radio.id),
        );
    return OnlineMediaCard(
      width: width,
      title: radio.displayName.replaceAll(' Radio', ''),
      subtitle: 'Live radio',
      imageUrl: loading || radio.image.isEmpty ? null : radio.image,
      icon: CupertinoIcons.antenna_radiowaves_left_right,
      badge: loading ? null : 'LIVE',
      isActive: playing,
      onTap: loading ? () {} : () => playRadio(context, radio),
    );
  }
}

class _NowPlayingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(CupertinoIcons.waveform, color: Colors.white, size: 14.sp),
    );
  }
}

/// Gradient tile for a curated mix.
class OnlineMixCard extends StatelessWidget {
  const OnlineMixCard({super.key, required this.mix, required this.onTap, this.width});

  final JamendoMix mix;
  final VoidCallback onTap;
  final double? width;

  static const Map<String, IconData> _icons = {
    'pop': CupertinoIcons.star_fill,
    'rock': CupertinoIcons.bolt_fill,
    'electronic': CupertinoIcons.waveform_path,
    'hiphop': CupertinoIcons.mic_fill,
    'jazz': CupertinoIcons.music_note_2,
    'lounge': CupertinoIcons.moon_stars_fill,
    'classical': CupertinoIcons.music_note_list,
    'relaxation': CupertinoIcons.leaf_arrow_circlepath,
    'songwriter': CupertinoIcons.pencil,
    'world': CupertinoIcons.globe,
    'metal': CupertinoIcons.flame_fill,
    'soundtrack': CupertinoIcons.film_fill,
  };

  @override
  Widget build(BuildContext context) {
    final w = width ?? 132.w;
    final hue = (mix.tag.hashCode % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, hue, 0.55, context.isDark ? 0.38 : 0.55).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, context.isDark ? 0.28 : 0.45).toColor();
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: w,
        child: Custom3DCard(
          height: w * 0.62,
          padding: EdgeInsets.all(12.r),
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(_icons[mix.tag] ?? CupertinoIcons.music_note, color: Colors.white, size: 20.sp),
              Text(
                mix.title,
                maxLines: 2,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SONG ROW ====================

/// List row for an online song: artwork, title, artist, like, download
/// (when the artist allows it) and a menu (share / open / licence).
class OnlineSongTile extends StatelessWidget {
  const OnlineSongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
  });

  final Song song;
  final VoidCallback onTap;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<MusicBloc, bool>(
      (b) => b.state.myPlayerState.currentSongId == song.id,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: isCurrent ? context.primaryStart.withValues(alpha: 0.10) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48.r,
                height: 48.r,
                child: OnlineArtwork(
                  url: song.albumArt,
                  icon: CupertinoIcons.music_note,
                  radius: 10.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? context.primaryStart : context.onSurfaceColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      [
                        song.artists.first,
                        if (song.duration > Duration.zero) song.formattedDuration,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              if (!song.id.startsWith('skeleton_')) ...[
                LikeButton(song: song),
                if (song.canDownload) DownloadButton(song: song),
                _SongMenu(song: song),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.song, this.size});
  final Song song;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final liked = context.select<OnlineLibraryBloc, bool>((b) => b.state.isLiked(song.id));
    return IconButton(
      tooltip: liked ? 'Remove from liked songs' : 'Like',
      visualDensity: VisualDensity.compact,
      onPressed: () {
        HapticFeedback.lightImpact();
        context.read<OnlineLibraryBloc>().add(OnlineLibraryEvent.toggleLike(song));
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          key: ValueKey(liked),
          size: size ?? 20.sp,
          color: liked ? context.primaryStart : context.onSurfaceVariantColor,
        ),
      ),
    );
  }
}

class DownloadButton extends StatelessWidget {
  const DownloadButton({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    final download = context.select<OnlineLibraryBloc, OnlineDownload?>(
      (b) => b.state.downloadOf(song.id),
    );
    final phase = download?.phase;
    if (phase == DownloadPhase.queued || phase == DownloadPhase.downloading) {
      return Padding(
        padding: EdgeInsets.all(10.r),
        child: SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            value: phase == DownloadPhase.queued ? null : download!.progress,
            color: context.primaryStart,
            backgroundColor: context.onSurfaceColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }
    final done = phase == DownloadPhase.completed;
    return IconButton(
      tooltip: done ? 'Saved to My Music' : 'Download to My Music',
      visualDensity: VisualDensity.compact,
      onPressed: done ? null : () => startDownload(context, song),
      icon: Icon(
        done ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.arrow_down_circle,
        size: 20.sp,
        color: done ? context.primaryStart : context.onSurfaceVariantColor,
      ),
    );
  }
}

Future<void> startDownload(BuildContext context, Song song) async {
  if (!getIt.isRegistered<DownloadService>()) return;
  HapticFeedback.lightImpact();
  AppCustom.info(context, 'Downloading "${song.title}"…');
  final path = await getIt<DownloadService>().download(song);
  if (!context.mounted) return;
  if (path != null) {
    AppCustom.success(context, 'Saved to My Music');
  } else {
    final error = context.read<OnlineLibraryBloc>().state.downloadOf(song.id)?.error;
    AppCustom.error(context, error ?? 'Download failed');
  }
}

class _SongMenu extends StatelessWidget {
  const _SongMenu({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(CupertinoIcons.ellipsis_vertical, size: 18.sp, color: context.onSurfaceVariantColor),
      onSelected: (value) async {
        switch (value) {
          case 'share':
            if (song.shareUrl != null) {
              await Share.share(
                '${song.title} by ${song.artists.first}\n${song.shareUrl}',
              );
            }
          case 'open':
            if (song.shareUrl != null) {
              await launchUrl(Uri.parse(song.shareUrl!), mode: LaunchMode.externalApplication);
            }
          case 'license':
            if (song.licenseUrl != null) {
              await launchUrl(Uri.parse(song.licenseUrl!), mode: LaunchMode.externalApplication);
            }
          case 'download':
            if (context.mounted) await startDownload(context, song);
          case 'ringtone':
            if (context.mounted) await openRingtoneEditor(context, song);
        }
      },
      itemBuilder: (_) => [
        if (song.canDownload)
          const PopupMenuItem(value: 'download', child: Text('Download to My Music')),
        if (song.canDownload)
          const PopupMenuItem(value: 'ringtone', child: Text('Make ringtone')),
        if (song.shareUrl != null) const PopupMenuItem(value: 'share', child: Text('Share')),
        if (song.shareUrl != null) const PopupMenuItem(value: 'open', child: Text('Open on Jamendo')),
        if (song.licenseUrl != null)
          const PopupMenuItem(value: 'license', child: Text('Creative Commons licence')),
      ],
    );
  }
}

// ==================== STATES ====================

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onSwitchToLocal});
  final VoidCallback? onSwitchToLocal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.wifi_slash, color: Colors.orange, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "You're offline · showing saved results",
              style: TextStyle(color: context.onSurfaceColor, fontSize: 12.sp, fontFamily: 'Poppins'),
            ),
          ),
          if (onSwitchToLocal != null)
            TextButton(
              onPressed: onSwitchToLocal,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text('My Music', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class InlineRetry extends StatelessWidget {
  const InlineRetry({super.key, required this.message, required this.onRetry, this.height});
  final String message;
  final VoidCallback onRetry;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.onSurfaceColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, color: context.onSurfaceVariantColor, size: 22.sp),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 4.h),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(CupertinoIcons.arrow_clockwise, size: 16.sp),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

String friendlyError(Object? kind) {
  final name = kind.toString();
  if (name.contains('offline')) return 'No internet connection';
  if (name.contains('timeout')) return 'Jamendo is taking too long to answer';
  if (name.contains('notConfigured')) return 'Discover is not configured in this build';
  return "Couldn't load this right now";
}

class JamendoAttribution extends StatelessWidget {
  const JamendoAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://www.jamendo.com'), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.music_note_2, size: 12.sp, color: context.onSurfaceVariantColor),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                'Music powered by Jamendo · Creative Commons',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal list used by Discover sections.
class HorizontalShelf extends StatelessWidget {
  const HorizontalShelf({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height,
    this.spacing,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double? height;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 186.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(width: spacing ?? 14.w),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
