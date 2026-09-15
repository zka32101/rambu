/// ベンチマーク用ユーティリティ
/// Phase 2: パラメータ調整測定用

import 'dart:io';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/ai_engine.dart';
import 'package:rambu_shogi/services/evaluation_params.dart';
import 'package:rambu_shogi/services/game_logic.dart';

/// ベンチマーク結果
class BenchmarkResult {
  final String paramName;
  final String? paramDescription;
  final int gamesPlayed;
  final int senteWins;
  final int goteWins;
  final double senteWinRate;
  final List<int> gameDurations;
  final DateTime startedAt;
  final DateTime completedAt;

  double get avgDuration => gameDurations.isEmpty
      ? 0.0
      : gameDurations.reduce((a, b) => a + b) / gameDurations.length;

  double get avgTurns =>
      (gameDurations.length > 0)
          ? gameDurations.length.toDouble()
          : 0.0;

  bool get isBalanced =>
      senteWinRate >= 0.47 && senteWinRate <= 0.53;

  bool get isSenteAdvantage => senteWinRate > 0.53;
  bool get isGoteAdvantage => senteWinRate < 0.47;

  BenchmarkResult({
    required this.paramName,
    required this.paramDescription,
    required this.gamesPlayed,
    required this.senteWins,
    required this.goteWins,
    required this.gameDurations,
    required this.startedAt,
    required this.completedAt,
  }) : senteWinRate = senteWins / gamesPlayed;

  /// ベンチマーク結果をレポート形式で出力
  String toReport() {
    final duration = completedAt.difference(startedAt).inSeconds;
    final buffer = StringBuffer();

    buffer.writeln('📊 ベンチマーク結果: $paramName');
    buffer.writeln('─' * 50);
    if (paramDescription != null) {
      buffer.writeln('説明: $paramDescription');
    }
    buffer.writeln('対局数: $gamesPlayed');
    buffer.writeln('先手勝: $senteWins (${ (senteWinRate * 100).toStringAsFixed(1)}%)');
    buffer.writeln('後手勝: $goteWins (${((1 - senteWinRate) * 100).toStringAsFixed(1)}%)');
    buffer.writeln('平均ゲーム時間: ${avgDuration.toStringAsFixed(1)}秒');
    buffer.writeln('実行時間: ${duration}秒');

    // バランス判定
    if (isBalanced) {
      buffer.writeln('バランス評価: ✅ 良好（50±3%範囲内）');
    } else if (isSenteAdvantage) {
      buffer.writeln('バランス評価: ⚠️  先手優位（補正推奨）');
    } else {
      buffer.writeln('バランス評価: ⚠️  後手優位（補正推奨）');
    }

    return buffer.toString();
  }

  @override
  String toString() => toReport();
}

/// ベンチマーク実行ユーティリティ
class BenchmarkUtils {
  /// 単一ゲームを実行
  static Future<(PlayerColor, int)> playGame(
    Difficulty difficulty, {
    EvaluationParams? params,
  }) async {
    final game = GameSession(
      sessionId: 'bench-${DateTime.now().millisecondsSinceEpoch}',
      aiDifficulty: difficulty,
      playerColor: PlayerColor.sente,
    );

    game.start();

    final aiSente = AIEngine(difficulty: difficulty, params: params);
    final aiGote = AIEngine(difficulty: difficulty, params: params);

    // 最大500手でゲーム終了
    int turns = 0;
    while (!game.isGameOver && game.turnCount < 500) {
      try {
        if (game.currentPlayer == PlayerColor.sente) {
          if (!game.board.secondHandBonusAvailable) {
            final move = aiSente.findBestMove(game);
            game.applyMove(move);
          } else {
            game.board.secondHandBonusAvailable = false;
            game.turnCount++;
            game.currentPlayer = game.currentPlayer.opponent;
          }
        } else {
          if (!game.board.secondHandBonusAvailable) {
            final move = aiGote.findBestMove(game);
            game.applyMove(move);
          } else {
            final moves = GameLogic.getLegalMoves(game);
            if (moves.isNotEmpty) {
              game.applyMove(moves.first);
            }
          }
        }
        turns++;
      } catch (e) {
        break;
      }
    }

    final winner = game.winner ?? PlayerColor.gote;
    return (winner, game.turnCount);
  }

  /// ベンチマークを実行
  static Future<BenchmarkResult> runBenchmark(
    Difficulty difficulty, {
    required int games,
    EvaluationParams? params,
  }) async {
    final startedAt = DateTime.now();
    final paramName = params?.name ?? 'default';
    final paramDesc = params?.description;

    int senteWins = 0;
    int goteWins = 0;
    final gameDurations = <int>[];

    for (int i = 0; i < games; i++) {
      final (winner, duration) = await playGame(
        difficulty,
        params: params,
      );

      if (winner == PlayerColor.sente) {
        senteWins++;
      } else {
        goteWins++;
      }

      gameDurations.add(duration);

      // 進捗表示
      if ((i + 1) % 10 == 0 || i + 1 == games) {
        final progress = ((i + 1) / games * 100).toStringAsFixed(1);
        final rate = (senteWins / (i + 1) * 100).toStringAsFixed(1);
        print('進捗: $progress% (先手: $rate%)');
      }
    }

    final completedAt = DateTime.now();

    return BenchmarkResult(
      paramName: paramName,
      paramDescription: paramDesc,
      gamesPlayed: games,
      senteWins: senteWins,
      goteWins: goteWins,
      gameDurations: gameDurations,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  /// 複数のパラメータセットをテスト
  static Future<List<BenchmarkResult>> compareParameters(
    Difficulty difficulty, {
    required List<EvaluationParams> paramsList,
    required int gamesPerParam,
  }) async {
    final results = <BenchmarkResult>[];

    for (final params in paramsList) {
      print('\n🔄 テスト中: ${params.name}');
      final result = await runBenchmark(
        difficulty,
        games: gamesPerParam,
        params: params,
      );
      results.add(result);
      print(result.toReport());
    }

    return results;
  }

  /// テンポボーナス変動テスト
  static Future<List<BenchmarkResult>> tempoVariationTest({
    Difficulty difficulty = Difficulty.normal,
    int gamesPerTempo = 20,
  }) async {
    print('🎯 テンポボーナス変動テストを開始します');
    print('難易度: ${difficulty.label}');
    print('各テンポごとのゲーム数: $gamesPerTempo');
    print('─' * 50);

    final paramsList = EvaluationParams.generateTempoVariations();
    return compareParameters(
      difficulty,
      paramsList: paramsList,
      gamesPerParam: gamesPerTempo,
    );
  }

  /// ベンチマーク結果を比較レポート出力
  static void printComparisonReport(List<BenchmarkResult> results) {
    print('\n' + '=' * 60);
    print('📈 ベンチマーク比較レポート');
    print('=' * 60);

    // ソート: 先手勝率が50%に近い順
    results.sort((a, b) =>
        (a.senteWinRate - 0.5).abs()
            .compareTo((b.senteWinRate - 0.5).abs()));

    for (final result in results) {
      final rating = result.isBalanced
          ? '✅'
          : result.isSenteAdvantage
              ? '⚠️  (先手優位)'
              : '⚠️  (後手優位)';

      print(
          '$rating ${result.paramName}: 先手${(result.senteWinRate * 100).toStringAsFixed(1)}% (${result.senteWins}/${result.gamesPlayed})');
    }

    final best = results.first;
    print('\n🏆 最適パラメータ: ${best.paramName}');
    print('先手勝率: ${(best.senteWinRate * 100).toStringAsFixed(1)}%');
    if (best.paramDescription != null) {
      print('説明: ${best.paramDescription}');
    }
  }
}
