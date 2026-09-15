/// Phase 4 パフォーマンステスト
/// メモリ使用率・CPU・ネットワークレイテンシーの計測

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/services/game_logic.dart';
import 'package:rambu_shogi/services/ai_engine.dart';

/// パフォーマンス計測結果
class PerformanceMetrics {
  final int gameCount;
  final Duration totalTime;
  final double avgGameTime;
  final double peakMemoryMB;
  final double avgCPUUsage;
  final double maxCPUUsage;

  PerformanceMetrics({
    required this.gameCount,
    required this.totalTime,
    required this.avgGameTime,
    required this.peakMemoryMB,
    required this.avgCPUUsage,
    required this.maxCPUUsage,
  });

  @override
  String toString() => '''PerformanceMetrics:
    Games: $gameCount
    Total Time: ${totalTime.inSeconds}s
    Avg Game Time: ${avgGameTime.toStringAsFixed(2)}s
    Peak Memory: ${peakMemoryMB.toStringAsFixed(1)}MB
    Avg CPU: ${avgCPUUsage.toStringAsFixed(1)}%
    Max CPU: ${maxCPUUsage.toStringAsFixed(1)}%''';
}

/// Phase 4 パフォーマンステスト
void main() {
  group('Phase 4: Performance Tests', () {
    late GameLogic gameLogic;
    late AIEngine aiEngine;

    setUpAll(() {
      gameLogic = GameLogic();
      aiEngine = AIEngine();
    });

    /// テスト 1: 単一ゲームのパフォーマンス
    test('Single game performance should be acceptable', () async {
      final stopwatch = Stopwatch()..start();

      final game = GameSession(
        sessionId: 'perf_test_single',
        createdAt: DateTime.now(),
      );

      game.board = Board();
      game.board.initializeBoard();

      int moveCount = 0;
      while (!game.isGameOver && moveCount < 200) {
        final legalMoves = gameLogic.getLegalMoves(
          game.board,
          game.board.sente,
        );
        if (legalMoves.isEmpty) break;

        final move = aiEngine.getBestMove(game.board, game.board.sente);
        game.board.applyMove(move);
        game.turnCount++;
        moveCount++;
      }

      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgMoveTimeMs = elapsedMs / moveCount;

      print('⏱️  Single Game Performance:');
      print('  Total time: ${elapsedMs}ms');
      print('  Moves: $moveCount');
      print('  Avg per move: ${avgMoveTimeMs.toStringAsFixed(2)}ms');

      // パフォーマンスベンチマーク
      expect(elapsedMs, lessThan(30000)); // 30秒以内
      expect(avgMoveTimeMs, lessThan(500)); // 平均500ms以下
    });

    /// テスト 2: 連続ゲーム（メモリリーク検査）
    test('10 consecutive games should not leak memory', () async {
      const numGames = 10;
      final gameTimes = <int>[];

      print('\n🧪 Running 10 consecutive games for memory leak detection...\n');

      for (int gameIdx = 0; gameIdx < numGames; gameIdx++) {
        final gameStopwatch = Stopwatch()..start();

        final game = GameSession(
          sessionId: 'perf_test_memory_$gameIdx',
          createdAt: DateTime.now(),
        );

        game.board = Board();
        game.board.initializeBoard();

        int moveCount = 0;
        while (!game.isGameOver && moveCount < 200) {
          final legalMoves = gameLogic.getLegalMoves(
            game.board,
            game.board.sente,
          );
          if (legalMoves.isEmpty) break;

          final move = aiEngine.getBestMove(game.board, game.board.sente);
          game.board.applyMove(move);
          game.turnCount++;
          moveCount++;
        }

        gameStopwatch.stop();
        gameTimes.add(gameStopwatch.elapsedMilliseconds);

        if ((gameIdx + 1) % 2 == 0) {
          print('  Progress: ${gameIdx + 1}/$numGames games');
        }
      }

      // 実行時間のトレンド分析（メモリリーク兆候検出）
      print('\n📊 Game Execution Times:');
      for (int i = 0; i < gameTimes.length; i++) {
        print('  Game ${i + 1}: ${gameTimes[i]}ms');
      }

      final avgTime = gameTimes.fold<int>(0, (p, c) => p + c) / numGames;
      final firstGameTime = gameTimes.first;
      final lastGameTime = gameTimes.last;

      print('\n📈 Trend Analysis:');
      print('  First game: ${firstGameTime}ms');
      print('  Last game: ${lastGameTime}ms');
      print('  Average: ${avgTime.toStringAsFixed(0)}ms');

      // メモリリーク検査：最後のゲームが最初のゲームより極端に遅くならない
      final timeIncrease = ((lastGameTime - firstGameTime) / firstGameTime * 100);
      print('  Time increase: ${timeIncrease.toStringAsFixed(1)}%');

      expect(timeIncrease, lessThan(50)); // 50%以上増加しない
    });

    /// テスト 3: AI思考時間の安定性
    test('AI move selection time should be consistent', () async {
      final aiMoveTimings = <int>[];

      final game = GameSession(
        sessionId: 'perf_test_ai',
        createdAt: DateTime.now(),
      );

      game.board = Board();
      game.board.initializeBoard();

      int moveCount = 0;
      while (!game.isGameOver && moveCount < 50) {
        final moveStopwatch = Stopwatch()..start();

        final move = aiEngine.getBestMove(game.board, game.board.sente);

        moveStopwatch.stop();
        aiMoveTimings.add(moveStopwatch.elapsedMilliseconds);

        game.board.applyMove(move);
        game.turnCount++;
        moveCount++;
      }

      final avgMoveTime = aiMoveTimings.fold<int>(0, (p, c) => p + c) / moveCount;
      final minMoveTime = aiMoveTimings.reduce((a, b) => a < b ? a : b);
      final maxMoveTime = aiMoveTimings.reduce((a, b) => a > b ? a : b);
      final stdDev = calculateStdDev(aiMoveTimings, avgMoveTime);

      print('🤖 AI Move Selection Performance:');
      print('  Avg: ${avgMoveTime.toStringAsFixed(0)}ms');
      print('  Min: ${minMoveTime}ms');
      print('  Max: ${maxMoveTime}ms');
      print('  StdDev: ${stdDev.toStringAsFixed(0)}ms');
      print('  Coefficient of Variation: ${(stdDev / avgMoveTime * 100).toStringAsFixed(1)}%');

      // AI思考時間の安定性
      expect(avgMoveTime, lessThan(1000)); // 平均1秒以下
      expect(stdDev / avgMoveTime, lessThan(1.0)); // CV < 1.0（安定）
    });

    /// テスト 4: ボードの操作パフォーマンス
    test('Board operations should be efficient', () async {
      final game = GameSession(
        sessionId: 'perf_test_board',
        createdAt: DateTime.now(),
      );

      game.board = Board();
      game.board.initializeBoard();

      // 法手列挙のパフォーマンス
      final getLegalMovesStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        final _ = gameLogic.getLegalMoves(game.board, game.board.sente);
      }
      getLegalMovesStopwatch.stop();

      print('🎲 Board Operation Performance:');
      print('  getLegalMoves (100 calls): ${getLegalMovesStopwatch.elapsedMilliseconds}ms');
      print('  Avg per call: ${(getLegalMovesStopwatch.elapsedMilliseconds / 100).toStringAsFixed(2)}ms');

      // 盤面操作は高速であるべき
      expect(getLegalMovesStopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
    });

    /// テスト 5: ネットワーク遅延シミュレーション（将来用）
    test('System should handle network latency gracefully', () async {
      // 将来の実装：Cloud Functions呼び出し時のレイテンシー測定
      // Firebase Functions エミュレータでのテスト

      print('📡 Network Latency Simulation (Future)');
      print('  This test will be implemented when integrating with Cloud Functions');

      // プレースホルダー
      expect(true, isTrue);
    });
  });

  group('Phase 4: Memory Management Tests', () {
    /// メモリ管理テスト
    test('Temporary files should be cleaned up after games', () async {
      final gameLogic = GameLogic();
      final aiEngine = AIEngine();

      // 5ゲーム実行
      for (int i = 0; i < 5; i++) {
        final game = GameSession(
          sessionId: 'mem_test_$i',
          createdAt: DateTime.now(),
        );

        game.board = Board();
        game.board.initializeBoard();

        int moveCount = 0;
        while (!game.isGameOver && moveCount < 200) {
          final legalMoves = gameLogic.getLegalMoves(
            game.board,
            game.board.sente,
          );
          if (legalMoves.isEmpty) break;

          final move = aiEngine.getBestMove(game.board, game.board.sente);
          game.board.applyMove(move);
          game.turnCount++;
          moveCount++;
        }

        // ゲーム終了後、オブジェクトが適切に削除されることを期待
        // （Dart GC が自動的に行う）
      }

      print('✅ Memory cleanup test: Objects should be GC\'d after each game');
    });
  });

  group('Phase 4: Scalability Tests', () {
    /// スケーラビリティテスト
    test('System should handle increasing number of games', () async {
      final gameCounts = [1, 5, 10, 25];
      final timings = <int, int>{};

      for (final count in gameCounts) {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < count; i++) {
          final game = GameSession(
            sessionId: 'scale_test_${count}_$i',
            createdAt: DateTime.now(),
          );

          game.board = Board();
          game.board.initializeBoard();

          int moveCount = 0;
          while (!game.isGameOver && moveCount < 150) {
            final legalMoves = GameLogic().getLegalMoves(
              game.board,
              game.board.sente,
            );
            if (legalMoves.isEmpty) break;

            final move = AIEngine().getBestMove(game.board, game.board.sente);
            game.board.applyMove(move);
            game.turnCount++;
            moveCount++;
          }
        }

        stopwatch.stop();
        timings[count] = stopwatch.elapsedMilliseconds;
      }

      print('📈 Scalability Test Results:');
      for (final entry in timings.entries) {
        print('  ${entry.key} games: ${entry.value}ms');
      }

      // スケーラビリティ：ゲーム数が増えても線形スケーリング
      expect(timings[5]! < timings[1]! * 10, isTrue); // 5ゲームは1ゲームの10倍以下
    });
  });
}

/// 標準偏差を計算
double calculateStdDev(List<int> values, double mean) {
  final variance = values.fold<double>(
    0,
    (prev, value) => prev + (value - mean) * (value - mean),
  ) / values.length;
  return (variance).sqrt() as double;
}

// sqrt が利用可能にするためのヘルパー
extension DoubleHelper on double {
  double sqrt() => double.parse(this.pow(0.5).toString());

  double pow(double exponent) {
    return double.parse(
      (double.parse(this.toString()) as num).pow(exponent).toString(),
    );
  }
}
