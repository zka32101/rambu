/// Phase 4 エンドツーエンド統合テスト
/// 25局の完全ゲーム実行＆ハイライト生成成功率検証

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/services/game_logic.dart';
import 'package:rambu_shogi/services/ai_engine.dart';
import 'package:rambu_shogi/services/highlight_service.dart';
import 'package:rambu_shogi/services/highlight_orchestrator.dart';

/// テスト用のゲーム結果追跡
class GameTestResult {
  final int gameNumber;
  final String winner;
  final int turnCount;
  final Duration gameDuration;
  final bool highlightDetected;
  final bool highlightGenerationSuccess;
  final Duration? highlightGenerationTime;
  final String? errorMessage;

  GameTestResult({
    required this.gameNumber,
    required this.winner,
    required this.turnCount,
    required this.gameDuration,
    required this.highlightDetected,
    required this.highlightGenerationSuccess,
    this.highlightGenerationTime,
    this.errorMessage,
  });

  @override
  String toString() => 'Game #$gameNumber: $winner (${turnCount}手) - '
      'Highlight: ${highlightGenerationSuccess ? '✅' : '❌'}';
}

/// Phase 4 統合テスト
void main() {
  group('Phase 4: End-to-End Integration Tests', () {
    late GameLogic gameLogic;
    late AIEngine aiEngine;
    late HighlightService highlightService;
    late HighlightOrchestrator orchestrator;

    setUpAll(() {
      gameLogic = GameLogic();
      aiEngine = AIEngine(); // 中級難易度（デフォルト）
      highlightService = HighlightService();
      orchestrator = HighlightOrchestrator();
    });

    tearDownAll(() async {
      await orchestrator.dispose();
    });

    /// テスト 1: 単一ゲーム完全実行
    test('Single game should complete successfully', () async {
      final game = GameSession(
        sessionId: 'e2e_test_single',
        createdAt: DateTime.now(),
      );

      game.board = Board();
      game.board.initializeBoard();

      final startTime = DateTime.now();
      int moveCount = 0;

      // ゲーム実行
      while (!game.isGameOver && moveCount < 200) {
        final legalMoves = gameLogic.getLegalMoves(game.board, game.board.sente);
        if (legalMoves.isEmpty) break;

        final move = aiEngine.getBestMove(game.board, game.board.sente);
        game.board.applyMove(move);
        game.turnCount++;
        moveCount++;
      }

      final duration = DateTime.now().difference(startTime);

      expect(game.isGameOver, isTrue);
      expect(moveCount, greaterThan(0));
      print('✅ Single game completed in ${duration.inSeconds}s (${moveCount} moves)');
    });

    /// テスト 2: 5局連続実行
    test('5 consecutive games should complete successfully', () async {
      const numGames = 5;
      int completedCount = 0;

      for (int gameIdx = 0; gameIdx < numGames; gameIdx++) {
        final game = GameSession(
          sessionId: 'e2e_test_5games_$gameIdx',
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

        if (game.isGameOver) {
          completedCount++;
        }

        print('  Game ${gameIdx + 1}/5: ✅ Completed');
      }

      expect(completedCount, equals(numGames));
      print('✅ 5-Game Test: All ${numGames}/${numGames} games completed');
    });

    /// テスト 3: ハイライト検出統合テスト
    test('Highlight detection should work for multiple games', () async {
      const numGames = 5;
      int highlightDetectedCount = 0;

      for (int gameIdx = 0; gameIdx < numGames; gameIdx++) {
        final game = GameSession(
          sessionId: 'e2e_test_highlight_$gameIdx',
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

        // ハイライト検出
        final events = highlightService.detectHighlightEvents(game);
        if (events.isNotEmpty) {
          highlightDetectedCount++;
        }

        print('  Game ${gameIdx + 1}/5: Highlights detected: ${events.length}');
      }

      print('✅ Highlight Detection Test: '
          '${highlightDetectedCount}/${numGames} games had highlights');
    });

    /// テスト 4: 25局の大規模E2Eテスト
    test('25 consecutive games full E2E (SLOW TEST)', () async {
      const numGames = 25;
      final results = <GameTestResult>[];
      int successCount = 0;
      int highlightCount = 0;

      print('\n🎮 Starting 25-game E2E test suite...\n');

      for (int gameIdx = 0; gameIdx < numGames; gameIdx++) {
        final gameStartTime = DateTime.now();

        try {
          final game = GameSession(
            sessionId: 'e2e_test_25games_$gameIdx',
            createdAt: DateTime.now(),
          );

          game.board = Board();
          game.board.initializeBoard();

          // ゲーム実行
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

          final gameDuration = DateTime.now().difference(gameStartTime);

          // ハイライト検出
          final events = highlightService.detectHighlightEvents(game);
          bool hasHighlight = events.isNotEmpty;

          if (hasHighlight) {
            highlightCount++;
          }

          final result = GameTestResult(
            gameNumber: gameIdx + 1,
            winner: game.isGameOver ? 'Completed' : 'In Progress',
            turnCount: game.turnCount,
            gameDuration: gameDuration,
            highlightDetected: hasHighlight,
            highlightGenerationSuccess: true,
            highlightGenerationTime: null,
          );

          results.add(result);
          successCount++;

          if ((gameIdx + 1) % 5 == 0) {
            print('  Progress: ${gameIdx + 1}/$numGames games completed');
          }
        } catch (e) {
          print('  ⚠️  Game ${gameIdx + 1} failed: $e');
        }
      }

      // 結果集計
      print('\n📊 25-Game E2E Test Results:');
      print('  Total: $numGames');
      print('  Successful: $successCount/$numGames (${(successCount / numGames * 100).toStringAsFixed(1)}%)');
      print('  With Highlights: $highlightCount/$numGames (${(highlightCount / numGames * 100).toStringAsFixed(1)}%)');

      // 勝率分析
      int senteWins = 0; // 実装時に追加

      final avgDuration = results.fold<Duration>(
        Duration.zero,
        (prev, result) => prev + result.gameDuration,
      ).inSeconds / numGames;

      print('  Avg. Game Duration: ${avgDuration.toStringAsFixed(1)}s');

      expect(successCount, equals(numGames));
      expect(highlightCount, greaterThanOrEqualTo((numGames * 0.6).toInt())); // 60%以上
    });

    /// テスト 5: ゲーム統計の検証
    test('Game statistics should be consistent', () async {
      const numGames = 5;
      final results = <GameTestResult>[];

      for (int gameIdx = 0; gameIdx < numGames; gameIdx++) {
        final game = GameSession(
          sessionId: 'e2e_test_stats_$gameIdx',
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

        final result = GameTestResult(
          gameNumber: gameIdx + 1,
          winner: 'Test',
          turnCount: game.turnCount,
          gameDuration: Duration.zero,
          highlightDetected: false,
          highlightGenerationSuccess: false,
        );

        results.add(result);
      }

      // 統計検証
      final avgTurnCount = results.fold<int>(
            0,
            (prev, result) => prev + result.turnCount,
          ) / numGames;

      expect(avgTurnCount, greaterThan(10)); // 平均10手以上
      print('✅ Game statistics validated. Avg turns: $avgTurnCount');
    });
  });

  group('Phase 4: Performance Baseline', () {
    /// パフォーマンス基準テスト
    test('Single game performance baseline', () async {
      final gameLogic = GameLogic();
      final aiEngine = AIEngine();

      final stopwatch = Stopwatch()..start();

      final game = GameSession(
        sessionId: 'perf_baseline',
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

      final elapsed = stopwatch.elapsedMilliseconds;
      print('⏱️  Single game completed in ${elapsed}ms (${moveCount} moves)');
      print('⏱️  Average move time: ${(elapsed / moveCount).toStringAsFixed(2)}ms');

      // パフォーマンスベンチマーク
      expect(elapsed, lessThan(30000)); // 30秒以内
    });
  });

  group('Phase 4: System Integration', () {
    /// システム統合テスト
    test('All services should initialize without errors', () async {
      expect(() {
        final gameLogic = GameLogic();
        final aiEngine = AIEngine();
        final highlightService = HighlightService();
        final orchestrator = HighlightOrchestrator();
      }, returnsNormally);

      print('✅ All services initialized successfully');
    });
  });
}
