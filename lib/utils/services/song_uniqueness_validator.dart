import '../models/song/song_model.dart';
import 'song_cleanup_service.dart';

class SongUniquenessValidator {
  /// Validate that all songs have unique IDs
  static bool validateUniqueIds(List<Song> songs) {
    return SongCleanupService.validateUniqueIds(songs);
  }

  /// Remove duplicate songs based on ID, keeping the first occurrence
  static List<Song> removeDuplicates(List<Song> songs) {
    return SongCleanupService.removeDuplicatesById(songs);
  }

  /// Get duplicate song IDs for debugging
  static List<String> getDuplicateIds(List<Song> songs) {
    return SongCleanupService.getDuplicateIds(songs);
  }
}
