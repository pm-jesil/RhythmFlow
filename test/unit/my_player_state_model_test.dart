import 'package:flutter_test/flutter_test.dart';
import 'package:pmj_music_player/utils/models/my_player_state_model.dart';

void main() {
  group('MyPlayerStateModel', () {
    late MyPlayerStateModel testState;

    setUp(() {
      testState = MyPlayerStateModel(
        playlistId: 'test-playlist',
        currentPlayList: ['song1', 'song2', 'song3'],
        currentSongId: 'song2',
        previousSongId: 'song1',
        completedSongs: ['song1'],
        repeatModeIndex: 1,
        filterKeyword: 'test',
        isPlaying: true,
        isShuffle: true,
      );
    });

    group('Constructor', () {
      test('should create state with all properties', () {
        expect(testState.playlistId, equals('test-playlist'));
        expect(testState.currentPlayList, equals(['song1', 'song2', 'song3']));
        expect(testState.currentSongId, equals('song2'));
        expect(testState.previousSongId, equals('song1'));
        expect(testState.completedSongs, equals(['song1']));
        expect(testState.repeatModeIndex, equals(1));
        expect(testState.filterKeyword, equals('test'));
        expect(testState.isPlaying, isTrue);
        expect(testState.isShuffle, isTrue);
      });

      test('should create state with default values', () {
        final defaultState = MyPlayerStateModel();
        
        expect(defaultState.playlistId, isNull);
        expect(defaultState.currentPlayList, isEmpty);
        expect(defaultState.currentSongId, isNull);
        expect(defaultState.previousSongId, isNull);
        expect(defaultState.completedSongs, isEmpty);
        expect(defaultState.repeatModeIndex, equals(0));
        expect(defaultState.filterKeyword, equals(''));
        expect(defaultState.isPlaying, isFalse);
        expect(defaultState.isShuffle, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedState = testState.copyWith(
          currentSongId: 'song3',
          isPlaying: false,
          isShuffle: false,
        );

        expect(updatedState.currentSongId, equals('song3'));
        expect(updatedState.isPlaying, isFalse);
        expect(updatedState.isShuffle, isFalse);
        
        // Other properties should remain the same
        expect(updatedState.playlistId, equals(testState.playlistId));
        expect(updatedState.currentPlayList, equals(testState.currentPlayList));
        expect(updatedState.previousSongId, equals(testState.previousSongId));
        expect(updatedState.completedSongs, equals(testState.completedSongs));
        expect(updatedState.repeatModeIndex, equals(testState.repeatModeIndex));
        expect(updatedState.filterKeyword, equals(testState.filterKeyword));
      });

      test('should create copy with updated values', () {
        final updatedState = testState.copyWith(
          currentSongId: 'new-song',
          isPlaying: false,
        );

        expect(updatedState.currentSongId, equals('new-song'));
        expect(updatedState.isPlaying, isFalse);
        
        // Other properties should remain the same
        expect(updatedState.playlistId, equals(testState.playlistId));
        expect(updatedState.currentPlayList, equals(testState.currentPlayList));
        expect(updatedState.previousSongId, equals(testState.previousSongId));
        expect(updatedState.completedSongs, equals(testState.completedSongs));
        expect(updatedState.repeatModeIndex, equals(testState.repeatModeIndex));
        expect(updatedState.filterKeyword, equals(testState.filterKeyword));
        expect(updatedState.isShuffle, equals(testState.isShuffle));
      });
    });

    group('clear', () {
      test('should clear all state properties', () {
        final clearedState = testState.clear();

        expect(clearedState.playlistId, isNull);
        expect(clearedState.currentPlayList, isEmpty);
        expect(clearedState.currentSongId, isNull);
        expect(clearedState.previousSongId, isNull);
        expect(clearedState.completedSongs, isEmpty);
        expect(clearedState.repeatModeIndex, equals(0));
        expect(clearedState.filterKeyword, equals(''));
        expect(clearedState.isPlaying, isFalse);
        expect(clearedState.isShuffle, isFalse);
      });
    });

    group('Equality', () {
      test('should have same properties as identical state', () {
        final identicalState = MyPlayerStateModel(
          playlistId: 'test-playlist',
          currentPlayList: ['song1', 'song2', 'song3'],
          currentSongId: 'song2',
          previousSongId: 'song1',
          completedSongs: ['song1'],
          repeatModeIndex: 1,
          filterKeyword: 'test',
          isPlaying: true,
          isShuffle: true,
        );

        expect(testState.playlistId, equals(identicalState.playlistId));
        expect(testState.currentPlayList, equals(identicalState.currentPlayList));
        expect(testState.currentSongId, equals(identicalState.currentSongId));
        expect(testState.previousSongId, equals(identicalState.previousSongId));
        expect(testState.completedSongs, equals(identicalState.completedSongs));
        expect(testState.repeatModeIndex, equals(identicalState.repeatModeIndex));
        expect(testState.filterKeyword, equals(identicalState.filterKeyword));
        expect(testState.isPlaying, equals(identicalState.isPlaying));
        expect(testState.isShuffle, equals(identicalState.isShuffle));
      });

      test('should have different properties from different state', () {
        final differentState = testState.copyWith(currentSongId: 'different');
        expect(testState.currentSongId, isNot(equals(differentState.currentSongId)));
      });
    });

    group('Helper Methods', () {
      test('isEmpty should return true when no songs', () {
        final emptyState = MyPlayerStateModel();
        expect(emptyState.isEmpty, isTrue);
      });

      test('isEmpty should return false when has songs', () {
        expect(testState.isEmpty, isFalse);
      });

      test('hasSongs should return true when has songs', () {
        expect(testState.hasSongs, isTrue);
      });

      test('hasSongs should return false when no songs', () {
        final emptyState = MyPlayerStateModel();
        expect(emptyState.hasSongs, isFalse);
      });

      test('remainingSongs should return correct count', () {
        expect(testState.remainingSongs, equals(3));
      });

      test('completedCount should return correct count', () {
        expect(testState.completedCount, equals(1));
      });

      test('repeat mode helpers should work correctly', () {
        final repeatOffState = testState.copyWith(repeatModeIndex: 0);
        final repeatOneState = testState.copyWith(repeatModeIndex: 1);
        final loopState = testState.copyWith(repeatModeIndex: 2);

        expect(repeatOffState.isRepeatOff, isTrue);
        expect(repeatOffState.isRepeatOne, isFalse);
        expect(repeatOffState.isLoop, isFalse);

        expect(repeatOneState.isRepeatOff, isFalse);
        expect(repeatOneState.isRepeatOne, isTrue);
        expect(repeatOneState.isLoop, isFalse);

        expect(loopState.isRepeatOff, isFalse);
        expect(loopState.isRepeatOne, isFalse);
        expect(loopState.isLoop, isTrue);
      });

      test('repeatModeDescription should return correct descriptions', () {
        final repeatOffState = testState.copyWith(repeatModeIndex: 0);
        final repeatOneState = testState.copyWith(repeatModeIndex: 1);
        final loopState = testState.copyWith(repeatModeIndex: 2);

        expect(repeatOffState.repeatModeDescription, equals('Off'));
        expect(repeatOneState.repeatModeDescription, equals('Repeat One'));
        expect(loopState.repeatModeDescription, equals('Loop'));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final string = testState.toString();
        
        expect(string, contains('test-playlist'));
        expect(string, contains('song2'));
        expect(string, contains('3')); // currentPlayList length
        expect(string, contains('test')); // filterKeyword
      });
    });

    group('Edge Cases', () {
      test('should handle empty lists', () {
        final emptyState = MyPlayerStateModel(
          currentPlayList: [],
          completedSongs: [],
        );

        expect(emptyState.currentPlayList, isEmpty);
        expect(emptyState.completedSongs, isEmpty);
      });

      test('should handle large lists', () {
        final largeList = List.generate(1000, (index) => 'song$index');
        final largeState = MyPlayerStateModel(
          currentPlayList: largeList,
          completedSongs: largeList.take(100).toList(),
        );

        expect(largeState.currentPlayList.length, equals(1000));
        expect(largeState.completedSongs.length, equals(100));
      });

      test('should handle extreme repeat mode indices', () {
        final extremeState = testState.copyWith(repeatModeIndex: 999);
        expect(extremeState.repeatModeIndex, equals(999));
      });

      test('should handle long filter keywords', () {
        final longKeyword = 'a' * 1000;
        final longKeywordState = testState.copyWith(filterKeyword: longKeyword);
        expect(longKeywordState.filterKeyword, equals(longKeyword));
      });
    });
  });
}
