part of 'online_browse_bloc.dart';

@freezed
abstract class OnlineBrowseEvent with _$OnlineBrowseEvent {
  /// First load (no-op when items are already loaded, unless [force]).
  const factory OnlineBrowseEvent.started({@Default(false) bool force}) =
      _Started;

  /// Pull to refresh.
  const factory OnlineBrowseEvent.refreshed() = _Refreshed;

  const factory OnlineBrowseEvent.sortChanged(OnlineSort sort) = _SortChanged;

  /// Filter chip (Jamendo tag); null clears the filter. Tracks only.
  const factory OnlineBrowseEvent.tagChanged(String? tag) = _TagChanged;

  /// Search text (debounced).
  const factory OnlineBrowseEvent.queryChanged(String query) = _QueryChanged;

  /// Infinite scroll.
  const factory OnlineBrowseEvent.loadMore() = _LoadMore;
}
