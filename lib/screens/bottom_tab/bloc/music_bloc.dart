import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythmflow/core/constants/app_enums.dart';
import 'package:rhythmflow/core/constants/app_constants.dart';
import 'package:rhythmflow/utils/models/my_playlist/my_playlist_model.dart';
import 'package:music_feature_analyzer/music_feature_analyzer.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/my_player_state_model.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/services/fetch_songs.dart';
import '../../../utils/services/music_metadata_service.dart';
import '../../../utils/services/music_service.dart';
import '../../../utils/services/audio_service.dart';
import '../../../utils/services/remote_control_service.dart';
import '../../../utils/services/song_cleanup_service.dart';
import '../../../utils/services/play_count_tracking_service.dart';
import '../../../utils/services/my_playlist_service.dart';
import '../../../utils/services/app_lifecycle_handler.dart';
import '../../../utils/services/ai_shuffle/ai_shuffle_service.dart';
import '../../widgets/sync_app_settings_helper.dart';
import '../../app_settings/bloc/app_settings_bloc.dart';
import '../../widgets/sorting_helper.dart';
import '../../widgets/playlist_source_helper.dart';

part 'music_event.dart';
part '../bloc/music_state.dart';
part 'music_bloc.freezed.dart';

@singleton
class MusicBloc extends HydratedBloc<MusicEvent, MusicState> {
  static final AppLogger _logger = AppLogger('MusicBloc');

  // Services
  final AudioService _audioService;
  final RemoteControlService _remoteControlService;
  final AppSettingsBloc _appSettingsBloc;

  // Stream subscriptions for proper disposal
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<AppSettingsState>? _appSettingsSubscription;

  // Sleep timer
  Timer? _sleepTimer;

  // Flag to prevent race conditions during state updates
  bool _isUpdatingState = false;

  // Queue for pending song changes to prevent race conditions
  final List<Song> _pendingSongChanges = [];
  bool _isProcessingSongChanges = false;

  // Flag to prevent position updates during app initialization
  bool _isInitializing = true;

  // Counter to prevent infinite loops with invalid songs
  int _invalidSongAttempts = 0;
  static const int maxInvalidSongAttempts = 3;

  /// Count of in-flight Next/Previous actions. When > 0: ignore completion,
  /// ignore onSongChanged queue, and ignore "invalid song" from interrupted loads.
  int _programmaticChangeCount = 0;

  // Track previous AI shuffle state to detect when it's enabled
  bool _previousAiShuffleState = false;

  // Sorting options constants
  static const List<String> sortingOptions = [
    'Newest First',
    'Oldest First',
    'Alphabetical',
    'Duration (Shortest)',
    'Duration (Longest)',
    'Most Played',
  ];

  MusicBloc(
    this._audioService,
    this._remoteControlService,
    this._appSettingsBloc,
  ) : super(MusicState.initial()) {
    _setupPlayCountTracking();

    on<_FetchAndUpdateSongs>(_onFetchAndUpdateSongs);
    on<_FetchAndUpdateMetadata>(_onFetchAndUpdateMetadata);
    on<_LoadMyPlaylists>(_onLoadMyPlaylists);
    on<_AddOrUpdateMyPlayList>(_onAddOrUpdateMyPlayList);
    on<_PlayOrPauseSong>(_onPlayOrPauseSong);
    on<_PlayNext>(_onPlayNext);
    on<_PlayPrevious>(_onPlayPrevious);
    on<_ToggleShuffle>(_onToggleShuffle);
    on<_ToggleRepeat>(_onToggleRepeat);
    on<_ChangeSortingOrder>(_onChangeSortingOrder);
    on<_SeekToPosition>(_onSeekToPosition);
    on<_UpdateLastPosition>(_onUpdateLastPosition);
    on<_UpdateFilterKeyword>(_onUpdateFilterKeyword);
    on<_SetNavigationFilter>(_onSetNavigationFilter);
    on<_UpdateMusicBlocState>(_onUpdateMusicBlocState);
    on<_ExtractComprehensiveFeatures>(_onExtractComprehensiveFeatures);
    on<_AiShuffle>(_onAiShuffle);

    _audioService.onSongChanged = _onAudioServiceSongChanged;
    _audioService.setPositionChangedCallback(_onPositionChanged);
    _audioService.setInvalidSongCallback(_onInvalidSong);
    _audioService.setSkipCallbacks(
      onNext: () => add(const MusicEvent.playNext()),
      onPrevious: () => add(const MusicEvent.playPrevious()),
    );
    _audioService.setShuffleRepeatCallbacks(
      onShuffle: () {
        // Trigger the same 3-state cycle logic as music player screen
        // None → AI → Normal → None
        final currentPlayList = state.myPlayerState.currentPlayList;
        final currentSongId = state.myPlayerState.currentSongId;
        final appSettings = _appSettingsBloc.state;
        final isAiShuffleEnabled = appSettings.isAiShuffleEnabled;
        final isShuffleActive = state.myPlayerState.isShuffle;

        if (isAiShuffleEnabled) {
          // AI → Normal: disable AI, then enable regular shuffle (auto-start)
          _appSettingsBloc.add(
            AppSettingsEvent.updateAiShuffle(isEnabled: false),
          );
          add(
            MusicEvent.toggleShuffle(
              isShuffle: true,
              currentPlayList: currentPlayList,
              isAutoStart: false,
            ),
          );
        } else if (isShuffleActive) {
          // Normal → None: disable regular shuffle
          add(
            MusicEvent.toggleShuffle(
              isShuffle: false,
              currentPlayList: currentPlayList,
            ),
          );
        } else {
          // None → AI: enable AI and trigger AI shuffle
          _appSettingsBloc.add(
            AppSettingsEvent.updateAiShuffle(isEnabled: true),
          );
          if (currentSongId != null) {
            add(
              MusicEvent.aiShuffle(
                currentSongId: currentSongId,
                currentPlayList: currentPlayList,
              ),
            );
          }
        }
      },
      onRepeat: () => add(const MusicEvent.toggleRepeat()),
    );
    _audioService.setPlayPauseCallbacks(
      onPlay: () {
        // When play is pressed from notification, trigger play/pause event
        if (state.myPlayerState.currentSongId != null &&
            !state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
      },
      onPause: () {
        // When pause is pressed from notification, trigger play/pause event
        if (state.myPlayerState.currentSongId != null &&
            state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
      },
    );
    _remoteControlService.setActionCallback(_handleRemoteControlAction);

    SyncAppSettingsHelper.initializeSettingsSync(
      appSettingsBloc: _appSettingsBloc,
      audioService: _audioService,
    );

    // Sync initial shuffle/repeat state to notification when bloc is created
    // This ensures notification shows correct icons on first song play
    _audioService.updateShuffleRepeatState(
      isShuffle: state.myPlayerState.isShuffle,
      isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
      repeatModeIndex: state.myPlayerState.repeatModeIndex,
    );
    _logger.i('📱 Initial shuffle/repeat state synced to notification');

    // Listen to app settings changes for mutual exclusivity
    _previousAiShuffleState = _appSettingsBloc.state.isAiShuffleEnabled;
    _appSettingsBloc.stream.listen((appSettingsState) {
      final isAiShuffleNowEnabled = appSettingsState.isAiShuffleEnabled;

      // When AI shuffle is enabled, disable regular shuffle
      if (isAiShuffleNowEnabled && state.myPlayerState.isShuffle) {
        _logger.i('🤖 AI Shuffle enabled - disabling regular shuffle');
        add(
          const MusicEvent.toggleShuffle(isShuffle: false, currentPlayList: []),
        );
        // Update notification to show AI shuffle
        _audioService.updateShuffleRepeatState(
          isShuffle: false,
          isAiShuffle: true,
        );
      } else if (!isAiShuffleNowEnabled) {
        // When AI shuffle is disabled, clear AI shuffle state in notification
        _audioService.updateShuffleRepeatState(isAiShuffle: false);
      }

      // Check and trigger music features analysis when AI shuffle is enabled
      // Only check if AI shuffle was just enabled (not if it was already enabled)
      if (isAiShuffleNowEnabled && !_previousAiShuffleState) {
        _logger.i('🤖 AI Shuffle enabled - checking music features analysis');
        _checkAndTriggerFeatureAnalysis();
      }

      // Update previous state for next comparison
      _previousAiShuffleState = isAiShuffleNowEnabled;
    });

    // On every app launch: check in background if all songs have AI features extracted;
    // if not, automatically trigger comprehensive feature extraction for pending songs.
    Future.delayed(const Duration(milliseconds: 1200), () {
      _logger.i(
        '🔬 App launch - checking for pending comprehensive feature extraction',
      );
      _checkAndTriggerFeatureAnalysis();
    });

    // Initialize app lifecycle handler
    AppLifecycleHandler.initialize(
      musicBloc: this,
      appSettingsBloc: _appSettingsBloc,
    );

    _appSettingsSubscription = _appSettingsBloc.stream.listen((
      appSettingsState,
    ) {
      SyncAppSettingsHelper.syncAllSettings(
        appSettingsBloc: _appSettingsBloc,
        audioService: _audioService,
      );
      SyncAppSettingsHelper.handleSleepTimerSettingsChange(
        appSettingsBloc: _appSettingsBloc,
        musicBloc: this,
      );
    });

    _playerStateSubscription = _audioService.playerStateStream.listen((
      playerState,
    ) {
      if (!_isUpdatingState) {
        if (state.myPlayerState.isPlaying != playerState.playing) {
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: state.myPlayerState.copyWith(
                  isPlaying: playerState.playing,
                ),
              ),
            ),
          );
        }
      }

      if (playerState.processingState == ProcessingState.completed &&
          _programmaticChangeCount == 0) {
        _handleSongCompletion();
      }
    });

    // Ensure favorites playlist exists after HydratedBloc initialization
    // Use a delayed check to ensure state is loaded from storage first
    Future.delayed(const Duration(milliseconds: 100), () {
      _ensureFavoritesPlaylistOnInit();
    });
  }

  /// Ensure favorites playlist exists in the current state
  /// This method checks if favorites exists and adds it if missing
  void _ensureFavoritesPlaylistOnInit() {
    final currentPlaylists = state.myPlaylist;
    final hasFavorites = currentPlaylists.any(
      (p) => p.id == MyPlaylistService.createDefaultFavoritesPlaylist().id,
    );

    if (!hasFavorites) {
      _logger.i(
        '❤️ Favorites playlist not found in state, adding default favorites playlist',
      );
      final playlistsWithFavorites = MyPlaylistService.ensureFavoritesPlaylist(
        currentPlaylists,
      );
      // Update state with favorites playlist
      add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(myPlaylist: playlistsWithFavorites),
        ),
      );
    } else {
      _logger.d('✅ Favorites playlist already exists in state');
    }
  }

  @override
  String get storagePrefix => 'MusicBloc';

  @override
  Map<String, dynamic>? toJson(MusicState state) {
    try {
      return {
        'sortingIndex': state.sortingIndex,
        'allSongs': state.allSongs.map((s) => s.toJson()).toList(),
        'albumList': state.albumList.map((a) => a.toJson()).toList(),
        'artistList': state.artistList.map((a) => a.toJson()).toList(),
        'myPlaylist': state.myPlaylist.map((p) => p.toJson()).toList(),
        'myPlayerState': {
          'completedSongs': state.myPlayerState.completedSongs,
          'currentPlayList': state.myPlayerState.currentPlayList,
          'currentSongId': state.myPlayerState.currentSongId,
          'repeatModeIndex': state.myPlayerState.repeatModeIndex,
          'playlistId': state.myPlayerState.playlistId,
          'previousSongId': state.myPlayerState.previousSongId,
          'isShuffle': state.myPlayerState.isShuffle,
          'isPlaying': state.myPlayerState.isPlaying,
          'lastPosition': state.myPlayerState.lastPosition?.inMilliseconds,
        },
        'comprehensiveFeatureExtractionFailureCount': state
            .comprehensiveFeatureExtractionFailureCount
            .map((k, v) => MapEntry(k, v)),
      };
    } catch (_) {
      return null; // skip persisting on serialization errors
    }
  }

  @override
  MusicState? fromJson(Map<String, dynamic> json) {
    try {
      final songs = (json['allSongs'] as List<dynamic>? ?? [])
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
      final albums = (json['albumList'] as List<dynamic>? ?? [])
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
      final artists = (json['artistList'] as List<dynamic>? ?? [])
          .map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList();
      final myPlaylists = (json['myPlaylist'] as List<dynamic>? ?? [])
          .map((e) => MyPlaylist.fromJson(e as Map<String, dynamic>))
          .toList();

      // Ensure favorites playlist exists when loading from storage
      final playlistsWithFavorites = MyPlaylistService.ensureFavoritesPlaylist(
        myPlaylists,
      );

      final mp = (json['myPlayerState'] as Map<String, dynamic>? ?? {});
      var myPlayerState = MyPlayerStateModel(
        playlistId: mp['playlistId'] as String?,
        currentPlayList: List<String>.from(mp['currentPlayList'] ?? const []),
        currentSongId: mp['currentSongId'] as String?,
        previousSongId: mp['previousSongId'] as String?,
        completedSongs: List<String>.from(mp['completedSongs'] ?? const []),
        repeatModeIndex: (mp['repeatModeIndex'] as int?) ?? 0,
        filterKeyword: '',
        isShuffle: (mp['isShuffle'] as bool?) ?? true,
        isPlaying: false,
        lastPosition: mp['lastPosition'] != null
            ? Duration(milliseconds: mp['lastPosition'] as int)
            : null,
      );
      // Restore: if we have a current song but queue was empty, repopulate queue
      if (myPlayerState.currentSongId != null &&
          myPlayerState.currentPlayList.isEmpty) {
        myPlayerState = myPlayerState.copyWith(
          currentPlayList: [myPlayerState.currentSongId!],
        );
      }

      final failureCountRaw =
          json['comprehensiveFeatureExtractionFailureCount'];
      final Map<String, int> comprehensiveFeatureExtractionFailureCount;
      if (failureCountRaw is Map) {
        comprehensiveFeatureExtractionFailureCount = failureCountRaw.map(
          (k, v) => MapEntry(
            k.toString(),
            (v is int) ? v : (v is num ? v.toInt() : 0),
          ),
        );
      } else {
        comprehensiveFeatureExtractionFailureCount = const <String, int>{};
      }

      return MusicState(
        myPlayerState: myPlayerState,
        allSongs: songs,
        albumList: albums,
        artistList: artists,
        myPlaylist: playlistsWithFavorites,
        sortingIndex: (json['sortingIndex'] as int?) ?? 0,

        isSongListLoading: false,
        isAlbumListLoading: false,
        isArtistListLoading: false,
        isSongListError: false,
        isAlbumListError: false,
        isArtistListError: false,
        isLoading: false,
        isError: false,
        isComprehensiveFeaturesExtractingLoading: false,
        isComprehensiveFeaturesExtractingError: false,
        comprehensiveFeatureExtractionFailureCount:
            comprehensiveFeatureExtractionFailureCount,
      );
    } catch (e) {
      _logger.e('Failed to restore state from storage: $e');
      // Clear corrupted storage to prevent future issues
      try {
        HydratedBloc.storage.clear();
        _logger.i('Cleared corrupted storage');
      } catch (clearError) {
        _logger.e('Failed to clear corrupted storage: $clearError');
      }
      return null; // Fall back to initial state
    }
  }

  // ==================== LOADING EVENT HANDLERS ====================

  /// Check if we should skip fetching based on last update time (configurable rule)
  bool _shouldSkipFetch() {
    final lastUpdate = _appSettingsBloc.state.lastUpdateMusicLibrary;
    if (lastUpdate == null) {
      _logger.i('⏰ No previous fetch time found - proceeding with fetch');
      return false;
    }

    final now = DateTime.now();
    final timeDifference = now.difference(lastUpdate);
    final refreshTimeGap = Duration(
      hours: _appSettingsBloc.state.appBackgroundRefreshTimeGap,
    );

    if (timeDifference < refreshTimeGap) {
      _logger.i(
        '⏰ Last fetch was ${timeDifference.inMinutes} minutes ago (< ${_appSettingsBloc.state.appBackgroundRefreshTimeGap} hours) - skipping fetch',
      );
      return true;
    } else {
      _logger.i(
        '⏰ Last fetch was ${timeDifference.inHours} hours ago (>= ${_appSettingsBloc.state.appBackgroundRefreshTimeGap} hours) - proceeding with fetch',
      );
      return false;
    }
  }

  /// Update the last music library fetch timestamp
  void _updateLastFetchTime() {
    _appSettingsBloc.add(
      AppSettingsEvent.updateLastMusicLibraryUpdate(timestamp: DateTime.now()),
    );
    _logger.i('⏰ Updated last music library fetch time');
  }

  /// Fetch and update songs - shows songs as they're fetched
  Future<void> _onFetchAndUpdateSongs(
    _FetchAndUpdateSongs event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🚀 Starting progressive song loading... (isForce: ${event.isForce ?? false})',
    );

    // Check if we should skip fetching based on 5-hour rule (unless force refresh)
    if (!(event.isForce ?? false) &&
        _shouldSkipFetch() &&
        state.allSongs.isNotEmpty) {
      _logger.i(
        '⏰ Skipping progressive song fetch - using cached data (${state.allSongs.length} songs)',
      );
      return;
    }

    try {
      // Set app settings fetch flag to true
      emit(state.copyWith(appSettingsFetchSong: true));

      // Check if we already have songs in cache (HydratedBloc)
      final hasExistingSongs = state.allSongs.isNotEmpty;

      if (hasExistingSongs) {
        _logger.i(
          '📀 Found ${state.allSongs.length} cached songs - fetching only new songs',
        );

        // Set loading state but keep existing songs visible
        emit(
          state.copyWith(
            isSongListLoading: true,
            isSongListError: false,
            // Keep existing songs - don't clear them
          ),
        );

        // Fetch only new songs (not in existing list)
        final fetchResult = await FetchSongsService.fetchNewSongs(
          state.allSongs,
          supportedFormats: _appSettingsBloc.state.supportedAudioFormats,
          whitelistedFolders: _appSettingsBloc.state.whiteListFolder,
          blockedFolders: _appSettingsBloc.state.blockedFolderList,
        );

        final newSongs = fetchResult['newSongs'] as List<Song>;
        final invalidSongIds = fetchResult['invalidSongIds'] as List<String>;

        // Handle invalid songs cleanup first
        if (invalidSongIds.isNotEmpty) {
          _logger.i('🧹 Cleaning up ${invalidSongIds.length} invalid songs');
          final cleanupResult = SongCleanupService.performEnhancedCleanup(
            allSongs: state.allSongs,
            albums: state.albumList,
            artists: state.artistList,
            playlists: state.myPlaylist,
            playerState: state.myPlayerState,
            invalidSongIds: invalidSongIds,
          );

          // Apply comprehensive cleanup to state
          emit(
            state.copyWith(
              allSongs: cleanupResult['allSongs'] as List<Song>,
              albumList: cleanupResult['albums'] as List<Album>,
              artistList: cleanupResult['artists'] as List<Artist>,
              myPlaylist: cleanupResult['playlists'] as List<MyPlaylist>,
              myPlayerState: cleanupResult['playerState'] as MyPlayerStateModel,
            ),
          );
        }

        if (newSongs.isNotEmpty) {
          _logger.i('🆕 Found ${newSongs.length} new songs to add');

          // Add new songs to existing list
          final updatedSongs = [...state.allSongs, ...newSongs];

          // Validate uniqueness
          final uniqueSongs = SongCleanupService.removeDuplicatesById(
            updatedSongs,
          );

          emit(
            state.copyWith(
              allSongs: uniqueSongs,
              isSongListLoading: false,
              appSettingsFetchSong: false,
            ),
          );

          _logger.i(
            '✅ Added ${uniqueSongs.length - state.allSongs.length} new songs',
          );
        } else {
          _logger.i(
            '✅ No new songs found - keeping existing ${state.allSongs.length} songs',
          );
          emit(
            state.copyWith(
              isSongListLoading: false,
              appSettingsFetchSong: false,
            ),
          );
        }
      } else {
        _logger.i(
          '📀 No cached songs found - performing full progressive scan',
        );

        // No existing songs - do progressive loading for first time
        emit(
          state.copyWith(
            isSongListLoading: true,
            isSongListError: false,
            allSongs: [], // Clear for fresh start
          ),
        );

        // Start progressive loading in background
        await FetchSongsService.fetchAllSongsProgressive(
          supportedFormats: _appSettingsBloc.state.supportedAudioFormats,
          whitelistedFolders: _appSettingsBloc.state.whiteListFolder,
          blockedFolders: _appSettingsBloc.state.blockedFolderList,
          onProgress: (newSongs, isComplete, totalFound) {
            _logger.d(
              '📀 Progress update: ${newSongs.length} new songs, total: $totalFound, complete: $isComplete',
            );

            // Add new songs to existing list
            final updatedSongs = [...state.allSongs, ...newSongs];

            // Validate uniqueness for new batch
            final uniqueSongs = SongCleanupService.removeDuplicatesById(
              updatedSongs,
            );

            emit(
              state.copyWith(
                allSongs: uniqueSongs,
                isSongListLoading: !isComplete,
                songLoadingProgress: totalFound,
                appSettingsFetchSong: !isComplete,
              ),
            );

            // If this is the first batch (10+ songs), hide loading and show songs
            if (uniqueSongs.length >= 10 && state.isSongListLoading) {
              _logger.i(
                '🎵 First batch loaded (${uniqueSongs.length} songs) - showing UI',
              );
            }

            // Update albums and artists when we have a significant number of songs
            if (uniqueSongs.length >= 10 && uniqueSongs.length % 20 == 0) {
              _logger.i(
                '🔄 Updating albums and artists with ${uniqueSongs.length} songs...',
              );
              refreshAlbumsAndArtists();
            }
          },
        );

        _logger.i('✅ Progressive song loading completed');

        // Clean up removed songs from all references
        final removedSongIds = SongCleanupService.findRemovedSongIds(
          state.allSongs,
          state.allSongs,
        );
        final cleanedState = _applySongCleanup(state, removedSongIds);
        if (cleanedState != state) {
          emit(cleanedState);
        }

        // Final refresh of albums and artists after all songs are loaded
        _logger.i(
          '🔄 Final refresh of albums and artists after progressive loading...',
        );
        refreshAlbumsAndArtists();
      }

      // Update last fetch time after successful progressive loading
      _updateLastFetchTime();

      // Always update albums and artists when songs are refreshed
      _logger.i(
        '🔄 Updating albums and artists after progressive song refresh...',
      );
      add(
        const MusicEvent.fetchAndUpdateMetadata(
          includeAlbums: true,
          includeArtists: true,
          isProgressive: true,
        ),
      );

      // Set app settings fetch flag to false after completion
      emit(state.copyWith(appSettingsFetchSong: false));
    } catch (e) {
      _logger.e('❌ Error in progressive song loading: $e');
      emit(
        state.copyWith(
          isSongListLoading: false,
          isSongListError: true,
          appSettingsFetchSong: false,
        ),
      );
    }
  }

  /// Unified metadata update - handles both albums and artists
  Future<void> _onFetchAndUpdateMetadata(
    _FetchAndUpdateMetadata event,
    Emitter<MusicState> emit,
  ) async {
    final includeAlbums = event.includeAlbums ?? true;
    final includeArtists = event.includeArtists ?? true;
    final isProgressive = event.isProgressive ?? false;

    _logger.i(
      '🚀 Starting metadata update - Albums: $includeAlbums, Artists: $includeArtists, Progressive: $isProgressive',
    );

    try {
      if (includeAlbums) {
        await _updateAlbums(emit, isProgressive);
      }

      if (includeArtists) {
        await _updateArtists(emit, isProgressive);
      }

      _logger.i('✅ Metadata update completed');

      // After metadata (albums/artists) is complete, automatically run comprehensive
      // feature extraction in background for pending songs (e.g. after song upload / initial scan).
      if (includeAlbums && includeArtists) {
        _logger.i(
          '🎵 Metadata complete - Triggering comprehensive features extraction (pending songs only)',
        );
        add(const MusicEvent.extractComprehensiveFeatures(isForce: false));
      }
    } catch (e) {
      _logger.e('❌ Error in metadata update: $e');
    }
  }

  /// Update albums from current songs
  Future<void> _updateAlbums(
    Emitter<MusicState> emit,
    bool isProgressive,
  ) async {
    _logger.i(
      '💿 Updating albums from current songs (${state.allSongs.length} songs)',
    );

    try {
      // Extract albums from current songs
      final albums = MusicService.fetchAlbumList(state.allSongs);
      final uniqueAlbums = albums.toSet().toList();

      emit(state.copyWith(albumList: uniqueAlbums));
      _logger.i('✅ Updated albums: ${uniqueAlbums.length} total');

      // Progressive loading only if needed and requested
      if (isProgressive &&
          state.albumList.isEmpty &&
          state.allSongs.length < 50) {
        _logger.i('💿 Performing progressive album extraction');
        await _extractAlbumsProgressive(
          onProgress: (newAlbums, isComplete) {
            final updatedAlbums = [...state.albumList, ...newAlbums];
            final uniqueAlbums = updatedAlbums.toSet().toList();
            emit(state.copyWith(albumList: uniqueAlbums));
          },
        );
      }
    } catch (e) {
      _logger.e('❌ Error updating albums: $e');
    }
  }

  /// Update artists from current songs
  Future<void> _updateArtists(
    Emitter<MusicState> emit,
    bool isProgressive,
  ) async {
    _logger.i(
      '👤 Updating artists from current songs (${state.allSongs.length} songs)',
    );

    try {
      // Extract artists from current songs
      final artists = MusicService.fetchArtistList(state.allSongs);
      final uniqueArtists = artists.toSet().toList();

      emit(state.copyWith(artistList: uniqueArtists));
      _logger.i('✅ Updated artists: ${uniqueArtists.length} total');

      // Progressive loading only if needed and requested
      if (isProgressive &&
          state.artistList.isEmpty &&
          state.allSongs.length < 50) {
        _logger.i('👤 Performing progressive artist extraction');
        await _extractArtistsProgressive(
          onProgress: (newArtists, isComplete) {
            final updatedArtists = [...state.artistList, ...newArtists];
            final uniqueArtists = updatedArtists.toSet().toList();
            emit(state.copyWith(artistList: uniqueArtists));
          },
        );
      }
    } catch (e) {
      _logger.e('❌ Error updating artists: $e');
    }
  }

  Future<void> _onLoadMyPlaylists(
    _LoadMyPlaylists event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('Loading my playlists...');

    try {
      // Check current state and ensure favorites playlist exists
      List<MyPlaylist> currentPlaylists = List.from(state.myPlaylist);

      // If the list is empty, add default favorites playlist
      if (currentPlaylists.isEmpty) {
        _logger.i(
          '📝 Playlist list is empty, adding default favorites playlist',
        );
        final defaultFavorites =
            MyPlaylistService.createDefaultFavoritesPlaylist();
        currentPlaylists.add(defaultFavorites);
      } else {
        // Ensure favorites playlist exists in the current state
        currentPlaylists = MyPlaylistService.ensureFavoritesPlaylist(
          currentPlaylists,
        );
      }

      _logger.i(
        '✅ Loaded ${currentPlaylists.length} playlists (including favorites)',
      );
      emit(state.copyWith(myPlaylist: currentPlaylists));
    } catch (e) {
      _logger.e('Error loading playlists: $e');
      // Don't emit error state for playlists as they're optional
    }
  }

  Future<void> _onAddOrUpdateMyPlayList(
    _AddOrUpdateMyPlayList event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🎵 Playlist operation: ${event.operation}');

    try {
      List<MyPlaylist> updatedPlaylists = List.from(state.myPlaylist);
      MyPlaylist? updatedPlaylist;

      switch (event.operation) {
        case MyPlaylistOperation.create:
          _logger.i('📝 Creating new playlist: ${event.name}');
          updatedPlaylist = MyPlaylistService.createPlaylist(
            name: event.name!,
            description: event.description ?? '',
            songIds: event.songIds ?? [],
            coverImage: event.coverImage,
            isPublic: event.isPublic ?? false,
          );
          updatedPlaylists.insert(0, updatedPlaylist);
          break;

        case MyPlaylistOperation.update:
          _logger.i('📝 Updating playlist: ${event.playlistId}');
          final existingPlaylist = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () =>
                throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.updatePlaylist(
            playlist: existingPlaylist,
            name: event.name,
            description: event.description,
            songIds: event.songIds,
            coverImage: event.coverImage,
            isPublic: event.isPublic,
          );
          final index = updatedPlaylists.indexWhere(
            (p) => p.id == event.playlistId,
          );
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.delete:
          _logger.i('🗑️ Deleting playlist: ${event.playlistId}');
          if (event.playlistId == 'my_playlist_favorites') {
            throw Exception('Cannot delete favorites playlist');
          }
          updatedPlaylists.removeWhere((p) => p.id == event.playlistId);
          break;

        case MyPlaylistOperation.addSong:
          _logger.i(
            '➕ Adding song ${event.songId} to playlist ${event.playlistId}',
          );
          final playlistToUpdate = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () =>
                throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.addSongToPlaylist(
            playlist: playlistToUpdate,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere(
            (p) => p.id == event.playlistId,
          );
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.removeSong:
          _logger.i(
            '➖ Removing song ${event.songId} from playlist ${event.playlistId}',
          );
          final playlistToRemoveFrom = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () =>
                throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.removeSongFromPlaylist(
            playlist: playlistToRemoveFrom,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere(
            (p) => p.id == event.playlistId,
          );
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.toggleFavorite:
          _logger.i('❤️ Toggling song ${event.songId} in favorites');
          final favoritesPlaylist = MyPlaylistService.getFavoritesPlaylist(
            updatedPlaylists,
          );
          if (favoritesPlaylist == null) {
            throw Exception('Favorites playlist not found');
          }
          updatedPlaylist = MyPlaylistService.toggleSongInFavorites(
            favoritesPlaylist: favoritesPlaylist,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere(
            (p) => p.id == 'my_playlist_favorites',
          );
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.updateDuration:
          _logger.i('⏱️ Updating playlist duration: ${event.playlistId}');
          final playlistToUpdateDuration = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () =>
                throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.updatePlaylistDuration(
            playlist: playlistToUpdateDuration,
            allSongs: state.allSongs,
          );
          final index = updatedPlaylists.indexWhere(
            (p) => p.id == event.playlistId,
          );
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;
      }

      emit(state.copyWith(myPlaylist: updatedPlaylists));
      _logger.i('✅ Playlist operation completed successfully');
    } catch (e) {
      _logger.e('❌ Playlist operation failed: $e');
      // Don't emit error state for playlist operations as they're optional
    }
  }

  // ==================== PLAYBACK EVENT HANDLERS ====================
  Future<void> _onPlayOrPauseSong(
    _PlayOrPauseSong event,
    Emitter<MusicState> emit,
  ) async {
    // Prevent race conditions
    if (_isUpdatingState) {
      _logger.w('⚠️ PlayOrPause event ignored - state update in progress');
      return;
    }

    _isUpdatingState = true;

    try {
      _logger.i(
        '🎵 PlayOrPause event: ${event.songId} | Current: ${state.myPlayerState.currentSongId} | Playing: ${state.myPlayerState.isPlaying}',
      );

      // Handle force stop (clear current song and set isPlaying = false)
      if (event.isForceStop == true) {
        _logger.i('🛑 Force stopping music - clearing current song');

        // Stop the audio service to actually stop playback
        await _audioService.stop();

        // Stop sleep timer when force stopping
        SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);

        emit(state.copyWith(myPlayerState: state.myPlayerState.clear()));
        _hideNotification();
        return;
      }

      // Handle empty songId (clear current song and set isPlaying = false)
      if (event.songId == null || event.songId!.isEmpty) {
        _logger.i('🧹 Clearing current song and playlist');

        // Stop the audio service to actually stop playback
        await _audioService.stop();

        // Stop sleep timer when clearing song
        SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);

        emit(state.copyWith(myPlayerState: state.myPlayerState.clear()));
        _hideNotification();
        return;
      }

      // Check if no song is currently selected
      if (state.myPlayerState.currentSongId == null) {
        _logger.i('🎵 No current song - playing new song');
        // No current song - play the new song
        final song = state.allSongs.firstWhere(
          (s) => s.id == event.songId,
          orElse: () => throw Exception('Song not found in allSongs'),
        );

        // Determine source and create appropriate playlist
        final source = event.playlistSource ?? PlaylistSource.allSongs();
        List<Song> playlistSongs;
        String playlistId;

        if (event.playlistSource == null) {
          // No source provided - keep current playlist if it exists, otherwise use allSongs
          if (state.myPlayerState.currentPlayList.isNotEmpty) {
            playlistSongs = currentPlayListSongs;
            playlistId = state.myPlayerState.playlistId ?? 'all_songs';
          } else {
            playlistSongs = state.allSongs;
            playlistId = 'all_songs';
          }
        } else {
          // Source provided - create new playlist
          playlistSongs = _getPlaylistSongs(source);
          playlistId = _getPlaylistId(source);
        }

        // Create new myPlayerState with appropriate playlist
        final newPlayerState =
            MyPlayerStateModel(
                  playlistId: playlistId,
                  currentPlayList: getSongIds(playlistSongs),
                  currentSongId: event.songId,
                  previousSongId: null,
                  completedSongs: [],
                  repeatModeIndex: state.myPlayerState.repeatModeIndex,
                  isShuffle: state.myPlayerState.isShuffle,
                )
                .reorderToStartWith(event.songId!)
                .copyWith(
                  isPlaying: true,
                  lastPosition: null, // Clear position for new song
                );

        _logger.i(
          '🔄 Reordered playlist: ${getSongIds(playlistSongs)} → ${newPlayerState.currentPlayList}',
        );

        // Update state immediately - clear last position for new song
        emit(state.copyWith(myPlayerState: newPlayerState));

        // Reset invalid song attempts counter when starting new song
        _invalidSongAttempts = 0;

        // Sync shuffle/repeat state to notification BEFORE playing
        // This ensures notification shows correct icons from the start
        _audioService.updateShuffleRepeatState(
          isShuffle: newPlayerState.isShuffle,
          isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
          repeatModeIndex: newPlayerState.repeatModeIndex,
        );

        _programmaticChangeCount++;
        _audioService
            .playSong(
              song,
              playlistId: playlistId,
              playlistSource: source,
            )
            .whenComplete(() => _programmaticChangeCount--);

        _showNotificationForCurrentSong();
        SyncAppSettingsHelper.startSleepTimer(
          appSettingsBloc: _appSettingsBloc,
          musicBloc: this,
        );
        _triggerAiShuffleIfEnabled(
          songId: event.songId!,
          playlistSource: event.playlistSource,
          currentPlayList: newPlayerState.currentPlayList,
        );

        return;
      }

      // Check if this is the same song that's currently selected
      if (event.songId == state.myPlayerState.currentSongId) {
        _logger.i('🔄 Same song - toggling play/pause');
        // Same song - toggle play/pause
        if (state.myPlayerState.isPlaying) {
          // Currently playing - pause
          // Save current position before pausing
          final currentPosition = _audioService.position;
          _logger.i(
            '⏸️ Pausing and saving position: ${currentPosition.inSeconds}s',
          );

          emit(
            state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(
                isPlaying: false,
                lastPosition: currentPosition,
              ),
            ),
          );
          _audioService.pause();
          _updateNotificationForCurrentSong();

          // Stop sleep timer when pausing
          SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);
        } else {
          // Currently paused - resume
          emit(
            state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(isPlaying: true),
            ),
          );

          // Resume playback
          _audioService.resume();
          _updateNotificationForCurrentSong();

          // Start sleep timer when resuming playback
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        }
      } else {
        _logger.i('🆕 Different song - playing new song');
        // Different song - play the new song
        final song = state.allSongs.firstWhere(
          (s) => s.id == event.songId,
          orElse: () => throw Exception('Song not found in allSongs'),
        );

        // Determine source and create appropriate playlist
        final source = event.playlistSource ?? PlaylistSource.allSongs();
        List<Song> playlistSongs;
        String playlistId;

        if (event.playlistSource == null) {
          // No source provided - keep current playlist if it exists, otherwise use allSongs
          if (state.myPlayerState.currentPlayList.isNotEmpty) {
            playlistSongs = currentPlayListSongs;
            playlistId = state.myPlayerState.playlistId ?? 'all_songs';
          } else {
            playlistSongs = state.allSongs;
            playlistId = 'all_songs';
          }
        } else {
          // Source provided - create new playlist
          playlistSongs = _getPlaylistSongs(source);
          playlistId = _getPlaylistId(source);
        }

        // Create new myPlayerState with appropriate playlist and reorder to start with tapped song
        final newPlayerState =
            MyPlayerStateModel(
                  playlistId: playlistId,
                  currentPlayList: getSongIds(playlistSongs),
                  currentSongId: event.songId,
                  previousSongId: state.myPlayerState.currentSongId,
                  completedSongs: [],
                  repeatModeIndex: state.myPlayerState.repeatModeIndex,
                  isShuffle: state.myPlayerState.isShuffle,
                )
                .reorderToStartWith(event.songId!)
                .copyWith(
                  isPlaying: true,
                  lastPosition: null, // Clear position for new song
                );

        _logger.i(
          '🔄 Reordered playlist: ${getSongIds(playlistSongs)} → ${newPlayerState.currentPlayList}',
        );

        // Update state immediately - clear last position for new song
        emit(state.copyWith(myPlayerState: newPlayerState));

        // Reset invalid song attempts counter when starting new song
        _invalidSongAttempts = 0;

        _audioService.updateShuffleRepeatState(
          isShuffle: newPlayerState.isShuffle,
          isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
          repeatModeIndex: newPlayerState.repeatModeIndex,
        );

        _programmaticChangeCount++;
        _audioService
            .playSong(
              song,
              playlistId: playlistId,
              playlistSource: source,
            )
            .whenComplete(() => _programmaticChangeCount--);

        _showNotificationForCurrentSong();
        SyncAppSettingsHelper.startSleepTimer(
          appSettingsBloc: _appSettingsBloc,
          musicBloc: this,
        );
        _triggerAiShuffleIfEnabled(
          songId: event.songId!,
          playlistSource: event.playlistSource,
          currentPlayList: newPlayerState.currentPlayList,
        );
      }

      _logger.i(
        '✅ PlayOrPause completed | Song: ${event.songId} | Playing: ${state.myPlayerState.isPlaying}',
      );
    } catch (e) {
      _logger.e('❌ Error in play/pause song: $e | Event: ${event.songId}');
    } finally {
      _isUpdatingState = false;
    }
  }

  Future<void> _onPlayNext(_PlayNext event, Emitter<MusicState> emit) async {
    try {
      _logger.i('Playing next song from queue');

      if (state.myPlayerState.currentPlayList.isNotEmpty) {
        // Use nextSongIgnoringRepeat() - Next button should NOT respect repeat mode
        final updatedQueue = state.myPlayerState.nextSongIgnoringRepeat();

        if (updatedQueue.currentSongId != null &&
            updatedQueue.currentSongId != state.myPlayerState.currentSongId) {
          final nextSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );
          _logger.i('🎵 Playing next song in queue: "${nextSong.title}"');
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state immediately with new queue
          emit(
            state.copyWith(
              myPlayerState: updatedQueue.copyWith(isPlaying: true),
            ),
          );

          // Sync shuffle/repeat state to notification BEFORE playing
          // This ensures notification shows correct icons from the start
          _audioService.updateShuffleRepeatState(
            isShuffle: updatedQueue.isShuffle,
            isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
            repeatModeIndex: updatedQueue.repeatModeIndex,
          );

          _programmaticChangeCount++;
          try {
            await _audioService.playSong(
              nextSong,
              playlistId: state.myPlayerState.playlistId,
              playlistSource: _getPlaylistSourceFromId(
                state.myPlayerState.playlistId,
              ),
            );
          } finally {
            _programmaticChangeCount--;
          }

          _updateNotificationForCurrentSong();
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        } else {
          _logger.w(
            '⚠️ Next button: No next song available (playlist has only one song or is empty)',
          );
        }
      } else {
        _logger.w('⚠️ No songs in queue');
      }
    } catch (e) {
      _logger.e('Error playing next song: $e');
    }
  }

  Future<void> _onPlayPrevious(
    _PlayPrevious event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i('Playing previous song from completed songs');

      if (state.myPlayerState.completedSongs.isNotEmpty) {
        final updatedQueue = state.myPlayerState.previousSong();

        if (updatedQueue.currentSongId != null &&
            updatedQueue.currentSongId != state.myPlayerState.currentSongId) {
          final previousSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );
          _logger.i(
            '🎵 Playing previous song from completed: "${previousSong.title}"',
          );
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state immediately with new queue
          emit(
            state.copyWith(
              myPlayerState: updatedQueue.copyWith(isPlaying: true),
            ),
          );

          // Sync shuffle/repeat state to notification BEFORE playing
          // This ensures notification shows correct icons from the start
          _audioService.updateShuffleRepeatState(
            isShuffle: updatedQueue.isShuffle,
            isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
            repeatModeIndex: updatedQueue.repeatModeIndex,
          );

          _programmaticChangeCount++;
          try {
            await _audioService.playSong(
              previousSong,
              playlistId: state.myPlayerState.playlistId,
              playlistSource: _getPlaylistSourceFromId(
                state.myPlayerState.playlistId,
              ),
            );
          } finally {
            _programmaticChangeCount--;
          }

          _updateNotificationForCurrentSong();
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        } else {
          _logger.w('⚠️ No previous song available or same song');
        }
      } else {
        _logger.i(
          '🔄 No completed songs to go back to - seeking current song to beginning',
        );

        await _audioService.seekTo(Duration.zero);

        // Ensure the song is playing
        if (!state.myPlayerState.isPlaying) {
          await _audioService.resume();

          // Update state to reflect playing status
          emit(
            state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(isPlaying: true),
            ),
          );

          // Update notification
          _updateNotificationForCurrentSong();

          // Start sleep timer
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        }
      }
    } catch (e) {
      _logger.e('Error playing previous song: $e');
    }
  }

  // ==================== AI SHUFFLE HELPER METHODS ====================

  /// Trigger AI Shuffle only when starting to play a song (not when pausing)
  void _triggerAiShuffleIfEnabled({
    required String songId,
    required PlaylistSource? playlistSource,
    required List<String> currentPlayList,
  }) {
    try {
      // Check AI Shuffle setting and trigger if enabled
      final appSettings = _appSettingsBloc.state;
      if (appSettings.isAiShuffleEnabled) {
        _logger.d(
          '🎵 AI Shuffle enabled - triggering intelligent reordering for song: $songId',
        );

        add(
          MusicEvent.aiShuffle(
            currentSongId: songId,
            currentPlayList: currentPlayList,
            playlistSource: playlistSource,
          ),
        );
      } else {
        _logger.d(
          '🎵 AI Shuffle disabled - maintaining original playlist order',
        );
      }
    } catch (e) {
      _logger.e('❌ Error triggering AI Shuffle: $e');
    }
  }

  // ==================== PLAYBACK SETTINGS EVENT HANDLERS ====================
  Future<void> _onToggleShuffle(
    _ToggleShuffle event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🔄 Toggle shuffle → ${event.isShuffle} | Auto-start: ${event.isAutoStart ?? false}',
    );

    // Check AI shuffle state and implement mutual exclusivity
    final appSettings = _appSettingsBloc.state;
    if (event.isShuffle && appSettings.isAiShuffleEnabled) {
      _logger.i(
        '🤖 AI Shuffle is enabled - disabling AI Shuffle to enable regular shuffle',
      );
      // Disable AI shuffle when enabling regular shuffle
      _appSettingsBloc.add(AppSettingsEvent.updateAiShuffle(isEnabled: false));
    }

    // Shuffle setting is handled by MusicBloc state management

    if (event.isShuffle) {
      // Shuffle current playlist
      _logger.i('🔀 Shuffling current playlist...');
      final shuffledQueue = state.myPlayerState.shufflePlaylist();

      emit(
        state.copyWith(myPlayerState: shuffledQueue.copyWith(isShuffle: true)),
      );

      // Update notification shuffle state (disable AI shuffle when enabling normal shuffle)
      _audioService.updateShuffleRepeatState(
        isShuffle: true,
        isAiShuffle: false,
      );

      // Track regular shuffle usage
      _appSettingsBloc.add(
        AppSettingsEvent.trackShuffleUsage(shuffleType: 'regular_shuffle'),
      );

      _logger.i(
        '✅ Shuffle enabled | Queue: ${shuffledQueue.remainingSongs} songs',
      );

      // Auto-start if requested and there's a current song
      if (event.isAutoStart == true && shuffledQueue.currentSongId != null) {
        _logger.i('🎵 Auto-starting shuffled playlist...');

        // Use playOrPauseSong event for auto-start
        add(
          MusicEvent.playOrPauseSong(
            songId: shuffledQueue.currentSongId!,
            currentPlayList: event.currentPlayList,
            playlistSource: event.playlistSource,
          ),
        );

        _logger.i(
          '🎵 Auto-start event dispatched for: ${shuffledQueue.currentSongId}',
        );
      }
    } else {
      // Revert shuffle - restore original order based on playlistId
      _logger.i('🔄 Reverting shuffle to original order...');

      List<String> originalOrder;
      final playlistId = state.myPlayerState.playlistId;

      if (playlistId == null || playlistId == 'all_songs') {
        originalOrder = getSongIds(state.allSongs);
        _logger.i('📋 Reverting to all songs order');
      } else if (playlistId.startsWith('album_')) {
        final albumId = playlistId.substring(6); // Remove 'album_' prefix
        final album = state.albumList.firstWhere(
          (album) => album.id == albumId,
          orElse: () => throw Exception('Album not found: $albumId'),
        );
        originalOrder = album.songIds;
        _logger.i('📋 Reverting to album "${album.name}" order');
      } else if (playlistId.startsWith('artist_')) {
        final artistId = playlistId.substring(7); // Remove 'artist_' prefix
        final artist = state.artistList.firstWhere(
          (artist) => artist.id == artistId,
          orElse: () => throw Exception('Artist not found: $artistId'),
        );
        originalOrder = artist.songIds;
        _logger.i('📋 Reverting to artist "${artist.name}" order');
      } else if (playlistId.startsWith('my_playlist_')) {
        final myPlaylistId = playlistId.substring(
          12,
        ); // Remove 'my_playlist_' prefix
        final myPlaylist = state.myPlaylist.firstWhere(
          (playlist) => playlist.id == myPlaylistId,
          orElse: () => throw Exception('MyPlaylist not found: $myPlaylistId'),
        );
        originalOrder = myPlaylist.songIds;
        _logger.i('📋 Reverting to my playlist "${myPlaylist.name}" order');
      } else {
        originalOrder = getSongIds(state.allSongs);
        _logger.i('📋 Reverting to all songs order (unknown playlist)');
      }

      // Apply filter if keyword exists
      if (state.myPlayerState.filterKeyword.isNotEmpty) {
        // Get the actual song list based on playlist type
        List<Song> actualSongList;
        if (playlistId == null || playlistId == 'all_songs') {
          actualSongList = state.allSongs;
        } else if (playlistId.startsWith('album_')) {
          final albumId = playlistId.substring(6);
          final album = state.albumList.firstWhere(
            (album) => album.id == albumId,
            orElse: () => throw Exception('Album not found: $albumId'),
          );
          actualSongList = getSongsFromIds(album.songIds);
        } else if (playlistId.startsWith('artist_')) {
          final artistId = playlistId.substring(7);
          final artist = state.artistList.firstWhere(
            (artist) => artist.id == artistId,
            orElse: () => throw Exception('Artist not found: $artistId'),
          );
          actualSongList = getSongsFromIds(artist.songIds);
        } else if (playlistId.startsWith('my_playlist_')) {
          final myPlaylistId = playlistId.substring(12);
          final myPlaylist = state.myPlaylist.firstWhere(
            (playlist) => playlist.id == myPlaylistId,
            orElse: () =>
                throw Exception('MyPlaylist not found: $myPlaylistId'),
          );
          actualSongList = getSongsFromIds(myPlaylist.songIds);
        } else {
          actualSongList = state.allSongs;
        }

        originalOrder = state.myPlayerState.getFilteredSongIds(
          originalOrder,
          actualSongList,
        );
        _logger.i(
          '🔍 Applied filter "${state.myPlayerState.filterKeyword}" to reverted order using ${actualSongList.length} songs',
        );
      }

      final revertedQueue = state.myPlayerState.revertShuffle(originalOrder);

      emit(
        state.copyWith(myPlayerState: revertedQueue.copyWith(isShuffle: false)),
      );

      // Update notification shuffle state
      _audioService.updateShuffleRepeatState(
        isShuffle: false,
        isAiShuffle: false,
      );

      _logger.i(
        '✅ Shuffle disabled | Queue: ${revertedQueue.remainingSongs} songs',
      );
    }
  }

  Future<void> _onToggleRepeat(
    _ToggleRepeat event,
    Emitter<MusicState> emit,
  ) async {
    // Cycle through repeat modes: 0 -> 1 -> 2 -> 0
    final updatedQueue = state.myPlayerState.cycleRepeatMode();
    final newRepeatModeIndex = updatedQueue.repeatModeIndex;

    _logger.i(
      '🔄 Toggle repeat → ${updatedQueue.repeatModeDescription} (Index: $newRepeatModeIndex)',
    );

    // Update myPlayerState with new repeat mode
    emit(state.copyWith(myPlayerState: updatedQueue));

    // Update notification repeat state
    _audioService.updateShuffleRepeatState(repeatModeIndex: newRepeatModeIndex);
  }

  // ==================== SORTING AND SEEKING EVENT HANDLERS ====================
  Future<void> _onChangeSortingOrder(
    _ChangeSortingOrder event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🔄 Change sorting order → Index: ${event.sortingIndex} | Source: ${event.playlistSource?.source ?? Sources.allSongs}',
    );

    emit(state.copyWith(sortingIndex: event.sortingIndex));

    // Apply sorting based on source
    final source = event.playlistSource?.source ?? Sources.allSongs;

    switch (source) {
      case Sources.allSongs:
        // Apply sorting to all songs
        final sortedSongs = _applySorting(
          event.sortingList
              .map(
                (songId) => state.allSongs.firstWhere(
                  (song) => song.id == songId,
                  orElse: () => throw Exception('Song not found: $songId'),
                ),
              )
              .toList(),
          event.sortingIndex,
        );
        emit(state.copyWith(allSongs: sortedSongs));
        _logger.i('✅ All songs sorted with index ${event.sortingIndex}');
        break;

      case Sources.album:
        // Apply sorting to album songs
        if (event.playlistSource?.albumId != null) {
          final albumSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedAlbumSongs = _applySorting(
            albumSongs,
            event.sortingIndex,
          );
          // Update album list with sorted songs
          final updatedAlbumList = state.albumList.map((album) {
            if (album.id == event.playlistSource!.albumId) {
              return album.copyWith(
                songIds: sortedAlbumSongs.map((s) => s.id).toList(),
              );
            }
            return album;
          }).toList();
          emit(state.copyWith(albumList: updatedAlbumList));
          _logger.i(
            '✅ Album "${event.playlistSource!.albumId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      case Sources.artist:
        // Apply sorting to artist songs
        if (event.playlistSource?.artistId != null) {
          final artistSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedArtistSongs = _applySorting(
            artistSongs,
            event.sortingIndex,
          );
          // Update artist list with sorted songs
          final updatedArtistList = state.artistList.map((artist) {
            if (artist.id == event.playlistSource!.artistId) {
              return artist.copyWith(
                songIds: sortedArtistSongs.map((s) => s.id).toList(),
              );
            }
            return artist;
          }).toList();
          emit(state.copyWith(artistList: updatedArtistList));
          _logger.i(
            '✅ Artist "${event.playlistSource!.artistId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      case Sources.myPlaylist:
        // Apply sorting to playlist songs
        if (event.playlistSource?.playlistId != null) {
          final playlistSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedPlaylistSongs = _applySorting(
            playlistSongs,
            event.sortingIndex,
          );
          // Update playlist with sorted songs
          final updatedPlaylist = state.myPlaylist.map((playlist) {
            if (playlist.id == event.playlistSource!.playlistId) {
              return playlist.copyWith(
                songIds: sortedPlaylistSongs.map((s) => s.id).toList(),
              );
            }
            return playlist;
          }).toList();
          emit(state.copyWith(myPlaylist: updatedPlaylist));
          _logger.i(
            '✅ Playlist "${event.playlistSource!.playlistId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      default:
        _logger.w('⚠️ Unknown sorting source: $source');
        break;
    }
  }

  Future<void> _onSeekToPosition(
    _SeekToPosition event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i(
        '🔍 Seek event triggered | Position: ${event.position.inSeconds}s (${event.position.inMilliseconds}ms)',
      );

      await _audioService.seekTo(event.position);
      _logger.i(
        '✅ Seek event completed successfully | Position: ${event.position.inSeconds}s',
      );
    } catch (e) {
      _logger.e(
        '❌ Error seeking to position ${event.position.inSeconds}s: $e | Current state: currentSongId=${state.myPlayerState.currentSongId}',
      );
    }
  }

  Future<void> _onUpdateLastPosition(
    _UpdateLastPosition event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i(
        '💾 Updating last position: ${event.position.inSeconds}s | Song: ${state.myPlayerState.currentSongId}',
      );

      emit(
        state.copyWith(
          myPlayerState: state.myPlayerState.copyWith(
            lastPosition: event.position,
          ),
        ),
      );

      _logger.i('✅ Last position updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating last position: $e');
    }
  }

  // ==================== STATE UPDATE EVENT HANDLERS ====================
  Future<void> _onUpdateMusicBlocState(
    _UpdateMusicBlocState event,
    Emitter<MusicState> emit,
  ) async {
    emit(event.newState);
  }

  // ==================== AI SHUFFLE EVENT HANDLER ====================
  Future<void> _onAiShuffle(_AiShuffle event, Emitter<MusicState> emit) async {
    try {
      _logger.i('🎵 AI Shuffle triggered for song: ${event.currentSongId}');

      // Get current state
      final currentState = state;

      // Reorder playlist using AI shuffle
      final reorderedPlaylist = AiShuffleService.reorderPlaylistBySimilarity(
        currentSongId: event.currentSongId,
        playlistSongIds: event.currentPlayList,
        allSongs: currentState.allSongs,
      );

      _logger.d(
        '🎯 Original playlist: ${event.currentPlayList.take(5).join(', ')}...',
      );
      _logger.d(
        '🎯 Reordered playlist: ${reorderedPlaylist.take(5).join(', ')}...',
      );

      // Update player state with reordered playlist
      final updatedPlayerState = currentState.myPlayerState.aiShufflePlaylist(
        reorderedPlaylist,
      );

      // Emit new state
      emit(currentState.copyWith(myPlayerState: updatedPlayerState));

      // Update notification with AI shuffle state
      _audioService.updateShuffleRepeatState(
        isShuffle: false,
        isAiShuffle: true,
      );

      _logger.i(
        '✅ AI Shuffle completed: ${reorderedPlaylist.length} songs reordered',
      );
    } catch (e, stackTrace) {
      _logger.e('❌ AI Shuffle failed: $e');
      _logger.e('Stack trace: $stackTrace');
      // Don't fail silently - maintain current playlist
    }
  }

  /// Mark initialization as complete to allow position updates
  void markInitializationComplete() {
    _isInitializing = false;
    _logger.i(
      '✅ App initialization marked as complete - position tracking enabled',
    );
  }

  // ==================== AUDIO SERVICE CALLBACKS ====================
  /// Handle position changes from audio service
  void _onPositionChanged(Duration position) {
    // Don't update position during app initialization to prevent overriding restored position
    if (_isInitializing) {
      _logger.d(
        '🔍 Position change ignored during initialization: ${position.inSeconds}s',
      );
      return;
    }

    // Only update position if we're not currently updating state to prevent race conditions
    if (!_isUpdatingState && state.myPlayerState.currentSongId != null) {
      // Update position every 5 seconds to avoid too frequent updates
      // But only if the position has actually changed significantly
      final currentSavedPosition = state.myPlayerState.lastPosition;
      if (currentSavedPosition == null ||
          (position.inSeconds - currentSavedPosition.inSeconds).abs() >= 5) {
        if (position.inSeconds % 5 == 0) {
          add(MusicEvent.updateLastPosition(position: position));
        }
      }
    }
  }

  /// Handle when audio service changes songs automatically
  void _onAudioServiceSongChanged(Song newSong) {
    _logger.i(
      '🎵 Audio service song changed: "${newSong.title}" | Queueing for processing',
    );

    // Reset invalid song attempts counter on successful song change
    _invalidSongAttempts = 0;

    // Add to queue instead of ignoring
    _pendingSongChanges.add(newSong);

    // Process queue if not already processing
    if (!_isProcessingSongChanges) {
      _processSongChangeQueue();
    }
  }

  /// Process queued song changes to prevent race conditions
  Future<void> _processSongChangeQueue() async {
    if (_isProcessingSongChanges || _pendingSongChanges.isEmpty) return;

    _isProcessingSongChanges = true;

    while (_pendingSongChanges.isNotEmpty) {
      final newSong = _pendingSongChanges.removeAt(0);

      // Wait for any ongoing state updates to complete
      while (_isUpdatingState) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await _processSongChange(newSong);
    }

    _isProcessingSongChanges = false;
  }

  /// Process individual song change
  Future<void> _processSongChange(Song newSong) async {
    _logger.i('🔄 Processing song change: "${newSong.title}"');

    // Check if this is a different song (skip scenario)
    if (state.myPlayerState.currentSongId != null &&
        state.myPlayerState.currentSongId != newSong.id) {
      _logger.i('🔄 Song skipped - moving previous song to completed');

      // Move current song to completed and set new song as current
      final updatedQueue = state.myPlayerState.moveCurrentToCompleted();
      final finalQueue = updatedQueue.copyWith(
        currentSongId: newSong.id,
        previousSongId: state.myPlayerState.currentSongId,
        isPlaying: true,
      );

      _logger.i(
        '✅ Completed songs: ${state.myPlayerState.completedCount} → ${finalQueue.completedCount} songs',
      );

      add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(myPlayerState: finalQueue),
        ),
      );
    } else {
      // Same song or no previous song - just update current song and previousSongId
      add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(
            myPlayerState: state.myPlayerState.copyWith(
              currentSongId: newSong.id,
              previousSongId:
                  state.myPlayerState.currentSongId, // Update previousSongId
              currentPlayList: state.myPlayerState.currentPlayList,
              isPlaying: true,
            ),
          ),
        ),
      );
    }

    // Update notification with new song
    _updateNotificationForCurrentSong();

    _logger.i(
      '✅ Bloc state updated for new song: "${newSong.title}" | currentSongId: ${newSong.id}',
    );
  }

  /// Handle when a song is invalid (file not found, corrupted, etc.)
  void _onInvalidSong(
    Song invalidSong,
    String? playlistId,
    PlaylistSource? playlistSource,
  ) {
    if (_programmaticChangeCount > 0) {
      return;
    }

    _invalidSongAttempts++;

    _logger.w(
      '🚫 Invalid song detected: "${invalidSong.title}" - attempt $_invalidSongAttempts/$maxInvalidSongAttempts',
    );

    _clearPendingSongChanges();
    _refreshLibraryToRemoveInvalidSongs();
    _tryPlayNextSong();
  }

  /// Try to play next song, if not available try previous song
  /// This is a fallback for invalid songs - should ignore repeat mode
  void _tryPlayNextSong() {
    try {
      if (state.myPlayerState.currentPlayList.isNotEmpty) {
        // Use nextSongIgnoringRepeat() - fallback should move to next song regardless of repeat mode
        final updatedQueue = state.myPlayerState.nextSongIgnoringRepeat();

        if (updatedQueue.currentSongId != null) {
          // Found next song - play it
          final nextSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );

          _logger.i('🔄 Playing next song: "${nextSong.title}"');

          // Update state and play
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: updatedQueue.copyWith(isPlaying: true),
              ),
            ),
          );

          // Sync shuffle/repeat state to notification BEFORE playing
          // This ensures notification shows correct icons from the start
          _audioService.updateShuffleRepeatState(
            isShuffle: updatedQueue.isShuffle,
            isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
            repeatModeIndex: updatedQueue.repeatModeIndex,
          );

          _audioService.playSong(
            nextSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(
              state.myPlayerState.playlistId,
            ),
          );

          _updateNotificationForCurrentSong();
          return;
        }
      }

      // No next song available - try previous song
      _tryPlayPreviousSong();
    } catch (e) {
      _logger.e('❌ Error playing next song: $e');
      _tryPlayPreviousSong();
    }
  }

  /// Try to play previous song
  void _tryPlayPreviousSong() {
    try {
      if (state.myPlayerState.completedSongs.isNotEmpty) {
        final updatedQueue = state.myPlayerState.previousSong();

        if (updatedQueue.currentSongId != null) {
          // Found previous song - play it
          final previousSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );

          _logger.i('🔄 Playing previous song: "${previousSong.title}"');

          // Update state and play
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: updatedQueue.copyWith(isPlaying: true),
              ),
            ),
          );

          // Sync shuffle/repeat state to notification BEFORE playing
          // This ensures notification shows correct icons from the start
          _audioService.updateShuffleRepeatState(
            isShuffle: updatedQueue.isShuffle,
            isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
            repeatModeIndex: updatedQueue.repeatModeIndex,
          );

          _audioService.playSong(
            previousSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(
              state.myPlayerState.playlistId,
            ),
          );

          _updateNotificationForCurrentSong();
          return;
        }
      }

      _refreshLibraryToRemoveInvalidSongs();
    } catch (e) {
      _logger.e('❌ Error playing previous song: $e');
      _refreshLibraryToRemoveInvalidSongs();
    }
  }

  /// Refresh library to remove invalid songs
  void _refreshLibraryToRemoveInvalidSongs() {
    _logger.i('🔄 Refreshing library to remove invalid songs');
    add(const MusicEvent.fetchAndUpdateSongs(isForce: true));
  }

  /// Clear pending song changes queue
  void _clearPendingSongChanges() {
    _pendingSongChanges.clear();
    _isProcessingSongChanges = false;
    // Cleared pending song changes queue
  }

  // ==================== REMOTE CONTROL METHODS ====================
  /// Handle remote control actions from external devices
  void _handleRemoteControlAction(RemoteControlAction action) {
    _logger.i('🎧 Remote control action received: ${action.description}');

    if (state.myPlayerState.currentSongId == null ||
        state.myPlayerState.currentPlayList.isEmpty) {
      _logger.w('⚠️ Remote control action ignored - no current song');
      return;
    }

    switch (action) {
      case RemoteControlAction.play:
        if (!state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId!,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
        break;
      case RemoteControlAction.pause:
        if (state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId!,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
        break;
      case RemoteControlAction.togglePlayPause:
        add(
          MusicEvent.playOrPauseSong(
            songId: state.myPlayerState.currentSongId!,
            currentPlayList: state.myPlayerState.currentPlayList,
          ),
        );
        break;
      case RemoteControlAction.next:
        add(const MusicEvent.playNext());
        break;
      case RemoteControlAction.previous:
        add(const MusicEvent.playPrevious());
        break;
      case RemoteControlAction.stop:
        // Stop playback and clear current song
        add(MusicEvent.playOrPauseSong(songId: '', currentPlayList: []));
        break;
      case RemoteControlAction.seekForward:
        // Seek forward 10 seconds
        final newPosition =
            _audioService.position + const Duration(seconds: 10);
        final duration = _audioService.duration;
        if (duration > Duration.zero && newPosition < duration) {
          add(MusicEvent.seekToPosition(position: newPosition));
        }
        break;
      case RemoteControlAction.seekBackward:
        // Seek backward 10 seconds
        final newPosition =
            _audioService.position - const Duration(seconds: 10);
        if (newPosition > Duration.zero) {
          add(MusicEvent.seekToPosition(position: newPosition));
        }
        break;
    }
  }

  // ==================== NOTIFICATION METHODS ====================
  /// Update notification for current song
  void _updateNotificationForCurrentSong() {
    if (state.myPlayerState.currentSongId != null) {
      try {
        final currentSong = state.allSongs.firstWhere(
          (song) => song.id == state.myPlayerState.currentSongId,
        );

        // Notification is automatically managed by audio_service
        _logger.i('📱 Notification updated for: "${currentSong.title}"');
      } catch (e) {
        _logger.e('❌ Error updating notification: $e');
      }
    }
  }

  /// Show notification when music starts
  void _showNotificationForCurrentSong() {
    if (state.myPlayerState.currentSongId != null) {
      try {
        final currentSong = state.allSongs.firstWhere(
          (song) => song.id == state.myPlayerState.currentSongId,
        );

        // Notification is automatically managed by audio_service
        _logger.i('📱 Notification shown for: "${currentSong.title}"');
      } catch (e) {
        _logger.e('❌ Error showing notification: $e');
      }
    }
  }

  /// Hide notification when music stops
  void _hideNotification() {
    try {
      // Notification is automatically managed by audio_service
      _logger.i('📱 Notification hidden');
    } catch (e) {
      _logger.e('❌ Error hiding notification: $e');
    }
  }

  // ==================== SONG COMPLETION HANDLING ====================
  /// Handle when a song completes - move it to completed songs and play next
  Future<void> _handleSongCompletion() async {
    _logger.i('🎯 Song completed - checking autoPlayNext setting');

    if (state.myPlayerState.currentSongId != null &&
        state.myPlayerState.currentPlayList.isNotEmpty) {
      // Check autoPlayNext setting from AppSettingsBloc
      final appSettingsState = _appSettingsBloc.state;
      final autoPlayNext = appSettingsState.autoPlayNext;

      _logger.i('⚙️ AutoPlayNext setting: $autoPlayNext');

      if (autoPlayNext) {
        // AutoPlayNext is enabled - continue with normal flow
        _logger.i(
          '✅ AutoPlayNext enabled - moving to completed songs and playing next',
        );

        // Try to get next song (handles repeat/loop logic)
        final updatedQueue = state.myPlayerState.nextSong();

        if (updatedQueue.currentSongId != null) {
          // There's a next song to play
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state with new queue and play next song
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: updatedQueue.copyWith(isPlaying: true),
              ),
            ),
          );

          // Play the next song
          final nextSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );

          // Sync shuffle/repeat state to notification BEFORE playing
          // This ensures notification shows correct icons from the start
          _audioService.updateShuffleRepeatState(
            isShuffle: updatedQueue.isShuffle,
            isAiShuffle: _appSettingsBloc.state.isAiShuffleEnabled,
            repeatModeIndex: updatedQueue.repeatModeIndex,
          );

          await _audioService.playSong(
            nextSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(
              state.myPlayerState.playlistId,
            ),
          );

          _updateNotificationForCurrentSong();
        } else {
          // No next song - just move current to completed
          final completedQueue = state.myPlayerState.moveCurrentToCompleted();

          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${completedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${completedQueue.completedCount} songs',
          );

          // Update state with completed queue
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: completedQueue.copyWith(isPlaying: false),
              ),
            ),
          );

          // Hide notification when queue is empty
          if (completedQueue.currentPlayList.isEmpty) {
            _hideNotification();
          }
        }
      } else {
        // AutoPlayNext is disabled - just pause and move to completed
        _logger.i(
          '⏸️ AutoPlayNext disabled - pausing playback and moving to completed',
        );

        // Move current song to completed
        final completedQueue = state.myPlayerState.moveCurrentToCompleted();

        _logger.i(
          '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${completedQueue.remainingSongs} songs',
        );
        _logger.i(
          '✅ Completed songs: ${state.myPlayerState.completedCount} → ${completedQueue.completedCount} songs',
        );

        // Update state with completed queue and pause
        add(
          MusicEvent.updateMusicBlocState(
            newState: state.copyWith(
              myPlayerState: completedQueue.copyWith(isPlaying: false),
            ),
          ),
        );

        // Reset position to beginning and pause the audio service
        await _audioService.seekTo(Duration.zero);
        await _audioService.pause();

        _logger.i('🔄 Song position reset to beginning for next play');

        // Hide notification when queue is empty
        if (completedQueue.currentPlayList.isEmpty) {
          _hideNotification();
        }
      }
    }
  }

  // ==================== PLAYBACK SPEED CONTROL ====================

  /// Public method to sync playback speed (can be called from outside)
  void syncPlaybackSpeed() {
    SyncAppSettingsHelper.syncPlaybackSpeed(
      appSettingsBloc: _appSettingsBloc,
      audioService: _audioService,
    );
  }

  // ==================== SLEEP TIMER PUBLIC METHODS ====================
  /// Check if sleep timer is currently running
  bool get isSleepTimerRunning => _sleepTimer != null;

  /// Get remaining sleep timer duration (for debugging/logging)
  Duration? getSleepTimerRemainingDuration() {
    if (_sleepTimer == null) return null;
    // Note: Dart Timer doesn't provide remaining time, so we return null
    // This is just for future enhancement if needed
    return null;
  }

  // ==================== SLEEP TIMER INTERNAL METHODS ====================
  /// Internal method to start sleep timer (used by helper)
  void startSleepTimerInternal(Duration timerDuration) {
    try {
      // Cancel any existing timer first
      _sleepTimer?.cancel();
      _sleepTimer = null;

      // Start new timer
      _sleepTimer = Timer(timerDuration, () {
        _handleSleepTimerExpiredInternal();
      });
    } catch (e) {
      _logger.e('❌ Error starting sleep timer internally: $e');
    }
  }

  /// Internal method to stop sleep timer (used by helper)
  void stopSleepTimerInternal() {
    try {
      if (_sleepTimer != null) {
        _sleepTimer?.cancel();
        _sleepTimer = null;
        _logger.i('💤 Sleep timer stopped and cleared');
      } else {
        // No sleep timer running to stop
      }
    } catch (e) {
      _logger.e('❌ Error stopping sleep timer internally: $e');
    }
  }

  /// Internal method to handle sleep timer expiration (used by helper)
  void _handleSleepTimerExpiredInternal() {
    try {
      _logger.i('💤 Sleep timer expired - pausing playback');

      // Pause the audio service
      _audioService.pause();

      // Update state to reflect paused state
      add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(
            myPlayerState: state.myPlayerState.copyWith(isPlaying: false),
          ),
        ),
      );

      // Hide notification
      _hideNotification();

      _logger.i('✅ Sleep timer completed - playback paused');
    } catch (e) {
      _logger.e('❌ Error handling sleep timer expiration internally: $e');
    }
  }

  // ==================== REFRESH METHODS ====================

  /// Force refresh albums and artists from current songs
  /// This ensures albums and artists are always in sync with songs
  void refreshAlbumsAndArtists() {
    _logger.i('🔄 Force refreshing albums and artists from current songs...');

    if (state.allSongs.isNotEmpty) {
      // Use the new unified metadata update event
      add(
        const MusicEvent.fetchAndUpdateMetadata(
          includeAlbums: true,
          includeArtists: true,
          isProgressive: false,
        ),
      );
    } else {
      _logger.w('⚠️ No songs available to refresh albums and artists');
    }
  }

  // ==================== SONG CLEANUP METHODS ====================

  /// Apply song cleanup to the current state
  MusicState _applySongCleanup(
    MusicState currentState,
    List<String> removedSongIds,
  ) {
    if (removedSongIds.isEmpty) {
      return currentState;
    }

    _logger.i('🧹 Applying cleanup for ${removedSongIds.length} removed songs');

    // Clean up current player state
    final cleanedPlayerState = SongCleanupService.cleanupPlayerState(
      currentState.myPlayerState,
      removedSongIds,
    );

    // Clean up albums
    final cleanedAlbums = SongCleanupService.cleanupAlbums(
      currentState.albumList,
      removedSongIds,
    );

    // Clean up artists
    final cleanedArtists = SongCleanupService.cleanupArtists(
      currentState.artistList,
      removedSongIds,
    );

    // Clean up my playlists
    final cleanedPlaylists = SongCleanupService.cleanupMyPlaylists(
      currentState.myPlaylist,
      removedSongIds,
    );

    return currentState.copyWith(
      myPlayerState: cleanedPlayerState,
      albumList: cleanedAlbums,
      artistList: cleanedArtists,
      myPlaylist: cleanedPlaylists,
    );
  }

  // ==================== UTILITY METHODS ====================
  List<Song> _applySorting(List<Song> songs, int sortingIndex) {
    // Use centralized SortingHelper instead of duplicate logic
    return SortingHelper.applySorting(songs, sortingIndex);
  }

  // ==================== HELPER METHODS ====================
  /// Get current song from state using allSongs
  Song? get currentSong {
    if (state.myPlayerState.currentSongId == null) {
      return null;
    }

    try {
      return state.allSongs.firstWhere(
        (song) => song.id == state.myPlayerState.currentSongId,
      );
    } catch (e) {
      _logger.e('Error finding current song: $e');
      return null;
    }
  }

  /// Get songs from currentPlayList (song IDs) using allSongs
  List<Song> get currentPlayListSongs {
    return state.myPlayerState.currentPlayList
        .map(
          (songId) => state.allSongs.firstWhere(
            (song) => song.id == songId,
            orElse: () => throw Exception('Song not found: $songId'),
          ),
        )
        .toList();
  }

  /// Get playlist ID based on PlaylistSource
  String _getPlaylistId(PlaylistSource playlistSource) {
    return PlaylistSourceHelper.getPlaylistId(playlistSource);
  }

  /// Get playlist songs based on PlaylistSource
  List<Song> _getPlaylistSongs(PlaylistSource playlistSource) {
    return PlaylistSourceHelper.getPlaylistSongs(playlistSource, state);
  }

  /// Get song IDs from a list of songs
  List<String> getSongIds(List<Song> songs) {
    return PlaylistSourceHelper.getSongIds(songs);
  }

  /// Get songs from song IDs using allSongs
  List<Song> getSongsFromIds(List<String> songIds) {
    return PlaylistSourceHelper.getSongsFromIds(songIds, state.allSongs);
  }

  /// Get PlaylistSource from playlist ID
  PlaylistSource? _getPlaylistSourceFromId(String? playlistId) {
    return PlaylistSourceHelper.getPlaylistSourceFromId(playlistId);
  }

  // ==================== FILTER EVENT HANDLERS ====================
  Future<void> _onUpdateFilterKeyword(
    _UpdateFilterKeyword event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🔍 Updating filter keyword: "${event.filterKeyword}"');

    emit(
      state.copyWith(
        myPlayerState: state.myPlayerState.copyWith(
          filterKeyword: event.filterKeyword,
        ),
      ),
    );

    _logger.i('✅ Filter keyword updated');
  }

  Future<void> _onSetNavigationFilter(
    _SetNavigationFilter event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🧭 Setting navigation filter: type="${event.filterType}", value="${event.filterValue}"',
    );

    emit(
      state.copyWith(
        navigationFilterType: event.filterType,
        navigationFilterValue: event.filterValue ?? '',
      ),
    );

    _logger.i('✅ Navigation filter updated');
  }

  // ==================== PROGRESSIVE EXTRACTION METHODS ====================

  /// Extract albums progressively from current songs
  Future<void> _extractAlbumsProgressive({
    required Function(List<Album>, bool) onProgress,
  }) async {
    try {
      final songs = state.allSongs;
      final List<Album> albums = [];
      const int batchSize = 10;

      for (int i = 0; i < songs.length; i += batchSize) {
        final batch = songs.skip(i).take(batchSize).toList();
        final batchAlbums = MusicService.fetchAlbumList(batch);

        // Add new albums to the list
        for (final album in batchAlbums) {
          if (!albums.any((existing) => existing.name == album.name)) {
            albums.add(album);
          }
        }

        // Report progress
        final isComplete = (i + batchSize) >= songs.length;
        onProgress(batchAlbums, isComplete);

        // Small delay to prevent UI blocking
        if (!isComplete) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _logger.i(
        '✅ Progressive album extraction completed: ${albums.length} albums',
      );
    } catch (e) {
      _logger.e('❌ Error in progressive album extraction: $e');
    }
  }

  /// Extract artists progressively from current songs
  Future<void> _extractArtistsProgressive({
    required Function(List<Artist>, bool) onProgress,
  }) async {
    try {
      final songs = state.allSongs;
      final List<Artist> artists = [];
      const int batchSize = 10;

      for (int i = 0; i < songs.length; i += batchSize) {
        final batch = songs.skip(i).take(batchSize).toList();
        final batchArtists = MusicService.fetchArtistList(batch);

        // Add new artists to the list
        for (final artist in batchArtists) {
          if (!artists.any((existing) => existing.name == artist.name)) {
            artists.add(artist);
          }
        }

        // Report progress
        final isComplete = (i + batchSize) >= songs.length;
        onProgress(batchArtists, isComplete);

        // Small delay to prevent UI blocking
        if (!isComplete) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _logger.i(
        '✅ Progressive artist extraction completed: ${artists.length} artists',
      );
    } catch (e) {
      _logger.e('❌ Error in progressive artist extraction: $e');
    }
  }

  // ==================== PLAY COUNT TRACKING METHODS ====================

  /// Setup play count tracking callbacks
  void _setupPlayCountTracking() {
    PlayCountTrackingService.onUpdatePlayCount = _updatePlayCountOnState;
    _logger.i('📊 Play count tracking service initialized');
  }

  /// Comprehensive play count update method - updates song, artists, albums, and playlist in one atomic operation
  void _updatePlayCountOnState(String songId) {
    try {
      _logger.i('🎵 Updating play counts for song ID: $songId');

      final currentState = state;
      final now = DateTime.now();

      // Step 1: Find and update the current song
      final songIndex = currentState.allSongs.indexWhere(
        (song) => song.id == songId,
      );
      if (songIndex == -1) {
        _logger.w('⚠️ Song not found with ID: $songId');
        return;
      }

      final currentSong = currentState.allSongs[songIndex];
      final updatedSongWithCount = currentSong.copyWith(
        lastPlayed: now,
        playCount: (currentSong.playCount ?? 0) + 1,
      );

      // Create updated allSongs list
      final updatedAllSongs = List<Song>.from(currentState.allSongs);
      updatedAllSongs[songIndex] = updatedSongWithCount;

      // Step 2: Update artists based on song's artist names (case-insensitive)
      List<Artist> updatedArtistList = List<Artist>.from(
        currentState.artistList,
      );

      for (String artistName in currentSong.artists) {
        final artistIndex = updatedArtistList.indexWhere(
          (artist) =>
              artist.name.toLowerCase().trim() ==
              artistName.toLowerCase().trim(),
        );
        if (artistIndex != -1) {
          final currentArtist = updatedArtistList[artistIndex];
          final updatedArtist = currentArtist.copyWith(
            lastPlayed: now,
            playCount: (currentArtist.playCount ?? 0) + 1,
          );
          updatedArtistList[artistIndex] = updatedArtist;
          _logger.d('🎤 Updated artist: "${currentArtist.name}"');
        } else {
          _logger.w('⚠️ Artist not found: "$artistName"');
        }
      }

      // Step 3: Update albums based on song's album names (case-insensitive)
      List<Album> updatedAlbumList = List<Album>.from(currentState.albumList);

      for (String albumName in currentSong.albums) {
        final albumIndex = updatedAlbumList.indexWhere(
          (album) =>
              album.name.toLowerCase().trim() == albumName.toLowerCase().trim(),
        );
        if (albumIndex != -1) {
          final currentAlbum = updatedAlbumList[albumIndex];
          final updatedAlbum = currentAlbum.copyWith(
            lastPlayed: now,
            playCount: (currentAlbum.playCount ?? 0) + 1,
          );
          updatedAlbumList[albumIndex] = updatedAlbum;
          _logger.d('💿 Updated album: "${currentAlbum.name}"');
        } else {
          _logger.w('⚠️ Album not found: "$albumName"');
        }
      }

      // Step 4: Update MyPlaylist if applicable (from tracking service context)
      List<MyPlaylist> updatedMyPlaylistList = List<MyPlaylist>.from(
        currentState.myPlaylist,
      );

      // Check if we have playlist context from the tracking service
      final trackingStatus = PlayCountTrackingService.getTrackingStatus();
      final playlistId = trackingStatus['playlistId'] as String?;
      final playlistSource = trackingStatus['playlistSource'] as String?;

      if (playlistId != null &&
          playlistSource != null &&
          playlistSource == 'my_playlist') {
        // Extract actual playlist ID (remove prefix if present)
        String actualPlaylistId = playlistId;
        if (playlistId.startsWith('my_playlist_')) {
          actualPlaylistId = playlistId.substring(12);
        }

        final playlistIndex = updatedMyPlaylistList.indexWhere(
          (playlist) => playlist.id == actualPlaylistId,
        );

        if (playlistIndex != -1) {
          final currentPlaylist = updatedMyPlaylistList[playlistIndex];
          final updatedPlaylist = currentPlaylist.copyWith(
            lastPlayed: now,
            playCount: (currentPlaylist.playCount ?? 0) + 1,
          );
          updatedMyPlaylistList[playlistIndex] = updatedPlaylist;
          _logger.d('📋 Updated playlist: "${currentPlaylist.name}"');
        } else {
          _logger.w('⚠️ Playlist not found: $actualPlaylistId');
        }
      }

      // Step 5: Emit updated state (preserving all other state properties)
      add(
        MusicEvent.updateMusicBlocState(
          newState: currentState.copyWith(
            allSongs: updatedAllSongs,
            artistList: updatedArtistList,
            albumList: updatedAlbumList,
            myPlaylist: updatedMyPlaylistList,
          ),
        ),
      );

      _logger.i(
        '✅ Play count updated successfully for: "${currentSong.title}"',
      );
    } catch (e) {
      _logger.e('❌ Error updating play count: $e');
    }
  }

  /// Extract comprehensive features for all songs using background service
  Future<void> _onExtractComprehensiveFeatures(
    _ExtractComprehensiveFeatures event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🔬 Starting comprehensive features extraction (hybrid background mode)',
    );

    try {
      // Initialize Music Feature Analyzer if needed
      if (!MusicFeatureAnalyzer.isInitialized) {
        _logger.i('🚀 Initializing Music Feature Analyzer...');
        final initialized = await MusicFeatureAnalyzer.initialize();
        if (!initialized) {
          _logger.e('❌ Failed to initialize Music Feature Analyzer');
          emit(
            state.copyWith(
              isComprehensiveFeaturesExtractingLoading: false,
              isComprehensiveFeaturesExtractingError: true,
            ),
          );
          return;
        }
      }

      // Validate song list
      if (state.allSongs.isEmpty) {
        _logger.w('⚠️ No songs to analyze');
        emit(
          state.copyWith(
            isComprehensiveFeaturesExtractingLoading: false,
            isComprehensiveFeaturesExtractingError: false,
          ),
        );
        return;
      }

      // Note: Can't check processing state across isolates with WorkManager

      // Determine which songs to process (exclude songs that failed >= 2 times)
      const int maxFailureCountBeforeExclude = 2;
      final failureCount = state.comprehensiveFeatureExtractionFailureCount;

      List<Song> targetSongs;
      if (event.isForce == true) {
        // Force re-extraction for all songs (ignore failure count)
        targetSongs = List<Song>.from(state.allSongs);
        _logger.i(
          '🔁 Force re-extraction enabled — processing all ${targetSongs.length} songs.',
        );
      } else {
        // Extract only for songs missing features and not excluded (failure count < 2)
        targetSongs = state.allSongs.where((song) {
          if (song.features != null) return false;
          final count = failureCount[song.id] ?? 0;
          if (count >= maxFailureCountBeforeExclude) {
            _logger.d('⏭️ Skipping song (failed $count times): ${song.title}');
            return false;
          }
          return true;
        }).toList();

        if (targetSongs.isEmpty) {
          _logger.i(
            '✅ All songs already have features or excluded after failures. Nothing to process.',
          );
          emit(
            state.copyWith(
              isComprehensiveFeaturesExtractingLoading: false,
              isComprehensiveFeaturesExtractingError: false,
            ),
          );
          return;
        }

        _logger.i(
          '🎵 Extracting features for ${targetSongs.length} pending songs (excluded ${failureCount.values.where((c) => c >= maxFailureCountBeforeExclude).length} with >= $maxFailureCountBeforeExclude failures)...',
        );
      }

      final targetSongIds = targetSongs.map((s) => s.id).toSet();
      final successIdsInRun = <String>{};

      // Set loading state
      emit(
        state.copyWith(
          isComprehensiveFeaturesExtractingLoading: true,
          isComprehensiveFeaturesExtractingError: false,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Convert songs to file paths for analysis
      final filePaths = targetSongs.map((song) => song.path).toList();
      // Pass durations to avoid per-file metadata reads on main isolate (keeps UI responsive)
      final durationMsByPath = {
        for (final song in targetSongs) song.path: song.duration.inMilliseconds,
      };

      try {
        _logger.i('🎵 Starting Music Feature Analyzer batch processing...');

        // Analyze songs using package with background processing (same as original)
        await MusicFeatureAnalyzer.extractFeaturesInBackground(
          filePaths,
          durationMsByPath: durationMsByPath,
          onProgress: (current, total) {
            _logger.d(
              '📊 Feature extraction progress: $current/$total songs processed',
            );
            // Emit progress update to UI
            emit(
              state.copyWith(
                isComprehensiveFeaturesExtractingLoading: true,
                isComprehensiveFeaturesExtractingError: false,
              ),
            );
          },
          onSongUpdated: (filePath, features) {
            _logger.d('🔄 Updated song: ${filePath.split('/').last}');
            if (features != null) {
              _logger.d(
                '🔍 Features: ${features.estimatedGenre} | ${features.tempoBpm} BPM',
              );
              try {
                final songForPath = state.allSongs.firstWhere(
                  (s) => s.path == filePath,
                );
                successIdsInRun.add(songForPath.id);
              } catch (_) {}
              final projectFeatures =
                  MusicMetadataService.extractedToSongFeatures(features);
              if (projectFeatures == null) return;
              final updatedSongs = state.allSongs.map((song) {
                if (song.path == filePath) {
                  return song.copyWith(features: projectFeatures);
                }
                return song;
              }).toList();

              // Emit updated state with the new song features
              emit(
                state.copyWith(
                  allSongs: updatedSongs,
                  isComprehensiveFeaturesExtractingLoading: true,
                  isComprehensiveFeaturesExtractingError: false,
                ),
              );
            }
          },
          onCompleted: () {
            _recordExtractionFailures(targetSongIds, successIdsInRun, emit);
            _logger.i('✅ Background feature extraction completed');
          },
          onError: (error) {
            _logger.e('❌ Background feature extraction error: $error');
            _recordExtractionFailures(targetSongIds, successIdsInRun, emit);
          },
        );

        // Final state update - mark extraction as complete
        emit(
          state.copyWith(
            isComprehensiveFeaturesExtractingLoading: false,
            isComprehensiveFeaturesExtractingError: false,
          ),
        );

        _logger.i('✅ Music Feature Analyzer completed successfully');
      } catch (e) {
        _logger.e('❌ Music Feature Analyzer error: $e');
        emit(
          state.copyWith(
            isComprehensiveFeaturesExtractingLoading: false,
            isComprehensiveFeaturesExtractingError: true,
          ),
        );
      }
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          isComprehensiveFeaturesExtractingLoading: false,
          isComprehensiveFeaturesExtractingError: true,
        ),
      );
      _logger.e('❌ Error in comprehensive features extraction: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// Record extraction failures for songs that were in this run but never got a successful update.
  /// Increments failure count in state; when count >= 2 the song is excluded from future pending lists.
  void _recordExtractionFailures(
    Set<String> targetSongIds,
    Set<String> successIdsInRun,
    Emitter<MusicState> emit,
  ) {
    final failedIds = targetSongIds.difference(successIdsInRun);
    if (failedIds.isEmpty) return;

    final current = state.comprehensiveFeatureExtractionFailureCount;
    final updated = Map<String, int>.from(current);
    for (final id in failedIds) {
      updated[id] = (updated[id] ?? 0) + 1;
    }

    _logger.w(
      '⚠️ Recording extraction failure for ${failedIds.length} song(s); '
      'excluded when count >= 2',
    );
    emit(state.copyWith(comprehensiveFeatureExtractionFailureCount: updated));
  }

  /// Check if music features are analyzed and trigger background analysis if needed
  void _checkAndTriggerFeatureAnalysis() {
    try {
      final currentState = state;
      final allSongs = currentState.allSongs;

      // Skip if no songs available
      if (allSongs.isEmpty) {
        _logger.d('📊 No songs available for feature analysis check');
        return;
      }

      // Skip if already analyzing
      if (currentState.isComprehensiveFeaturesExtractingLoading) {
        _logger.d('📊 Feature analysis already in progress, skipping');
        return;
      }

      // Check if there are songs without features
      final songsWithoutFeatures = allSongs
          .where((song) => song.features == null)
          .toList();

      if (songsWithoutFeatures.isEmpty) {
        _logger.i('✅ All songs already have features analyzed');
        return;
      }

      // Get progress to check completion percentage
      final progress = MusicFeatureAnalyzer.getExtractionProgressWithSongs(
        allSongs,
      );
      final completionPercentage =
          progress['completionPercentage'] as double? ?? 0.0;

      _logger.i(
        '📊 Feature analysis check: ${songsWithoutFeatures.length} songs need analysis (${completionPercentage.toStringAsFixed(1)}% complete)',
      );

      // Trigger background analysis for songs without features
      _logger.i('🚀 Starting background feature analysis for AI shuffle...');
      add(const MusicEvent.extractComprehensiveFeatures(isForce: false));
    } catch (e, stackTrace) {
      _logger.e('❌ Error checking feature analysis: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  @override
  Future<void> close() {
    // Stop play count tracking
    PlayCountTrackingService.stopTracking();

    // Stop sleep timer
    SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);

    // Note: WorkManager handles background task cleanup automatically

    // Dispose stream subscriptions to prevent memory leaks
    _playerStateSubscription?.cancel();
    _appSettingsSubscription?.cancel();
    return super.close();
  }
}
