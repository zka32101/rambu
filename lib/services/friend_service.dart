/// Friend Service
/// フレンド申請・フレンド関係・対戦招待・アクティビティフィードの管理

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/friend.dart';
import 'package:rambu_shogi/models/user_profile.dart';

/// Friend Service
class FriendService {
  static final FriendService _instance = FriendService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FriendService._internal();

  factory FriendService() => _instance;

  static const String _requestsCollection = 'friend_requests';
  static const String _friendshipsCollection = 'friendships';
  static const String _invitesCollection = 'battle_invites';
  static const String _activityCollection = 'friend_activity';
  static const String _usersCollection = 'users';

  // ---------------------------------------------------------------------
  // フレンド申請
  // ---------------------------------------------------------------------

  /// フレンド申請を送信
  ///
  /// 既に申請中・既にフレンドの場合は例外を投げる。
  Future<FriendRequest> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
  }) async {
    if (fromUserId == toUserId) {
      throw Exception('自分自身にフレンド申請はできません');
    }

    final existingFriends = await getFriends(fromUserId);
    if (existingFriends.any((f) => f.friendId == toUserId)) {
      throw Exception('既にフレンドです');
    }

    final pendingRequests = await getOutgoingRequests(fromUserId);
    if (pendingRequests.any((r) =>
        r.toUserId == toUserId && r.status == FriendRequestStatus.pending)) {
      throw Exception('既に申請済みです');
    }

    final docRef = _firestore.collection(_requestsCollection).doc();
    final request = FriendRequest(
      id: docRef.id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      status: FriendRequestStatus.pending,
      sentAt: DateTime.now().toIso8601String(),
    );

    await docRef.set(request.toJson());
    return request;
  }

  /// 自分宛の受信中フレンド申請を取得
  Future<List<FriendRequest>> getIncomingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_requestsCollection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.pending.index)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get incoming friend requests: $e');
      return [];
    }
  }

  /// 自分が送信した申請を取得
  Future<List<FriendRequest>> getOutgoingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get outgoing friend requests: $e');
      return [];
    }
  }

  /// フレンド申請に応答（承認 or 拒否）
  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    final doc = await _firestore.collection(_requestsCollection).doc(requestId).get();
    if (!doc.exists) {
      throw Exception('申請が見つかりません');
    }

    final request = FriendRequest.fromJson(doc.data()!);
    final updated = request.copyWith(
      status: accept ? FriendRequestStatus.accepted : FriendRequestStatus.declined,
      respondedAt: DateTime.now().toIso8601String(),
    );

    await doc.reference.update(updated.toJson());

    if (accept) {
      await addFriendship(
        userId: request.fromUserId,
        userName: request.fromUserName,
        friendId: request.toUserId,
        friendName: request.toUserName,
      );

      await logActivity(
        friendId: request.toUserId,
        friendName: request.toUserName,
        type: FriendActivityType.becameFriends,
        description: '${request.fromUserName}さんとフレンドになりました',
      );
    }
  }

  /// フレンド一覧を取得
  Future<List<Friendship>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_friendshipsCollection)
          .get();

      return snapshot.docs.map((doc) => Friendship.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get friends: $e');
      return [];
    }
  }

  /// フレンドを追加（双方向）
  Future<void> addFriendship({
    required String userId,
    required String userName,
    required String friendId,
    required String friendName,
  }) async {
    final now = DateTime.now().toIso8601String();

    final userSide = Friendship(
      friendId: friendId,
      friendName: friendName,
      becameFriendsAt: now,
    );
    final friendSide = Friendship(
      friendId: userId,
      friendName: userName,
      becameFriendsAt: now,
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_friendshipsCollection)
          .doc(friendId),
      userSide.toJson(),
    );
    batch.set(
      _firestore
          .collection(_usersCollection)
          .doc(friendId)
          .collection(_friendshipsCollection)
          .doc(userId),
      friendSide.toJson(),
    );
    await batch.commit();
  }

  /// フレンドを削除（双方向）
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_friendshipsCollection)
        .doc(friendId));
    batch.delete(_firestore
        .collection(_usersCollection)
        .doc(friendId)
        .collection(_friendshipsCollection)
        .doc(userId));
    await batch.commit();
  }

  /// 対戦成績を更新（対局終了時に呼び出す）
  Future<void> recordHeadToHeadResult({
    required String userId,
    required String friendId,
    required bool userWon,
  }) async {
    final docRef = _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_friendshipsCollection)
        .doc(friendId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final friendship = Friendship.fromJson(doc.data()!);
    final updated = friendship.copyWith(
      headToHeadWins: friendship.headToHeadWins + (userWon ? 1 : 0),
      headToHeadLosses: friendship.headToHeadLosses + (userWon ? 0 : 1),
      lastPlayedAt: DateTime.now().toIso8601String(),
    );

    await docRef.update(updated.toJson());
  }

  // ---------------------------------------------------------------------
  // ユーザー検索
  // ---------------------------------------------------------------------

  /// ユーザー名でユーザーを検索（フレンド追加用）
  Future<List<GameOpponent>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GameOpponent.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to search users: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------
  // 対戦招待
  // ---------------------------------------------------------------------

  /// フレンドに対戦を招待
  Future<BattleInvite> sendBattleInvite({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    String difficulty = '中級',
    Duration validFor = const Duration(minutes: 10),
  }) async {
    final docRef = _firestore.collection(_invitesCollection).doc();
    final now = DateTime.now();

    final invite = BattleInvite(
      id: docRef.id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      difficulty: difficulty,
      createdAt: now.toIso8601String(),
      expiresAt: now.add(validFor).toIso8601String(),
    );

    await docRef.set(invite.toJson());
    return invite;
  }

  /// 自分宛の対戦招待を取得（有効期限内・pending のみ）
  Future<List<BattleInvite>> getPendingInvites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitesCollection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: BattleInviteStatus.pending.index)
          .get();

      final now = DateTime.now();
      final invites = snapshot.docs.map((doc) => BattleInvite.fromJson(doc.data())).toList();

      return invites.where((invite) => !invite.isExpiredAt(now)).toList();
    } catch (e) {
      print('Failed to get pending battle invites: $e');
      return [];
    }
  }

  /// 対戦招待に応答
  Future<BattleInvite> respondToBattleInvite(
    String inviteId,
    bool accept, {
    String? gameSessionId,
  }) async {
    final doc = await _firestore.collection(_invitesCollection).doc(inviteId).get();
    if (!doc.exists) {
      throw Exception('招待が見つかりません');
    }

    final invite = BattleInvite.fromJson(doc.data()!);

    if (invite.isExpiredAt(DateTime.now())) {
      final expired = invite.copyWith(status: BattleInviteStatus.expired);
      await doc.reference.update(expired.toJson());
      throw Exception('招待の有効期限が切れています');
    }

    final updated = invite.copyWith(
      status: accept ? BattleInviteStatus.accepted : BattleInviteStatus.declined,
      gameSessionId: accept ? gameSessionId : null,
    );

    await doc.reference.update(updated.toJson());
    return updated;
  }

  // ---------------------------------------------------------------------
  // アクティビティフィード
  // ---------------------------------------------------------------------

  /// フレンドのアクティビティを記録
  Future<void> logActivity({
    required String friendId,
    required String friendName,
    required FriendActivityType type,
    required String description,
  }) async {
    final docRef = _firestore.collection(_activityCollection).doc();
    final activity = FriendActivity(
      id: docRef.id,
      friendId: friendId,
      friendName: friendName,
      type: type,
      description: description,
      occurredAt: DateTime.now().toIso8601String(),
    );
    await docRef.set(activity.toJson());
  }

  /// フレンド一覧のアクティビティフィードを取得（新しい順）
  Future<List<FriendActivity>> getFriendActivityFeed(
    List<String> friendIds, {
    int limit = 30,
  }) async {
    if (friendIds.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(_activityCollection)
          .where('friendId', whereIn: friendIds.take(30).toList())
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => FriendActivity.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get friend activity feed: $e');
      return [];
    }
  }
}
