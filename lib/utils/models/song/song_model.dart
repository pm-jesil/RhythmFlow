import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rhythmflow/utils/models/song_features/song_features.dart';

part 'song_model.freezed.dart';
part 'song_model.g.dart';

/// Converter for handling Duration in JSON
class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required List<String> artists,
    required List<String> albums,
    List<String>? myPlaylistIds,
    required String path,
    @DurationConverter() required Duration duration,
    String? albumArt,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? composer,
    String? lyrics,
    int? bitrate,
    int? fileSize, // changed from String? → int? (bytes)
    DateTime? dateAdded,
    DateTime? updatedAt,
    // Last-modified time of the file when its metadata was read. Used by the
    // scanner to detect edited/replaced files and re-read their tags.
    DateTime? fileModifiedAt,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
    String? albumArtist,
    List<double>? audioEmbedding,
    SongFeatures ? features,

    // ---- Online (Discover / Jamendo) songs. All null for local songs. ----
    /// `jamendo` for Jamendo tracks, `jamendo_radio` for radio streams,
    /// null for on-device songs.
    String? source,
    String? remoteId,
    String? streamUrl,
    String? downloadUrl,
    bool? downloadAllowed,
    String? licenseUrl,
    String? shareUrl,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

extension SongExtension on Song {
  String get displayTitle => title.isNotEmpty ? title : 'Unknown Title';
  String get displayArtist =>
      primaryArtist.isNotEmpty ? primaryArtist : 'Unknown Artist';
  String get displayAlbum =>
      primaryAlbum.isNotEmpty ? primaryAlbum : 'Unknown Album';

  /// Get the primary (first) artist from the list
  String get primaryArtist =>
      artists.isNotEmpty ? artists.first : 'Unknown Artist';

  /// Get the primary (first) album from the list
  String get primaryAlbum => albums.isNotEmpty ? albums.first : 'Unknown Album';

  /// Get all artists as a formatted string
  String get allArtists => artists.join(', ');

  /// Get all albums as a formatted string
  String get allAlbums => albums.join(', ');

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileExtension {
    final parts = path.split('.');
    return parts.length > 1 ? '.${parts.last.toLowerCase()}' : 'unknown';
  }

  bool get hasAlbumArt => albumArt != null && albumArt!.isNotEmpty;

  /// True for songs streamed from the internet (Discover).
  bool get isOnline => source != null;

  /// True for live radio streams (no fixed duration, no next/previous).
  bool get isRadio => source == SongSources.jamendoRadio;

  /// Only Jamendo tracks whose artist allows it may be downloaded.
  bool get canDownload =>
      source == SongSources.jamendo &&
      downloadAllowed == true &&
      (downloadUrl?.isNotEmpty ?? false);

  String get searchableText =>
      '${title.toLowerCase()} ${allArtists.toLowerCase()} ${allAlbums.toLowerCase()} ${genre?.toLowerCase() ?? ''}'
          .trim();

  String get formattedFileSize {
    if (fileSize == null) return '';
    const kb = 1024;
    const mb = 1024 * kb;
    if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSize! / kb).toStringAsFixed(2)} KB';
    }
  }
}

/// Values of [Song.source].
class SongSources {
  SongSources._();
  static const String jamendo = 'jamendo';
  static const String jamendoRadio = 'jamendo_radio';
}
