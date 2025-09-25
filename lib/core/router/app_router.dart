import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../screens/bottom_tab/bottom_tab.dart';
import '../../screens/music_player/music_player_screen.dart';
import '../../screens/music_player/playing_queue_screen.dart';
import '../../screens/bottom_tab/screens/playlist_detail_screen.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/logger/logger.dart';

class AppRouter {
  static final AppLogger _logger = AppLogger('AppRouter');

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main bottom tab screen
      GoRoute(path: '/', builder: (context, state) => const BottomTab()),

      // Play song screen
      GoRoute(
        path: '/play/:songId',
        builder: (context, state) {
          final songId = state.pathParameters['songId'] ?? '';
          _logger.d('Navigate to play song: $songId');
          return const MusicPlayerScreen();
        },
      ),

      // Play song screen without parameters (for direct navigation)
      GoRoute(
        path: '/play',
        builder: (context, state) {
          final songData = state.extra as Map<String, dynamic>? ?? {};
          _logger.d('Navigate to play song with data: ${songData['id']}');
          return const MusicPlayerScreen();
        },
      ),

      // Playing Queue screen (UI label kept)
      GoRoute(
        path: '/playing-queue',
        builder: (context, state) {
          _logger.d('Navigate to playing queue');
          return const PlayingQueueScreen();
        },
      ),

      // Playlist Detail screen
      GoRoute(
        path: '/playlist-detail/:type/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? '';
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};

          _logger.d('Navigate to playlist detail: $type/$id');

          return PlaylistDetailScreen(
            type: _parseDetailType(type),
            id: id,
            name: extra['name'] ?? 'Unknown',
            description: extra['description'],
            year: extra['year'],
            bio: extra['bio'],
            songCount: extra['songCount'] ?? 0,
            albumCount: extra['albumCount'],
          );
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
    AppLogger('Navigation').d('Navigate to home');
    GoRouter.of(this).go('/');
  }

  void navigateToSongList() {
    GoRouter.of(this).go('/');
  }

  void navigateToPlaySong(String songId) {
    AppLogger('Navigation').d('Navigate to play song: $songId');
    // Show modal instead of navigation
    MusicPlayerModal.showWithGetIt(this);

    // AppLogger('Navigation').d('Navigate to Music Player 2');
    // // Show Music Player 2 modal
    // MusicPlayerModal2.showWithGetIt(this);
  }

  void navigateToPlaySongWithData(Map<String, dynamic> songData) {
    AppLogger(
      'Navigation',
    ).d('Navigate to play song with data: ${songData['id']}');
    // Show modal instead of navigation
    MusicPlayerModal.showWithGetIt(this);
  }

  void navigateToPlayingQueue() {
    AppLogger('Navigation').d('Navigate to playing queue');
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
    AppLogger('Navigation').d('Navigate to playlist detail: ${type.name}/$id');
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

  void goBack() {
    AppLogger('Navigation').d('Navigate back');
    GoRouter.of(this).pop();
  }

  void goToRoot() {
    GoRouter.of(this).go('/');
  }
}
