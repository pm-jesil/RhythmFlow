import 'dart:math' as math;
import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import '../../models/song_features/song_features.dart';

/// ============================================================================
/// AI SHUFFLE SERVICE - Intelligent Playlist Reordering
/// ============================================================================
///
/// PURPOSE: Intelligently reorder playlist based on current song features
/// 
/// FEATURES:
/// - Analyzes current song's musical characteristics
/// - Finds most similar songs based on multiple feature dimensions
/// - Reorders playlist to play similar songs next
/// - Supports mood-based shuffling (DJ, sad, sleep, energetic, etc.)
/// 
/// ALGORITHM:
/// 1. Extract features from current song
/// 2. Calculate similarity scores for all other songs
/// 3. Reorder playlist by similarity (most similar first)
/// 4. Maintain current song position and completed songs

class AiShuffleService {
  static final AppLogger _logger = AppLogger('AiShuffleService');

  /// Intelligently reorder playlist based on current song features
  static List<String> reorderPlaylistBySimilarity({
    required String currentSongId,
    required List<String> playlistSongIds,
    required List<Song> allSongs,
    int maxSimilarSongs = 20,
  }) {
    try {
      _logger.i('🎵 Starting AI shuffle for current song: $currentSongId');
      
      // Find current song
      final currentSong = allSongs.firstWhere(
        (song) => song.id == currentSongId,
        orElse: () => throw Exception('Current song not found: $currentSongId'),
      );
      
      // Check if current song has features
      if (currentSong.features == null) {
        _logger.w('⚠️ Current song has no features, falling back to regular shuffle');
        return _fallbackShuffle(playlistSongIds, currentSongId);
      }
      
      // Get songs with features from playlist
      final playlistSongs = allSongs.where((song) => 
        playlistSongIds.contains(song.id) && song.features != null
      ).toList();
      
      if (playlistSongs.length < 2) {
        _logger.w('⚠️ Not enough songs with features for AI shuffle');
        return _fallbackShuffle(playlistSongIds, currentSongId);
      }
      
      // Calculate similarity scores
      final similarityScores = _calculateSimilarityScores(
        currentSong.features!,
        playlistSongs,
      );
      
      // Sort by similarity (highest first)
      similarityScores.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
      
      // Create reordered playlist
      final reorderedPlaylist = <String>[];
      
      // Add current song first
      reorderedPlaylist.add(currentSongId);
      
      // Add most similar songs (excluding current song)
      int addedCount = 0;
      for (final score in similarityScores) {
        if (score.songId != currentSongId && addedCount < maxSimilarSongs) {
          reorderedPlaylist.add(score.songId);
          addedCount++;
        }
      }
      
      // Add remaining songs that weren't included
      for (final songId in playlistSongIds) {
        if (!reorderedPlaylist.contains(songId)) {
          reorderedPlaylist.add(songId);
        }
      }
      
      _logger.i('✅ AI shuffle completed: ${reorderedPlaylist.length} songs reordered');
      _logger.d('🎯 Top 5 similar songs: ${similarityScores.take(5).map((s) => '${s.songId}(${s.similarityScore.toStringAsFixed(2)})').join(', ')}');
      
      return reorderedPlaylist;
      
    } catch (e, stackTrace) {
      _logger.e('❌ AI shuffle failed: $e');
      _logger.e('Stack trace: $stackTrace');
      return _fallbackShuffle(playlistSongIds, currentSongId);
    }
  }

  /// Calculate similarity scores between current song and all other songs
  static List<SongSimilarity> _calculateSimilarityScores(
    SongFeatures currentFeatures,
    List<Song> otherSongs,
  ) {
    final similarities = <SongSimilarity>[];
    
    for (final song in otherSongs) {
      if (song.features == null) continue;
      
      final similarity = _calculateSongSimilarity(currentFeatures, song.features!);
      similarities.add(SongSimilarity(
        songId: song.id,
        similarityScore: similarity,
      ));
    }
    
    return similarities;
  }

  /// Calculate comprehensive similarity between two songs
  static double _calculateSongSimilarity(SongFeatures song1, SongFeatures song2) {
    try {
      // Weighted similarity calculation across multiple dimensions
      double totalSimilarity = 0.0;
      double totalWeight = 0.0;
      
      // 1. Genre Similarity (Weight: 0.25)
      final genreSimilarity = _calculateGenreSimilarity(song1, song2);
      totalSimilarity += genreSimilarity * 0.25;
      totalWeight += 0.25;
      
      // 2. Mood Similarity (Weight: 0.20)
      final moodSimilarity = _calculateMoodSimilarity(song1, song2);
      totalSimilarity += moodSimilarity * 0.20;
      totalWeight += 0.20;
      
      // 3. Energy Similarity (Weight: 0.15)
      final energySimilarity = _calculateEnergySimilarity(song1, song2);
      totalSimilarity += energySimilarity * 0.15;
      totalWeight += 0.15;
      
      // 4. Tempo Similarity (Weight: 0.15)
      final tempoSimilarity = _calculateTempoSimilarity(song1, song2);
      totalSimilarity += tempoSimilarity * 0.15;
      totalWeight += 0.15;
      
      // 5. Instrument Similarity (Weight: 0.15)
      final instrumentSimilarity = _calculateInstrumentSimilarity(song1, song2);
      totalSimilarity += instrumentSimilarity * 0.15;
      totalWeight += 0.15;
      
      // 6. Spectral Similarity (Weight: 0.10)
      final spectralSimilarity = _calculateSpectralSimilarity(song1, song2);
      totalSimilarity += spectralSimilarity * 0.10;
      totalWeight += 0.10;
      
      return totalWeight > 0 ? totalSimilarity / totalWeight : 0.0;
      
    } catch (e) {
      _logger.e('❌ Error calculating similarity: $e');
      return 0.0;
    }
  }

  /// Calculate genre similarity
  static double _calculateGenreSimilarity(SongFeatures song1, SongFeatures song2) {
    // Exact genre match
    if (song1.estimatedGenre.toLowerCase() == song2.estimatedGenre.toLowerCase()) {
      return 1.0;
    }
    
    // Genre category matching
    final genre1 = song1.estimatedGenre.toLowerCase();
    final genre2 = song2.estimatedGenre.toLowerCase();
    
    // Define genre categories
    final genreCategories = {
      'electronic': ['electronic', 'techno', 'house', 'trance', 'dubstep', 'edm'],
      'rock': ['rock', 'metal', 'punk', 'grunge', 'alternative'],
      'pop': ['pop', 'dance', 'disco', 'funk'],
      'classical': ['classical', 'orchestral', 'chamber', 'symphony'],
      'jazz': ['jazz', 'blues', 'swing', 'bebop'],
      'hip_hop': ['hip hop', 'rap', 'r&b', 'soul'],
      'country': ['country', 'folk', 'bluegrass'],
      'ambient': ['ambient', 'new age', 'meditation', 'sleep'],
    };
    
    // Find matching categories
    for (final category in genreCategories.entries) {
      final categoryGenres = category.value;
      final hasGenre1 = categoryGenres.any((genre) => genre1.contains(genre));
      final hasGenre2 = categoryGenres.any((genre) => genre2.contains(genre));
      
      if (hasGenre1 && hasGenre2) {
        return 0.8; // Same category
      }
    }
    
    return 0.0; // No match
  }

  /// Calculate mood similarity
  static double _calculateMoodSimilarity(SongFeatures song1, SongFeatures song2) {
    // Exact mood match
    if (song1.mood.toLowerCase() == song2.mood.toLowerCase()) {
      return 1.0;
    }
    
    // Mood category matching
    final mood1 = song1.mood.toLowerCase();
    final mood2 = song2.mood.toLowerCase();
    
    // Define mood categories
    final moodCategories = {
      'energetic': ['happy', 'energetic', 'upbeat', 'exciting', 'cheerful'],
      'calm': ['calm', 'peaceful', 'relaxing', 'serene', 'tranquil'],
      'sad': ['sad', 'melancholy', 'somber', 'gloomy', 'dark'],
      'neutral': ['neutral', 'balanced', 'moderate'],
    };
    
    // Find matching mood categories
    for (final category in moodCategories.entries) {
      final categoryMoods = category.value;
      final hasMood1 = categoryMoods.any((mood) => mood1.contains(mood));
      final hasMood2 = categoryMoods.any((mood) => mood2.contains(mood));
      
      if (hasMood1 && hasMood2) {
        return 0.8; // Same mood category
      }
    }
    
    return 0.0; // No match
  }

  /// Calculate energy similarity
  static double _calculateEnergySimilarity(SongFeatures song1, SongFeatures song2) {
    // Compare energy levels
    final energy1 = song1.overallEnergy;
    final energy2 = song2.overallEnergy;
    
    // Calculate energy difference (0-1 scale)
    final energyDiff = (energy1 - energy2).abs();
    
    // Convert to similarity (closer energies = higher similarity)
    return math.max(0.0, 1.0 - energyDiff);
  }

  /// Calculate tempo similarity
  static double _calculateTempoSimilarity(SongFeatures song1, SongFeatures song2) {
    final tempo1 = song1.tempoBpm;
    final tempo2 = song2.tempoBpm;
    
    // Calculate tempo difference percentage
    final avgTempo = (tempo1 + tempo2) / 2;
    final tempoDiff = (tempo1 - tempo2).abs() / avgTempo;
    
    // Convert to similarity (closer tempos = higher similarity)
    return math.max(0.0, 1.0 - tempoDiff);
  }

  /// Calculate instrument similarity
  static double _calculateInstrumentSimilarity(SongFeatures song1, SongFeatures song2) {
    final instruments1 = song1.instruments.map((i) => i.toLowerCase()).toSet();
    final instruments2 = song2.instruments.map((i) => i.toLowerCase()).toSet();
    
    if (instruments1.isEmpty || instruments2.isEmpty) return 0.0;
    
    // Calculate Jaccard similarity
    final intersection = instruments1.intersection(instruments2).length;
    final union = instruments1.union(instruments2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculate spectral similarity
  static double _calculateSpectralSimilarity(SongFeatures song1, SongFeatures song2) {
    // Compare spectral characteristics
    final centroid1 = song1.spectralCentroid;
    final centroid2 = song2.spectralCentroid;
    final rolloff1 = song1.spectralRolloff;
    final rolloff2 = song2.spectralRolloff;
    
    // Normalize spectral features (assuming 0-8000 Hz range)
    final normalizedCentroid1 = centroid1 / 8000.0;
    final normalizedCentroid2 = centroid2 / 8000.0;
    final normalizedRolloff1 = rolloff1 / 8000.0;
    final normalizedRolloff2 = rolloff2 / 8000.0;
    
    // Calculate spectral distance
    final centroidDiff = (normalizedCentroid1 - normalizedCentroid2).abs();
    final rolloffDiff = (normalizedRolloff1 - normalizedRolloff2).abs();
    
    // Convert to similarity
    final avgDiff = (centroidDiff + rolloffDiff) / 2;
    return math.max(0.0, 1.0 - avgDiff);
  }

  /// Fallback shuffle when AI shuffle fails
  static List<String> _fallbackShuffle(List<String> playlistSongIds, String currentSongId) {
    final shuffled = List<String>.from(playlistSongIds);
    shuffled.shuffle();
    
    // Ensure current song is first
    shuffled.remove(currentSongId);
    shuffled.insert(0, currentSongId);
    
    return shuffled;
  }

  /// Get mood-based playlist reordering
  static List<String> reorderByMood({
    required String currentSongId,
    required List<String> playlistSongIds,
    required List<Song> allSongs,
    String? targetMood,
  }) {
    try {
      _logger.i('🎭 Starting mood-based shuffle for: $targetMood');
      
      // Find current song
      final currentSong = allSongs.firstWhere(
        (song) => song.id == currentSongId,
        orElse: () => throw Exception('Current song not found: $currentSongId'),
      );
      
      if (currentSong.features == null) {
        return _fallbackShuffle(playlistSongIds, currentSongId);
      }
      
      // Determine target mood
      final mood = targetMood ?? _classifySongMood(currentSong.features!);
      _logger.d('🎯 Target mood: $mood');
      
      // Get songs with features
      final playlistSongs = allSongs.where((song) => 
        playlistSongIds.contains(song.id) && song.features != null
      ).toList();
      
      // Score songs by mood match
      final moodScores = <SongSimilarity>[];
      
      for (final song in playlistSongs) {
        if (song.features == null) continue;
        
        final moodMatch = _calculateMoodMatch(song.features!, mood);
        moodScores.add(SongSimilarity(
          songId: song.id,
          similarityScore: moodMatch,
        ));
      }
      
      // Sort by mood match
      moodScores.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
      
      // Create reordered playlist
      final reorderedPlaylist = <String>[];
      reorderedPlaylist.add(currentSongId);
      
      for (final score in moodScores) {
        if (score.songId != currentSongId) {
          reorderedPlaylist.add(score.songId);
        }
      }
      
      _logger.i('✅ Mood-based shuffle completed');
      return reorderedPlaylist;
      
    } catch (e) {
      _logger.e('❌ Mood-based shuffle failed: $e');
      return _fallbackShuffle(playlistSongIds, currentSongId);
    }
  }

  /// Classify song mood based on features
  static String _classifySongMood(SongFeatures features) {
    final energy = features.overallEnergy;
    final tempo = features.tempoBpm;
    final mood = features.mood.toLowerCase();
    
    // High energy + fast tempo = Energetic
    if (energy > 0.7 && tempo > 120) {
      return 'energetic';
    }
    
    // Low energy + slow tempo = Calm
    if (energy < 0.4 && tempo < 90) {
      return 'calm';
    }
    
    // Sad mood indicators
    if (mood.contains('sad') || mood.contains('melancholy') || mood.contains('somber')) {
      return 'sad';
    }
    
    // Sleep/ambient indicators
    if (mood.contains('calm') || mood.contains('peaceful') || mood.contains('relaxing')) {
      return 'sleep';
    }
    
    // Default to current mood
    return mood;
  }

  /// Calculate mood match score
  static double _calculateMoodMatch(SongFeatures features, String targetMood) {
    final currentMood = _classifySongMood(features);
    
    // Exact match
    if (currentMood == targetMood) {
      return 1.0;
    }
    
    // Similar mood categories
    final moodCategories = {
      'energetic': ['happy', 'upbeat', 'exciting'],
      'calm': ['peaceful', 'relaxing', 'serene'],
      'sad': ['melancholy', 'somber', 'gloomy'],
      'sleep': ['ambient', 'meditation', 'tranquil'],
    };
    
    for (final category in moodCategories.entries) {
      if (category.key == targetMood && category.value.contains(currentMood)) {
        return 0.8;
      }
    }
    
    return 0.0;
  }
}

/// Song similarity data class
class SongSimilarity {
  final String songId;
  final double similarityScore;

  SongSimilarity({
    required this.songId,
    required this.similarityScore,
  });
}
