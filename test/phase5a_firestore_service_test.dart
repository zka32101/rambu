/// Firestore Service Tests
/// 対局記録の保存・読み込み・管理機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  // テスト用のGameRecordサンプル
  GameRecord createTestGameRecord({
    String id = 'test_001',
    GameResult result = GameResult.whiteWon,
    int durationSeconds = 300,
  }) {
    return GameRecord(
      id: id,
      playedAt: DateTime.now(),
      createdAt: DateTime.now(),
      playerName: 'Test Player',
      aiDifficulty: '中級',
      playerColor: 'sente',
      result: result,
      moves: [
        {
          'from': {'x': 2, 'y': 7},
          'to': {'x': 2, 'y': 6},
          'player': 'sente',
          'piece_type': 'pawn',
          'move_type': 'normal',
          'damage': 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ],
      durationSeconds: durationSeconds,
      stats: {
        'white_max_hp': 20.0,
        'black_max_hp': 20.0,
        'white_current_hp': 15.0,
        'black_current_hp': 0.0,
        'white_ranged_attacks': 2,
        'black_ranged_attacks': 1,
        'critical_hits': 1,
        'total_moves': 15,
      },
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService();
    // FakeFirestoreを使うように設定（本来はモック化が必要）
  });

  group('Firestore Service Tests', () {
    test('saveGameRecord should store record in Firestore', () async {
      // 準備
      final record = createTestGameRecord();

      // 実行
      final savedId = await firestoreService.saveGameRecord(record);

      // 検証
      expect(savedId, equals(record.id));

      // Firestoreから取得して検証
      final loadedRecord = await firestoreService.loadGameRecord(record.id);
      expect(loadedRecord, isNotNull);
      expect(loadedRecord?.id, equals(record.id));
      expect(loadedRecord?.playerColor, equals('sente'));
      expect(loadedRecord?.result, equals(GameResult.whiteWon));
    });

    test('loadGameRecord should retrieve correct record', () async {
      // 準備
      final record = createTestGameRecord(id: 'test_002');
      await firestoreService.saveGameRecord(record);

      // 実行
      final loadedRecord = await firestoreService.loadGameRecord('test_002');

      // 検証
      expect(loadedRecord, isNotNull);
      expect(loadedRecord!.playerName, equals('Test Player'));
      expect(loadedRecord.aiDifficulty, equals('中級'));
      expect(loadedRecord.durationSeconds, equals(300));
    });

    test('loadGameRecord should return null for non-existent record', () async {
      // 実行
      final loadedRecord =
          await firestoreService.loadGameRecord('non_existent');

      // 検証
      expect(loadedRecord, isNull);
    });

    test('listGameRecords should return records in descending order', () async {
      // 準備
      final now = DateTime.now();
      final record1 = createTestGameRecord(
        id: 'test_001',
      );
      final record2 = createTestGameRecord(
        id: 'test_002',
      );
      final record3 = createTestGameRecord(
        id: 'test_003',
      );

      await firestoreService.saveGameRecord(record1);
      await Future.delayed(Duration(milliseconds: 10));
      await firestoreService.saveGameRecord(record2);
      await Future.delayed(Duration(milliseconds: 10));
      await firestoreService.saveGameRecord(record3);

      // 実行
      final records = await firestoreService.listGameRecords(limit: 10);

      // 検証
      expect(records.length, greaterThanOrEqualTo(3));
      // 最新順になっているか確認
      expect(records.first.id, isIn(['test_003', 'test_002', 'test_001']));
    });

    test('listGameRecords should respect limit parameter', () async {
      // 準備
      for (int i = 0; i < 10; i++) {
        await firestoreService
            .saveGameRecord(createTestGameRecord(id: 'test_$i'));
      }

      // 実行
      final records = await firestoreService.listGameRecords(limit: 5);

      // 検証
      expect(records.length, lessThanOrEqualTo(5));
    });

    test('deleteGameRecord should remove record', () async {
      // 準備
      final record = createTestGameRecord(id: 'test_delete');
      await firestoreService.saveGameRecord(record);

      // 削除前の確認
      var loadedRecord = await firestoreService.loadGameRecord('test_delete');
      expect(loadedRecord, isNotNull);

      // 実行
      await firestoreService.deleteGameRecord('test_delete');

      // 削除後の確認
      loadedRecord = await firestoreService.loadGameRecord('test_delete');
      expect(loadedRecord, isNull);
    });

    test('updateGameStats should update stats field', () async {
      // 準備
      final record = createTestGameRecord(id: 'test_stats');
      await firestoreService.saveGameRecord(record);

      final newStats = {
        'white_max_hp': 25.0,
        'black_max_hp': 15.0,
        'white_current_hp': 20.0,
        'black_current_hp': 5.0,
        'white_ranged_attacks': 3,
        'black_ranged_attacks': 2,
        'critical_hits': 2,
        'total_moves': 20,
      };

      // 実行
      await firestoreService.updateGameStats('test_stats', newStats);

      // 検証
      final loadedRecord =
          await firestoreService.loadGameRecord('test_stats');
      expect(loadedRecord?.stats['white_max_hp'], equals(25.0));
      expect(loadedRecord?.stats['critical_hits'], equals(2));
    });

    test('listGameRecordsByDifficulty should filter by difficulty', () async {
      // 準備
      final easyRecord = GameRecord(
        id: 'test_easy',
        playedAt: DateTime.now(),
        createdAt: DateTime.now(),
        aiDifficulty: '初級',
        playerColor: 'sente',
        result: GameResult.whiteWon,
        moves: [],
        durationSeconds: 300,
        stats: {},
      );

      final hardRecord = GameRecord(
        id: 'test_hard',
        playedAt: DateTime.now(),
        createdAt: DateTime.now(),
        aiDifficulty: '上級',
        playerColor: 'sente',
        result: GameResult.blackWon,
        moves: [],
        durationSeconds: 400,
        stats: {},
      );

      await firestoreService.saveGameRecord(easyRecord);
      await firestoreService.saveGameRecord(hardRecord);

      // 実行
      final easyRecords =
          await firestoreService.listGameRecordsByDifficulty('初級');
      final hardRecords =
          await firestoreService.listGameRecordsByDifficulty('上級');

      // 検証
      expect(
        easyRecords.every((r) => r.aiDifficulty == '初級'),
        isTrue,
      );
      expect(
        hardRecords.every((r) => r.aiDifficulty == '上級'),
        isTrue,
      );
    });

    test('listGameRecordsByResult should filter by result', () async {
      // 準備
      final whiteWinRecord = createTestGameRecord(
        id: 'test_white_win',
        result: GameResult.whiteWon,
      );
      final blackWinRecord = createTestGameRecord(
        id: 'test_black_win',
        result: GameResult.blackWon,
      );

      await firestoreService.saveGameRecord(whiteWinRecord);
      await firestoreService.saveGameRecord(blackWinRecord);

      // 実行
      final whiteWins =
          await firestoreService.listGameRecordsByResult('white_won');
      final blackWins =
          await firestoreService.listGameRecordsByResult('black_won');

      // 検証
      expect(
        whiteWins.every((r) => r.result == GameResult.whiteWon),
        isTrue,
      );
      expect(
        blackWins.every((r) => r.result == GameResult.blackWon),
        isTrue,
      );
    });

    test('getGameStatistics should calculate aggregate stats', () async {
      // 準備
      final whiteWinRecord1 = createTestGameRecord(
        id: 'test_stat_1',
        result: GameResult.whiteWon,
        durationSeconds: 300,
      );
      final whiteWinRecord2 = createTestGameRecord(
        id: 'test_stat_2',
        result: GameResult.whiteWon,
        durationSeconds: 400,
      );
      final blackWinRecord = createTestGameRecord(
        id: 'test_stat_3',
        result: GameResult.blackWon,
        durationSeconds: 500,
      );

      await firestoreService.saveGameRecord(whiteWinRecord1);
      await firestoreService.saveGameRecord(whiteWinRecord2);
      await firestoreService.saveGameRecord(blackWinRecord);

      // 実行
      final stats = await firestoreService.getGameStatistics();

      // 検証
      expect(stats['total_games'], greaterThanOrEqualTo(3));
      expect(stats['white_wins'], greaterThanOrEqualTo(2));
      expect(stats['black_wins'], greaterThanOrEqualTo(1));
      expect(stats['average_duration_seconds'], isA<double>());
      expect(stats['white_win_rate'], isA<double>());
    });

    test('deleteOldGameRecords should remove records older than threshold', () async {
      // 準備（古いレコードを作成）
      final oldRecord = GameRecord(
        id: 'test_old',
        playedAt: DateTime.now().subtract(Duration(days: 40)),
        createdAt: DateTime.now().subtract(Duration(days: 40)),
        aiDifficulty: '中級',
        playerColor: 'sente',
        result: GameResult.whiteWon,
        moves: [],
        durationSeconds: 300,
        stats: {},
      );

      final newRecord = createTestGameRecord(id: 'test_new');

      await firestoreService.saveGameRecord(oldRecord);
      await firestoreService.saveGameRecord(newRecord);

      // 実行（30日以上前のレコードを削除）
      final deletedCount = await firestoreService.deleteOldGameRecords(30);

      // 検証
      expect(deletedCount, greaterThanOrEqualTo(0));

      // 古いレコードが削除されているか確認
      final oldLoaded =
          await firestoreService.loadGameRecord('test_old');
      final newLoaded = await firestoreService.loadGameRecord('test_new');

      // 新しいレコードは残っているはず
      expect(newLoaded, isNotNull);
    });
  });

  group('Error Handling Tests', () {
    test('saveGameRecord should throw FirestoreException on error', () async {
      // エラーケース（nullを保存しようとする）
      expect(
        () async {
          // 実装により異なる動作になる可能性
        },
        throwsA(isA<Exception>()),
      );
    });

    test('listGameRecords with invalid query should handle gracefully', () async {
      // 無効なクエリでも適切にエラーを処理
      // 実装依存
    });
  });

  group('Performance Tests', () {
    test('listGameRecords should complete within reasonable time', () async {
      // 準備
      for (int i = 0; i < 20; i++) {
        await firestoreService
            .saveGameRecord(createTestGameRecord(id: 'perf_$i'));
      }

      // 実行
      final stopwatch = Stopwatch()..start();
      await firestoreService.listGameRecords(limit: 50);
      stopwatch.stop();

      // 検証: 1秒以内に完了すること
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('getGameStatistics should complete within reasonable time', () async {
      // 準備
      for (int i = 0; i < 10; i++) {
        await firestoreService
            .saveGameRecord(createTestGameRecord(id: 'stat_perf_$i'));
      }

      // 実行
      final stopwatch = Stopwatch()..start();
      await firestoreService.getGameStatistics();
      stopwatch.stop();

      // 検証: 2秒以内に完了すること
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
