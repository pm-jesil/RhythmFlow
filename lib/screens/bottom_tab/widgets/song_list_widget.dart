import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../screens/bloc/music_bloc.dart';

class SongListWidget {
  static void showSortingMenu(BuildContext context) {
    final currentSortingIndex = context.read<MusicBloc>().state.sortingIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.onSurfaceVariantColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort Songs',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...MusicBloc.sortingOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              return _buildSortOption(
                context,
                title,
                index,
                currentSortingIndex,
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSortOption(
    BuildContext context,
    String title,
    int index,
    int currentSortingIndex,
  ) {
    final isSelected = currentSortingIndex == index;

    IconData getIcon(int index) {
      switch (index) {
        case 0:
          return Icons.new_releases;
        case 1:
          return Icons.history;
        case 2:
          return Icons.sort_by_alpha;
        case 3:
          return Icons.timer;
        case 4:
          return Icons.timer_off;
        default:
          return Icons.sort;
      }
    }

    return ListTile(
      leading: Icon(
        getIcon(index),
        color: isSelected ? context.primaryStart : context.onSurfaceVariantColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? context.primaryStart : context.onSurfaceColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: context.primaryStart)
          : null,
      onTap: () {
        Navigator.pop(context);
        context.read<MusicBloc>().add(
          MusicEvent.changeSortingOrder(
            sortingIndex: index,
            sortingList: context.read<MusicBloc>().state.allSongs.map((s) => s.id).toList(),
            playlistSource: PlaylistSource.allSongs(),
          ),
        );
      },
    );
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
