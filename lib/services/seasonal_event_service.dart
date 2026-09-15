/// Seasonal Event Service
/// シーズナルイベント・バトルパス・シーズン管理

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/seasonal_event.dart';

/// シーズナルイベント サービス
class SeasonalEventService {
  static final SeasonalEventService _instance = SeasonalEventService._internal();

  late FirebaseFirestore _firestore;

  SeasonalEventService._internal();

  factory SeasonalEventService() {
    return _instance;
  }

  /// 初期化
  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  // ================== Season Methods ==================

  /// 現在のシーズンを取得
  Future<Season?> getCurrentSeason() async {
    try {
      final snapshot = await _firestore
          .collection('seasons')
          .where('status', isEqualTo: SeasonStatus.active.index)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Season.fromJson(snapshot.docs.first.data());
      }

      // アクティブなシーズンがない場合は最新を返す
      final latestSnapshot = await _firestore
          .collection('seasons')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (latestSnapshot.docs.isNotEmpty) {
        return Season.fromJson(latestSnapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      print('Failed to get current season: $e');
      return null;
    }
  }

  /// シーズンをIDで取得
  Future<Season?> getSeasonById(String seasonId) async {
    try {
      final doc = await _firestore.collection('seasons').doc(seasonId).get();
      if (doc.exists) {
        return Season.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get season: $e');
      return null;
    }
  }

  /// すべてのシーズンを取得
  Future<List<Season>> getAllSeasons() async {
    try {
      final snapshot = await _firestore
          .collection('seasons')
          .orderBy('seasonNumber', descending: true)
          .get();

      return snapshot.docs.map((doc) => Season.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get all seasons: $e');
      return [];
    }
  }

  /// シーズンを作成
  Future<String> createSeason(Season season) async {
    try {
      final docRef = _firestore.collection('seasons').doc();
      await docRef.set(season.toJson());
      return docRef.id;
    } catch (e) {
      print('Failed to create season: $e');
      rethrow;
    }
  }

  // ================== Battle Pass Methods ==================

  /// バトルパスを取得
  Future<BattlePass?> getBattlePass(String battlePassId) async {
    try {
      final doc = await _firestore.collection('battle_passes').doc(battlePassId).get();
      if (doc.exists) {
        return BattlePass.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get battle pass: $e');
      return null;
    }
  }

  /// シーズンのバトルパスを取得
  Future<List<BattlePass>> getSeasonBattlePasses(String seasonId) async {
    try {
      final snapshot = await _firestore
          .collection('battle_passes')
          .where('seasonId', isEqualTo: seasonId)
          .get();

      return snapshot.docs.map((doc) => BattlePass.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get season battle passes: $e');
      return [];
    }
  }

  /// バトルパスを作成
  Future<String> createBattlePass(BattlePass battlePass) async {
    try {
      final docRef = _firestore.collection('battle_passes').doc();
      await docRef.set(battlePass.toJson());
      return docRef.id;
    } catch (e) {
      print('Failed to create battle pass: $e');
      rethrow;
    }
  }

  // ================== User Battle Pass Methods ==================

  /// ユーザーのバトルパス進捗を取得
  Future<UserBattlePass?> getUserBattlePass(String userId, String seasonId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('battle_passes')
          .where('seasonId', isEqualTo: seasonId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserBattlePass.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Failed to get user battle pass: $e');
      return null;
    }
  }

  /// ユーザーのバトルパス進捗を更新
  Future<void> updateUserBattlePassProgress(
    String userId,
    String seasonId,
    String battlePassId,
    int pointsGained,
  ) async {
    try {
      final userBP = await getUserBattlePass(userId, seasonId);
      if (userBP == null) return;

      final newProgress = userBP.currentProgress + pointsGained;
      final levelUp = newProgress ~/ userBP.progressPerLevel;
      final newLevel = userBP.currentLevel + levelUp;
      final remainingProgress = newProgress % userBP.progressPerLevel;

      // Max Levelに達したかチェック
      final battlePass = await getBattlePass(battlePassId);
      final maxLevel = battlePass?.maxLevel ?? 100;
      final isCompleted = newLevel >= maxLevel;

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('battle_passes')
          .doc(seasonId);

      await docRef.update({
        'currentLevel': isCompleted ? maxLevel : newLevel,
        'currentProgress': isCompleted ? 0 : remainingProgress,
        'isCompleted': isCompleted,
      });

      // レベルアップ時の報酬自動クレーム処理
      if (levelUp > 0) {
        await _claimLevelRewards(userId, seasonId, userBP.currentLevel, newLevel);
      }
    } catch (e) {
      print('Failed to update user battle pass progress: $e');
      rethrow;
    }
  }

  /// バトルパスを購入
  Future<void> purchaseBattlePass(String userId, String seasonId, String battlePassId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('battle_passes')
          .doc(seasonId);

      await docRef.update({
        'isPurchased': true,
        'purchasedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to purchase battle pass: $e');
      rethrow;
    }
  }

  /// レベル報酬をクレーム
  Future<void> _claimLevelRewards(
    String userId,
    String seasonId,
    int fromLevel,
    int toLevel,
  ) async {
    try {
      // レベルアップの報酬をここで処理（今後の実装）
      for (int level = fromLevel + 1; level <= toLevel; level++) {
        // この実装は報酬配信システムと連携
      }
    } catch (e) {
      print('Failed to claim level rewards: $e');
    }
  }

  // ================== Battle Pass Reward Methods ==================

  /// バトルパス報酬を取得
  Future<List<BattlePassReward>> getBattlePassRewards(String battlePassId) async {
    try {
      final snapshot = await _firestore
          .collection('battle_pass_rewards')
          .where('battlePassId', isEqualTo: battlePassId)
          .orderBy('level')
          .get();

      return snapshot.docs.map((doc) => BattlePassReward.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get battle pass rewards: $e');
      return [];
    }
  }

  /// 特定レベルの報酬を取得
  Future<BattlePassReward?> getRewardForLevel(String battlePassId, int level) async {
    try {
      final snapshot = await _firestore
          .collection('battle_pass_rewards')
          .where('battlePassId', isEqualTo: battlePassId)
          .where('level', isEqualTo: level)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BattlePassReward.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Failed to get reward for level: $e');
      return null;
    }
  }

  /// 報酬をクレーム
  Future<void> claimReward(String userId, String seasonId, String rewardId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('battle_passes')
          .doc(seasonId);

      await docRef.update({
        'claimedRewards': FieldValue.arrayUnion([rewardId]),
      });
    } catch (e) {
      print('Failed to claim reward: $e');
      rethrow;
    }
  }

  // ================== Seasonal Challenge Methods ==================

  /// シーズナルチャレンジを取得
  Future<List<SeasonalChallenge>> getSeasonalChallenges(String seasonId) async {
    try {
      final snapshot = await _firestore
          .collection('seasonal_challenges')
          .where('seasonId', isEqualTo: seasonId)
          .orderBy('difficulty')
          .get();

      return snapshot.docs.map((doc) => SeasonalChallenge.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get seasonal challenges: $e');
      return [];
    }
  }

  /// ユーザーのシーズナルチャレンジ進捗を取得
  Future<List<UserSeasonalChallenge>> getUserSeasonalChallenges(
    String userId,
    String seasonId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('seasonal_challenges')
          .where('seasonId', isEqualTo: seasonId)
          .get();

      return snapshot.docs
          .map((doc) => UserSeasonalChallenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get user seasonal challenges: $e');
      return [];
    }
  }

  /// シーズナルチャレンジ進捗を更新
  Future<void> updateSeasonalChallengeProgress(
    String userId,
    String challengeId,
    String seasonId,
    int progress,
    int requiredProgress,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('seasonal_challenges')
          .doc('${seasonId}_${challengeId}');

      final doc = await docRef.get();
      final currentProgress = doc.exists ? (doc.data()?['currentProgress'] as int? ?? 0) : 0;
      final newProgress = currentProgress + progress;
      final isCompleted = newProgress >= requiredProgress;

      await docRef.set({
        'userId': userId,
        'challengeId': challengeId,
        'seasonId': seasonId,
        'currentProgress': newProgress,
        'isCompleted': isCompleted,
        'completedAt': isCompleted && !doc.exists
            ? DateTime.now().toIso8601String()
            : (doc.data()?['completedAt'] as String?),
        'rewardClaimed': false,
      }, SetOptions(merge: true));

      // チャレンジ完了時のバトルパス進捗増加
      if (isCompleted && (!doc.exists || !(doc.data()?['isCompleted'] as bool? ?? false))) {
        final challenge = await _getSeasonalChallengeById(challengeId);
        if (challenge != null) {
          // バトルパス進捗にチャレンジ報酬ポイントを追加
          // 実装は updateUserBattlePassProgress に統合
        }
      }
    } catch (e) {
      print('Failed to update seasonal challenge progress: $e');
      rethrow;
    }
  }

  /// シーズナルチャレンジ報酬をクレーム
  Future<void> claimSeasonalChallengeReward(
    String userId,
    String challengeId,
    String seasonId,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('seasonal_challenges')
          .doc('${seasonId}_${challengeId}');

      await docRef.update({'rewardClaimed': true});
    } catch (e) {
      print('Failed to claim seasonal challenge reward: $e');
      rethrow;
    }
  }

  /// シーズナルチャレンジをIDで取得
  Future<SeasonalChallenge?> _getSeasonalChallengeById(String challengeId) async {
    try {
      final doc = await _firestore.collection('seasonal_challenges').doc(challengeId).get();
      if (doc.exists) {
        return SeasonalChallenge.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get seasonal challenge: $e');
      return null;
    }
  }

  // ================== Season System Data ==================

  /// シーズンシステムの全データを取得
  Future<SeasonSystemData?> getSeasonSystemData(String userId) async {
    try {
      final season = await getCurrentSeason();
      if (season == null) return null;

      final battlePasses = await getSeasonBattlePasses(season.id);
      final userBP = await getUserBattlePass(userId, season.id);

      if (userBP == null || battlePasses.isEmpty) return null;

      final battlePass = battlePasses.firstWhere(
        (bp) => bp.id == userBP.battlePassId,
        orElse: () => battlePasses.first,
      );

      final challenges = await getSeasonalChallenges(season.id);
      final userChallenges = await getUserSeasonalChallenges(userId, season.id);
      final rewards = await getBattlePassRewards(battlePass.id);

      return SeasonSystemData(
        currentSeason: season,
        userBattlePass: userBP,
        availableChallenges: challenges,
        userChallengeProgress: userChallenges,
        battlePassRewards: rewards,
      );
    } catch (e) {
      print('Failed to get season system data: $e');
      return null;
    }
  }
}

/// シーズナルイベント ストリーム プロバイダー
class SeasonalEventStreamProvider {
  static final SeasonalEventStreamProvider _instance =
      SeasonalEventStreamProvider._internal();

  late FirebaseFirestore _firestore;

  SeasonalEventStreamProvider._internal();

  factory SeasonalEventStreamProvider() {
    return _instance;
  }

  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// ユーザーバトルパスのストリーム
  Stream<UserBattlePass?> watchUserBattlePass(String userId, String seasonId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('battle_passes')
        .where('seasonId', isEqualTo: seasonId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return UserBattlePass.fromJson(snapshot.docs.first.data());
      }
      return null;
    });
  }

  /// シーズナルチャレンジのストリーム
  Stream<List<UserSeasonalChallenge>> watchUserSeasonalChallenges(
    String userId,
    String seasonId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('seasonal_challenges')
        .where('seasonId', isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserSeasonalChallenge.fromJson(doc.data()))
          .toList();
    });
  }

  /// 現在のシーズンのストリーム
  Stream<Season?> watchCurrentSeason() {
    return _firestore
        .collection('seasons')
        .where('status', isEqualTo: SeasonStatus.active.index)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Season.fromJson(snapshot.docs.first.data());
      }
      return null;
    });
  }
}
