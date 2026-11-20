import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:hive/hive.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'utils/logger/logger.dart';
import 'utils/services/audio_handler.dart';
import 'utils/services/audio_service.dart';
import 'utils/services/library_storage.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'screens/bottom_tab/bloc/music_bloc.dart';
import 'utils/services/app_lifecycle_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = AppLogger('Main');
  logger.i('🎵 RhythmFlow starting...');

  await _initializeHydratedBloc();
  // Must be ready before the DI graph creates MusicBloc (it restores the
  // library from this store).
  await _initializeLibraryStorage();

  try {
    await configureDependencies();
    logger.i('✅ Dependencies initialized successfully');
  } catch (e) {
    logger.e('❌ Error initializing dependencies: $e');
  }

  // Initialize audio_service for background playback and notifications
  try {
    final audioHandler = RhythmFlowAudioHandler();
    await audio_service_pkg.AudioService.init(
      builder: () => audioHandler,
      config: audio_service_pkg.AudioServiceConfig(
      androidNotificationChannelId: 'com.technexa.rhythmflow.channel.audio',
      androidNotificationChannelName: 'RhythmFlow',
      androidNotificationOngoing: true,
        androidStopForegroundOnPause: true, // Must be true when androidNotificationOngoing is true
        androidShowNotificationBadge: true,
        androidNotificationClickStartsActivity: true,
      ),
    );
    
    // Set the audio handler in AudioService after initialization
    try {
      final audioService = getIt<AudioService>();
      audioService.setAudioHandler(audioHandler);
      logger.i('✅ AudioService handler connected');
    } catch (e) {
      logger.w('⚠️ Could not connect AudioService handler: $e');
    }
    
    logger.i('✅ AudioService initialized successfully');
  } catch (e) {
    logger.e('❌ AudioService initialization failed: $e');
  }

  // The Music Feature Analyzer (ML model) is initialised lazily by MusicBloc
  // the first time features are extracted, which keeps cold start fast.

  runApp(const MyApp());
}

Future<void> _initializeHydratedBloc() async {
  final logger = AppLogger('HydratedBlocInitializer');
  try {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorageDirectory.web
          : HydratedStorageDirectory(
              (await getApplicationDocumentsDirectory()).path,
            ),
    );
    logger.i('HydratedBloc storage initialized successfully');
  } catch (e) {
    logger.e('Error initializing HydratedBloc storage', error: e);
  }
}

Future<void> _initializeLibraryStorage() async {
  final logger = AppLogger('LibraryStorageInitializer');
  if (kIsWeb) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init('${dir.path}/rhythmflow_library');
    await LibraryStorage.init();
  } catch (e) {
    logger.e('Error initializing library storage', error: e);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Use centralized lifecycle handler for ALL lifecycle concerns
    AppLifecycleHandler.handleLifecycleChange(state);
  }

  ThemeMode _getThemeMode(AppSettingsState state) {
    if (state.followSystemTheme == true) {
      return ThemeMode.system;
    } else if (state.isDarkMode == true) {
      return ThemeMode.dark;
    } else if (state.isDarkMode == false) {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(const ThemeEvent.initialize()),
        ),
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
