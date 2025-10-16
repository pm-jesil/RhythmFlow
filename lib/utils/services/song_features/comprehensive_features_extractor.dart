import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import '../../models/song_features/song_features.dart';
import 'comprehensive_features_extractor_helper.dart';

/// ============================================================================
/// COMPREHENSIVE FEATURES EXTRACTOR - Main Service
/// ============================================================================
///
/// PURPOSE: Extract detailed music features using YAMNet AI model
///
/// WHEN TO USE: After all songs, albums, and artists are fetched
///
/// WORKFLOW:
/// 1. App starts → Songs/Albums/Artists fetched
/// 2. Initialize this service → ComprehensiveFeaturesExtractor.initialize()
/// 3. Extract features → ComprehensiveFeaturesExtractor.extractAllSongsFeatures()
/// 4. Features stored in Song.features → Auto-persisted by Hydrated Bloc
///
/// FEATURES EXTRACTED:
/// - Instruments (AI-detected): Piano, Guitar, Drums, etc.
/// - Genre (AI-classified): Rock, Pop, Jazz, Classical, etc.
/// - Mood (AI-analyzed): Happy, Sad, Calm, Energetic, etc.
/// - Tempo (Computed): BPM, tempo category
/// - Energy (Combined): Overall energy, intensity
/// - Beat (Analyzed): Beat strength, danceability
/// - Spectral (DSP): Centroid, rolloff, zero-crossing rate
///
/// STORAGE: Hydrated Bloc (no SQLite needed)
/// INDEPENDENCE: Fully standalone, no external service dependencies

/// Data model for passing feature extraction data to isolates
/// This allows us to pre-load assets in the main thread and pass them to isolates
class IsolateFeatureData {
  final Song song;
  final Uint8List yamnetModelBytes;
  final List<String> yamnetLabels;
  final String modelVersion;
  final Float32List? audioData; // Pre-processed audio data

  const IsolateFeatureData({
    required this.song,
    required this.yamnetModelBytes,
    required this.yamnetLabels,
    required this.modelVersion,
    this.audioData,
  });
}

class ComprehensiveFeaturesExtractor {
  static final AppLogger _logger = AppLogger('ComprehensiveFeaturesExtractor');

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  static Interpreter? _yamnetInterpreter;
  static List<YAMNetLabel> _yamnetLabels = [];
  static bool _isInitialized = false;
  static final Set<String> _processingSongs = <String>{};
  static bool _isBackgroundProcessing = false;
  
  // Pre-loaded data for isolates
  static Uint8List? _cachedModelBytes;
  static List<String>? _cachedLabels;

  static const String _modelVersion = '1.0.0';
  static const String _modelPath = 'assets/models/1.tflite';
  static const String _labelsPath = 'assets/models/yamnet_class_map.csv';

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Initialize the feature extractor (load model and labels)
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        _logger.d('✅ Already initialized');
        return true;
      }

      _logger.i('🚀 Initializing Comprehensive Features Extractor...');

      // Load YAMNet TFLite model
      _logger.d('📦 Loading YAMNet model from assets...');
      _yamnetInterpreter = await Interpreter.fromAsset(_modelPath);
      _logger.i('✅ YAMNet model loaded');

      // Cache model bytes for isolates
      _logger.d('📦 Caching model bytes for isolates...');
      _cachedModelBytes = await _getModelBytes();
      _logger.i('✅ Model bytes cached');

      // Log model details and validate
      FeatureExtractorHelper.logModelDetails(_yamnetInterpreter!);

      // Validate model compatibility
      if (!_validateModelCompatibility()) {
        _logger.w(
          '⚠️ Model compatibility issues detected - will use fallback mode',
        );
      }

      // Load YAMNet labels
      _logger.d('📋 Loading YAMNet labels...');
      final csvContent = await rootBundle.loadString(_labelsPath);
      _yamnetLabels = FeatureExtractorHelper.parseYAMNetLabels(csvContent);
      _logger.i('✅ Loaded ${_yamnetLabels.length} YAMNet labels');
      
      // Cache labels for isolates
      _logger.d('📋 Caching labels for isolates...');
      _cachedLabels = _yamnetLabels.map((label) => label.displayName).toList();
      _logger.i('✅ Labels cached');

      _isInitialized = true;
      _logger.i('✅ Initialization complete - Ready to extract features');

      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Initialization failed: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get cached model bytes for isolates
  static Uint8List? get cachedModelBytes {
    if (_cachedModelBytes == null) {
      _logger.w('⚠️ Model bytes not cached - ensure initialize() was called');
    }
    return _cachedModelBytes;
  }
  
  /// Get cached labels for isolates
  static List<String>? get cachedLabels {
    if (_cachedLabels == null) {
      _logger.w('⚠️ Labels not cached - ensure initialize() was called');
    }
    return _cachedLabels;
  }

  /// Get current processing state for monitoring
  static Map<String, dynamic> getProcessingState() {
    return {
      'isInitialized': _isInitialized,
      'isBackgroundProcessing': _isBackgroundProcessing,
      'processingSongsCount': _processingSongs.length,
      'processingSongs': _processingSongs.toList(),
      'cachedModelBytes': _cachedModelBytes != null,
      'cachedLabels': _cachedLabels != null,
      'yamnetLabelsCount': _yamnetLabels.length,
    };
  }

  /// Force cleanup of stuck processing states (emergency use)
  static void forceCleanupProcessingStates() {
    _logger.w('🧹 Force cleaning up processing states...');
    _processingSongs.clear();
    _isBackgroundProcessing = false;
    _logger.i('✅ Processing states force cleaned');
  }
  
  /// Get model bytes from asset
  static Future<Uint8List> _getModelBytes() async {
    final byteData = await rootBundle.load(_modelPath);
    return byteData.buffer.asUint8List();
  }

  /// Extract features from a single song
  static Future<Song> extractFeatures(Song song) async {
    try {
      // STEP 1: Pre-validation
      if (song.features != null &&
          FeatureExtractorHelper.isCompleteFeatures(
            song.features!,
            _modelVersion,
          )) {
        _logger.d('✅ Song already analyzed: ${song.title}');
        return song;
      }

      // STEP 2: Concurrency control
      if (_processingSongs.contains(song.id)) {
        _logger.d('⏳ Song already being processed: ${song.title}');
        return song;
      }

      _processingSongs.add(song.id);

      try {
        // STEP 3: Initialization check
        if (!_isInitialized || _yamnetInterpreter == null) {
          _logger.e('❌ Not initialized');
          return song;
        }

        _logger.i('🎵 Extracting features for: ${song.title}');

        // STEP 4: Validate audio file
        if (!await FeatureExtractorHelper.validateAudioFile(song.path)) {
          _logger.e('❌ Invalid audio file: ${song.path}');
          return song;
        }

        // STEP 5: Extract audio waveform
        final waveform = await extractAudioWaveform(song.path, song.duration);
        if (waveform == null) {
          _logger.e('❌ Failed to extract waveform: ${song.title}');
          return song;
        }

        // STEP 6: Run YAMNet analysis (with fallback)
        final yamnetResults = await _analyzeWithYAMNet(waveform);
        if (yamnetResults == null) {
          _logger.w('⚠️ YAMNet analysis failed, using fallback: ${song.title}');
          // Create minimal fallback results
          final signalFeatures = FeatureExtractorHelper.calculateSignalFeatures(
            waveform,
          );
          final fallbackResults = YAMNetResults(
            instruments: ['Unknown'],
            hasVocals: signalFeatures.energy > 0.3,
            genre: 'Unknown',
            energy: signalFeatures.energy,
            moodTags: ['Unknown'],
          );

          // Continue with fallback results
          final features = SongFeatures(
            // Basic categorical
            tempo: FeatureExtractorHelper.categorizeTempo(
              signalFeatures.tempoBpm,
            ),
            beat: FeatureExtractorHelper.categorizeBeat(
              signalFeatures.beatStrength,
            ),
            energy: FeatureExtractorHelper.categorizeEnergy(
              fallbackResults.energy,
            ),
            instruments: fallbackResults.instruments,
            vocals: fallbackResults.hasVocals
                ? FeatureExtractorHelper.categorizeVocals(
                    fallbackResults.energy,
                  )
                : null,
            mood: FeatureExtractorHelper.categorizeMood(
              fallbackResults.moodTags,
            ),

            // YAMNet results
            yamnetInstruments: fallbackResults.instruments,
            hasVocals: fallbackResults.hasVocals,
            estimatedGenre: fallbackResults.genre,
            yamnetEnergy: fallbackResults.energy,
            moodTags: fallbackResults.moodTags,

            // Signal processing
            tempoBpm: signalFeatures.tempoBpm,
            beatStrength: signalFeatures.beatStrength,
            signalEnergy: signalFeatures.energy,
            brightness: signalFeatures.brightness,
            danceability: signalFeatures.danceability,

            // Combined metrics
            overallEnergy: (fallbackResults.energy + signalFeatures.energy) / 2,
            intensity: signalFeatures.energy, // Use energy as intensity
            spectralCentroid: signalFeatures.spectralCentroid,
            spectralRolloff: signalFeatures.spectralRolloff,
            zeroCrossingRate: signalFeatures.zeroCrossingRate,

            // Metadata
            analyzedAt: DateTime.now(),
            modelVersion: _modelVersion,
          );

          final updatedSong = song.copyWith(features: features);
          _logger.i('✅ Features extracted (fallback mode): ${song.title}');
          return updatedSong;
        }

        // STEP 7: Calculate signal processing features
        final signalFeatures = FeatureExtractorHelper.calculateSignalFeatures(
          waveform,
        );

        // STEP 8: Create comprehensive features
        final features = SongFeatures(
          // Basic categorical
          tempo: FeatureExtractorHelper.categorizeTempo(
            signalFeatures.tempoBpm,
          ),
          beat: FeatureExtractorHelper.categorizeBeat(
            signalFeatures.beatStrength,
          ),
          energy: FeatureExtractorHelper.categorizeEnergy(yamnetResults.energy),
          instruments: yamnetResults.instruments,
          vocals: yamnetResults.hasVocals
              ? FeatureExtractorHelper.categorizeVocals(yamnetResults.energy)
              : null,
          mood: FeatureExtractorHelper.categorizeMood(yamnetResults.moodTags),

          // YAMNet results
          yamnetInstruments: yamnetResults.instruments,
          hasVocals: yamnetResults.hasVocals,
          estimatedGenre: yamnetResults.genre,
          yamnetEnergy: yamnetResults.energy,
          moodTags: yamnetResults.moodTags,

          // Signal processing
          tempoBpm: signalFeatures.tempoBpm,
          beatStrength: signalFeatures.beatStrength,
          signalEnergy: signalFeatures.energy,
          brightness: signalFeatures.brightness,
          danceability: signalFeatures.danceability,

          // Combined metrics
          overallEnergy: (yamnetResults.energy + signalFeatures.energy) / 2,
          intensity: FeatureExtractorHelper.calculateIntensity(
            yamnetResults,
            signalFeatures,
          ),
          spectralCentroid: signalFeatures.spectralCentroid,
          spectralRolloff: signalFeatures.spectralRolloff,
          zeroCrossingRate: signalFeatures.zeroCrossingRate,

          // Metadata
          analyzedAt: DateTime.now(),
          modelVersion: _modelVersion,
        );

        _logger.d(
          '✅ Features extracted -- Basic categorical: Tempo == ${FeatureExtractorHelper.categorizeTempo(signalFeatures.tempoBpm)} | Beat == ${FeatureExtractorHelper.categorizeBeat(signalFeatures.beatStrength)} | Energy == ${FeatureExtractorHelper.categorizeEnergy(yamnetResults.energy)} | Instruments == ${yamnetResults.instruments} | Vocals == ${yamnetResults.hasVocals ? FeatureExtractorHelper.categorizeVocals(yamnetResults.energy) : null} | Mood == ${FeatureExtractorHelper.categorizeMood(yamnetResults.moodTags)}',
        );
        _logger.d(
          '✅ Features extracted -- YAMNet results: Instruments == ${yamnetResults.instruments} | Has Vocals == ${yamnetResults.hasVocals} | Estimated Genre == ${yamnetResults.genre} | Energy == ${yamnetResults.energy} | Mood Tags == ${yamnetResults.moodTags}',
        );
        _logger.d(
          '✅ Features extracted -- Signal processing: Tempo BPM == ${signalFeatures.tempoBpm} | Beat Strength == ${signalFeatures.beatStrength} | Signal Energy == ${signalFeatures.energy} | Brightness == ${signalFeatures.brightness} | Danceability == ${signalFeatures.danceability}',
        );
        _logger.d(
          '✅ Features extracted -- Combined metrics: Overall Energy == ${features.overallEnergy} | Intensity == ${features.intensity} | Spectral Centroid == ${features.spectralCentroid} | Spectral Rolloff == ${features.spectralRolloff} | Zero Crossing Rate == ${features.zeroCrossingRate}',
        );

        // STEP 9: Update song (preserve audioEmbedding)
        final updatedSong = song.copyWith(
          features: features,
          updatedAt: DateTime.now(),
          audioEmbedding: song.audioEmbedding, // PRESERVE
        );

        _logger.i('✅ Features extracted: ${song.title}');
        _logger.d(
          '   Genre: ${features.estimatedGenre} | Energy: ${features.energy} | Tempo: ${features.tempoBpm.toStringAsFixed(0)} BPM',
        );

        return updatedSong;
      } finally {
        _processingSongs.remove(song.id);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error extracting features for ${song.title}: $e');
      _logger.e('Stack trace: $stackTrace');
      _processingSongs.remove(song.id);
      return song;
    }
  }

  /// Extract features from all songs (batch processing)
  static Future<List<Song>> extractSongsFeatures(
    List<Song> allSongs, {
    Function(int current, int total)? onProgress,
    Function(Song updatedSong)? onSongUpdated,
  }) async {
    _logger.i(
      '🤖 Starting async batch feature extraction for ${allSongs.length} songs',
    );

    try {
      // Filter songs needing analysis
      final songsNeedingAnalysis = allSongs.where((song) {
        return song.features == null ||
            !FeatureExtractorHelper.isCompleteFeatures(
              song.features!,
              _modelVersion,
            );
      }).toList();

      if (songsNeedingAnalysis.isEmpty) {
        _logger.i('✅ All songs already analyzed');
        return allSongs;
      }

      _logger.i(
        '🎵 Found ${songsNeedingAnalysis.length} songs needing analysis',
      );

      final updatedSongs = List<Song>.from(allSongs);
      
      // Use background extractor with proper async scheduling
      await extractFeaturesInBackground(
        songs: songsNeedingAnalysis,
        onSongUpdated: (updatedSong) {
          // Update in main list
          final index = updatedSongs.indexWhere(
            (s) => s.id == updatedSong.id,
          );
          if (index != -1) {
            updatedSongs[index] = updatedSong;
          }
          onSongUpdated?.call(updatedSong);
        },
        onProgress: (current, total) {
          onProgress?.call(current, total);
        },
        onCompleted: () {
          _logger.i('✅ Background feature extraction completed successfully');
        },
        onError: (error) {
          _logger.e('❌ Background extraction error: $error');
        },
      );

      _logger.i('✅ Async batch extraction completed');
      return updatedSongs;
    } catch (e) {
      _logger.e('❌ Batch extraction error: $e');
      return allSongs;
    }
  }

  /// Get extraction progress statistics
  static Map<String, dynamic> getExtractionProgress(List<Song> allSongs) {
    final total = allSongs.length;
    final analyzed = allSongs
        .where(
          (s) =>
              s.features != null &&
              FeatureExtractorHelper.isCompleteFeatures(
                s.features!,
                _modelVersion,
              ),
        )
        .length;

    return {
      'totalSongs': total,
      'analyzedSongs': analyzed,
      'pendingSongs': total - analyzed,
      'completionPercentage': total > 0 ? (analyzed / total * 100) : 0.0,
    };
  }

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      _logger.i('🧹 Disposing ComprehensiveFeaturesExtractor...');
      
      // Close interpreter safely
      if (_yamnetInterpreter != null) {
        try {
          _yamnetInterpreter!.close();
          _logger.d('✅ YAMNet interpreter closed');
        } catch (e) {
          _logger.w('⚠️ Error closing interpreter: $e');
        }
        _yamnetInterpreter = null;
      }
      
      // Clear all cached data and processing states
      _yamnetLabels.clear();
      _processingSongs.clear();
      _cachedModelBytes = null;
      _cachedLabels = null;
      _isBackgroundProcessing = false;
      _isInitialized = false;
      
      _logger.d('✅ All processing states cleared');
      
      _logger.i('✅ ComprehensiveFeaturesExtractor disposed successfully');
    } catch (e) {
      _logger.e('❌ Error disposing ComprehensiveFeaturesExtractor: $e');
      // Force reset state even if disposal fails
      _yamnetInterpreter = null;
      _yamnetLabels.clear();
      _processingSongs.clear();
      _cachedModelBytes = null;
      _cachedLabels = null;
      _isBackgroundProcessing = false;
      _isInitialized = false;
    }
  }

  // ============================================================================
  // PRIVATE METHODS - Audio Extraction
  // ============================================================================

  /// Extract audio waveform using FFmpeg
  static Future<Float32List?> extractAudioWaveform(
    String filePath,
    Duration duration,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.raw';

      // Calculate optimal start time (middle of song)
      final startTime = FeatureExtractorHelper.calculateMiddleStartTime(
        duration,
      );

      _logger.d(
        '🎵 Extracting audio: duration=${duration.inSeconds}s, start=${startTime.toStringAsFixed(1)}s',
      );

      // Build FFmpeg command
      final command = FeatureExtractorHelper.buildFFmpegCommand(
        filePath,
        outputPath,
        startTime,
      );

      // Execute FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final rawFile = File(outputPath);
        try {
          if (await rawFile.exists()) {
            final rawBytes = await rawFile.readAsBytes();
            await rawFile.delete(); // Clean up immediately

            if (rawBytes.isEmpty) {
              _logger.w('FFmpeg output empty, using fallback');
              return _extractFallbackWaveform(filePath);
            }

            final waveform = FeatureExtractorHelper.convertRawAudioToFloat32(
              rawBytes,
            );
            _logger.d('✅ Extracted ${waveform.length} samples');
            return waveform;
          } else {
            _logger.w('⚠️ FFmpeg output file not found, using fallback');
            return _extractFallbackWaveform(filePath);
          }
        } catch (fileError) {
          _logger.e('❌ Error reading FFmpeg output: $fileError');
          // Ensure cleanup even on error
          try {
            if (await rawFile.exists()) {
              await rawFile.delete();
            }
          } catch (cleanupError) {
            _logger.w('⚠️ Error cleaning up temp file: $cleanupError');
          }
          return _extractFallbackWaveform(filePath);
        }
      }

      _logger.w('⚠️ FFmpeg failed, using fallback');
      return _extractFallbackWaveform(filePath);
    } catch (e) {
      _logger.e('Error extracting audio: $e');
      return _extractFallbackWaveform(filePath);
    }
  }

  /// Fallback waveform extraction
  static Future<Float32List?> _extractFallbackWaveform(String filePath) async {
    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      const sampleRate = 16000;
      const duration = 3;
      const totalSamples = sampleRate * duration;

      final waveform = Float32List(totalSamples);

      for (int i = 0; i < totalSamples; i++) {
        final byteIndex = i % fileBytes.length;
        waveform[i] = (fileBytes[byteIndex] - 128) / 128.0 * 0.5;
      }

      _logger.d('✅ Generated fallback waveform: $totalSamples samples');
      return waveform;
    } catch (e) {
      _logger.e('Fallback extraction failed: $e');
      return null;
    }
  }

  // ============================================================================
  // PRIVATE METHODS - YAMNet Analysis
  // ============================================================================

  /// Analyze audio using YAMNet model
  static Future<YAMNetResults?> _analyzeWithYAMNet(Float32List waveform) async {
    try {
      if (_yamnetInterpreter == null) {
        _logger.e('❌ YAMNet interpreter not available');
        return _createFallbackResults(waveform);
      }

      _logger.d('🤖 Running YAMNet analysis...');

      // Prepare input (15,600 samples required by YAMNet)
      final inputWaveform = FeatureExtractorHelper.prepareYAMNetInput(waveform);

      // Run inference with proper error handling
      final input = [inputWaveform];
      // ✅ FIX: Create output with correct shape [1, 521]
      final output = [List.filled(521, 0.0)]; // 2D array: [1, 521]

      try {
        _yamnetInterpreter!.run(input, output);
      } catch (modelError) {
        _logger.e('⛔ Model inference error: $modelError');
        _logger.w('🔄 Falling back to signal processing only...');
        return _createFallbackResults(waveform);
      }

      // Extract and process scores
      final scores = output[0] as List<double>?;
      if (scores == null || scores.isEmpty) {
        _logger.e('❌ YAMNet output is null');
        return _createFallbackResults(waveform);
      }

      // Process scores to extract features
      return _processYAMNetOutput(scores);
    } catch (e) {
      _logger.e('⛔ YAMNet analysis error: $e');
      _logger.w('🔄 Falling back to signal processing only...');
      return _createFallbackResults(waveform);
    }
  }

  /// Validate model compatibility
  static bool _validateModelCompatibility() {
    try {
      if (_yamnetInterpreter == null) return false;

      final inputTensors = _yamnetInterpreter!.getInputTensors();
      final outputTensors = _yamnetInterpreter!.getOutputTensors();

      _logger.d('📊 Model input tensors: ${inputTensors.length}');
      _logger.d('📊 Model output tensors: ${outputTensors.length}');

      for (int i = 0; i < inputTensors.length; i++) {
        _logger.d(
          '📊 Input $i: shape=${inputTensors[i].shape}, type=${inputTensors[i].type}',
        );
      }

      for (int i = 0; i < outputTensors.length; i++) {
        _logger.d(
          '📊 Output $i: shape=${outputTensors[i].shape}, type=${outputTensors[i].type}',
        );
      }

      // Check if we have the expected input/output structure
      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        _logger.w('⚠️ Unexpected model structure');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('❌ Model validation error: $e');
      return false;
    }
  }

  /// Create fallback results when YAMNet fails
  static YAMNetResults _createFallbackResults(Float32List waveform) {
    _logger.i('🔄 Creating fallback features using signal processing...');

    // Calculate signal features for fallback
    final signalFeatures = FeatureExtractorHelper.calculateSignalFeatures(
      waveform,
    );

    // Enhanced fallback heuristics
    final instruments = _inferInstrumentsFromSignal(signalFeatures);
    final hasVocals = _inferVocalsFromSignal(signalFeatures);
    final genre = _inferGenreFromSignal(signalFeatures);
    final moodTags = _inferMoodFromSignal(signalFeatures);

    return YAMNetResults(
      instruments: instruments,
      hasVocals: hasVocals,
      genre: genre,
      energy: signalFeatures.energy,
      moodTags: moodTags,
    );
  }

  /// Infer instruments from signal features
  static List<String> _inferInstrumentsFromSignal(SignalFeatures signal) {
    final instruments = <String>[];

    // High spectral centroid suggests bright instruments
    if (signal.spectralCentroid > 0.7) {
      instruments.addAll(['Piano', 'Guitar', 'Violin']);
    } else if (signal.spectralCentroid > 0.4) {
      instruments.addAll(['Guitar', 'Bass']);
    } else {
      instruments.addAll(['Bass', 'Drums']);
    }

    // High zero crossing rate suggests percussive elements
    if (signal.zeroCrossingRate > 0.3) {
      instruments.add('Drums');
    }

    return instruments.isEmpty ? ['Unknown'] : instruments;
  }

  /// Infer vocals from signal features
  static bool _inferVocalsFromSignal(SignalFeatures signal) {
    // High zero crossing rate and moderate energy suggests vocals
    return signal.zeroCrossingRate > 0.2 &&
        signal.energy > 0.3 &&
        signal.energy < 0.8;
  }

  /// Infer genre from signal features
  static String _inferGenreFromSignal(SignalFeatures signal) {
    // High tempo and high energy suggests electronic/rock
    if (signal.tempoBpm > 120 && signal.energy > 0.7) {
      return 'Electronic music';
    }

    // High tempo and moderate energy suggests rock
    if (signal.tempoBpm > 100 && signal.energy > 0.5) {
      return 'Rock music';
    }

    // Low tempo and low energy suggests classical
    if (signal.tempoBpm < 80 && signal.energy < 0.4) {
      return 'Classical music';
    }

    // Moderate tempo suggests pop
    if (signal.tempoBpm >= 80 && signal.tempoBpm <= 120) {
      return 'Pop music';
    }

    return 'Unknown';
  }

  /// Infer mood from signal features
  static List<String> _inferMoodFromSignal(SignalFeatures signal) {
    final moodTags = <String>[];

    if (signal.energy > 0.7) {
      moodTags.add('energetic');
    } else if (signal.energy < 0.3) {
      moodTags.add('calm');
    } else {
      moodTags.add('neutral');
    }

    if (signal.tempoBpm > 120) {
      moodTags.add('upbeat');
    } else if (signal.tempoBpm < 80) {
      moodTags.add('relaxing');
    }

    return moodTags.isEmpty ? ['neutral'] : moodTags;
  }

  /// Process YAMNet output scores
  static YAMNetResults _processYAMNetOutput(List<double> scores) {
    final instruments = <String>[];
    final moodTags = <String>[];
    bool hasVocals = false;
    String genre = 'Unknown';
    double energy = 0.5;

    // Get top predictions
    final topIndices = FeatureExtractorHelper.getTopIndices(scores, 15);

    _logger.d('🔍 YAMNet Debug - Top 15 indices: $topIndices');
    _logger.d(
      '🔍 YAMNet Debug - Top scores: ${topIndices.map((i) => scores[i]).toList()}',
    );

    // If no indices found with threshold, try without threshold
    if (topIndices.isEmpty) {
      _logger.w('⚠️ No results with threshold, trying without threshold...');
      final allIndices = FeatureExtractorHelper.getTopIndicesWithThreshold(
        scores,
        15,
        0.0,
      );
      _logger.d('🔍 YAMNet Debug - All indices (no threshold): $allIndices');
      topIndices.addAll(allIndices);
    }

    for (final index in topIndices) {
      if (index >= _yamnetLabels.length) continue;

      final label = _yamnetLabels[index];
      final score = scores[index];

      _logger.d(
        '🔍 YAMNet Debug - Label: ${label.displayName} | Score: $score | isInstrument: ${label.isInstrument} | isVocal: ${label.isVocal} | isGenre: ${label.isGenre} | isMood: ${label.isMood}',
      );

      // FIXED: Add confidence thresholds for better accuracy
      const confidenceThreshold = 0.1; // Minimum confidence score
      
      if (score < confidenceThreshold) continue; // Skip low-confidence predictions
      
      // Categorize based on label type with confidence filtering
      if (label.isInstrument && instruments.length < 5 && score > 0.15) {
        instruments.add(label.displayName);
        _logger.d('✅ Added instrument: ${label.displayName} (confidence: $score)');
      } else if (label.isVocal && score > 0.2) {
        hasVocals = true;
        _logger.d('✅ Detected vocals: ${label.displayName} (confidence: $score)');
      } else if (label.isGenre && genre == 'Unknown' && score > 0.2) {
        genre = label.displayName;
        _logger.d('✅ Detected genre: ${label.displayName} (confidence: $score)');
      } else if (label.isMood && moodTags.length < 3 && score > 0.15) {
        moodTags.add(label.displayName);
        _logger.d('✅ Added mood: ${label.displayName} (confidence: $score)');
      }

      if (label.isEnergyRelated) {
        // FIXED: Use weighted average instead of max to capture all energy information
        energy = (energy + score) / 2;
        _logger.d('✅ Energy related: ${label.displayName} | Score: $score');
      }
    }

    _logger.d(
      '🔍 YAMNet Debug - Final results: instruments=$instruments, hasVocals=$hasVocals, genre=$genre, energy=$energy, moodTags=$moodTags',
    );

    // Ensure defaults
    if (instruments.isEmpty) instruments.add('Unknown');
    if (moodTags.isEmpty) moodTags.add('Neutral');

    return YAMNetResults(
      instruments: instruments,
      hasVocals: hasVocals,
      genre: genre,
      energy: energy.clamp(0.0, 1.0),
      moodTags: moodTags,
    );
  }

  // ============================================================================
  // BACKGROUND PROCESSING METHODS
  // ============================================================================

  /// Extract features in background with UI responsiveness
  static Future<void> extractFeaturesInBackground({
    required List<Song> songs,
    required Function(Song updatedSong) onSongUpdated,
    required Function(int current, int total) onProgress,
    Function()? onCompleted,
    Function(String error)? onError,
  }) async {
    if (_isBackgroundProcessing) {
      _logger.w('⚠️ Feature extraction already in progress');
      return;
    }

    _isBackgroundProcessing = true;
    _logger.i('🎵 Starting UI-responsive background feature extraction for ${songs.length} songs');
    
    try {
      final songsNeedingAnalysis = songs.where((song) {
        return song.features == null ||
            !FeatureExtractorHelper.isCompleteFeatures(song.features!, '1.0.0');
      }).toList();

      if (songsNeedingAnalysis.isEmpty) {
        _logger.i('✅ All songs already analyzed');
        onCompleted?.call();
        return;
      }

      _logger.i('🎵 Found ${songsNeedingAnalysis.length} songs needing analysis');

      // Process songs with proper async scheduling
      await _processSongsWithUIResponsiveness(
        songsNeedingAnalysis,
        onSongUpdated,
        onProgress,
      );
      
      _logger.i('✅ UI-responsive background extraction completed');
      onCompleted?.call();
    } catch (e) {
      _logger.e('❌ Error in UI-responsive background extraction: $e');
      onError?.call(e.toString());
    } finally {
      _isBackgroundProcessing = false;
    }
  }

  /// Process songs with UI responsiveness using proper async scheduling
  static Future<void> _processSongsWithUIResponsiveness(
    List<Song> songs,
    Function(Song updatedSong) onSongUpdated,
    Function(int current, int total) onProgress,
  ) async {
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      
      // Check if song is already being processed
      if (_processingSongs.contains(song.id)) {
        _logger.d('⏳ Song already being processed: ${song.title}');
        onProgress(i + 1, songs.length);
        continue;
      }
      
      // Add to processing set
      _processingSongs.add(song.id);
      
      try {
        _logger.d('🎵 Processing song ${i + 1}/${songs.length}: ${song.title}');
        
        // Extract features with proper async scheduling
        final updatedSong = await _extractFeaturesAsync(song);
        
        // Send updated song
        if (updatedSong.features != null) {
          _logger.d('🔄 Calling onSongUpdated for: ${updatedSong.title}');
          _logger.d('🔍 Features extracted: ${updatedSong.features != null ? "YES" : "NO"}');
          onSongUpdated(updatedSong);
        } else {
          _logger.w('⚠️ No features extracted for: ${updatedSong.title}');
        }
        
        // Send progress update
        onProgress(i + 1, songs.length);
        
        // Yield control to allow UI updates between songs
        await _yieldToUI();
        
      } catch (e) {
        _logger.e('❌ Error processing ${song.title}: $e');
        // Continue with next song
        continue;
      } finally {
        // CRITICAL: Always remove from processing set
        _processingSongs.remove(song.id);
        _logger.d('🧹 Cleaned up processing state for: ${song.title}');
      }
    }
  }

  /// Extract features using true isolates to prevent UI blocking
  static Future<Song> _extractFeaturesAsync(Song song) async {
    try {
      _logger.d('🔄 Starting isolate-based feature extraction for: ${song.title}');
      
      // Pre-load assets in main thread
      final isolateData = await _prepareIsolateData(song);
      
      // Use compute to run heavy processing in isolate
      final result = await compute(_extractFeaturesInIsolate, isolateData);
      
      _logger.d('✅ Isolate-based extraction completed for: ${song.title}');
      _logger.d('🔍 Result features: ${result.features != null ? "EXTRACTED" : "NULL"}');
      return result;
    } catch (e) {
      _logger.e('❌ Error in isolate-based extraction for ${song.title}: $e');
      // Return original song if extraction fails
      return song;
    }
  }

  /// Prepare data for isolate processing
  static Future<IsolateFeatureData> _prepareIsolateData(Song song) async {
    try {
      _logger.d('📦 Preparing isolate data for: ${song.title}');

      // Ensure ComprehensiveFeaturesExtractor is initialized
      if (!_isInitialized) {
        _logger.w('⚠️ Not initialized, attempting to initialize...');
        final initSuccess = await initialize();
        if (!initSuccess) {
          throw Exception('Failed to initialize ComprehensiveFeaturesExtractor');
        }
      }

      // Get pre-loaded model bytes and labels with validation
      final modelBytes = await _getYAMNetModelBytes();
      final labels = await _getYAMNetLabels();
      final modelVersion = '1.0.0';

      // Validate critical data
      if (modelBytes.isEmpty) {
        throw Exception('Model bytes are empty - initialization may have failed');
      }
      if (labels.isEmpty) {
        throw Exception('Labels are empty - initialization may have failed');
      }

      // Pre-process audio in main thread (FFmpeg can be used here)
      final audioData = await extractAudioWaveform(song.path, song.duration);
      if (audioData == null) {
        _logger.w('⚠️ Audio extraction failed, isolate will handle it');
      }

      return IsolateFeatureData(
        song: song,
        yamnetModelBytes: modelBytes,
        yamnetLabels: labels,
        modelVersion: modelVersion,
        audioData: audioData,
      );
    } catch (e) {
      _logger.e('❌ Error preparing isolate data: $e');
      rethrow;
    }
  }

  /// Get YAMNet model bytes (pre-loaded in main thread)
  static Future<Uint8List> _getYAMNetModelBytes() async {
    final modelBytes = _cachedModelBytes;
    if (modelBytes == null || modelBytes.isEmpty) {
      _logger.e('❌ Model bytes not cached or empty');
      throw Exception('Model bytes not cached - ensure ComprehensiveFeaturesExtractor is initialized');
    }
    _logger.d('✅ Retrieved ${modelBytes.length} model bytes');
    return modelBytes;
  }

  /// Get YAMNet labels (pre-loaded in main thread)
  static Future<List<String>> _getYAMNetLabels() async {
    final labels = _cachedLabels;
    if (labels == null || labels.isEmpty) {
      _logger.e('❌ Labels not cached or empty');
      throw Exception('Labels not cached - ensure ComprehensiveFeaturesExtractor is initialized');
    }
    _logger.d('✅ Retrieved ${labels.length} labels');
    return labels;
  }


  /// Yield control to the UI thread
  static Future<void> _yieldToUI() async {
    // Use multiple microtasks to ensure UI responsiveness
    await Future.microtask(() {});
    await Future.delayed(const Duration(milliseconds: 1));
    await Future.microtask(() {});
  }

  // ============================================================================
  // ISOLATE PROCESSING METHODS
  // ============================================================================

  /// Extract features in isolate using pre-loaded data (static function for compute)
  static Future<Song> _extractFeaturesInIsolate(IsolateFeatureData data) async {
    try {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.d('🔄 Starting isolate feature extraction for: ${data.song.title}');
      
      // Initialize TFLite interpreter with pre-loaded model bytes
      final interpreter = Interpreter.fromBuffer(data.yamnetModelBytes);
      
      // Extract features using the pre-loaded data
      final features = await _extractFeaturesWithPreloadedData(
        data.song,
        interpreter,
        data.yamnetLabels,
        data.modelVersion,
        data,
      );
      
      // Close interpreter
      interpreter.close();
      
      // Return updated song with features
      final updatedSong = data.song.copyWith(features: features);
      
      logger.d('✅ Isolate feature extraction completed for: ${data.song.title}');
      return updatedSong;
    } catch (e) {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.e('❌ Error in isolate feature extraction: $e');
      return data.song; // Return original song if extraction fails
    }
  }

  /// Extract features using pre-loaded model and labels
  static Future<SongFeatures?> _extractFeaturesWithPreloadedData(
    Song song,
    Interpreter interpreter,
    List<String> yamnetLabels,
    String modelVersion,
    IsolateFeatureData data,
  ) async {
    try {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.d('🎵 Extracting features for: ${song.title}');

      // Use pre-processed audio data from isolate data
      Float32List? audioData = data.audioData;
      if (audioData == null) {
        logger.w('⚠️ No pre-processed audio data available for ${song.title}');
        return null;
      }

      // Run YAMNet inference
      final yamnetResults = await _runYAMNetInference(interpreter, audioData);
      
      // Process results
      final features = _processYAMNetResults(yamnetResults, yamnetLabels);
      
      // Create comprehensive features with real calculations
      final energyString = features['energy'] as String;
      final tempoString = features['tempo'] as String;
      final energyDouble = _convertEnergyToDouble(energyString);
      final tempoDouble = _convertTempoToDouble(tempoString);
      
      // Calculate real signal features from audio data
      final signalFeatures = _calculateSignalFeaturesInIsolate(audioData);
      
      final songFeatures = SongFeatures(
        tempo: tempoString,
        beat: _categorizeBeatFromSignal(signalFeatures.beatStrength),
        energy: energyString,
        instruments: features['instruments'] as List<String>,
        vocals: features['hasVocals'] as bool ? 'Detected' : null,
        mood: features['mood'] as String,
        yamnetInstruments: features['instruments'] as List<String>,
        hasVocals: features['hasVocals'] as bool,
        estimatedGenre: features['genre'] as String,
        yamnetEnergy: energyDouble,
        moodTags: [features['mood'] as String],
        tempoBpm: tempoDouble,
        beatStrength: signalFeatures.beatStrength,
        signalEnergy: signalFeatures.energy,
        brightness: signalFeatures.spectralCentroid,
        danceability: _calculateDanceability(energyDouble, signalFeatures.tempoBpm),
        overallEnergy: (energyDouble + signalFeatures.energy) / 2,
        intensity: _calculateIntensity(energyDouble, signalFeatures.tempoBpm),
        spectralCentroid: signalFeatures.spectralCentroid,
        spectralRolloff: signalFeatures.spectralRolloff,
        zeroCrossingRate: signalFeatures.zeroCrossingRate,
        analyzedAt: DateTime.now(),
        modelVersion: modelVersion,
      );

      logger.d('✅ Features extracted successfully for: ${song.title}');
      return songFeatures;
    } catch (e) {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.e('❌ Error extracting features for ${song.title}: $e');
      return null;
    }
  }

  /// Run YAMNet inference
  static Future<List<double>> _runYAMNetInference(
    Interpreter interpreter,
    Float32List audioData,
  ) async {
    try {
      // Prepare input tensor
      final input = [audioData];
      final output = List.filled(521, 0.0).reshape([1, 521]);
      
      // Run inference
      interpreter.run(input, output);
      
      return output[0];
    } catch (e) {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.e('❌ Error running YAMNet inference: $e');
      return List.filled(521, 0.0);
    }
  }

  /// Process YAMNet results
  static Map<String, dynamic> _processYAMNetResults(
    List<double> results,
    List<String> labels,
  ) {
    try {
      // Find top predictions
      final indexedResults = results.asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topPredictions = indexedResults.take(10).toList();
      
      // Extract features
      final instruments = <String>[];
      bool hasVocals = false;
      String genre = 'Unknown';
      String mood = 'Neutral';
      double energy = 0.5;
      
      for (final prediction in topPredictions) {
        final label = labels[prediction.key];
        final score = prediction.value;
        
        if (score > 0.1) { // Threshold for relevance
          if (_isInstrument(label)) {
            instruments.add(label);
          }
          if (_isVocal(label)) {
            hasVocals = true;
          }
          if (_isGenre(label)) {
            genre = label;
          }
          if (_isMood(label)) {
            mood = label;
          }
        }
      }
      
      // Calculate energy from results
      energy = results.take(100).reduce((a, b) => a + b) / 100;
      
      return {
        'instruments': instruments,
        'hasVocals': hasVocals,
        'genre': genre,
        'mood': mood,
        'energy': energy > 0.7 ? 'High' : energy > 0.4 ? 'Medium' : 'Low',
        'tempo': energy > 0.7 ? 'Fast' : energy > 0.4 ? 'Medium' : 'Slow',
        'danceability': energy,
        // Note: Spectral features will be calculated from actual audio data
        'spectralCentroid': 0.0, // Will be overridden by real calculation
        'spectralRolloff': 0.0,  // Will be overridden by real calculation
        'zeroCrossingRate': 0.0, // Will be overridden by real calculation
      };
    } catch (e) {
      final logger = AppLogger('IsolateFeatureExtractor');
      logger.e('❌ Error processing YAMNet results: $e');
      return {
        'instruments': <String>[],
        'hasVocals': false,
        'genre': 'Unknown',
        'mood': 'Neutral',
        'energy': 'Medium',
        'tempo': 'Medium',
        'danceability': 0.5,
        // Note: Spectral features will be calculated from actual audio data
        'spectralCentroid': 0.0, // Will be overridden by real calculation
        'spectralRolloff': 0.0,  // Will be overridden by real calculation
        'zeroCrossingRate': 0.0, // Will be overridden by real calculation
      };
    }
  }

  /// Check if label is an instrument
  static bool _isInstrument(String label) {
    final instrumentKeywords = [
      'guitar', 'piano', 'drum', 'violin', 'bass', 'saxophone',
      'trumpet', 'flute', 'clarinet', 'organ', 'synthesizer'
    ];
    return instrumentKeywords.any((keyword) => label.toLowerCase().contains(keyword));
  }

  /// Check if label indicates vocals
  static bool _isVocal(String label) {
    final vocalKeywords = [
      'voice', 'vocal', 'singing', 'speech', 'talking', 'whispering'
    ];
    return vocalKeywords.any((keyword) => label.toLowerCase().contains(keyword));
  }

  /// Check if label is a genre
  static bool _isGenre(String label) {
    final genreKeywords = [
      'rock', 'pop', 'jazz', 'classical', 'blues', 'country',
      'electronic', 'hip hop', 'reggae', 'folk', 'metal'
    ];
    return genreKeywords.any((keyword) => label.toLowerCase().contains(keyword));
  }

  /// Check if label indicates mood
  static bool _isMood(String label) {
    final moodKeywords = [
      'happy', 'sad', 'calm', 'energetic', 'peaceful', 'melancholy',
      'upbeat', 'relaxing', 'exciting', 'dramatic'
    ];
    return moodKeywords.any((keyword) => label.toLowerCase().contains(keyword));
  }

  /// Convert energy string to double value
  static double _convertEnergyToDouble(String energy) {
    switch (energy.toLowerCase()) {
      case 'high':
        return 0.8;
      case 'medium':
        return 0.5;
      case 'low':
        return 0.2;
      default:
        return 0.5;
    }
  }

  /// Convert tempo string to double value (BPM)
  static double _convertTempoToDouble(String tempo) {
    switch (tempo.toLowerCase()) {
      case 'fast':
        return 140.0;
      case 'medium':
        return 120.0;
      case 'slow':
        return 80.0;
      default:
        return 120.0;
    }
  }

  /// Calculate real signal features in isolate
  static SignalFeatures _calculateSignalFeaturesInIsolate(Float32List audioData) {
    try {
      // Calculate RMS energy
      final energy = _calculateRMSEnergy(audioData);
      
      // Calculate tempo (simplified autocorrelation)
      final tempoBpm = _calculateTempoBPM(audioData);
      
      // Calculate beat strength
      final beatStrength = _calculateBeatStrength(audioData);
      
      // Calculate spectral features
      final spectralCentroid = _calculateSpectralCentroid(audioData);
      final spectralRolloff = _calculateSpectralRolloff(audioData);
      final zeroCrossingRate = _calculateZeroCrossingRate(audioData);
      
      return SignalFeatures(
        tempoBpm: tempoBpm,
        beatStrength: beatStrength,
        energy: energy,
        brightness: spectralCentroid,
        danceability: _calculateDanceabilityFromSignal(energy, tempoBpm),
        spectralCentroid: spectralCentroid,
        spectralRolloff: spectralRolloff,
        zeroCrossingRate: zeroCrossingRate,
      );
    } catch (e) {
      // Return default values if calculation fails
      return SignalFeatures(
        tempoBpm: 120.0,
        beatStrength: 0.5,
        energy: 0.5,
        brightness: 2000.0,
        danceability: 0.5,
        spectralCentroid: 2000.0,
        spectralRolloff: 4000.0,
        zeroCrossingRate: 0.1,
      );
    }
  }

  /// Calculate RMS energy
  static double _calculateRMSEnergy(Float32List audioData) {
    double sum = 0.0;
    for (final sample in audioData) {
      sum += sample * sample;
    }
    return math.sqrt(sum / audioData.length);
  }

  /// Calculate tempo using autocorrelation
  static double _calculateTempoBPM(Float32List audioData) {
    try {
      // Simplified tempo detection using autocorrelation
      final windowSize = math.min(4096, audioData.length);
      final window = audioData.take(windowSize).toList();
      
      double maxCorrelation = 0.0;
      int bestPeriod = 0;
      
      // Check periods from 0.1s to 2s (60-1200 BPM)
      for (int period = 16; period < windowSize ~/ 4; period++) {
        double correlation = 0.0;
        for (int i = 0; i < windowSize - period; i++) {
          correlation += window[i] * window[i + period];
        }
        
        if (correlation > maxCorrelation) {
          maxCorrelation = correlation;
          bestPeriod = period;
        }
      }
      
      if (bestPeriod > 0) {
        // Convert period to BPM (16000 Hz sample rate)
        final bpm = (16000.0 * 60.0) / bestPeriod;
        return math.max(60.0, math.min(200.0, bpm));
      }
      
      return 120.0; // Default tempo
    } catch (e) {
      return 120.0;
    }
  }

  /// Calculate beat strength
  static double _calculateBeatStrength(Float32List audioData) {
    try {
      // Calculate spectral flux for beat strength
      final windowSize = math.min(1024, audioData.length);
      final window = audioData.take(windowSize).toList();
      
      double flux = 0.0;
      for (int i = 1; i < window.length; i++) {
        final diff = window[i] - window[i - 1];
        flux += diff > 0 ? diff : 0;
      }
      
      return math.min(1.0, flux / window.length);
    } catch (e) {
      return 0.5;
    }
  }

  /// Calculate spectral centroid
  static double _calculateSpectralCentroid(Float32List audioData) {
    try {
      // Simplified spectral centroid calculation
      final windowSize = math.min(1024, audioData.length);
      final window = audioData.take(windowSize).toList();
      
      double weightedSum = 0.0;
      double magnitudeSum = 0.0;
      
      for (int i = 0; i < window.length; i++) {
        final magnitude = window[i].abs();
        weightedSum += i * magnitude;
        magnitudeSum += magnitude;
      }
      
      return magnitudeSum > 0 ? (weightedSum / magnitudeSum) * 2000.0 : 2000.0;
    } catch (e) {
      return 2000.0;
    }
  }

  /// Calculate spectral rolloff
  static double _calculateSpectralRolloff(Float32List audioData) {
    try {
      final windowSize = math.min(1024, audioData.length);
      final window = audioData.take(windowSize).toList();
      
      // Calculate total energy
      double totalEnergy = 0.0;
      for (final sample in window) {
        totalEnergy += sample * sample;
      }
      
      // Find 85% energy rolloff point
      double cumulativeEnergy = 0.0;
      for (int i = 0; i < window.length; i++) {
        cumulativeEnergy += window[i] * window[i];
        if (cumulativeEnergy >= 0.85 * totalEnergy) {
          return (i / window.length) * 8000.0; // Scale to frequency range
        }
      }
      
      return 4000.0;
    } catch (e) {
      return 4000.0;
    }
  }

  /// Calculate zero crossing rate
  static double _calculateZeroCrossingRate(Float32List audioData) {
    try {
      int crossings = 0;
      for (int i = 1; i < audioData.length; i++) {
        if ((audioData[i] >= 0) != (audioData[i - 1] >= 0)) {
          crossings++;
        }
      }
      return crossings / (audioData.length - 1);
    } catch (e) {
      return 0.1;
    }
  }

  /// Categorize beat from signal strength
  static String _categorizeBeatFromSignal(double beatStrength) {
    if (beatStrength > 0.7) return 'Strong';
    if (beatStrength > 0.4) return 'Medium';
    return 'Weak';
  }

  /// Calculate danceability from energy and tempo
  static double _calculateDanceability(double energy, double tempo) {
    // Danceability based on energy and tempo
    final tempoFactor = math.min(1.0, tempo / 140.0);
    final energyFactor = energy;
    return (tempoFactor + energyFactor) / 2;
  }

  /// Calculate danceability from signal features
  static double _calculateDanceabilityFromSignal(double energy, double tempo) {
    return _calculateDanceability(energy, tempo);
  }

  /// Calculate intensity from energy and tempo
  static double _calculateIntensity(double energy, double tempo) {
    // Intensity combines energy and tempo
    final tempoIntensity = math.min(1.0, tempo / 160.0);
    return (energy + tempoIntensity) / 2;
  }
}
