import 'dart:io';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:injectable/injectable.dart';
import '../models/song/song_model.dart';
import '../logger/logger.dart';

@singleton
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

  /// Create playlist MediaItems with enhanced metadata
  static List<MediaItem> createEnhancedPlaylistMediaItems(List<Song> songs) {
    _logger.i('📋 Creating enhanced playlist with ${songs.length} songs');
    return songs.map((song) => createEnhancedMediaItem(song)).toList();
  }

  /// Show enhanced notification when music starts playing
  static Future<void> showEnhancedNotification({
    required Song song,
    required bool isPlaying,
  }) async {
    try {
      _logger.i('📱 Showing enhanced notification | Song: "${song.title}" | Playing: $isPlaying');
      // Notification is automatically managed by just_audio_background
      _logger.i('✅ Enhanced notification shown by just_audio_background');
    } catch (e) {
      _logger.e('❌ Error showing enhanced notification: $e | Song: "${song.title}"');
    }
  }

  /// Hide enhanced notification when music stops
  static Future<void> hideEnhancedNotification() async {
    try {
      _logger.i('📱 Hiding enhanced notification');
      // Notification is automatically hidden by just_audio_background
      _logger.i('✅ Enhanced notification hidden by just_audio_background');
    } catch (e) {
      _logger.e('❌ Error hiding enhanced notification: $e');
    }
  }
}