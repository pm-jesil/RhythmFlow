import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/theme_extension.dart';
import '../../widgets/sorting_helper.dart';

class SongListWidget {
  static void showSortingMenu(BuildContext context) {
    SortingHelper.showSortingMenu(context);
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.folder_open, color: context.primaryStart, size: 28),
              const SizedBox(width: 12),
              Text(
                'Storage Permission Required',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To access your music files, PMJ Music needs storage permission.',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This allows the app to:',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildPermissionItem(context, 'Scan music files from your device'),
              _buildPermissionItem(context, 'Access selected music folders'),
              _buildPermissionItem(context, 'Play your local music collection'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryStart,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildPermissionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: context.primaryStart, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
