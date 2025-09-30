import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/app_settings/bloc/app_settings_bloc.dart';

/// Utility class for managing supported audio formats
class FormatUtils {
  /// Get supported audio formats from app settings
  static List<String> getSupportedFormats(BuildContext context) {
    return context.read<AppSettingsBloc>().state.supportedAudioFormats;
  }

  /// Check if a file extension is supported
  static bool isSupportedFormat(String filePath, BuildContext context) {
    final supportedFormats = getSupportedFormats(context);
    final extension = '.${filePath.split('.').last.toLowerCase()}';
    return supportedFormats.contains(extension);
  }

  /// Get supported formats as a set for faster lookup
  static Set<String> getSupportedFormatsSet(BuildContext context) {
    return getSupportedFormats(context).toSet();
  }

  /// Default supported formats (fallback)
  static const List<String> defaultSupportedFormats = [
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
  ];
}
