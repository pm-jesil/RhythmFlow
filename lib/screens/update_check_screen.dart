import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/theme_extension.dart';
import '../utils/services/app_update_service.dart';
import '../utils/logger/logger.dart';

/// Simple update check screen that shows while checking for updates
class UpdateCheckScreen extends StatefulWidget {
  final Widget child; // The actual content to show after update check

  const UpdateCheckScreen({
    super.key,
    required this.child,
  });

  @override
  State<UpdateCheckScreen> createState() => _UpdateCheckScreenState();
}

class _UpdateCheckScreenState extends State<UpdateCheckScreen> {
  final AppLogger _logger = AppLogger('UpdateCheckScreen');
  bool _isChecking = true;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      _logger.i('🔍 Starting update check...');
      
      // Small delay to show loading screen
      await Future.delayed(const Duration(milliseconds: 500));
      
      final canContinue = await AppUpdateService.checkForUpdates(context);
      
      if (mounted) {
        setState(() {
          _isChecking = false;
          _updateRequired = !canContinue;
        });
        
        if (!canContinue) {
          _logger.i('🔄 Update required - user must update');
        } else {
          _logger.i('✅ No update required - continuing to app');
        }
      }
    } catch (e) {
      _logger.e('❌ Error during update check: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
          _updateRequired = false; // Continue on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildLoadingScreen();
    }
    
    if (_updateRequired) {
      return _buildUpdateRequiredScreen();
    }
    
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryStart.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: _buildAppIcon(),
                ),
              ),
              SizedBox(height: 30.h),

              // Loading Animation
              SizedBox(
                width: 50.w,
                height: 50.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
                ),
              ),
              SizedBox(height: 20.h),

              // Loading Text
              Text(
                'Checking for updates...',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please wait a moment',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateRequiredScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Update Icon
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.system_update,
                    color: Colors.orange,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 30.h),

                // Title
                Text(
                  'Update Required',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 16.h),

                // Description
                Text(
                  'A new version of PMJ Music Player is available and must be installed to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.onSurfaceVariantColor,
                    fontSize: 16.sp,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkForUpdates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryStart,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Check Again',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    // Try different Android icon paths in order of preference
    final iconPaths = [
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/drawable/ic_launcher.png',
    ];

    return _tryImagePaths(iconPaths, 0);
  }

  Widget _tryImagePaths(List<String> paths, int index) {
    if (index >= paths.length) {
      // All paths failed, return fallback
      return Container(
        decoration: BoxDecoration(
          gradient: context.primaryGradient,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 50.sp),
      );
    }

    return Image.asset(
      paths[index],
      width: 100.w,
      height: 100.w,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Try next path
        return _tryImagePaths(paths, index + 1);
      },
    );
  }
}
