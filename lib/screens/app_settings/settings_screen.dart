import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_bloc.dart';
import '../../../core/router/app_router.dart';
import 'bloc/app_settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Theme sync is handled by AppSettingsBloc initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Settings',
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.onSurfaceColor,
          size: 18.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        return ListView(
          children: [
            _buildProfileSection(state),
            SizedBox(height: 32.h),
            _buildAppearanceSection(state),
            SizedBox(height: 32.h),
            _buildPlaybackSection(state),
            SizedBox(height: 32.h),
            _buildSleepTimerSection(state),
            SizedBox(height: 32.h),
            _buildAdvancedSection(state),
            SizedBox(height: 80.h),
          ],
        );
      },
    );
  }

  // ==================== SECTION BUILDERS ====================

  Widget _buildProfileSection(AppSettingsState state) {
    return Column(
      children: [_buildSectionHeader('Profile'), _buildProfileSettings(state)],
    );
  }

  Widget _buildAppearanceSection(AppSettingsState state) {
    return Column(
      children: [_buildSectionHeader('Appearance'), _buildThemeSettings(state)],
    );
  }

  Widget _buildPlaybackSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Playback'),
        _buildPlaybackSettings(state),
      ],
    );
  }

  Widget _buildSleepTimerSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Sleep Timer'),
        _buildSleepTimerSettings(state),
      ],
    );
  }

  Widget _buildAdvancedSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Advanced'),
        _buildAdvancedSettings(state),
      ],
    );
  }

  // ==================== SECTION HEADERS ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==================== SETTINGS SECTIONS ====================

  Widget _buildProfileSettings(AppSettingsState state) {
    final nickName = state.nickName ?? 'Not set';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: Icons.face_rounded,
            title: 'Profile',
            subtitle: nickName,
            onTap: () => _navigateToProfileEdit(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeSwitchTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            value: state.isDarkMode ?? false,
            onChanged: (state.followSystemTheme == true)
                ? null
                : (value) => _updateTheme(value, state.followSystemTheme),
            enabled: state.followSystemTheme != true,
          ),
          if (state.followSystemTheme == true)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Dark mode is controlled by system settings',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          _buildDivider(),
          _buildNativeSwitchTile(
            icon: Icons.settings_suggest_rounded,
            title: 'Follow System',
            value: state.followSystemTheme ?? true,
            onChanged: (value) => _updateFollowSystem(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeSwitchTile(
            icon: Icons.skip_next_rounded,
            title: 'Auto Play Next',
            value: state.autoPlayNext,
            onChanged: (value) => _updatePlaybackSettings(
              value,
              state.showNotifications,
              state.playbackSpeed,
            ),
          ),
          _buildDivider(),
          _buildNativeSwitchTile(
            icon: Icons.notifications_rounded,
            title: 'Show Notifications',
            value: state.showNotifications,
            onChanged: (value) => _updatePlaybackSettings(
              state.autoPlayNext,
              value,
              state.playbackSpeed,
            ),
          ),
          _buildDivider(),
          _buildNativeSliderTile(
            icon: Icons.speed_rounded,
            title: 'Playback Speed',
            subtitle: '${state.playbackSpeed.toStringAsFixed(1)}x',
            value: state.playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) => _updatePlaybackSettings(
              state.autoPlayNext,
              state.showNotifications,
              value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimerSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeSwitchTile(
            icon: Icons.bedtime_rounded,
            title: 'Sleep Timer',
            value: state.isSleepTimerEnabled,
            onChanged: (value) =>
                _updateSleepTimer(state.sleepTimerMinutes, value),
          ),
          if (state.isSleepTimerEnabled) ...[
            _buildDivider(),
            _buildNativeSliderTile(
              icon: Icons.timer_rounded,
              title: 'Timer Duration',
              subtitle: _formatDuration(state.sleepTimerMinutes),
              value: state.sleepTimerMinutes.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              onChanged: (value) =>
                  _updateSleepTimer(value.round(), state.isSleepTimerEnabled),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeActionTile(
            icon: Icons.music_note_rounded,
            title: 'Fetch Songs Settings',
            onTap: _navigateToFetchSongsSettings,
          ),
          _buildDivider(),
          _buildNativeSliderTile(
            icon: Icons.refresh_rounded,
            title: 'Background Refresh Interval',
            subtitle: '${state.appBackgroundRefreshTimeGap} hours',
            value: state.appBackgroundRefreshTimeGap.toDouble(),
            min: 1,
            max: 24,
            divisions: 23,
            onChanged: (value) =>
                _updateBackgroundRefreshTimeGap(value.round()),
          ),
          _buildDivider(),
          _buildNativeActionTile(
            icon: Icons.restore_rounded,
            title: 'Reset to Defaults',
            onTap: _showResetDialog,
          ),
          _buildDivider(),
          _buildNativeInfoTile(
            icon: Icons.info_rounded,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _updateTheme(bool isDarkMode, bool? followSystemTheme) {
    // When user manually toggles dark mode, disable follow system
    final actualFollowSystem = false;

    // Update AppSettingsBloc
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateTheme(
        isDarkMode: isDarkMode,
        followSystemTheme: actualFollowSystem,
      ),
    );

    // Sync with main app's theme system
    AppTheme.updateTheme(
      isDarkMode: isDarkMode,
      isFollowingSystem: actualFollowSystem,
    );

    // Also sync with ThemeBloc if available
    _syncWithThemeBloc(isDarkMode, actualFollowSystem);
  }

  void _syncWithThemeBloc(bool isDarkMode, bool followSystemTheme) {
    try {
      final themeBloc = context.read<ThemeBloc>();
      if (followSystemTheme) {
        themeBloc.followSystem();
      } else {
        themeBloc.add(ThemeEvent.setTheme(isDarkMode: isDarkMode));
      }
    } catch (e) {
      // ThemeBloc not available, that's okay
    }
  }

  void _updateFollowSystem(bool followSystemTheme) {
    bool? actualDarkMode;

    if (followSystemTheme) {
      // When enabling follow system, set isDarkMode to false (follow system)
      actualDarkMode = false;
    } else {
      // When disabling follow system, get current app theme state
      try {
        final themeBloc = context.read<ThemeBloc>();
        actualDarkMode = themeBloc.isDarkMode;
      } catch (e) {
        // Fallback to AppTheme if ThemeBloc not available
        actualDarkMode = AppTheme.isDarkMode;
      }
    }

    // Update AppSettingsBloc
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateTheme(
        isDarkMode: actualDarkMode,
        followSystemTheme: followSystemTheme,
      ),
    );

    // Sync with main app's theme system
    AppTheme.updateTheme(
      isDarkMode: actualDarkMode,
      isFollowingSystem: followSystemTheme,
    );

    // Also sync with ThemeBloc if available
    _syncWithThemeBloc(actualDarkMode, followSystemTheme);
  }

  void _updatePlaybackSettings(
    bool autoPlayNext,
    bool showNotifications,
    double playbackSpeed,
  ) {
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updatePlaybackSettings(
        autoPlayNext: autoPlayNext,
        showNotifications: showNotifications,
        playbackSpeed: playbackSpeed,
      ),
    );
  }

  void _updateBackgroundRefreshTimeGap(int hours) {
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateBackgroundRefreshTimeGap(hours: hours),
    );
  }

  void _navigateToFetchSongsSettings() {
    context.navigateToMusicLibrarySettings();
  }

  void _updateSleepTimer(int minutes, bool isEnabled) {
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateSleepTimer(minutes: minutes, isEnabled: isEnabled),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildNativeSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? context.primaryStart : context.onSurfaceVariantColor,
        size: 22.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? context.onSurfaceColor
              : context.onSurfaceVariantColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: context.primaryStart,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildNativeSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.primaryStart, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: context.primaryStart,
            inactiveColor: context.onSurfaceVariantColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.primaryStart, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: context.onSurfaceVariantColor,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildNativeInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.onSurfaceVariantColor, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: context.onSurfaceVariantColor.withValues(alpha: 0.1),
      height: 1.h,
      thickness: 0.5,
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  // ==================== DIALOGS ====================

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'Reset Settings',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppSettingsBloc>().add(
                AppSettingsEvent.resetToDefaults(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: context.primaryStart,
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PROFILE HELPER METHODS ====================

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: context.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: context.primaryStart, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: context.onSurfaceVariantColor,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }

  void _navigateToProfileEdit() {
    context.navigateToProfileEdit();
  }
}
