/// AI Benchmarking Tests
/// AI性能測定・ベンチマーク機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/services/ai_benchmarking.dart';
import 'package:rambu_shogi/services/ai_difficulty_limiter.dart';

void main() {
  /// テスト用のゲーム記録を作成
  GameRecord createTestGameRecord({
    String id = 'test_001',
    GameResult result = GameResult.whiteWon,
    int moveCount = 10,
    int durationSeconds = 300,
  }) {
    final moves = List.generate(
      moveCount,
      (index) => {
        'from': {'x': 2, 'y': (7 - index % 2)},
        'to': {'x': 2, 'y': (6 - index % 2)},
        'player': index % 2 == 0 ? 'sente' : 'gote',
        'piece_type': 'pawn',
        'move_type': 'normal',
        'damage': 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch + (index * 1000),
      },
    );

    return GameRecord(
      id: id,
      playedAt: DateTime.now(),
      createdAt: DateTime.now(),
      playerName: 'Test Player',
      aiDifficulty: '中級',
      playerColor: 'sente',
      result: result,
      moves: moves,
      durationSeconds: durationSeconds,
      stats: {
        'white_max_hp': 20.0,
        'black_max_hp': 20.0,
        'white_current_hp': 15.0,
        'black_current_hp': 0.0,
        'total_moves': moveCount,
      },
    );
  }

  group('Benchmark Result Tests', () {
    test('should create benchmark result', () {
      final result = BenchmarkResult(
        gamesPlayed: 100,
        sentWins: 50,
        goteWins: 45,
        draws: 5,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 500000,
        avgNodesPerMove: 5000.0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        difficulty: AIDifficulty.normal,
      );

      expect(result.gamesPlayed, equals(100));
      expect(result.sentWins, equals(50));
      expect(result.sentWinRate, equals(50.0));
    });

    test('should calculate elapsed seconds', () {
      final now = DateTime.now();
      final result = BenchmarkResult(
        gamesPlayed: 10,
        sentWins: 5,
        goteWins: 5,
        draws: 0,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 50000,
        avgNodesPerMove: 500.0,
        startTime: now.subtract(const Duration(seconds: 60)),
        endTime: now,
        difficulty: AIDifficulty.normal,
      );

      expect(result.elapsedSeconds, equals(60));
    });

    test('should calculate average game duration', () {
      final now = DateTime.now();
      final result = BenchmarkResult(
        gamesPlayed: 10,
        sentWins: 5,
        goteWins: 5,
        draws: 0,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 50000,
        avgNodesPerMove: 500.0,
        startTime: now.subtract(const Duration(seconds: 100)),
        endTime: now,
        difficulty: AIDifficulty.normal,
      );

      expect(result.avgGameDurationSeconds, equals(10.0));
    });

    test('should convert to JSON', () {
      final result = BenchmarkResult(
        gamesPlayed: 100,
        sentWins: 50,
        goteWins: 45,
        draws: 5,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 500000,
        avgNodesPerMove: 5000.0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        difficulty: AIDifficulty.normal,
      );

      final json = result.toJson();
      expect(json['games_played'], equals(100));
      expect(json['sent_wins'], equals(50));
      expect(json['sent_win_rate_percent'], equals(50.0));
    });

    test('should generate report text', () {
      final result = BenchmarkResult(
        gamesPlayed: 100,
        sentWins: 50,
        goteWins: 45,
        draws: 5,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 500000,
        avgNodesPerMove: 5000.0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        difficulty: AIDifficulty.normal,
      );

      final report = result.generateReport();
      expect(report, contains('BENCHMARK REPORT'));
      expect(report, contains('100'));
      expect(report, contains('50.00%'));
    });

    test('should provide string representation', () {
      final result = BenchmarkResult(
        gamesPlayed: 100,
        sentWins: 50,
        goteWins: 45,
        draws: 5,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 500000,
        avgNodesPerMove: 5000.0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        difficulty: AIDifficulty.normal,
      );

      final str = result.toString();
      expect(str, contains('games=100'));
      expect(str, contains('50.00%'));
    });
  });

  group('AI Benchmark Tests', () {
    late AIBenchmark benchmark;

    setUp(() {
      benchmark = AIBenchmark();
    });

    test('should initialize benchmark', () {
      expect(benchmark.isRunning, isFalse);
      expect(benchmark.currentGameCount, equals(0));
      expect(benchmark.targetGameCount, equals(0));
    });

    test('should start benchmark', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      expect(benchmark.isRunning, isTrue);
      expect(benchmark.targetGameCount, equals(10));
    });

    test('should record game results', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      final record = createTestGameRecord();
      benchmark.recordGameResult(record);

      final result = benchmark.getResult();
      expect(result.gamesPlayed, equals(1));
    });

    test('should record multiple games', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      for (int i = 0; i < 5; i++) {
        benchmark.recordGameResult(createTestGameRecord(id: 'game_$i'));
      }

      final result = benchmark.getResult();
      expect(result.gamesPlayed, equals(5));
    });

    test('should track thinking time', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      benchmark.recordThinkingTime(1000);
      benchmark.recordThinkingTime(2000);
      benchmark.recordThinkingTime(1500);

      final result = benchmark.getResult();
      expect(result.avgThinkingTimeMs, equals(1500.0));
    });

    test('should track min and max thinking time', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      benchmark.recordThinkingTime(1000);
      benchmark.recordThinkingTime(5000);
      benchmark.recordThinkingTime(2000);

      final result = benchmark.getResult();
      expect(result.minThinkingTimeMs, equals(1000));
      expect(result.maxThinkingTimeMs, equals(5000));
    });

    test('should record evaluated nodes', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      benchmark.recordNodesEvaluated(10000);
      benchmark.recordNodesEvaluated(20000);
      benchmark.recordNodesEvaluated(15000);

      final result = benchmark.getResult();
      expect(result.totalNodesEvaluated, equals(45000));
    });

    test('should calculate win rate', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      // 白が5勝、黒が5勝
      for (int i = 0; i < 5; i++) {
        benchmark.recordGameResult(
          createTestGameRecord(id: 'win_$i', result: GameResult.whiteWon),
        );
        benchmark.recordGameResult(
          createTestGameRecord(id: 'loss_$i', result: GameResult.blackWon),
        );
      }

      final result = benchmark.getResult();
      expect(result.sentWinRate, equals(50.0));
    });

    test('should handle zero games', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      final result = benchmark.getResult();
      expect(result.gamesPlayed, equals(0));
      expect(result.sentWinRate, equals(0));
    });

    test('should calculate progress', () {
      benchmark.startBenchmark(
        gameCount: 100,
        difficulty: AIDifficulty.normal,
      );

      for (int i = 0; i < 50; i++) {
        benchmark.recordGameResult(createTestGameRecord(id: 'game_$i'));
      }

      final progress = benchmark.getProgress();
      expect(progress, equals(0.5));
    });

    test('should stop benchmark', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      expect(benchmark.isRunning, isTrue);
      benchmark.stop();
      expect(benchmark.isRunning, isFalse);
    });

    test('should not record after stop', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      benchmark.recordGameResult(createTestGameRecord(id: 'game_1'));
      benchmark.stop();
      benchmark.recordGameResult(createTestGameRecord(id: 'game_2'));

      final result = benchmark.getResult();
      expect(result.gamesPlayed, equals(1));
    });

    test('should count draws', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      for (int i = 0; i < 3; i++) {
        benchmark.recordGameResult(
          createTestGameRecord(id: 'draw_$i', result: GameResult.draw),
        );
      }

      final result = benchmark.getResult();
      expect(result.draws, equals(3));
    });

    test('should generate result report', () {
      benchmark.startBenchmark(
        gameCount: 10,
        difficulty: AIDifficulty.normal,
      );

      for (int i = 0; i < 5; i++) {
        benchmark.recordGameResult(createTestGameRecord(id: 'game_$i'));
      }

      // Should not throw
      benchmark.printResult();
    });
  });

  group('AI Benchmark Suite Tests', () {
    late AIBenchmarkSuite suite;

    setUp(() {
      suite = AIBenchmarkSuite();
    });

    test('should create benchmark suite', () {
      expect(suite.results, isEmpty);
    });

    test('should store results for each difficulty', () async {
      await suite.runFullSuite(
        gamesPerDifficulty: 0,
        gameFactory: null,
      );

      expect(suite.results.length, equals(4));
      expect(suite.results.containsKey(AIDifficulty.easy), isTrue);
      expect(suite.results.containsKey(AIDifficulty.normal), isTrue);
      expect(suite.results.containsKey(AIDifficulty.hard), isTrue);
      expect(suite.results.containsKey(AIDifficulty.expert), isTrue);
    });

    test('should generate full report', () {
      // Manually add results
      suite.results[AIDifficulty.normal] = BenchmarkResult(
        gamesPlayed: 100,
        sentWins: 50,
        goteWins: 45,
        draws: 5,
        sentWinRate: 50.0,
        avgThinkingTimeMs: 2500.0,
        maxThinkingTimeMs: 5000,
        minThinkingTimeMs: 500,
        totalNodesEvaluated: 500000,
        avgNodesPerMove: 5000.0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        difficulty: AIDifficulty.normal,
      );

      final report = suite.generateFullReport();
      expect(report, contains('BENCHMARK SUITE REPORT'));
      expect(report, contains('SUMMARY ASSESSMENT'));
    });

    test('should print full report', () {
      // Should not throw
      suite.printReport();
    });
  });

  group('Performance Tests', () {
    test('benchmark should handle large game counts efficiently', () {
      final benchmark = AIBenchmark();
      benchmark.startBenchmark(
        gameCount: 1000,
        difficulty: AIDifficulty.normal,
      );

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        benchmark.recordThinkingTime(2500);
        benchmark.recordNodesEvaluated(5000);
      }

      stopwatch.stop();

      // Should handle 100 recordings quickly (< 50ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('result calculation should be fast', () {
      final benchmark = AIBenchmark();
      benchmark.startBenchmark(
        gameCount: 100,
        difficulty: AIDifficulty.normal,
      );

      for (int i = 0; i < 100; i++) {
        benchmark.recordGameResult(
          createTestGameRecord(id: 'game_$i'),
        );
      }

      final stopwatch = Stopwatch()..start();
      final result = benchmark.getResult();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(result.gamesPlayed, equals(100));
    });
  });
}
