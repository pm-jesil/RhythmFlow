part of 'app_settings_bloc.dart';

@freezed
abstract class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState({
    required Map<String, List<String>> whiteListFolder,
    required Map<String, List<String>> blockedFolderList,
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
    DateTime? quoteUpdateDateTime,
    required int currentQuoteIndex,
    @Default(0) int notificationPermissionRejectedCount,
  }) = _Initial;

  factory AppSettingsState.initial() => AppSettingsState(
    // Default music folders from fetch_songs.dart
    whiteListFolder: const {
      'android': ['/storage/emulated/0'],
      'ios': ['/var/mobile/Media'],
    },

    blockedFolderList: const {
      'android': [
        '/storage/emulated/0/Alarms',
        '/storage/emulated/0/Notifications',
        '/storage/emulated/0/Ringtones',
      ],
      'ios': [],
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
    isAiShuffleEnabled: false,
    showNotifications: true,
    playbackSpeed: 1.0,
    appBackgroundRefreshTimeGap: 20,
    userName: null,
    nickName: null,
    shuffleHistory: [],
    quoteUpdateDateTime: null,
    currentQuoteIndex: 0,
    notificationPermissionRejectedCount: 0,
  );
}
