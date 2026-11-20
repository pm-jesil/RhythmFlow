import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../utils/logger/logger.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/online_song_registry.dart';

part 'online_library_event.dart';
part 'online_library_state.dart';
part 'online_library_bloc.freezed.dart';

/// The user's own online collection: liked songs, history, followed
/// artists, saved albums and downloads. Persisted with HydratedBloc.
class OnlineLibraryBloc
    extends HydratedBloc<OnlineLibraryEvent, OnlineLibraryState> {
  static final AppLogger _logger = AppLogger('OnlineLibraryBloc');

  static const int maxHistory = 50;
  static const int maxLiked = 1000;

  OnlineLibraryBloc() : super(const OnlineLibraryState()) {
    on<_ToggleLike>((event, emit) {
      final song = event.song;
      if (!song.isOnline) return;
      final liked = state.isLiked(song.id)
          ? state.likedSongs.where((s) => s.id != song.id).toList()
          : [song, ...state.likedSongs].take(maxLiked).toList();
      OnlineSongRegistry.register([song]);
      emit(state.copyWith(likedSongs: liked));
    });
    on<_RecordPlay>((event, emit) {
      final song = event.song;
      if (!song.isOnline) return;
      final history = [
        song,
        ...state.recentlyPlayed.where((s) => s.id != song.id),
      ].take(maxHistory).toList();
      emit(state.copyWith(recentlyPlayed: history));
    });
    on<_ClearHistory>(
      (event, emit) => emit(state.copyWith(recentlyPlayed: const [])),
    );
    on<_ToggleFollowArtist>((event, emit) {
      final artist = event.artist;
      emit(
        state.copyWith(
          followedArtists: state.isFollowing(artist.id)
              ? state.followedArtists.where((a) => a.id != artist.id).toList()
              : [artist.copyWith(songIds: const []), ...state.followedArtists],
        ),
      );
    });
    on<_ToggleSaveAlbum>((event, emit) {
      final album = event.album;
      emit(
        state.copyWith(
          savedAlbums: state.isSaved(album.id)
              ? state.savedAlbums.where((a) => a.id != album.id).toList()
              : [album, ...state.savedAlbums],
        ),
      );
    });
    on<_DownloadUpdated>((event, emit) {
      emit(
        state.copyWith(
          downloads: {...state.downloads, event.songId: event.download},
        ),
      );
    });
    on<_DownloadDismissed>((event, emit) {
      emit(
        state.copyWith(
          downloads: Map.of(state.downloads)..remove(event.songId),
        ),
      );
    });

    OnlineSongRegistry.register([...state.likedSongs, ...state.recentlyPlayed]);
  }

  @override
  String get storagePrefix => 'OnlineLibraryBloc';

  @override
  Map<String, dynamic>? toJson(OnlineLibraryState state) {
    try {
      return {
        'likedSongs': state.likedSongs.map((s) => s.toJson()).toList(),
        'recentlyPlayed': state.recentlyPlayed.map((s) => s.toJson()).toList(),
        'followedArtists': state.followedArtists.map((a) => a.toJson()).toList(),
        'savedAlbums': state.savedAlbums.map((a) => a.toJson()).toList(),
        'downloads': state.downloads.map((k, v) => MapEntry(k, v.toJson())),
      };
    } catch (_) {
      return null;
    }
  }

  @override
  OnlineLibraryState? fromJson(Map<String, dynamic> json) {
    try {
      List<Map<String, dynamic>> maps(Object? v) => v is List
          ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [];
      final downloads = <String, OnlineDownload>{};
      final rawDownloads = json['downloads'];
      if (rawDownloads is Map) {
        rawDownloads.forEach((key, value) {
          downloads[key as String] = OnlineDownload.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
        });
      }
      return OnlineLibraryState(
        likedSongs: maps(json['likedSongs']).map(Song.fromJson).toList(),
        recentlyPlayed: maps(json['recentlyPlayed']).map(Song.fromJson).toList(),
        followedArtists: maps(json['followedArtists']).map(Artist.fromJson).toList(),
        savedAlbums: maps(json['savedAlbums']).map(Album.fromJson).toList(),
        downloads: downloads,
      );
    } catch (e) {
      _logger.w('⚠️ Could not restore online library: $e');
      return null;
    }
  }
}
