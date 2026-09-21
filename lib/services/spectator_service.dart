/// Spectator Service
/// ライブ観戦・リプレイ共有・リプレイコメントの管理
///
/// CLAUDE.md の Firestore コスト削減方針に従い、ライブ観戦は
/// 「対局の要約ドキュメント」のみをリアルタイム同期する（盤面全体は同期しない）。

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/spectator.dart';

/// Spectator Service
class SpectatorService {
  static final SpectatorService _instance = SpectatorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SpectatorService._internal();

  factory SpectatorService() => _instance;

  static const String _broadcastsCollection = 'live_broadcasts';
  static const String _sharesCollection = 'replay_shares';
  static const String _commentsCollection = 'replay_comments';

  // ---------------------------------------------------------------------
  // ライブ観戦（ブロードキャスト）
  // ---------------------------------------------------------------------

  /// ライブ配信を開始（対局開始時に呼び出す）
  Future<LiveGameBroadcast> startBroadcast({
    required String gameSessionId,
    required String hostUserId,
    required String hostUserName,
    String? guestUserId,
    String guestUserName = 'CPU',
    bool allowSpectators = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final broadcast = LiveGameBroadcast(
      gameSessionId: gameSessionId,
      hostUserId: hostUserId,
      hostUserName: hostUserName,
      guestUserId: guestUserId,
      guestUserName: guestUserName,
      allowSpectators: allowSpectators,
      startedAt: now,
      lastUpdatedAt: now,
    );

    await _firestore
        .collection(_broadcastsCollection)
        .doc(gameSessionId)
        .set(broadcast.toJson());

    return broadcast;
  }

  /// 対局の進行状況を更新（着手のたびに呼び出す）
  ///
  /// 盤面全体ではなく手数・HP合計のみを送るため、書き込みコストを抑える。
  Future<void> updateBroadcastProgress({
    required String gameSessionId,
    required int currentMoveNumber,
    required int hostTotalHP,
    required int guestTotalHP,
  }) async {
    await _firestore.collection(_broadcastsCollection).doc(gameSessionId).update({
      'currentMoveNumber': currentMoveNumber,
      'hostTotalHP': hostTotalHP,
      'guestTotalHP': guestTotalHP,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// ライブ配信を終了（対局終了時に呼び出す）
  Future<void> stopBroadcast(String gameSessionId) async {
    final doc = _firestore.collection(_broadcastsCollection).doc(gameSessionId);
    final snapshot = await doc.get();
    if (!snapshot.exists) return;

    await doc.update({
      'isFinished': true,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 観戦可能な対局一覧を取得（観戦許可あり・進行中のみ）
  Future<List<LiveGameBroadcast>> getActiveBroadcasts() async {
    try {
      final snapshot = await _firestore
          .collection(_broadcastsCollection)
          .where('allowSpectators', isEqualTo: true)
          .where('isFinished', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => LiveGameBroadcast.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get active broadcasts: $e');
      return [];
    }
  }

  /// 特定対局のライブ状態をリアルタイム監視
  Stream<LiveGameBroadcast?> watchBroadcast(String gameSessionId) {
    return _firestore
        .collection(_broadcastsCollection)
        .doc(gameSessionId)
        .snapshots()
        .map((doc) => doc.exists ? LiveGameBroadcast.fromJson(doc.data()!) : null);
  }

  /// 観戦者数を増減
  Future<void> adjustViewerCount(String gameSessionId, int delta) async {
    await _firestore.collection(_broadcastsCollection).doc(gameSessionId).update({
      'viewerCount': FieldValue.increment(delta),
    });
  }

  // ---------------------------------------------------------------------
  // リプレイ共有
  // ---------------------------------------------------------------------

  /// リプレイ共有リンクを作成
  Future<ReplayShare> createReplayShare({
    required String gameRecordId,
    required String ownerUserId,
    required String ownerUserName,
    bool isPublic = true,
  }) async {
    // 既存の共有があれば再利用
    final existing = await getReplaySharesForRecord(gameRecordId);
    final ownerExisting = existing.where((s) => s.ownerUserId == ownerUserId);
    if (ownerExisting.isNotEmpty) {
      return ownerExisting.first;
    }

    final docRef = _firestore.collection(_sharesCollection).doc();
    final share = ReplayShare(
      id: docRef.id,
      gameRecordId: gameRecordId,
      shareToken: _generateShareToken(),
      ownerUserId: ownerUserId,
      ownerUserName: ownerUserName,
      isPublic: isPublic,
      createdAt: DateTime.now().toIso8601String(),
    );

    await docRef.set(share.toJson());
    return share;
  }

  /// トークンから共有情報を取得
  Future<ReplayShare?> getReplayShareByToken(String token) async {
    try {
      final snapshot = await _firestore
          .collection(_sharesCollection)
          .where('shareToken', isEqualTo: token)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReplayShare.fromJson(snapshot.docs.first.data());
    } catch (e) {
      print('Failed to get replay share by token: $e');
      return null;
    }
  }

  /// 対局記録に紐づく共有一覧を取得
  Future<List<ReplayShare>> getReplaySharesForRecord(String gameRecordId) async {
    try {
      final snapshot = await _firestore
          .collection(_sharesCollection)
          .where('gameRecordId', isEqualTo: gameRecordId)
          .get();

      return snapshot.docs.map((doc) => ReplayShare.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get replay shares: $e');
      return [];
    }
  }

  /// 閲覧数をインクリメント
  Future<void> incrementReplayViewCount(String shareId) async {
    await _firestore.collection(_sharesCollection).doc(shareId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// 共有トークンを生成（8文字の英数字）
  String _generateShareToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 判読しづらい文字を除外
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ---------------------------------------------------------------------
  // リプレイコメント
  // ---------------------------------------------------------------------

  /// コメントを投稿
  Future<ReplayComment> addReplayComment({
    required String gameRecordId,
    required String userId,
    required String userName,
    int? moveIndex,
    required String text,
  }) async {
    final docRef = _firestore.collection(_commentsCollection).doc();
    final comment = ReplayComment(
      id: docRef.id,
      gameRecordId: gameRecordId,
      userId: userId,
      userName: userName,
      moveIndex: moveIndex,
      text: text,
      createdAt: DateTime.now().toIso8601String(),
    );

    await docRef.set(comment.toJson());
    return comment;
  }

  /// 対局記録に紐づくコメント一覧を取得（着手番号順→投稿順）
  Future<List<ReplayComment>> getReplayComments(String gameRecordId) async {
    try {
      final snapshot = await _firestore
          .collection(_commentsCollection)
          .where('gameRecordId', isEqualTo: gameRecordId)
          .get();

      final comments =
          snapshot.docs.map((doc) => ReplayComment.fromJson(doc.data())).toList();

      comments.sort((a, b) {
        final aIndex = a.moveIndex ?? -1;
        final bIndex = b.moveIndex ?? -1;
        if (aIndex != bIndex) return aIndex.compareTo(bIndex);
        return a.createdAt.compareTo(b.createdAt);
      });

      return comments;
    } catch (e) {
      print('Failed to get replay comments: $e');
      return [];
    }
  }

  /// コメントを削除（投稿者本人のみ）
  Future<void> deleteReplayComment(String commentId, String requestingUserId) async {
    final doc = await _firestore.collection(_commentsCollection).doc(commentId).get();
    if (!doc.exists) return;

    final comment = ReplayComment.fromJson(doc.data()!);
    if (comment.userId != requestingUserId) {
      throw Exception('自分のコメントのみ削除できます');
    }

    await doc.reference.delete();
  }
}
