part of 'app_settings_bloc.dart';

@freezed
class AppSettingsEvent with _$AppSettingsEvent {
  const factory AppSettingsEvent.updateWhiteListFolder({
    required String platform,
    required String folder,
    @Default(false) bool isRemove,
  }) = _UpdateWhiteListFolder;

  const factory AppSettingsEvent.updateSupportedAudioFormats({
    required String format,
    @Default(false) bool isRemove,
  }) = _UpdateSupportedAudioFormats;

  const factory AppSettingsEvent.updateBlockedFolderList({
    required String platform,
    required String folder,
    @Default(false) bool isRemove,
  }) = _UpdateBlockedFolderList;

  const factory AppSettingsEvent.updateLastMusicLibraryUpdate({
    required DateTime timestamp,
  }) = _UpdateLastMusicLibraryUpdate;

  const factory AppSettingsEvent.resetToDefaults() = _ResetToDefaults;

  const factory AppSettingsEvent.updateAppSettingsState({
    required AppSettingsState newState,
  }) = _UpdateAppSettingsState;

  const factory AppSettingsEvent.updateTheme({
    required bool isDarkMode,
    required bool followSystemTheme,
  }) = _UpdateTheme;

  const factory AppSettingsEvent.updateSleepTimer({
    required int minutes,
    required bool isEnabled,
  }) = _UpdateSleepTimer;

  const factory AppSettingsEvent.updatePlaybackSettings({
    required bool autoPlayNext,
    required bool showNotifications,
    required double playbackSpeed,
  }) = _UpdatePlaybackSettings;

  const factory AppSettingsEvent.updateAiShuffle({
    required bool isEnabled,
  }) = _UpdateAiShuffle;

  const factory AppSettingsEvent.updateBackgroundRefreshTimeGap({
    required int hours,
  }) = _UpdateBackgroundRefreshTimeGap;

  const factory AppSettingsEvent.updateUserProfile({
    required String userName,
    required String nickName,
  }) = _UpdateUserProfile;

  const factory AppSettingsEvent.trackShuffleUsage({
    required String shuffleType,
  }) = _TrackShuffleUsage;

  const factory AppSettingsEvent.updateDailyQuote({
    @Default(false) bool forceUpdate,
  }) = _UpdateDailyQuote;

  const factory AppSettingsEvent.updateNotificationPermissionRejectedCount({
    required int value,
  }) = _UpdateNotificationPermissionRejectedCount;

  const factory AppSettingsEvent.syncAppIntroVisibilityWithBuild({
    required String currentBuildNumber,
  }) = _SyncAppIntroVisibilityWithBuild;

  const factory AppSettingsEvent.dismissAppIntro({
    required String currentBuildNumber,
  }) = _DismissAppIntro;
}
