import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/format_utils.dart';
import '../../../utils/services/fetch_songs.dart';
import 'bloc/app_settings_bloc.dart';
import '../../../screens/bottom_tab/screens/bloc/music_bloc.dart';

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
                _buildWhitelistSection(appSettingsState),
                SizedBox(height: 32.h),
                _buildRefreshSection(appSettingsState),
                SizedBox(height: 32.h),
                _buildManualFetchSection(appSettingsState, musicState),
                SizedBox(height: 80.h),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== SECTION BUILDERS ====================
  
  Widget _buildWhitelistSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Music Folders'),
        _buildWhitelistSettings(state),
      ],
    );
  }

  Widget _buildRefreshSection(AppSettingsState state) {
    return Column(
      children: [
        _buildSectionHeader('Library Management'),
        _buildRefreshSettings(state),
      ],
    );
  }

  Widget _buildManualFetchSection(AppSettingsState state, MusicState musicState) {
    return Column(
      children: [
        _buildSectionHeader('Add Music Manually'),
        _buildManualFetchSettings(state, musicState),
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
  
  Widget _buildWhitelistSettings(AppSettingsState state) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final folders = state.whiteListFolder[platform] ?? [];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeActionTile(
            icon: Icons.folder_open_rounded,
            title: 'Add Folder',
            subtitle: 'Select folder from device storage',
            onTap: _addFolder,
          ),
          if (folders.isNotEmpty) ...[
            _buildDivider(),
            ...folders.map((folder) => _buildFolderTile(folder, state)),
          ],
          if (folders.isEmpty) ...[
            _buildDivider(),
            _buildEmptyStateTile(),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshSettings(AppSettingsState state) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, musicState) {
        final isFetching = musicState.appSettingsFetchSong;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              _buildNativeActionTile(
                icon: Icons.refresh_rounded,
                title: 'Refresh Music Library',
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
      },
    );
  }

  Widget _buildManualFetchSettings(AppSettingsState state, MusicState musicState) {
    final isFetching = musicState.appSettingsFetchSong;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          _buildNativeActionTile(
            icon: Icons.file_open_rounded,
            title: 'Add Specific Files',
            subtitle: 'Select individual audio files',
            onTap: isFetching ? null : _fetchSpecificFiles,
            isLoading: isFetching,
          ),
          _buildDivider(),
          _buildNativeActionTile(
            icon: Icons.folder_rounded,
            title: 'Add from Folder',
            subtitle: 'Select a specific folder to scan',
            onTap: isFetching ? null : _fetchFromFolder,
            isLoading: isFetching,
          ),
        ],
      ),
    );
  }

  // ==================== TILE BUILDERS ====================
  
  Widget _buildFolderTile(String folder, AppSettingsState state) {
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
        onPressed: () => _removeFolder(folder, state),
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
      height: 1,
      thickness: 0.5,
      color: context.onSurfaceVariantColor.withValues(alpha: 0.2),
      indent: 16.w,
      endIndent: 16.w,
    );
  }

  // ==================== EVENT HANDLERS ====================
  
  Future<void> _addFolder() async {
    try {
      _logger.i('📁 Opening folder picker...');
      
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );
      
      if (selectedDirectory != null) {
        _logger.i('📁 Selected folder: $selectedDirectory');
        
        final platform = Platform.isAndroid ? 'android' : 'ios';
        context.read<AppSettingsBloc>().add(
          AppSettingsEvent.updateWhiteListFolder(
            platform: platform,
            folder: selectedDirectory,
            isRemove: false,
          ),
        );
        
        _showSnackBar('Folder added successfully', isSuccess: true);
      } else {
        _logger.i('📁 No folder selected');
      }
    } catch (e) {
      _logger.e('❌ Error selecting folder: $e');
      _showSnackBar('Error selecting folder', isSuccess: false);
    }
  }

  void _removeFolder(String folder, AppSettingsState state) {
    _logger.i('🗑️ Removing folder: $folder');
    
    final platform = Platform.isAndroid ? 'android' : 'ios';
    context.read<AppSettingsBloc>().add(
      AppSettingsEvent.updateWhiteListFolder(
        platform: platform,
        folder: folder,
        isRemove: true,
      ),
    );
    
    _showSnackBar('Folder removed successfully', isSuccess: true);
  }

  Future<void> _refreshAllSongs() async {
    try {
      _logger.i('🔄 Starting full song refresh (force refresh)...');
      _showSnackBar('Refreshing songs...', isSuccess: true);
      
      // Trigger music bloc to refresh all songs with force flag
      context.read<MusicBloc>().add(const MusicEvent.loadAllSongsProgressive(isForce: true));
      
      // Update last refresh time
      context.read<AppSettingsBloc>().add(
        AppSettingsEvent.updateLastMusicLibraryUpdate(
          timestamp: DateTime.now(),
        ),
      );
      
      _logger.i('✅ Force song refresh initiated successfully');
      _showSnackBar('Force song refresh initiated', isSuccess: true);
      
    } catch (e) {
      _logger.e('❌ Error refreshing songs: $e');
      _showSnackBar('Error refreshing songs', isSuccess: false);
    }
  }

  Future<void> _fetchSpecificFiles() async {
    try {
      _logger.i('📁 Opening file picker for specific files...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        dialogTitle: 'Select Audio Files',
      );
      
      if (result != null && result.files.isNotEmpty) {
        _logger.i('📁 Selected ${result.files.length} files');
        
        // Process selected files
        final filePaths = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
        
        if (filePaths.isNotEmpty) {
          _showSnackBar('Processing ${filePaths.length} files...', isSuccess: true);
          
          // Process the selected files using FetchSongsService
          try {
            // Set the fetch flag to true for manual operations
            context.read<MusicBloc>().add(
              MusicEvent.updateMusicBlocState(
                newState: context.read<MusicBloc>().state.copyWith(
                  appSettingsFetchSong: true,
                ),
              ),
            );
            
            final songs = <Song>[];
            for (final filePath in filePaths) {
              final file = File(filePath);
              if (await file.exists()) {
                // Use the metadata extractor directly
                final song = await FetchSongsService.processFile(file, supportedFormats: FormatUtils.getSupportedFormats(context));
                if (song != null) {
                  songs.add(song);
                }
              }
            }
            
            if (songs.isNotEmpty) {
              // Add songs to music bloc
              context.read<MusicBloc>().add(
                MusicEvent.updateMusicBlocState(
                  newState: context.read<MusicBloc>().state.copyWith(
                    allSongs: [...context.read<MusicBloc>().state.allSongs, ...songs],
                    appSettingsFetchSong: false,
                  ),
                ),
              );
              
              // Refresh albums and artists
              context.read<MusicBloc>().refreshAlbumsAndArtists();
              
              _logger.i('✅ ${songs.length} files processed successfully');
              _showSnackBar('${songs.length} files added to library', isSuccess: true);
            } else {
              _showSnackBar('No valid audio files found', isSuccess: false);
              
              // Set flag to false even when no songs found
              context.read<MusicBloc>().add(
                MusicEvent.updateMusicBlocState(
                  newState: context.read<MusicBloc>().state.copyWith(
                    appSettingsFetchSong: false,
                  ),
                ),
              );
            }
          } catch (e) {
            _logger.e('❌ Error processing files: $e');
            _showSnackBar('Error processing files', isSuccess: false);
            
            // Set flag to false on error
            context.read<MusicBloc>().add(
              MusicEvent.updateMusicBlocState(
                newState: context.read<MusicBloc>().state.copyWith(
                  appSettingsFetchSong: false,
                ),
              ),
            );
          }
        } else {
          _showSnackBar('No valid files selected', isSuccess: false);
        }
      } else {
        _logger.i('📁 No files selected');
      }
    } catch (e) {
      _logger.e('❌ Error fetching specific files: $e');
      _showSnackBar('Error processing files', isSuccess: false);
    }
  }

  Future<void> _fetchFromFolder() async {
    try {
      _logger.i('📁 Opening folder picker for manual fetch...');
      
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder to Scan',
      );
      
      if (selectedDirectory != null) {
        _logger.i('📁 Selected folder for manual fetch: $selectedDirectory');
        
        _showSnackBar('Scanning folder...', isSuccess: true);
        
        // Set the fetch flag to true for manual operations
        context.read<MusicBloc>().add(
          MusicEvent.updateMusicBlocState(
            newState: context.read<MusicBloc>().state.copyWith(
              appSettingsFetchSong: true,
            ),
          ),
        );
        
        // Scan the selected folder for songs
        try {
          final songs = await FetchSongsService.scanFolderForSongs(selectedDirectory, supportedFormats: FormatUtils.getSupportedFormats(context));
          
          if (songs.isNotEmpty) {
            // Add songs to music bloc
            context.read<MusicBloc>().add(
              MusicEvent.updateMusicBlocState(
                newState: context.read<MusicBloc>().state.copyWith(
                  allSongs: [...context.read<MusicBloc>().state.allSongs, ...songs],
                  appSettingsFetchSong: false,
                ),
              ),
            );
            
            // Refresh albums and artists
            context.read<MusicBloc>().refreshAlbumsAndArtists();
            
            _logger.i('✅ Folder scanned successfully: ${songs.length} songs found');
            _showSnackBar('${songs.length} songs added from folder', isSuccess: true);
          } else {
            _showSnackBar('No songs found in folder', isSuccess: false);
            
            // Set flag to false even when no songs found
            context.read<MusicBloc>().add(
              MusicEvent.updateMusicBlocState(
                newState: context.read<MusicBloc>().state.copyWith(
                  appSettingsFetchSong: false,
                ),
              ),
            );
          }
        } catch (e) {
          _logger.e('❌ Error scanning folder: $e');
          _showSnackBar('Error scanning folder', isSuccess: false);
          
          // Set flag to false on error
          context.read<MusicBloc>().add(
            MusicEvent.updateMusicBlocState(
              newState: context.read<MusicBloc>().state.copyWith(
                appSettingsFetchSong: false,
              ),
            ),
          );
        }
      } else {
        _logger.i('📁 No folder selected for manual fetch');
      }
    } catch (e) {
      _logger.e('❌ Error fetching from folder: $e');
      _showSnackBar('Error scanning folder', isSuccess: false);
      
      // Set flag to false on error
      context.read<MusicBloc>().add(
        MusicEvent.updateMusicBlocState(
          newState: context.read<MusicBloc>().state.copyWith(
            appSettingsFetchSong: false,
          ),
        ),
      );
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

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}
