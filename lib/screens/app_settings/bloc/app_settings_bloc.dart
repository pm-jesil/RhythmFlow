import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/theme/app_theme.dart';

part 'app_settings_event.dart';
part 'app_settings_state.dart';
part 'app_settings_bloc.freezed.dart';

@singleton
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  AppSettingsBloc() : super(AppSettingsState.initial()) {
    on<_UpdateWhiteListFolder>(_onUpdateWhiteListFolder);
    on<_UpdateSupportedAudioFormats>(_onUpdateSupportedAudioFormats);
    on<_UpdateLastMusicLibraryUpdate>(_onUpdateLastMusicLibraryUpdate);
    on<_ResetToDefaults>(_onResetToDefaults);
    on<_UpdateAppSettingsState>(_onUpdateAppSettingsState);
    on<_UpdateTheme>(_onUpdateTheme);
    on<_UpdateSleepTimer>(_onUpdateSleepTimer);
    on<_UpdatePlaybackSettings>(_onUpdatePlaybackSettings);
    
    // Initialize theme sync
    _initializeThemeSync();
  }
  
  void _initializeThemeSync() {
    // Sync current settings with AppTheme
    AppTheme.updateTheme(
      isDarkMode: state.isDarkMode,
      isFollowingSystem: state.followSystemTheme,
    );
  }

  @override
  String get storagePrefix => 'AppSettingsBloc';

  void _onUpdateWhiteListFolder(_UpdateWhiteListFolder event, Emitter<AppSettingsState> emit) {
    final updatedWhiteList = Map<String, List<String>>.from(state.whiteListFolder);
    final platformFolders = List<String>.from(updatedWhiteList[event.platform] ?? []);
    
    if (event.isRemove) {
      // Remove folder from the list
      platformFolders.remove(event.folder);
    } else {
      // Add folder to the list (if not already present)
      if (!platformFolders.contains(event.folder)) {
        platformFolders.add(event.folder);
      }
    }
    
    updatedWhiteList[event.platform] = platformFolders;
    emit(state.copyWith(whiteListFolder: updatedWhiteList));
  }

  void _onUpdateSupportedAudioFormats(_UpdateSupportedAudioFormats event, Emitter<AppSettingsState> emit) {
    final updatedFormats = List<String>.from(state.supportedAudioFormats);
    
    if (event.isRemove) {
      // Remove format from the list
      updatedFormats.remove(event.format);
    } else {
      // Add format to the list (if not already present)
      if (!updatedFormats.contains(event.format)) {
        updatedFormats.add(event.format);
      }
    }
    
    emit(state.copyWith(supportedAudioFormats: updatedFormats));
  }

  void _onUpdateLastMusicLibraryUpdate(_UpdateLastMusicLibraryUpdate event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(lastUpdateMusicLibrary: event.timestamp));
  }

  void _onResetToDefaults(_ResetToDefaults event, Emitter<AppSettingsState> emit) {
    emit(AppSettingsState.initial());
  }

  void _onUpdateAppSettingsState(_UpdateAppSettingsState event, Emitter<AppSettingsState> emit) {
    emit(event.newState);
  }

  void _onUpdateTheme(_UpdateTheme event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(
      isDarkMode: event.isDarkMode,
      followSystemTheme: event.followSystemTheme,
    ));
    
    // Sync with main app's theme system
    AppTheme.updateTheme(
      isDarkMode: event.isDarkMode,
      isFollowingSystem: event.followSystemTheme,
    );
  }

  void _onUpdateSleepTimer(_UpdateSleepTimer event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(
      sleepTimerMinutes: event.minutes,
      isSleepTimerEnabled: event.isEnabled,
    ));
  }

  void _onUpdatePlaybackSettings(_UpdatePlaybackSettings event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(
      autoPlayNext: event.autoPlayNext,
      showNotifications: event.showNotifications,
      playbackSpeed: event.playbackSpeed,
    ));
  }

  @override
  Map<String, dynamic>? toJson(AppSettingsState state) {
    try {
      return {
        'whiteListFolder': state.whiteListFolder,
        'supportedAudioFormats': state.supportedAudioFormats,
        'lastUpdateMusicLibrary': state.lastUpdateMusicLibrary?.toIso8601String(),
        'isDarkMode': state.isDarkMode,
        'followSystemTheme': state.followSystemTheme,
        'sleepTimerMinutes': state.sleepTimerMinutes,
        'isSleepTimerEnabled': state.isSleepTimerEnabled,
        'autoPlayNext': state.autoPlayNext,
        'showNotifications': state.showNotifications,
        'playbackSpeed': state.playbackSpeed,
      };
    } catch (_) {
      return null; // skip persisting on serialization errors
    }
  }

  @override
  AppSettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return AppSettingsState(
        whiteListFolder: Map<String, List<String>>.from(
          json['whiteListFolder'] ?? {
            'android': ['/storage/emulated/0/Music', '/storage/emulated/0/Download'],
            'ios': [
              '/var/mobile/Media/iTunes_Control/Music',
              '/var/mobile/Media/Music',
            ],
          },
        ),
        supportedAudioFormats: List<String>.from(
          json['supportedAudioFormats'] ?? [
            '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.wma', '.opus',
            '.aiff', '.alac', '.m4b', '.m4p', '.amr', '.3ga',
          ],
        ),
        lastUpdateMusicLibrary: json['lastUpdateMusicLibrary'] != null
            ? DateTime.parse(json['lastUpdateMusicLibrary'])
            : null,
        isDarkMode: json['isDarkMode'] ?? false,
        followSystemTheme: json['followSystemTheme'] ?? true,
        sleepTimerMinutes: json['sleepTimerMinutes'] ?? 30,
        isSleepTimerEnabled: json['isSleepTimerEnabled'] ?? false,
        autoPlayNext: json['autoPlayNext'] ?? true,
        showNotifications: json['showNotifications'] ?? true,
        playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
      );
    } catch (e) {
      return null;
    }
  }
}

