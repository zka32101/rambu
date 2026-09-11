/// Achievement & Challenge Service
/// 実績・チャレンジ・関係管理

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/achievement.dart';

/// 実績・チャレンジ サービス
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();

  late FirebaseFirestore _firestore;

  AchievementService._internal();

  factory AchievementService() {
    return _instance;
  }

  /// 初期化
  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  // ================== Achievement Methods ==================

  /// すべての実績を取得
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final snapshot = await _firestore.collection('achievements').get();
      return snapshot.docs
          .map((doc) => Achievement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get achievements: $e');
      return [];
    }
  }

  /// ユーザーの実績進捗を取得
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      return snapshot.docs
          .map((doc) => UserAchievement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get user achievements: $e');
      return [];
    }
  }

  /// ユーザーの実績進捗を更新
  Future<void> updateUserAchievementProgress(
    String userId,
    String achievementId,
    int progress,
  ) async {
    try {
      final achievement = await _getAchievementById(achievementId);
      if (achievement == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId);

      final doc = await docRef.get();
      final currentProgress = doc.exists ? (doc.data()?['currentProgress'] as int? ?? 0) : 0;
      final newProgress = currentProgress + progress;
      final isUnlocked = newProgress >= achievement.requiredProgress;

      await docRef.set({
        'userId': userId,
        'achievementId': achievementId,
        'achievement': achievement.toJson(),
        'currentProgress': newProgress,
        'isUnlocked': isUnlocked,
        'unlockedAt': isUnlocked && !doc.exists
            ? DateTime.now().toIso8601String()
            : (doc.data()?['unlockedAt'] as String?),
      }, SetOptions(merge: true));

      // ユーザーの実績数を更新
      if (isUnlocked && (!doc.exists || !(doc.data()?['isUnlocked'] as bool? ?? false))) {
        await _incrementUserAchievementCount(userId);
      }
    } catch (e) {
      print('Failed to update user achievement progress: $e');
      rethrow;
    }
  }

  /// ユーザーの実績数をインクリメント
  Future<void> _incrementUserAchievementCount(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'achievementCount': FieldValue.increment(1),
          });
    } catch (e) {
      print('Failed to increment achievement count: $e');
    }
  }

  /// 実績IDから実績を取得
  Future<Achievement?> _getAchievementById(String achievementId) async {
    try {
      final doc = await _firestore.collection('achievements').doc(achievementId).get();
      if (doc.exists) {
        return Achievement.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get achievement: $e');
      return null;
    }
  }

  // ================== Challenge Methods ==================

  /// すべてのチャレンジを取得
  Future<List<Challenge>> getAllChallenges() async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('isPublic', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Challenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get challenges: $e');
      return [];
    }
  }

  /// チャレンジタイプで取得
  Future<List<Challenge>> getChallengesByType(ChallengeType type) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: type.index)
          .where('isPublic', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Challenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get challenges by type: $e');
      return [];
    }
  }

  /// ユーザーのチャレンジ進捗を取得
  Future<List<UserChallenge>> getUserChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .get();

      return snapshot.docs
          .map((doc) => UserChallenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get user challenges: $e');
      return [];
    }
  }

  /// ユーザーのアクティブなチャレンジを取得
  Future<List<UserChallenge>> getUserActiveChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => UserChallenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get user active challenges: $e');
      return [];
    }
  }

  /// ユーザーのチャレンジ進捗を更新
  Future<void> updateUserChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    try {
      final challenge = await _getChallengeById(challengeId);
      if (challenge == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);

      final doc = await docRef.get();
      final currentProgress = doc.exists ? (doc.data()?['currentProgress'] as int? ?? 0) : 0;
      final newProgress = currentProgress + progress;
      final isCompleted = newProgress >= challenge.difficulty;

      await docRef.set({
        'userId': userId,
        'challengeId': challengeId,
        'challenge': challenge.toJson(),
        'currentProgress': newProgress,
        'isCompleted': isCompleted,
        'completedAt': isCompleted && !doc.exists
            ? DateTime.now().toIso8601String()
            : (doc.data()?['completedAt'] as String?),
        'rewardClaimed': false,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to update user challenge progress: $e');
      rethrow;
    }
  }

  /// チャレンジ報酬を受け取り
  Future<void> claimChallengeReward(String userId, String challengeId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);

      final doc = await docRef.get();
      if (!doc.exists) return;

      final challenge = Challenge.fromJson(
        (doc.data()?['challenge'] as Map<String, dynamic>),
      );

      // 報酬をクレーム
      await docRef.update({'rewardClaimed': true});

      // ユーザーのポイントを増加
      await _firestore.collection('users').doc(userId).update({
        'achievementPoints': FieldValue.increment(challenge.rewardPoints),
      });
    } catch (e) {
      print('Failed to claim challenge reward: $e');
      rethrow;
    }
  }

  /// チャレンジIDからチャレンジを取得
  Future<Challenge?> _getChallengeById(String challengeId) async {
    try {
      final doc = await _firestore.collection('challenges').doc(challengeId).get();
      if (doc.exists) {
        return Challenge.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get challenge: $e');
      return null;
    }
  }

  // ================== Relationship Methods ==================

  /// フレンド・ライバルを追加
  Future<void> addRelationship(
    String userId,
    String otherUserId,
    String otherUserName,
    String? otherUserProfileImage,
    RelationshipType type,
  ) async {
    try {
      final relationshipId = '${userId}_${otherUserId}';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('relationships')
          .doc(relationshipId)
          .set({
            'userId': userId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
            'otherUserProfileImage': otherUserProfileImage,
            'type': type.index,
            'createdAt': DateTime.now().toIso8601String(),
            'gamesPlayed': 0,
            'wins': 0,
            'losses': 0,
          });
    } catch (e) {
      print('Failed to add relationship: $e');
      rethrow;
    }
  }

  /// ユーザーの関係を取得
  Future<List<UserRelationship>> getUserRelationships(
    String userId, {
    RelationshipType? type,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('relationships');

      if (type != null) {
        query = query.where('type', isEqualTo: type.index);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserRelationship.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to get user relationships: $e');
      return [];
    }
  }

  /// 関係を更新（対局結果反映）
  Future<void> updateRelationshipStats(
    String userId,
    String otherUserId,
    bool isWin,
  ) async {
    try {
      final relationshipId = '${userId}_${otherUserId}';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('relationships')
          .doc(relationshipId)
          .update({
            'gamesPlayed': FieldValue.increment(1),
            'wins': FieldValue.increment(isWin ? 1 : 0),
            'losses': FieldValue.increment(isWin ? 0 : 1),
          });
    } catch (e) {
      print('Failed to update relationship stats: $e');
      rethrow;
    }
  }

  /// 関係を削除
  Future<void> removeRelationship(String userId, String otherUserId) async {
    try {
      final relationshipId = '${userId}_${otherUserId}';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('relationships')
          .doc(relationshipId)
          .delete();
    } catch (e) {
      print('Failed to remove relationship: $e');
      rethrow;
    }
  }

  // ================== Match Request Methods ==================

  /// 対局申請を送信
  Future<String> sendMatchRequest(
    String requesterId,
    String requesterName,
    String? requesterImage,
    String receiverId,
    String? message,
  ) async {
    try {
      final requestRef = _firestore.collection('match_requests').doc();
      await requestRef.set({
        'id': requestRef.id,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterImage': requesterImage,
        'receiverId': receiverId,
        'status': MatchRequestStatus.pending.index,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
        'respondedAt': null,
      });

      return requestRef.id;
    } catch (e) {
      print('Failed to send match request: $e');
      rethrow;
    }
  }

  /// ユーザーが受け取った申請を取得
  Future<List<MatchRequest>> getReceivedMatchRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('match_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: MatchRequestStatus.pending.index)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MatchRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get received match requests: $e');
      return [];
    }
  }

  /// ユーザーが送った申請を取得
  Future<List<MatchRequest>> getSentMatchRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('match_requests')
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => MatchRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get sent match requests: $e');
      return [];
    }
  }

  /// 対局申請に応答
  Future<void> respondToMatchRequest(
    String requestId,
    MatchRequestStatus status,
  ) async {
    try {
      await _firestore.collection('match_requests').doc(requestId).update({
        'status': status.index,
        'respondedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to respond to match request: $e');
      rethrow;
    }
  }

  /// 対局申請をキャンセル
  Future<void> cancelMatchRequest(String requestId) async {
    try {
      await _firestore.collection('match_requests').doc(requestId).update({
        'status': MatchRequestStatus.cancelled.index,
        'respondedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to cancel match request: $e');
      rethrow;
    }
  }
}

/// 実績・チャレンジ ストリーム プロバイダー
class AchievementStreamProvider {
  static final AchievementStreamProvider _instance = AchievementStreamProvider._internal();

  late FirebaseFirestore _firestore;

  AchievementStreamProvider._internal();

  factory AchievementStreamProvider() {
    return _instance;
  }

  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// ユーザー実績のストリーム
  Stream<List<UserAchievement>> watchUserAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserAchievement.fromJson(doc.data()))
          .toList();
    });
  }

  /// ユーザーチャレンジのストリーム
  Stream<List<UserChallenge>> watchUserChallenges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserChallenge.fromJson(doc.data()))
          .toList();
    });
  }

  /// 受取申請のストリーム
  Stream<List<MatchRequest>> watchReceivedMatchRequests(String userId) {
    return _firestore
        .collection('match_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: MatchRequestStatus.pending.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchRequest.fromJson(doc.data()))
          .toList();
    });
  }
}
