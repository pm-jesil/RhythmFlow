import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../equalizer/bloc/equalizer_bloc.dart';

part 'app_settings_event.dart';
part 'app_settings_state.dart';
part 'app_settings_bloc.freezed.dart';

@singleton
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  AppSettingsBloc() : super(AppSettingsState.initial()) {
    on<_UpdateWhiteListFolder>(_onUpdateWhiteListFolder);
    on<_UpdateBlockedFolderList>(_onUpdateBlockedFolderList);
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
    on<_UpdateDailyQuote>(_onUpdateDailyQuote);
    on<_UpdateNotificationPermissionRejectedCount>(
        _onUpdateNotificationPermissionRejectedCount);

    // Initialize theme sync
    _initializeThemeSync();
    
    // Initialize quote if needed (when quoteUpdateDateTime is null)
    if (state.quoteUpdateDateTime == null) {
      add(const AppSettingsEvent.updateDailyQuote());
    }
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

    // Create new state with preserved values
    final resetState = AppSettingsState(
      // Reset these to defaults
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
      isAiShuffleEnabled: false,
      showNotifications: true,
      playbackSpeed: 1.0,
      appBackgroundRefreshTimeGap: 10,

      // Preserve these values
      userName: currentUserName,
      nickName: currentNickName,
      isDarkMode: currentIsDarkMode,
      followSystemTheme: currentFollowSystemTheme,
      shuffleHistory: [],
      quoteUpdateDateTime: state.quoteUpdateDateTime,
      currentQuoteIndex: state.currentQuoteIndex,
      notificationPermissionRejectedCount: 0,
    );

    emit(resetState);

    // Reset equalizer and sound effects to defaults
    try {
      getIt<EqualizerBloc>().add(const EqualizerEvent.resetToDefaults());
    } catch (_) {}

    // Sync with AppTheme using preserved theme values
    if (currentIsDarkMode != null && currentFollowSystemTheme != null) {
      AppTheme.updateTheme(
        isDarkMode: currentIsDarkMode,
        isFollowingSystem: currentFollowSystemTheme,
      );
    }
  }

  void _onUpdateBlockedFolderList(
    _UpdateBlockedFolderList event,
    Emitter<AppSettingsState> emit,
  ) {
    final updatedBlockedList = Map<String, List<String>>.from(
      state.blockedFolderList,
    );

    final platformFolders = List<String>.from(
      updatedBlockedList[event.platform] ?? [],
    );

    if (event.isRemove) {
      platformFolders.remove(event.folder);
    } else {
      if (!platformFolders.contains(event.folder)) {
        platformFolders.add(event.folder);
      }
    }

    updatedBlockedList[event.platform] = platformFolders;
    emit(state.copyWith(blockedFolderList: updatedBlockedList));
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

  void _onUpdateDailyQuote(
    _UpdateDailyQuote event,
    Emitter<AppSettingsState> emit,
  ) {
    final now = DateTime.now();
    final quoteUpdateDateTime = state.quoteUpdateDateTime;
    
    // Check if quote needs to be updated (more than a day has passed) or force update
    bool shouldUpdate = event.forceUpdate;
    if (!shouldUpdate) {
      if (quoteUpdateDateTime == null) {
        // First time, initialize with a quote
        shouldUpdate = true;
      } else {
        // Check if more than a day has passed
        final difference = now.difference(quoteUpdateDateTime);
        shouldUpdate = difference.inDays >= 1;
      }
    }
    
    if (shouldUpdate) {
      int newQuoteIndex;
      
      if (event.forceUpdate) {
        // When forced (tap), move to next quote in sequence
        newQuoteIndex = (state.currentQuoteIndex + 1) % AppConstants.musicQuotes.length;
      } else {
        // Calculate new quote index based on current date and user name for consistency
        final userName = state.userName ?? 'User';
        final dateBasedSeed = now.year * 10000 + now.month * 100 + now.day;
        final userBasedSeed = userName.hashCode.abs();
        newQuoteIndex = (dateBasedSeed + userBasedSeed) % AppConstants.musicQuotes.length;
      }
      
      emit(state.copyWith(
        quoteUpdateDateTime: now,
        currentQuoteIndex: newQuoteIndex,
      ));
    }
  }

  void _onUpdateNotificationPermissionRejectedCount(
    _UpdateNotificationPermissionRejectedCount event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(
      notificationPermissionRejectedCount: event.value.clamp(0, 2),
    ));
  }

  @override
  Map<String, dynamic>? toJson(AppSettingsState state) {
    try {
      return {
        'whiteListFolder': state.whiteListFolder,
        'blockedFolderList': state.blockedFolderList,
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
        'quoteUpdateDateTime': state.quoteUpdateDateTime?.toIso8601String(),
        'currentQuoteIndex': state.currentQuoteIndex,
        'notificationPermissionRejectedCount':
            state.notificationPermissionRejectedCount,
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
                'android': ['/storage/emulated/0'],
                'ios': ['/var/mobile/Media'],
              },
        ),
        blockedFolderList: Map<String, List<String>>.from(
          json['blockedFolderList'] ??
              {
                'android': [
                  '/storage/emulated/0/Alarms',
                  '/storage/emulated/0/Notifications',
                  '/storage/emulated/0/Ringtones',
                ],
                'ios': [],
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
        appBackgroundRefreshTimeGap: json['appBackgroundRefreshTimeGap'] ?? 10,
        userName: json['userName'],
        nickName: json['nickName'],
        isAiShuffleEnabled: json['isAiShuffleEnabled'] ?? false,
        shuffleHistory: List<String>.from(json['shuffleHistory'] ?? []),
        quoteUpdateDateTime: json['quoteUpdateDateTime'] != null
            ? DateTime.parse(json['quoteUpdateDateTime'])
            : null,
        currentQuoteIndex: json['currentQuoteIndex'] ?? 0,
        notificationPermissionRejectedCount:
            json['notificationPermissionRejectedCount'] ?? 0,
      );
    } catch (e) {
      return null;
    }
  }


}
