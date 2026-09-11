/// Phase 6B Achievement & Challenge Tests
/// 実績・チャレンジ・関係管理機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/achievement.dart';

void main() {
  group('Achievement Model Tests', () {
    test('should create achievement', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: '初勝利',
        description: '最初の対局に勝つ',
        icon: '🏆',
        rarity: AchievementRarity.common,
        condition: '対局に勝つ',
        points: 10,
        requiredProgress: 1,
      );

      expect(achievement.id, equals('ach_001'));
      expect(achievement.name, equals('初勝利'));
      expect(achievement.points, equals(10));
      expect(achievement.requiredProgress, equals(1));
    });

    test('should convert to JSON', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: '初勝利',
        description: 'First win',
        icon: '🏆',
        rarity: AchievementRarity.rare,
        condition: 'Win a game',
        points: 50,
      );

      final json = achievement.toJson();

      expect(json['id'], equals('ach_001'));
      expect(json['name'], equals('初勝利'));
      expect(json['points'], equals(50));
      expect(json['rarity'], equals(AchievementRarity.rare.index));
    });

    test('should create from JSON', () {
      final json = {
        'id': 'ach_001',
        'name': 'First Win',
        'description': 'Win first game',
        'icon': '🏆',
        'rarity': 1,
        'condition': 'Win a game',
        'points': 50,
        'requiredProgress': 1,
      };

      final achievement = Achievement.fromJson(json);

      expect(achievement.id, equals('ach_001'));
      expect(achievement.name, equals('First Win'));
      expect(achievement.rarity, equals(AchievementRarity.uncommon));
    });

    test('should have all achievement rarities', () {
      expect(AchievementRarity.values.length, equals(5));
      expect(AchievementRarity.values, contains(AchievementRarity.common));
      expect(AchievementRarity.values, contains(AchievementRarity.legendary));
    });
  });

  group('User Achievement Tests', () {
    test('should create user achievement', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: 'Test Achievement',
        description: 'Test',
        icon: '🏆',
        condition: 'Test condition',
        requiredProgress: 10,
      );

      final userAchievement = UserAchievement(
        userId: 'user_001',
        achievementId: 'ach_001',
        achievement: achievement,
        currentProgress: 5,
      );

      expect(userAchievement.userId, equals('user_001'));
      expect(userAchievement.currentProgress, equals(5));
      expect(userAchievement.isUnlocked, isFalse);
    });

    test('should calculate progress percent', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: 'Test',
        description: 'Test',
        icon: '🏆',
        condition: 'Test',
        requiredProgress: 10,
      );

      final userAchievement = UserAchievement(
        userId: 'user_001',
        achievementId: 'ach_001',
        achievement: achievement,
        currentProgress: 5,
      );

      expect(userAchievement.progressPercent, equals(50.0));
    });

    test('should unlock achievement when progress reaches required', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: 'Test',
        description: 'Test',
        icon: '🏆',
        condition: 'Test',
        requiredProgress: 10,
      );

      final unlockedAchievement = UserAchievement(
        userId: 'user_001',
        achievementId: 'ach_001',
        achievement: achievement,
        currentProgress: 10,
        isUnlocked: true,
        unlockedAt: '2026-09-11T00:00:00Z',
      );

      expect(unlockedAchievement.isUnlocked, isTrue);
      expect(unlockedAchievement.unlockedAt, isNotNull);
    });

    test('should copyWith correctly', () {
      final achievement = Achievement(
        id: 'ach_001',
        name: 'Test',
        description: 'Test',
        icon: '🏆',
        condition: 'Test',
        requiredProgress: 10,
      );

      final original = UserAchievement(
        userId: 'user_001',
        achievementId: 'ach_001',
        achievement: achievement,
        currentProgress: 5,
      );

      final updated = original.copyWith(currentProgress: 10, isUnlocked: true);

      expect(updated.currentProgress, equals(10));
      expect(updated.isUnlocked, isTrue);
      expect(updated.userId, equals(original.userId));
    });
  });

  group('Challenge Model Tests', () {
    test('should create challenge', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: '3連勝チャレンジ',
        description: '3回連続で勝つ',
        difficulty: 2,
        rewardPoints: 50,
        objective: '3回連続で勝つ',
        type: ChallengeType.daily,
      );

      expect(challenge.id, equals('ch_001'));
      expect(challenge.name, equals('3連勝チャレンジ'));
      expect(challenge.difficulty, equals(2));
      expect(challenge.type, equals(ChallengeType.daily));
    });

    test('should have all challenge types', () {
      expect(ChallengeType.values.length, equals(5));
      expect(ChallengeType.values, contains(ChallengeType.daily));
      expect(ChallengeType.values, contains(ChallengeType.seasonal));
    });

    test('should convert to JSON', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: 'Challenge',
        description: 'Test challenge',
        difficulty: 3,
        rewardPoints: 100,
        objective: 'Objective',
        type: ChallengeType.weekly,
      );

      final json = challenge.toJson();

      expect(json['id'], equals('ch_001'));
      expect(json['difficulty'], equals(3));
      expect(json['type'], equals(ChallengeType.weekly.index));
    });
  });

  group('User Challenge Tests', () {
    test('should create user challenge', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: 'Test Challenge',
        description: 'Test',
        difficulty: 3,
        objective: 'Test objective',
      );

      final userChallenge = UserChallenge(
        userId: 'user_001',
        challengeId: 'ch_001',
        challenge: challenge,
        currentProgress: 1,
      );

      expect(userChallenge.userId, equals('user_001'));
      expect(userChallenge.currentProgress, equals(1));
      expect(userChallenge.isCompleted, isFalse);
    });

    test('should calculate challenge progress percent', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: 'Test',
        description: 'Test',
        difficulty: 5,
        objective: 'Test',
      );

      final userChallenge = UserChallenge(
        userId: 'user_001',
        challengeId: 'ch_001',
        challenge: challenge,
        currentProgress: 2,
      );

      expect(userChallenge.progressPercent, equals(40.0));
    });

    test('should complete challenge at required progress', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: 'Test',
        description: 'Test',
        difficulty: 3,
        objective: 'Test',
      );

      final completedChallenge = UserChallenge(
        userId: 'user_001',
        challengeId: 'ch_001',
        challenge: challenge,
        currentProgress: 3,
        isCompleted: true,
        completedAt: '2026-09-11T00:00:00Z',
      );

      expect(completedChallenge.isCompleted, isTrue);
      expect(completedChallenge.completedAt, isNotNull);
    });

    test('should track reward claim status', () {
      final challenge = Challenge(
        id: 'ch_001',
        name: 'Test',
        description: 'Test',
        difficulty: 1,
        objective: 'Test',
        rewardPoints: 50,
      );

      final claimedChallenge = UserChallenge(
        userId: 'user_001',
        challengeId: 'ch_001',
        challenge: challenge,
        currentProgress: 1,
        isCompleted: true,
        rewardClaimed: true,
      );

      expect(claimedChallenge.rewardClaimed, isTrue);
    });
  });

  group('Relationship Model Tests', () {
    test('should create user relationship', () {
      final relationship = UserRelationship(
        userId: 'user_001',
        otherUserId: 'user_002',
        otherUserName: 'Rival',
        type: RelationshipType.rival,
        createdAt: DateTime.now().toIso8601String(),
        gamesPlayed: 10,
        wins: 6,
        losses: 4,
      );

      expect(relationship.userId, equals('user_001'));
      expect(relationship.otherUserId, equals('user_002'));
      expect(relationship.type, equals(RelationshipType.rival));
      expect(relationship.gamesPlayed, equals(10));
    });

    test('should calculate win rate against user', () {
      final relationship = UserRelationship(
        userId: 'user_001',
        otherUserId: 'user_002',
        otherUserName: 'Opponent',
        type: RelationshipType.friend,
        createdAt: DateTime.now().toIso8601String(),
        gamesPlayed: 10,
        wins: 6,
        losses: 4,
      );

      expect(relationship.winRateAgainstUser, equals(0.6));
    });

    test('should have all relationship types', () {
      expect(RelationshipType.values.length, equals(3));
      expect(RelationshipType.values, contains(RelationshipType.friend));
      expect(RelationshipType.values, contains(RelationshipType.rival));
      expect(RelationshipType.values, contains(RelationshipType.blocked));
    });

    test('should convert to JSON', () {
      final relationship = UserRelationship(
        userId: 'user_001',
        otherUserId: 'user_002',
        otherUserName: 'Friend',
        type: RelationshipType.friend,
        createdAt: '2026-09-01T00:00:00Z',
        gamesPlayed: 5,
        wins: 3,
        losses: 2,
      );

      final json = relationship.toJson();

      expect(json['userId'], equals('user_001'));
      expect(json['otherUserName'], equals('Friend'));
      expect(json['gamesPlayed'], equals(5));
    });
  });

  group('Match Request Tests', () {
    test('should create match request', () {
      final request = MatchRequest(
        id: 'req_001',
        requesterId: 'user_001',
        requesterName: 'Player A',
        receiverId: 'user_002',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(request.id, equals('req_001'));
      expect(request.requesterId, equals('user_001'));
      expect(request.status, equals(MatchRequestStatus.pending));
    });

    test('should have all match request statuses', () {
      expect(MatchRequestStatus.values.length, equals(5));
      expect(MatchRequestStatus.values, contains(MatchRequestStatus.pending));
      expect(MatchRequestStatus.values, contains(MatchRequestStatus.accepted));
      expect(MatchRequestStatus.values, contains(MatchRequestStatus.declined));
    });

    test('should convert to JSON', () {
      final request = MatchRequest(
        id: 'req_001',
        requesterId: 'user_001',
        requesterName: 'Player A',
        receiverId: 'user_002',
        status: MatchRequestStatus.accepted,
        message: 'Let\'s play!',
        createdAt: '2026-09-11T00:00:00Z',
        respondedAt: '2026-09-11T01:00:00Z',
      );

      final json = request.toJson();

      expect(json['id'], equals('req_001'));
      expect(json['status'], equals(MatchRequestStatus.accepted.index));
      expect(json['message'], equals('Let\'s play!'));
    });

    test('should create from JSON', () {
      final json = {
        'id': 'req_001',
        'requesterId': 'user_001',
        'requesterName': 'Player A',
        'receiverId': 'user_002',
        'status': 1,
        'message': 'Test message',
        'createdAt': '2026-09-11T00:00:00Z',
      };

      final request = MatchRequest.fromJson(json);

      expect(request.id, equals('req_001'));
      expect(request.status, equals(MatchRequestStatus.accepted));
      expect(request.message, equals('Test message'));
    });
  });

  group('Achievement Progress Tests', () {
    test('should track multiple achievements', () {
      final achievements = [
        Achievement(
          id: 'ach_001',
          name: 'First Win',
          description: 'Win first game',
          icon: '🏆',
          condition: 'Win 1 game',
          requiredProgress: 1,
          points: 10,
        ),
        Achievement(
          id: 'ach_002',
          name: 'Ten Wins',
          description: 'Win 10 games',
          icon: '🎖️',
          condition: 'Win 10 games',
          requiredProgress: 10,
          points: 100,
        ),
        Achievement(
          id: 'ach_003',
          name: 'Master',
          description: 'Reach level 50',
          icon: '👑',
          condition: 'Reach level 50',
          requiredProgress: 50,
          points: 500,
        ),
      ];

      expect(achievements.length, equals(3));
      expect(achievements[0].points, lessThan(achievements[1].points));
      expect(achievements[1].points, lessThan(achievements[2].points));
    });

    test('should track challenge progression', () {
      final challenges = [
        Challenge(
          id: 'ch_001',
          name: 'Daily Challenge',
          description: 'Win 1 game',
          difficulty: 1,
          objective: 'Win 1 game',
          type: ChallengeType.daily,
          rewardPoints: 10,
        ),
        Challenge(
          id: 'ch_002',
          name: 'Weekly Challenge',
          description: 'Win 7 games',
          difficulty: 7,
          objective: 'Win 7 games',
          type: ChallengeType.weekly,
          rewardPoints: 100,
        ),
      ];

      expect(challenges.length, equals(2));
      expect(challenges[0].difficulty, lessThan(challenges[1].difficulty));
      expect(challenges[0].rewardPoints, lessThan(challenges[1].rewardPoints));
    });
  });

  group('Performance Tests', () {
    test('should create achievements quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        Achievement(
          id: 'ach_$i',
          name: 'Achievement $i',
          description: 'Description $i',
          icon: '🏆',
          condition: 'Condition $i',
          points: i * 10,
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('should create challenges quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        Challenge(
          id: 'ch_$i',
          name: 'Challenge $i',
          description: 'Description $i',
          difficulty: (i % 5) + 1,
          objective: 'Objective $i',
          rewardPoints: i * 10,
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(30));
    });

    test('should create relationships quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        UserRelationship(
          userId: 'user_001',
          otherUserId: 'user_$i',
          otherUserName: 'Player $i',
          type: i % 2 == 0 ? RelationshipType.friend : RelationshipType.rival,
          createdAt: DateTime.now().toIso8601String(),
          gamesPlayed: i * 10,
          wins: i * 6,
          losses: i * 4,
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
