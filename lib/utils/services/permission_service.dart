import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../logger/logger.dart';
import '../../screens/widgets/permission_dialog.dart';

/// Centralized permission service for essential music player and now-playing notification.
class PermissionService {
  static final AppLogger _logger = AppLogger('PermissionService');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns true if all permissions required for music access are granted.
  static Future<bool> hasAllRequiredPermissions() async {
    _logger.i('🔍 Checking required permissions...');
    try {
      if (!Platform.isAndroid) {
        return Platform.isIOS ? await _checkIOSPermissions() : false;
      }
      final sdk = await _getAndroidVersion();
      _logger.d('Android version: $sdk');
      if (sdk >= 33) return await _checkAndroid13Permissions();
      if (sdk >= 30) return await _checkAndroid11Permissions();
      return await _checkLegacyAndroidPermissions();
    } catch (e) {
      _logger.e('Error checking permissions', error: e);
      return false;
    }
  }

  /// Requests all required permissions (storage/audio + notification on Android 13+).
  /// Uses [context] for dialogs when permission is permanently denied.
  static Future<bool> requestAllRequiredPermissions(
    BuildContext context,
  ) async {
    _logger.i('📋 Requesting required permissions...');
    try {
      if (await hasAllRequiredPermissions()) {
        _logger.i('✅ Permissions already granted');
        return true;
      }
      if (!Platform.isAndroid) {
        if (Platform.isIOS && context.mounted) {
          return await _requestIOSPermissions(context);
        }
        return false;
      }
      final sdk = await _getAndroidVersion();
      _logger.d('Android version: $sdk');
      if (!context.mounted) return false;
      if (sdk >= 33) return await _requestAndroid13Permissions(context);
      if (sdk >= 30) return await _requestAndroid11Permissions(context);
      return await _requestLegacyAndroidPermissions(context);
    } catch (e) {
      _logger.e('Error requesting permissions', error: e);
      return false;
    }
  }

  /// Requests POST_NOTIFICATIONS on Android 13+ so the now-playing notification
  /// can show. Safe to call without context. No-op on iOS or Android < 13.
  static Future<void> requestNotificationPermissionForPlayback() async {
    if (!Platform.isAndroid) return;
    if (!await _isAndroid13OrHigher()) return;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        _logger.d('POST_NOTIFICATIONS already granted');
        return;
      }
      if (status.isPermanentlyDenied) {
        _logger.w(
          'POST_NOTIFICATIONS permanently denied - enable in device settings',
        );
        return;
      }
      final result = await _requestPermissionWithTimeout(Permission.notification);
      if (result.isGranted) {
        _logger.i(
          'POST_NOTIFICATIONS granted - now playing notification will show',
        );
      } else {
        _logger.w(
          'POST_NOTIFICATIONS denied - now playing may not show on Android 13+',
        );
      }
    } catch (e) {
      _logger.e('Error requesting notification permission', error: e);
    }
  }

  /// True if notification permission is granted, or N/A (e.g. Android < 13).
  static Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    if (!await _isAndroid13OrHigher()) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Shows a dialog directing the user to grant music access in settings.
  static Future<void> showPermissionRequiredDialog(BuildContext context) async {
    await PermissionDialog.showPermissionDialog(
      context: context,
      title: 'Music Access Required',
      message: 'This app needs permission to access your music files.',
      settingsMessage:
          'Please grant the permission in your device settings to continue.',
    );
  }

  // ---------------------------------------------------------------------------
  // Private – Android version
  // ---------------------------------------------------------------------------

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

  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    final sdk = await _getAndroidVersion();
    return sdk >= 33;
  }

  // ---------------------------------------------------------------------------
  // Private – Request by platform
  // ---------------------------------------------------------------------------

  static Future<bool> _requestAndroid11Permissions(BuildContext context) async {
    _logger.d('Requesting Android 11-12 permissions');
    try {
      final status = await _requestPermissionWithTimeout(Permission.storage);
      if (status.isGranted) {
        _logger.i('READ_EXTERNAL_STORAGE permission granted');
        return true;
      }
      if (status.isDenied) {
        _logger.w('READ_EXTERNAL_STORAGE permission denied');
        return false;
      }
      if (status.isPermanentlyDenied) {
        _logger.w('READ_EXTERNAL_STORAGE permission permanently denied');
        if (context.mounted) {
          await _showPermissionDialogInUI(
            context: context,
            title: 'Storage Permission Required',
            message: 'This app needs access to your music files to play them.',
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

  /// Android 13+: READ_MEDIA_AUDIO first, then POST_NOTIFICATIONS (via shared helper).
  static Future<bool> _requestAndroid13Permissions(BuildContext context) async {
    _logger.d('Requesting Android 13+ permissions');
    try {
      final audioStatus = await _requestPermissionWithTimeout(Permission.audio);
      if (!audioStatus.isGranted) {
        if (audioStatus.isDenied) {
          _logger.w('READ_MEDIA_AUDIO permission denied');
          return false;
        }
        if (audioStatus.isPermanentlyDenied) {
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
      }
      _logger.i('READ_MEDIA_AUDIO permission granted');
      await requestNotificationPermissionForPlayback();
      return true;
    } catch (e) {
      _logger.e('Error requesting Android 13+ permissions', error: e);
      return false;
    }
  }

  static Future<bool> _requestLegacyAndroidPermissions(
    BuildContext context,
  ) async {
    _logger.d('Requesting legacy Android permissions');
    try {
      final status = await _requestPermissionWithTimeout(Permission.storage);
      if (status.isGranted) {
        _logger.i('Storage permission granted');
        return true;
      }
      if (status.isPermanentlyDenied && context.mounted) {
        _logger.w('Storage permission permanently denied');
        await _showPermissionDialogInUI(
          context: context,
          title: 'Music Access Required',
          message: 'This app needs access to your music files to play them.',
          settingsMessage:
              'Please grant the permission in your device settings to continue.',
        );
      }
      return false;
    } catch (e) {
      _logger.e('Error requesting legacy Android permissions', error: e);
      return false;
    }
  }

  static Future<bool> _requestIOSPermissions(BuildContext context) async {
    _logger.d('Requesting iOS permissions');
    _logger.i('iOS permissions not required for music access');
    return true;
  }

  // ---------------------------------------------------------------------------
  // Private – Check by platform
  // ---------------------------------------------------------------------------

  static Future<bool> _checkAndroid11Permissions() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> _checkAndroid13Permissions() async {
    final status = await Permission.audio.status;
    return status.isGranted;
  }

  static Future<bool> _checkLegacyAndroidPermissions() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> _checkIOSPermissions() async {
    return true;
  }

  // ---------------------------------------------------------------------------
  // Private – Helpers
  // ---------------------------------------------------------------------------

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
}
