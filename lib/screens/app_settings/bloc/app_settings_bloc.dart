import 'package:flutter/material.dart';
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
    on<_UpdateBackgroundRefreshTimeGap>(_onUpdateBackgroundRefreshTimeGap);
    on<_UpdateUserProfile>(_onUpdateUserProfile);
    on<_UpdateAiShuffle>(_onUpdateAiShuffle);
    on<_TrackShuffleUsage>(_onTrackShuffleUsage);
    on<_UpdateMusicSource>(_onUpdateMusicSource);
    on<_UpdateMusicRegion>(_onUpdateMusicRegion);
    on<_UpdateMusicTastes>(
      (event, emit) => emit(state.copyWith(musicTastes: _cleanList(event.tastes))),
    );
    on<_UpdateDiscoverProfile>(_onUpdateDiscoverProfile);

    // Initialize theme sync
    _initializeThemeSync();
  }

  void _initializeThemeSync() {
    // Get system theme preference
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final systemBrightness = platformDispatcher.platformBrightness;
    final isSystemDark = systemBrightness == Brightness.dark;

    bool? actualIsDarkMode;
    bool? actualFollowSystem;

    // Determine theme logic based on stored values
    if (state.followSystemTheme == null || state.followSystemTheme == true) {
      // First install or follow system is enabled
      actualIsDarkMode = isSystemDark;
      actualFollowSystem = true;
    } else {
      // User has explicitly set a theme preference
      actualIsDarkMode = state.isDarkMode ?? isSystemDark;
      actualFollowSystem = false;
    }

    // Update state if needed
    if (state.isDarkMode != actualIsDarkMode ||
        state.followSystemTheme != actualFollowSystem) {
      add(
        AppSettingsEvent.updateTheme(
          isDarkMode: actualIsDarkMode,
          followSystemTheme: actualFollowSystem,
        ),
      );
    }

    // Sync with AppTheme
    AppTheme.updateTheme(
      isDarkMode: actualIsDarkMode,
      isFollowingSystem: actualFollowSystem,
    );
  }

  @override
  String get storagePrefix => 'AppSettingsBloc';

  void _onUpdateWhiteListFolder(
    _UpdateWhiteListFolder event,
    Emitter<AppSettingsState> emit,
  ) {
    final updatedWhiteList = Map<String, List<String>>.from(
      state.whiteListFolder,
    );
    final platformFolders = List<String>.from(
      updatedWhiteList[event.platform] ?? [],
    );

    if (event.isRemove) {
      // Remove folder from the list
      platformFolders.remove(event.folder);
    } else {
      // Check if we can add more folders (max 6)
      if (platformFolders.length >= 6) {
        // Don't add if already at maximum
        return;
      }

      // Add folder to the list (if not already present)
      if (!platformFolders.contains(event.folder)) {
        platformFolders.add(event.folder);
      }
    }

    updatedWhiteList[event.platform] = platformFolders;
    emit(state.copyWith(whiteListFolder: updatedWhiteList));
  }

  void _onUpdateSupportedAudioFormats(
    _UpdateSupportedAudioFormats event,
    Emitter<AppSettingsState> emit,
  ) {
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

  void _onUpdateLastMusicLibraryUpdate(
    _UpdateLastMusicLibraryUpdate event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(lastUpdateMusicLibrary: event.timestamp));
  }

  void _onResetToDefaults(
    _ResetToDefaults event,
    Emitter<AppSettingsState> emit,
  ) {
    // Preserve user's name, nickname, and theme preferences
    final currentUserName = state.userName;
    final currentNickName = state.nickName;
    final currentIsDarkMode = state.isDarkMode;
    final currentFollowSystemTheme = state.followSystemTheme;
    final currentMusicSource = state.musicSource;
    final currentMusicCountry = state.musicCountry;
    final currentMusicLanguages = state.musicLanguages;
    final currentMusicTastes = state.musicTastes;

    // Create new state with preserved values
    final resetState = AppSettingsState(
      // Reset these to defaults
      whiteListFolder: const {
        'android': [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
        ],
        'ios': [
          '/var/mobile/Media/iTunes_Control/Music',
          '/var/mobile/Media/Music',
        ],
      },
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
      sleepTimerMinutes: 30,
      isSleepTimerEnabled: false,
      autoPlayNext: true,
      isAiShuffleEnabled: true,
      showNotifications: true,
      playbackSpeed: 1.0,
      appBackgroundRefreshTimeGap: 5,

      // Preserve these values
      userName: currentUserName,
      nickName: currentNickName,
      isDarkMode: currentIsDarkMode,
      followSystemTheme: currentFollowSystemTheme,
      shuffleHistory: [],
      musicSource: currentMusicSource,
      musicCountry: currentMusicCountry,
      musicLanguages: currentMusicLanguages,
      musicTastes: currentMusicTastes,
    );

    emit(resetState);

    // Sync with AppTheme using preserved theme values
    if (currentIsDarkMode != null && currentFollowSystemTheme != null) {
      AppTheme.updateTheme(
        isDarkMode: currentIsDarkMode,
        isFollowingSystem: currentFollowSystemTheme,
      );
    }
  }

  void _onUpdateAppSettingsState(
    _UpdateAppSettingsState event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(event.newState);
  }

  void _onUpdateTheme(_UpdateTheme event, Emitter<AppSettingsState> emit) {
    emit(
      state.copyWith(
        isDarkMode: event.isDarkMode,
        followSystemTheme: event.followSystemTheme,
      ),
    );

    // Sync with main app's theme system
    AppTheme.updateTheme(
      isDarkMode: event.isDarkMode,
      isFollowingSystem: event.followSystemTheme,
    );
  }

  void _onUpdateSleepTimer(
    _UpdateSleepTimer event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        sleepTimerMinutes: event.minutes,
        isSleepTimerEnabled: event.isEnabled,
      ),
    );
  }

  void _onUpdatePlaybackSettings(
    _UpdatePlaybackSettings event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        autoPlayNext: event.autoPlayNext,
        showNotifications: event.showNotifications,
        playbackSpeed: event.playbackSpeed,
      ),
    );
  }

  void _onUpdateBackgroundRefreshTimeGap(
    _UpdateBackgroundRefreshTimeGap event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(appBackgroundRefreshTimeGap: event.hours));
  }

  void _onUpdateUserProfile(
    _UpdateUserProfile event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(userName: event.userName, nickName: event.nickName));
  }

  void _onUpdateAiShuffle(
    _UpdateAiShuffle event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isAiShuffleEnabled: event.isEnabled));
    
    // Track shuffle usage when enabling
    if (event.isEnabled) {
      add(AppSettingsEvent.trackShuffleUsage(shuffleType: 'ai_shuffle'));
    }
  }


  void _onTrackShuffleUsage(
    _TrackShuffleUsage event,
    Emitter<AppSettingsState> emit,
  ) {
    final currentHistory = List<String>.from(state.shuffleHistory);
    
    // Add new shuffle type to the beginning of the list
    currentHistory.insert(0, event.shuffleType);
    
    // Keep only the last 3 items
    if (currentHistory.length > 3) {
      currentHistory.removeRange(3, currentHistory.length);
    }
    
    emit(state.copyWith(shuffleHistory: currentHistory));
  }

  void _onUpdateMusicSource(
    _UpdateMusicSource event,
    Emitter<AppSettingsState> emit,
  ) {
    final source = event.source == MusicSourceKeys.local
        ? MusicSourceKeys.local
        : MusicSourceKeys.online;
    emit(state.copyWith(musicSource: source));
  }

  void _onUpdateMusicRegion(
    _UpdateMusicRegion event,
    Emitter<AppSettingsState> emit,
  ) {
    final languages = <String>[];
    for (final code in event.languages) {
      if (code.isNotEmpty && !languages.contains(code)) languages.add(code);
    }
    emit(
      state.copyWith(
        musicCountry: event.country.isEmpty ? null : event.country.toUpperCase(),
        musicLanguages: languages,
      ),
    );
  }

  static List<String> _cleanList(List<String> values) {
    final result = <String>[];
    for (final v in values) {
      final t = v.trim();
      if (t.isNotEmpty && !result.contains(t)) result.add(t);
    }
    return result;
  }

  void _onUpdateDiscoverProfile(
    _UpdateDiscoverProfile event,
    Emitter<AppSettingsState> emit,
  ) {
    final nick = event.nickName?.trim();
    final setName = nick != null && nick.isNotEmpty;
    emit(
      state.copyWith(
        nickName: setName ? nick : state.nickName,
        // userName mirrors the nickname when it was never set (Welcome
        // screen does the same).
        userName: setName && (state.userName?.trim().isEmpty ?? true)
            ? nick
            : state.userName,
        musicCountry: event.country.isEmpty ? state.musicCountry : event.country.toUpperCase(),
        musicLanguages: _cleanList(event.languages),
        musicTastes: _cleanList(event.tastes),
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(AppSettingsState state) {
    try {
      return {
        'whiteListFolder': state.whiteListFolder,
        'supportedAudioFormats': state.supportedAudioFormats,
        'lastUpdateMusicLibrary': state.lastUpdateMusicLibrary
            ?.toIso8601String(),
        'isDarkMode': state.isDarkMode,
        'followSystemTheme': state.followSystemTheme,
        'sleepTimerMinutes': state.sleepTimerMinutes,
        'isSleepTimerEnabled': state.isSleepTimerEnabled,
        'autoPlayNext': state.autoPlayNext,
        'showNotifications': state.showNotifications,
        'playbackSpeed': state.playbackSpeed,
        'appBackgroundRefreshTimeGap': state.appBackgroundRefreshTimeGap,
        'userName': state.userName,
        'nickName': state.nickName,
        'shuffleHistory': state.shuffleHistory,
        'isAiShuffleEnabled': state.isAiShuffleEnabled,
        'musicSource': state.musicSource,
        'musicCountry': state.musicCountry,
        'musicLanguages': state.musicLanguages,
        'musicTastes': state.musicTastes,
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
          json['whiteListFolder'] ??
              {
                'android': [
                  '/storage/emulated/0/Music',
                  '/storage/emulated/0/Download',
                ],
                'ios': [
                  '/var/mobile/Media/iTunes_Control/Music',
                  '/var/mobile/Media/Music',
                ],
              },
        ),
        supportedAudioFormats: List<String>.from(
          json['supportedAudioFormats'] ??
              [
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
        ),
        lastUpdateMusicLibrary: json['lastUpdateMusicLibrary'] != null
            ? DateTime.parse(json['lastUpdateMusicLibrary'])
            : null,
        isDarkMode: json['isDarkMode'], // Keep null if not set
        followSystemTheme: json['followSystemTheme'], // Keep null if not set
        sleepTimerMinutes: json['sleepTimerMinutes'] ?? 30,
        isSleepTimerEnabled: json['isSleepTimerEnabled'] ?? false,
        autoPlayNext: json['autoPlayNext'] ?? true,
        showNotifications: json['showNotifications'] ?? true,
        playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
        appBackgroundRefreshTimeGap: json['appBackgroundRefreshTimeGap'] ?? 5,
        userName: json['userName'],
        nickName: json['nickName'],
        isAiShuffleEnabled: json['isAiShuffleEnabled'] ?? true,
        shuffleHistory: List<String>.from(json['shuffleHistory'] ?? []),
        musicSource: json['musicSource'] == MusicSourceKeys.local
            ? MusicSourceKeys.local
            : MusicSourceKeys.online,
        musicCountry: json['musicCountry'] as String?,
        musicLanguages: List<String>.from(json['musicLanguages'] ?? const []),
        musicTastes: List<String>.from(json['musicTastes'] ?? const []),
      );
    } catch (e) {
      return null;
    }
  }


}
