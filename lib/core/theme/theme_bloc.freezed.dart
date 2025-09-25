// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ThemeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() toggleTheme,
    required TResult Function(bool isDarkMode) setTheme,
    required TResult Function() followSystem,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? toggleTheme,
    TResult? Function(bool isDarkMode)? setTheme,
    TResult? Function()? followSystem,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? toggleTheme,
    TResult Function(bool isDarkMode)? setTheme,
    TResult Function()? followSystem,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_ToggleTheme value) toggleTheme,
    required TResult Function(_SetTheme value) setTheme,
    required TResult Function(_FollowSystem value) followSystem,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_ToggleTheme value)? toggleTheme,
    TResult? Function(_SetTheme value)? setTheme,
    TResult? Function(_FollowSystem value)? followSystem,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_ToggleTheme value)? toggleTheme,
    TResult Function(_SetTheme value)? setTheme,
    TResult Function(_FollowSystem value)? followSystem,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThemeEventCopyWith<$Res> {
  factory $ThemeEventCopyWith(
    ThemeEvent value,
    $Res Function(ThemeEvent) then,
  ) = _$ThemeEventCopyWithImpl<$Res, ThemeEvent>;
}

/// @nodoc
class _$ThemeEventCopyWithImpl<$Res, $Val extends ThemeEvent>
    implements $ThemeEventCopyWith<$Res> {
  _$ThemeEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitializeImplCopyWith<$Res> {
  factory _$$InitializeImplCopyWith(
    _$InitializeImpl value,
    $Res Function(_$InitializeImpl) then,
  ) = __$$InitializeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitializeImplCopyWithImpl<$Res>
    extends _$ThemeEventCopyWithImpl<$Res, _$InitializeImpl>
    implements _$$InitializeImplCopyWith<$Res> {
  __$$InitializeImplCopyWithImpl(
    _$InitializeImpl _value,
    $Res Function(_$InitializeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitializeImpl implements _Initialize {
  const _$InitializeImpl();

  @override
  String toString() {
    return 'ThemeEvent.initialize()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitializeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() toggleTheme,
    required TResult Function(bool isDarkMode) setTheme,
    required TResult Function() followSystem,
  }) {
    return initialize();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? toggleTheme,
    TResult? Function(bool isDarkMode)? setTheme,
    TResult? Function()? followSystem,
  }) {
    return initialize?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? toggleTheme,
    TResult Function(bool isDarkMode)? setTheme,
    TResult Function()? followSystem,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_ToggleTheme value) toggleTheme,
    required TResult Function(_SetTheme value) setTheme,
    required TResult Function(_FollowSystem value) followSystem,
  }) {
    return initialize(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_ToggleTheme value)? toggleTheme,
    TResult? Function(_SetTheme value)? setTheme,
    TResult? Function(_FollowSystem value)? followSystem,
  }) {
    return initialize?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_ToggleTheme value)? toggleTheme,
    TResult Function(_SetTheme value)? setTheme,
    TResult Function(_FollowSystem value)? followSystem,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize(this);
    }
    return orElse();
  }
}

abstract class _Initialize implements ThemeEvent {
  const factory _Initialize() = _$InitializeImpl;
}

/// @nodoc
abstract class _$$ToggleThemeImplCopyWith<$Res> {
  factory _$$ToggleThemeImplCopyWith(
    _$ToggleThemeImpl value,
    $Res Function(_$ToggleThemeImpl) then,
  ) = __$$ToggleThemeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ToggleThemeImplCopyWithImpl<$Res>
    extends _$ThemeEventCopyWithImpl<$Res, _$ToggleThemeImpl>
    implements _$$ToggleThemeImplCopyWith<$Res> {
  __$$ToggleThemeImplCopyWithImpl(
    _$ToggleThemeImpl _value,
    $Res Function(_$ToggleThemeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ToggleThemeImpl implements _ToggleTheme {
  const _$ToggleThemeImpl();

  @override
  String toString() {
    return 'ThemeEvent.toggleTheme()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ToggleThemeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() toggleTheme,
    required TResult Function(bool isDarkMode) setTheme,
    required TResult Function() followSystem,
  }) {
    return toggleTheme();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? toggleTheme,
    TResult? Function(bool isDarkMode)? setTheme,
    TResult? Function()? followSystem,
  }) {
    return toggleTheme?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? toggleTheme,
    TResult Function(bool isDarkMode)? setTheme,
    TResult Function()? followSystem,
    required TResult orElse(),
  }) {
    if (toggleTheme != null) {
      return toggleTheme();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_ToggleTheme value) toggleTheme,
    required TResult Function(_SetTheme value) setTheme,
    required TResult Function(_FollowSystem value) followSystem,
  }) {
    return toggleTheme(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_ToggleTheme value)? toggleTheme,
    TResult? Function(_SetTheme value)? setTheme,
    TResult? Function(_FollowSystem value)? followSystem,
  }) {
    return toggleTheme?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_ToggleTheme value)? toggleTheme,
    TResult Function(_SetTheme value)? setTheme,
    TResult Function(_FollowSystem value)? followSystem,
    required TResult orElse(),
  }) {
    if (toggleTheme != null) {
      return toggleTheme(this);
    }
    return orElse();
  }
}

abstract class _ToggleTheme implements ThemeEvent {
  const factory _ToggleTheme() = _$ToggleThemeImpl;
}

/// @nodoc
abstract class _$$SetThemeImplCopyWith<$Res> {
  factory _$$SetThemeImplCopyWith(
    _$SetThemeImpl value,
    $Res Function(_$SetThemeImpl) then,
  ) = __$$SetThemeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isDarkMode});
}

/// @nodoc
class __$$SetThemeImplCopyWithImpl<$Res>
    extends _$ThemeEventCopyWithImpl<$Res, _$SetThemeImpl>
    implements _$$SetThemeImplCopyWith<$Res> {
  __$$SetThemeImplCopyWithImpl(
    _$SetThemeImpl _value,
    $Res Function(_$SetThemeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isDarkMode = null}) {
    return _then(
      _$SetThemeImpl(
        isDarkMode: null == isDarkMode
            ? _value.isDarkMode
            : isDarkMode // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SetThemeImpl implements _SetTheme {
  const _$SetThemeImpl({required this.isDarkMode});

  @override
  final bool isDarkMode;

  @override
  String toString() {
    return 'ThemeEvent.setTheme(isDarkMode: $isDarkMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetThemeImpl &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isDarkMode);

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetThemeImplCopyWith<_$SetThemeImpl> get copyWith =>
      __$$SetThemeImplCopyWithImpl<_$SetThemeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() toggleTheme,
    required TResult Function(bool isDarkMode) setTheme,
    required TResult Function() followSystem,
  }) {
    return setTheme(isDarkMode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? toggleTheme,
    TResult? Function(bool isDarkMode)? setTheme,
    TResult? Function()? followSystem,
  }) {
    return setTheme?.call(isDarkMode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? toggleTheme,
    TResult Function(bool isDarkMode)? setTheme,
    TResult Function()? followSystem,
    required TResult orElse(),
  }) {
    if (setTheme != null) {
      return setTheme(isDarkMode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_ToggleTheme value) toggleTheme,
    required TResult Function(_SetTheme value) setTheme,
    required TResult Function(_FollowSystem value) followSystem,
  }) {
    return setTheme(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_ToggleTheme value)? toggleTheme,
    TResult? Function(_SetTheme value)? setTheme,
    TResult? Function(_FollowSystem value)? followSystem,
  }) {
    return setTheme?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_ToggleTheme value)? toggleTheme,
    TResult Function(_SetTheme value)? setTheme,
    TResult Function(_FollowSystem value)? followSystem,
    required TResult orElse(),
  }) {
    if (setTheme != null) {
      return setTheme(this);
    }
    return orElse();
  }
}

abstract class _SetTheme implements ThemeEvent {
  const factory _SetTheme({required final bool isDarkMode}) = _$SetThemeImpl;

  bool get isDarkMode;

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetThemeImplCopyWith<_$SetThemeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FollowSystemImplCopyWith<$Res> {
  factory _$$FollowSystemImplCopyWith(
    _$FollowSystemImpl value,
    $Res Function(_$FollowSystemImpl) then,
  ) = __$$FollowSystemImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FollowSystemImplCopyWithImpl<$Res>
    extends _$ThemeEventCopyWithImpl<$Res, _$FollowSystemImpl>
    implements _$$FollowSystemImplCopyWith<$Res> {
  __$$FollowSystemImplCopyWithImpl(
    _$FollowSystemImpl _value,
    $Res Function(_$FollowSystemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThemeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FollowSystemImpl implements _FollowSystem {
  const _$FollowSystemImpl();

  @override
  String toString() {
    return 'ThemeEvent.followSystem()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$FollowSystemImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialize,
    required TResult Function() toggleTheme,
    required TResult Function(bool isDarkMode) setTheme,
    required TResult Function() followSystem,
  }) {
    return followSystem();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialize,
    TResult? Function()? toggleTheme,
    TResult? Function(bool isDarkMode)? setTheme,
    TResult? Function()? followSystem,
  }) {
    return followSystem?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialize,
    TResult Function()? toggleTheme,
    TResult Function(bool isDarkMode)? setTheme,
    TResult Function()? followSystem,
    required TResult orElse(),
  }) {
    if (followSystem != null) {
      return followSystem();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_ToggleTheme value) toggleTheme,
    required TResult Function(_SetTheme value) setTheme,
    required TResult Function(_FollowSystem value) followSystem,
  }) {
    return followSystem(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_ToggleTheme value)? toggleTheme,
    TResult? Function(_SetTheme value)? setTheme,
    TResult? Function(_FollowSystem value)? followSystem,
  }) {
    return followSystem?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_ToggleTheme value)? toggleTheme,
    TResult Function(_SetTheme value)? setTheme,
    TResult Function(_FollowSystem value)? followSystem,
    required TResult orElse(),
  }) {
    if (followSystem != null) {
      return followSystem(this);
    }
    return orElse();
  }
}

abstract class _FollowSystem implements ThemeEvent {
  const factory _FollowSystem() = _$FollowSystemImpl;
}

/// @nodoc
mixin _$ThemeState {
  bool get isDarkMode => throw _privateConstructorUsedError;
  bool get isFollowingSystem => throw _privateConstructorUsedError;

  /// Create a copy of ThemeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThemeStateCopyWith<ThemeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThemeStateCopyWith<$Res> {
  factory $ThemeStateCopyWith(
    ThemeState value,
    $Res Function(ThemeState) then,
  ) = _$ThemeStateCopyWithImpl<$Res, ThemeState>;
  @useResult
  $Res call({bool isDarkMode, bool isFollowingSystem});
}

/// @nodoc
class _$ThemeStateCopyWithImpl<$Res, $Val extends ThemeState>
    implements $ThemeStateCopyWith<$Res> {
  _$ThemeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThemeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isDarkMode = null, Object? isFollowingSystem = null}) {
    return _then(
      _value.copyWith(
            isDarkMode: null == isDarkMode
                ? _value.isDarkMode
                : isDarkMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFollowingSystem: null == isFollowingSystem
                ? _value.isFollowingSystem
                : isFollowingSystem // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ThemeStateImplCopyWith<$Res>
    implements $ThemeStateCopyWith<$Res> {
  factory _$$ThemeStateImplCopyWith(
    _$ThemeStateImpl value,
    $Res Function(_$ThemeStateImpl) then,
  ) = __$$ThemeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isDarkMode, bool isFollowingSystem});
}

/// @nodoc
class __$$ThemeStateImplCopyWithImpl<$Res>
    extends _$ThemeStateCopyWithImpl<$Res, _$ThemeStateImpl>
    implements _$$ThemeStateImplCopyWith<$Res> {
  __$$ThemeStateImplCopyWithImpl(
    _$ThemeStateImpl _value,
    $Res Function(_$ThemeStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThemeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isDarkMode = null, Object? isFollowingSystem = null}) {
    return _then(
      _$ThemeStateImpl(
        isDarkMode: null == isDarkMode
            ? _value.isDarkMode
            : isDarkMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFollowingSystem: null == isFollowingSystem
            ? _value.isFollowingSystem
            : isFollowingSystem // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ThemeStateImpl implements _ThemeState {
  const _$ThemeStateImpl({
    required this.isDarkMode,
    required this.isFollowingSystem,
  });

  @override
  final bool isDarkMode;
  @override
  final bool isFollowingSystem;

  @override
  String toString() {
    return 'ThemeState(isDarkMode: $isDarkMode, isFollowingSystem: $isFollowingSystem)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThemeStateImpl &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode) &&
            (identical(other.isFollowingSystem, isFollowingSystem) ||
                other.isFollowingSystem == isFollowingSystem));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isDarkMode, isFollowingSystem);

  /// Create a copy of ThemeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThemeStateImplCopyWith<_$ThemeStateImpl> get copyWith =>
      __$$ThemeStateImplCopyWithImpl<_$ThemeStateImpl>(this, _$identity);
}

abstract class _ThemeState implements ThemeState {
  const factory _ThemeState({
    required final bool isDarkMode,
    required final bool isFollowingSystem,
  }) = _$ThemeStateImpl;

  @override
  bool get isDarkMode;
  @override
  bool get isFollowingSystem;

  /// Create a copy of ThemeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThemeStateImplCopyWith<_$ThemeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
