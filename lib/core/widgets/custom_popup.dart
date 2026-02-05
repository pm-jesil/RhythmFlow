import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_extension.dart';

/// Custom popup for consistent UI across the app
class CustomPopup {
  /// Show a general popup dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    IconData? icon,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? backgroundColor,
    double? width,
    double? height,
    EdgeInsets? padding,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundColor ?? dialogContext.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: title != null
            ? Row(
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
              )
            : null,
        content: Container(
          width: width,
          height: height,
          padding: padding,
          child: child,
        ),
        actions: actions,
      ),
    );
  }

  /// Show info popup
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData icon = Icons.info_outline,
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      icon: icon,
      child: Text(
        message,
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onPressed?.call();
            Navigator.pop(context);
          },
          child: Text(
            buttonText,
            style: TextStyle(
              color: context.primaryStart,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show loading popup
  static Future<void> showLoading({
    required BuildContext context,
    required String message,
    bool barrierDismissible = false,
  }) {
    return show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.primaryStart),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show bottom sheet popup
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    IconData? icon,
    bool isScrollControlled = true,
    bool isDismissible = true,
    Color? backgroundColor,
    double? height,
    EdgeInsets? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: height,
        decoration: BoxDecoration(
          color: bottomSheetContext.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 8.h),
              decoration: BoxDecoration(
                color: bottomSheetContext.onSurfaceVariantColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Title
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: bottomSheetContext.primaryStart, size: 24.sp),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: bottomSheetContext.onSurfaceColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Content
            Flexible(
              child: Padding(
                padding: padding ?? EdgeInsets.all(16.w),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show selection popup
  static Future<T?> showSelection<T>({
    required BuildContext context,
    required String title,
    required List<SelectionItem<T>> items,
    IconData? icon,
  }) {
    return showBottomSheet(
      context: context,
      title: title,
      icon: icon,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item.icon != null
                ? Icon(item.icon, color: context.primaryStart)
                : null,
            title: Text(
              item.title,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: item.subtitle != null
                ? Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 14.sp,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context, item.value);
            },
          );
        },
      ),
    );
  }

  /// Show input popup
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    required String hint,
    String? initialValue,
    String confirmText = 'Save',
    String cancelText = 'Cancel',
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    return show(
      context: context,
      title: title,
      icon: icon,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelText,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14.sp,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final value = controller.text.trim();
            if (validator == null || validator(value) == null) {
              Navigator.pop(context, value);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text(
            confirmText,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Result of notification permission dialog.
  static const String notificationPermissionResultEnable = 'enable';
  static const String notificationPermissionResultCancel = 'cancel';
  static const String notificationPermissionResultMaybeLater = 'maybe_later';

  /// Shows a short dialog when notification permission is needed. Enable button
  /// triggers system permission (or opens Settings if not possible). Cancel and
  /// Maybe later do not request permission. Matches app theme.
  static Future<String?> showNotificationPermissionDialog(
    BuildContext context,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: dialogContext.primaryStart,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Notification permission',
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
          'Show now playing in the notification bar and control playback from there.',
          style: TextStyle(
            color: dialogContext.onSurfaceVariantColor,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(notificationPermissionResultMaybeLater),
            child: Text(
              'Maybe later',
              style: TextStyle(
                color: dialogContext.onSurfaceVariantColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(notificationPermissionResultCancel),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dialogContext.onSurfaceVariantColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(notificationPermissionResultEnable),
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.primaryStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Enable',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selection item for popup
class SelectionItem<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;

  const SelectionItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
  });
}
