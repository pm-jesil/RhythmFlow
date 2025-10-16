/// ============================================================================
/// TEST CONFIGURATION
/// ============================================================================
/// 
/// PURPOSE: Centralized configuration for all feature extraction tests
/// 
/// This file contains shared configuration, constants, and utilities
/// used across all test files.

import 'dart:async';

/// Test configuration constants
class TestConfig {
  // Test timeouts
  static const Duration shortTimeout = Duration(milliseconds: 100);
  static const Duration mediumTimeout = Duration(milliseconds: 500);
  static const Duration longTimeout = Duration(milliseconds: 2000);
  
  // Test data
  static const int smallSongCount = 5;
  static const int mediumSongCount = 50;
  static const int largeSongCount = 1000;
  
  // Test paths
  static const String testAudioPath = '/test/audio/';
  static const String testMusicPath = '/test/music/';
  
  // Test titles
  static const String normalTitle = 'Test Song';
  static const String specialCharTitle = 'Test Song with émojis 🎵🎶 and spëcial chars';
  static String get longTitle => 'A' * 1000;
  
  // Test artists
  static const String normalArtist = 'Test Artist';
  static const String specialCharArtist = 'Artist with ñ and ümlauts';
  static String get longArtist => 'B' * 1000;
  
  // Test albums
  static const String normalAlbum = 'Test Album';
  static const String specialCharAlbum = 'Album with "quotes" and \'apostrophes\'';
  static String get longAlbum => 'C' * 1000;
}

/// Test utilities
class TestUtils {
  /// Create a test song with specified parameters
  static Map<String, dynamic> createTestSong({
    required String id,
    String title = TestConfig.normalTitle,
    String artist = TestConfig.normalArtist,
    String album = TestConfig.normalAlbum,
    String path = '/test/song.mp3',
    Duration duration = const Duration(minutes: 3),
    Map<String, dynamic>? features,
  }) {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration,
      'features': features,
    };
  }
  
  /// Create a list of test songs
  static List<Map<String, dynamic>> createTestSongs(int count, {
    bool withFeatures = false,
    bool withSpecialChars = false,
    bool withLongTitles = false,
  }) {
    return List.generate(count, (index) {
      String title = TestConfig.normalTitle;
      String artist = TestConfig.normalArtist;
      String album = TestConfig.normalAlbum;
      
      if (withSpecialChars) {
        title = TestConfig.specialCharTitle;
        artist = TestConfig.specialCharArtist;
        album = TestConfig.specialCharAlbum;
      } else if (withLongTitles) {
        title = TestConfig.longTitle;
        artist = TestConfig.longArtist;
        album = TestConfig.longAlbum;
      }
      
      return createTestSong(
        id: '$index',
        title: title,
        artist: artist,
        album: album,
        path: '${TestConfig.testAudioPath}song$index.mp3',
        features: withFeatures ? createTestFeatures() : null,
      );
    });
  }
  
  /// Create test features
  static Map<String, dynamic> createTestFeatures() {
    return {
      'instruments': ['Piano', 'Guitar'],
      'genre': 'Pop',
      'mood': 'Happy',
      'tempo': 120,
      'energy': 0.7,
      'beat': 0.8,
      'spectralCentroid': 1000.0,
      'spectralRolloff': 2000.0,
      'zeroCrossingRate': 0.1,
    };
  }
  
  /// Wait for a condition to be true
  static Future<bool> waitForCondition(
    bool Function() condition, {
    Duration timeout = TestConfig.mediumTimeout,
    Duration interval = const Duration(milliseconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      if (condition()) {
        return true;
      }
      await Future.delayed(interval);
    }
    
    return false;
  }
  
  /// Run a test with timeout
  static Future<T> runWithTimeout<T>(
    Future<T> Function() test, {
    Duration timeout = TestConfig.longTimeout,
  }) async {
    return await test().timeout(timeout);
  }
  
  /// Log test results
  static void logTestResult(String testName, bool passed, {String? error}) {
    if (passed) {
      print('✅ PASS: $testName');
    } else {
      print('❌ FAIL: $testName${error != null ? ' - $error' : ''}');
    }
  }
  
  /// Log test suite results
  static void logTestSuiteResults({
    required String suiteName,
    required int passed,
    required int failed,
    required List<String> failedTests,
  }) {
    print('\n📊 $suiteName RESULTS');
    print('=' * 40);
    print('✅ Tests Passed: $passed');
    print('❌ Tests Failed: $failed');
    print('📈 Success Rate: ${(passed / (passed + failed) * 100).toStringAsFixed(1)}%');
    
    if (failed > 0) {
      print('\n⚠️ FAILED TESTS:');
      for (String failedTest in failedTests) {
        print('   - $failedTest');
      }
    }
  }
}

/// Test data generators
class TestDataGenerator {
  /// Generate normal test songs
  static List<Map<String, dynamic>> generateNormalSongs(int count) {
    return TestUtils.createTestSongs(count);
  }
  
  /// Generate songs with special characters
  static List<Map<String, dynamic>> generateSpecialCharSongs(int count) {
    return TestUtils.createTestSongs(count, withSpecialChars: true);
  }
  
  /// Generate songs with long titles
  static List<Map<String, dynamic>> generateLongTitleSongs(int count) {
    return TestUtils.createTestSongs(count, withLongTitles: true);
  }
  
  /// Generate songs with existing features
  static List<Map<String, dynamic>> generateProcessedSongs(int count) {
    return TestUtils.createTestSongs(count, withFeatures: true);
  }
  
  /// Generate mixed song library
  static List<Map<String, dynamic>> generateMixedLibrary({
    int newSongs = 5,
    int processedSongs = 3,
    int specialCharSongs = 2,
    int longTitleSongs = 1,
  }) {
    List<Map<String, dynamic>> songs = [];
    
    // Add new songs (without features)
    songs.addAll(TestUtils.createTestSongs(newSongs));
    
    // Add processed songs (with features)
    songs.addAll(TestUtils.createTestSongs(processedSongs, withFeatures: true));
    
    // Add special character songs
    songs.addAll(TestUtils.createTestSongs(specialCharSongs, withSpecialChars: true));
    
    // Add long title songs
    songs.addAll(TestUtils.createTestSongs(longTitleSongs, withLongTitles: true));
    
    return songs;
  }
}

/// Test assertions
class TestAssertions {
  static bool assertTrue(bool condition, String message) {
    if (!condition) {
      print('❌ ASSERTION FAILED: $message');
    }
    return condition;
  }
  
  static bool assertFalse(bool condition, String message) {
    if (condition) {
      print('❌ ASSERTION FAILED: $message');
    }
    return !condition;
  }
  
  static bool assertNotNull(dynamic value, String message) {
    if (value == null) {
      print('❌ ASSERTION FAILED: $message');
      return false;
    }
    return true;
  }
  
  static bool assertNull(dynamic value, String message) {
    if (value != null) {
      print('❌ ASSERTION FAILED: $message');
      return false;
    }
    return true;
  }
  
  static bool assertEquals(dynamic expected, dynamic actual, String message) {
    if (expected != actual) {
      print('❌ ASSERTION FAILED: $message (Expected: $expected, Actual: $actual)');
      return false;
    }
    return true;
  }
  
  static bool assertNotEquals(dynamic expected, dynamic actual, String message) {
    if (expected == actual) {
      print('❌ ASSERTION FAILED: $message (Expected: $expected, Actual: $actual)');
      return false;
    }
    return true;
  }
  
  static bool assertGreaterThan(dynamic value, dynamic threshold, String message) {
    if (value <= threshold) {
      print('❌ ASSERTION FAILED: $message (Value: $value, Threshold: $threshold)');
      return false;
    }
    return true;
  }
  
  static bool assertLessThan(dynamic value, dynamic threshold, String message) {
    if (value >= threshold) {
      print('❌ ASSERTION FAILED: $message (Value: $value, Threshold: $threshold)');
      return false;
    }
    return true;
  }
  
  static bool assertGreaterThanOrEqual(dynamic value, dynamic threshold, String message) {
    if (value < threshold) {
      print('❌ ASSERTION FAILED: $message (Value: $value, Threshold: $threshold)');
      return false;
    }
    return true;
  }
  
  static bool assertLessThanOrEqual(dynamic value, dynamic threshold, String message) {
    if (value > threshold) {
      print('❌ ASSERTION FAILED: $message (Value: $value, Threshold: $threshold)');
      return false;
    }
    return true;
  }
}

/// Test environment setup
class TestEnvironment {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🧪 Initializing test environment...');
    
    // Setup test environment
    _isInitialized = true;
    
    print('✅ Test environment initialized');
  }
  
  static Future<void> cleanup() async {
    if (!_isInitialized) return;
    
    print('🧹 Cleaning up test environment...');
    
    // Cleanup test environment
    _isInitialized = false;
    
    print('✅ Test environment cleaned up');
  }
  
  static bool get isInitialized => _isInitialized;
}
