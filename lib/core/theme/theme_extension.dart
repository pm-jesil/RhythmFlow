import 'package:flutter/material.dart';
import 'app_theme.dart';

extension ThemeExtension on BuildContext {
  // 🎨 Reactive Theme Color Access (Will rebuild when theme changes!)
  Color get backgroundColor => _isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground;
  Color get surfaceColor => _isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get cardColor => _isDarkMode ? AppTheme.darkCard : AppTheme.lightCard;
  Color get onSurfaceColor => _isDarkMode ? AppTheme.darkOnSurface : AppTheme.lightOnSurface;
  Color get onSurfaceVariantColor => _isDarkMode ? AppTheme.darkOnSurfaceVariant : AppTheme.lightOnSurfaceVariant;
  LinearGradient get backgroundGradient => _isDarkMode ? AppTheme.darkBackgroundGradient : AppTheme.lightBackgroundGradient;
  
  // 🎯 Primary Colors (always available)
  Color get primaryStart => AppTheme.primaryStart;
  Color get primaryEnd => AppTheme.primaryEnd;
  LinearGradient get primaryGradient => AppTheme.primaryGradient;
  
  // 🎵 Accent Colors (always available)
  Color get accentRed => AppTheme.accentRed;
  Color get accentTeal => AppTheme.accentTeal;
  Color get accentGreen => AppTheme.accentGreen;
  
  // 🚨 Status Colors (always available)
  Color get error => AppTheme.error;
  Color get success => AppTheme.success;
  Color get warning => AppTheme.warning;

  // 📱 Theme Properties
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isLight => Theme.of(this).brightness == Brightness.light;
  
  // 🔧 Helper method to get current theme mode (reactive)
  bool get _isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // 📐 Text Styles
  TextTheme get text => Theme.of(this).textTheme;
  
  // 🎨 Color Scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // 🎭 Theme Data
  ThemeData get theme => Theme.of(this);

  // 📏 Screen Dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
}
