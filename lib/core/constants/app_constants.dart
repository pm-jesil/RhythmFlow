class AppConstants {
  // App Info
  static const String appName = 'PMJ Music Player';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String themeKey = 'theme_preference';
  static const String lastPlayedSongKey = 'last_played_song';
  static const String playlistsKey = 'playlists';
  static const String favoritesKey = 'favorites';
  
  // Audio Settings
  static const double defaultVolume = 1.0;
  static const bool defaultShuffle = false;
  static const bool defaultRepeat = false;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // File Extensions
  static const List<String> supportedAudioFormats = [
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
  ];
  
  // Glassmorphism Constants
  static const double glassBlurRadius = 10.0;
  static const double glassOpacity = 0.8;
  static const double glassBorderRadius = 20.0;
  
  // Gradient Constants
  static const double gradientStartX = 0.0;
  static const double gradientStartY = 0.0;
  static const double gradientEndX = 1.0;
  static const double gradientEndY = 1.0;
  
}

class TabLabels {
  const TabLabels();

  static const String forYou = 'For You';
  static const String songs = 'Songs';
  static const String albums = 'Albums';
  static const String artists = 'Artists';
  static const String playlists = 'Playlists';
}

class Sources {
  const Sources();
  
  static const String allSongs = 'allSongs';
  static const String album = 'album';
  static const String artist = 'artist';
  static const String myPlaylist = 'my_playlist';
}
