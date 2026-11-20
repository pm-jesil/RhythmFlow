part of 'app_settings_bloc.dart';

@freezed
class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState({
    required Map<String, List<String>> whiteListFolder,
    required List<String> supportedAudioFormats,
    required DateTime? lastUpdateMusicLibrary,
    bool? isDarkMode,
    bool? followSystemTheme,
    required int sleepTimerMinutes,
    required bool isSleepTimerEnabled,
    required bool isAiShuffleEnabled,
    required bool autoPlayNext,
    required bool showNotifications,
    required double playbackSpeed,
    required int appBackgroundRefreshTimeGap,
    String? userName,
    String? nickName,
    required List<String> shuffleHistory,

    // Music source shown in all tabs: 'online' (Discover / Jamendo) or
    // 'local' (My Music). Discover is the default.
    @Default(MusicSourceKeys.online) String musicSource,

    // Discover personalisation: ISO 3166-1 alpha-2 country code and
    // ISO 639-1 language codes (first = primary). Null/empty until the user
    // picks them (Welcome screen, Discover setup sheet or Profile).
    String? musicCountry,
    @Default(<String>[]) List<String> musicLanguages,
  }) = _Initial;

  factory AppSettingsState.initial() => AppSettingsState(
    // Default music folders from fetch_songs.dart
    whiteListFolder: const {
      'android': ['/storage/emulated/0/Music', '/storage/emulated/0/Download'],
      'ios': [
        '/var/mobile/Media/iTunes_Control/Music',
        '/var/mobile/Media/Music',
      ],
    },

    // Default supported audio formats from fetch_songs.dart
    supportedAudioFormats: const [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.wma',
      '.opus',
      '.aiff',
      '.alac',
      '.m4b',
      '.m4p',
      '.amr',
      '.3ga',
    ],

    lastUpdateMusicLibrary: null,
    isDarkMode: null,
    followSystemTheme: null,
    sleepTimerMinutes: 30,
    isSleepTimerEnabled: false,
    autoPlayNext: true,
    isAiShuffleEnabled: true, // Enable AI shuffle by default
    showNotifications: true,
    playbackSpeed: 1.0,
    appBackgroundRefreshTimeGap: 5,
    userName: null,
    nickName: null,
    shuffleHistory: [],
  );
}

/// Persisted values of [AppSettingsState.musicSource].
class MusicSourceKeys {
  MusicSourceKeys._();
  static const String online = 'online';
  static const String local = 'local';
}

extension AppSettingsRegionX on AppSettingsState {
  bool get isOnlineSource => musicSource != MusicSourceKeys.local;

  /// Discover needs a country and at least one language.
  bool get hasMusicRegion =>
      (musicCountry?.isNotEmpty ?? false) && musicLanguages.isNotEmpty;
}
