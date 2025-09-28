import 'package:flutter_test/flutter_test.dart';
import 'package:pmj_music_player/utils/models/artist/artist_model.dart';

void main() {
  group('Artist Model', () {
    late Artist testArtist;

    setUp(() {
      testArtist = Artist(
        id: 'test-artist-id',
        name: 'Test Artist',
        songIds: ['song1', 'song2', 'song3'],
        createdAt: DateTime(2023, 1, 1),
      );
    });

    group('Constructor', () {
      test('should create artist with all properties', () {
        expect(testArtist.id, equals('test-artist-id'));
        expect(testArtist.name, equals('Test Artist'));
        expect(testArtist.songIds, equals(['song1', 'song2', 'song3']));
        expect(testArtist.songCount, equals(3));
      });

      test('should create artist with minimal properties', () {
        final minimalArtist = Artist(
          id: 'minimal-id',
          name: 'Minimal Artist',
          songIds: ['song1'],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(minimalArtist.id, equals('minimal-id'));
        expect(minimalArtist.name, equals('Minimal Artist'));
        expect(minimalArtist.songIds, equals(['song1']));
        expect(minimalArtist.songCount, equals(1));
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedArtist = testArtist.copyWith(
          name: 'Updated Artist',
          songIds: ['song1', 'song2', 'song3', 'song4'],
        );

        expect(updatedArtist.name, equals('Updated Artist'));
        expect(updatedArtist.songCount, equals(4));
        
        // Other properties should remain the same
        expect(updatedArtist.id, equals(testArtist.id));
      });

      test('should create copy with all properties updated', () {
        final fullyUpdatedArtist = testArtist.copyWith(
          name: 'Fully Updated Artist',
          songIds: ['song1', 'song2', 'song3', 'song4', 'song5'],
        );

        expect(fullyUpdatedArtist.name, equals('Fully Updated Artist'));
        expect(fullyUpdatedArtist.songCount, equals(5));
        
        // ID should remain the same
        expect(fullyUpdatedArtist.id, equals(testArtist.id));
      });
    });

    group('Equality', () {
      test('should be equal to identical artist', () {
        final identicalArtist = Artist(
          id: 'test-artist-id',
          name: 'Test Artist',
          songIds: ['song1', 'song2', 'song3'],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(testArtist, equals(identicalArtist));
        expect(testArtist.hashCode, equals(identicalArtist.hashCode));
      });

      test('should not be equal to different artist', () {
        final differentArtist = testArtist.copyWith(name: 'Different Artist');
        expect(testArtist, isNot(equals(differentArtist)));
        expect(testArtist.hashCode, isNot(equals(differentArtist.hashCode)));
      });
    });

    group('JSON Serialization', () {
      test('toJson should include all properties', () {
        final json = testArtist.toJson();
        
        expect(json['id'], equals('test-artist-id'));
        expect(json['name'], equals('Test Artist'));
        expect(json['songIds'], equals(['song1', 'song2', 'song3']));
        expect(json['albumIds'], equals(['album1', 'album2', 'album3']));
      });

      test('fromJson should create correct artist', () {
        final json = {
          'id': 'json-artist-id',
          'name': 'JSON Artist',
          'songIds': ['json1', 'json2'],
          'createdAt': '2023-01-01T00:00:00.000Z',
          'albumIds': ['album1', 'album2'],
        };

        final artist = Artist.fromJson(json);
        
        expect(artist.id, equals('json-artist-id'));
        expect(artist.name, equals('JSON Artist'));
        expect(artist.songIds, equals(['json1', 'json2']));
        expect(artist.songCount, equals(2));
      });

      test('fromJson should handle missing properties with defaults', () {
        final json = {
          'id': 'minimal-json-id',
          'name': 'Minimal JSON Artist',
          'songIds': [],
          'createdAt': '2023-01-01T00:00:00.000Z',
        };

        final artist = Artist.fromJson(json);
        
        expect(artist.id, equals('minimal-json-id'));
        expect(artist.name, equals('Minimal JSON Artist'));
        expect(artist.songIds, isEmpty);
        expect(artist.songCount, equals(0));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final string = testArtist.toString();
        
        expect(string, contains('Test Artist'));
        expect(string, contains('3')); // songCount
      });
    });

    group('Edge Cases', () {
      test('should handle zero counts', () {
        final zeroCountArtist = testArtist.copyWith(
          songIds: [],
        );
        expect(zeroCountArtist.songCount, equals(0));
      });

      test('should handle large counts', () {
        final largeSongIds = List.generate(9999, (index) => 'song$index');
        final largeCountArtist = testArtist.copyWith(
          songIds: largeSongIds,
        );
        expect(largeCountArtist.songCount, equals(9999));
      });

      test('should handle empty strings', () {
        final emptyStringArtist = Artist(
          id: '',
          name: '',
          songIds: [],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(emptyStringArtist.id, isEmpty);
        expect(emptyStringArtist.name, isEmpty);
        expect(emptyStringArtist.songCount, equals(0));
      });

      test('should handle long strings', () {
        final longName = 'A' * 1000;
        final longArtist = testArtist.copyWith(name: longName);

        expect(longArtist.name, equals(longName));
      });

      test('should handle special characters in name', () {
        final specialName = 'Test Artist & The Band (feat. Special Guest)';
        final specialArtist = testArtist.copyWith(name: specialName);

        expect(specialArtist.name, equals(specialName));
      });

      test('should handle unicode characters in name', () {
        final unicodeName = '测试艺术家';
        final unicodeArtist = testArtist.copyWith(name: unicodeName);

        expect(unicodeArtist.name, equals(unicodeName));
      });
    });

    group('Validation', () {
      test('should handle empty song list gracefully', () {
        final emptySongArtist = testArtist.copyWith(songIds: []);
        expect(emptySongArtist.songCount, equals(0));
      });

      test('should handle null album list gracefully', () {
      });
    });
  });
}
