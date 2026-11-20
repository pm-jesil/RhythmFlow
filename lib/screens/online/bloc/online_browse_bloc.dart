import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/jamendo_api_client.dart';
import '../../../utils/services/jamendo/jamendo_config.dart';
import '../../../utils/services/jamendo/jamendo_models.dart';
import '../../../utils/services/jamendo/jamendo_repository.dart';
import '../../../utils/services/jamendo/online_song_registry.dart';

part 'online_browse_event.dart';
part 'online_browse_state.dart';
part 'online_browse_bloc.freezed.dart';

/// Paged, searchable list of online tracks / albums / artists (one bloc per
/// tab). Not hydrated: results are cached by [JamendoRepository].
class OnlineBrowseBloc extends Bloc<OnlineBrowseEvent, OnlineBrowseState> {
  final JamendoRepository repository;
  final int pageSize;

  /// Search debounce.
  static Duration queryDebounce = const Duration(milliseconds: 400);

  /// Incremented on every new query/sort/tag so late responses of an older
  /// request are ignored.
  int _generation = 0;

  OnlineBrowseBloc({
    required this.repository,
    required OnlineBrowseKind kind,
    this.pageSize = JamendoConfig.pageSize,
  }) : super(OnlineBrowseState(kind: kind)) {
    on<_Started>(_onStarted);
    on<_Refreshed>((event, emit) => _reload(emit, force: true));
    on<_SortChanged>((event, emit) {
      if (event.sort == state.sort) return null;
      emit(state.copyWith(sort: event.sort));
      return _reload(emit);
    });
    on<_TagChanged>((event, emit) {
      if (event.tag == state.tag) return null;
      emit(state.copyWith(tag: event.tag));
      return _reload(emit);
    });
    on<_QueryChanged>(
      (event, emit) {
        final query = event.query.trim();
        if (query == state.query.trim()) return null;
        emit(state.copyWith(query: query));
        return _reload(emit);
      },
      // Debounce typing and drop results of superseded searches.
      transformer: (events, mapper) =>
          events.debounceTime(queryDebounce).switchMap(mapper),
    );
    on<_LoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(_Started event, Emitter<OnlineBrowseState> emit) async {
    if (!event.force && !state.isEmpty && state.status == BrowseStatus.success) {
      return;
    }
    await _reload(emit, force: event.force);
  }

  Future<void> _reload(Emitter<OnlineBrowseState> emit, {bool force = false}) async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: BrowseStatus.loading,
        nextOffset: 0,
        hasMore: true,
        isLoadingMore: false,
        error: null,
        // Keep the old items while refreshing; clear them for a new query.
        songs: force ? state.songs : const [],
        albums: force ? state.albums : const [],
        artists: force ? state.artists : const [],
      ),
    );
    await _fetchPage(emit, generation, offset: 0, force: force);
  }

  Future<void> _onLoadMore(_LoadMore event, Emitter<OnlineBrowseState> emit) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != BrowseStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    await _fetchPage(emit, _generation, offset: state.nextOffset);
  }

  Future<void> _fetchPage(
    Emitter<OnlineBrowseState> emit,
    int generation, {
    required int offset,
    bool force = false,
  }) async {
    final staleBefore = repository.staleResponseCount;
    try {
      final search = state.isSearching ? state.query : null;
      switch (state.kind) {
        case OnlineBrowseKind.tracks:
          final page = await repository.tracks(
            sort: state.sort,
            tag: search == null ? state.tag : null,
            search: search,
            offset: offset,
            limit: pageSize,
            forceRefresh: force,
          );
          if (generation != _generation) return;
          OnlineSongRegistry.register(page.items);
          _emitPage(
            emit,
            page,
            staleBefore,
            (items) => state.copyWith(
              songs: _merge(offset == 0 ? const [] : state.songs, items, (s) => s.id),
            ),
          );
        case OnlineBrowseKind.albums:
          final page = await repository.albums(
            sort: state.sort,
            search: search,
            offset: offset,
            limit: pageSize,
            forceRefresh: force,
          );
          if (generation != _generation) return;
          _emitPage(
            emit,
            page,
            staleBefore,
            (items) => state.copyWith(
              albums: _merge(offset == 0 ? const [] : state.albums, items, (a) => a.id),
            ),
          );
        case OnlineBrowseKind.artists:
          final page = await repository.artists(
            sort: state.sort,
            search: search,
            offset: offset,
            limit: pageSize,
            forceRefresh: force,
          );
          if (generation != _generation) return;
          _emitPage(
            emit,
            page,
            staleBefore,
            (items) => state.copyWith(
              artists: _merge(offset == 0 ? const [] : state.artists, items, (a) => a.id),
            ),
          );
      }
    } on JamendoException catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: state.isEmpty ? BrowseStatus.failure : BrowseStatus.success,
          isLoadingMore: false,
          error: e.kind,
          isOffline: e.kind == JamendoErrorKind.offline,
        ),
      );
    }
  }

  void _emitPage<T>(
    Emitter<OnlineBrowseState> emit,
    JamendoPage<T> page,
    int staleBefore,
    OnlineBrowseState Function(List<T> items) withItems,
  ) {
    final next = withItems(page.items);
    emit(
      next.copyWith(
        status: BrowseStatus.success,
        nextOffset: page.nextOffset,
        hasMore: page.hasMore,
        isLoadingMore: false,
        error: null,
        isOffline: repository.staleResponseCount > staleBefore,
      ),
    );
  }

  static List<T> _merge<T>(List<T> current, List<T> page, String Function(T) id) {
    final seen = current.map(id).toSet();
    return [...current, ...page.where((item) => seen.add(id(item)))];
  }
}
