import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/album/album_model.dart';

void main() {
  group('Album Model', () {
    late Album testAlbum;

    setUp(() {
      testAlbum = Album(
        id: 'test-album-id',
        name: 'Test Album',
        songIds: ['song1', 'song2', 'song3'],
        createdAt: DateTime(2023, 1, 1),
        coverImage: '/test/album_art.jpg',
        artistId: 'artist1',
      );
    });

    group('Constructor', () {
      test('should create album with all properties', () {
        expect(testAlbum.id, equals('test-album-id'));
        expect(testAlbum.name, equals('Test Album'));
        expect(testAlbum.songIds, equals(['song1', 'song2', 'song3']));
        expect(testAlbum.songCount, equals(3));
        expect(testAlbum.coverImage, equals('/test/album_art.jpg'));
        expect(testAlbum.artistId, equals('artist1'));
      });

      test('should create album with minimal properties', () {
        final minimalAlbum = Album(
          id: 'minimal-id',
          name: 'Minimal Album',
          songIds: ['song1'],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(minimalAlbum.id, equals('minimal-id'));
        expect(minimalAlbum.name, equals('Minimal Album'));
        expect(minimalAlbum.songIds, equals(['song1']));
        expect(minimalAlbum.songCount, equals(1));
        expect(minimalAlbum.coverImage, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedAlbum = testAlbum.copyWith(
          name: 'Updated Album',
          songIds: ['song1', 'song2', 'song3', 'song4'],
        );

        expect(updatedAlbum.name, equals('Updated Album'));
        expect(updatedAlbum.songCount, equals(4));
        
        // Other properties should remain the same
        expect(updatedAlbum.id, equals(testAlbum.id));
        expect(updatedAlbum.artistId, equals(testAlbum.artistId));
        expect(updatedAlbum.coverImage, equals(testAlbum.coverImage));
      });

      test('should create copy with null values', () {
        final nulledAlbum = testAlbum.copyWith(coverImage: null);
        expect(nulledAlbum.coverImage, isNull);
        
        // Other properties should remain the same
        expect(nulledAlbum.id, equals(testAlbum.id));
        expect(nulledAlbum.name, equals(testAlbum.name));
        expect(nulledAlbum.artistId, equals(testAlbum.artistId));
        expect(nulledAlbum.songCount, equals(testAlbum.songCount));
      });
    });

    group('Equality', () {
      test('should be equal to identical album', () {
        final identicalAlbum = Album(
          id: 'test-album-id',
          name: 'Test Album',
          songIds: ['song1', 'song2', 'song3'],
          createdAt: DateTime(2023, 1, 1),
          coverImage: '/test/album_art.jpg',
          artistId: 'artist1',
        );

        expect(testAlbum, equals(identicalAlbum));
        expect(testAlbum.hashCode, equals(identicalAlbum.hashCode));
      });

      test('should not be equal to different album', () {
        final differentAlbum = testAlbum.copyWith(name: 'Different Album');
        expect(testAlbum, isNot(equals(differentAlbum)));
        expect(testAlbum.hashCode, isNot(equals(differentAlbum.hashCode)));
      });
    });

    group('JSON Serialization', () {
      test('toJson should include all properties', () {
        final json = testAlbum.toJson();
        
        expect(json['id'], equals('test-album-id'));
        expect(json['name'], equals('Test Album'));
        expect(json['songIds'], equals(['song1', 'song2', 'song3']));
        expect(json['coverImage'], equals('/test/album_art.jpg'));
        expect(json['artistId'], equals('artist1'));
      });

      test('fromJson should create correct album', () {
        final json = {
          'id': 'json-album-id',
          'name': 'JSON Album',
          'songIds': ['json1', 'json2'],
          'createdAt': '2023-01-01T00:00:00.000Z',
          'coverImage': '/json/album_art.jpg',
          'artistId': 'json-artist',
        };

        final album = Album.fromJson(json);
        
        expect(album.id, equals('json-album-id'));
        expect(album.name, equals('JSON Album'));
        expect(album.songIds, equals(['json1', 'json2']));
        expect(album.songCount, equals(2));
        expect(album.coverImage, equals('/json/album_art.jpg'));
        expect(album.artistId, equals('json-artist'));
      });

      test('fromJson should handle null coverImage', () {
        final json = {
          'id': 'null-art-id',
          'name': 'Null Art Album',
          'songIds': ['song1'],
          'createdAt': '2023-01-01T00:00:00.000Z',
          'coverImage': null,
        };

        final album = Album.fromJson(json);
        
        expect(album.coverImage, isNull);
        expect(album.id, equals('null-art-id'));
        expect(album.name, equals('Null Art Album'));
        expect(album.songIds, equals(['song1']));
        expect(album.songCount, equals(1));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final string = testAlbum.toString();
        
        expect(string, contains('Test Album'));
        expect(string, contains('3')); // songCount
      });
    });

    group('Edge Cases', () {
      test('should handle zero song count', () {
        final emptyAlbum = testAlbum.copyWith(songIds: []);
        expect(emptyAlbum.songCount, equals(0));
      });

      test('should handle large song count', () {
        final largeSongIds = List.generate(999, (index) => 'song$index');
        final largeAlbum = testAlbum.copyWith(songIds: largeSongIds);
        expect(largeAlbum.songCount, equals(999));
      });

      test('should handle empty strings', () {
        final emptyStringAlbum = Album(
          id: '',
          name: '',
          songIds: [],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(emptyStringAlbum.id, isEmpty);
        expect(emptyStringAlbum.name, isEmpty);
        expect(emptyStringAlbum.songCount, equals(0));
      });

      test('should handle long strings', () {
        final longName = 'A' * 1000;
        final longAlbum = testAlbum.copyWith(name: longName);

        expect(longAlbum.name, equals(longName));
      });
    });
  });
}
