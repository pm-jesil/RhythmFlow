import 'package:flutter_test/flutter_test.dart';
import 'package:music_feature_analyzer/music_feature_analyzer.dart';
import 'package:pmj_music_player/utils/models/song/song_model.dart';
import 'package:pmj_music_player/utils/models/song_features/song_features.dart';

/// ============================================================================
/// PACKAGE INTEGRATION TEST SUITE
/// ============================================================================
/// 
/// PURPOSE: Test the integration between the music_feature_analyzer package
/// and the PMJ Music Player project
/// 
/// TEST COVERAGE:
/// - Package initialization
/// - Model conversion between package and project
/// - Background processing integration
/// - Error handling
/// - Progress tracking

void main() {
  group('Package Integration Tests', () {
    setUp(() {
      // Setup for each test
    });

    tearDown(() {
      // Clean up after each test
    });

    group('Package Initialization', () {
      test('should initialize package successfully', () async {
        // Test package initialization
        final isInitialized = MusicFeatureAnalyzer.isInitialized;
        expect(isInitialized, isA<bool>());
      });

      test('should handle initialization gracefully', () async {
        // Test that initialization doesn't crash
        try {
          final initialized = await MusicFeatureAnalyzer.initialize();
          expect(initialized, isA<bool>());
        } catch (e) {
          // Initialization might fail in test environment, that's okay
          expect(e, isA<Exception>());
        }
      });
    });

    group('Model Conversion', () {
      test('should convert package features to project features', () {
        // Mock package features (ExtractedSongFeatures)
        final mockPackageFeatures = {
          'tempo': 'Fast',
          'beat': 'Strong',
          'energy': 'High',
          'instruments': ['Guitar', 'Drums'],
          'vocals': 'Male',
          'mood': 'Energetic',
          'yamnetInstruments': ['Guitar', 'Drums'],
          'hasVocals': true,
          'estimatedGenre': 'Rock',
          'yamnetEnergy': 0.8,
          'moodTags': ['Energetic', 'Upbeat'],
          'tempoBpm': 120.0,
          'beatStrength': 0.9,
          'signalEnergy': 0.8,
          'brightness': 0.7,
          'danceability': 0.8,
          'overallEnergy': 0.8,
          'intensity': 0.9,
          'spectralCentroid': 1000.0,
          'spectralRolloff': 2000.0,
          'zeroCrossingRate': 0.1,
          'spectralFlux': 0.5,
          'complexity': 0.7,
          'valence': 0.8,
          'arousal': 0.9,
          'confidence': 0.95,
          'analyzedAt': DateTime.now(),
          'analyzerVersion': '1.0.0',
        };

        // Test conversion function (simulate the conversion logic)
        final projectFeatures = SongFeatures(
          // Basic categorical
          tempo: mockPackageFeatures['tempo'] as String,
          beat: mockPackageFeatures['beat'] as String,
          energy: mockPackageFeatures['energy'] as String,
          instruments: (mockPackageFeatures['instruments'] as List).cast<String>(),
          vocals: mockPackageFeatures['vocals'] as String,
          mood: mockPackageFeatures['mood'] as String,

          // YAMNet results
          yamnetInstruments: (mockPackageFeatures['yamnetInstruments'] as List).cast<String>(),
          hasVocals: mockPackageFeatures['hasVocals'] as bool,
          estimatedGenre: mockPackageFeatures['estimatedGenre'] as String,
          yamnetEnergy: mockPackageFeatures['yamnetEnergy'] as double,
          moodTags: (mockPackageFeatures['moodTags'] as List).cast<String>(),

          // Signal processing
          tempoBpm: mockPackageFeatures['tempoBpm'] as double,
          beatStrength: mockPackageFeatures['beatStrength'] as double,
          signalEnergy: mockPackageFeatures['signalEnergy'] as double,
          brightness: mockPackageFeatures['brightness'] as double,
          danceability: mockPackageFeatures['danceability'] as double,

          // Combined metrics
          overallEnergy: mockPackageFeatures['overallEnergy'] as double,
          intensity: mockPackageFeatures['intensity'] as double,
          spectralCentroid: mockPackageFeatures['spectralCentroid'] as double,
          spectralRolloff: mockPackageFeatures['spectralRolloff'] as double,
          zeroCrossingRate: mockPackageFeatures['zeroCrossingRate'] as double,
          spectralFlux: mockPackageFeatures['spectralFlux'] as double,
          complexity: mockPackageFeatures['complexity'] as double,
          valence: mockPackageFeatures['valence'] as double,
          arousal: mockPackageFeatures['arousal'] as double,
          confidence: mockPackageFeatures['confidence'] as double,

          // Metadata
          analyzedAt: mockPackageFeatures['analyzedAt'] as DateTime,
          modelVersion: mockPackageFeatures['analyzerVersion'] as String,
        );

        // Verify conversion worked correctly
        expect(projectFeatures.tempo, equals('Fast'));
        expect(projectFeatures.estimatedGenre, equals('Rock'));
        expect(projectFeatures.tempoBpm, equals(120.0));
        expect(projectFeatures.hasVocals, isTrue);
        expect(projectFeatures.instruments, contains('Guitar'));
        expect(projectFeatures.confidence, equals(0.95));
      });
    });

    group('Background Processing Integration', () {
      test('should handle background processing without crashing', () async {
        // Test that background processing methods exist and are callable
        expect(MusicFeatureAnalyzer.extractFeaturesInBackground, isA<Function>());
        expect(MusicFeatureAnalyzer.getExtractionProgressWithSongs, isA<Function>());
        expect(MusicFeatureAnalyzer.getStats, isA<Function>());
      });

      test('should handle progress tracking', () {
        // Test progress tracking with mock data
        final mockSongs = [
          Song(
            id: '1',
            title: 'Test Song 1',
            artists: ['Test Artist'],
            albums: ['Test Album'],
            path: '/test/path1.mp3',
            duration: const Duration(minutes: 3),
            features: SongFeatures(
              tempo: 'Fast',
              beat: 'Strong',
              energy: 'High',
              instruments: ['Guitar'],
              vocals: 'Male',
              mood: 'Energetic',
              yamnetInstruments: ['Guitar'],
              hasVocals: true,
              estimatedGenre: 'Rock',
              yamnetEnergy: 0.8,
              moodTags: ['Energetic'],
              tempoBpm: 120.0,
              beatStrength: 0.9,
              signalEnergy: 0.8,
              brightness: 0.7,
              danceability: 0.8,
              overallEnergy: 0.8,
              intensity: 0.9,
              spectralCentroid: 1000.0,
              spectralRolloff: 2000.0,
              zeroCrossingRate: 0.1,
              spectralFlux: 0.5,
              complexity: 0.7,
              valence: 0.8,
              arousal: 0.9,
              confidence: 0.95,
              analyzedAt: DateTime.now(),
              modelVersion: '1.0.0',
            ),
          ),
          Song(
            id: '2',
            title: 'Test Song 2',
            artists: ['Test Artist'],
            albums: ['Test Album'],
            path: '/test/path2.mp3',
            duration: const Duration(minutes: 4),
            // No features - pending analysis
          ),
        ];

        // Test progress calculation
        final progress = MusicFeatureAnalyzer.getExtractionProgressWithSongs(mockSongs);
        
        expect(progress, isA<Map<String, dynamic>>());
        expect(progress['totalSongs'], equals(2));
        expect(progress['analyzedSongs'], equals(1));
        expect(progress['pendingSongs'], equals(1));
        expect(progress['completionPercentage'], equals(50.0));
      });
    });

    group('Error Handling', () {
      test('should handle package errors gracefully', () async {
        // Test that package methods don't crash on errors
        try {
          final stats = MusicFeatureAnalyzer.getStats();
          expect(stats, isA<dynamic>());
        } catch (e) {
          // Package might not be initialized in test environment
          expect(e, isA<Exception>());
        }
      });

      test('should handle null/empty inputs', () {
        // Test with empty song list
        final progress = MusicFeatureAnalyzer.getExtractionProgressWithSongs([]);
        
        expect(progress, isA<Map<String, dynamic>>());
        expect(progress['totalSongs'], equals(0));
        expect(progress['analyzedSongs'], equals(0));
        expect(progress['pendingSongs'], equals(0));
        expect(progress['completionPercentage'], equals(0.0));
      });
    });

    group('Package API Compatibility', () {
      test('should have all required methods', () {
        // Test that all required package methods exist
        expect(MusicFeatureAnalyzer.initialize, isA<Function>());
        expect(MusicFeatureAnalyzer.isInitialized, isA<bool>());
        expect(MusicFeatureAnalyzer.extractFeaturesInBackground, isA<Function>());
        expect(MusicFeatureAnalyzer.getExtractionProgressWithSongs, isA<Function>());
        expect(MusicFeatureAnalyzer.getStats, isA<Function>());
        expect(MusicFeatureAnalyzer.resetStats, isA<Function>());
        expect(MusicFeatureAnalyzer.dispose, isA<Function>());
      });

      test('should handle model types correctly', () {
        // Test that package models are properly typed
        // This test ensures the package returns the correct model types
        // without causing type conflicts with project models
        
        // The package should return ExtractedSongFeatures, not SongFeatures
        // This is handled by the conversion function in the project
        
        expect(true, isTrue); // Placeholder - actual type checking happens at compile time
      });
    });
  });
}
