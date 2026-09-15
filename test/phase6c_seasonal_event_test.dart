/// Phase 6C Seasonal Event Tests
/// シーズナルイベント・バトルパス機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/seasonal_event.dart';

void main() {
  group('Season Model Tests', () {
    test('should create season', () {
      final season = Season(
        id: 'season_001',
        name: 'シーズン1',
        description: 'First season',
        seasonNumber: 1,
        status: SeasonStatus.active,
        startDate: '2026-09-01T00:00:00Z',
        endDate: '2026-11-30T23:59:59Z',
        themeColor: '#FF6200EE',
      );

      expect(season.id, equals('season_001'));
      expect(season.name, equals('シーズン1'));
      expect(season.seasonNumber, equals(1));
      expect(season.status, equals(SeasonStatus.active));
    });

    test('should have all season statuses', () {
      expect(SeasonStatus.values.length, equals(4));
      expect(SeasonStatus.values, contains(SeasonStatus.active));
      expect(SeasonStatus.values, contains(SeasonStatus.closed));
    });

    test('should convert to JSON', () {
      final season = Season(
        id: 'season_001',
        name: 'Season 1',
        description: 'Test season',
        seasonNumber: 1,
        startDate: '2026-09-01T00:00:00Z',
        endDate: '2026-11-30T23:59:59Z',
        themeColor: '#FF6200EE',
      );

      final json = season.toJson();

      expect(json['id'], equals('season_001'));
      expect(json['seasonNumber'], equals(1));
      expect(json['status'], equals(SeasonStatus.upcoming.index));
    });
  });

  group('Battle Pass Model Tests', () {
    test('should create free battle pass', () {
      final battlePass = BattlePass(
        id: 'bp_001',
        seasonId: 'season_001',
        type: BattlePassType.free,
        description: 'Free battle pass',
      );

      expect(battlePass.id, equals('bp_001'));
      expect(battlePass.type, equals(BattlePassType.free));
      expect(battlePass.price, isNull);
    });

    test('should create premium battle pass', () {
      final battlePass = BattlePass(
        id: 'bp_002',
        seasonId: 'season_001',
        type: BattlePassType.premium,
        description: 'Premium battle pass',
        price: 999,
        currency: 'JPY',
      );

      expect(battlePass.type, equals(BattlePassType.premium));
      expect(battlePass.price, equals(999));
      expect(battlePass.currency, equals('JPY'));
    });

    test('should have all battle pass types', () {
      expect(BattlePassType.values.length, equals(2));
    });
  });

  group('User Battle Pass Tests', () {
    test('should create user battle pass', () {
      final userBP = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        currentLevel: 1,
        currentProgress: 500,
        progressPerLevel: 1000,
      );

      expect(userBP.userId, equals('user_001'));
      expect(userBP.currentLevel, equals(1));
      expect(userBP.currentProgress, equals(500));
    });

    test('should calculate level progress percent', () {
      final userBP = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        currentLevel: 5,
        currentProgress: 500,
        progressPerLevel: 1000,
      );

      expect(userBP.levelProgressPercent, equals(50.0));
    });

    test('should track premium purchase', () {
      final userBP = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        isPurchased: true,
        purchasedAt: '2026-09-01T00:00:00Z',
      );

      expect(userBP.isPurchased, isTrue);
      expect(userBP.purchasedAt, isNotNull);
    });

    test('should track claimed rewards', () {
      final userBP = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        claimedRewards: ['reward_1', 'reward_2', 'reward_3'],
      );

      expect(userBP.claimedRewards.length, equals(3));
      expect(userBP.claimedRewards, contains('reward_1'));
    });

    test('should copyWith correctly', () {
      final original = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        currentLevel: 5,
      );

      final updated = original.copyWith(currentLevel: 10, isPurchased: true);

      expect(updated.currentLevel, equals(10));
      expect(updated.isPurchased, isTrue);
      expect(updated.userId, equals(original.userId));
    });
  });

  group('Battle Pass Reward Tests', () {
    test('should create battle pass reward', () {
      final reward = BattlePassReward(
        id: 'reward_001',
        battlePassId: 'bp_001',
        level: 10,
        type: RewardType.cosmetic,
        rewardContent: 'skin_dragon_king',
        description: 'Dragon King Skin',
        icon: '🐉',
        isFreeTierAvailable: true,
      );

      expect(reward.id, equals('reward_001'));
      expect(reward.level, equals(10));
      expect(reward.type, equals(RewardType.cosmetic));
    });

    test('should have all reward types', () {
      expect(RewardType.values.length, equals(6));
      expect(RewardType.values, contains(RewardType.cosmetic));
      expect(RewardType.values, contains(RewardType.title));
    });

    test('should track free tier availability', () {
      final freeReward = BattlePassReward(
        id: 'reward_001',
        battlePassId: 'bp_001',
        level: 5,
        type: RewardType.points,
        rewardContent: '100',
        description: 'Free points',
        icon: '⭐',
        isFreeTierAvailable: true,
      );

      final premiumReward = BattlePassReward(
        id: 'reward_002',
        battlePassId: 'bp_001',
        level: 50,
        type: RewardType.cosmetic,
        rewardContent: 'skin_legendary',
        description: 'Legendary Skin',
        icon: '👑',
        isFreeTierAvailable: false,
      );

      expect(freeReward.isFreeTierAvailable, isTrue);
      expect(premiumReward.isFreeTierAvailable, isFalse);
    });
  });

  group('Seasonal Challenge Tests', () {
    test('should create seasonal challenge', () {
      final challenge = SeasonalChallenge(
        id: 'sc_001',
        seasonId: 'season_001',
        name: '3連勝チャレンジ',
        description: '3回連続で勝つ',
        rewardPoints: 50,
        objective: '3回連続で勝つ',
        difficulty: 2,
      );

      expect(challenge.id, equals('sc_001'));
      expect(challenge.name, equals('3連勝チャレンジ'));
      expect(challenge.rewardPoints, equals(50));
    });

    test('should have all reset frequencies', () {
      expect(ResetFrequency.values.length, equals(4));
      expect(ResetFrequency.values, contains(ResetFrequency.daily));
      expect(ResetFrequency.values, contains(ResetFrequency.seasonal));
    });

    test('should have all progress types', () {
      expect(ProgressType.values.length, equals(3));
    });

    test('should convert to JSON', () {
      final challenge = SeasonalChallenge(
        id: 'sc_001',
        seasonId: 'season_001',
        name: 'Challenge',
        description: 'Test challenge',
        rewardPoints: 100,
        objective: 'Test objective',
        difficulty: 3,
        resetFrequency: ResetFrequency.weekly,
      );

      final json = challenge.toJson();

      expect(json['id'], equals('sc_001'));
      expect(json['rewardPoints'], equals(100));
      expect(json['resetFrequency'], equals(ResetFrequency.weekly.index));
    });
  });

  group('User Seasonal Challenge Tests', () {
    test('should create user seasonal challenge', () {
      final userChallenge = UserSeasonalChallenge(
        userId: 'user_001',
        challengeId: 'sc_001',
        seasonId: 'season_001',
        currentProgress: 1,
      );

      expect(userChallenge.userId, equals('user_001'));
      expect(userChallenge.currentProgress, equals(1));
      expect(userChallenge.isCompleted, isFalse);
    });

    test('should track completion status', () {
      final completedChallenge = UserSeasonalChallenge(
        userId: 'user_001',
        challengeId: 'sc_001',
        seasonId: 'season_001',
        currentProgress: 3,
        isCompleted: true,
        completedAt: '2026-09-11T00:00:00Z',
      );

      expect(completedChallenge.isCompleted, isTrue);
      expect(completedChallenge.completedAt, isNotNull);
    });

    test('should track reward claim status', () {
      final claimedChallenge = UserSeasonalChallenge(
        userId: 'user_001',
        challengeId: 'sc_001',
        seasonId: 'season_001',
        isCompleted: true,
        rewardClaimed: true,
      );

      expect(claimedChallenge.rewardClaimed, isTrue);
    });

    test('should copyWith correctly', () {
      final original = UserSeasonalChallenge(
        userId: 'user_001',
        challengeId: 'sc_001',
        seasonId: 'season_001',
        currentProgress: 1,
      );

      final updated = original.copyWith(
        currentProgress: 3,
        isCompleted: true,
      );

      expect(updated.currentProgress, equals(3));
      expect(updated.isCompleted, isTrue);
      expect(updated.userId, equals(original.userId));
    });
  });

  group('Performance Tests', () {
    test('should create seasons quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 20; i++) {
        Season(
          id: 'season_$i',
          name: 'Season $i',
          description: 'Description $i',
          seasonNumber: i + 1,
          startDate: DateTime.now().toIso8601String(),
          endDate: DateTime.now().add(Duration(days: 60)).toIso8601String(),
          themeColor: '#FF${(i * 10).toRadixString(16)}0000',
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(30));
    });

    test('should create battle passes quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        BattlePass(
          id: 'bp_$i',
          seasonId: 'season_001',
          type: i % 2 == 0 ? BattlePassType.free : BattlePassType.premium,
          description: 'BP $i',
          price: i % 2 == 0 ? null : 999,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('should create seasonal challenges quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        SeasonalChallenge(
          id: 'sc_$i',
          seasonId: 'season_001',
          name: 'Challenge $i',
          description: 'Description $i',
          rewardPoints: i * 10,
          objective: 'Objective $i',
          difficulty: (i % 5) + 1,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(30));
    });
  });

  group('Season System Integration Tests', () {
    test('should create complete season system', () {
      final season = Season(
        id: 'season_001',
        name: 'シーズン1',
        description: 'First season',
        seasonNumber: 1,
        status: SeasonStatus.active,
        startDate: '2026-09-01T00:00:00Z',
        endDate: '2026-11-30T23:59:59Z',
        themeColor: '#FF6200EE',
      );

      final freeBattlePass = BattlePass(
        id: 'bp_free_001',
        seasonId: season.id,
        type: BattlePassType.free,
        description: 'Free Battle Pass',
      );

      final premiumBattlePass = BattlePass(
        id: 'bp_premium_001',
        seasonId: season.id,
        type: BattlePassType.premium,
        description: 'Premium Battle Pass',
        price: 999,
        currency: 'JPY',
      );

      expect(season.seasonNumber, equals(1));
      expect(freeBattlePass.type, equals(BattlePassType.free));
      expect(premiumBattlePass.price, equals(999));
    });

    test('should track user progression through season', () {
      final userBP = UserBattlePass(
        userId: 'user_001',
        battlePassId: 'bp_001',
        seasonId: 'season_001',
        currentLevel: 50,
        currentProgress: 500,
        progressPerLevel: 1000,
        isPurchased: true,
        claimedRewards: List.generate(10, (i) => 'reward_${i + 1}'),
      );

      expect(userBP.currentLevel, equals(50));
      expect(userBP.claimedRewards.length, equals(10));
      expect(userBP.isPurchased, isTrue);
    });
  });
}
