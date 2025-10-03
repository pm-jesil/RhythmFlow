import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../logger/logger.dart';
import '../../screens/widgets/permission_dialog.dart';
import '../../core/widgets/app_custom.dart';
import 'ringtone_service.dart';

/// Centralized permission service for handling all permission-related operations
class PermissionService {
  static final AppLogger _logger = AppLogger('PermissionService');

  /// Check if all required permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    _logger.i('🔍 Checking all required permissions...');

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

  /// Request all required permissions with user-friendly dialogs
  static Future<bool> requestAllRequiredPermissions(
    BuildContext context,
  ) async {
    _logger.i('📋 Requesting all required permissions...');

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
          return await _requestAndroid13Permissions(context);
        } else if (androidVersion >= 30) {
          return await _requestAndroid11Permissions(context);
        } else {
          return await _requestLegacyAndroidPermissions(context);
        }
      } else if (Platform.isIOS) {
        return await _requestIOSPermissions(context);
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

  /// Request permissions for Android 11+ (API 30+)
  static Future<bool> _requestAndroid11Permissions(BuildContext context) async {
    _logger.d('Requesting Android 11+ permissions');

    try {
      final storagePermission = await _requestPermissionWithTimeout(
        Permission.manageExternalStorage,
      );

      if (storagePermission.isGranted) {
        _logger.i('MANAGE_EXTERNAL_STORAGE permission granted');
        return true;
      } else if (storagePermission.isDenied) {
        _logger.w('MANAGE_EXTERNAL_STORAGE permission denied');
        return false;
      } else if (storagePermission.isPermanentlyDenied) {
        _logger.w('MANAGE_EXTERNAL_STORAGE permission permanently denied');
        await _showPermissionDialogInUI(
          context: context,
          title: 'Storage Permission Required',
          message:
              'This app needs access to your device storage to find and play music files.',
          settingsMessage:
              'Please grant the permission in your device settings to continue.',
        );
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting Android 11+ permissions', error: e);
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
        await _showPermissionDialogInUI(
          context: context,
          title: 'Audio Permission Required',
          message:
              'This app needs access to your audio files to find and play music.',
          settingsMessage:
              'Please grant the permission in your device settings to continue.',
        );
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
        await _showPermissionDialogInUI(
          context: context,
          title: 'Storage Permission Required',
          message:
              'This app needs access to your device storage to find and play music files.',
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

  /// Request iOS permissions
  static Future<bool> _requestIOSPermissions(BuildContext context) async {
    _logger.d('Requesting iOS permissions');
    // iOS doesn't require special permissions for accessing music files
    _logger.i('iOS permissions not required for music access');
    return true;
  }

  /// Check Android 11+ permissions
  static Future<bool> _checkAndroid11Permissions() async {
    final storagePermission = await Permission.manageExternalStorage.status;
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
      title: 'Permission Required',
      message:
          'This app needs storage permission to fetch songs from your device.',
      settingsMessage:
          'Please grant the permission in your device settings to continue.',
    );
  }

  /// Check if WRITE_SETTINGS permission is granted using RingtoneService
  static Future<bool> checkWriteSettingsPermission() async {
    return await RingtoneService.hasWriteSettingsPermission();
  }

  /// Request WRITE_SETTINGS permission using RingtoneService
  static Future<bool> requestWriteSettingsPermission(
    BuildContext context,
  ) async {
    try {
      _logger.i('⚙️ Requesting WRITE_SETTINGS permission...');

      final shouldRequest = await AppCustom.showConfirm(
        context: context,
        title: 'System Settings Permission',
        message:
            'To set ringtones, the app needs permission to modify system settings.\n\n'
            'You will be taken to Android Settings where you can enable "Modify system settings" for PMJ Music Player.',
        confirmText: 'Open Settings',
        cancelText: 'Cancel',
      );

      if (shouldRequest != true) {
        _logger.i('User cancelled WRITE_SETTINGS permission request');
        return false;
      }

      return await RingtoneService.requestWriteSettingsPermission();
    } catch (e) {
      _logger.e('Error requesting WRITE_SETTINGS permission: $e');
      return false;
    }
  }

  // ============================================================================
  // COMPREHENSIVE PERMISSION REQUEST SYSTEM
  // ============================================================================

  /// Request all required permissions with comprehensive user guidance
  static Future<void> requestAllRequiredPermissionsComprehensive(
    BuildContext context,
  ) async {
    try {
      _logger.i('🔐 Starting comprehensive permission request flow...');

      // Check if permissions are already granted
      final hasPermissions = await hasAllRequiredPermissions();
      if (hasPermissions) {
        _logger.i('✅ All permissions already granted');
        return;
      }

      // Show comprehensive permission explanation dialog
      final shouldProceed = await _showPermissionExplanationDialog(context);
      if (shouldProceed != true) {
        _logger.i('❌ User declined permission request');
        return;
      }

      // Request permissions step by step
      await _requestPermissionsStepByStep(context);
    } catch (e) {
      _logger.e('❌ Error in permission request flow: $e');
      AppCustom.error(context, 'Error requesting permissions: $e');
    }
  }

  /// Show comprehensive permission explanation dialog
  static Future<bool?> _showPermissionExplanationDialog(
    BuildContext context,
  ) async {
    return await AppCustom.showConfirm(
      context: context,
      title: 'Permissions Required',
      message:
          'PMJ Music Player needs several permissions to work properly:\n\n'
          '📁 **Storage Access** - To scan and play your music files\n'
          '🔔 **Notification** - To show music controls in notification panel\n'
          '📱 **System Settings** - To set ringtones and manage audio focus\n'
          '🎵 **Media Access** - To access your music library\n\n'
          'These permissions are essential for the app to function correctly.',
      confirmText: 'Grant Permissions',
      cancelText: 'Not Now',
    );
  }

  /// Request permissions step by step with detailed feedback
  static Future<void> _requestPermissionsStepByStep(
    BuildContext context,
  ) async {
    try {
      _logger.i('📋 Requesting permissions step by step...');

      // Step 1: Basic storage permissions
      await _requestStoragePermissionsComprehensive(context);

      // Step 2: Media permissions (Android 13+)
      await _requestMediaPermissionsComprehensive(context);

      // Step 3: Notification permissions
      await _requestNotificationPermissionsComprehensive(context);

      // Step 4: System settings permission (for ringtones)
      await _requestSystemSettingsPermissionComprehensive(context);

      // Final check
      final allGranted = await hasAllRequiredPermissions();
      if (allGranted) {
        AppCustom.success(
          context,
          'All permissions granted! You can now use all features.',
        );
        _logger.i('✅ All permissions successfully granted');
      } else {
        AppCustom.warning(
          context,
          'Some permissions were not granted. Some features may not work properly.',
        );
        _logger.w('⚠️ Some permissions were not granted');
      }
    } catch (e) {
      _logger.e('❌ Error in step-by-step permission request: $e');
      AppCustom.error(context, 'Error requesting permissions: $e');
    }
  }

  /// Request storage permissions with detailed explanation
  static Future<void> _requestStoragePermissionsComprehensive(
    BuildContext context,
  ) async {
    try {
      _logger.i('📁 Requesting storage permissions...');

      final granted = await requestAllRequiredPermissions(context);
      if (granted) {
        _logger.i('✅ Storage permissions granted');
        AppCustom.success(
          context,
          'Storage access granted! App can now access your music files.',
        );
      } else {
        _logger.w('⚠️ Storage permissions not granted');
        AppCustom.warning(
          context,
          'Storage permission denied. You may not be able to play music files.',
        );
      }
    } catch (e) {
      _logger.e('❌ Error requesting storage permissions: $e');
    }
  }

  /// Request media permissions for Android 13+
  static Future<void> _requestMediaPermissionsComprehensive(
    BuildContext context,
  ) async {
    try {
      if (!Platform.isAndroid) return;

      _logger.i('🎵 Requesting media permissions...');

      // Check Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) return;

      // Request media permissions
      final audioPermission = await Permission.audio.request();
      final imagesPermission = await Permission.photos.request();

      if (audioPermission.isGranted) {
        _logger.i('✅ Audio media permission granted');
      } else {
        _logger.w('⚠️ Audio media permission denied');
      }

      if (imagesPermission.isGranted) {
        _logger.i('✅ Images media permission granted');
      } else {
        _logger.w('⚠️ Images media permission denied');
      }
    } catch (e) {
      _logger.e('❌ Error requesting media permissions: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissionsComprehensive(
    BuildContext context,
  ) async {
    try {
      _logger.i('🔔 Requesting notification permissions...');

      final notificationPermission = await Permission.notification.request();
      if (notificationPermission.isGranted) {
        _logger.i('✅ Notification permission granted');
        AppCustom.success(
          context,
          'Notification permission granted! You\'ll see music controls in the notification panel.',
        );
      } else {
        _logger.w('⚠️ Notification permission denied');
        AppCustom.warning(
          context,
          'Notification permission denied. You won\'t see music controls in the notification panel.',
        );
      }
    } catch (e) {
      _logger.e('❌ Error requesting notification permissions: $e');
    }
  }

  /// Request system settings permission for ringtones
  static Future<void> _requestSystemSettingsPermissionComprehensive(
    BuildContext context,
  ) async {
    try {
      _logger.i('⚙️ Requesting system settings permission...');

      // Check if already granted
      final hasPermission = await checkWriteSettingsPermission();
      if (hasPermission) {
        _logger.i('✅ System settings permission already granted');
        return;
      }

      // Show explanation for system settings permission
      final shouldRequest = await AppCustom.showConfirm(
        context: context,
        title: 'System Settings Permission',
        message:
            'To set ringtones, the app needs permission to modify system settings. This is a security feature to protect your device.\n\n'
            'You will be taken to Android Settings where you can enable "Modify system settings" for this app.',
        confirmText: 'Open Settings',
        cancelText: 'Skip',
      );

      if (shouldRequest == true) {
        await requestWriteSettingsPermission(context);

        // Check again after user returns
        final granted = await checkWriteSettingsPermission();
        if (granted) {
          AppCustom.success(
            context,
            'System settings permission granted! You can now set ringtones.',
          );
        } else {
          AppCustom.info(
            context,
            'System settings permission not granted. Ringtone setting will not be available.',
          );
        }
      } else {
        AppCustom.info(
          context,
          'System settings permission skipped. Ringtone setting will not be available.',
        );
      }
    } catch (e) {
      _logger.e('❌ Error requesting system settings permission: $e');
    }
  }

  // ============================================================================
  // PERMISSION CHECK UTILITIES
  // ============================================================================

  /// Check if device supports ringtone setting
  static Future<bool> checkDeviceSupport() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }
      return true;
    } catch (e) {
      _logger.e('❌ Error checking device support: $e');
      return false;
    }
  }

  /// Check if notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      _logger.e('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Check if media permissions are granted (Android 13+)
  static Future<bool> checkMediaPermissions() async {
    try {
      if (!Platform.isAndroid) return true;

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) return true;

      final audioPermission = await Permission.audio.status;
      final imagesPermission = await Permission.photos.status;

      return audioPermission.isGranted && imagesPermission.isGranted;
    } catch (e) {
      _logger.e('❌ Error checking media permissions: $e');
      return false;
    }
  }

  // ============================================================================
  // PERMISSION REQUEST UTILITIES
  // ============================================================================

  /// Request notification permission with feedback
  static Future<bool> requestNotificationPermission(
    BuildContext context,
  ) async {
    try {
      _logger.i('🔔 Requesting notification permission...');

      final permission = await Permission.notification.request();
      if (permission.isGranted) {
        _logger.i('✅ Notification permission granted');
        AppCustom.success(context, 'Notification permission granted!');
        return true;
      } else {
        _logger.w('⚠️ Notification permission denied');
        AppCustom.warning(context, 'Notification permission denied.');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error requesting notification permission: $e');
      AppCustom.error(context, 'Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request media permissions with feedback
  static Future<bool> requestMediaPermissions(BuildContext context) async {
    try {
      if (!Platform.isAndroid) return true;

      _logger.i('🎵 Requesting media permissions...');

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) return true;

      final audioPermission = await Permission.audio.request();
      final imagesPermission = await Permission.photos.request();

      final allGranted =
          audioPermission.isGranted && imagesPermission.isGranted;

      if (allGranted) {
        _logger.i('✅ Media permissions granted');
        AppCustom.success(context, 'Media permissions granted!');
      } else {
        _logger.w('⚠️ Some media permissions denied');
        AppCustom.warning(context, 'Some media permissions denied.');
      }

      return allGranted;
    } catch (e) {
      _logger.e('❌ Error requesting media permissions: $e');
      AppCustom.error(context, 'Error requesting media permissions: $e');
      return false;
    }
  }

  // ============================================================================
  // PERMISSION STATUS UTILITIES
  // ============================================================================

  /// Get comprehensive permission status
  static Future<Map<String, bool>> getPermissionStatus() async {
    try {
      final status = <String, bool>{};

      // Storage permissions
      status['storage'] = await hasAllRequiredPermissions();

      // Media permissions
      status['media'] = await checkMediaPermissions();

      // Notification permission
      status['notification'] = await checkNotificationPermission();

      // System settings permission
      status['systemSettings'] = await checkWriteSettingsPermission();

      // Device support
      status['deviceSupport'] = await checkDeviceSupport();

      return status;
    } catch (e) {
      _logger.e('❌ Error getting permission status: $e');
      return {};
    }
  }

  /// Get permission status summary
  static Future<String> getPermissionStatusSummary(BuildContext context) async {
    try {
      final status = await getPermissionStatus();
      final granted = status.values.where((granted) => granted).length;
      final total = status.length;

      if (granted == total) {
        return 'All permissions granted ($granted/$total)';
      } else {
        return 'Some permissions missing ($granted/$total)';
      }
    } catch (e) {
      _logger.e('❌ Error getting permission status summary: $e');
      return 'Permission status unknown';
    }
  }
}
