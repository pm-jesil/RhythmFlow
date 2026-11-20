import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rhythmflow/screens/app_settings/bloc/app_settings_bloc.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/jamendo/jamendo_models.dart';
import 'package:rhythmflow/utils/services/jamendo/recommendation_service.dart';
import 'package:rhythmflow/utils/services/jamendo/taste_models.dart';

import 'jamendo_data_layer_test.dart' show FakeTransport, envelope;
import 'online_blocs_test.dart' show repoFor;

class MockStorage extends Mock implements Storage {}

Song song(String id, {String artist = 'A', String? artistId}) => JamendoMapper.track({
  'id': id,
  'name': 'Song $id',
  'artist_name': artist,
  'artist_id': artistId ?? 'artist_$artist',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicTastes catalogue', () {
    test('ids are unique and every taste has real content', () {
      final ids = MusicTastes.all.map((t) => t.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(MusicTastes.all.every((t) => t.trackCount >= 1000), isTrue);
      expect(MusicTastes.genres, isNotEmpty);
      expect(MusicTastes.moods, isNotEmpty);
      expect(MusicTastes.genres.length + MusicTastes.moods.length, MusicTastes.all.length);
    });

    test('aliases: rap, hip hop, soul, lo-fi', () {
      expect(MusicTastes.byId('rap')!.id, 'hiphop');
      expect(MusicTastes.byId('Hip Hop')!.label, 'Hip-Hop & Rap');
      expect(MusicTastes.byId('soul')!.id, 'rnb');
      expect(MusicTastes.byId('lo-fi')!.id, 'lofi');
      expect(MusicTastes.byId('nope'), isNull);
      expect(MusicTastes.byId(null), isNull);
    });

    test('includes traditional and Indian music', () {
      expect(MusicTastes.byId('traditional'), isNotNull);
      expect(MusicTastes.byId('indian'), isNotNull);
    });
  });

  group('RecommendationService.buildProfile', () {
    test('picked tastes outweigh artist tags; unknown tags ignored', () {
      final liked = [song('1', artistId: 'x')];
      final profile = RecommendationService.buildProfile(
        pickedTastes: ['lofi'],
        liked: liked,
        artistTags: {
          'x': ['hiphop', 'trap', 'notatag'],
        },
      );
      expect(profile.tagWeights['lofi'], RecommendationService.pickedWeight);
      expect(profile.tagWeights['hiphop'], RecommendationService.likedArtistTagWeight);
      expect(profile.tagWeights.containsKey('notatag'), isFalse);
      expect(profile.topTags.first, 'lofi');
    });

    test('repeated artist tags add up and can rank above a single pick', () {
      final liked = [for (var i = 0; i < 4; i++) song('$i', artistId: 'x$i')];
      final profile = RecommendationService.buildProfile(
        pickedTastes: ['jazz'],
        liked: liked,
        artistTags: {
          for (var i = 0; i < 4; i++) 'x$i': ['rock'],
        },
      );
      expect(profile.topTags.first, 'rock'); // 4 > 3
      expect(profile.topTags, contains('jazz'));
    });

    test('alias tags from artists map to the canonical taste', () {
      final profile = RecommendationService.buildProfile(
        pickedTastes: const [],
        liked: [song('1', artistId: 'x')],
        artistTags: {
          'x': ['rap'],
        },
      );
      expect(profile.tagWeights.keys, ['hiphop']);
    });

    test('artists ranked by likes (x2) and plays (x1)', () {
      final profile = RecommendationService.buildProfile(
        pickedTastes: const [],
        liked: [song('1', artistId: 'liked')],
        recent: [song('2', artistId: 'played'), song('3', artistId: 'played'), song('4', artistId: 'played')],
      );
      expect(profile.topArtistIds, ['played', 'liked']);
    });

    test('ties keep the user\'s pick order', () {
      final profile = RecommendationService.buildProfile(pickedTastes: ['rock', 'jazz', 'pop']);
      expect(profile.topTags, ['rock', 'jazz', 'pop']);
      expect(RecommendationService.buildProfile(pickedTastes: const []).isEmpty, isTrue);
    });
  });

  group('RecommendationService.blend', () {
    test('round-robin, unique, excludes and limits per artist', () {
      final a = [song('a1', artist: 'A'), song('a2', artist: 'A'), song('a3', artist: 'A')];
      final b = [song('b1', artist: 'B'), song('a1', artist: 'A'), song('b2', artist: 'B')];
      final result = RecommendationService.blend(
        [a, b],
        exclude: {'jm_b2'},
        perArtist: 2,
      );
      expect(result.map((s) => s.remoteId), ['a1', 'b1', 'a2']);
    });

    test('respects the limit and handles empty sources', () {
      final a = [for (var i = 0; i < 10; i++) song('$i', artist: 'X$i')];
      expect(RecommendationService.blend([a, const []], limit: 4), hasLength(4));
      expect(RecommendationService.blend(const []), isEmpty);
    });
  });

  group('JamendoRepository taste queries', () {
    test('tasteTracks falls back to the other tag parameter when empty', () async {
      final t = FakeTransport();
      t.handler = (uri) {
        final p = uri.queryParameters;
        // lofi only works with `tags` on the live API.
        if (p['tags'] == 'lofi') {
          return envelope([
            {'id': '1', 'name': 'Lofi one', 'artist_name': 'A', 'artist_id': '1'},
          ]);
        }
        return envelope([]);
      };
      final lofi = MusicTastes.byId('lofi')!;
      final songs = await repoFor(t).tasteTracks(lofi);
      expect(songs.single.title, 'Lofi one');
      // Preferred parameter first, then the fallback.
      final params = t.requests.map((u) => u.queryParameters.keys.contains('tags') ? 'tags' : 'fuzzytags');
      expect(params.first, lofi.useFuzzy ? 'fuzzytags' : 'tags');
    });

    test('artistTags reads /artists/musicinfo', () async {
      final t = FakeTransport()
        ..handler = (_) => envelope([
          {
            'id': '9',
            'musicinfo': {
              'tags': ['Pop', 'dance'],
            },
          },
        ]);
      expect(await repoFor(t).artistTags('9'), ['pop', 'dance']);
      expect(t.requests.single.path, endsWith('/artists/musicinfo/'));
    });

    test('artistTags tolerates missing musicinfo', () async {
      final t = FakeTransport()..handler = (_) => envelope([{'id': '9'}]);
      expect(await repoFor(t).artistTags('9'), isEmpty);
    });
  });

  group('AppSettings: login + Discover profile', () {
    late AppSettingsBloc bloc;

    setUp(() {
      final storage = MockStorage();
      when(() => storage.read(any())).thenReturn(null);
      when(() => storage.write(any(), any())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;
      bloc = AppSettingsBloc();
    });

    tearDown(() => bloc.close());

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('blank or missing names are not a complete profile', () {
      final s = AppSettingsState.initial();
      expect(s.isProfileComplete, isFalse);
      expect(s.copyWith(userName: '  ', nickName: 'x').isProfileComplete, isFalse);
      expect(s.copyWith(userName: 'Jo', nickName: 'Jo').isProfileComplete, isTrue);
    });

    test('Discover is ready only with profile + region + tastes', () {
      final base = AppSettingsState.initial().copyWith(userName: 'Jo', nickName: 'Jo');
      expect(base.isDiscoverReady, isFalse);
      final region = base.copyWith(musicCountry: 'IN', musicLanguages: ['ml']);
      expect(region.isDiscoverReady, isFalse);
      expect(region.copyWith(musicTastes: ['rock']).isDiscoverReady, isTrue);
      expect(
        region.copyWith(musicTastes: ['rock'], nickName: '').isDiscoverReady,
        isFalse,
        reason: 'not signed in',
      );
    });

    test('updateDiscoverProfile saves everything in one step', () async {
      bloc.add(const AppSettingsEvent.updateDiscoverProfile(
        nickName: '  Jesil ',
        country: 'in',
        languages: ['ml', 'ml', 'ta'],
        tastes: ['lofi', ' ', 'rock'],
      ));
      await settle();
      expect(bloc.state.nickName, 'Jesil');
      expect(bloc.state.userName, 'Jesil');
      expect(bloc.state.musicCountry, 'IN');
      expect(bloc.state.musicLanguages, ['ml', 'ta']);
      expect(bloc.state.musicTastes, ['lofi', 'rock']);
      expect(bloc.state.isDiscoverReady, isTrue);
    });

    test('updateDiscoverProfile keeps an existing name when none is given', () async {
      bloc.add(const AppSettingsEvent.updateUserProfile(userName: 'Full Name', nickName: 'Nick'));
      bloc.add(const AppSettingsEvent.updateDiscoverProfile(
        country: 'FR',
        languages: ['fr'],
        tastes: ['jazz'],
      ));
      await settle();
      expect(bloc.state.userName, 'Full Name');
      expect(bloc.state.nickName, 'Nick');
    });

    test('tastes persist and survive reset', () async {
      bloc.add(const AppSettingsEvent.updateMusicTastes(tastes: ['pop', 'pop', 'sad']));
      await settle();
      expect(bloc.state.musicTastes, ['pop', 'sad']);
      final json = bloc.toJson(bloc.state)!;
      expect(bloc.fromJson(json)!.musicTastes, ['pop', 'sad']);
      bloc.add(const AppSettingsEvent.resetToDefaults());
      await settle();
      expect(bloc.state.musicTastes, ['pop', 'sad']);
    });
  });
}
