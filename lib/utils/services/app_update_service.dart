import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../logger/logger.dart';

class AppUpdateService {
  static final AppLogger _logger = AppLogger('AppUpdateService');

  /// Check for app updates and handle the update flow
  static Future<bool> checkForUpdates(BuildContext context) async {
    try {
      _logger.i('🔍 Checking for app updates...');

      // Skip update check on iOS (not supported)
      if (Platform.isIOS) {
        _logger.i('📱 iOS detected - skipping update check');
        return true; // Allow app to continue
      }

      // Check if update is available
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        _logger.i('🔄 Update available! Update priority: ${updateInfo.updatePriority}');
        
        // Show update dialog
        return await _showUpdateDialog(context, updateInfo);
      } else {
        _logger.i('✅ App is up to date');
        return true; // Allow app to continue
      }
    } catch (e) {
      _logger.e('❌ Error checking for updates: $e');
      // On error, allow app to continue
      return true;
    }
  }

  /// Show update dialog to user
  static Future<bool> _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must choose to update
      builder: (context) => _UpdateDialog(updateInfo: updateInfo),
    ) ?? false;
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

/// Update dialog widget
class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const _UpdateDialog({required this.updateInfo});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Update Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of PMJ Music Player is available!',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please update to continue using the app.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            if (widget.updateInfo.updatePriority == 5) // High priority
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'High Priority Update',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!_isUpdating) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't update
              },
              child: Text(
                'Later',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isUpdating ? null : _startUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUpdating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Update Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // For high priority updates, use immediate update
      if (widget.updateInfo.updatePriority == 5) { // High priority
        await AppUpdateService.performImmediateUpdate();
      } else {
        // For normal updates, use flexible update
        await AppUpdateService.startFlexibleUpdate();
        // Show completion dialog
        _showUpdateCompleteDialog();
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showUpdateCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Downloaded',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'The update has been downloaded. Restart the app to apply the update.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await AppUpdateService.completeFlexibleUpdate();
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: Text(
              'Restart App',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Failed',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'Failed to update the app. Please try again later.\n\nError: $error',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Continue Anyway',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}
