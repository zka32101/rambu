/// Firestore Service
/// 対局記録（棋譜）の保存・読み込み・管理
///
/// 機能:
/// - GameRecord の Firestore への保存
/// - 対局記録の読み込み（ID指定・一覧取得）
/// - 対局記録の削除
/// - 統計情報の更新
/// - リアルタイムリスナー対応

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_record.dart';

/// Firestore Service Provider
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// ゲーム記録リスト Provider（最新50件）
final gameRecordsProvider = FutureProvider<List<GameRecord>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.listGameRecords(limit: 50);
});

/// ゲーム記録ストリーム Provider（リアルタイム更新）
final gameRecordsStreamProvider =
    StreamProvider<List<GameRecord>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchGameRecords(limit: 50);
});

/// Firestore Service
class FirestoreService {
  /// Firestore インスタンス
  final _firestore = FirebaseFirestore.instance;

  /// ゲーム記録のコレクション名
  static const String gameRecordsCollection = 'gameRecords';

  /// ゲーム記録の統計サブコレクション
  static const String statsSubcollection = 'stats';

  /// ゲーム記録を保存
  ///
  /// [record]: 保存する対局記録
  /// Returns: 保存されたドキュメントID
  ///
  /// Firestore パス: /gameRecords/{recordId}
  Future<String> saveGameRecord(GameRecord record) async {
    try {
      final docRef = _firestore
          .collection(gameRecordsCollection)
          .doc(record.id);

      final recordData = record.toJson();

      await docRef.set(recordData, SetOptions(merge: true));

      // 統計情報も別途保存（クエリ最適化用）
      await _saveGameStats(record.id, GameRecordStats.fromGameRecord(record));

      return record.id;
    } catch (e) {
      throw FirestoreException(
        'Failed to save game record: $e',
        code: 'save_game_record_error',
      );
    }
  }

  /// ゲーム記録を読み込み
  ///
  /// [recordId]: ゲーム記録のID
  /// Returns: 対局記録、見つからない場合はnull
  Future<GameRecord?> loadGameRecord(String recordId) async {
    try {
      final doc = await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return GameRecord.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirestoreException(
        'Failed to load game record: $e',
        code: 'load_game_record_error',
      );
    }
  }

  /// 対局記録一覧を取得
  ///
  /// [limit]: 取得件数（デフォルト50）
  /// [orderBy]: ソート順（playedAt/difficulty）
  /// [descending]: 降順か昇順か（デフォルト降順）
  /// Returns: 対局記録のリスト
  ///
  /// デフォルト: 最新順（playedAtの降順）
  Future<List<GameRecord>> listGameRecords({
    int limit = 50,
    String orderBy = 'playedAt',
    bool descending = true,
  }) async {
    try {
      var query = _firestore
          .collection(gameRecordsCollection)
          .orderBy(orderBy, descending: descending)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => GameRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to list game records: $e',
        code: 'list_game_records_error',
      );
    }
  }

  /// 対局記録をリアルタイムで監視
  ///
  /// [limit]: 取得件数
  /// [orderBy]: ソート順
  /// Returns: 対局記録のストリーム
  Stream<List<GameRecord>> watchGameRecords({
    int limit = 50,
    String orderBy = 'playedAt',
    bool descending = true,
  }) {
    try {
      return _firestore
          .collection(gameRecordsCollection)
          .orderBy(orderBy, descending: descending)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameRecord.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw FirestoreException(
        'Failed to watch game records: $e',
        code: 'watch_game_records_error',
      );
    }
  }

  /// 対局記録を削除
  ///
  /// [recordId]: 削除する記録のID
  Future<void> deleteGameRecord(String recordId) async {
    try {
      // メインドキュメントを削除
      await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .delete();

      // 統計情報も削除
      await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .collection(statsSubcollection)
          .doc('summary')
          .delete()
          .catchError((_) {
            // 統計情報がない場合はエラーを無視
          });
    } catch (e) {
      throw FirestoreException(
        'Failed to delete game record: $e',
        code: 'delete_game_record_error',
      );
    }
  }

  /// 対局記録の統計情報を更新
  ///
  /// [recordId]: ゲーム記録のID
  /// [stats]: 更新する統計情報
  Future<void> updateGameStats(
    String recordId,
    Map<String, dynamic> stats,
  ) async {
    try {
      await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .update({'stats': stats});

      // サブコレクションにも保存（クエリ用）
      await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .collection(statsSubcollection)
          .doc('summary')
          .set(stats, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(
        'Failed to update game stats: $e',
        code: 'update_game_stats_error',
      );
    }
  }

  /// 統計情報を保存
  Future<void> _saveGameStats(
    String recordId,
    GameRecordStats stats,
  ) async {
    try {
      await _firestore
          .collection(gameRecordsCollection)
          .doc(recordId)
          .collection(statsSubcollection)
          .doc('summary')
          .set(stats.toJson(), SetOptions(merge: true));
    } catch (e) {
      // 統計情報の保存失敗は非致命的
      print('Warning: Failed to save game stats: $e');
    }
  }

  /// 難易度別の対局記録を取得
  ///
  /// [difficulty]: 難易度（easy/normal/hard）
  /// [limit]: 取得件数
  /// Returns: フィルタリングされた対局記録
  Future<List<GameRecord>> listGameRecordsByDifficulty(
    String difficulty, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(gameRecordsCollection)
          .where('aiDifficulty', isEqualTo: difficulty)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GameRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to list records by difficulty: $e',
        code: 'list_by_difficulty_error',
      );
    }
  }

  /// 結果別の対局記録を取得
  ///
  /// [result]: 対局結果（white_won/black_won/draw）
  /// [limit]: 取得件数
  /// Returns: フィルタリングされた対局記録
  Future<List<GameRecord>> listGameRecordsByResult(
    String result, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(gameRecordsCollection)
          .where('result', isEqualTo: result)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GameRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to list records by result: $e',
        code: 'list_by_result_error',
      );
    }
  }

  /// 統計情報を集計
  ///
  /// Returns: 全対局の統計情報
  Future<Map<String, dynamic>> getGameStatistics() async {
    try {
      final records = await listGameRecords(limit: 10000);

      int totalGames = records.length;
      int whiteWins = 0;
      int blackWins = 0;
      int draws = 0;
      double totalDuration = 0;
      int totalCriticalHits = 0;

      for (final record in records) {
        totalDuration += record.durationSeconds;
        totalCriticalHits += (record.stats['critical_hits'] as int? ?? 0);

        switch (record.result) {
          case GameResult.whiteWon:
            whiteWins++;
          case GameResult.blackWon:
            blackWins++;
          case GameResult.draw:
            draws++;
          default:
            break;
        }
      }

      return {
        'total_games': totalGames,
        'white_wins': whiteWins,
        'black_wins': blackWins,
        'draws': draws,
        'average_duration_seconds': totalGames > 0 ? totalDuration / totalGames : 0,
        'total_critical_hits': totalCriticalHits,
        'white_win_rate': totalGames > 0 ? (whiteWins / totalGames * 100) : 0,
      };
    } catch (e) {
      throw FirestoreException(
        'Failed to get game statistics: $e',
        code: 'get_statistics_error',
      );
    }
  }

  /// ゲーム記録をバッチ削除（古い記録の自動削除用）
  ///
  /// [daysOld]: 指定日数以上前の記録を削除
  Future<int> deleteOldGameRecords(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection(gameRecordsCollection)
          .where('playedAt', isLessThan: cutoffDate)
          .limit(500)  // バッチ処理の制限
          .get();

      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      throw FirestoreException(
        'Failed to delete old records: $e',
        code: 'delete_old_records_error',
      );
    }
  }
}

/// Firestore 例外
class FirestoreException implements Exception {
  final String message;
  final String code;

  FirestoreException(
    this.message, {
    required this.code,
  });

  @override
  String toString() => 'FirestoreException($code): $message';
}
