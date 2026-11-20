import 'dart:io';

import '../logger/logger.dart';
import '../models/song/song_model.dart';

/// Deletes cached album-art files of songs that were removed from the
/// library, so `<app documents>/album_art` does not grow forever.
class AlbumArtCleanup {
  AlbumArtCleanup._();

  static final AppLogger _logger = AppLogger('AlbumArtCleanup');

  /// Only files inside the app's own album-art cache are ever deleted
  /// (never `cover.jpg` files in the user's music folders).
  static bool isCachedArtPath(String path) => path.contains('/album_art/');

  /// Paths that can be deleted: art of [removedSongs] that lives in the app
  /// cache and is not used by any of [remainingSongs].
  static List<String> orphanedArtPaths({
    required List<Song> removedSongs,
    required List<Song> remainingSongs,
  }) {
    final stillUsed = remainingSongs
        .map((s) => s.albumArt)
        .whereType<String>()
        .toSet();
    return removedSongs
        .map((s) => s.albumArt)
        .whereType<String>()
        .where(isCachedArtPath)
        .where((p) => !stillUsed.contains(p))
        .toSet()
        .toList();
  }

  static Future<int> deleteOrphanedArt({
    required List<Song> removedSongs,
    required List<Song> remainingSongs,
  }) async {
    var deleted = 0;
    for (final path in orphanedArtPaths(
      removedSongs: removedSongs,
      remainingSongs: remainingSongs,
    )) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          deleted++;
        }
      } catch (e) {
        _logger.w('⚠️ Could not delete album art $path: $e');
      }
    }
    if (deleted > 0) _logger.i('🧹 Deleted $deleted orphaned album-art files');
    return deleted;
  }
}
