import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../logger/logger.dart';
import '../../screens/widgets/permission_dialog.dart';

/// Centralized permission service for handling essential music player permissions only
class PermissionService {
  static final AppLogger _logger = AppLogger('PermissionService');

  /// Check if all required permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    _logger.i('🔍 Checking required permissions...');

    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        _logger.d('Android version: $androidVersion');

        if (androidVersion >= 33) {
          return await _checkAndroid13Permissions();
        } else if (androidVersion >= 30) {
          return await _checkAndroid11Permissions();
        } else {
          return await _checkLegacyAndroidPermissions();
        }
      } else if (Platform.isIOS) {
        return await _checkIOSPermissions();
      }

      return false;
    } catch (e) {
      _logger.e('Error checking permissions', error: e);
      return false;
    }
  }

  /// Request all required permissions (essential for music player only)
  static Future<bool> requestAllRequiredPermissions(
    BuildContext context,
  ) async {
    _logger.i('📋 Requesting required permissions...');

    try {
      // First check if permissions are already granted
      final alreadyGranted = await hasAllRequiredPermissions();
      if (alreadyGranted) {
        _logger.i('✅ Permissions already granted');
        return true;
      }

      // Check Android version for appropriate permissions
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        _logger.d('Android version: $androidVersion');

        if (androidVersion >= 33) {
          if (context.mounted) {
            return await _requestAndroid13Permissions(context);
          }
        } else if (androidVersion >= 30) {
          if (context.mounted) {
            return await _requestAndroid11Permissions(context);
          }
        } else {
          if (context.mounted) {
            return await _requestLegacyAndroidPermissions(context);
          }
        }
      } else if (Platform.isIOS) {
        if (context.mounted) {
          return await _requestIOSPermissions(context);
        }
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting permissions', error: e);
      return false;
    }
  }

  /// Get Android version
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt;
      }
    } catch (e) {
      _logger.e('Error getting Android version', error: e);
    }
    return 0;
  }

  /// Request permissions for Android 11-12 (API 30-32)
  static Future<bool> _requestAndroid11Permissions(BuildContext context) async {
    _logger.d('Requesting Android 11-12 permissions');

    try {
      final storagePermission = await _requestPermissionWithTimeout(
        Permission.storage,
      );

      if (storagePermission.isGranted) {
        _logger.i('READ_EXTERNAL_STORAGE permission granted');
        return true;
      } else if (storagePermission.isDenied) {
        _logger.w('READ_EXTERNAL_STORAGE permission denied');
        return false;
      } else if (storagePermission.isPermanentlyDenied) {
        _logger.w('READ_EXTERNAL_STORAGE permission permanently denied');
        if (context.mounted) {
          await _showPermissionDialogInUI(
            context: context,
            title: 'Storage Permission Required',
            message:
                'This app needs access to your music files to play them.',
            settingsMessage:
                'Please grant the permission in your device settings to continue.',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting Android 11-12 permissions', error: e);
      return false;
    }
  }

  /// Request permissions for Android 13+ (API 33+)
  static Future<bool> _requestAndroid13Permissions(BuildContext context) async {
    _logger.d('Requesting Android 13+ permissions');

    try {
      final audioPermission = await _requestPermissionWithTimeout(
        Permission.audio,
      );

      if (audioPermission.isGranted) {
        _logger.i('READ_MEDIA_AUDIO permission granted');
        return true;
      } else if (audioPermission.isDenied) {
        _logger.w('READ_MEDIA_AUDIO permission denied');
        return false;
      } else if (audioPermission.isPermanentlyDenied) {
        _logger.w('READ_MEDIA_AUDIO permission permanently denied');
        if (context.mounted) {
          await _showPermissionDialogInUI(
            context: context,
            title: 'Audio Permission Required',
            message:
                'This app needs access to your audio files to find and play music.',
            settingsMessage:
                'Please grant the permission in your device settings to continue.',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting Android 13+ permissions', error: e);
      return false;
    }
  }

  /// Request legacy Android permissions (pre-Android 11)
  static Future<bool> _requestLegacyAndroidPermissions(
    BuildContext context,
  ) async {
    _logger.d('Requesting legacy Android permissions');

    try {
      final storagePermission = await _requestPermissionWithTimeout(
        Permission.storage,
      );

      if (storagePermission.isGranted) {
        _logger.i('Storage permission granted');
        return true;
      } else if (storagePermission.isPermanentlyDenied) {
        _logger.w('Storage permission permanently denied');
        if (context.mounted) {
          await _showPermissionDialogInUI(
            context: context,
            title: 'Music Access Required',
            message:
                'This app needs access to your music files to play them.',
            settingsMessage:
                'Please grant the permission in your device settings to continue.',
          );
        }
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting legacy Android permissions', error: e);
      return false;
    }
  }

  /// Request iOS permissions
  static Future<bool> _requestIOSPermissions(BuildContext context) async {
    _logger.d('Requesting iOS permissions');
    // iOS doesn't require special permissions for accessing music files
    _logger.i('iOS permissions not required for music access');
    return true;
  }

  /// Check Android 11-12 permissions
  static Future<bool> _checkAndroid11Permissions() async {
    final storagePermission = await Permission.storage.status;
    return storagePermission.isGranted;
  }

  /// Check Android 13+ permissions
  static Future<bool> _checkAndroid13Permissions() async {
    final audioPermission = await Permission.audio.status;
    return audioPermission.isGranted;
  }

  /// Check legacy Android permissions
  static Future<bool> _checkLegacyAndroidPermissions() async {
    final storagePermission = await Permission.storage.status;
    return storagePermission.isGranted;
  }

  /// Check iOS permissions
  static Future<bool> _checkIOSPermissions() async {
    // iOS doesn't require special permissions for music access
    return true;
  }

  /// Show permission dialog in UI with navigation to settings
  static Future<void> _showPermissionDialogInUI({
    required BuildContext context,
    required String title,
    required String message,
    String? settingsMessage,
  }) async {
    await PermissionDialog.showPermissionDialog(
      context: context,
      title: title,
      message: message,
      settingsMessage: settingsMessage,
    );
  }

  /// Request permission with timeout to prevent hanging
  static Future<PermissionStatus> _requestPermissionWithTimeout(
    Permission permission,
  ) async {
    try {
      return await permission.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w(
            'Permission request timed out for ${permission.toString()}',
          );
          return PermissionStatus.denied;
        },
      );
    } catch (e) {
      _logger.e(
        'Error requesting permission ${permission.toString()}',
        error: e,
      );
      return PermissionStatus.denied;
    }
  }

  /// Show permission required dialog for song fetching
  static Future<void> showPermissionRequiredDialog(BuildContext context) async {
    await PermissionDialog.showPermissionDialog(
      context: context,
      title: 'Music Access Required',
      message:
          'This app needs permission to access your music files.',
      settingsMessage:
          'Please grant the permission in your device settings to continue.',
    );
  }
}
