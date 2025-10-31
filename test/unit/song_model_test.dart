import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';

void main() {
  group('Song Model', () {
    late Song testSong;

    setUp(() {
      testSong = Song(
        id: 'test-id',
        title: 'Test Song',
        artists: ['Test Artist 1', 'Test Artist 2'],
        albums: ['Test Album'],
        path: '/test/path.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
        albumArt: '/test/art.jpg',
        genre: 'Rock',
        year: 2023,
        trackNumber: 1,
        discNumber: 1,
        composer: 'Test Composer',
        lyrics: 'Test lyrics',
        bitrate: 320,
        fileSize: 1024000,
        dateAdded: DateTime(2023, 1, 1),
        lastPlayed: DateTime(2023, 1, 2),
        playCount: 5,
        isFavorite: true,
        albumArtist: 'Test Album Artist',
      );
    });

    group('Constructor', () {
      test('should create song with all properties', () {
        expect(testSong.id, equals('test-id'));
        expect(testSong.title, equals('Test Song'));
        expect(testSong.artists, equals(['Test Artist 1', 'Test Artist 2']));
        expect(testSong.albums, equals(['Test Album']));
        expect(testSong.path, equals('/test/path.mp3'));
        expect(testSong.duration, equals(const Duration(minutes: 3, seconds: 30)));
        expect(testSong.albumArt, equals('/test/art.jpg'));
        expect(testSong.genre, equals('Rock'));
        expect(testSong.year, equals(2023));
        expect(testSong.trackNumber, equals(1));
        expect(testSong.discNumber, equals(1));
        expect(testSong.composer, equals('Test Composer'));
        expect(testSong.lyrics, equals('Test lyrics'));
        expect(testSong.bitrate, equals(320));
        expect(testSong.fileSize, equals(1024000));
        expect(testSong.dateAdded, equals(DateTime(2023, 1, 1)));
        expect(testSong.lastPlayed, equals(DateTime(2023, 1, 2)));
        expect(testSong.playCount, equals(5));
        expect(testSong.isFavorite, isTrue);
        expect(testSong.albumArtist, equals('Test Album Artist'));
      });

      test('should create song with minimal required properties', () {
        final minimalSong = Song(
          id: 'minimal-id',
          title: 'Minimal Song',
          artists: ['Minimal Artist'],
          albums: ['Minimal Album'],
          path: '/minimal/path.mp3',
          duration: const Duration(minutes: 2),
        );

        expect(minimalSong.id, equals('minimal-id'));
        expect(minimalSong.title, equals('Minimal Song'));
        expect(minimalSong.artists, equals(['Minimal Artist']));
        expect(minimalSong.albums, equals(['Minimal Album']));
        expect(minimalSong.path, equals('/minimal/path.mp3'));
        expect(minimalSong.duration, equals(const Duration(minutes: 2)));
        expect(minimalSong.albumArt, isNull);
        expect(minimalSong.genre, isNull);
        expect(minimalSong.year, isNull);
        expect(minimalSong.trackNumber, isNull);
        expect(minimalSong.discNumber, isNull);
        expect(minimalSong.composer, isNull);
        expect(minimalSong.lyrics, isNull);
        expect(minimalSong.bitrate, isNull);
        expect(minimalSong.fileSize, isNull);
        expect(minimalSong.dateAdded, isNull);
        expect(minimalSong.lastPlayed, isNull);
        expect(minimalSong.playCount, isNull);
        expect(minimalSong.isFavorite, isNull);
        expect(minimalSong.albumArtist, isNull);
      });
    });

    group('Getters', () {
      test('primaryArtist should return first artist', () {
        expect(testSong.primaryArtist, equals('Test Artist 1'));
      });

      test('primaryArtist should return "Unknown Artist" when no artists', () {
        final songWithoutArtists = testSong.copyWith(artists: []);
        expect(songWithoutArtists.primaryArtist, equals('Unknown Artist'));
      });

      test('primaryAlbum should return first album', () {
        expect(testSong.primaryAlbum, equals('Test Album'));
      });

      test('primaryAlbum should return "Unknown Album" when no albums', () {
        final songWithoutAlbums = testSong.copyWith(albums: []);
        expect(songWithoutAlbums.primaryAlbum, equals('Unknown Album'));
      });

      test('formattedDuration should return correct format', () {
        expect(testSong.formattedDuration, equals('03:30'));
      });

      test('formattedDuration should handle zero duration', () {
        final zeroDurationSong = testSong.copyWith(duration: Duration.zero);
        expect(zeroDurationSong.formattedDuration, equals('00:00'));
      });

      test('formattedDuration should handle long duration', () {
        final longDurationSong = testSong.copyWith(
          duration: const Duration(hours: 1, minutes: 23, seconds: 45),
        );
        expect(longDurationSong.formattedDuration, equals('83:45'));
      });

      test('formattedFileSize should return correct format', () {
        expect(testSong.formattedFileSize, equals('1000.00 KB'));
      });

      test('formattedFileSize should handle zero size', () {
        final zeroSizeSong = testSong.copyWith(fileSize: 0);
        expect(zeroSizeSong.formattedFileSize, equals('0.00 KB'));
      });

      test('formattedFileSize should handle bytes', () {
        final byteSong = testSong.copyWith(fileSize: 512);
        expect(byteSong.formattedFileSize, equals('0.50 KB'));
      });

      test('formattedFileSize should handle KB', () {
        final kbSong = testSong.copyWith(fileSize: 1536); // 1.5 KB
        expect(kbSong.formattedFileSize, equals('1.50 KB'));
      });

      test('formattedFileSize should handle GB', () {
        final gbSong = testSong.copyWith(fileSize: 1073741824); // 1 GB
        expect(gbSong.formattedFileSize, equals('1024.00 MB'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedSong = testSong.copyWith(
          title: 'Updated Title',
          artists: ['Updated Artist'],
          isFavorite: false,
        );

        expect(updatedSong.title, equals('Updated Title'));
        expect(updatedSong.artists, equals(['Updated Artist']));
        expect(updatedSong.isFavorite, isFalse);
        
        // Other properties should remain the same
        expect(updatedSong.id, equals(testSong.id));
        expect(updatedSong.path, equals(testSong.path));
        expect(updatedSong.duration, equals(testSong.duration));
      });

      test('should create copy with null values', () {
        final nulledSong = testSong.copyWith(
          albumArt: null,
          genre: null,
          year: null,
        );

        expect(nulledSong.albumArt, isNull);
        expect(nulledSong.genre, isNull);
        expect(nulledSong.year, isNull);
        
        // Other properties should remain the same
        expect(nulledSong.id, equals(testSong.id));
        expect(nulledSong.title, equals(testSong.title));
      });
    });

    group('Equality', () {
      test('should be equal to identical song', () {
        final identicalSong = Song(
          id: 'test-id',
          title: 'Test Song',
          artists: ['Test Artist 1', 'Test Artist 2'],
          albums: ['Test Album'],
          path: '/test/path.mp3',
          duration: const Duration(minutes: 3, seconds: 30),
          albumArt: '/test/art.jpg',
          genre: 'Rock',
          year: 2023,
          trackNumber: 1,
          discNumber: 1,
          composer: 'Test Composer',
          lyrics: 'Test lyrics',
          bitrate: 320,
          fileSize: 1024000,
          dateAdded: DateTime(2023, 1, 1),
          lastPlayed: DateTime(2023, 1, 2),
          playCount: 5,
          isFavorite: true,
          albumArtist: 'Test Album Artist',
        );

        expect(testSong, equals(identicalSong));
        expect(testSong.hashCode, equals(identicalSong.hashCode));
      });

      test('should not be equal to different song', () {
        final differentSong = testSong.copyWith(title: 'Different Title');
        expect(testSong, isNot(equals(differentSong)));
        expect(testSong.hashCode, isNot(equals(differentSong.hashCode)));
      });
    });

    group('JSON Serialization', () {
      test('toJson should include all properties', () {
        final json = testSong.toJson();
        
        expect(json['id'], equals('test-id'));
        expect(json['title'], equals('Test Song'));
        expect(json['artists'], equals(['Test Artist 1', 'Test Artist 2']));
        expect(json['albums'], equals(['Test Album']));
        expect(json['path'], equals('/test/path.mp3'));
        expect(json['duration'], equals(210000)); // 3:30 in milliseconds
        expect(json['albumArt'], equals('/test/art.jpg'));
        expect(json['genre'], equals('Rock'));
        expect(json['year'], equals(2023));
        expect(json['trackNumber'], equals(1));
        expect(json['discNumber'], equals(1));
        expect(json['composer'], equals('Test Composer'));
        expect(json['lyrics'], equals('Test lyrics'));
        expect(json['bitrate'], equals(320));
        expect(json['fileSize'], equals(1024000));
        expect(json['dateAdded'], equals(DateTime(2023, 1, 1).toIso8601String()));
        expect(json['lastPlayed'], equals(DateTime(2023, 1, 2).toIso8601String()));
        expect(json['playCount'], equals(5));
        expect(json['isFavorite'], isTrue);
        expect(json['albumArtist'], equals('Test Album Artist'));
      });

      test('fromJson should create correct song', () {
        final json = {
          'id': 'json-id',
          'title': 'JSON Song',
          'artists': ['JSON Artist'],
          'albums': ['JSON Album'],
          'path': '/json/path.mp3',
          'duration': 180000, // 3 minutes
          'albumArt': '/json/art.jpg',
          'genre': 'Pop',
          'year': 2022,
          'trackNumber': 2,
          'discNumber': 1,
          'composer': 'JSON Composer',
          'lyrics': 'JSON lyrics',
          'bitrate': 256,
          'fileSize': 512000,
          'dateAdded': '2022-01-01T00:00:00.000Z',
          'lastPlayed': '2022-01-02T00:00:00.000Z',
          'playCount': 3,
          'isFavorite': false,
          'albumArtist': 'JSON Album Artist',
        };

        final song = Song.fromJson(json);
        
        expect(song.id, equals('json-id'));
        expect(song.title, equals('JSON Song'));
        expect(song.artists, equals(['JSON Artist']));
        expect(song.albums, equals(['JSON Album']));
        expect(song.path, equals('/json/path.mp3'));
        expect(song.duration, equals(const Duration(minutes: 3)));
        expect(song.albumArt, equals('/json/art.jpg'));
        expect(song.genre, equals('Pop'));
        expect(song.year, equals(2022));
        expect(song.trackNumber, equals(2));
        expect(song.discNumber, equals(1));
        expect(song.composer, equals('JSON Composer'));
        expect(song.lyrics, equals('JSON lyrics'));
        expect(song.bitrate, equals(256));
        expect(song.fileSize, equals(512000));
        expect(song.dateAdded, equals(DateTime.parse('2022-01-01T00:00:00.000Z')));
        expect(song.lastPlayed, equals(DateTime.parse('2022-01-02T00:00:00.000Z')));
        expect(song.playCount, equals(3));
        expect(song.isFavorite, isFalse);
        expect(song.albumArtist, equals('JSON Album Artist'));
      });

      test('fromJson should handle null values', () {
        final json = {
          'id': 'null-id',
          'title': 'Null Song',
          'artists': ['Null Artist'],
          'albums': ['Null Album'],
          'path': '/null/path.mp3',
          'duration': 120000,
          'albumArt': null,
          'genre': null,
          'year': null,
          'trackNumber': null,
          'discNumber': null,
          'composer': null,
          'lyrics': null,
          'bitrate': null,
          'fileSize': 0,
          'dateAdded': '2022-01-01T00:00:00.000Z',
          'lastPlayed': null,
          'playCount': 0,
          'isFavorite': false,
          'albumArtist': null,
        };

        final song = Song.fromJson(json);
        
        expect(song.albumArt, isNull);
        expect(song.genre, isNull);
        expect(song.year, isNull);
        expect(song.trackNumber, isNull);
        expect(song.discNumber, isNull);
        expect(song.composer, isNull);
        expect(song.lyrics, isNull);
        expect(song.bitrate, isNull);
        expect(song.lastPlayed, isNull);
        expect(song.albumArtist, isNull);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final string = testSong.toString();
        
        expect(string, contains('Test Song'));
        expect(string, contains('Test Artist 1'));
        expect(string, contains('Test Album'));
        expect(string, contains('3:30'));
      });
    });
  });
}
