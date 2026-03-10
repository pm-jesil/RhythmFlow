import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/theme/theme_extension.dart';

/// Equalizer screen app bar with back button, title, and optional add-preset action.
class EqualizerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EqualizerAppBar({
    super.key,
    this.eq,
    required this.onBack,
    this.onAddPreset,
  });

  final AndroidEqualizer? eq;
  final VoidCallback onBack;
  final VoidCallback? onAddPreset;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final toolbarHeight = (screenHeight * 0.064).clamp(28.r, 40.h);
    return AppBar(
      toolbarHeight: toolbarHeight,
      title: Text(
        'Equalizer',
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          CupertinoIcons.back,
          color: context.onSurfaceColor,
          size: 10.sp,
        ),
        iconSize: 16.r,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        ),
        onPressed: onBack,
      ),
      actions: [
        if (eq != null && onAddPreset != null) _buildAddButton(context),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.add,
        color: context.primaryStart,
        size: 10.sp,
      ),
      iconSize: 16.r,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
      ),
      onPressed: onAddPreset,
      tooltip: 'Add preset',
    );
  }
}
