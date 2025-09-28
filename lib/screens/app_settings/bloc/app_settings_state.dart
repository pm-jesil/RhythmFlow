part of 'app_settings_bloc.dart';

@freezed
class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState({
    required Map<String, List<String>> whiteListFolder,
    required List<String> supportedAudioFormats,
    required DateTime? lastUpdateMusicLibrary,
    required bool isDarkMode,
    required bool followSystemTheme,
    required int sleepTimerMinutes,
    required bool isSleepTimerEnabled,
    required bool autoPlayNext,
    required bool showNotifications,
    required double playbackSpeed,
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
    isDarkMode: false,
    followSystemTheme: true,
    sleepTimerMinutes: 30,
    isSleepTimerEnabled: false,
    autoPlayNext: true,
    showNotifications: true,
    playbackSpeed: 1.0,
  );
}
