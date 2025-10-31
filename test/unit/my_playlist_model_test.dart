import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/my_playlist/my_playlist_model.dart';

void main() {
  group('MyPlaylist Model', () {
    late MyPlaylist testPlaylist;

    setUp(() {
      testPlaylist = MyPlaylist(
        id: 'test-playlist-id',
        name: 'Test Playlist',
        description: 'Test Description',
        songIds: ['song1', 'song2', 'song3'],
        createdAt: DateTime(2023, 1, 1),
      );
    });

    group('Constructor', () {
      test('should create playlist with all properties', () {
        expect(testPlaylist.id, equals('test-playlist-id'));
        expect(testPlaylist.name, equals('Test Playlist'));
        expect(testPlaylist.description, equals('Test Description'));
        expect(testPlaylist.songIds, equals(['song1', 'song2', 'song3']));
        expect(testPlaylist.createdAt, equals(DateTime(2023, 1, 1)));
      });

      test('should create playlist with minimal properties', () {
        final minimalPlaylist = MyPlaylist(
          id: 'minimal-id',
          name: 'Minimal Playlist',
          description: 'Minimal Description',
          songIds: [],
          createdAt: DateTime.now(),
        );

        expect(minimalPlaylist.id, equals('minimal-id'));
        expect(minimalPlaylist.name, equals('Minimal Playlist'));
        expect(minimalPlaylist.description, equals('Minimal Description'));
        expect(minimalPlaylist.songIds, isEmpty);
        expect(minimalPlaylist.createdAt, isA<DateTime>());
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedPlaylist = testPlaylist.copyWith(
          name: 'Updated Playlist',
          songIds: ['song1', 'song2', 'song3', 'song4'],
        );

        expect(updatedPlaylist.name, equals('Updated Playlist'));
        expect(updatedPlaylist.songIds, equals(['song1', 'song2', 'song3', 'song4']));
        
        // Other properties should remain the same
        expect(updatedPlaylist.id, equals(testPlaylist.id));
        expect(updatedPlaylist.createdAt, equals(testPlaylist.createdAt));
      });

      test('should create copy with all properties updated', () {
        final newCreatedAt = DateTime(2023, 6, 15);
        final fullyUpdatedPlaylist = testPlaylist.copyWith(
          name: 'Fully Updated Playlist',
          songIds: ['newSong1', 'newSong2'],
          createdAt: newCreatedAt,
        );

        expect(fullyUpdatedPlaylist.name, equals('Fully Updated Playlist'));
        expect(fullyUpdatedPlaylist.songIds, equals(['newSong1', 'newSong2']));
        expect(fullyUpdatedPlaylist.createdAt, equals(newCreatedAt));
        
        // ID should remain the same
        expect(fullyUpdatedPlaylist.id, equals(testPlaylist.id));
      });
    });

    group('addSong', () {
      test('should add song to playlist', () {
        final updatedPlaylist = testPlaylist.addSong('song4');
        
        expect(updatedPlaylist.songIds, equals(['song1', 'song2', 'song3', 'song4']));
        expect(updatedPlaylist.songIds.length, equals(4));
      });

      test('should not add duplicate song', () {
        final updatedPlaylist = testPlaylist.addSong('song1');
        
        expect(updatedPlaylist.songIds, equals(['song1', 'song2', 'song3']));
        expect(updatedPlaylist.songIds.length, equals(3));
      });

      test('should add song to empty playlist', () {
        final emptyPlaylist = testPlaylist.copyWith(songIds: []);
        final updatedPlaylist = emptyPlaylist.addSong('firstSong');
        
        expect(updatedPlaylist.songIds, equals(['firstSong']));
        expect(updatedPlaylist.songIds.length, equals(1));
      });
    });

    group('removeSong', () {
      test('should remove song from playlist', () {
        final updatedPlaylist = testPlaylist.removeSong('song2');
        
        expect(updatedPlaylist.songIds, equals(['song1', 'song3']));
        expect(updatedPlaylist.songIds.length, equals(2));
      });

      test('should not remove non-existent song', () {
        final updatedPlaylist = testPlaylist.removeSong('nonExistentSong');
        
        expect(updatedPlaylist.songIds, equals(['song1', 'song2', 'song3']));
        expect(updatedPlaylist.songIds.length, equals(3));
      });

      test('should handle removing from empty playlist', () {
        final emptyPlaylist = testPlaylist.copyWith(songIds: []);
        final updatedPlaylist = emptyPlaylist.removeSong('anySong');
        
        expect(updatedPlaylist.songIds, isEmpty);
      });
    });

    group('Helper Methods', () {
      test('should have correct song count', () {
        expect(testPlaylist.songCount, equals(3));
      });

      test('should have formatted song count', () {
        expect(testPlaylist.formattedSongCount, equals('3 songs'));
      });

      test('should handle single song count', () {
        final singleSongPlaylist = testPlaylist.copyWith(songIds: ['song1']);
        expect(singleSongPlaylist.formattedSongCount, equals('1 song'));
      });
    });

    group('Equality', () {
      test('should be equal to identical playlist', () {
        final identicalPlaylist = MyPlaylist(
          id: 'test-playlist-id',
          name: 'Test Playlist',
          description: 'Test Description',
          songIds: ['song1', 'song2', 'song3'],
          createdAt: DateTime(2023, 1, 1),
        );

        expect(testPlaylist, equals(identicalPlaylist));
        expect(testPlaylist.hashCode, equals(identicalPlaylist.hashCode));
      });

      test('should not be equal to different playlist', () {
        final differentPlaylist = testPlaylist.copyWith(name: 'Different Playlist');
        expect(testPlaylist, isNot(equals(differentPlaylist)));
        expect(testPlaylist.hashCode, isNot(equals(differentPlaylist.hashCode)));
      });
    });

    group('JSON Serialization', () {
      test('toJson should include all properties', () {
        final json = testPlaylist.toJson();
        
        expect(json['id'], equals('test-playlist-id'));
        expect(json['name'], equals('Test Playlist'));
        expect(json['songIds'], equals(['song1', 'song2', 'song3']));
        expect(json['createdAt'], equals(DateTime(2023, 1, 1).toIso8601String()));
      });

      test('fromJson should create correct playlist', () {
        final json = {
          'id': 'json-playlist-id',
          'name': 'JSON Playlist',
          'description': 'JSON Description',
          'songIds': ['json1', 'json2'],
          'createdAt': '2023-06-15T12:00:00.000Z',
        };

        final playlist = MyPlaylist.fromJson(json);
        
        expect(playlist.id, equals('json-playlist-id'));
        expect(playlist.name, equals('JSON Playlist'));
        expect(playlist.description, equals('JSON Description'));
        expect(playlist.songIds, equals(['json1', 'json2']));
        expect(playlist.createdAt, equals(DateTime.parse('2023-06-15T12:00:00.000Z')));
      });

      test('fromJson should handle missing properties with defaults', () {
        final json = {
          'id': 'minimal-json-id',
          'name': 'Minimal JSON Playlist',
          'description': 'Minimal Description',
          'songIds': [],
          'createdAt': '2023-01-01T00:00:00.000Z',
        };

        final playlist = MyPlaylist.fromJson(json);
        
        expect(playlist.id, equals('minimal-json-id'));
        expect(playlist.name, equals('Minimal JSON Playlist'));
        expect(playlist.description, equals('Minimal Description'));
        expect(playlist.songIds, isEmpty);
        expect(playlist.createdAt, isA<DateTime>());
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final string = testPlaylist.toString();
        
        expect(string, contains('Test Playlist'));
        expect(string, contains('3')); // songIds length
      });
    });

    group('Edge Cases', () {
      test('should handle empty song list', () {
        final emptyPlaylist = testPlaylist.copyWith(songIds: []);
        expect(emptyPlaylist.songIds, isEmpty);
      });

      test('should handle large song list', () {
        final largeSongList = List.generate(1000, (index) => 'song$index');
        final largePlaylist = testPlaylist.copyWith(songIds: largeSongList);
        expect(largePlaylist.songIds.length, equals(1000));
      });

      test('should handle empty strings', () {
        final emptyStringPlaylist = MyPlaylist(
          id: '',
          name: '',
          description: '',
          songIds: [],
          createdAt: DateTime.now(),
        );

        expect(emptyStringPlaylist.id, isEmpty);
        expect(emptyStringPlaylist.name, isEmpty);
        expect(emptyStringPlaylist.description, isEmpty);
      });

      test('should handle long strings', () {
        final longName = 'A' * 1000;
        final longPlaylist = testPlaylist.copyWith(name: longName);

        expect(longPlaylist.name, equals(longName));
      });

      test('should handle special characters in name', () {
        final specialName = 'My Playlist & Mix (2023)';
        final specialPlaylist = testPlaylist.copyWith(name: specialName);

        expect(specialPlaylist.name, equals(specialName));
      });

      test('should handle unicode characters in name', () {
        final unicodeName = '我的播放列表';
        final unicodePlaylist = testPlaylist.copyWith(name: unicodeName);

        expect(unicodePlaylist.name, equals(unicodeName));
      });
    });

    group('Song Management Edge Cases', () {
      test('should handle adding multiple songs', () {
        var playlist = testPlaylist;
        playlist = playlist.addSong('song4');
        playlist = playlist.addSong('song5');
        
        expect(playlist.songIds, equals(['song1', 'song2', 'song3', 'song4', 'song5']));
        expect(playlist.songIds.length, equals(5));
      });

      test('should handle removing multiple songs', () {
        var playlist = testPlaylist;
        playlist = playlist.removeSong('song1');
        playlist = playlist.removeSong('song3');
        
        expect(playlist.songIds, equals(['song2']));
        expect(playlist.songIds.length, equals(1));
      });

      test('should handle removing all songs', () {
        var playlist = testPlaylist;
        for (final songId in testPlaylist.songIds) {
          playlist = playlist.removeSong(songId);
        }
        
        expect(playlist.songIds, isEmpty);
      });
    });
  });
}
