import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/app_custom.dart';
import '../../widgets/sorting_helper.dart';
import '../../../utils/services/permission_service.dart';

class SongListWidget {
  static void showSortingMenu(BuildContext context) {
    SortingHelper.showSortingMenu(context);
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return AppCustom.showPopup(
      context: context,
      title: 'Storage Permission Required',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To access your music files, RhythmFlow needs storage permission.',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'This allows the app to:',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
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
              fontSize: 16.sp,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await PermissionService.showPermissionRequiredDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'Grant Permission',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      ],
    );
  }

  static Widget _buildPermissionItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.primaryStart,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
