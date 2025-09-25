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

  const factory AppSettingsEvent.updateLastMusicLibraryUpdate({
    required DateTime timestamp,
  }) = _UpdateLastMusicLibraryUpdate;

  const factory AppSettingsEvent.resetToDefaults() = _ResetToDefaults;

  const factory AppSettingsEvent.updateAppSettingsState({
    required AppSettingsState newState,
  }) = _UpdateAppSettingsState;
}
