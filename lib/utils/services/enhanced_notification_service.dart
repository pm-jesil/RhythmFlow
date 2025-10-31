import 'dart:io';
import 'package:audio_service/audio_service.dart';
import '../models/song/song_model.dart';
import '../logger/logger.dart';

class EnhancedNotificationService {
  static final AppLogger _logger = AppLogger('EnhancedNotificationService');

  /// Create enhanced MediaItem for notification and lock screen
  static MediaItem createEnhancedMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artists.join(', '),
      album: song.albums.join(', '),
      duration: song.duration,
      artUri: _getAlbumArtUri(song),
      extras: {
        'songId': song.id,
        'filePath': song.path,
        'albumArtPath': song.albumArt,
        'album': song.albums.join(', '),
        'artist': song.artists.join(', '),
        'title': song.title,
        'genre': song.genre,
        'year': song.year,
        'trackNumber': song.trackNumber,
        'discNumber': song.discNumber,
        'composer': song.composer,
        'bitrate': song.bitrate,
        'fileSize': song.fileSize,
        'dateAdded': song.dateAdded?.toIso8601String(),
        'lastPlayed': song.lastPlayed?.toIso8601String(),
        'playCount': song.playCount,
        'isFavorite': song.isFavorite,
        'albumArtist': song.albumArtist,
        'displayTitle': song.displayTitle,
        'displayArtist': song.displayArtist,
        'displayAlbum': song.displayAlbum,
        'formattedDuration': song.formattedDuration,
        'fileExtension': song.fileExtension,
        'hasAlbumArt': song.hasAlbumArt,
        'formattedFileSize': song.formattedFileSize,
      },
    );
  }

  /// Get album art URI with fallback handling
  static Uri? _getAlbumArtUri(Song song) {
    try {
      if (song.albumArt != null && song.albumArt!.isNotEmpty) {
        final file = File(song.albumArt!);
        if (file.existsSync()) {
          _logger.d('📸 Using album art: ${song.albumArt}');
          return Uri.file(song.albumArt!);
        } else {
          _logger.w('⚠️ Album art file not found: ${song.albumArt}');
        }
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error getting album art URI: $e');
      return null;
    }
  }

}