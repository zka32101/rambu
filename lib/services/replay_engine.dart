/// Replay Engine
/// 対局記録の再生・再現エンジン
///
/// 機能:
/// - GameRecord から GameSession を再現
/// - 再生制御（再生・一時停止・ステップ・シーク）
/// - 再生速度調整（0.5x, 1x, 2x）
/// - 変化手の閲覧

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';

/// Replay Engine Provider
final replayEngineProvider = Provider<ReplayEngine>((ref) => ReplayEngine());

/// Replay State Model
class ReplayState {
  /// 現在の盤面状態
  final GameSession currentBoard;

  /// 現在の手数（0-indexed）
  final int moveIndex;

  /// 現在の手（nullの場合は開始前）
  final Move? currentMove;

  /// 再生中か
  final bool isPlaying;

  /// 利用可能な変化手
  final List<AnalysisNode> availableVariations;

  /// 再生速度（0.5x, 1x, 2x）
  final double playbackSpeed;

  /// 総手数
  final int totalMoves;

  /// エラーメッセージ（ある場合）
  final String? errorMessage;

  ReplayState({
    required this.currentBoard,
    this.moveIndex = 0,
    this.currentMove,
    this.isPlaying = false,
    this.availableVariations = const [],
    this.playbackSpeed = 1.0,
    this.totalMoves = 0,
    this.errorMessage,
  });

  ReplayState copyWith({
    GameSession? currentBoard,
    int? moveIndex,
    Move? currentMove,
    bool? isPlaying,
    List<AnalysisNode>? availableVariations,
    double? playbackSpeed,
    int? totalMoves,
    String? errorMessage,
  }) {
    return ReplayState(
      currentBoard: currentBoard ?? this.currentBoard,
      moveIndex: moveIndex ?? this.moveIndex,
      currentMove: currentMove ?? this.currentMove,
      isPlaying: isPlaying ?? this.isPlaying,
      availableVariations: availableVariations ?? this.availableVariations,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      totalMoves: totalMoves ?? this.totalMoves,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'ReplayState(moveIndex=$moveIndex/$totalMoves, playing=$isPlaying, speed=${playbackSpeed}x)';
}

/// Replay Engine
///
/// GameRecord から GameSession を再現し、再生制御を行う
class ReplayEngine {
  /// 現在の盤面状態
  late GameSession _gameSession;

  /// 現在の手数
  int _currentMoveIndex = 0;

  /// 再生フラグ
  bool _isPlaying = false;

  /// 再生速度（倍率）
  double _playbackSpeed = 1.0;

  /// 対局記録
  late GameRecord _gameRecord;

  /// Riverpod のための状態ストリーム
  final List<ReplayState> _stateHistory = [];

  /// 現在のリプレイ状態
  ReplayState? _currentState;

  /// 初期化済みフラグ
  bool _initialized = false;

  /// ゲーム記録で再生エンジンを初期化
  ///
  /// [record]: 再生する対局記録
  /// Throws: [ReplayException] 初期化に失敗した場合
  void initialize(GameRecord record) {
    try {
      _gameRecord = record;
      _currentMoveIndex = 0;
      _isPlaying = false;
      _playbackSpeed = 1.0;

      // GameSession を再現
      _gameSession = GameSession(
        sessionId: record.id,
        aiDifficulty: _parseDifficulty(record.aiDifficulty),
        playerColor: record.playerColor == 'sente'
            ? PlayerColor.sente
            : PlayerColor.gote,
      );

      // ゲーム開始
      _gameSession.start();

      // 初期状態を保存
      _currentState = ReplayState(
        currentBoard: _gameSession,
        moveIndex: 0,
        currentMove: null,
        isPlaying: false,
        totalMoves: record.moves.length,
        playbackSpeed: _playbackSpeed,
        availableVariations: record.variations,
      );

      _stateHistory.clear();
      _stateHistory.add(_currentState!);
      _initialized = true;
    } catch (e) {
      throw ReplayException(
        'Failed to initialize replay engine: $e',
        code: 'init_error',
      );
    }
  }

  /// 再生開始
  void play() {
    if (!_initialized) {
      throw ReplayException('Engine not initialized', code: 'not_initialized');
    }
    _isPlaying = true;
    _updateState();
  }

  /// 一時停止
  void pause() {
    _isPlaying = false;
    _updateState();
  }

  /// 前の手に戻す
  void stepBackward() {
    if (_currentMoveIndex > 0) {
      _currentMoveIndex--;
      _rebuildGameState();
      _updateState();
    }
  }

  /// 次の手に進める
  void stepForward() {
    if (_currentMoveIndex < _gameRecord.moves.length) {
      _currentMoveIndex++;
      _rebuildGameState();
      _updateState();
    }
  }

  /// 指定した手数にジャンプ
  ///
  /// [moveIndex]: ジャンプ先の手数（0-indexed）
  void jumpToMove(int moveIndex) {
    if (moveIndex < 0 || moveIndex > _gameRecord.moves.length) {
      throw ReplayException(
        'Invalid move index: $moveIndex',
        code: 'invalid_index',
      );
    }
    _currentMoveIndex = moveIndex;
    _rebuildGameState();
    _updateState();
  }

  /// 再生速度を変更
  ///
  /// [speed]: 再生速度（0.5x, 1x, 2x推奨）
  void setPlaybackSpeed(double speed) {
    if (speed <= 0) {
      throw ReplayException(
        'Invalid speed: $speed',
        code: 'invalid_speed',
      );
    }
    _playbackSpeed = speed;
    _updateState();
  }

  /// 再生開始位置にリセット
  void reset() {
    _currentMoveIndex = 0;
    _isPlaying = false;
    _rebuildGameState();
    _updateState();
  }

  /// 最後まで進める
  void jumpToEnd() {
    _currentMoveIndex = _gameRecord.moves.length;
    _rebuildGameState();
    _updateState();
  }

  /// 現在の再生状態を取得
  ReplayState get currentState => _currentState ?? ReplayState(
    currentBoard: _gameSession,
    totalMoves: _gameRecord.moves.length,
  );

  /// 現在の手数を取得
  int get moveIndex => _currentMoveIndex;

  /// 総手数を取得
  int get totalMoves => _gameRecord.moves.length;

  /// 再生中か取得
  bool get isPlaying => _isPlaying;

  /// 再生速度を取得
  double get playbackSpeed => _playbackSpeed;

  /// 現在の手を取得
  Move? get currentMove {
    if (_currentMoveIndex > 0 && _currentMoveIndex <= _gameRecord.moves.length) {
      return _moveFromJson(_gameRecord.moves[_currentMoveIndex - 1]);
    }
    return null;
  }

  /// 盤面を再構築（手数0から現在位置まで）
  ///
  /// GameSession を初期状態から現在の手数まで再現
  void _rebuildGameState() {
    // リセット
    _gameSession.reset();
    _gameSession.start();

    // 現在位置まで手を適用
    for (int i = 0; i < _currentMoveIndex; i++) {
      try {
        final moveJson = _gameRecord.moves[i];
        final move = _moveFromJson(moveJson);
        _gameSession.applyMove(move);
      } catch (e) {
        throw ReplayException(
          'Failed to rebuild game state at move $i: $e',
          code: 'rebuild_error',
        );
      }
    }
  }

  /// 状態を更新してキャッシュ
  void _updateState() {
    _currentState = ReplayState(
      currentBoard: _gameSession,
      moveIndex: _currentMoveIndex,
      currentMove: currentMove,
      isPlaying: _isPlaying,
      availableVariations: _gameRecord.variations,
      playbackSpeed: _playbackSpeed,
      totalMoves: _gameRecord.moves.length,
    );
    _stateHistory.add(_currentState!);
  }

  /// JSON から Move に変換
  Move _moveFromJson(Map<String, dynamic> json) {
    return Move(
      from: Position(
        (json['from'] as Map)['x'] as int,
        (json['from'] as Map)['y'] as int,
      ),
      to: Position(
        (json['to'] as Map)['x'] as int,
        (json['to'] as Map)['y'] as int,
      ),
      player: (json['player'] as String) == 'sente'
          ? PlayerColor.sente
          : PlayerColor.gote,
      piece: _createDummyPiece(),  // TODO: 実装完了後に正しい駒を復元
      moveType: _parseMoveType(json['move_type'] as String),
      damageDealt: (json['damage'] as num?)?.toInt() ?? 0,
      targetHPBefore: (json['target_hp_before'] as num?)?.toInt(),
      targetHPAfter: (json['target_hp_after'] as num?)?.toInt(),
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );
  }

  /// 難易度を解析
  Difficulty _parseDifficulty(String label) {
    return switch (label) {
      '初級' => Difficulty.easy,
      '中級' => Difficulty.normal,
      '上級' => Difficulty.hard,
      _ => Difficulty.normal,
    };
  }

  /// MoveType を解析
  MoveType _parseMoveType(String type) {
    return switch (type) {
      'normal' => MoveType.normal,
      'ranged' => MoveType.ranged,
      'capture' => MoveType.capture,
      'promote' => MoveType.promote,
      _ => MoveType.normal,
    };
  }

  /// ダミー駒を作成（JSONから駒を復元するまでの暫定処理）
  Piece _createDummyPiece() {
    return Piece(
      type: PieceType.pawn,
      player: PlayerColor.sente,
      currentHP: 1,
      maxHP: 1,
    );
  }
}

/// Replay Exception
class ReplayException implements Exception {
  final String message;
  final String code;

  ReplayException(
    this.message, {
    required this.code,
  });

  @override
  String toString() => 'ReplayException($code): $message';
}
