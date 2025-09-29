import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/logger/logger.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? settingsMessage;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onCancelPressed;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    this.settingsMessage,
    this.onSettingsPressed,
    this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (settingsMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              settingsMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onCancelPressed != null)
          TextButton(
            onPressed: onCancelPressed,
            child: const Text('Cancel'),
          ),
        if (onSettingsPressed != null)
          ElevatedButton(
            onPressed: onSettingsPressed,
            child: const Text('Open Settings'),
          ),
      ],
    );
  }

  /// Show permission dialog for permanently denied permissions
  static Future<void> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? settingsMessage,
  }) async {
    final logger = AppLogger('PermissionDialog');
    logger.d('Showing permission dialog: $title');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialog(
          title: title,
          message: message,
          settingsMessage: settingsMessage,
          onCancelPressed: () {
            logger.d('User cancelled permission dialog');
            Navigator.of(context).pop();
          },
          onSettingsPressed: () async {
            logger.d('User requested to open settings');
            Navigator.of(context).pop();
            await openAppSettings();
          },
        );
      },
    );
  }

  /// Show permission dialog for storage permission
  static Future<void> showStoragePermissionDialog(BuildContext context) async {
    return showPermissionDialog(
      context: context,
      title: 'Storage Permission Required',
      message: 'This app needs access to your device storage to find and play music files.',
      settingsMessage: 'Please grant the permission in your device settings to continue.',
    );
  }

  /// Show permission dialog for media permissions
  static Future<void> showMediaPermissionDialog(BuildContext context) async {
    return showPermissionDialog(
      context: context,
      title: 'Media Permissions Required',
      message: 'This app needs access to your media files to find and play music.',
      settingsMessage: 'Please grant the permissions in your device settings to continue.',
    );
  }

  /// Show permission dialog for audio permissions
  static Future<void> showAudioPermissionDialog(BuildContext context) async {
    return showPermissionDialog(
      context: context,
      title: 'Audio Permission Required',
      message: 'This app needs access to audio files to play music.',
      settingsMessage: 'Please grant the permission in your device settings to continue.',
    );
  }
}
