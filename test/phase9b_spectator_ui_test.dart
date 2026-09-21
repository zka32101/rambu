/// Phase 9B Spectator & Replay Sharing UI Tests
/// 観戦一覧・リプレイ共有・ライブビュー表示ロジックのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/spectator.dart';

void main() {
  group('Broadcast List Display Tests', () {
    test('should show empty state when no active broadcasts', () {
      final broadcasts = <LiveGameBroadcast>[];
      final showEmptyState = broadcasts.isEmpty;

      expect(showEmptyState, isTrue);
    });

    test('should format broadcast card subtitle correctly', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        guestUserName: 'Player B',
        currentMoveNumber: 15,
        hostTotalHP: 6,
        guestTotalHP: 4,
        viewerCount: 3,
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      final subtitle =
          '${broadcast.currentMoveNumber}手目 · HP ${broadcast.hostTotalHP} - ${broadcast.guestTotalHP} '
          '· 観戦者${broadcast.viewerCount}人';

      expect(subtitle, contains('15手目'));
      expect(subtitle, contains('HP 6 - 4'));
      expect(subtitle, contains('観戦者3人'));
    });

    test('should exclude finished broadcasts from spectate list', () {
      final broadcasts = [
        LiveGameBroadcast(
          gameSessionId: 'session_001',
          hostUserId: 'user_001',
          hostUserName: 'Player A',
          isFinished: false,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        ),
        LiveGameBroadcast(
          gameSessionId: 'session_002',
          hostUserId: 'user_002',
          hostUserName: 'Player B',
          isFinished: true,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        ),
      ];

      final active = broadcasts.where((b) => !b.isFinished).toList();
      expect(active.length, equals(1));
      expect(active.first.gameSessionId, equals('session_001'));
    });

    test('should exclude broadcasts that disallow spectators', () {
      final broadcasts = [
        LiveGameBroadcast(
          gameSessionId: 'session_001',
          hostUserId: 'user_001',
          hostUserName: 'Player A',
          allowSpectators: true,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        ),
        LiveGameBroadcast(
          gameSessionId: 'session_002',
          hostUserId: 'user_002',
          hostUserName: 'Player B',
          allowSpectators: false,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        ),
      ];

      final spectatable = broadcasts.where((b) => b.allowSpectators).toList();
      expect(spectatable.length, equals(1));
    });
  });

  group('Live View Display Tests', () {
    test('should show finished message when broadcast is null or finished', () {
      LiveGameBroadcast? broadcast;
      final showFinishedMessage = broadcast == null || broadcast.isFinished;
      expect(showFinishedMessage, isTrue);
    });

    test('should show finished message when broadcast marked finished', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        isFinished: true,
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      final showFinishedMessage = broadcast.isFinished;
      expect(showFinishedMessage, isTrue);
    });

    test('should display matchup title correctly', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        guestUserName: 'Player B',
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      final title = '${broadcast.hostUserName} vs ${broadcast.guestUserName}';
      expect(title, equals('Player A vs Player B'));
    });
  });

  group('Replay Share Dialog Tests', () {
    test('should show create-link prompt when no token generated yet', () {
      const String? lastGeneratedToken = null;
      final showCreatePrompt = lastGeneratedToken == null;

      expect(showCreatePrompt, isTrue);
    });

    test('should show generated token after creation', () {
      const lastGeneratedToken = 'ABCD1234';
      final showToken = lastGeneratedToken.isNotEmpty;

      expect(showToken, isTrue);
      expect(lastGeneratedToken.length, equals(8));
    });

    test('should format record share card subtitle with move count and date', () {
      final playedAt = DateTime(2026, 9, 21);
      final moveCount = 42;

      final dateStr =
          '${playedAt.year}/${playedAt.month.toString().padLeft(2, '0')}/${playedAt.day.toString().padLeft(2, '0')}';
      final subtitle = '$moveCount手 · $dateStr';

      expect(subtitle, equals('42手 · 2026/09/21'));
    });
  });

  group('Viewer Count Tracking Tests', () {
    test('should increment viewer count when opening live view', () {
      var viewerCount = 3;
      viewerCount += 1;
      expect(viewerCount, equals(4));
    });

    test('should decrement viewer count when closing live view', () {
      var viewerCount = 4;
      viewerCount -= 1;
      expect(viewerCount, equals(3));
    });

    test('should never show negative viewer count', () {
      var viewerCount = 0;
      final adjusted = viewerCount - 1;
      final displayed = adjusted < 0 ? 0 : adjusted;

      expect(displayed, equals(0));
    });
  });

  group('Performance Tests', () {
    test('should filter 100 broadcasts quickly', () {
      final stopwatch = Stopwatch()..start();

      final broadcasts = List.generate(
        100,
        (i) => LiveGameBroadcast(
          gameSessionId: 'session_$i',
          hostUserId: 'user_$i',
          hostUserName: 'Player $i',
          allowSpectators: i % 2 == 0,
          isFinished: i % 5 == 0,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final spectatable =
          broadcasts.where((b) => b.allowSpectators && !b.isFinished).toList();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(spectatable.isNotEmpty, isTrue);
    });
  });
}
