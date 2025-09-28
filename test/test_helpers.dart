import 'package:mocktail/mocktail.dart';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/models/album/album_model.dart';
import 'package:pmj_music_player/utils/models/artist/artist_model.dart';
import 'package:pmj_music_player/utils/models/my_playlist/my_playlist_model.dart';
import 'package:pmj_music_player/utils/models/my_player_state_model.dart';

/// Test helper functions and mock data for unit tests
class TestHelpers {
  /// Creates a test song with default values
  static Song createTestSong({
    String? id,
    String? title,
    List<String>? artists,
    List<String>? albums,
    String? path,
    Duration? duration,
    String? albumArt,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? composer,
    String? lyrics,
    int? bitrate,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
    String? albumArtist,
  }) {
    return Song(
      id: id ?? 'test-song-id',
      title: title ?? 'Test Song',
      artists: artists ?? ['Test Artist'],
      albums: albums ?? ['Test Album'],
      path: path ?? '/test/path.mp3',
      duration: duration ?? const Duration(minutes: 3, seconds: 30),
      albumArt: albumArt,
      genre: genre ?? 'Rock',
      year: year ?? 2023,
      trackNumber: trackNumber ?? 1,
      discNumber: discNumber ?? 1,
      composer: composer ?? 'Test Composer',
      lyrics: lyrics ?? 'Test lyrics',
      bitrate: bitrate ?? 320,
      fileSize: fileSize ?? 1024000,
      dateAdded: dateAdded ?? DateTime(2023, 1, 1),
      lastPlayed: lastPlayed ?? DateTime(2023, 1, 2),
      playCount: playCount ?? 5,
      isFavorite: isFavorite ?? true,
      albumArtist: albumArtist ?? 'Test Album Artist',
    );
  }

  /// Creates a test album with default values
  static Album createTestAlbum({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    String? coverImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? artistId,
    String? genre,
    int? year,
  }) {
    return Album(
      id: id ?? 'test-album-id',
      name: name ?? 'Test Album',
      description: description ?? 'Test Album Description',
      songIds: songIds ?? ['song1', 'song2', 'song3'],
      coverImage: coverImage,
      createdAt: createdAt ?? DateTime(2023, 1, 1),
      updatedAt: updatedAt,
      artistId: artistId ?? 'test-artist-id',
      genre: genre,
      year: year,
    );
  }

  /// Creates a test artist with default values
  static Artist createTestArtist({
    String? id,
    String? name,
    String? bio,
    String? image,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? albumIds,
  }) {
    return Artist(
      id: id ?? 'test-artist-id',
      name: name ?? 'Test Artist',
      bio: bio ?? 'Test Artist Bio',
      image: image,
      songIds: songIds ?? ['song1', 'song2', 'song3'],
      createdAt: createdAt ?? DateTime(2023, 1, 1),
      updatedAt: updatedAt,
    );
  }

  /// Creates a test playlist with default values
  static MyPlaylist createTestPlaylist({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImage,
    bool? isPublic,
    String? createdBy,
    Duration? totalDuration,
  }) {
    return MyPlaylist(
      id: id ?? 'test-playlist-id',
      name: name ?? 'Test Playlist',
      description: description ?? 'Test Description',
      songIds: songIds ?? ['song1', 'song2', 'song3'],
      createdAt: createdAt ?? DateTime(2023, 1, 1),
      updatedAt: updatedAt,
      coverImage: coverImage,
      isPublic: isPublic,
      createdBy: createdBy,
      totalDuration: totalDuration,
    );
  }

  /// Creates a test player state with default values
  static MyPlayerStateModel createTestPlayerState({
    String? playlistId,
    List<String>? currentPlayList,
    String? currentSongId,
    String? previousSongId,
    List<String>? completedSongs,
    int? repeatModeIndex,
    String? filterKeyword,
    bool? isPlaying,
    bool? isShuffle,
  }) {
    return MyPlayerStateModel(
      playlistId: playlistId ?? 'test-playlist',
      currentPlayList: currentPlayList ?? ['song1', 'song2', 'song3'],
      currentSongId: currentSongId ?? 'song2',
      previousSongId: previousSongId ?? 'song1',
      completedSongs: completedSongs ?? ['song1'],
      repeatModeIndex: repeatModeIndex ?? 1,
      filterKeyword: filterKeyword ?? 'test',
      isPlaying: isPlaying ?? true,
      isShuffle: isShuffle ?? true,
    );
  }

  /// Creates a list of test songs
  static List<Song> createTestSongs({int count = 3}) {
    return List.generate(count, (index) => createTestSong(
      id: 'test-song-$index',
      title: 'Test Song $index',
      artists: ['Test Artist $index'],
      albums: ['Test Album $index'],
      path: '/test/path$index.mp3',
    ));
  }

  /// Creates a list of test albums
  static List<Album> createTestAlbums({int count = 3}) {
    return List.generate(count, (index) => createTestAlbum(
      id: 'test-album-$index',
      name: 'Test Album $index',
      songIds: ['song$index-1', 'song$index-2'],
      artistId: 'test-artist-$index',
    ));
  }

  /// Creates a list of test artists
  static List<Artist> createTestArtists({int count = 3}) {
    return List.generate(count, (index) => createTestArtist(
      id: 'test-artist-$index',
      name: 'Test Artist $index',
      songIds: ['song$index-1', 'song$index-2'],
      albumIds: ['album$index-1'],
    ));
  }

  /// Creates a list of test playlists
  static List<MyPlaylist> createTestPlaylists({int count = 3}) {
    return List.generate(count, (index) => createTestPlaylist(
      id: 'test-playlist-$index',
      name: 'Test Playlist $index',
      description: 'Test Description $index',
      songIds: ['song$index-1', 'song$index-2'],
    ));
  }
}

/// Mock classes for testing
class MockSong extends Mock implements Song {}
class MockAlbum extends Mock implements Album {}
class MockArtist extends Mock implements Artist {}
class MockMyPlaylist extends Mock implements MyPlaylist {}
class MockMyPlayerStateModel extends Mock implements MyPlayerStateModel {}

/// Test utilities
class TestUtils {
  /// Registers fallback values for mocktail
  static void registerFallbacks() {
    registerFallbackValue(TestHelpers.createTestSong());
    registerFallbackValue(TestHelpers.createTestAlbum());
    registerFallbackValue(TestHelpers.createTestArtist());
    registerFallbackValue(TestHelpers.createTestPlaylist());
    registerFallbackValue(TestHelpers.createTestPlayerState());
  }

  /// Creates a test file path
  static String createTestFilePath(String filename) {
    return '/test/path/$filename';
  }

  /// Creates a test directory path
  static String createTestDirectoryPath(String dirname) {
    return '/test/directory/$dirname';
  }

  /// Creates a test duration
  static Duration createTestDuration({int minutes = 3, int seconds = 30}) {
    return Duration(minutes: minutes, seconds: seconds);
  }

  /// Creates a test date
  static DateTime createTestDate({int year = 2023, int month = 1, int day = 1}) {
    return DateTime(year, month, day);
  }

  /// Creates multiple test songs
  static List<Song> createTestSongs({int count = 3}) {
    return TestHelpers.createTestSongs(count: count);
  }

  /// Creates multiple test albums
  static List<Album> createTestAlbums({int count = 3}) {
    return TestHelpers.createTestAlbums(count: count);
  }

  /// Creates multiple test artists
  static List<Artist> createTestArtists({int count = 3}) {
    return TestHelpers.createTestArtists(count: count);
  }

  /// Creates multiple test playlists
  static List<MyPlaylist> createTestPlaylists({int count = 3}) {
    return TestHelpers.createTestPlaylists(count: count);
  }
}

/// Test constants
class TestConstants {
  static const String testSongId = 'test-song-id';
  static const String testAlbumId = 'test-album-id';
  static const String testArtistId = 'test-artist-id';
  static const String testPlaylistId = 'test-playlist-id';
  
  static const String testSongTitle = 'Test Song';
  static const String testAlbumName = 'Test Album';
  static const String testArtistName = 'Test Artist';
  static const String testPlaylistName = 'Test Playlist';
  
  static const String testFilePath = '/test/path.mp3';
  static const String testAlbumArtPath = '/test/album_art.jpg';
  
  static const Duration testDuration = Duration(minutes: 3, seconds: 30);
  static final DateTime testDate = DateTime(2023, 1, 1);
  
  static const List<String> testSongIds = ['song1', 'song2', 'song3'];
  static const List<String> testArtists = ['Artist 1', 'Artist 2'];
  static const List<String> testAlbums = ['Album 1', 'Album 2'];
}
