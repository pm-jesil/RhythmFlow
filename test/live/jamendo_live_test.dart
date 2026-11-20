// Live tests against the real Jamendo API, one test per endpoint / feature.
//
// They are skipped unless a client id is given:
//   flutter test test/live --dart-define-from-file=config/jamendo.json
//
// Jamendo randomly answers ~1 in 4 requests with an empty result; the client
// retries those (see JamendoApiClient.emptyResultRetries), so these tests
// exercise the same resilience the app relies on.
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/audio_header_validator.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_api_client.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_cache.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_repository.dart';
import 'package:rhythmflow/utils/services/jamendo/recommendation_service.dart';
import 'package:rhythmflow/utils/services/jamendo/region_models.dart';
import 'package:rhythmflow/utils/services/jamendo/taste_models.dart';

const clientId = String.fromEnvironment('JAMENDO_CLIENT_ID');

void main() {
  final skip = clientId.isEmpty ? 'Set JAMENDO_CLIENT_ID to run live API tests' : null;
  late JamendoApiClient client;
  late JamendoRepository repo;

  setUp(() {
    client = JamendoApiClient(clientId: clientId, emptyResultRetries: 4);
    repo = JamendoRepository(client: client, cache: JamendoCache());
  });

  const t = Timeout(Duration(minutes: 2));

  group('raw endpoints', () {
    Future<List<Map<String, dynamic>>> get(String endpoint, Map<String, Object?> p) async =>
        (await client.get(endpoint, p)).results;

    test('GET /tracks', () async {
      final r = await get('tracks', {'limit': 5, 'order': 'popularity_week', 'audioformat': 'mp32'});
      expect(r, isNotEmpty);
      expect(r.first.keys, containsAll(['id', 'name', 'artist_name', 'audio', 'duration', 'audiodownload_allowed']));
    }, skip: skip, timeout: t);

    test('GET /albums', () async {
      final r = await get('albums', {'limit': 5, 'order': 'popularity_month'});
      expect(r.first.keys, containsAll(['id', 'name', 'artist_name', 'image']));
    }, skip: skip, timeout: t);

    test('GET /albums/tracks', () async {
      final album = (await get('albums', {'limit': 1, 'order': 'popularity_month'})).first;
      final r = await get('albums/tracks', {'id': album['id']});
      expect(r.first['tracks'], isA<List>());
    }, skip: skip, timeout: t);

    test('GET /artists', () async {
      final r = await get('artists', {'limit': 5, 'order': 'popularity_month'});
      expect(r.first.keys, containsAll(['id', 'name']));
    }, skip: skip, timeout: t);

    test('GET /artists/tracks', () async {
      final artist = (await get('artists', {'limit': 1, 'order': 'popularity_month'})).first;
      final r = await get('artists/tracks', {'id': artist['id']});
      expect(r.first['tracks'], isA<List>());
    }, skip: skip, timeout: t);

    test('GET /artists/locations (country)', () async {
      final r = await get('artists/locations', {'location_country': 'IND', 'limit': 10});
      expect(r, isNotEmpty);
      expect((r.first['locations'] as List).first['country'], 'IND');
    }, skip: skip, timeout: t);

    test('GET /artists/musicinfo (tags for suggestions)', () async {
      final artist = (await get('artists', {'limit': 1, 'order': 'popularity_total'})).first;
      final r = await get('artists/musicinfo', {'id': artist['id']});
      expect(r.first['musicinfo'], isA<Map>());
    }, skip: skip, timeout: t);

    test('GET /radios and /radios/stream', () async {
      final radios = await get('radios', {'limit': 50});
      expect(radios.length, greaterThanOrEqualTo(10));
      final stream = await get('radios/stream', {'id': radios.first['id']});
      expect(stream.first['stream'], startsWith('https://'));
    }, skip: skip, timeout: t);

    test('invalid client id is reported as an API error', () async {
      final bad = JamendoApiClient(clientId: 'invalid-client-id');
      await expectLater(
        bad.get('tracks', {'limit': 1}),
        throwsA(isA<JamendoException>().having((e) => e.kind, 'kind', JamendoErrorKind.api)),
      );
    }, skip: skip, timeout: t);
  });

  group('repository features', () {
    test('popular, newest and paging', () async {
      final popular = await repo.tracks();
      expect(popular.items, hasLength(30));
      final page2 = await repo.tracks(offset: popular.nextOffset);
      expect(page2.items, isNotEmpty);
      expect(page2.items.first.id, isNot(popular.items.first.id));
      expect((await repo.tracks(sort: OnlineSort.newest)).items, isNotEmpty);
    }, skip: skip, timeout: t);

    test('search tracks, albums and artists', () async {
      expect((await repo.tracks(search: 'love')).items, isNotEmpty);
      expect((await repo.albums(search: 'love')).items, isNotEmpty);
      expect((await repo.artists(search: 'love')).items, isNotEmpty);
    }, skip: skip, timeout: t);

    test('mood / genre chips (fuzzytags)', () async {
      expect((await repo.tracks(tag: 'happy')).items, isNotEmpty);
      expect(await repo.mixTracks('pop'), isNotEmpty);
    }, skip: skip, timeout: t);

    test('every taste in the picker returns music', () async {
      final empty = <String>[];
      for (final taste in MusicTastes.all) {
        final songs = await repo.tasteTracks(taste, limit: 3);
        if (songs.isEmpty) empty.add(taste.id);
      }
      expect(empty, isEmpty, reason: 'tastes without results: $empty');
    }, skip: skip, timeout: const Timeout(Duration(minutes: 6)));

    test('country picks (India) and language picks', () async {
      expect(await repo.tracksFromCountries(['IND']), isNotEmpty);
      for (final code in ['ml', 'hi', 'ta', 'en', 'fr', 'ja']) {
        final songs = await repo.languagePicks(MusicRegions.languageByCode(code)!);
        expect(songs, isNotEmpty, reason: code);
      }
    }, skip: skip, timeout: const Timeout(Duration(minutes: 4)));

    test('album and artist pages', () async {
      final album = (await repo.albums()).items.first;
      final a = await repo.albumWithTracks(album.remoteId!);
      expect(a!.$2, isNotEmpty);
      final artist = (await repo.artists()).items.first;
      final b = await repo.artistWithTracks(artist.remoteId!);
      expect(b!.$2, isNotEmpty);
    }, skip: skip, timeout: t);

    test('radios and stream urls', () async {
      final radios = await repo.radios();
      expect(radios, isNotEmpty);
      expect(await repo.radioStreamUrl(radios.first.id), startsWith('https://'));
    }, skip: skip, timeout: t);

    Future<(int, String?)> probe(String url) async {
      final http = HttpClient();
      try {
        final request = await http.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-4095');
        final response = await request.close();
        final type = response.headers.contentType?.primaryType;
        await response.drain<void>();
        return (response.statusCode, type);
      } finally {
        http.close();
      }
    }

    test('stream URLs of popular tracks serve audio', () async {
      // Individual Jamendo tracks can be broken on Jamendo's side (measured:
      // 404 for the stream, 500 for the download); the player skips those.
      final songs = (await repo.tracks(limit: 5)).items;
      final broken = <String>[];
      for (final song in songs) {
        final url = await repo.resolveStreamUrl(song.copyWith(streamUrl: null));
        final (status, type) = await probe(url!);
        if (!(status == 200 || status == 206) || type != 'audio') broken.add('${song.remoteId}:$status');
      }
      // ignore: avoid_print
      if (broken.isNotEmpty) print('Unplayable on Jamendo right now: $broken');
      expect(songs.length - broken.length, greaterThanOrEqualTo(3));
    }, skip: skip, timeout: t);

    test('download URL returns a real MP3 (valid header)', () async {
      final songs = (await repo.tracks(limit: 10)).items.where((s) => s.canDownload);
      final dir = await Directory.systemTemp.createTemp('jm_dl_');
      addTearDown(() => dir.delete(recursive: true));
      var valid = 0;
      for (final song in songs.take(4)) {
        final file = File('${dir.path}/${song.remoteId}.mp3');
        final http = HttpClient();
        try {
          final response = await (await http.getUrl(Uri.parse(song.downloadUrl!))).close();
          if (response.statusCode != 200) {
            await response.drain<void>();
            continue;
          }
          await response.pipe(file.openWrite());
          if (await AudioHeaderValidator.isValidFile(file.path)) valid++;
        } finally {
          http.close();
        }
        if (valid > 0) break;
      }
      expect(valid, greaterThan(0));
    }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

    test('Made for you from tastes', () async {
      final songs = await RecommendationService(repo).madeForYou(pickedTastes: ['hiphop', 'lofi']);
      expect(songs, isNotEmpty);
      final perArtist = <String, int>{};
      for (final s in songs) {
        perArtist[s.artists.first] = (perArtist[s.artists.first] ?? 0) + 1;
      }
      expect(perArtist.values.every((n) => n <= 2), isTrue);
    }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
  });
}
