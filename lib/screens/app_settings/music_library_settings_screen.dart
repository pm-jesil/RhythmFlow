import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/services/permission_service.dart';
import 'bloc/app_settings_bloc.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../../../core/widgets/app_custom.dart';

class MusicLibrarySettingsScreen extends StatefulWidget {
  const MusicLibrarySettingsScreen({super.key});

  @override
  State<MusicLibrarySettingsScreen> createState() => _MusicLibrarySettingsScreenState();
}

class _MusicLibrarySettingsScreenState extends State<MusicLibrarySettingsScreen> {
  static final AppLogger _logger = AppLogger('FetchSongsSettingsScreen');

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
        'Music Library Settings',
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
      actions: [
        BlocBuilder<MusicBloc, MusicState>(
          builder: (context, musicState) {
            if (musicState.appSettingsFetchSong) {
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Center(
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, appSettingsState) {
        return BlocBuilder<MusicBloc, MusicState>(
          builder: (context, musicState) {
            return ListView(
              children: [
                _buildMusicFoldersSection(appSettingsState),
                SizedBox(height: 24.h),
                _buildLibraryManagementSection(appSettingsState, musicState),
                SizedBox(height: 80.h),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== SECTION BUILDERS ====================
  
  Widget _buildMusicFoldersSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Blocked Folders'),
        _buildBlockedFoldersSettings(state),
        SizedBox(height: 16.h),
        _buildSectionHeader('Music Folders'),
        _buildMusicFoldersSettings(state),
      ],
    );
  }

  Widget _buildLibraryManagementSection(AppSettingsState state, MusicState musicState) {
    return Column(
      children: [
        _buildSectionHeader('Library Management'),
        _buildLibraryManagementSettings(state, musicState),
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
  
  Widget _buildBlockedFoldersSettings(AppSettingsState state) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final folders = state.blockedFolderList[platform] ?? [];
    const maxBlockedFolders = 10;
    final canAddMore = folders.length < maxBlockedFolders;

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
            icon: Icons.block_rounded,
            title: 'Add Blocked Folder',
            subtitle: canAddMore
                ? 'Folders here are skipped during scans (${folders.length}/$maxBlockedFolders)'
                : 'Maximum $maxBlockedFolders folders allowed (${folders.length}/$maxBlockedFolders)',
            onTap: canAddMore ? _addBlockedFolder : null,
          ),
          if (folders.isNotEmpty) ...[
            _buildDivider(),
            ...folders.map(
              (folder) => _buildFolderTile(
                folder: folder,
                onRemove: () => _removeBlockedFolder(folder),
              ),
            ),
          ],
          if (folders.isEmpty) ...[
            _buildDivider(),
            _buildBlockedEmptyStateTile(),
          ],
          if (!canAddMore) ...[
            _buildDivider(),
            _buildBlockedLimitTile(
              maxBlockedFolders,
              folders.length,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMusicFoldersSettings(AppSettingsState state) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final folders = state.whiteListFolder[platform] ?? [];
    final canAddMore = folders.length < 6;
    
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
            icon: Icons.folder_open_rounded,
            title: 'Add Folder',
            subtitle: canAddMore 
                ? 'Select folder from device storage (${folders.length}/6)'
                : 'Maximum 6 folders allowed (${folders.length}/6)',
            onTap: canAddMore ? _addFolder : null,
          ),
          if (folders.isNotEmpty) ...[
            _buildDivider(),
            ...folders.map(
              (folder) => _buildFolderTile(
                folder: folder,
                onRemove: () => _removeFolder(folder),
              ),
            ),
          ],
          if (folders.isEmpty) ...[
            _buildDivider(),
            _buildEmptyStateTile(),
          ],
          if (!canAddMore) ...[
            _buildDivider(),
            _buildMaxFoldersReachedTile(),
          ],
        ],
      ),
    );
  }

  Widget _buildLibraryManagementSettings(AppSettingsState state, MusicState musicState) {
    final isFetching = musicState.appSettingsFetchSong;
    
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
            icon: Icons.refresh_rounded,
            title: 'Refresh Library',
            subtitle: 'Scan all music folders for songs',
            onTap: isFetching ? null : _refreshAllSongs,
            isLoading: isFetching,
          ),
          _buildDivider(),
          _buildNativeInfoTile(
            icon: Icons.info_rounded,
            title: 'Last Refresh',
            subtitle: state.lastUpdateMusicLibrary != null 
                ? _formatLastUpdate(state.lastUpdateMusicLibrary!)
                : 'Never',
          ),
        ],
      ),
    );
  }


  // ==================== TILE BUILDERS ====================
  
  Widget _buildFolderTile({
    required String folder,
    required VoidCallback onRemove,
  }) {
    return ListTile(
      leading: Icon(
        Icons.folder_rounded,
        color: context.primaryStart,
        size: 22.sp,
      ),
      title: Text(
        _getFolderDisplayName(folder),
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        folder,
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 12.sp,
          fontFamily: 'Poppins',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 20.sp,
        ),
        onPressed: onRemove,
      ),
    );
  }

  Widget _buildEmptyStateTile() {
    return ListTile(
      leading: Icon(
        Icons.folder_off_rounded,
        color: context.onSurfaceVariantColor,
        size: 22.sp,
      ),
      title: Text(
        'No folders added',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        'Tap "Add Folder" to add music folders',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildBlockedEmptyStateTile() {
    return ListTile(
      leading: Icon(
        Icons.block_outlined,
        color: context.onSurfaceVariantColor,
        size: 22.sp,
      ),
      title: Text(
        'No blocked folders',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        'Add folders here to skip them during scans',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildBlockedLimitTile(int maxBlocked, int currentCount) {
    return ListTile(
      leading: Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
        size: 22.sp,
      ),
      title: Text(
        'Blocked folder limit reached',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        'Remove a folder to block a new one ($currentCount/$maxBlocked)',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildMaxFoldersReachedTile() {
    return ListTile(
      leading: Icon(
        Icons.warning_rounded,
        color: Colors.orange,
        size: 22.sp,
      ),
      title: Text(
        'Maximum folders reached',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        'Remove a folder to add a new one (6/6)',
        style: TextStyle(
          color: context.onSurfaceVariantColor,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildNativeActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: isLoading 
          ? SizedBox(
              width: 22.sp,
              height: 22.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
              ),
            )
          : Icon(
              icon,
              color: onTap != null ? context.primaryStart : context.onSurfaceVariantColor,
              size: 22.sp,
            ),
      title: Text(
        title,
        style: TextStyle(
          color: onTap != null ? context.onSurfaceColor : context.onSurfaceVariantColor,
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
      trailing: onTap != null && !isLoading
          ? Icon(
              Icons.arrow_forward_ios_rounded,
              color: context.onSurfaceVariantColor,
              size: 16.sp,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildNativeInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: context.primaryStart,
        size: 22.sp,
      ),
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

  // ==================== EVENT HANDLERS ====================
  
  Future<void> _addFolder() async {
    try {
      // Check if we can add more folders
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final currentFolders = context.read<AppSettingsBloc>().state.whiteListFolder[platform] ?? [];
      
      if (currentFolders.length >= 6) {
        AppCustom.warning(context, 'Maximum 6 folders allowed. Remove a folder to add a new one.');
        return;
      }
      
      _logger.i('📁 Opening folder picker...');
      
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );
      
      if (selectedDirectory != null) {
        _logger.i('📁 Selected folder: $selectedDirectory');
        
        context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateWhiteListFolder(
            platform: platform,
            folder: selectedDirectory,
            isRemove: false,
          ),
        );
        
        AppCustom.success(context, 'Folder added successfully');
      } else {
        _logger.i('📁 No folder selected');
      }
    } catch (e) {
      _logger.e('❌ Error selecting folder: $e');
      AppCustom.error(context, 'Error selecting folder');
    }
  }

  void _removeFolder(String folder) {
    _logger.i('🗑️ Removing folder: $folder');
    
    final platform = Platform.isAndroid ? 'android' : 'ios';
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateWhiteListFolder(
        platform: platform,
        folder: folder,
        isRemove: true,
      ),
    );
    
    AppCustom.success(context, 'Folder removed successfully');
  }

  Future<void> _addBlockedFolder() async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final blockedFolders =
          context.read<AppSettingsBloc>().state.blockedFolderList[platform] ?? [];
      const maxBlockedFolders = 10;

      if (blockedFolders.length >= maxBlockedFolders) {
        AppCustom.warning(
          context,
          'Maximum $maxBlockedFolders blocked folders allowed. Remove one to add another.',
        );
        return;
      }

      _logger.i('🚫 Opening folder picker for blocked folders...');

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder to Block',
      );

      if (selectedDirectory != null) {
        _logger.i('🚫 Selected blocked folder: $selectedDirectory');

        context.read<AppSettingsBloc>().add(
              AppSettingsEvent.updateBlockedFolderList(
                platform: platform,
                folder: selectedDirectory,
                isRemove: false,
              ),
            );

        AppCustom.success(context, 'Folder blocked successfully');
      } else {
        _logger.i('🚫 No blocked folder selected');
      }
    } catch (e) {
      _logger.e('❌ Error blocking folder: $e');
      AppCustom.error(context, 'Error blocking folder');
    }
  }

  void _removeBlockedFolder(String folder) {
    _logger.i('🚫 Removing blocked folder: $folder');

    final platform = Platform.isAndroid ? 'android' : 'ios';
    context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateBlockedFolderList(
            platform: platform,
            folder: folder,
            isRemove: true,
          ),
        );

    AppCustom.success(context, 'Folder unblocked successfully');
  }

  Future<void> _refreshAllSongs() async {
    _logger.i('🔄 Starting full song refresh (force refresh)...');
    
    try {
      // Check permissions first
      final hasPermissions = await PermissionService.hasAllRequiredPermissions();
      
      if (hasPermissions) {
        _logger.i('✅ Permissions granted, proceeding with refresh');
        AppCustom.info(context, 'Refreshing songs...');
        
        // Trigger music bloc to refresh all songs with force flag
        context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs(isForce: true));
        
        // Update last refresh time
        context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateLastMusicLibraryUpdate(
            timestamp: DateTime.now(),
          ),
        );
        
        _logger.i('✅ Force song refresh initiated successfully');
        AppCustom.success(context, 'Force song refresh initiated');
      } else {
        _logger.w('❌ Permissions not granted, requesting permissions');
        
        // Request permissions with user-friendly dialog
        final granted = await PermissionService.requestAllRequiredPermissions(context);
        
        if (granted) {
          _logger.i('✅ Permissions granted after request, proceeding with refresh');
          AppCustom.info(context, 'Refreshing songs...');
          
          // Trigger music bloc to refresh all songs with force flag
          context.read<MusicBloc>().add(const MusicEvent.fetchAndUpdateSongs(isForce: true));
          
          // Update last refresh time
          context.read<AppSettingsBloc>().add(
            AppSettingsEvent.updateLastMusicLibraryUpdate(
              timestamp: DateTime.now(),
            ),
          );
          
          _logger.i('✅ Force song refresh initiated successfully');
          AppCustom.success(context, 'Force song refresh initiated');
        } else {
          _logger.w('❌ Permissions denied, showing permission required dialog');
          await PermissionService.showPermissionRequiredDialog(context);
        }
      }
    } catch (e) {
      _logger.e('❌ Error refreshing songs: $e');
      AppCustom.error(context, 'Error refreshing songs');
    }
  }


  // ==================== UTILITY METHODS ====================
  
  String _getFolderDisplayName(String folder) {
    // Extract just the folder name from the full path
    final parts = folder.split('/');
    return parts.isNotEmpty ? parts.last : folder;
  }


  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

}
