/// Matchmaking Service
/// レーティングベース自動マッチング（待機キュー・マッチ成立・監視）
///
/// shogi_app の matching_service.dart を参考に、乱舞将棋向けに簡素化して実装。
/// 双方向のレーティング範囲チェックに加え、候補が複数いる場合は
/// レーティング差が最も小さい相手を優先する（対戦バランス改善）。

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/matchmaking.dart';

/// Matchmaking Service
class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MatchmakingService._internal();

  factory MatchmakingService() => _instance;

  static const String _queueCollection = 'matchmaking_queue';
  static const String _matchesCollection = 'matchmaking_matches';

  /// 待機タイムアウト（秒）
  static const int matchmakingTimeoutSeconds = 300;

  /// デフォルトのレーティング許容範囲（±）
  static const double defaultRatingRange = 200;

  // ---------------------------------------------------------------------
  // 待機キュー
  // ---------------------------------------------------------------------

  /// マッチング待機キューに参加し、即座にマッチングを試行する
  Future<MatchmakingEntry> joinQueue({
    required String userId,
    required String userName,
    required double rating,
    double ratingRange = defaultRatingRange,
  }) async {
    // 同一ユーザーの既存の待機中エントリをキャンセル（多重申込防止）
    await _cancelExistingWaitingEntries(userId);

    final docRef = _firestore.collection(_queueCollection).doc();
    final entry = MatchmakingEntry(
      id: docRef.id,
      userId: userId,
      userName: userName,
      rating: rating,
      minRatingRange: (rating - ratingRange).clamp(0, double.infinity),
      maxRatingRange: rating + ratingRange,
      queuedAt: DateTime.now().toIso8601String(),
    );

    await docRef.set(entry.toJson());

    final matched = await _tryMatchmaking(entry);
    return matched ?? entry;
  }

  /// マッチング待機をキャンセル
  Future<void> cancelQueue(String entryId) async {
    await _firestore.collection(_queueCollection).doc(entryId).update({
      'status': MatchmakingStatus.cancelled.index,
    });
  }

  /// 待機エントリーをリアルタイム監視（マッチ成立を検知するため）
  Stream<MatchmakingEntry?> watchQueueEntry(String entryId) {
    return _firestore.collection(_queueCollection).doc(entryId).snapshots().map(
          (doc) => doc.exists ? MatchmakingEntry.fromJson(doc.data()!) : null,
        );
  }

  /// 同一ユーザーの待機中エントリを cancelled にする
  Future<void> _cancelExistingWaitingEntries(String userId) async {
    final existing = await _firestore
        .collection(_queueCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: MatchmakingStatus.waiting.index)
        .get();

    if (existing.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'status': MatchmakingStatus.cancelled.index});
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------
  // 自動マッチング
  // ---------------------------------------------------------------------

  /// マッチメイキングを試行する。成立した場合は更新後の自分のエントリーを返す。
  Future<MatchmakingEntry?> _tryMatchmaking(MatchmakingEntry entry) async {
    try {
      final otherQueues = await _firestore
          .collection(_queueCollection)
          .where('status', isEqualTo: MatchmakingStatus.waiting.index)
          .limit(50)
          .get();

      final candidates = otherQueues.docs
          .map((doc) => MatchmakingEntry.fromJson(doc.data()))
          .where((other) => other.userId != entry.userId)
          .where((other) =>
              entry.canMatchRating(other.rating) && other.canMatchRating(entry.rating))
          .toList();

      if (candidates.isEmpty) return null;

      // レーティング差が最も小さい相手を選ぶ（対戦バランス優先）
      candidates.sort((a, b) => entry
          .ratingDistanceTo(a.rating)
          .compareTo(entry.ratingDistanceTo(b.rating)));

      final opponent = candidates.first;
      return _createMatch(entry, opponent);
    } catch (e) {
      print('Matchmaking attempt failed: $e');
      return null;
    }
  }

  /// マッチを成立させる
  Future<MatchmakingEntry> _createMatch(
    MatchmakingEntry entry,
    MatchmakingEntry opponent,
  ) async {
    final matchRef = _firestore.collection(_matchesCollection).doc();
    final match = MatchmakingMatch(
      id: matchRef.id,
      player1Id: entry.userId,
      player1Name: entry.userName,
      player1Rating: entry.rating,
      player2Id: opponent.userId,
      player2Name: opponent.userName,
      player2Rating: opponent.rating,
      matchedAt: DateTime.now().toIso8601String(),
    );

    final updatedEntry = entry.copyWith(
      status: MatchmakingStatus.matched,
      matchedWithUserId: opponent.userId,
      matchId: matchRef.id,
    );
    final updatedOpponent = opponent.copyWith(
      status: MatchmakingStatus.matched,
      matchedWithUserId: entry.userId,
      matchId: matchRef.id,
    );

    final batch = _firestore.batch();
    batch.set(matchRef, match.toJson());
    batch.update(_firestore.collection(_queueCollection).doc(entry.id), updatedEntry.toJson());
    batch.update(
        _firestore.collection(_queueCollection).doc(opponent.id), updatedOpponent.toJson());
    await batch.commit();

    return updatedEntry;
  }

  /// 期限切れの待機エントリを expired にする（画面から定期的に呼び出す想定）
  Future<void> cleanupExpiredEntries() async {
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(seconds: matchmakingTimeoutSeconds))
          .toIso8601String();

      final stale = await _firestore
          .collection(_queueCollection)
          .where('status', isEqualTo: MatchmakingStatus.waiting.index)
          .where('queuedAt', isLessThan: cutoff)
          .limit(20)
          .get();

      if (stale.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in stale.docs) {
        batch.update(doc.reference, {'status': MatchmakingStatus.expired.index});
      }
      await batch.commit();
    } catch (e) {
      print('Failed to cleanup expired matchmaking entries: $e');
    }
  }

  // ---------------------------------------------------------------------
  // マッチ情報
  // ---------------------------------------------------------------------

  /// マッチ情報を取得
  Future<MatchmakingMatch?> getMatch(String matchId) async {
    final doc = await _firestore.collection(_matchesCollection).doc(matchId).get();
    if (!doc.exists) return null;
    return MatchmakingMatch.fromJson(doc.data()!);
  }

  /// 対局セッションIDをマッチに紐付ける（対局画面初期化後に呼び出す）
  Future<void> attachGameSession(String matchId, String gameSessionId) async {
    await _firestore.collection(_matchesCollection).doc(matchId).update({
      'gameSessionId': gameSessionId,
    });
  }
}
