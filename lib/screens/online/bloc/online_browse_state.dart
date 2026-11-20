part of 'online_browse_bloc.dart';

/// What an [OnlineBrowseBloc] lists.
enum OnlineBrowseKind { tracks, albums, artists }

enum BrowseStatus { initial, loading, success, failure }

@freezed
abstract class OnlineBrowseState with _$OnlineBrowseState {
  const OnlineBrowseState._();

  const factory OnlineBrowseState({
    required OnlineBrowseKind kind,
    @Default(BrowseStatus.initial) BrowseStatus status,
    @Default(OnlineSort.popular) OnlineSort sort,
    String? tag,
    @Default('') String query,
    @Default(<Song>[]) List<Song> songs,
    @Default(<Album>[]) List<Album> albums,
    @Default(<Artist>[]) List<Artist> artists,
    @Default(0) int nextOffset,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isOffline,
    JamendoErrorKind? error,
  }) = _OnlineBrowseState;

  int get itemCount => switch (kind) {
    OnlineBrowseKind.tracks => songs.length,
    OnlineBrowseKind.albums => albums.length,
    OnlineBrowseKind.artists => artists.length,
  };

  bool get isEmpty => itemCount == 0;

  /// Full-screen skeleton: loading with nothing to show yet.
  bool get showSkeleton =>
      (status == BrowseStatus.initial || status == BrowseStatus.loading) &&
      isEmpty;

  bool get isSearching => query.trim().isNotEmpty;
}
