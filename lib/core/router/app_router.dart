import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import '../../screens/bottom_tab/bottom_tab.dart';
import '../../screens/music_player/music_player_screen.dart';
import '../../screens/palying_queue_screen/playing_queue_screen.dart';
import '../../screens/playlist_detail_screen/playlist_detail_screen.dart';
import '../../screens/app_settings/settings_screen.dart';
import '../../screens/app_settings/music_library_settings_screen.dart';
import '../../screens/app_settings/profile_edit_screen.dart';
import '../../screens/app_settings/comprehensive_features_settings_screen.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/app_settings/bloc/app_settings_bloc.dart';
import '../../utils/services/app_update_service.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/artist/artist_model.dart';
import '../../utils/models/album/album_model.dart';
import '../../utils/models/my_playlist/my_playlist_model.dart';

class AppRouter {

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main bottom tab screen with profile check and update check
      GoRoute(
        path: '/', 
        builder: (context, state) {
          return BlocBuilder<AppSettingsBloc, AppSettingsState>(
            builder: (context, appSettingsState) {
              // Check if user profile is set
              final isProfileSet = appSettingsState.userName != null && 
                                   appSettingsState.nickName != null;
              
              final content = isProfileSet 
                ? const BottomTab() 
                : const WelcomeScreen();
              
              // Run update check silently in background; show content immediately
              return _SilentUpdateWrapper(child: content);
            },
          );
        },
      ),

      GoRoute(
        path: '/play/:songId',
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Use modal player instead')));
        },
      ),

      GoRoute(
        path: '/play',
        builder: (context, state) {
          return const Scaffold(body: Center(child: Text('Use modal player instead')));
        },
      ),

      GoRoute(
        path: '/playing-queue',
        builder: (context, state) {
          return const PlayingQueueScreen();
        },
      ),

      GoRoute(
        path: '/playlist-detail/:type/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? '';
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};

          final name = extra['name'] ?? 'Unknown';
          final description = extra['description'];
          final year = extra['year'];
          final bio = extra['bio'];
          final songCount = extra['songCount'] ?? 0;
          final songs = extra['songs'] as List<Song>? ?? [];
          final coverImage = extra['coverImage'];

          return PlaylistDetailScreen(
            type: _parseDetailType(type),
            id: id,
            name: name,
            description: description,
            year: year,
            bio: bio,
            songCount: songCount,
            songs: songs,
            coverImage: coverImage,
          );
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return const SettingsScreen();
        },
      ),

      GoRoute(
        path: '/settings/music-library',
        builder: (context, state) {
          return const MusicLibrarySettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/profile-edit',
        builder: (context, state) {
          return const ProfileEditScreen();
        },
      ),

      
      GoRoute(
        path: '/comprehensive-features-settings',
        builder: (context, state) {
          return const ComprehensiveFeaturesSettingsScreen();
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: context.error),
              SizedBox(height: 16.h),
              Text(
                'Page not found',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'The page you are looking for does not exist.',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryStart,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Go to Home',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  static PlaylistDetailType _parseDetailType(String type) {
    switch (type.toLowerCase()) {
      case 'album':
        return PlaylistDetailType.album;
      case 'artist':
        return PlaylistDetailType.artist;
      case 'playlist':
        return PlaylistDetailType.playlist;
      default:
        return PlaylistDetailType.album;
    }
  }

}

// Helper extension for navigation
extension NavigationExtension on BuildContext {
  void navigateToHome() {
    GoRouter.of(this).go('/');
  }

  void navigateToSongList() {
    GoRouter.of(this).go('/');
  }

  void navigateToPlaySong(String songId) {
    MusicPlayerModal.showWithGetIt(this);
  }

  void navigateToPlaySongWithData(Map<String, dynamic> songData) {
    MusicPlayerModal.showWithGetIt(this);
  }

  void navigateToPlayingQueue() {
    GoRouter.of(this).push('/playing-queue');
  }

  void navigateToPlaylistDetail({
    required PlaylistDetailType type,
    required String id,
    required String name,
    String? description,
    String? year,
    String? bio,
    required int songCount,
    int? albumCount,
  }) {
    GoRouter.of(this).push(
      '/playlist-detail/${type.name}/$id',
      extra: {
        'name': name,
        'description': description,
        'year': year,
        'bio': bio,
        'songCount': songCount,
        'albumCount': albumCount,
      },
    );
  }

  // New object-based navigation methods
  void navigateToArtistDetail(Artist artist) {
    GoRouter.of(this).push(
      '/playlist-detail/artist/${artist.id}',
      extra: {'artist': artist},
    );
  }

  void navigateToAlbumDetail(Album album) {
    GoRouter.of(this).push(
      '/playlist-detail/album/${album.id}',
      extra: {'album': album},
    );
  }

  void navigateToMyPlaylistDetail(MyPlaylist playlist) {
    GoRouter.of(this).push(
      '/playlist-detail/playlist/${playlist.id}',
      extra: {'playlist': playlist},
    );
  }

  void goBack() {
    GoRouter.of(this).pop();
  }

  void goToRoot() {
    GoRouter.of(this).go('/');
  }

  void navigateToSettings() {
    GoRouter.of(this).push('/settings');
  }

  void navigateToMusicLibrarySettings() {
    GoRouter.of(this).push('/settings/music-library');
  }

  void navigateToProfileEdit() {
    GoRouter.of(this).push('/settings/profile-edit');
  }


  void navigateToComprehensiveFeaturesSettings() {
    GoRouter.of(this).push('/comprehensive-features-settings');
  }
}

/// Lightweight wrapper that triggers a silent background update check
class _SilentUpdateWrapper extends StatefulWidget {
  final Widget child;
  const _SilentUpdateWrapper({required this.child});

  @override
  State<_SilentUpdateWrapper> createState() => _SilentUpdateWrapperState();
}

class _SilentUpdateWrapperState extends State<_SilentUpdateWrapper> {
  @override
  void initState() {
    super.initState();
    // Defer to next frame to ensure UI renders first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fire-and-forget silent update check
      // No UI is presented; downloads happen in background for flexible updates
      AppUpdateService.checkForUpdatesSilently();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
