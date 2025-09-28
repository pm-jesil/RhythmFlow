// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppSettingsEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsEventCopyWith<$Res> {
  factory $AppSettingsEventCopyWith(
    AppSettingsEvent value,
    $Res Function(AppSettingsEvent) then,
  ) = _$AppSettingsEventCopyWithImpl<$Res, AppSettingsEvent>;
}

/// @nodoc
class _$AppSettingsEventCopyWithImpl<$Res, $Val extends AppSettingsEvent>
    implements $AppSettingsEventCopyWith<$Res> {
  _$AppSettingsEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$UpdateWhiteListFolderImplCopyWith<$Res> {
  factory _$$UpdateWhiteListFolderImplCopyWith(
    _$UpdateWhiteListFolderImpl value,
    $Res Function(_$UpdateWhiteListFolderImpl) then,
  ) = __$$UpdateWhiteListFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String platform, String folder, bool isRemove});
}

/// @nodoc
class __$$UpdateWhiteListFolderImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$UpdateWhiteListFolderImpl>
    implements _$$UpdateWhiteListFolderImplCopyWith<$Res> {
  __$$UpdateWhiteListFolderImplCopyWithImpl(
    _$UpdateWhiteListFolderImpl _value,
    $Res Function(_$UpdateWhiteListFolderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? platform = null,
    Object? folder = null,
    Object? isRemove = null,
  }) {
    return _then(
      _$UpdateWhiteListFolderImpl(
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        folder: null == folder
            ? _value.folder
            : folder // ignore: cast_nullable_to_non_nullable
                  as String,
        isRemove: null == isRemove
            ? _value.isRemove
            : isRemove // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UpdateWhiteListFolderImpl implements _UpdateWhiteListFolder {
  const _$UpdateWhiteListFolderImpl({
    required this.platform,
    required this.folder,
    this.isRemove = false,
  });

  @override
  final String platform;
  @override
  final String folder;
  @override
  @JsonKey()
  final bool isRemove;

  @override
  String toString() {
    return 'AppSettingsEvent.updateWhiteListFolder(platform: $platform, folder: $folder, isRemove: $isRemove)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateWhiteListFolderImpl &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.folder, folder) || other.folder == folder) &&
            (identical(other.isRemove, isRemove) ||
                other.isRemove == isRemove));
  }

  @override
  int get hashCode => Object.hash(runtimeType, platform, folder, isRemove);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateWhiteListFolderImplCopyWith<_$UpdateWhiteListFolderImpl>
  get copyWith =>
      __$$UpdateWhiteListFolderImplCopyWithImpl<_$UpdateWhiteListFolderImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateWhiteListFolder(platform, folder, isRemove);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateWhiteListFolder?.call(platform, folder, isRemove);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateWhiteListFolder != null) {
      return updateWhiteListFolder(platform, folder, isRemove);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateWhiteListFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateWhiteListFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateWhiteListFolder != null) {
      return updateWhiteListFolder(this);
    }
    return orElse();
  }
}

abstract class _UpdateWhiteListFolder implements AppSettingsEvent {
  const factory _UpdateWhiteListFolder({
    required final String platform,
    required final String folder,
    final bool isRemove,
  }) = _$UpdateWhiteListFolderImpl;

  String get platform;
  String get folder;
  bool get isRemove;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateWhiteListFolderImplCopyWith<_$UpdateWhiteListFolderImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateSupportedAudioFormatsImplCopyWith<$Res> {
  factory _$$UpdateSupportedAudioFormatsImplCopyWith(
    _$UpdateSupportedAudioFormatsImpl value,
    $Res Function(_$UpdateSupportedAudioFormatsImpl) then,
  ) = __$$UpdateSupportedAudioFormatsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String format, bool isRemove});
}

/// @nodoc
class __$$UpdateSupportedAudioFormatsImplCopyWithImpl<$Res>
    extends
        _$AppSettingsEventCopyWithImpl<$Res, _$UpdateSupportedAudioFormatsImpl>
    implements _$$UpdateSupportedAudioFormatsImplCopyWith<$Res> {
  __$$UpdateSupportedAudioFormatsImplCopyWithImpl(
    _$UpdateSupportedAudioFormatsImpl _value,
    $Res Function(_$UpdateSupportedAudioFormatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? format = null, Object? isRemove = null}) {
    return _then(
      _$UpdateSupportedAudioFormatsImpl(
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
        isRemove: null == isRemove
            ? _value.isRemove
            : isRemove // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UpdateSupportedAudioFormatsImpl
    implements _UpdateSupportedAudioFormats {
  const _$UpdateSupportedAudioFormatsImpl({
    required this.format,
    this.isRemove = false,
  });

  @override
  final String format;
  @override
  @JsonKey()
  final bool isRemove;

  @override
  String toString() {
    return 'AppSettingsEvent.updateSupportedAudioFormats(format: $format, isRemove: $isRemove)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateSupportedAudioFormatsImpl &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.isRemove, isRemove) ||
                other.isRemove == isRemove));
  }

  @override
  int get hashCode => Object.hash(runtimeType, format, isRemove);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateSupportedAudioFormatsImplCopyWith<_$UpdateSupportedAudioFormatsImpl>
  get copyWith =>
      __$$UpdateSupportedAudioFormatsImplCopyWithImpl<
        _$UpdateSupportedAudioFormatsImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateSupportedAudioFormats(format, isRemove);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateSupportedAudioFormats?.call(format, isRemove);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateSupportedAudioFormats != null) {
      return updateSupportedAudioFormats(format, isRemove);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateSupportedAudioFormats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateSupportedAudioFormats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateSupportedAudioFormats != null) {
      return updateSupportedAudioFormats(this);
    }
    return orElse();
  }
}

abstract class _UpdateSupportedAudioFormats implements AppSettingsEvent {
  const factory _UpdateSupportedAudioFormats({
    required final String format,
    final bool isRemove,
  }) = _$UpdateSupportedAudioFormatsImpl;

  String get format;
  bool get isRemove;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateSupportedAudioFormatsImplCopyWith<_$UpdateSupportedAudioFormatsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateLastMusicLibraryUpdateImplCopyWith<$Res> {
  factory _$$UpdateLastMusicLibraryUpdateImplCopyWith(
    _$UpdateLastMusicLibraryUpdateImpl value,
    $Res Function(_$UpdateLastMusicLibraryUpdateImpl) then,
  ) = __$$UpdateLastMusicLibraryUpdateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DateTime timestamp});
}

/// @nodoc
class __$$UpdateLastMusicLibraryUpdateImplCopyWithImpl<$Res>
    extends
        _$AppSettingsEventCopyWithImpl<$Res, _$UpdateLastMusicLibraryUpdateImpl>
    implements _$$UpdateLastMusicLibraryUpdateImplCopyWith<$Res> {
  __$$UpdateLastMusicLibraryUpdateImplCopyWithImpl(
    _$UpdateLastMusicLibraryUpdateImpl _value,
    $Res Function(_$UpdateLastMusicLibraryUpdateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? timestamp = null}) {
    return _then(
      _$UpdateLastMusicLibraryUpdateImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$UpdateLastMusicLibraryUpdateImpl
    implements _UpdateLastMusicLibraryUpdate {
  const _$UpdateLastMusicLibraryUpdateImpl({required this.timestamp});

  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'AppSettingsEvent.updateLastMusicLibraryUpdate(timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateLastMusicLibraryUpdateImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateLastMusicLibraryUpdateImplCopyWith<
    _$UpdateLastMusicLibraryUpdateImpl
  >
  get copyWith =>
      __$$UpdateLastMusicLibraryUpdateImplCopyWithImpl<
        _$UpdateLastMusicLibraryUpdateImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateLastMusicLibraryUpdate(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateLastMusicLibraryUpdate?.call(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateLastMusicLibraryUpdate != null) {
      return updateLastMusicLibraryUpdate(timestamp);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateLastMusicLibraryUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateLastMusicLibraryUpdate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateLastMusicLibraryUpdate != null) {
      return updateLastMusicLibraryUpdate(this);
    }
    return orElse();
  }
}

abstract class _UpdateLastMusicLibraryUpdate implements AppSettingsEvent {
  const factory _UpdateLastMusicLibraryUpdate({
    required final DateTime timestamp,
  }) = _$UpdateLastMusicLibraryUpdateImpl;

  DateTime get timestamp;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateLastMusicLibraryUpdateImplCopyWith<
    _$UpdateLastMusicLibraryUpdateImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ResetToDefaultsImplCopyWith<$Res> {
  factory _$$ResetToDefaultsImplCopyWith(
    _$ResetToDefaultsImpl value,
    $Res Function(_$ResetToDefaultsImpl) then,
  ) = __$$ResetToDefaultsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ResetToDefaultsImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$ResetToDefaultsImpl>
    implements _$$ResetToDefaultsImplCopyWith<$Res> {
  __$$ResetToDefaultsImplCopyWithImpl(
    _$ResetToDefaultsImpl _value,
    $Res Function(_$ResetToDefaultsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ResetToDefaultsImpl implements _ResetToDefaults {
  const _$ResetToDefaultsImpl();

  @override
  String toString() {
    return 'AppSettingsEvent.resetToDefaults()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ResetToDefaultsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return resetToDefaults();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return resetToDefaults?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (resetToDefaults != null) {
      return resetToDefaults();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return resetToDefaults(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return resetToDefaults?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (resetToDefaults != null) {
      return resetToDefaults(this);
    }
    return orElse();
  }
}

abstract class _ResetToDefaults implements AppSettingsEvent {
  const factory _ResetToDefaults() = _$ResetToDefaultsImpl;
}

/// @nodoc
abstract class _$$UpdateAppSettingsStateImplCopyWith<$Res> {
  factory _$$UpdateAppSettingsStateImplCopyWith(
    _$UpdateAppSettingsStateImpl value,
    $Res Function(_$UpdateAppSettingsStateImpl) then,
  ) = __$$UpdateAppSettingsStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({AppSettingsState newState});

  $AppSettingsStateCopyWith<$Res> get newState;
}

/// @nodoc
class __$$UpdateAppSettingsStateImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$UpdateAppSettingsStateImpl>
    implements _$$UpdateAppSettingsStateImplCopyWith<$Res> {
  __$$UpdateAppSettingsStateImplCopyWithImpl(
    _$UpdateAppSettingsStateImpl _value,
    $Res Function(_$UpdateAppSettingsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? newState = null}) {
    return _then(
      _$UpdateAppSettingsStateImpl(
        newState: null == newState
            ? _value.newState
            : newState // ignore: cast_nullable_to_non_nullable
                  as AppSettingsState,
      ),
    );
  }

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppSettingsStateCopyWith<$Res> get newState {
    return $AppSettingsStateCopyWith<$Res>(_value.newState, (value) {
      return _then(_value.copyWith(newState: value));
    });
  }
}

/// @nodoc

class _$UpdateAppSettingsStateImpl implements _UpdateAppSettingsState {
  const _$UpdateAppSettingsStateImpl({required this.newState});

  @override
  final AppSettingsState newState;

  @override
  String toString() {
    return 'AppSettingsEvent.updateAppSettingsState(newState: $newState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateAppSettingsStateImpl &&
            (identical(other.newState, newState) ||
                other.newState == newState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, newState);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateAppSettingsStateImplCopyWith<_$UpdateAppSettingsStateImpl>
  get copyWith =>
      __$$UpdateAppSettingsStateImplCopyWithImpl<_$UpdateAppSettingsStateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateAppSettingsState(newState);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateAppSettingsState?.call(newState);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateAppSettingsState != null) {
      return updateAppSettingsState(newState);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateAppSettingsState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateAppSettingsState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateAppSettingsState != null) {
      return updateAppSettingsState(this);
    }
    return orElse();
  }
}

abstract class _UpdateAppSettingsState implements AppSettingsEvent {
  const factory _UpdateAppSettingsState({
    required final AppSettingsState newState,
  }) = _$UpdateAppSettingsStateImpl;

  AppSettingsState get newState;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateAppSettingsStateImplCopyWith<_$UpdateAppSettingsStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateThemeImplCopyWith<$Res> {
  factory _$$UpdateThemeImplCopyWith(
    _$UpdateThemeImpl value,
    $Res Function(_$UpdateThemeImpl) then,
  ) = __$$UpdateThemeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isDarkMode, bool followSystemTheme});
}

/// @nodoc
class __$$UpdateThemeImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$UpdateThemeImpl>
    implements _$$UpdateThemeImplCopyWith<$Res> {
  __$$UpdateThemeImplCopyWithImpl(
    _$UpdateThemeImpl _value,
    $Res Function(_$UpdateThemeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isDarkMode = null, Object? followSystemTheme = null}) {
    return _then(
      _$UpdateThemeImpl(
        isDarkMode: null == isDarkMode
            ? _value.isDarkMode
            : isDarkMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        followSystemTheme: null == followSystemTheme
            ? _value.followSystemTheme
            : followSystemTheme // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UpdateThemeImpl implements _UpdateTheme {
  const _$UpdateThemeImpl({
    required this.isDarkMode,
    required this.followSystemTheme,
  });

  @override
  final bool isDarkMode;
  @override
  final bool followSystemTheme;

  @override
  String toString() {
    return 'AppSettingsEvent.updateTheme(isDarkMode: $isDarkMode, followSystemTheme: $followSystemTheme)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateThemeImpl &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode) &&
            (identical(other.followSystemTheme, followSystemTheme) ||
                other.followSystemTheme == followSystemTheme));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isDarkMode, followSystemTheme);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateThemeImplCopyWith<_$UpdateThemeImpl> get copyWith =>
      __$$UpdateThemeImplCopyWithImpl<_$UpdateThemeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateTheme(isDarkMode, followSystemTheme);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateTheme?.call(isDarkMode, followSystemTheme);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateTheme != null) {
      return updateTheme(isDarkMode, followSystemTheme);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateTheme(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateTheme?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateTheme != null) {
      return updateTheme(this);
    }
    return orElse();
  }
}

abstract class _UpdateTheme implements AppSettingsEvent {
  const factory _UpdateTheme({
    required final bool isDarkMode,
    required final bool followSystemTheme,
  }) = _$UpdateThemeImpl;

  bool get isDarkMode;
  bool get followSystemTheme;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateThemeImplCopyWith<_$UpdateThemeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateSleepTimerImplCopyWith<$Res> {
  factory _$$UpdateSleepTimerImplCopyWith(
    _$UpdateSleepTimerImpl value,
    $Res Function(_$UpdateSleepTimerImpl) then,
  ) = __$$UpdateSleepTimerImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int minutes, bool isEnabled});
}

/// @nodoc
class __$$UpdateSleepTimerImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$UpdateSleepTimerImpl>
    implements _$$UpdateSleepTimerImplCopyWith<$Res> {
  __$$UpdateSleepTimerImplCopyWithImpl(
    _$UpdateSleepTimerImpl _value,
    $Res Function(_$UpdateSleepTimerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? minutes = null, Object? isEnabled = null}) {
    return _then(
      _$UpdateSleepTimerImpl(
        minutes: null == minutes
            ? _value.minutes
            : minutes // ignore: cast_nullable_to_non_nullable
                  as int,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UpdateSleepTimerImpl implements _UpdateSleepTimer {
  const _$UpdateSleepTimerImpl({
    required this.minutes,
    required this.isEnabled,
  });

  @override
  final int minutes;
  @override
  final bool isEnabled;

  @override
  String toString() {
    return 'AppSettingsEvent.updateSleepTimer(minutes: $minutes, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateSleepTimerImpl &&
            (identical(other.minutes, minutes) || other.minutes == minutes) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @override
  int get hashCode => Object.hash(runtimeType, minutes, isEnabled);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateSleepTimerImplCopyWith<_$UpdateSleepTimerImpl> get copyWith =>
      __$$UpdateSleepTimerImplCopyWithImpl<_$UpdateSleepTimerImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updateSleepTimer(minutes, isEnabled);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updateSleepTimer?.call(minutes, isEnabled);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateSleepTimer != null) {
      return updateSleepTimer(minutes, isEnabled);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updateSleepTimer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updateSleepTimer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updateSleepTimer != null) {
      return updateSleepTimer(this);
    }
    return orElse();
  }
}

abstract class _UpdateSleepTimer implements AppSettingsEvent {
  const factory _UpdateSleepTimer({
    required final int minutes,
    required final bool isEnabled,
  }) = _$UpdateSleepTimerImpl;

  int get minutes;
  bool get isEnabled;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateSleepTimerImplCopyWith<_$UpdateSleepTimerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdatePlaybackSettingsImplCopyWith<$Res> {
  factory _$$UpdatePlaybackSettingsImplCopyWith(
    _$UpdatePlaybackSettingsImpl value,
    $Res Function(_$UpdatePlaybackSettingsImpl) then,
  ) = __$$UpdatePlaybackSettingsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool autoPlayNext, bool showNotifications, double playbackSpeed});
}

/// @nodoc
class __$$UpdatePlaybackSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsEventCopyWithImpl<$Res, _$UpdatePlaybackSettingsImpl>
    implements _$$UpdatePlaybackSettingsImplCopyWith<$Res> {
  __$$UpdatePlaybackSettingsImplCopyWithImpl(
    _$UpdatePlaybackSettingsImpl _value,
    $Res Function(_$UpdatePlaybackSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? autoPlayNext = null,
    Object? showNotifications = null,
    Object? playbackSpeed = null,
  }) {
    return _then(
      _$UpdatePlaybackSettingsImpl(
        autoPlayNext: null == autoPlayNext
            ? _value.autoPlayNext
            : autoPlayNext // ignore: cast_nullable_to_non_nullable
                  as bool,
        showNotifications: null == showNotifications
            ? _value.showNotifications
            : showNotifications // ignore: cast_nullable_to_non_nullable
                  as bool,
        playbackSpeed: null == playbackSpeed
            ? _value.playbackSpeed
            : playbackSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$UpdatePlaybackSettingsImpl implements _UpdatePlaybackSettings {
  const _$UpdatePlaybackSettingsImpl({
    required this.autoPlayNext,
    required this.showNotifications,
    required this.playbackSpeed,
  });

  @override
  final bool autoPlayNext;
  @override
  final bool showNotifications;
  @override
  final double playbackSpeed;

  @override
  String toString() {
    return 'AppSettingsEvent.updatePlaybackSettings(autoPlayNext: $autoPlayNext, showNotifications: $showNotifications, playbackSpeed: $playbackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdatePlaybackSettingsImpl &&
            (identical(other.autoPlayNext, autoPlayNext) ||
                other.autoPlayNext == autoPlayNext) &&
            (identical(other.showNotifications, showNotifications) ||
                other.showNotifications == showNotifications) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, autoPlayNext, showNotifications, playbackSpeed);

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdatePlaybackSettingsImplCopyWith<_$UpdatePlaybackSettingsImpl>
  get copyWith =>
      __$$UpdatePlaybackSettingsImplCopyWithImpl<_$UpdatePlaybackSettingsImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String platform, String folder, bool isRemove)
    updateWhiteListFolder,
    required TResult Function(String format, bool isRemove)
    updateSupportedAudioFormats,
    required TResult Function(DateTime timestamp) updateLastMusicLibraryUpdate,
    required TResult Function() resetToDefaults,
    required TResult Function(AppSettingsState newState) updateAppSettingsState,
    required TResult Function(bool isDarkMode, bool followSystemTheme)
    updateTheme,
    required TResult Function(int minutes, bool isEnabled) updateSleepTimer,
    required TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )
    updatePlaybackSettings,
  }) {
    return updatePlaybackSettings(
      autoPlayNext,
      showNotifications,
      playbackSpeed,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult? Function(String format, bool isRemove)?
    updateSupportedAudioFormats,
    TResult? Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult? Function()? resetToDefaults,
    TResult? Function(AppSettingsState newState)? updateAppSettingsState,
    TResult? Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult? Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult? Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
  }) {
    return updatePlaybackSettings?.call(
      autoPlayNext,
      showNotifications,
      playbackSpeed,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String platform, String folder, bool isRemove)?
    updateWhiteListFolder,
    TResult Function(String format, bool isRemove)? updateSupportedAudioFormats,
    TResult Function(DateTime timestamp)? updateLastMusicLibraryUpdate,
    TResult Function()? resetToDefaults,
    TResult Function(AppSettingsState newState)? updateAppSettingsState,
    TResult Function(bool isDarkMode, bool followSystemTheme)? updateTheme,
    TResult Function(int minutes, bool isEnabled)? updateSleepTimer,
    TResult Function(
      bool autoPlayNext,
      bool showNotifications,
      double playbackSpeed,
    )?
    updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updatePlaybackSettings != null) {
      return updatePlaybackSettings(
        autoPlayNext,
        showNotifications,
        playbackSpeed,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateWhiteListFolder value)
    updateWhiteListFolder,
    required TResult Function(_UpdateSupportedAudioFormats value)
    updateSupportedAudioFormats,
    required TResult Function(_UpdateLastMusicLibraryUpdate value)
    updateLastMusicLibraryUpdate,
    required TResult Function(_ResetToDefaults value) resetToDefaults,
    required TResult Function(_UpdateAppSettingsState value)
    updateAppSettingsState,
    required TResult Function(_UpdateTheme value) updateTheme,
    required TResult Function(_UpdateSleepTimer value) updateSleepTimer,
    required TResult Function(_UpdatePlaybackSettings value)
    updatePlaybackSettings,
  }) {
    return updatePlaybackSettings(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult? Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult? Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult? Function(_ResetToDefaults value)? resetToDefaults,
    TResult? Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult? Function(_UpdateTheme value)? updateTheme,
    TResult? Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult? Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
  }) {
    return updatePlaybackSettings?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateWhiteListFolder value)? updateWhiteListFolder,
    TResult Function(_UpdateSupportedAudioFormats value)?
    updateSupportedAudioFormats,
    TResult Function(_UpdateLastMusicLibraryUpdate value)?
    updateLastMusicLibraryUpdate,
    TResult Function(_ResetToDefaults value)? resetToDefaults,
    TResult Function(_UpdateAppSettingsState value)? updateAppSettingsState,
    TResult Function(_UpdateTheme value)? updateTheme,
    TResult Function(_UpdateSleepTimer value)? updateSleepTimer,
    TResult Function(_UpdatePlaybackSettings value)? updatePlaybackSettings,
    required TResult orElse(),
  }) {
    if (updatePlaybackSettings != null) {
      return updatePlaybackSettings(this);
    }
    return orElse();
  }
}

abstract class _UpdatePlaybackSettings implements AppSettingsEvent {
  const factory _UpdatePlaybackSettings({
    required final bool autoPlayNext,
    required final bool showNotifications,
    required final double playbackSpeed,
  }) = _$UpdatePlaybackSettingsImpl;

  bool get autoPlayNext;
  bool get showNotifications;
  double get playbackSpeed;

  /// Create a copy of AppSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePlaybackSettingsImplCopyWith<_$UpdatePlaybackSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AppSettingsState {
  Map<String, List<String>> get whiteListFolder =>
      throw _privateConstructorUsedError;
  List<String> get supportedAudioFormats => throw _privateConstructorUsedError;
  DateTime? get lastUpdateMusicLibrary => throw _privateConstructorUsedError;
  bool get isDarkMode => throw _privateConstructorUsedError;
  bool get followSystemTheme => throw _privateConstructorUsedError;
  int get sleepTimerMinutes => throw _privateConstructorUsedError;
  bool get isSleepTimerEnabled => throw _privateConstructorUsedError;
  bool get autoPlayNext => throw _privateConstructorUsedError;
  bool get showNotifications => throw _privateConstructorUsedError;
  double get playbackSpeed => throw _privateConstructorUsedError;

  /// Create a copy of AppSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsStateCopyWith<AppSettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsStateCopyWith<$Res> {
  factory $AppSettingsStateCopyWith(
    AppSettingsState value,
    $Res Function(AppSettingsState) then,
  ) = _$AppSettingsStateCopyWithImpl<$Res, AppSettingsState>;
  @useResult
  $Res call({
    Map<String, List<String>> whiteListFolder,
    List<String> supportedAudioFormats,
    DateTime? lastUpdateMusicLibrary,
    bool isDarkMode,
    bool followSystemTheme,
    int sleepTimerMinutes,
    bool isSleepTimerEnabled,
    bool autoPlayNext,
    bool showNotifications,
    double playbackSpeed,
  });
}

/// @nodoc
class _$AppSettingsStateCopyWithImpl<$Res, $Val extends AppSettingsState>
    implements $AppSettingsStateCopyWith<$Res> {
  _$AppSettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? whiteListFolder = null,
    Object? supportedAudioFormats = null,
    Object? lastUpdateMusicLibrary = freezed,
    Object? isDarkMode = null,
    Object? followSystemTheme = null,
    Object? sleepTimerMinutes = null,
    Object? isSleepTimerEnabled = null,
    Object? autoPlayNext = null,
    Object? showNotifications = null,
    Object? playbackSpeed = null,
  }) {
    return _then(
      _value.copyWith(
            whiteListFolder: null == whiteListFolder
                ? _value.whiteListFolder
                : whiteListFolder // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<String>>,
            supportedAudioFormats: null == supportedAudioFormats
                ? _value.supportedAudioFormats
                : supportedAudioFormats // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            lastUpdateMusicLibrary: freezed == lastUpdateMusicLibrary
                ? _value.lastUpdateMusicLibrary
                : lastUpdateMusicLibrary // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isDarkMode: null == isDarkMode
                ? _value.isDarkMode
                : isDarkMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            followSystemTheme: null == followSystemTheme
                ? _value.followSystemTheme
                : followSystemTheme // ignore: cast_nullable_to_non_nullable
                      as bool,
            sleepTimerMinutes: null == sleepTimerMinutes
                ? _value.sleepTimerMinutes
                : sleepTimerMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            isSleepTimerEnabled: null == isSleepTimerEnabled
                ? _value.isSleepTimerEnabled
                : isSleepTimerEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            autoPlayNext: null == autoPlayNext
                ? _value.autoPlayNext
                : autoPlayNext // ignore: cast_nullable_to_non_nullable
                      as bool,
            showNotifications: null == showNotifications
                ? _value.showNotifications
                : showNotifications // ignore: cast_nullable_to_non_nullable
                      as bool,
            playbackSpeed: null == playbackSpeed
                ? _value.playbackSpeed
                : playbackSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res>
    implements $AppSettingsStateCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, List<String>> whiteListFolder,
    List<String> supportedAudioFormats,
    DateTime? lastUpdateMusicLibrary,
    bool isDarkMode,
    bool followSystemTheme,
    int sleepTimerMinutes,
    bool isSleepTimerEnabled,
    bool autoPlayNext,
    bool showNotifications,
    double playbackSpeed,
  });
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$AppSettingsStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? whiteListFolder = null,
    Object? supportedAudioFormats = null,
    Object? lastUpdateMusicLibrary = freezed,
    Object? isDarkMode = null,
    Object? followSystemTheme = null,
    Object? sleepTimerMinutes = null,
    Object? isSleepTimerEnabled = null,
    Object? autoPlayNext = null,
    Object? showNotifications = null,
    Object? playbackSpeed = null,
  }) {
    return _then(
      _$InitialImpl(
        whiteListFolder: null == whiteListFolder
            ? _value._whiteListFolder
            : whiteListFolder // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>,
        supportedAudioFormats: null == supportedAudioFormats
            ? _value._supportedAudioFormats
            : supportedAudioFormats // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        lastUpdateMusicLibrary: freezed == lastUpdateMusicLibrary
            ? _value.lastUpdateMusicLibrary
            : lastUpdateMusicLibrary // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isDarkMode: null == isDarkMode
            ? _value.isDarkMode
            : isDarkMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        followSystemTheme: null == followSystemTheme
            ? _value.followSystemTheme
            : followSystemTheme // ignore: cast_nullable_to_non_nullable
                  as bool,
        sleepTimerMinutes: null == sleepTimerMinutes
            ? _value.sleepTimerMinutes
            : sleepTimerMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        isSleepTimerEnabled: null == isSleepTimerEnabled
            ? _value.isSleepTimerEnabled
            : isSleepTimerEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoPlayNext: null == autoPlayNext
            ? _value.autoPlayNext
            : autoPlayNext // ignore: cast_nullable_to_non_nullable
                  as bool,
        showNotifications: null == showNotifications
            ? _value.showNotifications
            : showNotifications // ignore: cast_nullable_to_non_nullable
                  as bool,
        playbackSpeed: null == playbackSpeed
            ? _value.playbackSpeed
            : playbackSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl({
    required final Map<String, List<String>> whiteListFolder,
    required final List<String> supportedAudioFormats,
    required this.lastUpdateMusicLibrary,
    required this.isDarkMode,
    required this.followSystemTheme,
    required this.sleepTimerMinutes,
    required this.isSleepTimerEnabled,
    required this.autoPlayNext,
    required this.showNotifications,
    required this.playbackSpeed,
  }) : _whiteListFolder = whiteListFolder,
       _supportedAudioFormats = supportedAudioFormats;

  final Map<String, List<String>> _whiteListFolder;
  @override
  Map<String, List<String>> get whiteListFolder {
    if (_whiteListFolder is EqualUnmodifiableMapView) return _whiteListFolder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_whiteListFolder);
  }

  final List<String> _supportedAudioFormats;
  @override
  List<String> get supportedAudioFormats {
    if (_supportedAudioFormats is EqualUnmodifiableListView)
      return _supportedAudioFormats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedAudioFormats);
  }

  @override
  final DateTime? lastUpdateMusicLibrary;
  @override
  final bool isDarkMode;
  @override
  final bool followSystemTheme;
  @override
  final int sleepTimerMinutes;
  @override
  final bool isSleepTimerEnabled;
  @override
  final bool autoPlayNext;
  @override
  final bool showNotifications;
  @override
  final double playbackSpeed;

  @override
  String toString() {
    return 'AppSettingsState(whiteListFolder: $whiteListFolder, supportedAudioFormats: $supportedAudioFormats, lastUpdateMusicLibrary: $lastUpdateMusicLibrary, isDarkMode: $isDarkMode, followSystemTheme: $followSystemTheme, sleepTimerMinutes: $sleepTimerMinutes, isSleepTimerEnabled: $isSleepTimerEnabled, autoPlayNext: $autoPlayNext, showNotifications: $showNotifications, playbackSpeed: $playbackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InitialImpl &&
            const DeepCollectionEquality().equals(
              other._whiteListFolder,
              _whiteListFolder,
            ) &&
            const DeepCollectionEquality().equals(
              other._supportedAudioFormats,
              _supportedAudioFormats,
            ) &&
            (identical(other.lastUpdateMusicLibrary, lastUpdateMusicLibrary) ||
                other.lastUpdateMusicLibrary == lastUpdateMusicLibrary) &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode) &&
            (identical(other.followSystemTheme, followSystemTheme) ||
                other.followSystemTheme == followSystemTheme) &&
            (identical(other.sleepTimerMinutes, sleepTimerMinutes) ||
                other.sleepTimerMinutes == sleepTimerMinutes) &&
            (identical(other.isSleepTimerEnabled, isSleepTimerEnabled) ||
                other.isSleepTimerEnabled == isSleepTimerEnabled) &&
            (identical(other.autoPlayNext, autoPlayNext) ||
                other.autoPlayNext == autoPlayNext) &&
            (identical(other.showNotifications, showNotifications) ||
                other.showNotifications == showNotifications) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_whiteListFolder),
    const DeepCollectionEquality().hash(_supportedAudioFormats),
    lastUpdateMusicLibrary,
    isDarkMode,
    followSystemTheme,
    sleepTimerMinutes,
    isSleepTimerEnabled,
    autoPlayNext,
    showNotifications,
    playbackSpeed,
  );

  /// Create a copy of AppSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      __$$InitialImplCopyWithImpl<_$InitialImpl>(this, _$identity);
}

abstract class _Initial implements AppSettingsState {
  const factory _Initial({
    required final Map<String, List<String>> whiteListFolder,
    required final List<String> supportedAudioFormats,
    required final DateTime? lastUpdateMusicLibrary,
    required final bool isDarkMode,
    required final bool followSystemTheme,
    required final int sleepTimerMinutes,
    required final bool isSleepTimerEnabled,
    required final bool autoPlayNext,
    required final bool showNotifications,
    required final double playbackSpeed,
  }) = _$InitialImpl;

  @override
  Map<String, List<String>> get whiteListFolder;
  @override
  List<String> get supportedAudioFormats;
  @override
  DateTime? get lastUpdateMusicLibrary;
  @override
  bool get isDarkMode;
  @override
  bool get followSystemTheme;
  @override
  int get sleepTimerMinutes;
  @override
  bool get isSleepTimerEnabled;
  @override
  bool get autoPlayNext;
  @override
  bool get showNotifications;
  @override
  double get playbackSpeed;

  /// Create a copy of AppSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
