import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../utils/logger/logger.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/jamendo_api_client.dart';
import '../../../utils/services/jamendo/jamendo_repository.dart';
import '../../../utils/services/jamendo/online_song_registry.dart';
import '../../../utils/services/jamendo/jamendo_models.dart';
import '../../../utils/services/jamendo/recommendation_service.dart';
import '../../../utils/services/jamendo/region_models.dart';
import '../../../utils/services/jamendo/taste_models.dart';
import 'discover_section.dart';

export 'discover_section.dart';

part 'discover_event.dart';
part 'discover_state.dart';
part 'discover_bloc.freezed.dart';

/// Discover home (online For You): personalised rows loaded independently,
/// persisted so the last content shows instantly on the next launch.
class DiscoverBloc extends HydratedBloc<DiscoverEvent, DiscoverState> {
  static final AppLogger _logger = AppLogger('DiscoverBloc');

  final JamendoRepository repository;
  final RecommendationService recommendations;
  final DateTime Function() _now;

  /// Liked / recently played online songs (from OnlineLibraryBloc) used by
  /// "Made for you". Empty when not provided.
  final ({List<Song> liked, List<Song> recent}) Function()? libraryInputs;
  bool _loading = false;

  DiscoverBloc({
    required this.repository,
    DateTime Function()? now,
    this.libraryInputs,
    RecommendationService? recommendations,
  }) : _now = now ?? DateTime.now,
       recommendations = recommendations ?? RecommendationService(repository),
      super(const DiscoverState()) {
    on<_LoadHome>(_onLoadHome);
    on<_RefreshSection>(_onRefreshSection);
    on<_RegionChanged>(_onRegionChanged);
    on<_SectionUpdated>(
      (event, emit) => emit(
        state.copyWith(
          sections: {...state.sections, event.section.id: event.section},
        ),
      ),
    );
    // Restored songs must be playable before the first refresh.
    for (final section in state.sections.values) {
      OnlineSongRegistry.register(section.songs);
    }
  }

  @override
  String get storagePrefix => 'DiscoverBloc';

  // ==================== SECTION DEFINITIONS ====================

  /// Sections for the current region, in display order.
  List<_SectionDef> _sectionDefinitions() {
    final country = MusicRegions.countryByAlpha2(state.country);
    final language = state.languages.isEmpty
        ? null
        : MusicRegions.languageByCode(state.languages.first);
    final tastes = state.tastes
        .map(MusicTastes.byId)
        .whereType<MusicTaste>()
        .toList();
    final heroTaste = tastes.isNotEmpty ? tastes.first : MusicTastes.byId('pop')!;
    return [
      _SectionDef(
        id: DiscoverSectionIds.hero,
        title: 'Featured for you',
        subtitle: '${heroTaste.emoji} ${heroTaste.label}',
        kind: DiscoverSectionKind.tracks,
        style: SectionStyle.hero,
        load: (force) async =>
            (await repository.tasteTracks(heroTaste, limit: 6, forceRefresh: force))
                .where((s) => s.albumArt != null)
                .take(5)
                .toList(),
      ),
      if (tastes.isNotEmpty)
        _SectionDef(
          id: DiscoverSectionIds.madeForYou,
          title: 'Made for you',
          subtitle: 'Based on your taste and listening',
          kind: DiscoverSectionKind.tracks,
          load: (force) {
            final inputs = libraryInputs?.call();
            return recommendations.madeForYou(
              pickedTastes: state.tastes,
              liked: inputs?.liked ?? const [],
              recent: inputs?.recent ?? const [],
              forceRefresh: force,
            );
          },
        ),
      _SectionDef(
        id: DiscoverSectionIds.trending,
        title: 'Trending now',
        subtitle: 'Top 10 on Jamendo this week',
        kind: DiscoverSectionKind.tracks,
        style: SectionStyle.chart,
        load: (force) async =>
            (await repository.tracks(limit: 10, forceRefresh: force)).items.take(10).toList(),
      ),
      _SectionDef(
        id: DiscoverSectionIds.mixes,
        title: tastes.isEmpty ? 'Mixes for you' : 'Your mixes',
        subtitle: tastes.isEmpty ? 'Curated by Jamendo' : 'Your vibes + Jamendo picks',
        kind: DiscoverSectionKind.mixes,
      ),
      if (country != null)
        _SectionDef(
          id: DiscoverSectionIds.country,
          title: 'Top in ${country.name} ${country.flag}',
          subtitle: 'Artists from ${country.name}',
          kind: DiscoverSectionKind.tracks,
          load: (force) => repository.tracksFromCountries(
            [country.alpha3],
            forceRefresh: force,
          ),
        ),
      if (language != null)
        _SectionDef(
          id: DiscoverSectionIds.language,
          title: language.isGlobal ? 'Popular songs' : '${language.name} picks',
          subtitle: language.isGlobal
              ? 'Most played vocals this month'
              : language.nativeName,
          kind: DiscoverSectionKind.tracks,
          load: (force) => repository.languagePicks(language, forceRefresh: force),
        ),
      for (var i = 0; i < tastes.length && i < 2; i++)
        _SectionDef(
          id: i == 0 ? DiscoverSectionIds.because0 : DiscoverSectionIds.because1,
          title: 'Because you like ${tastes[i].label}',
          subtitle: '${tastes[i].emoji} Popular this month',
          kind: DiscoverSectionKind.tracks,
          load: (force) => repository.tasteTracks(tastes[i], forceRefresh: force),
        ),
      _SectionDef(
        id: DiscoverSectionIds.newReleases,
        title: 'Fresh releases',
        subtitle: 'New albums',
        kind: DiscoverSectionKind.albums,
      ),
      _SectionDef(
        id: DiscoverSectionIds.artists,
        title: 'Artists to discover',
        subtitle: 'Popular this month',
        kind: DiscoverSectionKind.artists,
      ),
      _SectionDef(
        id: DiscoverSectionIds.radio,
        title: 'Live radio',
        subtitle: '24/7 Jamendo stations',
        kind: DiscoverSectionKind.radios,
      ),
    ];
  }

  /// Personal mixes (one per picked taste) followed by Jamendo's featured
  /// genre mixes that the user did not pick.
  static List<JamendoMix> buildMixes(List<String> tastes, List<JamendoMix> featured) {
    final picked = tastes
        .map(MusicTastes.byId)
        .whereType<MusicTaste>()
        .map(
          (t) => JamendoMix(
            id: 'mix_${t.id}',
            title: 'Your ${t.label} Mix',
            subtitle: '${t.emoji} Made for you',
            tag: t.id,
            featured: false,
          ),
        )
        .toList();
    final pickedTags = picked.map((m) => m.tag).toSet();
    return [...picked, ...featured.where((m) => !pickedTags.contains(m.tag))];
  }

  List<JamendoMix> _mixes() => buildMixes(state.tastes, repository.mixes());

  Future<DiscoverSection> _loadSection(_SectionDef def, {bool force = false}) async {
    var section = DiscoverSection(
      id: def.id,
      title: def.title,
      subtitle: def.subtitle,
      kind: def.kind,
      style: def.style,
    );
    try {
      switch (def.kind) {
        case DiscoverSectionKind.tracks:
          var songs = await def.load!(force);
          if (songs.isEmpty &&
              (def.id == DiscoverSectionIds.country ||
                  def.id == DiscoverSectionIds.language ||
                  def.id == DiscoverSectionIds.madeForYou)) {
            // Thin catalogue for this region: show popular music instead.
            songs = (await repository.tracks(forceRefresh: force)).items;
            section = section.copyWith(subtitle: 'Popular worldwide');
          }
          OnlineSongRegistry.register(songs);
          section = section.copyWith(songs: songs);
        case DiscoverSectionKind.albums:
          section = section.copyWith(
            albums: (await repository.albums(
              sort: OnlineSort.newest,
              limit: 20,
              forceRefresh: force,
            )).items,
          );
        case DiscoverSectionKind.artists:
          section = section.copyWith(
            artists: (await repository.artists(
              limit: 20,
              forceRefresh: force,
            )).items,
          );
        case DiscoverSectionKind.mixes:
          section = section.copyWith(mixes: _mixes());
        case DiscoverSectionKind.radios:
          section = section.copyWith(
            radios: await repository.radios(forceRefresh: force),
          );
      }
      return section.copyWith(
        status: SectionStatus.success,
        fetchedAt: _now(),
        clearError: true,
      );
    } on JamendoException catch (e) {
      _logger.w('⚠️ Section ${def.id} failed: ${e.kind}');
      final previous = state.sections[def.id];
      // Keep previously shown items; just flag the error.
      return (previous ?? section).copyWith(
        title: def.title,
        subtitle: previous?.subtitle ?? def.subtitle,
        status: SectionStatus.error,
        error: e.kind,
      );
    }
  }

  // ==================== HANDLERS ====================

  Future<void> _onLoadHome(_LoadHome event, Emitter<DiscoverState> emit) async {
    if (_loading && !event.force) return;
    _loading = true;
    try {
      await _loadAll(emit, force: event.force);
    } finally {
      _loading = false;
    }
  }

  Future<void> _loadAll(Emitter<DiscoverState> emit, {required bool force}) async {
    final defs = _sectionDefinitions();
    final ids = defs.map((d) => d.id).toSet();
    final staleBefore = repository.staleResponseCount;

    emit(
      state.copyWith(
        notConfigured: false,
        sections: {
          for (final def in defs)
            def.id: (state.sections[def.id] ??
                    DiscoverSection(
                      id: def.id,
                      title: def.title,
                      kind: def.kind,
                      style: def.style,
                    ))
                .copyWith(
                  title: def.title,
                  subtitle: def.subtitle,
                  status: SectionStatus.loading,
                ),
        },
      ),
    );

    var notConfigured = false;
    await Future.wait(
      defs.map((def) async {
        final section = await _loadSection(def, force: force);
        if (section.error == JamendoErrorKind.notConfigured) notConfigured = true;
        if (!isClosed && ids.contains(section.id)) {
          emit(state.copyWith(sections: {...state.sections, section.id: section}));
        }
      }),
    );

    emit(
      state.copyWith(
        lastLoadedAt: _now(),
        notConfigured: notConfigured,
        isOffline: repository.staleResponseCount > staleBefore ||
            state.sections.values.any((s) => s.error == JamendoErrorKind.offline),
      ),
    );
  }

  Future<void> _onRefreshSection(
    _RefreshSection event,
    Emitter<DiscoverState> emit,
  ) async {
    final def = _sectionDefinitions().where((d) => d.id == event.sectionId);
    if (def.isEmpty) return;
    final current = state.sections[event.sectionId];
    if (current != null) {
      emit(
        state.copyWith(
          sections: {
            ...state.sections,
            event.sectionId: current.copyWith(status: SectionStatus.loading),
          },
        ),
      );
    }
    final section = await _loadSection(def.first, force: true);
    emit(state.copyWith(sections: {...state.sections, section.id: section}));
  }

  Future<void> _onRegionChanged(
    _RegionChanged event,
    Emitter<DiscoverState> emit,
  ) async {
    final languages = List<String>.from(event.languages);
    final tastes = List<String>.from(event.tastes);
    if (event.country == state.country &&
        languages.join(',') == state.languages.join(',') &&
        tastes.join(',') == state.tastes.join(',') &&
        state.sections.isNotEmpty) {
      return;
    }
    // Drop personalised rows built for the previous region / tastes.
    final sections = Map<String, DiscoverSection>.from(state.sections)
      ..remove(DiscoverSectionIds.country)
      ..remove(DiscoverSectionIds.language)
      ..remove(DiscoverSectionIds.hero)
      ..remove(DiscoverSectionIds.madeForYou)
      ..remove(DiscoverSectionIds.because0)
      ..remove(DiscoverSectionIds.because1)
      ..remove(DiscoverSectionIds.mixes);
    emit(
      state.copyWith(
        country: event.country,
        languages: languages,
        tastes: tastes,
        sections: sections,
      ),
    );
    _loading = true;
    try {
      await _loadAll(emit, force: false);
    } finally {
      _loading = false;
    }
  }

  // ==================== PERSISTENCE ====================

  @override
  Map<String, dynamic>? toJson(DiscoverState state) {
    try {
      return {
        'country': state.country,
        'languages': state.languages,
        'tastes': state.tastes,
        'lastLoadedAt': state.lastLoadedAt?.toIso8601String(),
        'sections': [
          for (final s in state.sections.values)
            if (s.status == SectionStatus.success && !s.isEmpty) s.toJson(),
        ],
      };
    } catch (_) {
      return null;
    }
  }

  @override
  DiscoverState? fromJson(Map<String, dynamic> json) {
    try {
      final tastes = List<String>.from(json['tastes'] ?? const []);
      final mixes = buildMixes(tastes, repository.mixes());
      final sections = <String, DiscoverSection>{};
      for (final raw in (json['sections'] as List? ?? const [])) {
        final section = DiscoverSection.fromJson(
          Map<String, dynamic>.from(raw as Map),
          mixes: mixes,
        );
        sections[section.id] = section;
      }
      return DiscoverState(
        country: json['country'] as String?,
        languages: List<String>.from(json['languages'] ?? const []),
        tastes: tastes,
        sections: sections,
        lastLoadedAt: json['lastLoadedAt'] == null
            ? null
            : DateTime.tryParse(json['lastLoadedAt'] as String),
      );
    } catch (e) {
      _logger.w('⚠️ Could not restore Discover: $e');
      return null;
    }
  }
}

/// Static description of a section.
class _SectionDef {
  final String id;
  final String title;
  final String subtitle;
  final DiscoverSectionKind kind;
  final SectionStyle style;

  /// Loader for track sections (other kinds are loaded by kind).
  final Future<List<Song>> Function(bool force)? load;

  const _SectionDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.style = SectionStyle.shelf,
    this.load,
  });
}
