import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'app_theme.dart';

part 'theme_bloc.freezed.dart';

// Events
@freezed
class ThemeEvent with _$ThemeEvent {
  const factory ThemeEvent.initialize() = _Initialize;
  const factory ThemeEvent.toggleTheme() = _ToggleTheme;
  const factory ThemeEvent.setTheme({required bool isDarkMode}) = _SetTheme;
  const factory ThemeEvent.followSystem() = _FollowSystem;
}

// State
@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState({
    required bool isDarkMode,
    required bool isFollowingSystem,
  }) = _ThemeState;
  
  factory ThemeState.initial() => const ThemeState(
    isDarkMode: false,
    isFollowingSystem: true,
  );
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<ThemeEvent>((event, emit) async {
      await event.map(
        initialize: (e) => _onInitialize(emit),
        toggleTheme: (e) => _onToggleTheme(emit),
        setTheme: (e) => _onSetTheme(emit, e.isDarkMode),
        followSystem: (e) => _onFollowSystem(emit),
      );
    });
  }

  // Event Handlers
  Future<void> _onInitialize(Emitter<ThemeState> emit) async {
    // Get system theme preference
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final systemBrightness = platformDispatcher.platformBrightness;
    final isSystemDark = systemBrightness == Brightness.dark;
    
    final newState = state.copyWith(
      isDarkMode: isSystemDark,
      isFollowingSystem: true,
    );
    
    emit(newState);
    
    // Update AppTheme manager
    AppTheme.updateTheme(
      isDarkMode: newState.isDarkMode,
      isFollowingSystem: newState.isFollowingSystem,
    );
  }

  Future<void> _onToggleTheme(Emitter<ThemeState> emit) async {
    final newState = state.copyWith(
      isDarkMode: !state.isDarkMode,
      isFollowingSystem: false,
    );
    
    emit(newState);
    
    // Update AppTheme manager
    AppTheme.updateTheme(
      isDarkMode: newState.isDarkMode,
      isFollowingSystem: newState.isFollowingSystem,
    );
  }

  Future<void> _onSetTheme(Emitter<ThemeState> emit, bool isDarkMode) async {
    final newState = state.copyWith(
      isDarkMode: isDarkMode,
      isFollowingSystem: false,
    );
    
    emit(newState);
    
    // Update AppTheme manager
    AppTheme.updateTheme(
      isDarkMode: newState.isDarkMode,
      isFollowingSystem: newState.isFollowingSystem,
    );
  }

  Future<void> _onFollowSystem(Emitter<ThemeState> emit) async {
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final systemBrightness = platformDispatcher.platformBrightness;
    final isSystemDark = systemBrightness == Brightness.dark;
    
    final newState = state.copyWith(
      isDarkMode: isSystemDark,
      isFollowingSystem: true,
    );
    
    emit(newState);
    
    // Update AppTheme manager
    AppTheme.updateTheme(
      isDarkMode: newState.isDarkMode,
      isFollowingSystem: newState.isFollowingSystem,
    );
  }

  // Helper Methods
  ThemeMode get themeMode {
    if (state.isFollowingSystem) {
      return ThemeMode.system;
    }
    return state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => state.isDarkMode;
  bool get isFollowingSystem => state.isFollowingSystem;

  // Quick Actions
  void toggle() => add(const ThemeEvent.toggleTheme());
  void setDark() => add(const ThemeEvent.setTheme(isDarkMode: true));
  void followSystem() => add(const ThemeEvent.followSystem());
}

// Extension for easy access
extension ThemeStateExtension on ThemeState {
  String get themeName {
    if (isFollowingSystem) return 'System';
    return isDarkMode ? 'Dark' : 'Light';
  }
  
  IconData get themeIcon {
    if (isFollowingSystem) return Icons.brightness_auto;
    return isDarkMode ? Icons.dark_mode : Icons.light_mode;
  }
}
