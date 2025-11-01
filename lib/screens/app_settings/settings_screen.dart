import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_bloc.dart';
import '../../../core/router/app_router.dart';
import 'bloc/app_settings_bloc.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../../../core/widgets/app_custom.dart';

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
          CupertinoIcons.back,
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
            SizedBox(height: 24.h),
            _buildAppearanceSection(state),
            SizedBox(height: 24.h),
            _buildAiShuffleSection(state),
            SizedBox(height: 24.h),
            _buildMusicSection(state),
            SizedBox(height: 24.h),
            _buildAdvancedSection(state),
            SizedBox(height: 24.h),
            _buildAboutSection(),
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

  Widget _buildMusicSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Music & Playback'),
        _buildMusicSettings(state),
      ],
    );
  }

  Widget _buildAppearanceSection(AppSettingsState state) {
    return Column(
      children: [_buildSectionHeader('Appearance'), _buildThemeSettings(state)],
    );
  }

  Widget _buildAiShuffleSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('AI Shuffle'),
        _buildAiShuffleSettings(state),
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

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildSectionHeader('About'),
        _buildAboutSettings(),
      ],
    );
  }

  // ==================== SECTION HEADERS ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Align(
        alignment: Alignment.centerLeft,
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
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: CupertinoIcons.person,
            title: 'Profile',
            subtitle: nickName,
            onTap: () => _navigateToProfileEdit(),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNativeActionTile(
            icon: CupertinoIcons.music_note,
            title: 'Music Library',
            subtitle: 'Manage your music collection',
            onTap: _navigateToFetchSongsSettings,
          ),
          _buildDivider(),
          _buildNativeSwitchTile(
            icon: CupertinoIcons.forward,
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
            icon: CupertinoIcons.bell,
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
            icon: CupertinoIcons.speedometer,
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
          _buildDivider(),
          _buildNativeSwitchTile(
            icon: CupertinoIcons.moon,
            title: 'Sleep Timer',
            value: state.isSleepTimerEnabled,
            onChanged: (value) =>
                _updateSleepTimer(state.sleepTimerMinutes, value),
          ),
          if (state.isSleepTimerEnabled) ...[
            _buildDivider(),
            _buildNativeSliderTile(
              icon: CupertinoIcons.timer,
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

  Widget _buildThemeSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNativeSwitchTile(
            icon: CupertinoIcons.moon,
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
            icon: CupertinoIcons.gear,
            title: 'Follow System Theme',
            value: state.followSystemTheme ?? true,
            onChanged: (value) => _updateFollowSystem(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAiShuffleSettings(AppSettingsState state) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, musicState) {
        final isNormalShuffleEnabled = musicState.myPlayerState.isShuffle;
        
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNativeSwitchTile(
            icon: CupertinoIcons.sparkles,
            title: 'Enable AI Shuffle',
            subtitle: 'Intelligently reorders playlist based on current song features',
            value: state.isAiShuffleEnabled,
                onChanged: (value) => _updateAiShuffle(value, isNormalShuffleEnabled),
              ),
              _buildDivider(),
              _buildNativeSwitchTile(
                icon: CupertinoIcons.shuffle,
                title: 'Enable Normal Shuffle',
                subtitle: 'Randomly shuffle the playlist order',
                value: isNormalShuffleEnabled,
                onChanged: (value) => _updateNormalShuffle(value, state.isAiShuffleEnabled, musicState),
          ),
          _buildDivider(),
          _buildNativeListTile(
            icon: CupertinoIcons.chart_bar,
            title: 'Music Features Analysis',
            subtitle: 'Extract comprehensive features from your music',
            onTap: () {
              context.navigateToComprehensiveFeaturesSettings();
            },
          ),
        ],
      ),
        );
      },
    );
  }


  Widget _buildAdvancedSettings(AppSettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNativeSliderTile(
            icon: CupertinoIcons.refresh,
            title: 'Background Refresh',
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
            icon: CupertinoIcons.arrow_clockwise,
            title: 'Reset Settings',
            subtitle: 'Restore all settings to default',
            onTap: _showResetDialog,
          ),
          _buildDivider(),
          _buildNativeInfoTile(
            icon: CupertinoIcons.info,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNativeActionTile(
            icon: CupertinoIcons.info_circle,
            title: 'Developer Profile',
            subtitle: 'View my portfolio and projects',
            onTap: _openAboutUsWebsite,
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

  void _updateAiShuffle(bool isEnabled, bool isNormalShuffleEnabled) {
    // Update AI shuffle setting first
    // MusicBloc's listener will automatically handle disabling normal shuffle if needed
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateAiShuffle(isEnabled: isEnabled),
    );
    
    // If enabling AI shuffle and normal shuffle is currently enabled,
    // manually disable normal shuffle for immediate response
    // (MusicBloc listener will also handle this, but doing it here ensures UI updates immediately)
    if (isEnabled && isNormalShuffleEnabled) {
      final musicBloc = context.read<MusicBloc>();
      final currentPlayList = musicBloc.state.myPlayerState.currentPlayList;
      musicBloc.add(
        MusicEvent.toggleShuffle(
          isShuffle: false,
          currentPlayList: currentPlayList,
        ),
      );
    }
  }

  void _updateNormalShuffle(bool isEnabled, bool isAiShuffleEnabled, MusicState musicState) {
    final musicBloc = context.read<MusicBloc>();
    final currentPlayList = musicState.myPlayerState.currentPlayList;
    
    // If enabling normal shuffle, disable AI shuffle first
    // (MusicBloc's _onToggleShuffle will also handle this, but doing it here ensures consistency)
    if (isEnabled && isAiShuffleEnabled) {
      context.read<AppSettingsBloc>().add(
        AppSettingsEvent.updateAiShuffle(isEnabled: false),
      );
    }
    
    // Update normal shuffle via MusicBloc
    // Note: MusicBloc's _onToggleShuffle will also disable AI shuffle if it's enabled,
    // but we do it above for immediate UI response
    musicBloc.add(
      MusicEvent.toggleShuffle(
        isShuffle: isEnabled,
        currentPlayList: currentPlayList,
        isAutoStart: false,
      ),
    );
  }


  // ==================== HELPER METHODS ====================


  // ==================== UI COMPONENTS ====================

  Widget _buildNativeSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: context.primaryStart,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildNativeListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.primaryStart, size: 22.sp),
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
        CupertinoIcons.chevron_right,
        color: context.onSurfaceVariantColor,
        size: 16.sp,
      ),
      onTap: onTap,
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
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
            )
          : null,
      trailing: Icon(
        CupertinoIcons.chevron_right,
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
    AppCustom.showResetConfirm(
      context: context,
      itemName: 'Settings',
      customMessage: 'This will reset all settings to default values while preserving your profile information and theme preferences.',
      onConfirm: () async {
        try {
          // Reset to default settings (preserving user name, nickname, and theme)
          context.read<AppSettingsBloc>().add(
            AppSettingsEvent.resetToDefaults(),
          );
          
          // Show success message
          AppCustom.showSettingsSavedToast(context);
          
          // Close the dialog
          Navigator.of(context).pop();
        } catch (e) {
          // Handle any errors during reset
          AppCustom.error(context, 'Error resetting settings: $e');
          Navigator.of(context).pop();
        }
      },
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
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryStart.withValues(alpha: 0.15),
              context.primaryStart.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: context.primaryStart, size: 22.sp),
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
        CupertinoIcons.chevron_right,
        color: context.onSurfaceVariantColor,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }

  void _navigateToProfileEdit() {
    context.navigateToProfileEdit();
  }

  void _openAboutUsWebsite() {
    context.navigateToAboutUs();
  }
}
