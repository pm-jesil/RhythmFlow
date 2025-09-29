import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:pmj_music_player/core/di/injection.dart';
import 'package:pmj_music_player/screens/app_settings/bloc/app_settings_bloc.dart';
import 'utils/logger/logger.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'screens/bottom_tab/screens/bloc/music_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  final logger = AppLogger('Main');
  logger.i('🎵 PMJ Music Player starting...');

  // Initialize HydratedBloc storage FIRST (before any HydratedBloc instances are created)
  await _initializeHydratedBloc();

  // Initialize dependencies AFTER storage is ready
  try {
    await configureDependencies();
    logger.i('✅ Dependencies initialized successfully');
  } catch (e) {
    logger.e('❌ Error initializing dependencies: $e');
    // Continue anyway, some services might still work
  }

  // Initialize just_audio_background for notification and lock screen controls
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.pmj.music_player.channel.audio',
      androidNotificationChannelName: 'PMJ Music Player',
      androidNotificationOngoing: true,
    );
    logger.i('✅ JustAudioBackground initialized successfully');
  } catch (e) {
    logger.e('❌ JustAudioBackground initialization failed: $e');
    logger.i('📱 Continuing without background audio support...');
    // Don't rethrow the error, just continue without background audio
  }

  // Initialize app
  runApp(const MyApp());
}

/// Initialize HydratedBloc for state persistence
Future<void> _initializeHydratedBloc() async {
  final logger = AppLogger('HydratedBlocInitializer');
  try {
    // Initialize HydratedBloc with proper storage directory
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorageDirectory.web
          : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
    );

    logger.i('HydratedBloc storage initialized successfully');
  } catch (e) {
    logger.e('Error initializing HydratedBloc storage', error: e);
    // Continue without persistence if there's an error
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Get the appropriate ThemeMode based on app settings
  ThemeMode _getThemeMode(AppSettingsState state) {
    if (state.followSystemTheme == true) {
      return ThemeMode.system;
    } else if (state.isDarkMode == true) {
      return ThemeMode.dark;
    } else if (state.isDarkMode == false) {
      return ThemeMode.light;
    } else {
      // First install - follow system
      return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme Bloc
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(const ThemeEvent.initialize()),
        ),
        // Music Bloc
        BlocProvider(create: (ctx) => getIt<MusicBloc>()),
        BlocProvider(create: (ctx) => getIt<AppSettingsBloc>()),
      ],
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, appSettingsState) {
          return ScreenUtilInit(
            designSize: const Size(375, 812), // iPhone X design size
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: _getThemeMode(appSettingsState),
                routerConfig: AppRouter.router,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
