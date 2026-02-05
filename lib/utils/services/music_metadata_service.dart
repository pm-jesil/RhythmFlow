import 'package:music_feature_analyzer/music_feature_analyzer.dart';
import '../models/song/song_model.dart';
import '../models/song_features/song_features.dart';

/// Maps [SongModel] from music_feature_analyzer to app [Song] with safe fallbacks.
class MusicMetadataService {
  /// Convert package [SongModel] to app [Song]. Returns null if required fields are missing.
  static Song? songModelToSong(SongModel? model) {
    if (model == null) return null;

    final title = _nonEmpty(model.title) ?? _titleFromPath(model.filePath);
    final artistList = _splitAndClean(model.artist);
    final artists = artistList.isEmpty ? ['Unknown Artist'] : artistList;
    final albumList = _splitAndClean(model.album);
    final albums = albumList.isEmpty ? ['Unknown Album'] : albumList;

    return Song(
      id: model.id,
      title: title,
      artists: artists,
      albums: albums,
      path: model.filePath,
      duration: Duration(milliseconds: model.duration),
      albumArt: model.albumArt,
      genre: model.genre,
      year: model.year,
      trackNumber: model.trackNumber,
      discNumber: model.discNumber,
      composer: model.composer,
      lyrics: null,
      bitrate: model.bitrate,
      fileSize: model.fileSize,
      dateAdded: model.dateAdded,
      lastPlayed: null,
      playCount: 0,
      isFavorite: false,
      albumArtist: model.albumArtist,
      features: extractedToSongFeatures(model.features),
    );
  }

  static String _titleFromPath(String filePath) {
    try {
      final name = filePath.split(RegExp(r'[/\\]')).last;
      final withoutExt = name.contains('.') ? name.split('.').first : name;
      return withoutExt.trim().isEmpty ? 'Unknown Title' : withoutExt.trim();
    } catch (_) {
      return 'Unknown Title';
    }
  }

  static String? _nonEmpty(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _splitAndClean(String? s) {
    if (s == null || s.trim().isEmpty) return [];
    return s
        .split(RegExp(r'[,;|/&]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Map package [ExtractedSongFeatures] to app [SongFeatures]. Single place for AI feature conversion.
  static SongFeatures? extractedToSongFeatures(ExtractedSongFeatures? f) {
    if (f == null) return null;
    try {
      return SongFeatures(
        tempo: f.tempo,
        beat: f.beat,
        energy: f.energy,
        instruments: f.instruments,
        vocals: f.vocals,
        mood: f.mood,
        yamnetInstruments: f.yamnetInstruments,
        hasVocals: f.hasVocals,
        estimatedGenre: f.estimatedGenre,
        yamnetEnergy: f.yamnetEnergy,
        moodTags: f.moodTags,
        tempoBpm: f.tempoBpm,
        beatStrength: f.beatStrength,
        signalEnergy: f.signalEnergy,
        brightness: f.brightness,
        danceability: f.danceability,
        overallEnergy: f.overallEnergy,
        intensity: f.intensity,
        spectralCentroid: f.spectralCentroid,
        spectralRolloff: f.spectralRolloff,
        zeroCrossingRate: f.zeroCrossingRate,
        spectralFlux: f.spectralFlux,
        complexity: f.complexity,
        valence: f.valence,
        arousal: f.arousal,
        confidence: f.confidence,
        analyzedAt: f.analyzedAt,
        modelVersion: f.analyzerVersion,
      );
    } catch (_) {
      return null;
    }
  }
}
