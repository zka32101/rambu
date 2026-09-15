/// 乱舞将棋の対局記録（棋譜）
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';

part 'game_record.freezed.dart';
part 'game_record.g.dart';

/// 対局結果
enum GameResult {
  whiteWon,  // 先手勝利
  blackWon,  // 後手勝利
  draw,      // 引き分け
  aborted;   // 中止

  String get label => switch (this) {
    GameResult.whiteWon => '先手勝利',
    GameResult.blackWon => '後手勝利',
    GameResult.draw => '引き分け',
    GameResult.aborted => '中止',
  };

  String get toJson => switch (this) {
    GameResult.whiteWon => 'white_won',
    GameResult.blackWon => 'black_won',
    GameResult.draw => 'draw',
    GameResult.aborted => 'aborted',
  };

  static GameResult fromJson(String json) => switch (json) {
    'white_won' => GameResult.whiteWon,
    'black_won' => GameResult.blackWon,
    'draw' => GameResult.draw,
    'aborted' => GameResult.aborted,
    _ => GameResult.aborted,
  };
}

/// 分析ノード（変化手）
@freezed
class AnalysisNode with _$AnalysisNode {
  const factory AnalysisNode({
    required Move move,
    @Default([]) List<AnalysisNode> children,
    String? annotation,  // 評価・コメント
    double? evaluation,  // 局面評価値
  }) = _AnalysisNode;

  factory AnalysisNode.fromJson(Map<String, dynamic> json) =>
      _$AnalysisNodeFromJson(json);
}

/// 対局記録（棋譜）
@freezed
class GameRecord with _$GameRecord {
  const factory GameRecord({
    /// Firestore ドキュメント ID
    required String id,

    /// 対局日時
    required DateTime playedAt,

    /// 保存日時
    required DateTime createdAt,

    /// プレイヤー名（ローカル表示用）
    String? playerName,

    /// AI難易度
    required String aiDifficulty,  // easy, normal, hard

    /// プレイヤーの色（先手/後手）
    required String playerColor,  // sente, gote

    /// 対局結果
    required GameResult result,

    /// 着手列（JSON形式）
    required List<Map<String, dynamic>> moves,

    /// 対局時間（秒）
    required int durationSeconds,

    /// 変化手（オプション）
    @Default([]) List<AnalysisNode> variations,

    /// ハイライト動画URL
    String? highlightVideoUrl,

    /// 統計情報
    required Map<String, dynamic> stats,
  }) = _GameRecord;

  factory GameRecord.fromJson(Map<String, dynamic> json) =>
      _$GameRecordFromJson(json);

  /// GameSessionから作成
  factory GameRecord.fromGameSession({
    required String id,
    required GameSession gameSession,
    String? playerName,
  }) {
    return GameRecord(
      id: id,
      playedAt: gameSession.startedAt ?? DateTime.now(),
      createdAt: DateTime.now(),
      playerName: playerName ?? 'Player',
      aiDifficulty: gameSession.aiDifficulty.label,
      playerColor: gameSession.playerColor == PlayerColor.sente ? 'sente' : 'gote',
      result: _determineResult(gameSession),
      moves: gameSession.moveHistory.moves
          .map((m) => _moveToJson(m))
          .toList(),
      durationSeconds: gameSession.getGameDurationSeconds() ?? 0,
      stats: _buildStats(gameSession),
    );
  }

  static GameResult _determineResult(GameSession gameSession) {
    return switch (gameSession.state) {
      GameState.whiteWon => GameResult.whiteWon,
      GameState.blackWon => GameResult.blackWon,
      GameState.draw => GameResult.draw,
      _ => GameResult.aborted,
    };
  }

  static Map<String, dynamic> _moveToJson(Move move) {
    return {
      'from': {'x': move.from.x, 'y': move.from.y},
      'to': {'x': move.to.x, 'y': move.to.y},
      'player': move.player == PlayerColor.sente ? 'sente' : 'gote',
      'piece_type': _piecTypeToString(move.piece.type),
      'move_type': _moveTypeToString(move.moveType),
      'damage': move.damageDealt,
      'target_hp_before': move.targetHPBefore,
      'target_hp_after': move.targetHPAfter,
      'timestamp': move.timestamp,
      'is_critical': move.isCritical,
    };
  }

  static Map<String, dynamic> _buildStats(GameSession gameSession) {
    final whitePieces = gameSession.board.getWhitePieces();
    final blackPieces = gameSession.board.getBlackPieces();

    // クリティカルヒット数を数える
    int whiteRangedAttacks = 0;
    int blackRangedAttacks = 0;
    int criticalHits = 0;

    for (final move in gameSession.moveHistory.moves) {
      if (move.isRangedAttack) {
        if (move.player == PlayerColor.sente) {
          whiteRangedAttacks++;
        } else {
          blackRangedAttacks++;
        }
        if (move.isCritical) {
          criticalHits++;
        }
      }
    }

    return {
      'white_max_hp': whitePieces
          .where((p) => p.type != PieceType.king)
          .fold(0.0, (sum, p) => sum + p.maxHP),
      'black_max_hp': blackPieces
          .where((p) => p.type != PieceType.king)
          .fold(0.0, (sum, p) => sum + p.maxHP),
      'white_current_hp': whitePieces
          .where((p) => p.type != PieceType.king)
          .fold(0.0, (sum, p) => sum + p.currentHP),
      'black_current_hp': blackPieces
          .where((p) => p.type != PieceType.king)
          .fold(0.0, (sum, p) => sum + p.currentHP),
      'white_ranged_attacks': whiteRangedAttacks,
      'black_ranged_attacks': blackRangedAttacks,
      'critical_hits': criticalHits,
      'total_moves': gameSession.moveHistory.length,
    };
  }

  static String _piecTypeToString(PieceType type) {
    return switch (type) {
      PieceType.king => 'king',
      PieceType.rook => 'rook',
      PieceType.bishop => 'bishop',
      PieceType.gold => 'gold',
      PieceType.silver => 'silver',
      PieceType.knight => 'knight',
      PieceType.lance => 'lance',
      PieceType.pawn => 'pawn',
    };
  }

  static String _moveTypeToString(MoveType type) {
    return switch (type) {
      MoveType.normal => 'normal',
      MoveType.ranged => 'ranged',
      MoveType.capture => 'capture',
      MoveType.promote => 'promote',
    };
  }
}

/// ゲーム記録統計情報
@freezed
class GameRecordStats with _$GameRecordStats {
  const factory GameRecordStats({
    required double whiteMaxHP,
    required double blackMaxHP,
    required double whiteCurrentHP,
    required double blackCurrentHP,
    required int whiteRangedAttacks,
    required int blackRangedAttacks,
    required int criticalHits,
    required int totalMoves,
  }) = _GameRecordStats;

  factory GameRecordStats.fromJson(Map<String, dynamic> json) =>
      _$GameRecordStatsFromJson(json);

  /// ゲーム記録から統計を作成
  factory GameRecordStats.fromGameRecord(GameRecord record) {
    final stats = record.stats;
    return GameRecordStats(
      whiteMaxHP: (stats['white_max_hp'] as num?)?.toDouble() ?? 0,
      blackMaxHP: (stats['black_max_hp'] as num?)?.toDouble() ?? 0,
      whiteCurrentHP: (stats['white_current_hp'] as num?)?.toDouble() ?? 0,
      blackCurrentHP: (stats['black_current_hp'] as num?)?.toDouble() ?? 0,
      whiteRangedAttacks: (stats['white_ranged_attacks'] as num?)?.toInt() ?? 0,
      blackRangedAttacks: (stats['black_ranged_attacks'] as num?)?.toInt() ?? 0,
      criticalHits: (stats['critical_hits'] as num?)?.toInt() ?? 0,
      totalMoves: (stats['total_moves'] as num?)?.toInt() ?? 0,
    );
  }

  /// 先手の総ダメージ
  double get blackDamageReceived => blackMaxHP - blackCurrentHP;

  /// 後手の総ダメージ
  double get whiteDamageReceived => whiteMaxHP - whiteCurrentHP;
}
