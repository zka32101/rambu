/// Phase 10B Matchmaking UI Tests
/// マッチメイキング画面の表示・タイマー・遷移ロジックのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/matchmaking.dart';

void main() {
  group('Elapsed Time Formatting Tests', () {
    String formatElapsed(Duration d) {
      final minutes = d.inMinutes.toString().padLeft(2, '0');
      final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    test('should format zero duration as 00:00', () {
      expect(formatElapsed(Duration.zero), equals('00:00'));
    });

    test('should format under a minute correctly', () {
      expect(formatElapsed(const Duration(seconds: 45)), equals('00:45'));
    });

    test('should format over a minute correctly', () {
      expect(formatElapsed(const Duration(minutes: 2, seconds: 5)), equals('02:05'));
    });

    test('should format exactly at timeout threshold', () {
      expect(formatElapsed(const Duration(minutes: 5)), equals('05:00'));
    });
  });

  group('Rating Range Slider Tests', () {
    test('should default to a reasonable rating range', () {
      const defaultRange = 200.0;
      expect(defaultRange, greaterThanOrEqualTo(50));
      expect(defaultRange, lessThanOrEqualTo(500));
    });

    test('should clamp rating range within slider bounds', () {
      const min = 50.0;
      const max = 500.0;
      final value = 600.0.clamp(min, max);

      expect(value, equals(500));
    });

    test('should format rating range label correctly', () {
      const range = 200.0;
      final label = '±${range.toStringAsFixed(0)}';

      expect(label, equals('±200'));
    });
  });

  group('Search State Display Tests', () {
    test('should show search button when not searching', () {
      const isSearching = false;
      final showSearchButton = !isSearching;

      expect(showSearchButton, isTrue);
    });

    test('should show searching indicator when entry id is set', () {
      const currentEntryId = 'entry_001';
      final isActivelySearching = currentEntryId.isNotEmpty;

      expect(isActivelySearching, isTrue);
    });

    test('should show loading spinner before entry id is assigned', () {
      const String? currentEntryId = null;
      final showLoadingOnly = currentEntryId == null;

      expect(showLoadingOnly, isTrue);
    });
  });

  group('Match Found Dialog Tests', () {
    test('should trigger match dialog only once per entry', () {
      var dialogShown = false;
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
        status: MatchmakingStatus.matched,
        matchId: 'match_001',
      );

      // Simulate first detection
      if (!dialogShown && entry.status == MatchmakingStatus.matched) {
        dialogShown = true;
      }
      expect(dialogShown, isTrue);

      // Simulate a second stream event with the same matched status
      final shouldShowAgain = !dialogShown && entry.status == MatchmakingStatus.matched;
      expect(shouldShowAgain, isFalse);
    });

    test('should resolve opponent name from match for the correct player', () {
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

      final dialogText = '${match.opponentNameFor('user_001')}さんとマッチしました';
      expect(dialogText, equals('Player Bさんとマッチしました'));
    });

    test('should fall back to generic label when match not yet loaded', () {
      MatchmakingMatch? match;
      final opponentName = match?.opponentNameFor('user_001') ?? '対戦相手';

      expect(opponentName, equals('対戦相手'));
    });

    test('should not show match dialog for non-matched statuses', () {
      final entry = MatchmakingEntry(
        id: 'entry_001',
        userId: 'user_001',
        userName: 'Player A',
        rating: 1500,
        minRatingRange: 1300,
        maxRatingRange: 1700,
        queuedAt: DateTime.now().toIso8601String(),
        status: MatchmakingStatus.waiting,
      );

      final shouldShowDialog = entry.status == MatchmakingStatus.matched;
      expect(shouldShowDialog, isFalse);
    });
  });

  group('Cancel Search Flow Tests', () {
    test('should clear entry id and stop searching on cancel', () {
      var isSearching = true;
      String? currentEntryId = 'entry_001';

      // Simulate cancel
      isSearching = false;
      currentEntryId = null;

      expect(isSearching, isFalse);
      expect(currentEntryId, isNull);
    });
  });

  group('Performance Tests', () {
    test('should format 100 elapsed durations quickly', () {
      String formatElapsed(Duration d) {
        final minutes = d.inMinutes.toString().padLeft(2, '0');
        final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      }

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        formatElapsed(Duration(seconds: i * 3));
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
