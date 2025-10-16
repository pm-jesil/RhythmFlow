import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../logger/logger.dart';
import '../../models/song_features/song_features.dart';

/// ============================================================================
/// COMPREHENSIVE FEATURES EXTRACTOR HELPER
/// ============================================================================
/// 
/// PURPOSE: Utility functions and helpers for feature extraction
/// 
/// CONTAINS:
/// - YAMNet label parsing and categorization
/// - Signal processing algorithms (DSP)
/// - Feature categorization logic
/// - Validation and utility functions
class FeatureExtractorHelper {
  static final AppLogger _logger = AppLogger('FeatureExtractorHelper');
  
  // ============================================================================
  // YAMNET LABEL HANDLING
  // ============================================================================
  
  /// Parse YAMNet labels from CSV content
  static List<YAMNetLabel> parseYAMNetLabels(String csvContent) {
    final labels = <YAMNetLabel>[];
    final lines = csvContent.split('\n');
    
    // Skip header
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 3) {
        final index = int.tryParse(parts[0].trim()) ?? i - 1;
        final mid = parts[1].trim().replaceAll('"', '');
        final displayName = parts[2].trim().replaceAll('"', '');
        
        labels.add(YAMNetLabel(
          index: index,
          mid: mid,
          displayName: displayName,
        ));
      }
    }
    
    return labels;
  }
  
  /// Log model details for debugging
  static void logModelDetails(Interpreter interpreter) {
    try {
      final inputTensors = interpreter.getInputTensors();
      final outputTensors = interpreter.getOutputTensors();
      
      _logger.d('📊 Model Details:');
      _logger.d('   Inputs: ${inputTensors.length}');
      for (int i = 0; i < inputTensors.length; i++) {
        _logger.d('   Input[$i]: ${inputTensors[i].shape} - ${inputTensors[i].type}');
      }
      
      _logger.d('   Outputs: ${outputTensors.length}');
      for (int i = 0; i < outputTensors.length; i++) {
        _logger.d('   Output[$i]: ${outputTensors[i].shape} - ${outputTensors[i].type}');
      }
    } catch (e) {
      _logger.w('Could not log model details: $e');
    }
  }
  
  // ============================================================================
  // AUDIO FILE VALIDATION
  // ============================================================================
  
  /// Validate audio file
  static Future<bool> validateAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        _logger.e('File not found: $filePath');
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        _logger.e('File is empty: $filePath');
        return false;
      }
      
      final extension = filePath.toLowerCase().split('.').last;
      const supportedFormats = ['mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'wma', 'aiff'];
      
      if (!supportedFormats.contains(extension)) {
        _logger.w('Unsupported format: $extension');
        // Don't return false - FFmpeg might still handle it
      }
      
      return true;
    } catch (e) {
      _logger.e('Validation error: $e');
      return false;
    }
  }
  
  // ============================================================================
  // AUDIO PROCESSING UTILITIES
  // ============================================================================
  
  /// Calculate optimal start time from middle of song
  static double calculateMiddleStartTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    
    if (totalSeconds < 6) return 0.0;
    if (totalSeconds < 15) return totalSeconds * 0.25;
    if (totalSeconds < 60) return totalSeconds * 0.30;
    if (totalSeconds < 600) return totalSeconds * 0.35;
    if (totalSeconds < 1800) return totalSeconds * 0.25;
    if (totalSeconds < 3600) return totalSeconds * 0.20;
    return totalSeconds * 0.15;
  }
  
  /// Build FFmpeg command for audio extraction
  static String buildFFmpegCommand(String inputPath, String outputPath, double startTime) {
    return [
      '-y',
      '-ss', startTime.toStringAsFixed(1),
      '-i', '"$inputPath"',
      '-t', '0.975',
      '-f', 's16le',
      '-ar', '16000',
      '-ac', '1',
      '-avoid_negative_ts', 'make_zero',
      '-fflags', '+genpts',
      '"$outputPath"'
    ].join(' ');
  }
  
  /// Convert raw audio bytes to Float32List
  static Float32List convertRawAudioToFloat32(Uint8List rawBytes) {
    final samples = rawBytes.length ~/ 2;
    final waveform = Float32List(samples);
    
    for (int i = 0; i < samples; i++) {
      final byte1 = rawBytes[i * 2];
      final byte2 = rawBytes[i * 2 + 1];
      final sample = (byte2 << 8) | byte1;
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      waveform[i] = signedSample / 32768.0;
    }
    
    return waveform;
  }
  
  /// Prepare YAMNet input (ensure 15,600 samples)
  static Float32List prepareYAMNetInput(Float32List waveform) {
    const expectedSamples = 15600;
    
    if (waveform.length == expectedSamples) {
      return waveform;
    } else if (waveform.length > expectedSamples) {
      return Float32List.sublistView(waveform, 0, expectedSamples);
    } else {
      final padded = Float32List(expectedSamples);
      for (int i = 0; i < waveform.length; i++) {
        padded[i] = waveform[i];
      }
      return padded;
    }
  }
  
  // ============================================================================
  // SIGNAL PROCESSING - Digital Signal Processing Algorithms
  // ============================================================================
  
  /// Calculate comprehensive signal features
  static SignalFeatures calculateSignalFeatures(Float32List waveform) {
    final energy = _calculateEnergy(waveform);
    final spectralCentroid = _calculateSpectralCentroid(waveform);
    final spectralRolloff = _calculateSpectralRolloff(waveform);
    final zeroCrossingRate = _calculateZeroCrossingRate(waveform);
    final tempoBpm = _estimateTempo(waveform);
    final beatStrength = _calculateBeatStrength(waveform);
    final brightness = spectralCentroid;
    final danceability = _calculateDanceability(waveform, tempoBpm);
    
    return SignalFeatures(
      tempoBpm: tempoBpm,
      beatStrength: beatStrength,
      energy: energy,
      brightness: brightness,
      danceability: danceability,
      spectralCentroid: spectralCentroid,
      spectralRolloff: spectralRolloff,
      zeroCrossingRate: zeroCrossingRate,
    );
  }
  
  /// Calculate RMS energy
  static double _calculateEnergy(Float32List waveform) {
    double sum = 0.0;
    for (final sample in waveform) {
      sum += sample * sample;
    }
    return math.sqrt(sum / waveform.length);
  }
  
  /// Calculate spectral centroid (frequency center of mass) - FIXED with proper FFT
  static double _calculateSpectralCentroid(Float32List waveform) {
    try {
      // Apply windowing and perform FFT
      final windowed = _applyHannWindow(waveform);
      final fft = _performFFT(windowed);
      final magnitudes = _calculateMagnitudeSpectrumFromFFT(fft);
      
      if (magnitudes.isEmpty) return 0.0;
      
      double weightedSum = 0.0;
      double magnitudeSum = 0.0;
      
      for (int i = 0; i < magnitudes.length; i++) {
        final magnitude = magnitudes[i];
        weightedSum += i * magnitude;
        magnitudeSum += magnitude;
      }
      
      // Convert to frequency in Hz (sample rate = 16000)
      final frequencyBin = magnitudeSum > 0 ? weightedSum / magnitudeSum : 0.0;
      return (frequencyBin / magnitudes.length) * 8000.0; // Nyquist frequency
    } catch (e) {
      return 2000.0; // Safe fallback
    }
  }
  
  /// Calculate spectral rolloff (85% energy threshold) - FIXED with proper FFT
  static double _calculateSpectralRolloff(Float32List waveform) {
    try {
      // Apply windowing and perform FFT
      final windowed = _applyHannWindow(waveform);
      final fft = _performFFT(windowed);
      final magnitudes = _calculateMagnitudeSpectrumFromFFT(fft);
      
      if (magnitudes.isEmpty) return 0.0;
      
      // Calculate total energy
      final totalEnergy = magnitudes.fold<double>(0.0, (sum, mag) => sum + mag);
      final threshold = 0.85 * totalEnergy;
      
      // Find 85% energy rolloff point
      double cumulativeEnergy = 0.0;
      for (int i = 0; i < magnitudes.length; i++) {
        cumulativeEnergy += magnitudes[i];
        if (cumulativeEnergy >= threshold) {
          // Convert to frequency in Hz
          return (i / magnitudes.length) * 8000.0; // Nyquist frequency
        }
      }
      return 8000.0; // Full spectrum
    } catch (e) {
      return 4000.0; // Safe fallback
    }
  }
  
  /// Calculate zero crossing rate
  static double _calculateZeroCrossingRate(Float32List waveform) {
    int crossings = 0;
    for (int i = 1; i < waveform.length; i++) {
      if (waveform[i] * waveform[i - 1] < 0) {
        crossings++;
      }
    }
    return crossings / waveform.length;
  }
  
  /// Estimate tempo in BPM using autocorrelation
  static double _estimateTempo(Float32List waveform) {
    // Apply windowing for better analysis
    final windowed = _applyHannWindow(waveform);
    
    // Calculate autocorrelation
    final autocorr = _calculateAutocorrelation(windowed);
    
    // Find peaks in autocorrelation
    final peaks = _findPeaks(autocorr);
    
    if (peaks.isEmpty) {
      // FIXED: Use musical analysis instead of arbitrary formula
      return _estimateTempoFromRhythmicPattern(waveform);
    }
    
    // Find the most prominent peak (likely tempo)
    final maxPeakIndex = peaks.reduce((a, b) => autocorr[a] > autocorr[b] ? a : b);
    final sampleRate = 16000.0; // YAMNet sample rate
    final tempo = (sampleRate / maxPeakIndex) * 60.0;
    
    // Clamp to reasonable tempo range
    return tempo.clamp(60.0, 200.0);
  }
  
  /// Calculate beat strength - IMPROVED with onset detection
  static double _calculateBeatStrength(Float32List waveform) {
    try {
      const windowSize = 1024;
      const hopSize = 512;
      
      if (waveform.length < windowSize * 2) return 0.5;
      
      // Calculate spectral flux (onset detection)
      final energies = <double>[];
      final spectralFlux = <double>[];
      
      for (int i = 0; i < waveform.length - windowSize; i += hopSize) {
        final window = waveform.sublist(i, i + windowSize);
        final windowed = _applyHannWindow(Float32List.fromList(window));
        final fft = _performFFT(windowed);
        final magnitudes = _calculateMagnitudeSpectrumFromFFT(fft);
        
        // Calculate energy in different frequency bands
        final lowEnergy = magnitudes.take(magnitudes.length ~/ 4).fold(0.0, (sum, mag) => sum + mag);
        final midEnergy = magnitudes.skip(magnitudes.length ~/ 4).take(magnitudes.length ~/ 2).fold(0.0, (sum, mag) => sum + mag);
        final highEnergy = magnitudes.skip(3 * magnitudes.length ~/ 4).fold(0.0, (sum, mag) => sum + mag);
        
        final totalEnergy = lowEnergy + midEnergy + highEnergy;
        energies.add(totalEnergy);
        
        // Calculate spectral flux (difference from previous frame)
        if (energies.length > 1) {
          final flux = math.max(0.0, totalEnergy - energies[energies.length - 2]);
          spectralFlux.add(flux);
        }
      }
      
      if (spectralFlux.isEmpty) return 0.5;
      
      // Beat strength is based on spectral flux peaks
      final meanFlux = spectralFlux.reduce((a, b) => a + b) / spectralFlux.length;
      final fluxVariance = spectralFlux.map((f) => math.pow(f - meanFlux, 2)).reduce((a, b) => a + b) / spectralFlux.length;
      
      // Normalize to 0-1 range
      return math.min(fluxVariance / (meanFlux + 1e-6), 1.0);
    } catch (e) {
      return 0.5; // Safe fallback
    }
  }
  
  /// Calculate danceability
  static double _calculateDanceability(Float32List waveform, double tempo) {
    final beatStrength = _calculateBeatStrength(waveform);
    final tempoFactor = math.min(tempo / 120.0, 1.0);
    return (beatStrength + tempoFactor) / 2;
  }
  
  /// Apply Hann window to reduce spectral leakage
  static Float32List _applyHannWindow(Float32List waveform) {
    final windowed = Float32List(waveform.length);
    for (int i = 0; i < waveform.length; i++) {
      final windowValue = 0.5 * (1 - math.cos(2 * math.pi * i / (waveform.length - 1)));
      windowed[i] = waveform[i] * windowValue;
    }
    return windowed;
  }
  
  
  /// Perform FFT using Cooley-Tukey algorithm
  static List<Complex> _performFFT(Float32List signal) {
    final n = signal.length;
    if (n == 1) return [Complex(signal[0], 0)];
    
    // Pad to power of 2
    final paddedLength = _nextPowerOf2(n);
    final padded = Float32List(paddedLength);
    for (int i = 0; i < n; i++) {
      padded[i] = signal[i];
    }
    
    return _fftRecursive(padded);
  }
  
  /// Recursive FFT implementation
  static List<Complex> _fftRecursive(Float32List signal) {
    final n = signal.length;
    if (n == 1) return [Complex(signal[0], 0)];
    
    // Split into even and odd
    final even = <double>[];
    final odd = <double>[];
    for (int i = 0; i < n; i += 2) {
      even.add(signal[i]);
      if (i + 1 < n) odd.add(signal[i + 1]);
    }
    
    final evenFFT = _fftRecursive(Float32List.fromList(even));
    final oddFFT = _fftRecursive(Float32List.fromList(odd));
    
    final result = List<Complex>.filled(n, Complex(0, 0));
    final halfN = n ~/ 2;
    
    for (int k = 0; k < halfN; k++) {
      final t = oddFFT[k] * Complex(math.cos(-2 * math.pi * k / n), math.sin(-2 * math.pi * k / n));
      result[k] = evenFFT[k] + t;
      result[k + halfN] = evenFFT[k] - t;
    }
    
    return result;
  }
  
  /// Calculate magnitude spectrum from FFT result
  static List<double> _calculateMagnitudeSpectrumFromFFT(List<Complex> fft) {
    return fft.map((c) => math.sqrt(c.real * c.real + c.imaginary * c.imaginary)).toList();
  }
  
  /// Find next power of 2
  static int _nextPowerOf2(int n) {
    if (n <= 0) return 1;
    if ((n & (n - 1)) == 0) return n;
    return 1 << (n.bitLength);
  }
  
  /// Calculate autocorrelation function
  static List<double> _calculateAutocorrelation(Float32List signal) {
    final n = signal.length;
    final autocorr = <double>[];
    
    for (int lag = 0; lag < n ~/ 2; lag++) {
      double sum = 0.0;
      for (int i = 0; i < n - lag; i++) {
        sum += signal[i] * signal[i + lag];
      }
      autocorr.add(sum / (n - lag));
    }
    
    return autocorr;
  }
  
  /// Find peaks in autocorrelation function
  static List<int> _findPeaks(List<double> autocorr) {
    final peaks = <int>[];
    const minPeakDistance = 10; // Minimum distance between peaks
    const minPeakHeight = 0.1; // Minimum peak height
    
    for (int i = 1; i < autocorr.length - 1; i++) {
      // Check if it's a local maximum
      if (autocorr[i] > autocorr[i - 1] && 
          autocorr[i] > autocorr[i + 1] &&
          autocorr[i] > minPeakHeight) {
        
        // Check distance from previous peaks
        bool tooClose = false;
        for (final peak in peaks) {
          if ((i - peak).abs() < minPeakDistance) {
            tooClose = true;
            break;
          }
        }
        
        if (!tooClose) {
          peaks.add(i);
        }
      }
    }
    
    return peaks;
  }
  
  /// Estimate tempo from rhythmic pattern analysis (musical approach)
  static double _estimateTempoFromRhythmicPattern(Float32List waveform) {
    try {
      // Analyze energy variations to find rhythmic patterns
      const windowSize = 1024;
      final energies = <double>[];
      
      for (int i = 0; i < waveform.length - windowSize; i += windowSize ~/ 2) {
        final window = waveform.sublist(i, i + windowSize);
        energies.add(_calculateEnergy(Float32List.fromList(window)));
      }
      
      if (energies.length < 4) return 120.0; // Default tempo
      
      // Find energy peaks (potential beats)
      final peaks = <int>[];
      for (int i = 1; i < energies.length - 1; i++) {
        if (energies[i] > energies[i - 1] && energies[i] > energies[i + 1]) {
          peaks.add(i);
        }
      }
      
      if (peaks.length < 2) return 120.0; // Default tempo
      
      // Calculate average time between peaks
      double totalInterval = 0.0;
      for (int i = 1; i < peaks.length; i++) {
        totalInterval += peaks[i] - peaks[i - 1];
      }
      final avgInterval = totalInterval / (peaks.length - 1);
      
      // Convert to BPM (sample rate = 16000, window hop = 512)
      final timePerWindow = 512.0 / 16000.0; // seconds per window
      final intervalSeconds = avgInterval * timePerWindow;
      final bpm = 60.0 / intervalSeconds;
      
      // Clamp to reasonable range
      return bpm.clamp(60.0, 200.0);
    } catch (e) {
      return 120.0; // Safe fallback
    }
  }
  
  // ============================================================================
  // FEATURE CATEGORIZATION
  // ============================================================================
  
  /// Categorize tempo BPM into readable category
  static String categorizeTempo(double bpm) {
    if (bpm < 60) return 'Very Slow';
    if (bpm < 90) return 'Slow';
    if (bpm < 120) return 'Moderate';
    if (bpm < 140) return 'Fast';
    return 'Very Fast';
  }
  
  /// Categorize beat strength
  static String categorizeBeat(double strength) {
    if (strength < 0.3) return 'Soft';
    if (strength < 0.7) return 'Medium';
    return 'Strong';
  }
  
  /// Categorize energy level
  static String categorizeEnergy(double energy) {
    if (energy < 0.25) return 'Low';
    if (energy < 0.5) return 'Medium';
    if (energy < 0.75) return 'High';
    return 'Very High';
  }
  
  /// Categorize vocals style
  static String categorizeVocals(double energy) {
    if (energy < 0.3) return 'Soft';
    if (energy < 0.7) return 'Moderate';
    return 'Energetic';
  }
  
  /// Categorize overall mood
  static String categorizeMood(List<String> moodTags) {
    if (moodTags.isEmpty) return 'Neutral';
    
    final positive = ['happy', 'upbeat', 'energetic', 'joyful', 'cheerful'];
    final negative = ['sad', 'melancholy', 'dark', 'somber', 'gloomy'];
    final calm = ['calm', 'peaceful', 'relaxing', 'serene', 'tranquil'];
    
    for (final tag in moodTags) {
      final lower = tag.toLowerCase();
      if (positive.any((m) => lower.contains(m))) return 'Happy';
      if (negative.any((m) => lower.contains(m))) return 'Sad';
      if (calm.any((m) => lower.contains(m))) return 'Calm';
    }
    
    return 'Neutral';
  }
  
  /// Calculate intensity (combined metric)
  static double calculateIntensity(YAMNetResults yamnet, SignalFeatures signal) {
    return (
      yamnet.energy * 0.3 +
      signal.energy * 0.3 +
      (signal.tempoBpm / 200.0) * 0.2 +
      signal.beatStrength * 0.2
    ).clamp(0.0, 1.0);
  }
  
  // ============================================================================
  // VALIDATION UTILITIES
  // ============================================================================
  
  /// Check if features are complete and up-to-date
  static bool isCompleteFeatures(SongFeatures features, String currentModelVersion) {
    // A feature is complete if it has:
    // 1. Matching model version
    // 2. Non-empty genre (can be "Unknown")
    // Note: analyzedAt is non-nullable, so we don't need to check it
    return features.modelVersion == currentModelVersion &&
           features.estimatedGenre.isNotEmpty;
  }
  
  /// Get top N indices from scores array with confidence thresholding
  static List<int> getTopIndices(List<double> scores, int topN) {
    return getTopIndicesWithThreshold(scores, topN, 0.05); // Reduced to 5% threshold
  }
  
  /// Get top N indices with confidence threshold
  static List<int> getTopIndicesWithThreshold(List<double> scores, int topN, double threshold) {
    final indexed = List.generate(
      scores.length,
      (i) => MapEntry(i, scores[i]),
    );
    indexed.sort((a, b) => b.value.compareTo(a.value));
    
    // Filter by confidence threshold and take top N
    return indexed
        .where((entry) => entry.value > threshold)
        .take(topN)
        .map((e) => e.key)
        .toList();
  }
}

/// ============================================================================
/// DATA CLASSES
/// ============================================================================

/// YAMNet label with categorization
class YAMNetLabel {
  final int index;
  final String mid;
  final String displayName;

  YAMNetLabel({
    required this.index,
    required this.mid,
    required this.displayName,
  });
  
  /// Check if label represents an instrument
  bool get isInstrument {
    const instruments = [
      'piano', 'guitar', 'drum', 'bass', 'violin', 'saxophone', 'trumpet',
      'flute', 'clarinet', 'cello', 'organ', 'synthesizer', 'keyboard',
      'banjo', 'mandolin', 'ukulele', 'harp', 'accordion', 'harmonica',
      'trombone', 'tuba', 'oboe', 'bassoon', 'french horn', 'trombone',
      'xylophone', 'marimba', 'vibraphone', 'glockenspiel', 'timpani',
      'cymbals', 'snare', 'kick', 'hi-hat', 'crash', 'ride', 'tom',
      'electric guitar', 'acoustic guitar', 'bass guitar', 'double bass',
      'viola', 'violin', 'cello', 'contrabass', 'electric bass',
      'synthesizer', 'keyboard', 'piano', 'organ', 'harpsichord',
      'accordion', 'concertina', 'melodica', 'harmonica', 'mouth organ'
    ];
    final lower = displayName.toLowerCase();
    
    // Check for instrument names
    final hasInstrument = instruments.any((inst) => lower.contains(inst));
    
    // Also check for instrument-related terms
    const instrumentTerms = [
      'instrument', 'playing', 'strumming', 'plucking', 'bowing',
      'blowing', 'striking', 'hitting', 'tapping', 'fingering'
    ];
    final hasInstrumentTerm = instrumentTerms.any((term) => lower.contains(term));
    
    return hasInstrument || hasInstrumentTerm;
  }
  
  /// Check if label represents vocals
  bool get isVocal {
    const vocals = ['singing', 'speech', 'vocal', 'voice', 'choir', 'chorus', 'chant'];
    final lower = displayName.toLowerCase();
    return vocals.any((vocal) => lower.contains(vocal));
  }
  
  /// Check if label represents a genre
  bool get isGenre {
    const genres = [
      'rock', 'pop', 'jazz', 'classical', 'electronic', 'blues', 'country',
      'hip hop', 'reggae', 'metal', 'folk', 'r&b', 'soul', 'funk', 'disco',
      'techno', 'house', 'trance', 'dubstep', 'ambient', 'indie', 'gospel',
      'latin', 'world', 'new age', 'alternative', 'punk', 'grunge', 'emo',
      'hardcore', 'progressive', 'experimental', 'avant-garde', 'minimalist'
    ];
    final lower = displayName.toLowerCase();
    
    // Check for genre keywords with or without 'music' suffix
    final hasGenre = genres.any((genre) => lower.contains(genre));
    final hasMusic = lower.contains('music') || lower.contains('song') || lower.contains('tune');
    
    // Also check for specific genre patterns
    final genrePatterns = [
      'music', 'song', 'tune', 'melody', 'rhythm', 'beat', 'sound',
      'acoustic', 'electric', 'vocal', 'instrumental', 'orchestral'
    ];
    final hasPattern = genrePatterns.any((pattern) => lower.contains(pattern));
    
    // FIXED: Use OR logic instead of AND - any genre indicator is valid
    return hasGenre || hasMusic || hasPattern;
  }
  
  /// Check if label represents mood
  bool get isMood {
    const moods = [
      'happy', 'sad', 'energetic', 'calm', 'melancholy', 'upbeat', 'cheerful',
      'gloomy', 'peaceful', 'relaxing', 'intense', 'aggressive', 'gentle',
      'joyful', 'somber', 'dark', 'bright', 'serene', 'tranquil'
    ];
    final lower = displayName.toLowerCase();
    return moods.any((mood) => lower.contains(mood));
  }
  
  /// Check if label is energy-related
  bool get isEnergyRelated {
    const energyTerms = [
      'loud', 'quiet', 'energetic', 'intense', 'powerful', 'soft', 'strong',
      'heavy', 'light', 'dynamic', 'aggressive', 'gentle'
    ];
    final lower = displayName.toLowerCase();
    return energyTerms.any((term) => lower.contains(term));
  }
}

/// Signal processing features
class SignalFeatures {
  final double tempoBpm;
  final double beatStrength;
  final double energy;
  final double brightness;
  final double danceability;
  final double spectralCentroid;
  final double spectralRolloff;
  final double zeroCrossingRate;

  SignalFeatures({
    required this.tempoBpm,
    required this.beatStrength,
    required this.energy,
    required this.brightness,
    required this.danceability,
    required this.spectralCentroid,
    required this.spectralRolloff,
    required this.zeroCrossingRate,
  });
}

/// Complex number class for FFT calculations
class Complex {
  final double real;
  final double imaginary;

  Complex(this.real, this.imaginary);

  Complex operator +(Complex other) {
    return Complex(real + other.real, imaginary + other.imaginary);
  }

  Complex operator -(Complex other) {
    return Complex(real - other.real, imaginary - other.imaginary);
  }

  Complex operator *(Complex other) {
    return Complex(
      real * other.real - imaginary * other.imaginary,
      real * other.imaginary + imaginary * other.real,
    );
  }
}

/// YAMNet analysis results
class YAMNetResults {
  final List<String> instruments;
  final bool hasVocals;
  final String genre;
  final double energy;
  final List<String> moodTags;

  YAMNetResults({
    required this.instruments,
    required this.hasVocals,
    required this.genre,
    required this.energy,
    required this.moodTags,
  });
}

