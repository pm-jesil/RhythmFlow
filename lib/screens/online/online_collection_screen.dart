import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/album/album_model.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/models/playlist_source/playlist_source_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/jamendo/jamendo_api_client.dart';
import '../../utils/services/jamendo/jamendo_models.dart';
import '../../utils/services/jamendo/jamendo_repository.dart';
import '../../utils/services/jamendo/online_song_registry.dart';
import '../playlist_detail_screen/playlist_detail_screen.dart';
import 'widgets/online_widgets.dart';

/// Loaded content of an online album / artist / mix page.
class OnlineCollection {
  final String name;
  final List<Song> songs;
  final String? coverImage;
  final String? description;
  const OnlineCollection({
    required this.name,
    required this.songs,
    this.coverImage,
    this.description,
  });
}

/// Fetches an online collection (skeleton while loading, retry on error)
/// and shows it with the regular [PlaylistDetailScreen].
class OnlineCollectionScreen extends StatefulWidget {
  const OnlineCollectionScreen({
    super.key,
    required this.queueKey,
    required this.title,
    required this.type,
    required this.load,
    this.coverImage,
  });

  final String queueKey;
  final String title;
  final PlaylistDetailType type;
  final String? coverImage;
  final Future<OnlineCollection> Function() load;

  @override
  State<OnlineCollectionScreen> createState() => _OnlineCollectionScreenState();
}

class _OnlineCollectionScreenState extends State<OnlineCollectionScreen> {
  late Future<OnlineCollection> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnlineCollection>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final c = snapshot.data!;
          OnlineQueues.register(widget.queueKey, c.name, c.songs);
          return PlaylistDetailScreen(
            type: widget.type,
            id: widget.queueKey,
            name: c.name,
            description: c.description,
            songCount: c.songs.length,
            songs: c.songs,
            coverImage: c.coverImage ?? widget.coverImage,
            playlistSource: PlaylistSource.online(widget.queueKey),
          );
        }
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: context.backgroundGradient),
            child: SafeArea(
              child: snapshot.hasError
                  ? Column(
                      children: [
                        _BackBar(title: widget.title),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: InlineRetry(
                            message: friendlyError(
                              snapshot.error is JamendoException
                                  ? (snapshot.error as JamendoException).kind
                                  : snapshot.error,
                            ),
                            onRetry: () => setState(() => _future = widget.load()),
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    )
                  : _CollectionSkeleton(title: widget.title, cover: widget.coverImage),
            ),
          ),
        );
      },
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(CupertinoIcons.back, color: context.onSurfaceColor),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

/// Same layout as the detail screen (cover, title, rows) as shimmer bones.
class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton({required this.title, this.cover});
  final String title;
  final String? cover;

  @override
  Widget build(BuildContext context) {
    final songs = SkeletonData.songs(8);
    return Column(
      children: [
        _BackBar(title: title),
        Expanded(
          child: Skeletonizer(
            effect: discoverShimmer(context),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SizedBox(height: 8.h),
                Center(
                  child: Skeleton.leaf(
                    child: Container(
                      width: 180.r,
                      height: 180.r,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(height: 4.h),
                const Center(child: Text('12 songs · Artist name')),
                SizedBox(height: 16.h),
                for (final s in songs) OnlineSongTile(song: s, onTap: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== NAVIGATION ====================

JamendoRepository get _repo => getIt<JamendoRepository>();

void openOnlineAlbum(BuildContext context, Album album) {
  final id = album.remoteId ?? album.id;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnlineCollectionScreen(
        queueKey: 'album_$id',
        title: album.name,
        type: PlaylistDetailType.album,
        coverImage: album.coverImage,
        load: () async {
          final result = await _repo.albumWithTracks(id);
          if (result == null) {
            throw const JamendoException(JamendoErrorKind.api, 'Album not found');
          }
          return OnlineCollection(
            name: result.$1.name,
            songs: result.$2,
            coverImage: result.$1.coverImage,
            description: result.$1.artistName,
          );
        },
      ),
    ),
  );
}

void openOnlineArtist(BuildContext context, Artist artist) {
  final id = artist.remoteId ?? artist.id;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnlineCollectionScreen(
        queueKey: 'artist_$id',
        title: artist.name,
        type: PlaylistDetailType.artist,
        coverImage: artist.image,
        load: () async {
          final result = await _repo.artistWithTracks(id);
          if (result == null) {
            throw const JamendoException(JamendoErrorKind.api, 'Artist not found');
          }
          final songs = result.$2;
          return OnlineCollection(
            name: result.$1.name,
            songs: songs,
            coverImage: result.$1.image ?? (songs.isEmpty ? null : songs.first.albumArt),
            description: 'Artist on Jamendo',
          );
        },
      ),
    ),
  );
}

void openOnlineMix(BuildContext context, JamendoMix mix) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnlineCollectionScreen(
        queueKey: mix.id,
        title: mix.title,
        type: PlaylistDetailType.playlist,
        load: () async {
          final songs = await _repo.mixTracks(mix.tag, limit: 50);
          return OnlineCollection(
            name: mix.title,
            songs: songs,
            coverImage: songs.isEmpty ? null : songs.first.albumArt,
            description: mix.subtitle,
          );
        },
      ),
    ),
  );
}

/// Opens a fixed list of songs (e.g. a Discover section's "See all").
void openOnlineSongList(
  BuildContext context, {
  required String queueKey,
  required String title,
  required List<Song> songs,
  String? description,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnlineCollectionScreen(
        queueKey: queueKey,
        title: title,
        type: PlaylistDetailType.playlist,
        load: () async => OnlineCollection(
          name: title,
          songs: songs,
          coverImage: songs.isEmpty ? null : songs.first.albumArt,
          description: description,
        ),
      ),
    ),
  );
}
