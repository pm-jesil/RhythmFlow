import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/online/bloc/discover_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/online_browse_bloc.dart';
import 'package:rhythmflow/screens/online/bloc/online_library_bloc.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_api_client.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_cache.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_repository.dart';
import 'package:rhythmflow/utils/services/jamendo/online_song_registry.dart';

import 'jamendo_data_layer_test.dart' show FakeTransport, envelope, fixture;

class MockStorage extends Mock implements Storage {}

/// Builds a fake Jamendo that answers by endpoint.
FakeTransport fakeJamendo({Set<String> failing = const {}, bool offline = false}) {
  final t = FakeTransport();
  t.handler = (uri) {
    final path = uri.path;
    final p = uri.queryParameters;
    if (offline) return const SocketException('offline');
    for (final f in failing) {
      if (path.contains(f)) return const SocketException('offline');
    }
    if (path.endsWith('/radios/')) return fixture('radios.json');
    if (path.contains('artists/musicinfo')) {
      return envelope([
        {'id': p['id'], 'name': 'Liked artist', 'musicinfo': {'tags': ['hiphop', 'trap', 'unknowntag']}},
      ]);
    }
    if (path.contains('artists/tracks')) {
      return envelope([
        {
          'id': p['id'],
          'name': 'Fav artist',
          'tracks': [
            for (var i = 0; i < 3; i++)
              {'id': 'fav${p['id']}_$i', 'name': 'Fav song $i', 'duration': '200', 'audio': 'https://s/fav$i'},
          ],
        },
      ]);
    }
    if (path.contains('artists/locations')) {
      return envelope([{'id': '10', 'name': 'Local artist'}]);
    }
    if (path.endsWith('/artists/')) {
      final offset = int.parse(p['offset'] ?? '0');
      return envelope([
        for (var i = 0; i < 3; i++)
          {'id': 'a${offset + i}', 'name': 'Artist ${offset + i}'},
      ]);
    }
    if (path.endsWith('/albums/')) {
      final offset = int.parse(p['offset'] ?? '0');
      return envelope([
        for (var i = 0; i < 3; i++)
          {'id': 'al${offset + i}', 'name': 'Album ${offset + i}', 'artist_name': 'X'},
      ]);
    }
    if (path.endsWith('/tracks/')) {
      final offset = int.parse(p['offset'] ?? '0');
      final label = p['search'] ?? p['fuzzytags'] ?? p['tags'] ?? p['artist_id'] ?? p['order'] ?? 'x';
      // Two full pages, then a short last page.
      final count = offset >= 6 ? 1 : 3;
      return envelope([
        for (var i = 0; i < count; i++)
          {
            'id': '${label.hashCode.abs()}_${offset + i}',
            'name': '$label ${offset + i}',
            'artist_name': '$label artist ${offset + i}',
            'artist_id': '${label.hashCode.abs()}${offset + i}',
            'duration': 200,
            'audio': 'https://stream/${offset + i}',
          },
      ], next: count == 3 ? 'more' : null);
    }
    return envelope([]);
  };
  return t;
}

JamendoRepository repoFor(FakeTransport t) => JamendoRepository(
  client: JamendoApiClient(clientId: 'TEST', transport: t.call, retryDelay: Duration.zero),
  cache: JamendoCache(),
);

Future<void> settle([int ms = 30]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late MockStorage storage;
  final written = <String, dynamic>{};

  setUp(() {
    storage = MockStorage();
    written.clear();
    when(() => storage.read(any())).thenAnswer((i) => written[i.positionalArguments[0]]);
    when(() => storage.write(any(), any())).thenAnswer((i) async {
      written[i.positionalArguments[0] as String] = i.positionalArguments[1];
    });
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    OnlineSongRegistry.clear();
  });

  group('DiscoverBloc', () {
    test('loads every section for region + tastes in order', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo()));
      bloc.add(const DiscoverEvent.regionChanged(
        country: 'IN',
        languages: ['ml'],
        tastes: ['hiphop', 'lofi'],
      ));
      await settle(150);

      final ids = bloc.state.orderedSections.map((s) => s.id).toList();
      expect(ids, DiscoverSectionIds.order);
      expect(bloc.state.sections[DiscoverSectionIds.hero]!.style, SectionStyle.hero);
      expect(bloc.state.sections[DiscoverSectionIds.trending]!.style, SectionStyle.chart);
      expect(bloc.state.sections[DiscoverSectionIds.trending]!.songs.length, lessThanOrEqualTo(10));
      expect(bloc.state.sections[DiscoverSectionIds.because0]!.title, 'Because you like Hip-Hop & Rap');
      expect(bloc.state.sections[DiscoverSectionIds.because1]!.title, 'Because you like Lo-fi');
      expect(bloc.state.sections[DiscoverSectionIds.madeForYou]!.songs, isNotEmpty);
      expect(bloc.state.sections.values.every((s) => s.status == SectionStatus.success), isTrue);
      expect(bloc.state.sections[DiscoverSectionIds.country]!.title, contains('India'));
      expect(bloc.state.sections[DiscoverSectionIds.language]!.title, 'Malayalam picks');
      expect(bloc.state.sections[DiscoverSectionIds.radio]!.radios, hasLength(3));
      expect(bloc.state.sections[DiscoverSectionIds.mixes]!.mixes, isNotEmpty);
      expect(bloc.state.isInitialLoading, isFalse);
      // Songs shown on Discover are playable (registered).
      final song = bloc.state.sections[DiscoverSectionIds.trending]!.songs.first;
      expect(OnlineSongRegistry.get(song.id), isNotNull);
      await bloc.close();
    });

    test('without region/tastes only the global sections load', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo()));
      bloc.add(const DiscoverEvent.loadHome());
      await settle(100);
      expect(bloc.state.sections.keys.toSet(), {
        DiscoverSectionIds.hero,
        DiscoverSectionIds.trending,
        DiscoverSectionIds.mixes,
        DiscoverSectionIds.newReleases,
        DiscoverSectionIds.artists,
        DiscoverSectionIds.radio,
      });
      await bloc.close();
    });

    test('personal mixes come first, then featured genres not picked', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo()));
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['en'], tastes: ['lofi', 'pop']));
      await settle(150);
      final mixes = bloc.state.sections[DiscoverSectionIds.mixes]!.mixes;
      expect(mixes.take(2).map((m) => m.title), ['Your Lo-fi Mix', 'Your Pop Mix']);
      expect(mixes.where((m) => m.tag == 'pop'), hasLength(1), reason: 'no duplicate pop mix');
      expect(mixes.first.featured, isFalse);
      await bloc.close();
    });

    test('Made for you uses liked songs\' artists and excludes them', () async {
      final liked = JamendoMapper.track({
        'id': 'liked1', 'name': 'Liked', 'artist_name': 'Fav', 'artist_id': '777',
      });
      final t = fakeJamendo();
      final bloc = DiscoverBloc(
        repository: repoFor(t),
        libraryInputs: () => (liked: [liked], recent: const []),
      );
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['en'], tastes: ['lofi']));
      await settle(150);
      final made = bloc.state.sections[DiscoverSectionIds.madeForYou]!.songs;
      expect(made.map((s) => s.id), isNot(contains(liked.id)));
      // Tags of the liked artist (hiphop, trap) were queried.
      expect(t.requests.any((u) => u.path.contains('artists/musicinfo') && u.queryParameters['id'] == '777'), isTrue);
      expect(t.requests.any((u) => u.queryParameters['fuzzytags'] == 'hiphop' || u.queryParameters['tags'] == 'hiphop'), isTrue);
      // Songs of the favourite artist are suggested.
      expect(made.any((s) => s.title.startsWith('Fav song')), isTrue);
      await bloc.close();
    });

    test('changing tastes rebuilds the personal rows', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo()));
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['en'], tastes: ['lofi']));
      await settle(150);
      expect(bloc.state.sections[DiscoverSectionIds.because0]!.title, contains('Lo-fi'));
      expect(bloc.state.sections.containsKey(DiscoverSectionIds.because1), isFalse);
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['en'], tastes: ['jazz', 'rock']));
      await settle(150);
      expect(bloc.state.sections[DiscoverSectionIds.because0]!.title, contains('Jazz'));
      expect(bloc.state.sections[DiscoverSectionIds.because1]!.title, contains('Rock'));
      expect(bloc.state.tastes, ['jazz', 'rock']);
      await bloc.close();
    });

    test('a failing section only marks itself as error', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo(failing: {'radios'})));
      bloc.add(const DiscoverEvent.loadHome());
      await settle(100);
      final radio = bloc.state.sections[DiscoverSectionIds.radio]!;
      expect(radio.status, SectionStatus.error);
      expect(radio.error, JamendoErrorKind.offline);
      expect(bloc.state.sections[DiscoverSectionIds.trending]!.status, SectionStatus.success);
      expect(bloc.state.isOffline, isTrue);
      expect(bloc.state.isFailed, isFalse);
      await bloc.close();
    });

    test('everything offline and nothing cached -> isFailed', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo(offline: true)));
      bloc.add(const DiscoverEvent.loadHome());
      await settle(100);
      // Mixes are static, so they still show.
      final failed = bloc.state.sections.values.where((s) => s.hasError);
      expect(failed, isNotEmpty);
      expect(bloc.state.sections[DiscoverSectionIds.mixes]!.status, SectionStatus.success);
      await bloc.close();
    });

    test('refreshSection retries just that section', () async {
      final transport = fakeJamendo(failing: {'radios'});
      final bloc = DiscoverBloc(repository: repoFor(transport));
      bloc.add(const DiscoverEvent.loadHome());
      await settle(100);
      expect(bloc.state.sections[DiscoverSectionIds.radio]!.hasError, isTrue);

      final working = fakeJamendo();
      transport.handler = working.handler;
      bloc.add(const DiscoverEvent.refreshSection(sectionId: DiscoverSectionIds.radio));
      await settle(100);
      expect(bloc.state.sections[DiscoverSectionIds.radio]!.status, SectionStatus.success);
      await bloc.close();
    });

    test('empty country picks fall back to popular music', () async {
      final t = fakeJamendo();
      final base = t.handler!;
      t.handler = (uri) => uri.path.contains('artists/locations') ? envelope([]) : base(uri);
      final bloc = DiscoverBloc(repository: repoFor(t));
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['en']));
      await settle(100);
      final country = bloc.state.sections[DiscoverSectionIds.country]!;
      expect(country.songs, isNotEmpty);
      expect(country.subtitle, 'Popular worldwide');
      await bloc.close();
    });

    test('region change rebuilds personalised rows; same region is a no-op', () async {
      final t = fakeJamendo();
      final bloc = DiscoverBloc(repository: repoFor(t));
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['hi']));
      await settle(100);
      final calls = t.requests.length;
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['hi']));
      await settle(50);
      expect(t.requests.length, calls);

      bloc.add(const DiscoverEvent.regionChanged(country: 'FR', languages: ['fr']));
      await settle(100);
      expect(bloc.state.sections[DiscoverSectionIds.country]!.title, contains('France'));
      expect(bloc.state.sections[DiscoverSectionIds.language]!.title, 'French picks');
      await bloc.close();
    });

    test('state is persisted and restored (instant first paint)', () async {
      final bloc = DiscoverBloc(repository: repoFor(fakeJamendo()));
      bloc.add(const DiscoverEvent.regionChanged(country: 'IN', languages: ['ml'], tastes: ['rock']));
      await settle(100);
      final saved = bloc.toJson(bloc.state)!;
      await bloc.close();

      OnlineSongRegistry.clear();
      final restored = DiscoverBloc(repository: repoFor(fakeJamendo())).fromJson(saved)!;
      expect(restored.country, 'IN');
      expect(restored.languages, ['ml']);
      expect(restored.tastes, ['rock']);
      expect(restored.sections[DiscoverSectionIds.mixes]!.mixes.first.title, 'Your Rock Mix');
      // The hero only shows songs with artwork; the fake API has none, so the
      // (empty) hero is not persisted. One taste -> one 'because' row.
      expect(restored.sections.containsKey(DiscoverSectionIds.hero), isFalse);
      expect(
        restored.orderedSections.map((s) => s.id),
        DiscoverSectionIds.order.where(
          (id) => id != DiscoverSectionIds.hero && id != DiscoverSectionIds.because1,
        ),
      );
      expect(restored.sections[DiscoverSectionIds.trending]!.songs, isNotEmpty);
      expect(restored.sections[DiscoverSectionIds.mixes]!.mixes, isNotEmpty);
    });

    test('missing client id is reported', () async {
      final bloc = DiscoverBloc(
        repository: JamendoRepository(
          client: JamendoApiClient(clientId: '', transport: (_) async => {}),
          cache: JamendoCache(),
        ),
      );
      bloc.add(const DiscoverEvent.loadHome());
      await settle(100);
      expect(bloc.state.notConfigured, isTrue);
      await bloc.close();
    });
  });

  group('OnlineBrowseBloc', () {
    test('loads first page, then more pages until the end', () async {
      final bloc = OnlineBrowseBloc(
        repository: repoFor(fakeJamendo()),
        kind: OnlineBrowseKind.tracks,
        pageSize: 3,
      );
      bloc.add(const OnlineBrowseEvent.started());
      await settle();
      expect(bloc.state.songs, hasLength(3));
      expect(bloc.state.hasMore, isTrue);

      bloc.add(const OnlineBrowseEvent.loadMore());
      await settle();
      bloc.add(const OnlineBrowseEvent.loadMore());
      await settle();
      expect(bloc.state.songs, hasLength(7));
      expect(bloc.state.hasMore, isFalse);

      bloc.add(const OnlineBrowseEvent.loadMore()); // no-op at the end
      await settle();
      expect(bloc.state.songs, hasLength(7));
      expect(bloc.state.songs.map((s) => s.id).toSet(), hasLength(7));
      await bloc.close();
    });

    test('search is debounced and only the last query is fetched', () async {
      OnlineBrowseBloc.queryDebounce = const Duration(milliseconds: 50);
      final t = fakeJamendo();
      final bloc = OnlineBrowseBloc(repository: repoFor(t), kind: OnlineBrowseKind.tracks);
      for (final q in ['l', 'lo', 'lov', 'love']) {
        bloc.add(OnlineBrowseEvent.queryChanged(q));
        await settle(10);
      }
      await settle(150);
      final searches = t.requests.map((u) => u.queryParameters['search']).whereType<String>();
      expect(searches.toSet(), {'love'});
      expect(bloc.state.query, 'love');
      expect(bloc.state.songs.first.title, startsWith('love'));
      await bloc.close();
    });

    test('tag and sort changes reload from the first page', () async {
      final t = fakeJamendo();
      final bloc = OnlineBrowseBloc(repository: repoFor(t), kind: OnlineBrowseKind.tracks, pageSize: 3);
      bloc.add(const OnlineBrowseEvent.started());
      await settle();
      bloc.add(const OnlineBrowseEvent.tagChanged('rock'));
      await settle();
      expect(t.requests.last.queryParameters['fuzzytags'], 'rock');
      expect(t.requests.last.queryParameters['offset'], '0');
      expect(bloc.state.songs.first.title, startsWith('rock'));

      bloc.add(const OnlineBrowseEvent.sortChanged(OnlineSort.newest));
      await settle();
      expect(t.requests.last.queryParameters['order'], 'releasedate_desc');
      await bloc.close();
    });

    test('albums and artists tabs page too', () async {
      final albums = OnlineBrowseBloc(
        repository: repoFor(fakeJamendo()),
        kind: OnlineBrowseKind.albums,
        pageSize: 3,
      )..add(const OnlineBrowseEvent.started());
      final artists = OnlineBrowseBloc(
        repository: repoFor(fakeJamendo()),
        kind: OnlineBrowseKind.artists,
        pageSize: 3,
      )..add(const OnlineBrowseEvent.started());
      await settle();
      expect(albums.state.albums, hasLength(3));
      expect(artists.state.artists, hasLength(3));
      albums.add(const OnlineBrowseEvent.loadMore());
      await settle();
      expect(albums.state.albums, hasLength(6));
      await albums.close();
      await artists.close();
    });

    test('offline first load shows failure; skeleton only while empty', () async {
      final bloc = OnlineBrowseBloc(
        repository: repoFor(fakeJamendo(offline: true)),
        kind: OnlineBrowseKind.tracks,
      );
      expect(bloc.state.showSkeleton, isTrue);
      bloc.add(const OnlineBrowseEvent.started());
      await settle();
      expect(bloc.state.status, BrowseStatus.failure);
      expect(bloc.state.isOffline, isTrue);
      expect(bloc.state.showSkeleton, isFalse);
      await bloc.close();
    });

    test('refresh keeps current items visible while reloading', () async {
      final completer = Completer<void>();
      final t = fakeJamendo();
      final bloc = OnlineBrowseBloc(repository: repoFor(t), kind: OnlineBrowseKind.tracks);
      bloc.add(const OnlineBrowseEvent.started());
      await settle();
      final base = t.handler!;
      final states = <OnlineBrowseState>[];
      final sub = bloc.stream.listen(states.add);
      t.handler = (uri) => base(uri);
      bloc.add(const OnlineBrowseEvent.refreshed());
      await settle();
      expect(states.first.status, BrowseStatus.loading);
      expect(states.first.songs, isNotEmpty);
      await sub.cancel();
      completer.complete();
      await bloc.close();
    });
  });

  group('OnlineLibraryBloc', () {
    final song = JamendoMapper.track({'id': '1', 'name': 'One', 'artist_name': 'A'});
    final song2 = JamendoMapper.track({'id': '2', 'name': 'Two', 'artist_name': 'B'});

    test('like / unlike online songs (local songs are ignored)', () async {
      final bloc = OnlineLibraryBloc();
      bloc.add(OnlineLibraryEvent.toggleLike(song));
      await settle();
      expect(bloc.state.isLiked(song.id), isTrue);
      bloc.add(OnlineLibraryEvent.toggleLike(song));
      await settle();
      expect(bloc.state.isLiked(song.id), isFalse);
      bloc.add(OnlineLibraryEvent.toggleLike(song.copyWith(source: null)));
      await settle();
      expect(bloc.state.likedSongs, isEmpty);
      await bloc.close();
    });

    test('history is most-recent-first, unique and capped', () async {
      final bloc = OnlineLibraryBloc();
      bloc
        ..add(OnlineLibraryEvent.recordPlay(song))
        ..add(OnlineLibraryEvent.recordPlay(song2))
        ..add(OnlineLibraryEvent.recordPlay(song));
      await settle();
      expect(bloc.state.recentlyPlayed.map((s) => s.id), [song.id, song2.id]);
      for (var i = 0; i < 60; i++) {
        bloc.add(OnlineLibraryEvent.recordPlay(
          JamendoMapper.track({'id': 'h$i', 'name': 'H$i'}),
        ));
      }
      await settle();
      expect(bloc.state.recentlyPlayed, hasLength(OnlineLibraryBloc.maxHistory));
      bloc.add(const OnlineLibraryEvent.clearHistory());
      await settle();
      expect(bloc.state.recentlyPlayed, isEmpty);
      await bloc.close();
    });

    test('follow artists and save albums', () async {
      final bloc = OnlineLibraryBloc();
      final artist = JamendoMapper.artist({'id': '9', 'name': 'Nine'});
      final album = JamendoMapper.album({'id': '8', 'name': 'Eight'});
      bloc
        ..add(OnlineLibraryEvent.toggleFollowArtist(artist))
        ..add(OnlineLibraryEvent.toggleSaveAlbum(album));
      await settle();
      expect(bloc.state.isFollowing(artist.id), isTrue);
      expect(bloc.state.isSaved(album.id), isTrue);
      await bloc.close();
    });

    test('persists everything; interrupted downloads restore as failed', () async {
      final bloc = OnlineLibraryBloc();
      bloc
        ..add(OnlineLibraryEvent.toggleLike(song))
        ..add(OnlineLibraryEvent.recordPlay(song2))
        ..add(OnlineLibraryEvent.downloadUpdated(
          songId: song.id,
          download: OnlineDownload(phase: DownloadPhase.downloading, progress: .4, song: song),
        ))
        ..add(OnlineLibraryEvent.downloadUpdated(
          songId: song2.id,
          download: const OnlineDownload(phase: DownloadPhase.completed, progress: 1, localPath: '/m/2.mp3'),
        ));
      await settle();
      final json = bloc.toJson(bloc.state)!;
      await bloc.close();

      OnlineSongRegistry.clear();
      final restored = OnlineLibraryBloc().fromJson(json)!;
      expect(restored.likedSongs.single.id, song.id);
      expect(restored.recentlyPlayed.single.id, song2.id);
      expect(restored.downloads[song.id]!.phase, DownloadPhase.failed);
      expect(restored.downloads[song.id]!.error, 'Interrupted');
      expect(restored.downloads[song2.id]!.phase, DownloadPhase.completed);
      expect(restored.downloads[song2.id]!.localPath, '/m/2.mp3');
    });

    test('liked and recent songs are registered for playback on start', () async {
      // Real storage returns freshly decoded JSON (mutable maps/lists).
      written['OnlineLibraryBloc'] = jsonDecode(jsonEncode({
        'likedSongs': [song.toJson()],
        'recentlyPlayed': [song2.toJson()],
      }));
      final bloc = OnlineLibraryBloc();
      expect(OnlineSongRegistry.get(song.id), isNotNull);
      expect(OnlineSongRegistry.get(song2.id), isNotNull);
      await bloc.close();
    });
  });

  group('OnlineSongRegistry', () {
    test('ignores local songs and resolves in order', () {
      final online = JamendoMapper.track({'id': '1', 'name': 'One'});
      final local = online.copyWith(id: 'local', source: null);
      OnlineSongRegistry.register([online, local]);
      expect(OnlineSongRegistry.contains('local'), isFalse);
      expect(OnlineSongRegistry.resolveAll(['x', online.id]).single.id, online.id);
    });
  });
}
