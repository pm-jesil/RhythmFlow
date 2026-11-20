import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/utils/models/song/song_model.dart';
import 'package:rhythmflow/utils/services/song_cleanup_service.dart';

import 'library_test_utils.dart';

void main() {
  group('normalizeTitle (Unicode aware)', () {
    test('keeps Malayalam, Tamil, Hindi, Arabic and Japanese letters', () {
      expect(SongCleanupService.normalizeTitle('മഴ'), 'മഴ');
      expect(SongCleanupService.normalizeTitle('கண்ணான கண்ணே'), 'கண்ணான கண்ணே');
      expect(SongCleanupService.normalizeTitle('तुम ही हो'), 'तुम ही हो');
      expect(SongCleanupService.normalizeTitle('حبيبي'), 'حبيبي');
      expect(SongCleanupService.normalizeTitle('夜に駆ける'), '夜に駆ける');
    });

    test('keeps combining marks (Indic vowel signs) so words stay distinct', () {
      // Without \p{M} these two would both become "ക ക".
      expect(
        SongCleanupService.normalizeTitle('കാറ്റ്'),
        isNot(SongCleanupService.normalizeTitle('കറ്റ')),
      );
    });

    test('lower-cases, strips punctuation and collapses whitespace', () {
      expect(
        SongCleanupService.normalizeTitle('  Hello,   World!!  '),
        'hello world',
      );
    });

    test('does NOT remove words such as live / remix / I / you', () {
      expect(SongCleanupService.normalizeTitle('Song (Live)'), 'song live');
      expect(SongCleanupService.normalizeTitle('Here I Am'), 'here i am');
    });

    test('returns empty for an empty or punctuation-only title', () {
      expect(SongCleanupService.normalizeTitle(''), '');
      expect(SongCleanupService.normalizeTitle('!!!'), '');
    });
  });

  group('isSameRecording', () {
    test('same title, artist and duration is a duplicate', () {
      final a = testSong(id: 'a', title: 'Hello', artists: ['Adele']);
      final b = testSong(id: 'b', title: 'hello', artists: ['adele']);
      expect(SongCleanupService.isSameRecording(a, b), isTrue);
    });

    test('same title by different artists is NOT a duplicate', () {
      final a = testSong(id: 'a', title: 'Hello', artists: ['Adele']);
      final b = testSong(id: 'b', title: 'Hello', artists: ['Lionel Richie']);
      expect(SongCleanupService.isSameRecording(a, b), isFalse);
    });

    test('live / remix versions are NOT duplicates of the original', () {
      final original = testSong(id: 'a', title: 'Song');
      expect(
        SongCleanupService.isSameRecording(
          original,
          testSong(id: 'b', title: 'Song (Live)'),
        ),
        isFalse,
      );
      expect(
        SongCleanupService.isSameRecording(
          original,
          testSong(id: 'c', title: 'Song - Remix'),
        ),
        isFalse,
      );
    });

    test('durations within 2 s match, further apart do not', () {
      final a = testSong(
        id: 'a',
        title: 'Same',
        duration: const Duration(seconds: 200),
      );
      expect(
        SongCleanupService.isSameRecording(
          a,
          testSong(
            id: 'b',
            title: 'Same',
            duration: const Duration(seconds: 202),
          ),
        ),
        isTrue,
      );
      expect(
        SongCleanupService.isSameRecording(
          a,
          testSong(
            id: 'c',
            title: 'Same',
            duration: const Duration(seconds: 203),
          ),
        ),
        isFalse,
      );
    });

    test('unknown (zero) duration is never treated as a duplicate', () {
      final a = testSong(id: 'a', title: 'Same', duration: Duration.zero);
      final b = testSong(id: 'b', title: 'Same', duration: Duration.zero);
      expect(SongCleanupService.isSameRecording(a, b), isFalse);
    });

    test('titles that normalize to empty are never merged', () {
      final a = testSong(id: 'a', title: '???');
      final b = testSong(id: 'b', title: '!!!');
      expect(SongCleanupService.duplicateKey(a), isNull);
      expect(SongCleanupService.isSameRecording(a, b), isFalse);
    });
  });

  group('removeDuplicateSongsByTitle (regression for lost songs)', () {
    test('5 different Malayalam songs are all kept', () {
      final songs = [
        testSong(id: '1', title: 'മഴ', artists: ['K S Chithra']),
        testSong(id: '2', title: 'പൂമുത്തോളെ', artists: ['Vijay Yesudas']),
        testSong(id: '3', title: 'ജീവാംശമായ്', artists: ['K S Harishankar']),
        testSong(id: '4', title: 'മലരേ', artists: ['Vijay Yesudas']),
        testSong(id: '5', title: 'ഉയിരിൻ', artists: ['Sithara']),
      ];
      expect(SongCleanupService.removeDuplicateSongsByTitle(songs), hasLength(5));
    });

    test('Hindi and Tamil songs are all kept', () {
      final songs = [
        testSong(id: '1', title: 'तुम ही हो', artists: ['Arijit Singh']),
        testSong(id: '2', title: 'कबीरा', artists: ['Tochi Raina']),
        testSong(id: '3', title: 'கண்ணான கண்ணே', artists: ['Sid Sriram']),
        testSong(id: '4', title: 'வாத்தி கம்மிங்', artists: ['Anirudh']),
      ];
      expect(SongCleanupService.removeDuplicateSongsByTitle(songs), hasLength(4));
    });

    test('stop-word-only titles are kept separately', () {
      final songs = [
        testSong(id: '1', title: 'Here I Am', artists: ['A']),
        testSong(id: '2', title: 'What Do You Want From Me', artists: ['B']),
        testSong(id: '3', title: 'You and I', artists: ['C']),
      ];
      expect(SongCleanupService.removeDuplicateSongsByTitle(songs), hasLength(3));
    });

    test('a real duplicate file (copy) is removed, first one wins', () {
      final songs = [
        testSong(id: '1', title: 'Hello', artists: ['Adele'], path: '/a/1.mp3'),
        testSong(id: '2', title: 'Hello', artists: ['Adele'], path: '/b/1.mp3'),
      ];
      final result = SongCleanupService.removeDuplicateSongsByTitle(songs);
      expect(result.map((s) => s.id), ['1']);
    });
  });

  group('filterDuplicatesAgainst', () {
    test('existing library songs always win over new copies', () {
      final existing = [testSong(id: 'old', title: 'Hello', artists: ['Adele'])];
      final candidates = [
        testSong(id: 'new', title: 'Hello', artists: ['Adele'], path: '/x.mp3'),
      ];
      final result = SongCleanupService.filterDuplicatesAgainst(
        existing,
        candidates,
      );
      expect(result.accepted, isEmpty);
      expect(result.dropped.map((s) => s.id), ['new']);
    });

    test('drops candidates whose id or path is already present', () {
      final existing = [testSong(id: 'a', path: '/p.mp3')];
      final result = SongCleanupService.filterDuplicatesAgainst(existing, [
        testSong(id: 'a', title: 'Other', path: '/q.mp3'),
        testSong(id: 'b', title: 'Other 2', path: '/p.mp3'),
      ]);
      expect(result.accepted, isEmpty);
      expect(result.dropped, hasLength(2));
    });

    test('result is independent of how candidates are batched', () {
      // The old scanner removed duplicates per batch of 10 files, so a
      // duplicate in another batch survived and counts were inconsistent.
      final songs = <Song>[
        for (var i = 0; i < 25; i++)
          testSong(id: 'u$i', title: 'Unique $i', path: '/m/u$i.mp3'),
      ];
      // Copies of songs 0, 9 and 20 placed in different "batches".
      songs.insert(12, testSong(id: 'd0', title: 'Unique 0', path: '/d/0.mp3'));
      songs.insert(3, testSong(id: 'd9', title: 'Unique 9', path: '/d/9.mp3'));
      songs.add(testSong(id: 'd20', title: 'Unique 20', path: '/d/20.mp3'));

      final allAtOnce = SongCleanupService.filterDuplicatesAgainst(
        const [],
        songs,
      ).accepted;

      final batched = <Song>[];
      for (var i = 0; i < songs.length; i += 10) {
        final batch = songs.skip(i).take(10).toList();
        batched.addAll(
          SongCleanupService.filterDuplicatesAgainst(batched, batch).accepted,
        );
      }

      expect(allAtOnce, hasLength(25));
      expect(batched, hasLength(25));
      expect(
        batched.map((s) => s.id).toSet(),
        equals(allAtOnce.map((s) => s.id).toSet()),
      );
    });
  });

  group('fuzzy matching stays safe', () {
    test('requires same artist and duration', () {
      final a = testSong(id: 'a', title: 'Shape of You', artists: ['Ed Sheeran']);
      final b = testSong(id: 'b', title: 'Shape of You', artists: ['Cover Band']);
      expect(SongCleanupService.areSongsSimilar(a, b), isFalse);
      expect(SongCleanupService.removeDuplicatesSongsFuzzy([a, b]), hasLength(2));
    });

    test('tolerates a small typo for the same recording', () {
      final a = testSong(id: 'a', title: 'Bohemian Rhapsody', artists: ['Queen']);
      final b = testSong(id: 'b', title: 'Bohemian Rhapsodyy', artists: ['Queen']);
      expect(SongCleanupService.areSongsSimilar(a, b), isTrue);
    });
  });
}
