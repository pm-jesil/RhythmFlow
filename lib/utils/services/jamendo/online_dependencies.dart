import 'dart:async';

import '../../../core/di/injection.dart';
import '../../../screens/app_settings/bloc/app_settings_bloc.dart';
import '../../../screens/bottom_tab/bloc/music_bloc.dart';
import '../../../screens/online/bloc/discover_bloc.dart';
import '../../../screens/online/bloc/online_library_bloc.dart';
import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import '../audio_service.dart';
import 'download_service.dart';
import 'jamendo_cache.dart';
import 'jamendo_repository.dart';
import 'online_song_registry.dart';

/// Creates and wires the Discover (online) services. Registered in GetIt by
/// hand (not via injectable) so the generated DI config stays unchanged.
class OnlineDependencies {
  OnlineDependencies._();

  static final AppLogger _logger = AppLogger('OnlineDependencies');
  static final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Delay before likes refresh "Made for you" (several taps -> one call).
  static Duration likesRefreshDelay = const Duration(seconds: 3);

  /// Call after HydratedBloc storage, Hive and `configureDependencies()`.
  static Future<void> init() async {
    if (getIt.isRegistered<JamendoRepository>()) return;

    final repository = JamendoRepository(cache: await JamendoCache.open());
    getIt.registerSingleton<JamendoRepository>(repository);
    AudioService.remoteUrlResolver = repository.resolveStreamUrl;

    final library = OnlineLibraryBloc();
    getIt.registerSingleton<OnlineLibraryBloc>(library);

    final discover = DiscoverBloc(
      repository: repository,
      libraryInputs: () => (
        liked: library.state.likedSongs,
        recent: library.state.recentlyPlayed.where((s) => !s.isRadio).toList(),
      ),
    );
    getIt.registerSingleton<DiscoverBloc>(discover);

    final musicBloc = getIt<MusicBloc>();
    getIt.registerSingleton<DownloadService>(
      DownloadService(
        library: library,
        // New file in Music/RhythmFlow -> refresh "My Music".
        onSaved: () => musicBloc.requestAutoRefresh(reason: 'song downloaded'),
      ),
    );

    final settings = getIt<AppSettingsBloc>();
    connect(
      settings: settings,
      musicBloc: musicBloc,
      discover: discover,
      library: library,
    );
    _logger.i('🌐 Discover services ready');
  }

  /// Wires the blocs together (public for tests).
  static void connect({
    required AppSettingsBloc settings,
    required MusicBloc musicBloc,
    required DiscoverBloc discover,
    required OnlineLibraryBloc library,
  }) {
    // Country / language picked in settings -> personalised Discover rows.
    String regionKey(AppSettingsState s) =>
        '${s.musicCountry}|${s.musicLanguages.join(',')}|${s.musicTastes.join(',')}';
    var lastRegion = regionKey(settings.state);
    _subscriptions.add(
      settings.stream.listen((s) {
        final key = regionKey(s);
        if (key == lastRegion) return;
        lastRegion = key;
        discover.add(
          DiscoverEvent.regionChanged(
            country: s.musicCountry,
            languages: s.musicLanguages,
            tastes: s.musicTastes,
          ),
        );
      }),
    );

    // Likes change -> refresh "Made for you" (debounced).
    var likedKey = library.state.likedSongs.map((s) => s.id).join(',');
    Timer? likesTimer;
    _subscriptions.add(
      library.stream.listen((s) {
        final key = s.likedSongs.map((x) => x.id).join(',');
        if (key == likedKey) return;
        likedKey = key;
        likesTimer?.cancel();
        likesTimer = Timer(likesRefreshDelay, () {
          if (discover.state.sections.containsKey(DiscoverSectionIds.madeForYou)) {
            discover.add(
              const DiscoverEvent.refreshSection(sectionId: DiscoverSectionIds.madeForYou),
            );
          }
        });
      }),
    );

    // Online song started -> "Recently played".
    String? lastSongId = musicBloc.state.myPlayerState.currentSongId;
    _subscriptions.add(
      musicBloc.stream.listen((s) {
        final id = s.myPlayerState.currentSongId;
        if (id == null || id == lastSongId) return;
        lastSongId = id;
        final song = OnlineSongRegistry.get(id);
        if (song != null) library.add(OnlineLibraryEvent.recordPlay(song));
      }),
    );
  }

  /// For tests.
  static Future<void> disconnect() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}
