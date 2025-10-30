import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../logger/logger.dart';

class AppUpdateService {
  static final AppLogger _logger = AppLogger('AppUpdateService');


  /// Silent, non-blocking update check that does not show any UI.
  /// - For high priority updates, attempts immediate update (may show system UI).
  /// - For flexible updates, starts download silently in background.
  static Future<void> checkForUpdatesSilently() async {
    try {
      _logger.i('🔍 (Silent) Checking for app updates in background...');

      if (Platform.isIOS) {
        _logger.i('📱 iOS detected - skipping update check (silent)');
        return;
      }

      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        _logger.i('🔄 (Silent) Update available. Priority: ${updateInfo.updatePriority}');
        
        if (updateInfo.updatePriority == 5) {
          // High priority - trigger immediate update
          await performImmediateUpdate();
        } else {
          // Flexible update - start silently
          await startFlexibleUpdate();
        }
      } else {
        _logger.i('✅ (Silent) App is up to date');
      }
    } catch (e) {
      _logger.e('❌ (Silent) Error checking for updates: $e');
    }
  }

  /// Perform immediate update (full screen)
  static Future<void> performImmediateUpdate() async {
    try {
      _logger.i('🚀 Starting immediate update...');
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      _logger.e('❌ Error performing immediate update: $e');
    }
  }

  /// Start flexible update (background download)
  static Future<void> startFlexibleUpdate() async {
    try {
      _logger.i('📥 Starting flexible update...');
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      _logger.e('❌ Error starting flexible update: $e');
    }
  }

  /// Complete flexible update (install)
  static Future<void> completeFlexibleUpdate() async {
    try {
      _logger.i('✅ Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      _logger.e('❌ Error completing flexible update: $e');
    }
  }

  /// Get current app version info
  static Future<Map<String, String>> getAppVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      _logger.e('❌ Error getting app version info: $e');
      return {};
    }
  }
}
