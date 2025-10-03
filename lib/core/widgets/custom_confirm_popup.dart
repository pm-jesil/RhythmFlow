import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_extension.dart';

/// Custom confirmation popup for consistent UI across the app
class CustomConfirmPopup {
  /// Show a confirmation dialog with custom title, message, and actions
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? cancelColor,
    IconData? icon,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: dialogContext.primaryStart, size: 24.sp),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: dialogContext.onSurfaceColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: dialogContext.onSurfaceVariantColor,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.pop(dialogContext, false);
            },
            child: Text(
              cancelText,
              style: TextStyle(
                color: cancelColor ?? dialogContext.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? dialogContext.primaryStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              confirmText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? customMessage,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Delete $itemName',
      message: customMessage ?? 
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      confirmColor: context.error,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show reset confirmation dialog
  static Future<bool?> showResetConfirmation({
    required BuildContext context,
    required String itemName,
    String? customMessage,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Reset $itemName',
      message: customMessage ?? 
          'Are you sure you want to reset $itemName to default values? This action cannot be undone.',
      confirmText: 'Reset',
      cancelText: 'Cancel',
      icon: Icons.restore,
      confirmColor: context.error,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show logout confirmation dialog
  static Future<bool?> showLogoutConfirmation({
    required BuildContext context,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      icon: Icons.logout,
      confirmColor: context.error,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show clear data confirmation dialog
  static Future<bool?> showClearDataConfirmation({
    required BuildContext context,
    required String dataType,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Clear $dataType',
      message: 'Are you sure you want to clear all $dataType? This action cannot be undone.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      icon: Icons.clear_all,
      confirmColor: context.error,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show save confirmation dialog
  static Future<bool?> showSaveConfirmation({
    required BuildContext context,
    required String itemName,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Save Changes',
      message: 'Do you want to save changes to $itemName?',
      confirmText: 'Save',
      cancelText: 'Cancel',
      icon: Icons.save,
      confirmColor: context.primaryStart,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
