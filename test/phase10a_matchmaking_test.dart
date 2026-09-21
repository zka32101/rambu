/// Phase 10A Matchmaking Tests
/// レーティングベース自動マッチングのテスト
/// (shogi_app の matching_service.dart を参考に実装)

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/matchmaking.dart';

void main() {
  group('MatchmakingEntry Model Tests', () {
    test('should create entry with waiting status by default', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      expect(entry.status, equals(MatchmakingStatus.waiting));
      expect(entry.matchedWithUserId, isNull);
      expect(entry.matchId, isNull);
    });

    test('should correctly evaluate rating range inclusion', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      expect(entry.canMatchRating(1400), isTrue);
      expect(entry.canMatchRating(1300), isTrue); // boundary
      expect(entry.canMatchRating(1700), isTrue); // boundary
      expect(entry.canMatchRating(1200), isFalse);
      expect(entry.canMatchRating(1800), isFalse);
    });

    test('should calculate rating distance correctly', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      expect(entry.ratingDistanceTo(1550), equals(50));
      expect(entry.ratingDistanceTo(1450), equals(50));
      expect(entry.ratingDistanceTo(1500), equals(0));
    });

    test('should convert to JSON and back', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: '2026-09-21T10:00:00Z',
        status: MatchmakingStatus.matched,
        matchedWithUserId: 'user_002',
        matchId: 'match_001',
      );

      final json = entry.toJson();
      final restored = MatchmakingEntry.fromJson(json);

      expect(restored.status, equals(MatchmakingStatus.matched));
      expect(restored.matchedWithUserId, equals('user_002'));
      expect(restored.matchId, equals('match_001'));
    });

    test('should copyWith updated status', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      final updated = entry.copyWith(
        status: MatchmakingStatus.cancelled,
      );

      expect(updated.status, equals(MatchmakingStatus.cancelled));
      expect(updated.userId, equals(entry.userId));
    });

    test('should have all matchmaking statuses with Japanese labels', () {
      expect(MatchmakingStatus.values.length, equals(4));
      expect(MatchmakingStatus.waiting.label, equals('待機中'));
      expect(MatchmakingStatus.matched.label, equals('マッチ成立'));
      expect(MatchmakingStatus.expired.label, equals('期限切れ'));
    });
  });

  group('MatchmakingMatch Model Tests', () {
    test('should create match with no game session initially', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1500,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1520,
        matchedAt: DateTime.now().toIso8601String(),
      );

      expect(match.gameSessionId, isNull);
    });

    test('should calculate rating gap correctly', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1600,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1450,
        matchedAt: DateTime.now().toIso8601String(),
      );

      expect(match.ratingGap, equals(150));
    });

    test('should return correct opponent name for each player', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1500,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1520,
        matchedAt: DateTime.now().toIso8601String(),
      );

      expect(match.opponentNameFor('user_001'), equals('Player B'));
      expect(match.opponentNameFor('user_002'), equals('Player A'));
    });

    test('should return correct opponent rating for each player', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1500,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1520,
        matchedAt: DateTime.now().toIso8601String(),
      );

      expect(match.opponentRatingFor('user_001'), equals(1520));
      expect(match.opponentRatingFor('user_002'), equals(1500));
    });

    test('should convert to JSON and back', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1500,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1520,
        matchedAt: '2026-09-21T10:00:00Z',
        gameSessionId: 'session_001',
      );

      final json = match.toJson();
      final restored = MatchmakingMatch.fromJson(json);

      expect(restored.player1Name, equals('Player A'));
      expect(restored.gameSessionId, equals('session_001'));
    });

    test('should copyWith attached game session', () {
      final match = MatchmakingMatch(
        id: 'match_001',
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Rating: 1500,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Rating: 1520,
        matchedAt: DateTime.now().toIso8601String(),
      );

      final updated = match.copyWith(gameSessionId: 'session_002');
      expect(updated.gameSessionId, equals('session_002'));
      expect(updated.id, equals(match.id));
    });
  });

  group('Matchmaking Logic Integration Tests', () {
    test('should find bidirectionally compatible candidates', () {
      final seeker = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      final candidates = [
        MatchmakingEntry(
          id: 'entry_002',
          userId: 'user_002',
          userName: 'Player B',
          rating: 1550,
          minRatingRange: 1350,
          maxRatingRange: 1750,
          queuedAt: DateTime.now().toIso8601String(),
        ),
        // Rating within seeker's range, but seeker not within this one's range
        MatchmakingEntry(
          id: 'entry_003',
          userId: 'user_003',
          userName: 'Player C',
          rating: 1650,
          minRatingRange: 1600, // seeker's 1500 is below this
          maxRatingRange: 1900,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      ];

      final compatible = candidates
          .where((c) => seeker.canMatchRating(c.rating) && c.canMatchRating(seeker.rating))
          .toList();

      expect(compatible.length, equals(1));
      expect(compatible.first.userId, equals('user_002'));
    });

    test('should prioritize closest rating among multiple candidates', () {
      final seeker = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1000,
        maxRatingRange: 2000,
        queuedAt: DateTime.now().toIso8601String(),
      );

      final candidates = [
        MatchmakingEntry(
          id: 'entry_002',
          userId: 'user_002',
          userName: 'Far Player',
          rating: 1800,
          minRatingRange: 1000,
          maxRatingRange: 2000,
          queuedAt: DateTime.now().toIso8601String(),
        ),
        MatchmakingEntry(
          id: 'entry_003',
          userId: 'user_003',
          userName: 'Close Player',
          rating: 1520,
          minRatingRange: 1000,
          maxRatingRange: 2000,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      ];

      candidates.sort((a, b) =>
          seeker.ratingDistanceTo(a.rating).compareTo(seeker.ratingDistanceTo(b.rating)));

      expect(candidates.first.userName, equals('Close Player'));
    });

    test('should exclude self from candidate pool', () {
      const myUserId = 'user_001';
      final entries = [
        MatchmakingEntry(
          id: 'entry_001',
          userId: myUserId,
          userName: 'Me',
          rating: 1500,
          minRatingRange: 1300,
          maxRatingRange: 1700,
          queuedAt: DateTime.now().toIso8601String(),
        ),
        MatchmakingEntry(
          id: 'entry_002',
          userId: 'user_002',
          userName: 'Player B',
          rating: 1500,
          minRatingRange: 1300,
          maxRatingRange: 1700,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      ];

      final candidates = entries.where((e) => e.userId != myUserId).toList();
      expect(candidates.length, equals(1));
      expect(candidates.first.userId, equals('user_002'));
    });

    test('should only consider waiting-status entries as candidates', () {
      final entries = [
        MatchmakingEntry(
          id: 'entry_001',
          userId: 'user_001',
          userName: 'Player A',
          rating: 1500,
          minRatingRange: 1300,
          maxRatingRange: 1700,
          queuedAt: DateTime.now().toIso8601String(),
          status: MatchmakingStatus.waiting,
        ),
        MatchmakingEntry(
          id: 'entry_002',
          userId: 'user_002',
          userName: 'Player B',
          rating: 1500,
          minRatingRange: 1300,
          maxRatingRange: 1700,
          queuedAt: DateTime.now().toIso8601String(),
          status: MatchmakingStatus.matched,
        ),
      ];

      final waiting = entries.where((e) => e.status == MatchmakingStatus.waiting).toList();
      expect(waiting.length, equals(1));
    });
  });

  group('Performance Tests', () {
    test('should filter and sort 200 candidates quickly', () {
      final stopwatch = Stopwatch()..start();

      final seeker = MatchmakingEntry(
        id: 'entry_seeker',
        userId: 'user_seeker',
        userName: 'Seeker',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
      );

      final candidates = List.generate(
        200,
        (i) => MatchmakingEntry(
          id: 'entry_$i',
          userId: 'user_$i',
          userName: 'Player $i',
          rating: 1200 + (i * 5).toDouble(),
          minRatingRange: 1000 + (i * 5).toDouble(),
          maxRatingRange: 1800 + (i * 5).toDouble(),
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );

      final compatible = candidates
          .where((c) =>
              seeker.canMatchRating(c.rating) && c.canMatchRating(seeker.rating))
          .toList()
        ..sort((a, b) =>
            seeker.ratingDistanceTo(a.rating).compareTo(seeker.ratingDistanceTo(b.rating)));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(compatible, isNotEmpty);
    });
  });
}
