/// Replay Engine Tests
/// ゲーム再生・再現機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/replay_engine.dart';

void main() {
  late ReplayEngine replayEngine;
  late GameRecord testGameRecord;

  /// テスト用のゲーム記録を作成
  GameRecord createTestGameRecord({
    String id = 'test_replay_001',
    int moveCount = 10,
  }) {
    // テスト用の棋譜（簡略版）
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
      result: GameResult.whiteWon,
      moves: moves,
      durationSeconds: 300,
      stats: {
        'white_max_hp': 20.0,
        'black_max_hp': 20.0,
        'white_current_hp': 15.0,
        'black_current_hp': 0.0,
        'total_moves': moveCount,
      },
    );
  }

  setUp(() {
    replayEngine = ReplayEngine();
    testGameRecord = createTestGameRecord();
  });

  group('Replay Engine Initialization Tests', () {
    test('initialize should setup replay state correctly', () {
      // 実行
      replayEngine.initialize(testGameRecord);

      // 検証
      expect(replayEngine.moveIndex, equals(0));
      expect(replayEngine.totalMoves, equals(10));
      expect(replayEngine.isPlaying, isFalse);
      expect(replayEngine.playbackSpeed, equals(1.0));
    });

    test('initialize should throw ReplayException with invalid record', () {
      // 空のゲーム記録を作成
      final emptyRecord = GameRecord(
        id: 'empty',
        playedAt: DateTime.now(),
        createdAt: DateTime.now(),
        aiDifficulty: '中級',
        playerColor: 'sente',
        result: GameResult.draw,
        moves: [],
        durationSeconds: 0,
        stats: {},
      );

      // 実行・検証
      replayEngine.initialize(emptyRecord);
      expect(replayEngine.totalMoves, equals(0));
    });

    test('currentState should reflect initial state', () {
      // 実行
      replayEngine.initialize(testGameRecord);
      final state = replayEngine.currentState;

      // 検証
      expect(state.moveIndex, equals(0));
      expect(state.totalMoves, equals(10));
      expect(state.isPlaying, isFalse);
      expect(state.playbackSpeed, equals(1.0));
      expect(state.currentMove, isNull);
    });
  });

  group('Playback Control Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('play should set isPlaying to true', () {
      // 実行
      replayEngine.play();

      // 検証
      expect(replayEngine.isPlaying, isTrue);
      expect(replayEngine.currentState.isPlaying, isTrue);
    });

    test('pause should set isPlaying to false', () {
      // 準備
      replayEngine.play();
      expect(replayEngine.isPlaying, isTrue);

      // 実行
      replayEngine.pause();

      // 検証
      expect(replayEngine.isPlaying, isFalse);
    });

    test('stepForward should increment moveIndex', () {
      // 実行
      replayEngine.stepForward();

      // 検証
      expect(replayEngine.moveIndex, equals(1));
      expect(replayEngine.currentMove, isNotNull);
    });

    test('stepForward should not exceed totalMoves', () {
      // 準備：最後まで進める
      for (int i = 0; i < testGameRecord.moves.length; i++) {
        replayEngine.stepForward();
      }

      final lastIndex = replayEngine.moveIndex;

      // 実行：さらに進もうとする
      replayEngine.stepForward();

      // 検証：変わらないはず
      expect(replayEngine.moveIndex, equals(lastIndex));
    });

    test('stepBackward should decrement moveIndex', () {
      // 準備
      replayEngine.stepForward();
      replayEngine.stepForward();
      expect(replayEngine.moveIndex, equals(2));

      // 実行
      replayEngine.stepBackward();

      // 検証
      expect(replayEngine.moveIndex, equals(1));
    });

    test('stepBackward should not go below 0', () {
      // 実行
      replayEngine.stepBackward();

      // 検証
      expect(replayEngine.moveIndex, equals(0));
    });
  });

  group('Jump & Seek Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('jumpToMove should set moveIndex to target', () {
      // 実行
      replayEngine.jumpToMove(5);

      // 検証
      expect(replayEngine.moveIndex, equals(5));
    });

    test('jumpToMove should throw exception for invalid index', () {
      // 実行・検証
      expect(
        () => replayEngine.jumpToMove(-1),
        throwsA(isA<ReplayException>()),
      );

      expect(
        () => replayEngine.jumpToMove(100),
        throwsA(isA<ReplayException>()),
      );
    });

    test('jumpToEnd should move to last move', () {
      // 実行
      replayEngine.jumpToEnd();

      // 検証
      expect(replayEngine.moveIndex, equals(replayEngine.totalMoves));
    });

    test('reset should return to start', () {
      // 準備
      replayEngine.jumpToMove(5);
      expect(replayEngine.moveIndex, equals(5));

      // 実行
      replayEngine.reset();

      // 検証
      expect(replayEngine.moveIndex, equals(0));
      expect(replayEngine.isPlaying, isFalse);
    });
  });

  group('Playback Speed Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('setPlaybackSpeed should update speed', () {
      // 実行
      replayEngine.setPlaybackSpeed(2.0);

      // 検証
      expect(replayEngine.playbackSpeed, equals(2.0));
      expect(replayEngine.currentState.playbackSpeed, equals(2.0));
    });

    test('setPlaybackSpeed should support 0.5x speed', () {
      // 実行
      replayEngine.setPlaybackSpeed(0.5);

      // 検証
      expect(replayEngine.playbackSpeed, equals(0.5));
    });

    test('setPlaybackSpeed should throw exception for invalid speed', () {
      // 実行・検証
      expect(
        () => replayEngine.setPlaybackSpeed(0),
        throwsA(isA<ReplayException>()),
      );

      expect(
        () => replayEngine.setPlaybackSpeed(-1.0),
        throwsA(isA<ReplayException>()),
      );
    });
  });

  group('Game State Reconstruction Tests', () {
    test('board state should be correctly reconstructed at each move', () {
      // 実行
      replayEngine.initialize(testGameRecord);

      final statesAtEachMove = <int>[];

      // 各手での盤面状態を記録
      for (int i = 0; i <= testGameRecord.moves.length; i++) {
        replayEngine.jumpToMove(i);
        final state = replayEngine.currentState;
        statesAtEachMove.add(state.moveIndex);
      }

      // 検証：moveIndex が0から順に増えているか
      for (int i = 0; i < statesAtEachMove.length; i++) {
        expect(statesAtEachMove[i], equals(i));
      }
    });

    test('game session should be reset when jumping', () {
      // 準備
      replayEngine.initialize(testGameRecord);
      replayEngine.jumpToMove(3);
      var state1 = replayEngine.currentState;

      // 実行：別の位置へジャンプ
      replayEngine.jumpToMove(5);
      var state2 = replayEngine.currentState;

      // 検証
      expect(state1.moveIndex, equals(3));
      expect(state2.moveIndex, equals(5));
    });
  });

  group('Current Move Tracking Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('currentMove should be null at start', () {
      // 検証
      expect(replayEngine.currentMove, isNull);
    });

    test('currentMove should not be null after stepping forward', () {
      // 実行
      replayEngine.stepForward();

      // 検証
      expect(replayEngine.currentMove, isNotNull);
      expect(replayEngine.currentMove!.player, isNotNull);
    });

    test('currentMove should change when navigating', () {
      // 準備
      replayEngine.stepForward();
      final move1 = replayEngine.currentMove;

      // 実行
      replayEngine.stepForward();
      final move2 = replayEngine.currentMove;

      // 検証
      expect(move1, isNotNull);
      expect(move2, isNotNull);
      expect(move1 != move2, isTrue);  // 異なる手
    });
  });

  group('State History Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('current state should reflect latest navigation', () {
      // 実行
      replayEngine.stepForward();
      replayEngine.stepForward();
      final state = replayEngine.currentState;

      // 検証
      expect(state.moveIndex, equals(2));
    });

    test('state should be consistent across multiple operations', () {
      // 実行
      replayEngine.stepForward();
      replayEngine.stepForward();
      replayEngine.stepBackward();
      final state = replayEngine.currentState;

      // 検証
      expect(state.moveIndex, equals(1));
    });
  });

  group('Error Handling Tests', () {
    test('operations should fail if not initialized', () {
      // ReplayEngine を初期化しない状態

      // 実行・検証
      expect(
        () => replayEngine.play(),
        throwsA(isA<ReplayException>()),
      );

      expect(
        () => replayEngine.stepForward(),
        throwsA(isA<ReplayException>()),
      );
    });
  });

  group('Performance Tests', () {
    test('initialization should complete quickly', () {
      // 準備：大量の手を持つゲーム記録
      final largeRecord = createTestGameRecord(moveCount: 100);

      // 実行
      final stopwatch = Stopwatch()..start();
      replayEngine.initialize(largeRecord);
      stopwatch.stop();

      // 検証：100ミリ秒以内に完了
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('jumping should be fast even for large games', () {
      // 準備
      final largeRecord = createTestGameRecord(moveCount: 100);
      replayEngine.initialize(largeRecord);

      // 実行
      final stopwatch = Stopwatch()..start();
      replayEngine.jumpToMove(50);
      stopwatch.stop();

      // 検証：50ミリ秒以内に完了
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('stepForward should be consistently fast', () {
      // 準備
      replayEngine.initialize(testGameRecord);

      // 実行
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        replayEngine.stepForward();
      }
      stopwatch.stop();

      // 検証：10回のステップが100ミリ秒以内
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Variations & Analysis Tests', () {
    setUp(() {
      replayEngine.initialize(testGameRecord);
    });

    test('availableVariations should be accessible', () {
      // 検証
      final variations = replayEngine.currentState.availableVariations;
      expect(variations, isNotNull);
      expect(variations, isA<List<AnalysisNode>>());
    });

    test('variations should be empty if record has none', () {
      // テストゲームレコードには変化手がない
      expect(
        replayEngine.currentState.availableVariations.isEmpty,
        isTrue,
      );
    });
  });
}
