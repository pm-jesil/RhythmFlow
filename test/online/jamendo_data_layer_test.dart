import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_api_client.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_cache.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_repository.dart';
import 'package:rhythmflow/utils/services/jamendo/region_models.dart';
import 'package:rhythmflow/utils/services/library_storage.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/online/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> envelope(List<Map<String, dynamic>> results, {String? next}) => {
  'headers': {
    'status': 'success',
    'code': 0,
    'error_message': '',
    'warnings': '',
    'results_count': results.length,
    if (next != null) 'next': next,
  },
  'results': results,
};

/// Records requests and answers them from a queue / handler.
class FakeTransport {
  final List<Uri> requests = [];
  final List<Object> queue = [];
  Object Function(Uri uri)? handler;

  Future<Map<String, dynamic>> call(Uri uri) async {
    requests.add(uri);
    final next = queue.isNotEmpty ? queue.removeAt(0) : handler?.call(uri);
    if (next is Map<String, dynamic>) return next;
    if (next is Object) throw next;
    throw StateError('no response for $uri');
  }

  Map<String, String> paramsOf(int i) => requests[i].queryParameters;
}

JamendoApiClient clientWith(FakeTransport t) => JamendoApiClient(
  clientId: 'TEST',
  transport: t.call,
  retryDelay: Duration.zero,
);

void main() {
  group('JamendoApiClient.buildUri', () {
    final client = JamendoApiClient(clientId: 'abc', transport: (_) async => {});

    test('adds client id, json format and a trailing slash', () {
      final uri = client.buildUri('tracks', {'limit': 5});
      expect(uri.toString(),
          'https://api.jamendo.com/v3.0/tracks/?client_id=abc&format=json&limit=5');
    });

    test('joins multi-value params with %20, never "+"', () {
      final uri = client.buildUri('tracks', {
        'id': ['1', '2'],
        'search': 'rock pop',
      });
      final text = uri.toString();
      expect(text, contains('id=1%202'));
      expect(text, contains('search=rock%20pop'));
      expect(text, isNot(contains('+')));
    });

    test('skips null and empty values', () {
      final uri = client.buildUri('/albums/', {
        'a': null,
        'b': '',
        'c': <String>[],
        'd': 'x',
      });
      expect(uri.toString(),
          'https://api.jamendo.com/v3.0/albums/?client_id=abc&format=json&d=x');
    });
  });

  group('JamendoApiClient.get', () {
    test('parses results and the next link', () async {
      final t = FakeTransport()..queue.add(fixture('tracks.json'));
      final r = await clientWith(t).get('tracks');
      expect(r.results, hasLength(3));
    });

    test('API error envelope becomes JamendoException(api)', () async {
      final t = FakeTransport()..queue.add(fixture('error.json'));
      await expectLater(
        clientWith(t).get('tracks'),
        throwsA(isA<JamendoException>().having((e) => e.kind, 'kind', JamendoErrorKind.api)),
      );
    });

    test('retries timeouts and server errors, then succeeds', () async {
      final t = FakeTransport()
        ..queue.addAll([
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.receiveTimeout,
          ),
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: RequestOptions(), statusCode: 503),
          ),
          fixture('tracks.json'),
        ]);
      final r = await clientWith(t).get('tracks');
      expect(r.results, hasLength(3));
      expect(t.requests, hasLength(3));
    });

    test('does not retry when offline', () async {
      final t = FakeTransport()
        ..queue.add(const SocketException('no route'))
        ..queue.add(fixture('tracks.json'));
      await expectLater(
        clientWith(t).get('tracks'),
        throwsA(isA<JamendoException>().having((e) => e.kind, 'kind', JamendoErrorKind.offline)),
      );
      expect(t.requests, hasLength(1));
    });

    test('an empty result is retried (Jamendo flakiness) before accepting it', () async {
      final t = FakeTransport()
        ..queue.addAll([envelope([]), envelope([]), fixture('tracks.json')]);
      final r = await clientWith(t).get('tracks');
      expect(r.results, hasLength(3));
      expect(t.requests, hasLength(3));

      final t2 = FakeTransport()..handler = (_) => envelope([]);
      final empty = await clientWith(t2).get('tracks');
      expect(empty.results, isEmpty);
      expect(t2.requests, hasLength(3), reason: '1 call + 2 retries');
    });

    test('missing client id fails fast without a request', () async {
      final t = FakeTransport();
      final client = JamendoApiClient(clientId: '', transport: t.call);
      await expectLater(
        client.get('tracks'),
        throwsA(isA<JamendoException>().having((e) => e.kind, 'kind', JamendoErrorKind.notConfigured)),
      );
      expect(t.requests, isEmpty);
    });
  });

  group('JamendoMapper', () {
    test('maps a top-level track with numbers', () {
      final json = fixture('tracks.json')['results'][0] as Map<String, dynamic>;
      final song = JamendoMapper.track(json);
      expect(song.id, 'jm_${json['id']}');
      expect(song.remoteId, json['id']);
      expect(song.source, SongSources.jamendo);
      expect(song.isOnline, isTrue);
      expect(song.duration, Duration(seconds: json['duration'] as int));
      expect(song.streamUrl, json['audio']);
      expect(song.albumArt, startsWith('https://'));
      expect(song.path, 'jamendo://track/${json['id']}');
      expect(song.canDownload, json['audiodownload_allowed'] == true);
    });

    test('maps tracks nested in an album where numbers are strings', () {
      final album = fixture('album_tracks.json')['results'][0] as Map<String, dynamic>;
      final songs = JamendoMapper.albumTracks(album);
      expect(songs, isNotEmpty);
      final first = songs.first;
      final raw = (album['tracks'] as List).first as Map;
      expect(raw['duration'], isA<String>(), reason: 'fixture keeps the quirk');
      expect(first.duration.inSeconds, int.parse(raw['duration'] as String));
      expect(first.albums.single, album['name']);
      expect(first.artists.single, album['artist_name']);
      expect(first.albumArt, isNotNull, reason: 'falls back to album image');
    });

    test('maps tracks nested in an artist', () {
      final artist = fixture('artist_tracks.json')['results'][0] as Map<String, dynamic>;
      final songs = JamendoMapper.artistTracks(artist);
      expect(songs, isNotEmpty);
      expect(songs.every((s) => s.artists.single == artist['name']), isTrue);
    });

    test('maps albums, artists and radios', () {
      final a = JamendoMapper.album(fixture('albums.json')['results'][0]);
      expect(a.id, startsWith('jm_album_'));
      expect(a.coverImage, startsWith('https://'));
      expect(a.artistName, isNotEmpty);
      final ar = JamendoMapper.artist(fixture('artists.json')['results'][0]);
      expect(ar.id, startsWith('jm_artist_'));
      final radio = JamendoRadio.fromJson(fixture('radios.json')['results'][0]);
      expect(radio.displayName, isNotEmpty);
      final song = radio.toSong(streamUrl: 'https://s/1');
      expect(song.isRadio, isTrue);
      expect(song.id, startsWith('jmr_'));
      expect(song.canDownload, isFalse);
    });

    test('decodes HTML entities and tolerates missing fields', () {
      final song = JamendoMapper.track({
        'id': 7,
        'name': 'Rock &amp; Roll &#039;69',
        'duration': null,
      });
      expect(song.title, "Rock & Roll '69");
      expect(song.artists, ['Unknown Artist']);
      expect(song.duration, Duration.zero);
      expect(song.canDownload, isFalse);
    });

    test('online song ids', () {
      expect(JamendoMapper.isOnlineSongId('jm_1'), isTrue);
      expect(JamendoMapper.isOnlineSongId('jmr_1'), isTrue);
      expect(JamendoMapper.isOnlineSongId('a1b2c3d4e5f6a7b8'), isFalse);
      expect(JamendoMapper.remoteIdOf('jm_42'), '42');
      expect(JamendoMapper.remoteIdOf('jmr_3'), '3');
      expect(JamendoMapper.remoteIdOf('local'), isNull);
    });
  });

  group('JamendoRepository', () {
    late FakeTransport t;
    late JamendoRepository repo;
    late DateTime now;

    setUp(() {
      t = FakeTransport();
      now = DateTime(2026, 1, 1, 12);
      repo = JamendoRepository(
        client: clientWith(t),
        cache: JamendoCache(now: () => now),
        now: () => now,
      );
    });

    test('fresh cache entries are served without a request', () async {
      t.handler = (_) => fixture('tracks.json');
      await repo.tracks();
      await repo.tracks();
      expect(t.requests, hasLength(1));
      now = now.add(const Duration(hours: 2)); // past the list TTL
      await repo.tracks();
      expect(t.requests, hasLength(2));
    });

    test('offline: stale cache is served and flagged', () async {
      t.queue.add(fixture('tracks.json'));
      await repo.tracks();
      now = now.add(const Duration(days: 2));
      t.queue.add(const SocketException('offline'));
      final page = await repo.tracks();
      expect(page.items, hasLength(3));
      expect(repo.lastResponseWasStale, isTrue);
    });

    test('offline without cache rethrows', () async {
      t.queue.add(const SocketException('offline'));
      await expectLater(repo.tracks(), throwsA(isA<JamendoException>()));
    });

    test('an empty response never replaces good cached data', () async {
      t.queue.add(fixture('tracks.json'));
      await repo.tracks();
      now = now.add(const Duration(hours: 2));
      t.handler = (_) => envelope([]);
      final page = await repo.tracks();
      expect(page.items, hasLength(3));
    });

    test('empty responses are not cached', () async {
      t.handler = (_) => envelope([]);
      await repo.tracks();
      final before = t.requests.length;
      t.handler = (_) => fixture('tracks.json');
      final page = await repo.tracks();
      expect(t.requests.length, greaterThan(before));
      expect(page.items, hasLength(3));
    });

    test('sort params follow what the live API honours', () {
      expect(
        JamendoRepository.trackSortParams(sort: OnlineSort.popular, hasSearch: true, hasTag: false),
        isEmpty,
      );
      expect(
        JamendoRepository.trackSortParams(sort: OnlineSort.popular, hasSearch: false, hasTag: true),
        {'boost': 'popularity_week'},
      );
      expect(
        JamendoRepository.trackSortParams(sort: OnlineSort.popular, hasSearch: false, hasTag: false),
        {'order': 'popularity_week'},
      );
      expect(
        JamendoRepository.trackSortParams(sort: OnlineSort.newest, hasSearch: false, hasTag: false),
        {'order': 'releasedate_desc', 'boost': 'popularity_month'},
      );
    });

    test('search requests never send order/boost or include=musicinfo', () async {
      t.handler = (_) => fixture('tracks.json');
      await repo.tracks(search: 'love');
      final p = t.paramsOf(0);
      expect(p['search'], 'love');
      expect(p.containsKey('order'), isFalse);
      expect(p.containsKey('boost'), isFalse);
      expect(p.containsKey('include'), isFalse);
    });

    test('paging reports offsets and hasMore', () async {
      t.handler = (_) => envelope(
        List<Map<String, dynamic>>.from(fixture('tracks.json')['results']),
        next: 'https://api.jamendo.com/v3.0/tracks?offset=3',
      );
      final page = await repo.tracks(limit: 3);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 3);
      await repo.tracks(offset: page.nextOffset, limit: 3);
      expect(t.paramsOf(1)['offset'], '3');
    });

    test('country picks query artists by location then their tracks', () async {
      t.handler = (uri) {
        if (uri.path.contains('artists/locations')) {
          return envelope([
            {'id': '10', 'name': 'A'},
            {'id': '11', 'name': 'B'},
          ]);
        }
        return fixture('tracks.json');
      };
      final songs = await repo.tracksFromCountries(['IND']);
      expect(songs, isNotEmpty);
      expect(t.paramsOf(0)['location_country'], 'IND');
      expect(t.paramsOf(0).containsKey('order'), isFalse);
      expect(t.paramsOf(1)['artist_id'], '10 11');
    });

    test('language picks: tagged tracks first, then artists from its countries', () async {
      t.handler = (uri) {
        final p = uri.queryParameters;
        if (p['fuzzytags'] == 'hindi') return envelope([
          {'id': '1', 'name': 'Tagged', 'artist_name': 'X'},
        ]);
        if (uri.path.contains('artists/locations')) return envelope([{'id': '10'}]);
        return envelope([
          {'id': '2', 'name': 'From India', 'artist_name': 'Y'},
          {'id': '1', 'name': 'Tagged', 'artist_name': 'X'},
        ]);
      };
      final songs = await repo.languagePicks(MusicRegions.languageByCode('hi')!);
      expect(songs.map((s) => s.title), ['Tagged', 'From India']);
    });

    test('Malayalam (no tag on Jamendo) uses artists from India', () async {
      final ml = MusicRegions.languageByCode('ml')!;
      expect(ml.tag, isEmpty);
      t.handler = (uri) => uri.path.contains('artists/locations')
          ? envelope([{'id': '10'}])
          : fixture('tracks.json');
      final songs = await repo.languagePicks(ml);
      expect(songs, isNotEmpty);
      expect(t.requests.any((u) => u.queryParameters.containsKey('fuzzytags')), isFalse);
    });

    test('English maps to popular vocal tracks', () async {
      t.handler = (_) => fixture('tracks.json');
      await repo.languagePicks(MusicRegions.languageByCode('en')!);
      expect(t.paramsOf(0)['vocalinstrumental'], 'vocal');
    });

    test('limitPerArtist keeps variety', () {
      Song s(String id, String artist) =>
          JamendoMapper.track({'id': id, 'name': id, 'artist_name': artist});
      final result = JamendoRepository.limitPerArtist(
        [s('1', 'A'), s('2', 'A'), s('3', 'A'), s('4', 'B')],
        perArtist: 2,
      );
      expect(result.map((x) => x.remoteId), ['1', '2', '4']);
    });

    test('album and artist detail', () async {
      t.handler = (uri) => uri.path.contains('albums/tracks')
          ? fixture('album_tracks.json')
          : fixture('artist_tracks.json');
      final album = await repo.albumWithTracks('522038');
      expect(album!.$1.songIds, album.$2.map((s) => s.id).toList());
      final artist = await repo.artistWithTracks('551562');
      expect(artist!.$2, isNotEmpty);
    });

    test('radios and radio stream url', () async {
      t.handler = (uri) => uri.path.contains('radios/stream')
          ? fixture('radio_stream.json')
          : fixture('radios.json');
      final radios = await repo.radios();
      expect(radios, hasLength(3));
      expect(await repo.radioStreamUrl(radios.first.id), startsWith('https://'));
    });

    test('mixes are the featured genres', () {
      final mixes = repo.mixes();
      expect(mixes.map((m) => m.tag), contains('pop'));
      expect(mixes.first.title, endsWith('Mix'));
    });

    test('stream URLs are reused while fresh and refreshed when old', () async {
      t.handler = (_) => fixture('tracks.json');
      final page = await repo.tracks();
      final song = page.items.first;
      final before = t.requests.length;
      expect(await repo.resolveStreamUrl(song), song.streamUrl);
      expect(t.requests.length, before, reason: 'fresh URL reused');

      now = now.add(const Duration(hours: 3));
      await repo.resolveStreamUrl(song);
      expect(t.requests.length, before + 1, reason: 'expired URL refreshed');
      expect(t.requests.last.queryParameters['id'], song.remoteId);
    });

    test('cache keys ignore parameter order', () {
      expect(
        JamendoRepository.cacheKey('tracks', {'a': 1, 'b': [2, 3]}),
        JamendoRepository.cacheKey('tracks', {'b': [2, 3], 'a': 1}),
      );
    });
  });

  group('JamendoCache persistence', () {
    test('survives a restart through the storage backend', () async {
      final backend = InMemoryLibraryStoreBackend();
      final first = JamendoCache(backend: backend);
      await first.write('k', const JamendoResponse([{'id': '1'}], next: 'n'));
      final second = JamendoCache(backend: backend);
      final read = second.read('k');
      expect(read!.results.single['id'], '1');
      expect(read.next, 'n');
    });

    test('maxAge filters old entries but stale reads still work', () async {
      var now = DateTime(2026);
      final cache = JamendoCache(now: () => now);
      await cache.write('k', const JamendoResponse([{'id': '1'}]));
      now = now.add(const Duration(hours: 5));
      expect(cache.read('k', maxAge: const Duration(hours: 1)), isNull);
      expect(cache.read('k'), isNotNull);
    });
  });

  group('MusicRegions', () {
    test('countries are sorted, unique and include India', () {
      final names = MusicRegions.countries.map((c) => c.name).toList();
      expect(names, equals([...names]..sort()));
      expect(MusicRegions.countries.map((c) => c.alpha2).toSet(), hasLength(names.length));
      final india = MusicRegions.countryByAlpha2('in')!;
      expect(india.alpha3, 'IND');
      expect(india.flag, '🇮🇳');
      expect(india.artistCount, greaterThanOrEqualTo(3));
    });

    test('every language has a way to find music', () {
      for (final l in MusicRegions.languages) {
        expect(l.isGlobal || l.tag.isNotEmpty || l.countries.isNotEmpty, isTrue,
            reason: l.code);
      }
      expect(MusicRegions.languageByCode('ML')!.nativeName, 'മലയാളം');
    });

    test('search by English name, native name or code', () {
      expect(MusicRegions.searchLanguages('മലയാ').single.code, 'ml');
      expect(MusicRegions.searchLanguages('tam').map((l) => l.code), contains('ta'));
      expect(MusicRegions.searchCountries('ind').map((c) => c.alpha2), containsAll(['IN', 'ID']));
      expect(MusicRegions.searchCountries('IND').map((c) => c.alpha2), contains('IN'));
      expect(MusicRegions.searchCountries(''), hasLength(MusicRegions.countries.length));
    });

    test('locale suggestion', () {
      final s = MusicRegions.suggestFromLocale('ml', 'IN');
      expect(s.country?.alpha2, 'IN');
      expect(s.language?.code, 'ml');
      final none = MusicRegions.suggestFromLocale('xx', 'ZZ');
      expect(none.country, isNull);
      expect(none.language, isNull);
    });
  });
}
