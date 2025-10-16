import 'package:flutter/material.dart';
import 'custom_confirm_popup.dart';
import 'custom_popup.dart';
import 'custom_toast.dart';

/// Centralized custom UI components for the entire app
class AppCustom {
  // ==================== CONFIRMATION POPUPS ====================
  
  /// Show a confirmation dialog with custom title, message, and actions
  static Future<bool?> showConfirm({
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
    return CustomConfirmPopup.show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      cancelColor: cancelColor,
      icon: icon,
      barrierDismissible: barrierDismissible,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show delete confirmation dialog
  static Future<bool?> showDeleteConfirm({
    required BuildContext context,
    required String itemName,
    String? customMessage,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomConfirmPopup.showDeleteConfirmation(
      context: context,
      itemName: itemName,
      customMessage: customMessage,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show reset confirmation dialog
  static Future<bool?> showResetConfirm({
    required BuildContext context,
    required String itemName,
    String? customMessage,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomConfirmPopup.showResetConfirmation(
      context: context,
      itemName: itemName,
      customMessage: customMessage,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show logout confirmation dialog
  static Future<bool?> showLogoutConfirm({
    required BuildContext context,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomConfirmPopup.showLogoutConfirmation(
      context: context,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show clear data confirmation dialog
  static Future<bool?> showClearDataConfirm({
    required BuildContext context,
    required String dataType,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomConfirmPopup.showClearDataConfirmation(
      context: context,
      dataType: dataType,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show save confirmation dialog
  static Future<bool?> showSaveConfirm({
    required BuildContext context,
    required String itemName,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomConfirmPopup.showSaveConfirmation(
      context: context,
      itemName: itemName,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  // ==================== GENERAL POPUPS ====================

  /// Show a general popup dialog
  static Future<T?> showPopup<T>({
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
    return CustomPopup.show<T>(
      context: context,
      child: child,
      title: title,
      icon: icon,
      actions: actions,
      barrierDismissible: barrierDismissible,
      backgroundColor: backgroundColor,
      width: width,
      height: height,
      padding: padding,
    );
  }

  /// Show info popup
  static Future<void> showInfoPopup({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData icon = Icons.info_outline,
    VoidCallback? onPressed,
  }) {
    return CustomPopup.showInfo(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: icon,
      onPressed: onPressed,
    );
  }

  /// Show loading popup
  static Future<void> showLoadingPopup({
    required BuildContext context,
    required String message,
    bool barrierDismissible = false,
  }) {
    return CustomPopup.showLoading(
      context: context,
      message: message,
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
    return CustomPopup.showBottomSheet<T>(
      context: context,
      child: child,
      title: title,
      icon: icon,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor,
      height: height,
      padding: padding,
    );
  }

  /// Show selection popup
  static Future<T?> showSelectionPopup<T>({
    required BuildContext context,
    required String title,
    required List<SelectionItem<T>> items,
    IconData? icon,
  }) {
    return CustomPopup.showSelection<T>(
      context: context,
      title: title,
      items: items,
      icon: icon,
    );
  }

  /// Show input popup
  static Future<String?> showInputPopup({
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
    return CustomPopup.showInput(
      context: context,
      title: title,
      hint: hint,
      initialValue: initialValue,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
    );
  }

  // ==================== TOAST MESSAGES ====================

  /// Show a toast message
  static void showToast({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    CustomToast.show(
      context: context,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show success toast
  static void showSuccessToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    CustomToast.showSuccess(
      context: context,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show error toast
  static void showErrorToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    CustomToast.showError(
      context: context,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show warning toast
  static void showWarningToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    CustomToast.showWarning(
      context: context,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show info toast
  static void showInfoToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    CustomToast.showInfo(
      context: context,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show loading toast
  static void showLoadingToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    CustomToast.showLoading(
      context: context,
      message: message,
      duration: duration,
    );
  }

  /// Clear all toasts
  static void clearToasts(BuildContext context) {
    CustomToast.clear(context);
  }

  // ==================== HELPER METHODS ====================

  /// Show song added to playlist toast
  static void showSongAddedToPlaylistToast(BuildContext context, String songTitle, String playlistName) {
    ToastHelper.songAddedToPlaylist(context, songTitle, playlistName);
  }

  /// Show song removed from playlist toast
  static void showSongRemovedFromPlaylistToast(BuildContext context, String songTitle, String playlistName) {
    ToastHelper.songRemovedFromPlaylist(context, songTitle, playlistName);
  }

  /// Show song deleted toast
  static void showSongDeletedToast(BuildContext context, String songTitle) {
    ToastHelper.songDeleted(context, songTitle);
  }

  /// Show playlist created toast
  static void showPlaylistCreatedToast(BuildContext context, String playlistName) {
    ToastHelper.playlistCreated(context, playlistName);
  }

  /// Show playlist deleted toast
  static void showPlaylistDeletedToast(BuildContext context, String playlistName) {
    ToastHelper.playlistDeleted(context, playlistName);
  }

  /// Show settings saved toast
  static void showSettingsSavedToast(BuildContext context) {
    ToastHelper.settingsSaved(context);
  }


  /// Show share success toast
  static void showShareSuccessToast(BuildContext context, String itemName) {
    ToastHelper.shareSuccess(context, itemName);
  }

  /// Show error toast helper
  static void showErrorToastHelper(BuildContext context, String message) {
    ToastHelper.error(context, message);
  }

  /// Show permission denied toast
  static void showPermissionDeniedToast(BuildContext context, String permission) {
    ToastHelper.permissionDenied(context, permission);
  }

  /// Show network error toast
  static void showNetworkErrorToast(BuildContext context) {
    ToastHelper.networkError(context);
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Show a quick success message
  static void success(BuildContext context, String message) {
    showSuccessToast(context: context, message: message);
  }

  /// Show a quick error message
  static void error(BuildContext context, String message) {
    showErrorToast(context: context, message: message);
  }

  /// Show a quick info message
  static void info(BuildContext context, String message) {
    showInfoToast(context: context, message: message);
  }

  /// Show a quick warning message
  static void warning(BuildContext context, String message) {
    showWarningToast(context: context, message: message);
  }

  /// Show a quick loading message
  static void loading(BuildContext context, String message) {
    showLoadingToast(context: context, message: message);
  }

  /// Show a quick confirmation dialog
  static Future<bool?> confirm(BuildContext context, String title, String message) {
    return showConfirm(
      context: context,
      title: title,
      message: message,
    );
  }

  /// Show a quick delete confirmation
  static Future<bool?> confirmDelete(BuildContext context, String itemName) {
    return showDeleteConfirm(
      context: context,
      itemName: itemName,
    );
  }
}
