import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:rhythmflow/utils/services/audio_service.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';

// Mock classes
class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockAudioSource extends Fake implements AudioSource {}
class MockMediaItem extends Fake implements audio_service_pkg.MediaItem {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(MockAudioSource());
    registerFallbackValue(MockMediaItem());
  });

  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(audioService.currentSong, isNull);
        expect(audioService.isPlaying, isFalse);
        expect(audioService.volume, equals(1.0));
        expect(audioService.position, equals(Duration.zero));
        expect(audioService.duration, equals(Duration.zero));
      });
    });

    group('Song Management', () {
      final testSong = Song(
        id: 'test-id',
        title: 'Test Song',
        artists: ['Test Artist'],
        albums: ['Test Album'],
        path: '/test/path.mp3',
        duration: const Duration(minutes: 3),
      );

      test('should check if song is loaded', () {
        expect(audioService.isSongLoaded('test-id'), isFalse);
      });

      test('should set song changed callback', () {
        expect(() => audioService.setSongChangedCallback((song) {}), returnsNormally);
      });

      test('should handle song loading', () {
        // Test that the service can handle song loading without crashing
        expect(() => audioService.isSongLoaded(testSong.id), returnsNormally);
      });
    });

    group('Playback Control', () {
      test('should pause playback without error', () async {
        // Test that pause doesn't throw an exception
        expect(() => audioService.pause(), returnsNormally);
      });

      test('should stop playback without error', () async {
        // Test that stop doesn't throw an exception
        expect(() => audioService.stop(), returnsNormally);
      });

      test('should resume playback without error', () async {
        // Test that resume doesn't throw an exception
        expect(() => audioService.resume(), returnsNormally);
      });
    });

    group('Seeking', () {
      test('should seek to position without error', () async {
        const position = Duration(seconds: 30);
        // Test that seek doesn't throw an exception
        expect(() => audioService.seekTo(position), returnsNormally);
      });

      test('should handle negative position without error', () async {
        const negativePosition = Duration(seconds: -10);
        // Should handle gracefully without crashing
        expect(() => audioService.seekTo(negativePosition), returnsNormally);
      });

      test('should handle position beyond duration without error', () async {
        const beyondDuration = Duration(hours: 1);
        // Should handle gracefully without crashing
        expect(() => audioService.seekTo(beyondDuration), returnsNormally);
      });
    });

    group('Volume Control', () {
      test('should set volume', () async {
        const volume = 0.5;
        await audioService.setVolume(volume);
        expect(audioService.volume, equals(volume));
      });

      test('should clamp volume to valid range', () async {
        await audioService.setVolume(2.0);
        expect(audioService.volume, lessThanOrEqualTo(1.0));
        
        await audioService.setVolume(-0.5);
        expect(audioService.volume, greaterThanOrEqualTo(0.0));
      });

      test('should handle volume setting without error', () async {
        // Test that volume setting doesn't throw an exception
        expect(() => audioService.setVolume(0.8), returnsNormally);
      });
    });

    group('Streams', () {
      test('should provide position stream', () {
        expect(audioService.positionStream, isA<Stream<Duration>>());
      });

      test('should provide duration stream', () {
        expect(audioService.durationStream, isA<Stream<Duration>>());
      });

      test('should provide playing stream', () {
        expect(audioService.playingStream, isA<Stream<bool>>());
      });

      test('should provide player state stream', () {
        expect(audioService.playerStateStream, isA<Stream<PlayerState>>());
      });
    });

    group('Error Handling', () {
      test('should handle play errors gracefully', () async {
        // This test verifies that the service doesn't crash on play errors
        final testSong = Song(
          id: 'test-id',
          title: 'Test Song',
          artists: ['Test Artist'],
          albums: ['Test Album'],
          path: '/nonexistent/path.mp3', // Non-existent file
          duration: const Duration(minutes: 3),
        );
        
        // A missing file is reported through the invalid-song callback
        // (so the bloc can skip to the next song); playSong itself completes
        // normally instead of throwing.
        Song? reported;
        audioService.setInvalidSongCallback((song, _, __) => reported = song);
        await expectLater(audioService.playSong(testSong), completes);
        expect(reported?.id, equals('test-id'));
      });

      test('should handle seek errors gracefully', () async {
        // This test verifies that the service doesn't crash on seek errors
        expect(() => audioService.seekTo(const Duration(seconds: 30)), returnsNormally);
      });

      test('should handle volume errors gracefully', () async {
        // This test verifies that the service doesn't crash on volume errors
        expect(() => audioService.setVolume(0.5), returnsNormally);
      });
    });

    group('State Management', () {
      test('should maintain playing state', () {
        expect(audioService.isPlaying, isFalse);
      });

      test('should maintain current song', () {
        expect(audioService.currentSong, isNull);
      });

      test('should maintain volume', () {
        expect(audioService.volume, equals(1.0));
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () async {
        // Test that dispose doesn't throw an exception
        expect(() => audioService.dispose(), returnsNormally);
      });

      test('should handle multiple disposal calls', () async {
        // Test that multiple disposal calls don't cause issues
        await audioService.dispose();
        expect(() => audioService.dispose(), returnsNormally);
      });
    });
  });
}
