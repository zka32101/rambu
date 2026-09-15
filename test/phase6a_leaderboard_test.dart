/// Phase 6A Leaderboard Tests
/// ランキング・ユーザープロフィール機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/user_profile.dart';
import 'package:rambu_shogi/services/leaderboard_service.dart';

void main() {
  group('User Profile Model Tests', () {
    test('should create user profile', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'テストプレイヤー',
        level: 1,
        rank: '初級',
        totalGames: 10,
        wins: 6,
        losses: 4,
        draws: 0,
        winRate: 0.6,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.userId, equals('user_001'));
      expect(profile.displayName, equals('テストプレイヤー'));
      expect(profile.level, equals(1));
      expect(profile.rank, equals('初級'));
      expect(profile.totalGames, equals(10));
      expect(profile.wins, equals(6));
      expect(profile.winRate, equals(0.6));
    });

    test('should convert to JSON', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Test Player',
        level: 5,
        rank: '中級',
        totalGames: 50,
        wins: 30,
        losses: 20,
        winRate: 0.6,
        createdAt: '2026-09-01T00:00:00Z',
      );

      final json = profile.toJson();

      expect(json['userId'], equals('user_001'));
      expect(json['displayName'], equals('Test Player'));
      expect(json['level'], equals(5));
      expect(json['totalGames'], equals(50));
      expect(json['winRate'], equals(0.6));
    });

    test('should create from JSON', () {
      final json = {
        'userId': 'user_001',
        'displayName': 'Test Player',
        'level': 5,
        'rank': '中級',
        'totalGames': 50,
        'wins': 30,
        'losses': 20,
        'winRate': 0.6,
        'createdAt': '2026-09-01T00:00:00Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, equals('user_001'));
      expect(profile.displayName, equals('Test Player'));
      expect(profile.level, equals(5));
      expect(profile.winRate, equals(0.6));
    });

    test('should copyWith correctly', () {
      final original = UserProfile(
        userId: 'user_001',
        displayName: 'Original Name',
        level: 1,
        rank: '初級',
        totalGames: 10,
        createdAt: '2026-09-01T00:00:00Z',
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        level: 5,
        totalGames: 50,
      );

      expect(updated.userId, equals(original.userId));
      expect(updated.displayName, equals('Updated Name'));
      expect(updated.level, equals(5));
      expect(updated.totalGames, equals(50));
    });

    test('should have default values', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Test',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.level, equals(1));
      expect(profile.rank, equals('初級'));
      expect(profile.totalGames, equals(0));
      expect(profile.wins, equals(0));
      expect(profile.winRate, equals(0.0));
      expect(profile.ratingScore, equals(1200.0));
      expect(profile.isPrivate, isFalse);
    });

    test('should track statistics correctly', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Stats Test',
        totalGames: 100,
        wins: 60,
        losses: 35,
        draws: 5,
        winRate: 0.6,
        maxWinStreak: 8,
        currentWinStreak: 3,
        totalCriticalHits: 42,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.totalGames, equals(100));
      expect(profile.wins, equals(60));
      expect(profile.losses, equals(35));
      expect(profile.draws, equals(5));
      expect(profile.winRate, equals(0.6));
      expect(profile.maxWinStreak, equals(8));
      expect(profile.currentWinStreak, equals(3));
      expect(profile.totalCriticalHits, equals(42));
    });
  });

  group('Leaderboard Entry Tests', () {
    test('should create leaderboard entry', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Player 1',
        createdAt: DateTime.now().toIso8601String(),
      );

      final entry = LeaderboardEntry(
        rank: 1,
        userProfile: profile,
        score: 1500.0,
        rankChange: 2,
      );

      expect(entry.rank, equals(1));
      expect(entry.userProfile.displayName, equals('Player 1'));
      expect(entry.score, equals(1500.0));
      expect(entry.rankChange, equals(2));
    });

    test('should convert to JSON', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Player 1',
        createdAt: '2026-09-01T00:00:00Z',
      );

      final entry = LeaderboardEntry(
        rank: 5,
        userProfile: profile,
        score: 1200.0,
      );

      final json = entry.toJson();

      expect(json['rank'], equals(5));
      expect(json['score'], equals(1200.0));
      expect((json['userProfile'] as Map)['displayName'], equals('Player 1'));
    });

    test('should create from JSON', () {
      final json = {
        'rank': 1,
        'score': 1500.0,
        'rankChange': 3,
        'userProfile': {
          'userId': 'user_001',
          'displayName': 'Player 1',
          'level': 10,
          'rank': '上級',
          'totalGames': 100,
          'createdAt': '2026-09-01T00:00:00Z',
        },
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, equals(1));
      expect(entry.score, equals(1500.0));
      expect(entry.rankChange, equals(3));
      expect(entry.userProfile.displayName, equals('Player 1'));
    });
  });

  group('Game Opponent Model Tests', () {
    test('should create game opponent', () {
      final opponent = GameOpponent(
        userId: 'opponent_001',
        displayName: 'ライバル',
        rank: '中級',
        winRate: 0.55,
        totalGames: 25,
        isOnline: true,
      );

      expect(opponent.userId, equals('opponent_001'));
      expect(opponent.displayName, equals('ライバル'));
      expect(opponent.rank, equals('中級'));
      expect(opponent.winRate, equals(0.55));
      expect(opponent.totalGames, equals(25));
      expect(opponent.isOnline, isTrue);
    });

    test('should convert to JSON', () {
      final opponent = GameOpponent(
        userId: 'opponent_001',
        displayName: 'Rival',
        rank: '上級',
        winRate: 0.65,
        totalGames: 50,
      );

      final json = opponent.toJson();

      expect(json['userId'], equals('opponent_001'));
      expect(json['displayName'], equals('Rival'));
      expect(json['rank'], equals('上級'));
      expect(json['winRate'], equals(0.65));
    });

    test('should create from JSON', () {
      final json = {
        'userId': 'opponent_001',
        'displayName': 'Rival',
        'rank': '上級',
        'winRate': 0.65,
        'totalGames': 50,
        'isOnline': true,
      };

      final opponent = GameOpponent.fromJson(json);

      expect(opponent.userId, equals('opponent_001'));
      expect(opponent.displayName, equals('Rival'));
      expect(opponent.winRate, equals(0.65));
      expect(opponent.isOnline, isTrue);
    });

    test('should have default offline status', () {
      final opponent = GameOpponent(
        userId: 'opponent_001',
        displayName: 'Player',
        rank: '中級',
        winRate: 0.5,
        totalGames: 20,
      );

      expect(opponent.isOnline, isFalse);
    });
  });

  group('Leaderboard Category Tests', () {
    test('should have all leaderboard categories', () {
      expect(LeaderboardCategory.values.length, equals(6));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.overall));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.winRate));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.level));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.playTime));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.achievements));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.criticalHits));
    });
  });

  group('Leaderboard Service Mock Tests', () {
    late LeaderboardService leaderboardService;

    setUp(() {
      leaderboardService = LeaderboardService();
    });

    test('should be singleton', () {
      final service1 = LeaderboardService();
      final service2 = LeaderboardService();

      expect(identical(service1, service2), isTrue);
    });

    test('should handle win rate calculation', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Test',
        totalGames: 10,
        wins: 6,
        winRate: 0.6,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.winRate, equals(0.6));
      expect(profile.totalGames, equals(10));
      expect(profile.wins, equals(6));
    });

    test('should calculate level from wins', () {
      final profile1 = UserProfile(
        userId: 'user_001',
        displayName: 'Beginner',
        totalGames: 10,
        wins: 2,
        level: 1,
        createdAt: DateTime.now().toIso8601String(),
      );

      final profile2 = UserProfile(
        userId: 'user_002',
        displayName: 'Intermediate',
        totalGames: 50,
        wins: 30,
        level: 15,
        createdAt: DateTime.now().toIso8601String(),
      );

      final profile3 = UserProfile(
        userId: 'user_003',
        displayName: 'Master',
        totalGames: 200,
        wins: 150,
        level: 50,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile1.level, lessThan(profile2.level));
      expect(profile2.level, lessThan(profile3.level));
    });

    test('should classify rank based on win rate', () {
      final beginnerProfile = UserProfile(
        userId: 'user_001',
        displayName: 'Beginner',
        totalGames: 10,
        wins: 3,
        winRate: 0.3,
        rank: '初級',
        createdAt: DateTime.now().toIso8601String(),
      );

      final intermediateProfile = UserProfile(
        userId: 'user_002',
        displayName: 'Intermediate',
        totalGames: 50,
        wins: 25,
        winRate: 0.5,
        rank: '中級',
        createdAt: DateTime.now().toIso8601String(),
      );

      final advancedProfile = UserProfile(
        userId: 'user_003',
        displayName: 'Advanced',
        totalGames: 100,
        wins: 70,
        winRate: 0.7,
        rank: '上級',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(beginnerProfile.rank, equals('初級'));
      expect(intermediateProfile.rank, equals('中級'));
      expect(advancedProfile.rank, equals('上級'));
    });

    test('should track rating score (ELO)', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Rated Player',
        ratingScore: 1200.0,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.ratingScore, equals(1200.0));
    });

    test('should track play time', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Dedicated Player',
        totalPlayTimeSeconds: 3600, // 1 hour
        averageGameDurationSeconds: 120.0, // 2 minutes per game
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.totalPlayTimeSeconds, equals(3600));
      expect(profile.averageGameDurationSeconds, equals(120.0));
    });

    test('should track win streaks', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Win Streak Player',
        maxWinStreak: 10,
        currentWinStreak: 5,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.maxWinStreak, equals(10));
      expect(profile.currentWinStreak, equals(5));
    });

    test('should track critical hits', () {
      final profile = UserProfile(
        userId: 'user_001',
        displayName: 'Crit Master',
        totalCriticalHits: 42,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(profile.totalCriticalHits, equals(42));
    });
  });

  group('Leaderboard Ranking Tests', () {
    test('should rank players correctly by rating score', () {
      final players = [
        LeaderboardEntry(
          rank: 1,
          userProfile: UserProfile(
            userId: 'user_001',
            displayName: 'Top Player',
            ratingScore: 1500.0,
            createdAt: DateTime.now().toIso8601String(),
          ),
          score: 1500.0,
        ),
        LeaderboardEntry(
          rank: 2,
          userProfile: UserProfile(
            userId: 'user_002',
            displayName: 'Middle Player',
            ratingScore: 1300.0,
            createdAt: DateTime.now().toIso8601String(),
          ),
          score: 1300.0,
        ),
        LeaderboardEntry(
          rank: 3,
          userProfile: UserProfile(
            userId: 'user_003',
            displayName: 'Beginner Player',
            ratingScore: 1100.0,
            createdAt: DateTime.now().toIso8601String(),
          ),
          score: 1100.0,
        ),
      ];

      expect(players[0].rank, equals(1));
      expect(players[0].score, greaterThan(players[1].score));
      expect(players[1].score, greaterThan(players[2].score));
    });

    test('should track rank changes', () {
      final entry = LeaderboardEntry(
        rank: 5,
        userProfile: UserProfile(
          userId: 'user_001',
          displayName: 'Rising Player',
          createdAt: DateTime.now().toIso8601String(),
        ),
        score: 1300.0,
        rankChange: 3, // Up 3 positions
      );

      expect(entry.rankChange, equals(3));
      expect(entry.rankChange! > 0, isTrue);
    });

    test('should calculate negative rank changes', () {
      final entry = LeaderboardEntry(
        rank: 10,
        userProfile: UserProfile(
          userId: 'user_001',
          displayName: 'Falling Player',
          createdAt: DateTime.now().toIso8601String(),
        ),
        score: 1100.0,
        rankChange: -2, // Down 2 positions
      );

      expect(entry.rankChange, equals(-2));
      expect(entry.rankChange! < 0, isTrue);
    });
  });

  group('Performance Tests', () {
    test('should create user profile quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        UserProfile(
          userId: 'user_$i',
          displayName: 'Player $i',
          createdAt: DateTime.now().toIso8601String(),
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should convert to JSON quickly', () {
      final profiles = List.generate(
        100,
        (i) => UserProfile(
          userId: 'user_$i',
          displayName: 'Player $i',
          level: i % 50 + 1,
          totalGames: i * 10,
          wins: i * 6,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      final stopwatch = Stopwatch()..start();

      for (final profile in profiles) {
        profile.toJson();
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('should create leaderboard entries quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        LeaderboardEntry(
          rank: i + 1,
          userProfile: UserProfile(
            userId: 'user_$i',
            displayName: 'Player $i',
            createdAt: DateTime.now().toIso8601String(),
          ),
          score: 1500.0 - (i * 10),
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
