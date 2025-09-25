import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

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

  @override
  Map<String, dynamic>? toJson(AppSettingsState state) {
    try {
      return {
        'whiteListFolder': state.whiteListFolder,
        'supportedAudioFormats': state.supportedAudioFormats,
        'lastUpdateMusicLibrary': state.lastUpdateMusicLibrary?.toIso8601String(),
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
      );
    } catch (e) {
      return null;
    }
  }
}

