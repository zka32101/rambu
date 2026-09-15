/// 乱舞将棋のAI実装
/// 評価関数とアルファベータ探索

import 'dart:math' as math;
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/evaluation_params.dart';
import 'package:rambu_shogi/services/game_logic.dart';
import 'package:rambu_shogi/utils/constants.dart';

/// AI エンジン（アルファベータ探索 + 評価関数）
class AIEngine {
  final Difficulty difficulty;
  final math.Random _random = math.Random();
  int _evaluationCount = 0;

  /// 評価パラメータ（Phase 2でのバランス調整用）
  /// nullの場合はEvaluationConstantsから取得
  late final EvaluationParams _params;

  AIEngine({
    this.difficulty = Difficulty.normal,
    EvaluationParams? params,
  }) {
    _params = params ?? _getDefaultParams();
  }

  /// 難易度に応じたデフォルトパラメータを取得
  EvaluationParams _getDefaultParams() {
    // Phase 2では baseline を使用（後で調整予定）
    return EvaluationParams.baseline;
  }

  /// 現在使用中のパラメータを取得
  EvaluationParams get params => _params;

  /// 最善手を探す
  Move findBestMove(GameSession game) {
    _evaluationCount = 0;
    final moves = GameLogic.getLegalMoves(game);

    if (moves.isEmpty) {
      throw StateError('No legal moves available');
    }

    if (moves.length == 1) {
      return moves.first;
    }

    // アルファベータ探索で評価
    double bestScore = double.negativeInfinity;
    final bestMoves = <Move>[];

    for (final move in moves) {
      final clonedGame = game.clone();
      clonedGame.applyMove(move);

      final score = _alphaBeta(
        clonedGame,
        SearchConstants.maxDepth - 1,
        SearchConstants.initialAlpha.toDouble(),
        SearchConstants.initialBeta.toDouble(),
        maximizing: false, // 相手のターン
      );

      if (score > bestScore) {
        bestScore = score;
        bestMoves.clear();
        bestMoves.add(move);
      } else if ((score - bestScore).abs() < 0.01) {
        // ほぼ同じスコアなら候補に追加
        bestMoves.add(move);
      }
    }

    // 同点の場合、Top 3からランダム選択（バリエーション追加）
    final topMoves = bestMoves.take(3).toList();
    return topMoves[_random.nextInt(topMoves.length)];
  }

  /// アルファベータ探索
  double _alphaBeta(
    GameSession game,
    int depth,
    double alpha,
    double beta,
    {required bool maximizing},
  ) {
    // ベースケース
    if (depth == 0 || game.isGameOver) {
      return _evaluateBoard(game);
    }

    final moves = GameLogic.getLegalMoves(game);
    if (moves.isEmpty) {
      return _evaluateBoard(game);
    }

    if (maximizing) {
      // 最大化プレイヤー（先手）
      double maxEval = double.negativeInfinity;
      for (final move in moves) {
        final clonedGame = game.clone();
        clonedGame.applyMove(move);

        final eval = _alphaBeta(
          clonedGame,
          depth - 1,
          alpha,
          beta,
          maximizing: false,
        );

        maxEval = math.max(maxEval, eval);
        alpha = math.max(alpha, eval);

        if (beta <= alpha) {
          break;  // ベータカット
        }
      }
      return maxEval;
    } else {
      // 最小化プレイヤー（後手）
      double minEval = double.infinity;
      for (final move in moves) {
        final clonedGame = game.clone();
        clonedGame.applyMove(move);

        final eval = _alphaBeta(
          clonedGame,
          depth - 1,
          alpha,
          beta,
          maximizing: true,
        );

        minEval = math.min(minEval, eval);
        beta = math.min(beta, eval);

        if (beta <= alpha) {
          break;  // アルファカット
        }
      }
      return minEval;
    }
  }

  /// 盤面を評価する（AI評価関数の本体）
  /// 先手視点のスコア（正 = 先手有利、負 = 後手有利）
  double _evaluateBoard(GameSession game) {
    _evaluationCount++;

    // 終了局面の評価
    if (game.state == GameState.whiteWon) {
      return 99999.0;  // 先手勝利
    } else if (game.state == GameState.blackWon) {
      return -99999.0;  // 後手勝利
    }

    final board = game.board;
    double score = 0.0;

    // 1. 駒価値スコア
    score += _evaluatePieceValues(board);

    // 2. HP価値スコア
    score += _evaluateHPValues(board);

    // 3. 位置評価スコア
    score += _evaluatePositionValues(board);

    // 4. テンポボーナス（パラメータから取得）
    if (game.currentPlayer == PlayerColor.sente) {
      score += _params.tempoBonus;
    } else {
      score -= _params.tempoBonus;
    }

    // 5. クリティカル局面の特殊評価
    score += _evaluateCriticalSituations(board);

    // 6. ランダムノイズ（同点局面の多様化）
    final noise =
        _random.nextDouble() * difficulty.noiseRange * 2 - difficulty.noiseRange;
    score += noise;

    return score;
  }

  /// 駒価値スコアを評価
  double _evaluatePieceValues(Board board) {
    double score = 0.0;

    for (final piece in board.getWhitePieces()) {
      score += Piece.getPieceValue(piece.type);
    }

    for (final piece in board.getBlackPieces()) {
      score -= Piece.getPieceValue(piece.type);
    }

    return score * difficulty.piecValueWeight;
  }

  /// HP価値スコアを評価
  double _evaluateHPValues(Board board) {
    double score = 0.0;
    final hpWeight = 1.0 - difficulty.piecValueWeight;

    // 先手のHP価値
    for (final piece in board.getWhitePieces()) {
      if (piece.type != PieceType.king) {
        final hpValue = Piece.getPieceValue(piece.type) * piece.hpRatio;
        score += hpValue;
      }
    }

    // 後手のHP価値
    for (final piece in board.getBlackPieces()) {
      if (piece.type != PieceType.king) {
        final hpValue = Piece.getPieceValue(piece.type) * piece.hpRatio;
        score -= hpValue;
      }
    }

    return score * hpWeight;
  }

  /// 位置評価スコアを評価
  double _evaluatePositionValues(Board board) {
    double score = 0.0;

    for (final piece in board.getAllPieces()) {
      // 駒の位置を探す
      int? posX, posY;
      for (int y = 1; y <= 9; y++) {
        for (int x = 1; x <= 9; x++) {
          if (board.getPieceAt(Position(x, y)) == piece) {
            posX = x;
            posY = y;
            break;
          }
        }
        if (posX != null) break;
      }

      if (posX == null || posY == null) continue;

      final bonus = EvaluationConstants.getPositionBonus(
        posX,
        posY,
        piece.type,
      );

      if (piece.player == PlayerColor.sente) {
        score += bonus;
      } else {
        score -= bonus;
      }
    }

    return score;
  }

  /// クリティカル局面の特殊評価
  double _evaluateCriticalSituations(Board board) {
    double score = 0.0;

    for (final piece in board.getAllPieces()) {
      if (!piece.isAlive) continue;

      // 駒の位置を探す
      Position? piecePos;
      for (int y = 1; y <= 9; y++) {
        for (int x = 1; x <= 9; x++) {
          if (board.getPieceAt(Position(x, y)) == piece) {
            piecePos = Position(x, y);
            break;
          }
        }
        if (piecePos != null) break;
      }

      if (piecePos == null) continue;

      final opponent = piece.player.opponent;
      final opponentKing = board.getKing(opponent);
      if (opponentKing == null) continue;

      final kingPos = opponentKing == piece ? null : opponentKing;

      // 相手の王に隣接する駒配置
      if (kingPos != null && piecePos.chebyshevDistanceTo(kingPos) <= 1) {
        final bonus = _params.criticalAdjacentBonus * _params.criticalSituationCoefficient;
        if (piece.player == PlayerColor.sente) {
          score += bonus;
        } else {
          score -= bonus;
        }
      }

      // クリティカルダメージ可能な位置に飛び道具
      if (piece.hasRangedAttack) {
        final rangedPositions =
            GameLogic.getRangedAttackPositions(board, piecePos, piece);
        for (final target in rangedPositions) {
          final targetPiece = board.getPieceAt(target);
          if (targetPiece != null &&
              targetPiece.player != piece.player &&
              targetPiece.currentHP <= 1) {
            final bonus = _params.criticalDamageBonus * _params.criticalSituationCoefficient;
            if (piece.player == PlayerColor.sente) {
              score += bonus;
            } else {
              score -= bonus;
            }
          }
        }
      }

      // 自駒のHP満タン
      if (piece.currentHP == piece.maxHP && piece.type != PieceType.king) {
        final bonus = _params.fullHPBonus * _params.criticalSituationCoefficient;
        if (piece.player == PlayerColor.sente) {
          score += bonus;
        } else {
          score -= bonus;
        }
      }

      // 相手駒のHP1（一撃死寸前）
      if (piece.type == PieceType.king) continue;
      if (piece.currentHP == 1) {
        final bonus = _params.enemyLowHPBonus * _params.criticalSituationCoefficient;
        if (piece.player == PlayerColor.gote) {
          // 後手の弱い駒 = 先手に有利
          score += bonus;
        } else {
          // 先手の弱い駒 = 後手に有利
          score -= bonus;
        }
      }
    }

    return score;
  }

  int get evaluationCount => _evaluationCount;
}

/// Position クラスの拡張（相対距離計算用）
extension PositionExtension on Position {
  int chebyshevDistanceTo(Position other) =>
      (x - other.x).abs() > (y - other.y).abs()
          ? (x - other.x).abs()
          : (y - other.y).abs();
}
