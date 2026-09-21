/// Phase 8A Friend & Social System Tests
/// フレンド申請・フレンド関係・対戦招待・アクティビティのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/friend.dart';

void main() {
  group('FriendRequest Model Tests', () {
    test('should create friend request with pending status by default', () {
      final request = FriendRequest(
        id: 'req_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        sentAt: DateTime.now().toIso8601String(),
      );

      expect(request.status, equals(FriendRequestStatus.pending));
      expect(request.fromUserId, equals('user_001'));
      expect(request.toUserId, equals('user_002'));
      expect(request.respondedAt, isNull);
    });

    test('should convert to JSON and back', () {
      final request = FriendRequest(
        id: 'req_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        status: FriendRequestStatus.accepted,
        sentAt: '2026-09-01T10:00:00Z',
        respondedAt: '2026-09-01T11:00:00Z',
      );

      final json = request.toJson();
      final restored = FriendRequest.fromJson(json);

      expect(restored.id, equals(request.id));
      expect(restored.status, equals(FriendRequestStatus.accepted));
      expect(restored.respondedAt, equals('2026-09-01T11:00:00Z'));
    });

    test('should copyWith status update', () {
      final request = FriendRequest(
        id: 'req_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        sentAt: DateTime.now().toIso8601String(),
      );

      final updated = request.copyWith(
        status: FriendRequestStatus.declined,
        respondedAt: DateTime.now().toIso8601String(),
      );

      expect(updated.status, equals(FriendRequestStatus.declined));
      expect(updated.respondedAt, isNotNull);
      expect(updated.fromUserId, equals(request.fromUserId));
    });

    test('should have all friend request statuses', () {
      expect(FriendRequestStatus.values.length, equals(4));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.pending));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.blocked));
    });

    test('should provide Japanese labels for statuses', () {
      expect(FriendRequestStatus.pending.label, equals('申請中'));
      expect(FriendRequestStatus.accepted.label, equals('承認済み'));
      expect(FriendRequestStatus.declined.label, equals('拒否済み'));
      expect(FriendRequestStatus.blocked.label, equals('ブロック中'));
    });
  });

  group('Friendship Model Tests', () {
    test('should create friendship with default zero record', () {
      final friendship = Friendship(
        friendId: 'user_002',
        friendName: 'Player B',
        becameFriendsAt: DateTime.now().toIso8601String(),
      );

      expect(friendship.headToHeadWins, equals(0));
      expect(friendship.headToHeadLosses, equals(0));
      expect(friendship.totalHeadToHeadGames, equals(0));
      expect(friendship.headToHeadWinRate, equals(0.0));
      expect(friendship.isOnline, isFalse);
    });

    test('should calculate head-to-head win rate correctly', () {
      final friendship = Friendship(
        friendId: 'user_002',
        friendName: 'Player B',
        becameFriendsAt: DateTime.now().toIso8601String(),
        headToHeadWins: 7,
        headToHeadLosses: 3,
      );

      expect(friendship.totalHeadToHeadGames, equals(10));
      expect(friendship.headToHeadWinRate, equals(0.7));
    });

    test('should convert to JSON and back', () {
      final friendship = Friendship(
        friendId: 'user_002',
        friendName: 'Player B',
        friendProfileImageUrl: 'https://example.com/avatar.png',
        becameFriendsAt: '2026-09-01T10:00:00Z',
        headToHeadWins: 5,
        headToHeadLosses: 2,
        lastPlayedAt: '2026-09-10T10:00:00Z',
        isOnline: true,
      );

      final json = friendship.toJson();
      final restored = Friendship.fromJson(json);

      expect(restored.friendId, equals('user_002'));
      expect(restored.headToHeadWins, equals(5));
      expect(restored.isOnline, isTrue);
    });

    test('should copyWith updated head-to-head record', () {
      final friendship = Friendship(
        friendId: 'user_002',
        friendName: 'Player B',
        becameFriendsAt: DateTime.now().toIso8601String(),
        headToHeadWins: 3,
        headToHeadLosses: 1,
      );

      final updated = friendship.copyWith(
        headToHeadWins: 4,
        lastPlayedAt: DateTime.now().toIso8601String(),
      );

      expect(updated.headToHeadWins, equals(4));
      expect(updated.headToHeadLosses, equals(1));
      expect(updated.lastPlayedAt, isNotNull);
    });
  });

  group('BattleInvite Model Tests', () {
    test('should create battle invite with pending status by default', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      expect(invite.status, equals(BattleInviteStatus.pending));
      expect(invite.difficulty, equals('中級'));
      expect(invite.gameSessionId, isNull);
    });

    test('should detect expired invite', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        createdAt: now.subtract(const Duration(minutes: 20)).toIso8601String(),
        expiresAt: now.subtract(const Duration(minutes: 10)).toIso8601String(),
      );

      expect(invite.isExpiredAt(now), isTrue);
    });

    test('should detect non-expired invite', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      expect(invite.isExpiredAt(now), isFalse);
    });

    test('should convert to JSON and back', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        difficulty: '上級',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      final json = invite.toJson();
      final restored = BattleInvite.fromJson(json);

      expect(restored.difficulty, equals('上級'));
      expect(restored.status, equals(BattleInviteStatus.pending));
    });

    test('should copyWith accepted status and game session', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      final updated = invite.copyWith(
        status: BattleInviteStatus.accepted,
        gameSessionId: 'session_001',
      );

      expect(updated.status, equals(BattleInviteStatus.accepted));
      expect(updated.gameSessionId, equals('session_001'));
    });

    test('should have all battle invite statuses', () {
      expect(BattleInviteStatus.values.length, equals(5));
      expect(BattleInviteStatus.values, contains(BattleInviteStatus.expired));
      expect(BattleInviteStatus.values, contains(BattleInviteStatus.cancelled));
    });
  });

  group('FriendActivity Model Tests', () {
    test('should create friend activity', () {
      final activity = FriendActivity(
        id: 'activity_001',
        friendId: 'user_002',
        friendName: 'Player B',
        type: FriendActivityType.gameWon,
        description: 'Player Bさんが対局に勝利しました',
        occurredAt: DateTime.now().toIso8601String(),
      );

      expect(activity.type, equals(FriendActivityType.gameWon));
      expect(activity.friendName, equals('Player B'));
    });

    test('should convert to JSON and back', () {
      final activity = FriendActivity(
        id: 'activity_001',
        friendId: 'user_002',
        friendName: 'Player B',
        type: FriendActivityType.achievementUnlocked,
        description: '実績を解除しました',
        occurredAt: '2026-09-15T10:00:00Z',
      );

      final json = activity.toJson();
      final restored = FriendActivity.fromJson(json);

      expect(restored.type, equals(FriendActivityType.achievementUnlocked));
      expect(restored.occurredAt, equals('2026-09-15T10:00:00Z'));
    });

    test('should have all activity types with Japanese labels', () {
      expect(FriendActivityType.values.length, equals(5));
      expect(FriendActivityType.gameWon.label, equals('対局勝利'));
      expect(FriendActivityType.becameFriends.label, equals('フレンド追加'));
    });
  });

  group('Friend System Integration Tests', () {
    test('should model full friend request lifecycle', () {
      final request = FriendRequest(
        id: 'req_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        sentAt: DateTime.now().toIso8601String(),
      );

      expect(request.status, equals(FriendRequestStatus.pending));

      final accepted = request.copyWith(
        status: FriendRequestStatus.accepted,
        respondedAt: DateTime.now().toIso8601String(),
      );

      expect(accepted.status, equals(FriendRequestStatus.accepted));

      final friendshipA = Friendship(
        friendId: accepted.toUserId,
        friendName: accepted.toUserName,
        becameFriendsAt: accepted.respondedAt!,
      );
      final friendshipB = Friendship(
        friendId: accepted.fromUserId,
        friendName: accepted.fromUserName,
        becameFriendsAt: accepted.respondedAt!,
      );

      expect(friendshipA.friendId, equals('user_002'));
      expect(friendshipB.friendId, equals('user_001'));
    });

    test('should model battle invite to head-to-head record update', () {
      final now = DateTime.now();
      final invite = BattleInvite(
        id: 'invite_001',
        fromUserId: 'user_001',
        fromUserName: 'Player A',
        toUserId: 'user_002',
        toUserName: 'Player B',
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(minutes: 10)).toIso8601String(),
      );

      final accepted = invite.copyWith(
        status: BattleInviteStatus.accepted,
        gameSessionId: 'session_001',
      );

      final friendship = Friendship(
        friendId: accepted.toUserId,
        friendName: accepted.toUserName,
        becameFriendsAt: now.toIso8601String(),
      );

      // fromUser (user_001) won the resulting game
      final updatedFriendship = friendship.copyWith(
        headToHeadWins: friendship.headToHeadWins + 1,
        lastPlayedAt: now.toIso8601String(),
      );

      expect(updatedFriendship.headToHeadWins, equals(1));
      expect(updatedFriendship.lastPlayedAt, isNotNull);
    });
  });

  group('Performance Tests', () {
    test('should create many friend requests quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        FriendRequest(
          id: 'req_$i',
          fromUserId: 'user_$i',
          fromUserName: 'Player $i',
          toUserId: 'user_${i + 1}',
          toUserName: 'Player ${i + 1}',
          sentAt: DateTime.now().toIso8601String(),
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should create many friendships quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 200; i++) {
        Friendship(
          friendId: 'user_$i',
          friendName: 'Player $i',
          becameFriendsAt: DateTime.now().toIso8601String(),
          headToHeadWins: i % 10,
          headToHeadLosses: (i + 1) % 10,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
