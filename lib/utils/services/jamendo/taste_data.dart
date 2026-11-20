// GENERATED from a survey of the live Jamendo API (tool/survey_jamendo_tastes.py).
// Only tags with at least 1000 tracks are offered. `useFuzzy` tells which
// query parameter returned results for the tag (some tags only work with
// one of `tags` / `fuzzytags`). Jamendo maps "rap" to the hiphop tag.

import 'taste_models.dart';

const List<MusicTaste> jamendoTastes = [
  MusicTaste(id: 'pop', label: 'Pop', emoji: '🎤', kind: TasteKind.genre, useFuzzy: true, trackCount: 54734),
  MusicTaste(id: 'rock', label: 'Rock', emoji: '🎸', kind: TasteKind.genre, useFuzzy: true, trackCount: 84204),
  MusicTaste(id: 'hiphop', label: 'Hip-Hop & Rap', emoji: '🎧', kind: TasteKind.genre, useFuzzy: true, trackCount: 53676),
  MusicTaste(id: 'electronic', label: 'Electronic', emoji: '🎛️', kind: TasteKind.genre, useFuzzy: true, trackCount: 137543),
  MusicTaste(id: 'dance', label: 'Dance', emoji: '💃', kind: TasteKind.genre, useFuzzy: true, trackCount: 25980),
  MusicTaste(id: 'edm', label: 'EDM', emoji: '⚡', kind: TasteKind.genre, useFuzzy: true, trackCount: 7355),
  MusicTaste(id: 'house', label: 'House', emoji: '🏠', kind: TasteKind.genre, useFuzzy: true, trackCount: 18402),
  MusicTaste(id: 'techno', label: 'Techno', emoji: '🔊', kind: TasteKind.genre, useFuzzy: true, trackCount: 18385),
  MusicTaste(id: 'trap', label: 'Trap', emoji: '🔥', kind: TasteKind.genre, useFuzzy: true, trackCount: 10767),
  MusicTaste(id: 'lofi', label: 'Lo-fi', emoji: '📼', kind: TasteKind.genre, useFuzzy: false, trackCount: 8271),
  MusicTaste(id: 'chillout', label: 'Chillout', emoji: '🌊', kind: TasteKind.genre, useFuzzy: true, trackCount: 21003),
  MusicTaste(id: 'ambient', label: 'Ambient', emoji: '🌌', kind: TasteKind.genre, useFuzzy: true, trackCount: 61308),
  MusicTaste(id: 'acoustic', label: 'Acoustic', emoji: '🪕', kind: TasteKind.genre, useFuzzy: true, trackCount: 245622),
  MusicTaste(id: 'piano', label: 'Piano', emoji: '🎹', kind: TasteKind.genre, useFuzzy: true, trackCount: 69828),
  MusicTaste(id: 'classical', label: 'Classical', emoji: '🎻', kind: TasteKind.genre, useFuzzy: true, trackCount: 34191),
  MusicTaste(id: 'jazz', label: 'Jazz', emoji: '🎷', kind: TasteKind.genre, useFuzzy: true, trackCount: 18245),
  MusicTaste(id: 'blues', label: 'Blues', emoji: '🎺', kind: TasteKind.genre, useFuzzy: true, trackCount: 7555),
  MusicTaste(id: 'folk', label: 'Folk', emoji: '🌾', kind: TasteKind.genre, useFuzzy: true, trackCount: 23159),
  MusicTaste(id: 'traditional', label: 'Traditional', emoji: '🪘', kind: TasteKind.genre, useFuzzy: true, trackCount: 1628),
  MusicTaste(id: 'indian', label: 'Indian', emoji: '🪔', kind: TasteKind.genre, useFuzzy: true, trackCount: 1420),
  MusicTaste(id: 'world', label: 'World', emoji: '🌍', kind: TasteKind.genre, useFuzzy: true, trackCount: 18590),
  MusicTaste(id: 'latin', label: 'Latin', emoji: '🌶️', kind: TasteKind.genre, useFuzzy: true, trackCount: 5713),
  MusicTaste(id: 'reggae', label: 'Reggae', emoji: '🌴', kind: TasteKind.genre, useFuzzy: true, trackCount: 5907),
  MusicTaste(id: 'rnb', label: 'R&B', emoji: '💜', kind: TasteKind.genre, useFuzzy: true, trackCount: 6557),
  MusicTaste(id: 'funk', label: 'Funk', emoji: '🕺', kind: TasteKind.genre, useFuzzy: true, trackCount: 9809),
  MusicTaste(id: 'metal', label: 'Metal', emoji: '🤘', kind: TasteKind.genre, useFuzzy: true, trackCount: 15747),
  MusicTaste(id: 'punk', label: 'Punk', emoji: '🧷', kind: TasteKind.genre, useFuzzy: true, trackCount: 8948),
  MusicTaste(id: 'indie', label: 'Indie', emoji: '🌻', kind: TasteKind.genre, useFuzzy: true, trackCount: 22936),
  MusicTaste(id: 'soundtrack', label: 'Soundtrack', emoji: '🎬', kind: TasteKind.genre, useFuzzy: true, trackCount: 59894),
  MusicTaste(id: 'cinematic', label: 'Cinematic', emoji: '🎞️', kind: TasteKind.genre, useFuzzy: true, trackCount: 12266),
  MusicTaste(id: 'happy', label: 'Happy', emoji: '😊', kind: TasteKind.mood, useFuzzy: true, trackCount: 96064),
  MusicTaste(id: 'sad', label: 'Sad', emoji: '🌧️', kind: TasteKind.mood, useFuzzy: true, trackCount: 39345),
  MusicTaste(id: 'romantic', label: 'Romantic', emoji: '❤️', kind: TasteKind.mood, useFuzzy: true, trackCount: 6376),
  MusicTaste(id: 'energetic', label: 'Energetic', emoji: '⚡', kind: TasteKind.mood, useFuzzy: true, trackCount: 115961),
  MusicTaste(id: 'party', label: 'Party', emoji: '🎉', kind: TasteKind.mood, useFuzzy: true, trackCount: 4359),
  MusicTaste(id: 'relaxation', label: 'Relax', emoji: '🧘', kind: TasteKind.mood, useFuzzy: true, trackCount: 43555),
  MusicTaste(id: 'meditation', label: 'Meditation', emoji: '🕉️', kind: TasteKind.mood, useFuzzy: true, trackCount: 4757),
  MusicTaste(id: 'epic', label: 'Epic', emoji: '🏔️', kind: TasteKind.mood, useFuzzy: true, trackCount: 6781),
  MusicTaste(id: 'instrumental', label: 'Instrumental', emoji: '🎼', kind: TasteKind.mood, useFuzzy: true, trackCount: 95328),
  MusicTaste(id: 'christmas', label: 'Christmas', emoji: '🎄', kind: TasteKind.mood, useFuzzy: true, trackCount: 3684),
];
