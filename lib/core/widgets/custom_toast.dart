import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_extension.dart';

/// Custom toast for consistent UI across the app
class CustomToast {
  /// Show a toast message
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final color = _getToastColor(context, type);
    final icon = _getToastIcon(type);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // ScreenUtil is calibrated for portrait (375×812). In landscape the width
    // scale is ~2×, so .sp/.w/.r would double all sizes. Use raw logical-pixel
    // values for landscape to avoid over-scaling.
    final double finalIconSize = isLandscape ? 14.0 : 20.0.sp;
    final double finalFontSize = isLandscape ? 11.0 : 14.0.sp;
    final double iconGap      = isLandscape ? 6.0  : 8.0.w;
    final EdgeInsets margin   = isLandscape
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
        : EdgeInsets.all(16.w);
    final double radius       = isLandscape ? 6.0  : 8.0.r;
    final EdgeInsets? padding = isLandscape
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: finalIconSize),
              SizedBox(width: iconGap),
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: finalFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: margin,
        padding: padding,
        action: onTap != null
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: onTap,
              )
            : null,
      ),
    );
  }

  /// Show success toast
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show error toast
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show warning toast
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.warning,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show info toast
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show loading toast
  static void showLoading({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.loading,
      duration: duration,
    );
  }

  /// Clear all toasts
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Get toast color based on type
  static Color _getToastColor(BuildContext context, ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return context.error;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return context.primaryStart;
      case ToastType.loading:
        return context.primaryStart;
    }
  }

  /// Get toast icon based on type
  static IconData? _getToastIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
      case ToastType.loading:
        return Icons.hourglass_empty;
    }
  }
}

/// Toast types
enum ToastType {
  success,
  error,
  warning,
  info,
  loading,
}

/// Toast helper for common operations
class ToastHelper {
  /// Show song added to playlist toast
  static void songAddedToPlaylist(BuildContext context, String songTitle, String playlistName) {
    CustomToast.showSuccess(
      context: context,
      message: '"$songTitle" added to "$playlistName"',
    );
  }

  /// Show song removed from playlist toast
  static void songRemovedFromPlaylist(BuildContext context, String songTitle, String playlistName) {
    CustomToast.showInfo(
      context: context,
      message: '"$songTitle" removed from "$playlistName"',
    );
  }

  /// Show song deleted toast
  static void songDeleted(BuildContext context, String songTitle) {
    CustomToast.showSuccess(
      context: context,
      message: '"$songTitle" deleted successfully',
    );
  }

  /// Show playlist created toast
  static void playlistCreated(BuildContext context, String playlistName) {
    CustomToast.showSuccess(
      context: context,
      message: 'Playlist "$playlistName" created',
    );
  }

  /// Show playlist deleted toast
  static void playlistDeleted(BuildContext context, String playlistName) {
    CustomToast.showInfo(
      context: context,
      message: 'Playlist "$playlistName" deleted',
    );
  }

  /// Show settings saved toast
  static void settingsSaved(BuildContext context) {
    CustomToast.showSuccess(
      context: context,
      message: 'Settings saved successfully',
    );
  }


  /// Show share toast
  static void shareSuccess(BuildContext context, String itemName) {
    CustomToast.showSuccess(
      context: context,
      message: '$itemName shared successfully',
    );
  }

  /// Show error toast
  static void error(BuildContext context, String message) {
    CustomToast.showError(
      context: context,
      message: message,
    );
  }

  /// Show permission denied toast
  static void permissionDenied(BuildContext context, String permission) {
    CustomToast.showError(
      context: context,
      message: '$permission permission denied',
    );
  }

  /// Show network error toast
  static void networkError(BuildContext context) {
    CustomToast.showError(
      context: context,
      message: 'Network error. Please check your connection.',
    );
  }
}
