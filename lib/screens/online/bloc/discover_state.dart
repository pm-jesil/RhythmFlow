part of 'discover_bloc.dart';

@freezed
abstract class DiscoverState with _$DiscoverState {
  const DiscoverState._();

  const factory DiscoverState({
    /// Sections keyed by id (see [DiscoverSectionIds.order]).
    @Default(<String, DiscoverSection>{}) Map<String, DiscoverSection> sections,

    /// Country (alpha-2) and languages the personalised sections were
    /// built for.
    String? country,
    @Default(<String>[]) List<String> languages,

    /// Some data is shown from the offline cache.
    @Default(false) bool isOffline,

    /// The Jamendo client id is missing in this build.
    @Default(false) bool notConfigured,

    DateTime? lastLoadedAt,
  }) = _DiscoverState;

  /// Sections in display order (missing ones skipped).
  List<DiscoverSection> get orderedSections => [
    for (final id in DiscoverSectionIds.order)
      if (sections[id] != null) sections[id]!,
  ];

  /// True while nothing has been loaded yet (show the full-page skeleton).
  bool get isInitialLoading =>
      sections.isEmpty ||
      sections.values.every((s) => s.isLoading && s.isEmpty);

  /// Every section failed and nothing is cached.
  bool get isFailed =>
      sections.isNotEmpty &&
      sections.values.every((s) => s.hasError && s.isEmpty);

  String get regionKey => '${country ?? ''}|${languages.join(',')}';
}
