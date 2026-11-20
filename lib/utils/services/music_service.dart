import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../utils/models/song/song_model.dart';
import '../../utils/models/album/album_model.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/logger/logger.dart';

class MusicService {
  static final AppLogger _logger = AppLogger('MusicService');

  /// Builds the album list from [songs].
  ///
  /// The result always reflects [songs] exactly: albums without songs are
  /// dropped and song IDs that no longer exist are removed. When
  /// [existingAlbums] is given, user/extra data of albums with the same ID
  /// (cover image, creation date, play count, ...) is preserved.
  ///
  /// Albums are grouped by album name **and** album artist (or, when the
  /// album-artist tag is missing, by the folder the files live in), so that
  /// two different "Greatest Hits" albums are no longer merged, while a movie
  /// soundtrack with many singers in one folder stays one album.
  static List<Album> fetchAlbumList(
    List<Song> songs, [
    List<Album>? existingAlbums,
  ]) {
    _logger.i('Building album list from ${songs.length} songs');
    if (songs.isEmpty) return const [];

    try {
      final existingById = {
        for (final album in existingAlbums ?? const <Album>[]) album.id: album,
      };

      final albums = <Album>[];
      for (final group in _groupSongsByAlbum(songs).values) {
        final albumId = albumIdForSong(group.first);
        final songIds = group.map((s) => s.id).toList();
        final existing = existingById[albumId];
        if (existing != null) {
          final changed = !_sameIds(existing.songIds, songIds);
          albums.add(
            existing.copyWith(
              name: albumNameForSong(group.first),
              songIds: songIds,
              description: 'Album with ${songIds.length} songs',
              updatedAt: changed ? DateTime.now() : existing.updatedAt,
            ),
          );
        } else {
          albums.add(_createNewAlbum(albumId, group));
        }
      }

      _logger.i('Processed ${albums.length} albums from ${songs.length} songs');
      return albums;
    } catch (e) {
      _logger.e('Error processing albums', error: e);
      return existingAlbums ?? const [];
    }
  }

  /// Builds the artist list from [songs] (grouped case-insensitively by the
  /// primary artist). Same preservation rules as [fetchAlbumList].
  static List<Artist> fetchArtistList(
    List<Song> songs, [
    List<Artist>? existingArtists,
  ]) {
    _logger.i('Building artist list from ${songs.length} songs');
    if (songs.isEmpty) return const [];

    try {
      final existingById = {
        for (final artist in existingArtists ?? const <Artist>[])
          artist.id: artist,
      };

      final artists = <Artist>[];
      for (final group in _groupSongsByArtist(songs).values) {
        final artistName = _getCleanName(group.first.primaryArtist, 'Unknown Artist');
        final artistId = artistIdForName(artistName);
        final songIds = group.map((s) => s.id).toList();
        final existing = existingById[artistId];
        if (existing != null) {
          final changed = !_sameIds(existing.songIds, songIds);
          artists.add(
            existing.copyWith(
              name: artistName,
              songIds: songIds,
              updatedAt: changed ? DateTime.now() : existing.updatedAt,
            ),
          );
        } else {
          artists.add(_createNewArtist(artistId, artistName, group));
        }
      }

      _logger.i('Processed ${artists.length} artists from ${songs.length} songs');
      return artists;
    } catch (e) {
      _logger.e('Error processing artists', error: e);
      return existingArtists ?? const [];
    }
  }

  // ==================== GROUPING KEYS & IDS ====================

  static const String unknownAlbum = 'Unknown Album';
  static const String unknownArtist = 'Unknown Artist';

  /// Display name of the album a song belongs to.
  static String albumNameForSong(Song song) =>
      _getCleanName(song.primaryAlbum.trim(), unknownAlbum);

  /// Grouping key of the album a song belongs to.
  static String albumKeyForSong(Song song) {
    final name = albumNameForSong(song);
    final normalizedName = _normalize(name);
    if (normalizedName == _normalize(unknownAlbum)) return normalizedName;

    final albumArtist = song.albumArtist?.trim() ?? '';
    final owner = albumArtist.isNotEmpty
        ? 'artist:${_normalize(albumArtist)}'
        : 'folder:${_parentFolder(song.path)}';
    return '$normalizedName|$owner';
  }

  /// Stable album ID (does not depend on Dart's String.hashCode).
  static String albumIdForSong(Song song) =>
      'album_${_stableHash(albumKeyForSong(song))}';

  /// Stable artist ID for an artist name (case-insensitive).
  static String artistIdForName(String artistName) =>
      'artist_${_stableHash(_normalize(_getCleanName(artistName, unknownArtist)))}';

  static String _stableHash(String input) =>
      sha1.convert(utf8.encode(input)).toString().substring(0, 16);

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _parentFolder(String path) {
    final index = path.lastIndexOf('/');
    return index > 0 ? path.substring(0, index) : '';
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Album helper methods
  static Map<String, List<Song>> _groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> groups = {};
    for (final song in songs) {
      groups.putIfAbsent(albumKeyForSong(song), () => []).add(song);
    }
    return groups;
  }

  static Album _createNewAlbum(String albumId, List<Song> songs) {
    final first = songs.first;
    final albumArtist = first.albumArtist?.trim() ?? '';
    final artistName = albumArtist.isNotEmpty
        ? albumArtist
        : _mostCommonArtist(songs);
    final year = songs
        .map((s) => s.year)
        .firstWhere((y) => y != null, orElse: () => null);
    final now = DateTime.now();

    return Album(
      id: albumId,
      name: albumNameForSong(first),
      description: 'Album with ${songs.length} songs',
      songIds: songs.map((song) => song.id).toList(),
      coverImage: null,
      createdAt: now,
      updatedAt: now,
      artistId: artistIdForName(artistName),
      genre: null,
      year: year,
    );
  }

  static String _mostCommonArtist(List<Song> songs) {
    final counts = <String, int>{};
    for (final song in songs) {
      final name = _getCleanName(song.primaryArtist, unknownArtist);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  // Artist helper methods
  static Map<String, List<Song>> _groupSongsByArtist(List<Song> songs) {
    final Map<String, List<Song>> groups = {};
    for (final song in songs) {
      final artistName = _getCleanName(song.primaryArtist, unknownArtist);
      groups.putIfAbsent(_normalize(artistName), () => []).add(song);
    }
    return groups;
  }

  static Artist _createNewArtist(
    String artistId,
    String artistName,
    List<Song> songs,
  ) {
    final albumKeys = songs.map(albumKeyForSong).toSet();
    final now = DateTime.now();
    return Artist(
      id: artistId,
      name: artistName,
      bio: 'Artist with ${songs.length} songs across ${albumKeys.length} albums',
      image: null,
      songIds: songs.map((song) => song.id).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generic method to get clean names (reduces duplication)
  static String _getCleanName(String name, String defaultValue) {
    return name.isNotEmpty ? name : defaultValue;
  }

  /// Get unique album names and their counts from all songs
  static Map<String, int> getUniqueAlbums(List<Song> songs) {
    final Map<String, int> albumCounts = {};

    for (final song in songs) {
      for (final album in song.albums) {
        final cleanAlbum = _getCleanName(album, 'Unknown Album');
        albumCounts[cleanAlbum] = (albumCounts[cleanAlbum] ?? 0) + 1;
      }
    }

    _logger.i(
      'Found ${albumCounts.length} unique albums across ${songs.length} songs',
    );
    return albumCounts;
  }

  /// Get unique artist names and their counts from all songs
  static Map<String, int> getUniqueArtists(List<Song> songs) {
    final Map<String, int> artistCounts = {};

    for (final song in songs) {
      for (final artist in song.artists) {
        final cleanArtist = _getCleanName(artist, 'Unknown Artist');
        artistCounts[cleanArtist] = (artistCounts[cleanArtist] ?? 0) + 1;
      }
    }

    _logger.i(
      'Found ${artistCounts.length} unique artists across ${songs.length} songs',
    );
    return artistCounts;
  }

  /// Get album statistics for display
  static Map<String, dynamic> getAlbumStatistics(List<Song> songs) {
    final albumCounts = getUniqueAlbums(songs);
    final totalAlbums = albumCounts.length;
    final totalSongs = songs.length;

    // Get albums with most songs
    final sortedAlbums = albumCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topAlbums = sortedAlbums
        .take(5)
        .map((entry) => {'name': entry.key, 'songCount': entry.value})
        .toList();

    return {
      'totalAlbums': totalAlbums,
      'totalSongs': totalSongs,
      'topAlbums': topAlbums,
      'allAlbums': albumCounts,
    };
  }

  /// Get artist statistics for display
  static Map<String, dynamic> getArtistStatistics(List<Song> songs) {
    final artistCounts = getUniqueArtists(songs);
    final totalArtists = artistCounts.length;
    final totalSongs = songs.length;

    // Get artists with most songs
    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topArtists = sortedArtists
        .take(5)
        .map((entry) => {'name': entry.key, 'songCount': entry.value})
        .toList();

    return {
      'totalArtists': totalArtists,
      'totalSongs': totalSongs,
      'topArtists': topArtists,
      'allArtists': artistCounts,
    };
  }

  /// Get songs by specific album
  static List<Song> getSongsByAlbum(List<Song> songs, String albumName) {
    return songs
        .where(
          (song) => song.albums.any(
            (album) => _getCleanName(album, 'Unknown Album') == albumName,
          ),
        )
        .toList();
  }

  /// Get songs by specific artist
  static List<Song> getSongsByArtist(List<Song> songs, String artistName) {
    return songs
        .where(
          (song) => song.artists.any(
            (artist) => _getCleanName(artist, 'Unknown Artist') == artistName,
          ),
        )
        .toList();
  }
}
