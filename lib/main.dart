import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:rhythmflow/core/di/injection.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:music_feature_analyzer/music_feature_analyzer.dart';
import 'utils/logger/logger.dart';
import 'package:just_audio_background/just_audio_background.dart';

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

  try {
    await configureDependencies();
    logger.i('✅ Dependencies initialized successfully');
  } catch (e) {
    logger.e('❌ Error initializing dependencies: $e');
  }

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.technexa.rhythmflow.channel.audio',
      androidNotificationChannelName: 'RhythmFlow',
      androidNotificationOngoing: true,
    );
    logger.i('✅ JustAudioBackground initialized successfully');
  } catch (e) {
    logger.e('❌ JustAudioBackground initialization failed: $e');
  }

  // Initialize Music Feature Analyzer
  try {
    logger.i('🚀 Initializing Music Feature Analyzer...');
    final analyzerInitialized = await MusicFeatureAnalyzer.initialize();
    if (analyzerInitialized) {
      logger.i('✅ Music Feature Analyzer initialized successfully');
    } else {
      logger.w(
        '⚠️ Music Feature Analyzer initialization failed - will retry later',
      );
    }
  } catch (e) {
    logger.e('❌ Music Feature Analyzer initialization error: $e');
    // Continue anyway - will retry in bloc if needed
  }

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
