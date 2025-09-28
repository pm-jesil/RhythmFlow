import '../../utils/models/song/song_model.dart';
import '../../utils/models/album/album_model.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/logger/logger.dart';

class MusicService {
  static final AppLogger _logger = AppLogger('MusicService');

  /// Fetch album list from songs, updating existing albums if provided
  static List<Album> fetchAlbumList(
    List<Song> songs, [
    List<Album>? existingAlbums,
  ]) {
    _logger.i('Fetching album list from ${songs.length} songs');

    if (songs.isEmpty) {
      _logger.w('Songs list is empty, returning existing albums');
      return existingAlbums ?? [];
    }

    try {
      // Create map of existing albums for quick lookup
      final Map<String, Album> albumMap = {};
      if (existingAlbums != null) {
        for (final album in existingAlbums) {
          albumMap[album.id] = album;
        }
      }

      // Group songs by album
      final albumGroups = _groupSongsByAlbum(songs);

      // Process each album group
      for (final entry in albumGroups.entries) {
        final albumName = entry.key;
        final albumSongs = entry.value;
        final albumId = _generateIdFromName(albumName, 'album');

        if (albumMap.containsKey(albumId)) {
          // Update existing album
          albumMap[albumId] = _updateExistingAlbum(
            albumMap[albumId]!,
            albumSongs,
          );
        } else {
          // Create new album
          albumMap[albumId] = _createNewAlbum(albumName, albumSongs);
        }
      }

      final albums = albumMap.values.toList();
      _logger.i('Processed ${albums.length} albums from ${songs.length} songs');
      return albums;
    } catch (e) {
      _logger.e('Error processing albums', error: e);
      return existingAlbums ?? [];
    }
  }

  /// Fetch artist list from songs, updating existing artists if provided
  static List<Artist> fetchArtistList(
    List<Song> songs, [
    List<Artist>? existingArtists,
  ]) {
    _logger.i('Fetching artist list from ${songs.length} songs');

    if (songs.isEmpty) {
      _logger.w('Songs list is empty, returning existing artists');
      return existingArtists ?? [];
    }

    try {
      // Create map of existing artists for quick lookup
      final Map<String, Artist> artistMap = {};
      if (existingArtists != null) {
        for (final artist in existingArtists) {
          artistMap[artist.id] = artist;
        }
      }

      // Group songs by artist
      final artistGroups = _groupSongsByArtist(songs);

      // Process each artist group
      for (final entry in artistGroups.entries) {
        final artistName = entry.key;
        final artistSongs = entry.value;
        final artistId = _generateIdFromName(artistName, 'artist');

        if (artistMap.containsKey(artistId)) {
          // Update existing artist
          artistMap[artistId] = _updateExistingArtist(
            artistMap[artistId]!,
            artistSongs,
          );
        } else {
          // Create new artist
          artistMap[artistId] = _createNewArtist(artistName, artistSongs);
        }
      }

      final artists = artistMap.values.toList();
      _logger.i(
        'Processed ${artists.length} artists from ${songs.length} songs',
      );
      return artists;
    } catch (e) {
      _logger.e('Error processing artists', error: e);
      return existingArtists ?? [];
    }
  }

  // Album helper methods
  static Map<String, List<Song>> _groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> groups = {};
    for (final song in songs) {
      // Use primary album for grouping, but consider all albums
      final albumName = _getCleanName(song.primaryAlbum, 'Unknown Album');
      groups.putIfAbsent(albumName, () => []).add(song);
    }
    return groups;
  }

  static Album _createNewAlbum(String albumName, List<Song> songs) {
    final albumId = _generateIdFromName(albumName, 'album');
    final songIds = songs.map((song) => song.id).toList();
    final artistName = _getCleanName(
      songs.first.primaryArtist,
      'Unknown Artist',
    );

    return Album(
      id: albumId,
      name: albumName,
      description: 'Album with ${songs.length} songs',
      songIds: songIds,
      coverImage: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      artistId: _generateIdFromName(artistName, 'artist'),
      genre: null,
      year: songs.first.year,
    );
  }

  static Album _updateExistingAlbum(Album existingAlbum, List<Song> newSongs) {
    final newSongIds = newSongs.map((song) => song.id).toSet();
    final existingSongIds = existingAlbum.songIds.toSet();

    // Combine existing and new songs (avoiding duplicates)
    final allSongIds = {...existingSongIds, ...newSongIds}.toList();

    final hasNewSongs = !newSongIds.every((id) => existingSongIds.contains(id));

    if (hasNewSongs) {
      _logger.d(
        'Updating album: ${existingAlbum.name} with ${newSongs.length} songs',
      );
      return existingAlbum.copyWith(
        songIds: allSongIds,
        description: 'Album with ${allSongIds.length} songs',
        updatedAt: DateTime.now(),
      );
    }

    return existingAlbum;
  }

  // Artist helper methods
  static Map<String, List<Song>> _groupSongsByArtist(List<Song> songs) {
    final Map<String, List<Song>> groups = {};
    for (final song in songs) {
      // Use primary artist for grouping, but consider all artists
      final artistName = _getCleanName(song.primaryArtist, 'Unknown Artist');
      groups.putIfAbsent(artistName, () => []).add(song);
    }
    return groups;
  }

  static Artist _createNewArtist(String artistName, List<Song> songs) {
    final artistId = _generateIdFromName(artistName, 'artist');
    final songIds = songs.map((song) => song.id).toList();
    final albumNames = songs
        .map((song) => _getCleanName(song.primaryAlbum, 'Unknown Album'))
        .toSet();

    return Artist(
      id: artistId,
      name: artistName,
      bio:
          'Artist with ${songs.length} songs across ${albumNames.length} albums',
      image: null,
      songIds: songIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Artist _updateExistingArtist(
    Artist existingArtist,
    List<Song> newSongs,
  ) {
    final newSongIds = newSongs.map((song) => song.id).toSet();
    final existingSongIds = existingArtist.songIds.toSet();

    // Combine existing and new songs (avoiding duplicates)
    final allSongIds = {...existingSongIds, ...newSongIds}.toList();

    final hasNewSongs = !newSongIds.every((id) => existingSongIds.contains(id));

    if (hasNewSongs) {
      _logger.d(
        'Updating artist: ${existingArtist.name} with ${newSongs.length} songs',
      );
      return existingArtist.copyWith(
        songIds: allSongIds,
        updatedAt: DateTime.now(),
      );
    }

    return existingArtist;
  }

  /// Helper method to create unique ID from name
  static String _generateIdFromName(String name, String prefix) {
    return '${prefix}_${name.hashCode}';
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
