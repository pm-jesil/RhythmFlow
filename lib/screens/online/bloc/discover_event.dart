part of 'discover_bloc.dart';

@freezed
abstract class DiscoverEvent with _$DiscoverEvent {
  /// Load (or refresh) every section. Fresh cached data is used unless
  /// [force] is set (pull to refresh).
  const factory DiscoverEvent.loadHome({
    @Default(false) bool force,
  }) = _LoadHome;

  /// Retry / refresh a single section.
  const factory DiscoverEvent.refreshSection({
    required String sectionId,
  }) = _RefreshSection;

  /// Country / languages changed: rebuild personalised sections.
  const factory DiscoverEvent.regionChanged({
    String? country,
    @Default(<String>[]) List<String> languages,
  }) = _RegionChanged;

  /// Internal: one section finished loading (or failed).
  const factory DiscoverEvent.sectionUpdated({
    required DiscoverSection section,
  }) = _SectionUpdated;
}
