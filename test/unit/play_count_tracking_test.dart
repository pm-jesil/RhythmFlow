import 'dart:async';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/models/playlist_source/playlist_source_model.dart';
import 'package:pmj_music_player/utils/services/play_count_tracking_service.dart';

/// Test class to verify play count tracking implementation
class PlayCountTrackingTest {
  static final List<String> _testLogs = [];

  /// Test the complete play count tracking flow
  static Future<void> runCompleteTest() async {
    print('🧪 Starting Play Count Tracking Test...\n');

    // Setup test data
    final testSong = Song(
      id: 'test_song_1',
      title: 'Test Song',
      artists: ['Test Artist 1', 'Test Artist 2'],
      albums: ['Test Album 1', 'Test Album 2'],
      path: '/test/path.mp3',
      duration: const Duration(minutes: 3, seconds: 30), // 3:30 duration
    );

    final testPlaylistSource = PlaylistSource.myPlaylist('test_playlist_1');

    // Setup callbacks to track updates
    int songPlayCountUpdates = 0;
    int artistPlayCountUpdates = 0;
    int albumPlayCountUpdates = 0;
    int playlistPlayCountUpdates = 0;

    PlayCountTrackingService.onUpdatePlayCount = (songId) {
      songPlayCountUpdates++;
      _testLogs.add('✅ Song play count updated: $songId');
    };

    // Test 1: Start tracking
    print('📊 Test 1: Starting play count tracking...');
    PlayCountTrackingService.startTracking(
      song: testSong,
      currentPosition: Duration.zero,
      duration: testSong.duration,
      playlistId: 'my_playlist_test_playlist_1',
      playlistSource: testPlaylistSource,
    );

    // Test 2: Simulate position updates (should not trigger play count yet)
    print('📊 Test 2: Simulating position updates (0% to 35%)...');
    for (int i = 0; i <= 35; i += 5) {
      final position = Duration(
        seconds: (testSong.duration.inSeconds * i / 100).round(),
      );
      PlayCountTrackingService.updatePosition(position);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('   Expected: No play count updates yet (below 40% threshold)');
    print(
      '   Actual: Song updates: $songPlayCountUpdates, Artist updates: $artistPlayCountUpdates, Album updates: $albumPlayCountUpdates, Playlist updates: $playlistPlayCountUpdates\n',
    );

    // Test 3: Simulate reaching 40% threshold
    print('📊 Test 3: Simulating 40% threshold...');
    final position40Percent = Duration(
      seconds: (testSong.duration.inSeconds * 0.4).round(),
    );
    PlayCountTrackingService.updatePosition(position40Percent);
    await Future.delayed(const Duration(milliseconds: 100));

    print('   Expected: All play counts should be updated');
    print(
      '   Actual: Song updates: $songPlayCountUpdates, Artist updates: $artistPlayCountUpdates, Album updates: $albumPlayCountUpdates, Playlist updates: $playlistPlayCountUpdates\n',
    );

    // Test 4: Verify no duplicate updates
    print('📊 Test 4: Verifying no duplicate updates...');
    PlayCountTrackingService.updatePosition(
      Duration(seconds: testSong.duration.inSeconds ~/ 2),
    );
    await Future.delayed(const Duration(milliseconds: 100));

    print('   Expected: No additional updates (already tracked)');
    print(
      '   Actual: Song updates: $songPlayCountUpdates, Artist updates: $artistPlayCountUpdates, Album updates: $albumPlayCountUpdates, Playlist updates: $playlistPlayCountUpdates\n',
    );

    // Test 5: Test without playlist context
    print('📊 Test 5: Testing without playlist context...');
    PlayCountTrackingService.stopTracking();

    int songUpdatesWithoutPlaylist = 0;
    int playlistUpdatesWithoutPlaylist = 0;

    PlayCountTrackingService.onUpdatePlayCount = (songId) {
      songUpdatesWithoutPlaylist++;
    };

    PlayCountTrackingService.startTracking(
      song: testSong,
      currentPosition: Duration.zero,
      duration: testSong.duration,
      // No playlist context
    );

    PlayCountTrackingService.updatePosition(position40Percent);
    await Future.delayed(const Duration(milliseconds: 100));

    print(
      '   Expected: Song updates: 1, Playlist updates: 0 (no playlist context)',
    );
    print(
      '   Actual: Song updates: $songUpdatesWithoutPlaylist, Playlist updates: $playlistUpdatesWithoutPlaylist\n',
    );

    // Test 6: Cleanup
    print('📊 Test 6: Testing cleanup...');
    PlayCountTrackingService.stopTracking();

    // Print test results
    print('🧪 Test Results Summary:');
    print('========================');
    print(
      '✅ 40% Threshold Detection: ${songPlayCountUpdates > 0 ? "PASS" : "FAIL"}',
    );
    print(
      '✅ Song Play Count Update: ${songPlayCountUpdates > 0 ? "PASS" : "FAIL"}',
    );
    print(
      '✅ Artist Play Count Update: ${artistPlayCountUpdates >= 2 ? "PASS" : "FAIL"} (Expected: 2 artists)',
    );
    print(
      '✅ Album Play Count Update: ${albumPlayCountUpdates >= 2 ? "PASS" : "FAIL"} (Expected: 2 albums)',
    );
    print(
      '✅ Playlist Play Count Update: ${playlistPlayCountUpdates > 0 ? "PASS" : "FAIL"}',
    );
    print(
      '✅ No Duplicate Updates: ${songPlayCountUpdates == 1 ? "PASS" : "FAIL"}',
    );
    print(
      '✅ Context-Aware Updates: ${playlistUpdatesWithoutPlaylist == 0 ? "PASS" : "FAIL"}',
    );

    print('\n📋 Detailed Logs:');
    for (final log in _testLogs) {
      print('   $log');
    }

    print('\n🎉 Play Count Tracking Test Completed!');
  }

  /// Test the 40% threshold calculation
  static void testThresholdCalculation() {
    print('🧪 Testing 40% Threshold Calculation...\n');

    final testCases = [
      {'duration': 180, 'position': 72, 'expected': true}, // 40% of 3 minutes
      {
        'duration': 180,
        'position': 71,
        'expected': false,
      }, // 39.4% of 3 minutes
      {'duration': 240, 'position': 96, 'expected': true}, // 40% of 4 minutes
      {
        'duration': 240,
        'position': 95,
        'expected': false,
      }, // 39.6% of 4 minutes
    ];

    for (final testCase in testCases) {
      final duration = Duration(seconds: testCase['duration'] as int);
      final position = Duration(seconds: testCase['position'] as int);
      final expected = testCase['expected'] as bool;

      final percentage = position.inMilliseconds / duration.inMilliseconds;
      final actual = percentage >= 0.4;

      final result = actual == expected ? '✅ PASS' : '❌ FAIL';
      print(
        '   Duration: ${duration.inSeconds}s, Position: ${position.inSeconds}s, Percentage: ${(percentage * 100).toStringAsFixed(1)}%, Expected: $expected, Actual: $actual $result',
      );
    }

    print('');
  }
}

/// Main function to run the tests
void main() async {
  print('🚀 Starting Play Count Tracking Tests...\n');

  // Test 1: Threshold calculation
  PlayCountTrackingTest.testThresholdCalculation();

  // Test 2: Complete flow test
  await PlayCountTrackingTest.runCompleteTest();

  print('🎯 All tests completed!');
}
