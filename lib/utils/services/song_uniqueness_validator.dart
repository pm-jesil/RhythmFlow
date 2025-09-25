import '../models/song/song_model.dart';

class SongUniquenessValidator {
  /// Validate that all songs have unique IDs
  static bool validateUniqueIds(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    
    for (final song in songs) {
      if (seenIds.contains(song.id)) {
        return false; // Duplicate ID found
      }
      seenIds.add(song.id);
    }
    
    return true; // All IDs are unique
  }

  /// Remove duplicate songs based on ID, keeping the first occurrence
  static List<Song> removeDuplicates(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    final List<Song> uniqueSongs = <Song>[];
    
    for (final song in songs) {
      if (!seenIds.contains(song.id)) {
        seenIds.add(song.id);
        uniqueSongs.add(song);
      }
    }
    
    return uniqueSongs;
  }

  /// Get duplicate song IDs for debugging
  static List<String> getDuplicateIds(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    final List<String> duplicates = <String>[];
    
    for (final song in songs) {
      if (seenIds.contains(song.id)) {
        duplicates.add(song.id);
      } else {
        seenIds.add(song.id);
      }
    }
    
    return duplicates;
  }
}
