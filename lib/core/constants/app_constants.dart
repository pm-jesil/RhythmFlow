class Sources {
  const Sources();
  
  static const String allSongs = 'allSongs';
  static const String album = 'album';
  static const String artist = 'artist';
  static const String myPlaylist = 'my_playlist';
}

class TabLabels {
  const TabLabels();
  
  static const String forYou = 'For You';
  static const String songs = 'Songs';
  static const String albums = 'Albums';
  static const String artists = 'Artists';
  static const String playlists = 'Playlists';
}

class AppConstants {
  const AppConstants();
  
  static const String appName = 'RhythmFlow';
  static const String appNamePlayStore = 'RhythmFlow - AI Music Player';
  static const String appTagline = 'Music that flows with you';
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Music quotes for personalized experience
  static const List<String> musicQuotes = [
    "Music is the universal language of mankind",
    "Where words fail, music speaks",
    "Music is the soundtrack of your life",
    "Life is better with music",
    "Music washes away from the soul the dust of everyday life",
    "Without music, life would be a mistake",
    "Music is the wine that fills the cup of silence",
    "One good thing about music, when it hits you, you feel no pain",
    "Music expresses that which cannot be put into words",
    "The music is not in the notes, but in the silence between",
    "Music is the art of thinking with sounds",
    "Music is the language of the spirit",
    "Music is the moonlight in the gloomy night of life",
    "Music is the poetry of the air",
    "Music is the medicine of the mind",
    "Music is the voice of the heart",
    "Music is the soul of language",
    "Music is the art which is most nigh to tears and memory",
    "Music is the movement of sound to reach the soul",
    "Music is the silence between the notes",
    "Music is the universal language of the world",
    "Music is the food of love",
    "Music is the healing force of the universe",
    "Music is the rhythm of life",
    "Music is the melody of the soul",
    "Music is the harmony of the heart",
    "Music is the poetry of sound",
    "Music is the art of the invisible",
    "Music is the language of emotions",
    "Music is the bridge between heaven and earth",
  ];
}

/// Equalizer reverb preset IDs (match Android PresetReverb.PRESET_*).
class EqualizerReverbPresets {
  const EqualizerReverbPresets();

  static const int none = 0;
  static const int smallRoom = 1;
  static const int mediumRoom = 2;
  static const int largeRoom = 3;
  static const int mediumHall = 4;
  static const int largeHall = 5;
  static const int plate = 6;
}

/// Equalizer band gain presets (5-band default; use with presetForBandCount for other band counts).
class EqualizerBandPresets {
  const EqualizerBandPresets();

  static const List<double> flat = [0.0, 0.0, 0.0, 0.0, 0.0];
  static const List<double> bassBoost = [6.0, 4.0, 0.0, -2.0, -2.0];
  static const List<double> treble = [-2.0, -2.0, 0.0, 4.0, 6.0];
  static const List<double> vocal = [-2.0, 2.0, 4.0, 2.0, -1.0];
  static const List<double> rock = [4.0, 2.0, 2.0, 2.0, 4.0];
  static const List<double> pop = [2.0, 2.0, 0.0, 2.0, 2.0];
  static const List<double> jazz = [2.0, 2.0, 2.0, 2.0, 2.0];
  static const List<double> classical = [0.0, 0.0, 2.0, 4.0, 4.0];
  static const List<double> studio = [0.0, 0.0, 0.5, 0.5, 0.0];
  static const List<double> smallRoom = [1.0, 2.0, 1.0, 0.0, -1.0];
  static const List<double> smallHall = [0.0, 1.0, 2.0, 3.0, 2.0];
  static const List<double> concertHall = [0.0, 0.0, 2.0, 4.0, 5.0];
  static const List<double> liveStage = [0.0, 1.0, 3.0, 3.0, 2.0];
  static const List<double> ambientSpace = [-1.0, 0.0, 1.0, 3.0, 5.0];
  static const List<double> carCabin = [4.0, 3.0, 0.0, -1.0, -1.0];
  static const List<double> headphonesBoost = [0.0, 0.0, 1.0, 2.0, 2.0];

  /// Returns built-in band gains for [presetId], or flat if unknown.
  static List<double> getGains(String presetId) {
    switch (presetId) {
      case 'flat':
        return List<double>.from(flat);
      case 'bass_boost':
        return List<double>.from(bassBoost);
      case 'treble':
        return List<double>.from(treble);
      case 'vocal':
        return List<double>.from(vocal);
      case 'rock':
        return List<double>.from(rock);
      case 'pop':
        return List<double>.from(pop);
      case 'jazz':
        return List<double>.from(jazz);
      case 'classical':
        return List<double>.from(classical);
      case 'studio':
        return List<double>.from(studio);
      case 'small_room':
        return List<double>.from(smallRoom);
      case 'small_hall':
        return List<double>.from(smallHall);
      case 'concert_hall':
        return List<double>.from(concertHall);
      case 'live_stage':
        return List<double>.from(liveStage);
      case 'ambient_space':
        return List<double>.from(ambientSpace);
      case 'car_cabin':
        return List<double>.from(carCabin);
      case 'headphones_boost':
        return List<double>.from(headphonesBoost);
      default:
        return List<double>.from(flat);
    }
  }
}

/// Equalizer preset effect values (echo, virtualizer, loudness, bassBoost) per preset id.
class EqualizerPresetEffects {
  const EqualizerPresetEffects();

  static ({int echo, int virtualizer, int loudness, int bassBoost}) get(String presetId) {
    switch (presetId) {
      case 'flat':
        return (echo: 0, virtualizer: 0, loudness: 0, bassBoost: 0);
      case 'bass_boost':
        return (echo: 0, virtualizer: 0, loudness: 0, bassBoost: 700);
      case 'treble':
        return (echo: 0, virtualizer: 200, loudness: 0, bassBoost: 0);
      case 'vocal':
        return (echo: 15, virtualizer: 200, loudness: 100, bassBoost: 0);
      case 'rock':
        return (echo: 0, virtualizer: 200, loudness: 0, bassBoost: 400);
      case 'pop':
        return (echo: 0, virtualizer: 350, loudness: 200, bassBoost: 0);
      case 'jazz':
        return (echo: 20, virtualizer: 450, loudness: 0, bassBoost: 150);
      case 'classical':
        return (echo: 25, virtualizer: 550, loudness: 0, bassBoost: 0);
      case 'studio':
        return (echo: 0, virtualizer: 100, loudness: 0, bassBoost: 0);
      case 'small_room':
        return (echo: 25, virtualizer: 0, loudness: 0, bassBoost: 200);
      case 'small_hall':
        return (echo: 35, virtualizer: 400, loudness: 0, bassBoost: 0);
      case 'concert_hall':
        return (echo: 45, virtualizer: 600, loudness: 0, bassBoost: 0);
      case 'live_stage':
        return (echo: 40, virtualizer: 500, loudness: 0, bassBoost: 0);
      case 'ambient_space':
        return (echo: 60, virtualizer: 550, loudness: 0, bassBoost: 0);
      case 'car_cabin':
        return (echo: 0, virtualizer: 150, loudness: 0, bassBoost: 700);
      case 'headphones_boost':
        return (echo: 0, virtualizer: 350, loudness: 0, bassBoost: 0);
      default:
        return (echo: 0, virtualizer: 0, loudness: 0, bassBoost: 0);
    }
  }
}
