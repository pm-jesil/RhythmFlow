import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/jamendo_models.dart';
import '../../../utils/services/jamendo/taste_models.dart';
import '../../bottom_tab/bloc/music_bloc.dart';
import '../online_collection_screen.dart';
import 'online_widgets.dart';
import 'taste_picker.dart';

/// Big swipeable "Featured for you" cards.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.songs,
    required this.queueKey,
    required this.title,
  });

  final List<Song> songs;
  final String queueKey;
  final String title;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    return Column(
      children: [
        SizedBox(
          height: 190.h,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: songs.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _HeroCard(
                song: songs[i],
                onTap: () => playOnlineList(
                  context,
                  queueKey: widget.queueKey,
                  title: widget.title,
                  songs: songs,
                  startIndex: i,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < songs.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: i == _page ? 18.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: i == _page ? context.primaryGradient : null,
                  color: i == _page ? null : context.onSurfaceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<MusicBloc, bool>(
      (b) => b.state.myPlayerState.currentSongId == song.id,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: context.primaryStart.withValues(alpha: 0.28),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OnlineArtwork(url: song.albumArt, icon: CupertinoIcons.music_note, radius: 0),
              // Legibility scrim.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                top: 14.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: context.primaryGradient,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    isCurrent ? 'NOW PLAYING' : 'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                right: 70.w,
                bottom: 16.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      song.artists.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16.w,
                bottom: 16.h,
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
                  child: Icon(
                    isCurrent ? CupertinoIcons.waveform : CupertinoIcons.play_fill,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ranked "Top 10" chart, paged in columns of [rowsPerColumn].
class RankedChart extends StatelessWidget {
  const RankedChart({
    super.key,
    required this.songs,
    required this.queueKey,
    required this.title,
    this.rowsPerColumn = 4,
  });

  final List<Song> songs;
  final String queueKey;
  final String title;
  final int rowsPerColumn;

  @override
  Widget build(BuildContext context) {
    final columns = (songs.length / rowsPerColumn).ceil();
    final rowHeight = 58.h;
    return SizedBox(
      height: rowHeight * rowsPerColumn,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, c) => SizedBox(
          width: 280.w,
          child: Column(
            children: [
              for (var r = 0; r < rowsPerColumn; r++)
                if (c * rowsPerColumn + r < songs.length)
                  SizedBox(
                    height: rowHeight,
                    child: _ChartRow(
                      rank: c * rowsPerColumn + r + 1,
                      song: songs[c * rowsPerColumn + r],
                      onTap: () => playOnlineList(
                        context,
                        queueKey: queueKey,
                        title: title,
                        songs: songs,
                        startIndex: c * rowsPerColumn + r,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartRow extends StatelessWidget {
  const _ChartRow({required this.rank, required this.song, required this.onTap});
  final int rank;
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<MusicBloc, bool>(
      (b) => b.state.myPlayerState.currentSongId == song.id,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: ShaderMask(
              shaderCallback: (r) => context.primaryGradient.createShader(r),
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 46.r,
            height: 46.r,
            child: OnlineArtwork(url: song.albumArt, icon: CupertinoIcons.music_note, radius: 10.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? context.primaryStart : context.onSurfaceColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  song.artists.first,
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
          if (isCurrent)
            Icon(CupertinoIcons.waveform, color: context.primaryStart, size: 18.sp),
        ],
      ),
    );
  }
}

/// 2-column compact tiles for quick access ("Jump back in").
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, required this.songs, required this.queueKey, required this.title});

  final List<Song> songs;
  final String queueKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    final items = songs.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        mainAxisExtent: 52.h,
      ),
      itemBuilder: (context, i) => _QuickTile(
        song: items[i],
        onTap: () => playOnlineList(
          context,
          queueKey: queueKey,
          title: title,
          songs: songs,
          startIndex: i,
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<MusicBloc, bool>(
      (b) => b.state.myPlayerState.currentSongId == song.id,
    );
    return Material(
      color: isCurrent
          ? context.primaryStart.withValues(alpha: 0.14)
          : context.onSurfaceColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: OnlineArtwork(url: song.albumArt, icon: CupertinoIcons.music_note, radius: 0),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCurrent ? context.primaryStart : context.onSurfaceColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ),
      ),
    );
  }
}

/// Row of the user's tastes; each opens "Your (taste) Mix".
class VibeChipsRow extends StatelessWidget {
  const VibeChipsRow({super.key, required this.tastes, required this.onEdit});

  final List<String> tastes;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final picked = tastes.map(MusicTastes.byId).whereType<MusicTaste>().toList();
    return SizedBox(
      height: 34.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final t in picked)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: TasteChip(
                taste: t,
                selected: false,
                compact: true,
                onTap: () => openOnlineMix(
                  context,
                  JamendoMix(
                    id: 'mix_${t.id}',
                    title: 'Your ${t.label} Mix',
                    subtitle: '${t.emoji} Made for you',
                    tag: t.id,
                    featured: false,
                  ),
                ),
              ),
            ),
          ActionChip(
            key: const ValueKey('vibes_edit'),
            onPressed: onEdit,
            avatar: Icon(CupertinoIcons.add, size: 14.sp, color: context.primaryStart),
            label: Text(
              'Vibes',
              style: TextStyle(fontSize: 11.sp, fontFamily: 'Poppins', color: context.onSurfaceColor),
            ),
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
            side: BorderSide(color: context.primaryStart.withValues(alpha: 0.3)),
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
