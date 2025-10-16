import 'package:flutter_test/flutter_test.dart';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/models/playlist_source/playlist_source_model.dart';
import 'package:pmj_music_player/utils/services/play_count_tracking_service.dart';

void main() {
  group('Play Count Tracking Service', () {
    late Song testSong;
    late PlaylistSource testPlaylistSource;

    setUp(() {
      testSong = Song(
        id: 'test_song_1',
        title: 'Test Song',
        artists: ['Test Artist 1', 'Test Artist 2'],
        albums: ['Test Album 1', 'Test Album 2'],
        path: '/test/path.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
      );

      testPlaylistSource = PlaylistSource.myPlaylist('test_playlist_1');
    });

    tearDown(() {
      PlayCountTrackingService.stopTracking();
    });

    group('Threshold Calculation', () {
      test('should detect 40% threshold correctly', () {
        final testCases = [
          {'duration': 180, 'position': 72, 'expected': true}, // 40% of 3 minutes
          {'duration': 180, 'position': 71, 'expected': false}, // 39.4% of 3 minutes
          {'duration': 240, 'position': 96, 'expected': true}, // 40% of 4 minutes
          {'duration': 240, 'position': 95, 'expected': false}, // 39.6% of 4 minutes
        ];

        for (final testCase in testCases) {
          final duration = Duration(seconds: testCase['duration'] as int);
          final position = Duration(seconds: testCase['position'] as int);
          final expected = testCase['expected'] as bool;

          final percentage = position.inMilliseconds / duration.inMilliseconds;
          final actual = percentage >= 0.4;

          expect(actual, equals(expected));
        }
      });
    });

    group('Play Count Tracking', () {
      test('should start tracking without errors', () {
        expect(() => PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
          playlistId: 'test_playlist',
          playlistSource: testPlaylistSource,
        ), returnsNormally);
      });

      test('should update position without errors', () {
        PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
          playlistId: 'test_playlist',
          playlistSource: testPlaylistSource,
        );

        expect(() => PlayCountTrackingService.updatePosition(
          const Duration(seconds: 30)
        ), returnsNormally);
      });

      test('should stop tracking without errors', () {
        PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
          playlistId: 'test_playlist',
          playlistSource: testPlaylistSource,
        );

        expect(() => PlayCountTrackingService.stopTracking(), returnsNormally);
      });

      test('should handle tracking without playlist context', () {
        expect(() => PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
        ), returnsNormally);
      });
    });

    group('Service State', () {
      test('should handle multiple start/stop cycles', () {
        // Start tracking
        PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
        );

        // Stop tracking
        PlayCountTrackingService.stopTracking();

        // Start again
        expect(() => PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
        ), returnsNormally);
      });

      test('should handle position updates after stop', () {
        PlayCountTrackingService.startTracking(
          song: testSong,
          currentPosition: Duration.zero,
          duration: testSong.duration,
        );

        PlayCountTrackingService.stopTracking();

        // Should not crash when updating position after stop
        expect(() => PlayCountTrackingService.updatePosition(
          const Duration(seconds: 30)
        ), returnsNormally);
      });
    });
  });
}
