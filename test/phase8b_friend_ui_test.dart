/// Phase 8B Friend & Social UI Tests
/// フレンド画面・対戦招待・アクティビティフィード表示ロジックのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/friend.dart';
import 'package:rambu_shogi/models/user_profile.dart';

void main() {
  group('Friends List Display Tests', () {
    test('should display friends sorted by online status first', () {
      final friends = [
        Friendship(
          friendId: 'user_001',
          friendName: 'Offline Player',
          becameFriendsAt: DateTime.now().toIso8601String(),
          isOnline: false,
        ),
        Friendship(
          friendId: 'user_002',
          friendName: 'Online Player',
          becameFriendsAt: DateTime.now().toIso8601String(),
          isOnline: true,
        ),
      ];

      final sorted = [...friends]..sort((a, b) => (b.isOnline ? 1 : 0) - (a.isOnline ? 1 : 0));

      expect(sorted.first.isOnline, isTrue);
      expect(sorted.first.friendName, equals('Online Player'));
    });

    test('should show empty state message when no friends', () {
      final friends = <Friendship>[];
      final showEmptyState = friends.isEmpty;

      expect(showEmptyState, isTrue);
    });

    test('should format head-to-head record for display', () {
      final friend = Friendship(
        friendId: 'user_001',
        friendName: 'Player A',
        becameFriendsAt: DateTime.now().toIso8601String(),
        headToHeadWins: 8,
        headToHeadLosses: 2,
      );

      final displayText =
          '対戦成績: ${friend.headToHeadWins}勝${friend.headToHeadLosses}敗 '
          '(勝率${(friend.headToHeadWinRate * 100).toStringAsFixed(0)}%)';

      expect(displayText, contains('8勝2敗'));
      expect(displayText, contains('80%'));
    });

    test('should not show win rate when no games played', () {
      final friend = Friendship(
        friendId: 'user_001',
        friendName: 'Player A',
        becameFriendsAt: DateTime.now().toIso8601String(),
      );

      final shouldShowWinRate = friend.totalHeadToHeadGames > 0;
      expect(shouldShowWinRate, isFalse);
    });
  });

  group('Friend Request UI Tests', () {
    test('should count pending incoming requests for badge', () {
      final requests = [
        FriendRequest(
          id: 'req_1',
          fromUserId: 'user_1',
          fromUserName: 'A',
          toUserId: 'me',
          toUserName: 'Me',
          sentAt: DateTime.now().toIso8601String(),
        ),
        FriendRequest(
          id: 'req_2',
          fromUserId: 'user_2',
          fromUserName: 'B',
          toUserId: 'me',
          toUserName: 'Me',
          status: FriendRequestStatus.accepted,
          sentAt: DateTime.now().toIso8601String(),
        ),
      ];

      final pendingCount =
          requests.where((r) => r.status == FriendRequestStatus.pending).length;

      expect(pendingCount, equals(1));
    });

    test('should filter only incoming requests directed at current user', () {
      const myUserId = 'me';
      final allRequests = [
        FriendRequest(
          id: 'req_1',
          fromUserId: 'user_1',
          fromUserName: 'A',
          toUserId: myUserId,
          toUserName: 'Me',
          sentAt: DateTime.now().toIso8601String(),
        ),
        FriendRequest(
          id: 'req_2',
          fromUserId: myUserId,
          fromUserName: 'Me',
          toUserId: 'user_3',
          toUserName: 'C',
          sentAt: DateTime.now().toIso8601String(),
        ),
      ];

      final incoming = allRequests.where((r) => r.toUserId == myUserId).toList();
      expect(incoming.length, equals(1));
      expect(incoming.first.fromUserName, equals('A'));
    });
  });

  group('Battle Invite UI Tests', () {
    test('should exclude expired invites from display list', () {
      final now = DateTime.now();
      final invites = [
        BattleInvite(
          id: 'invite_1',
          fromUserId: 'user_1',
          fromUserName: 'A',
          toUserId: 'me',
          toUserName: 'Me',
          createdAt: now.subtract(const Duration(minutes: 20)).toIso8601String(),
          expiresAt: now.subtract(const Duration(minutes: 10)).toIso8601String(),
        ),
        BattleInvite(
          id: 'invite_2',
          fromUserId: 'user_2',
          fromUserName: 'B',
          toUserId: 'me',
          toUserName: 'Me',
          createdAt: now.toIso8601String(),
          expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
        ),
      ];

      final valid = invites.where((invite) => !invite.isExpiredAt(now)).toList();

      expect(valid.length, equals(1));
      expect(valid.first.id, equals('invite_2'));
    });

    test('should display invite difficulty label', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_1',
        fromUserId: 'user_1',
        fromUserName: 'A',
        toUserId: 'me',
        toUserName: 'Me',
        difficulty: '上級',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      final subtitle = '難易度: ${invite.difficulty}';
      expect(subtitle, equals('難易度: 上級'));
    });

    test('should show accept/decline actions only while pending', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_1',
        fromUserId: 'user_1',
        fromUserName: 'A',
        toUserId: 'me',
        toUserName: 'Me',
        status: BattleInviteStatus.accepted,
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      final showActions = invite.status == BattleInviteStatus.pending;
      expect(showActions, isFalse);
    });
  });

  group('User Search UI Tests', () {
    test('should not query when search field is empty', () {
      const searchQuery = '';
      final shouldQuery = searchQuery.trim().isNotEmpty;

      expect(shouldQuery, isFalse);
    });

    test('should display search results with rank and win rate', () {
      final opponent = GameOpponent(
        userId: 'user_001',
        displayName: 'Player A',
        rank: '中級',
        winRate: 0.65,
        totalGames: 40,
      );

      final subtitle = '${opponent.rank} · 勝率${(opponent.winRate * 100).toStringAsFixed(0)}%';
      expect(subtitle, equals('中級 · 勝率65%'));
    });

    test('should exclude self from search results', () {
      const myUserId = 'me';
      final results = [
        GameOpponent(
          userId: 'me',
          displayName: 'Myself',
          rank: '中級',
          winRate: 0.5,
          totalGames: 10,
        ),
        GameOpponent(
          userId: 'user_002',
          displayName: 'Other Player',
          rank: '中級',
          winRate: 0.5,
          totalGames: 10,
        ),
      ];

      final filtered = results.where((r) => r.userId != myUserId).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.displayName, equals('Other Player'));
    });
  });

  group('Friend Activity Feed UI Tests', () {
    test('should sort activity feed by most recent first', () {
      final activities = [
        FriendActivity(
          id: 'a1',
          friendId: 'user_1',
          friendName: 'A',
          type: FriendActivityType.gameWon,
          description: 'Won a game',
          occurredAt: '2026-09-01T10:00:00Z',
        ),
        FriendActivity(
          id: 'a2',
          friendId: 'user_2',
          friendName: 'B',
          type: FriendActivityType.rankUp,
          description: 'Ranked up',
          occurredAt: '2026-09-10T10:00:00Z',
        ),
      ];

      final sorted = [...activities]
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      expect(sorted.first.id, equals('a2'));
    });

    test('should render activity type label correctly', () {
      final activity = FriendActivity(
        id: 'a1',
        friendId: 'user_1',
        friendName: 'A',
        type: FriendActivityType.tournamentJoined,
        description: 'Joined a tournament',
        occurredAt: DateTime.now().toIso8601String(),
      );

      expect(activity.type.label, equals('トーナメント参加'));
    });
  });

  group('Performance Tests', () {
    test('should render 100 friends list quickly', () {
      final stopwatch = Stopwatch()..start();

      final friends = List.generate(
        100,
        (i) => Friendship(
          friendId: 'user_$i',
          friendName: 'Player $i',
          becameFriendsAt: DateTime.now().toIso8601String(),
          headToHeadWins: i % 10,
          headToHeadLosses: (i + 3) % 10,
          isOnline: i % 3 == 0,
        ),
      );

      final sorted = [...friends]..sort((a, b) => (b.isOnline ? 1 : 0) - (a.isOnline ? 1 : 0));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(sorted.length, equals(100));
    });

    test('should filter 200 search results quickly', () {
      final stopwatch = Stopwatch()..start();

      final results = List.generate(
        200,
        (i) => GameOpponent(
          userId: 'user_$i',
          displayName: 'Player $i',
          rank: i % 3 == 0 ? '上級' : '中級',
          winRate: (i % 100) / 100,
          totalGames: i,
        ),
      );

      final filtered = results.where((r) => r.rank == '上級').toList();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(filtered.isNotEmpty, isTrue);
    });
  });
}
