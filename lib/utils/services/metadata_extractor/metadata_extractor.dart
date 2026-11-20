import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:rhythmflow/utils/logger/logger.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import '../permission_service.dart';
import '../audio_header_validator.dart';

part 'metadata_extractor_helper.dart';
part 'fetch_artist_names_from_file.dart';
part 'fetch_album_names_from_file.dart';
part 'filename_parser.dart';
part 'album_art_handler.dart';
part 'metadata_utils.dart';
part 'shared_validation.dart';

/// Professional metadata extractor for audio files using audiotags
/// Supports ID3v1, ID3v2, APE, Vorbis, iTunes/MP4, FLAC, and other formats
class MetadataExtractor {
  static final _logger = AppLogger('MetadataExtractor');
  static bool _initialized = false;

  /// Supported audio file extensions (matches app settings)
  static const List<String> _supportedExtensions = [
    '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.wma', '.opus',
    '.aiff', '.alac', '.m4b', '.m4p', '.amr', '.3ga',
  ];

  /// ID3v1 genre mapping
  static const Map<String, String> _genreMap = {
    '0': 'Blues', '1': 'Classic Rock', '2': 'Country', '3': 'Dance', '4': 'Disco',
    '5': 'Funk', '6': 'Grunge', '7': 'Hip-Hop', '8': 'Jazz', '9': 'Metal',
    '10': 'New Age', '11': 'Oldies', '12': 'Other', '13': 'Pop', '14': 'R&B',
    '15': 'Rap', '16': 'Reggae', '17': 'Rock', '18': 'Techno', '19': 'Industrial',
    '20': 'Alternative', '21': 'Ska', '22': 'Death Metal', '23': 'Pranks',
    '24': 'Soundtrack', '25': 'Euro-Techno', '26': 'Ambient', '27': 'Trip-Hop',
    '28': 'Vocal', '29': 'Jazz+Funk', '30': 'Fusion', '31': 'Trance',
    '32': 'Classical', '33': 'Instrumental', '34': 'Acid', '35': 'House',
    '36': 'Game', '37': 'Sound Clip', '38': 'Gospel', '39': 'Noise',
    '40': 'AlternRock', '41': 'Bass', '42': 'Soul', '43': 'Punk', '44': 'Space',
    '45': 'Meditative', '46': 'Instrumental Pop', '47': 'Instrumental Rock',
    '48': 'Ethnic', '49': 'Gothic', '50': 'Darkwave', '51': 'Techno-Industrial',
    '52': 'Electronic', '53': 'Pop-Folk', '54': 'Eurodance', '55': 'Dream',
    '56': 'Southern Rock', '57': 'Comedy', '58': 'Cult', '59': 'Gangsta',
    '60': 'Top 40', '61': 'Christian Rap', '62': 'Pop/Funk', '63': 'Jungle',
    '64': 'Native American', '65': 'Cabaret', '66': 'New Wave', '67': 'Psychadelic',
    '68': 'Rave', '69': 'Showtunes', '70': 'Trailer', '71': 'Lo-Fi',
    '72': 'Tribal', '73': 'Acid Punk', '74': 'Acid Jazz', '75': 'Polka',
    '76': 'Retro', '77': 'Musical', '78': 'Rock & Roll', '79': 'Hard Rock',
  };

  /// Initialize metadata extractor
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      _logger.i('Initializing MetadataExtractor...');

      // Check permissions using centralized service
      final hasPermissions = await PermissionService.hasAllRequiredPermissions();
      if (!hasPermissions) {
        _logger.e('Required permissions not granted');
        return false;
      }
      _logger.i('Permissions granted');

      _initialized = true;
      _logger.i('MetadataExtractor initialization completed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize MetadataExtractor', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Extract metadata from a single audio file
  static Future<Song?> extractMetadata(String filePath) async {
    return await _extractMetadataCore(filePath);
  }

  /// Get supported audio file extensions
  static List<String> get supportedExtensions => List.unmodifiable(_supportedExtensions);

  /// Check if a specific song is currently loaded
  static Future<bool> isValidAudioFile(String filePath) async => await _isValidAudioFile(filePath);
}