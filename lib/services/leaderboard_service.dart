/// Leaderboard Service
/// ランキング・ユーザー統計情報の一元管理

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/user_profile.dart';

/// ランキング サービス
class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();

  late FirebaseFirestore _firestore;

  LeaderboardService._internal();

  factory LeaderboardService() {
    return _instance;
  }

  /// 初期化
  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// ユーザープロフィールを作成・更新
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// ユーザープロフィールを取得
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get user profile: $e');
      return null;
    }
  }

  /// ランキングを取得（カテゴリー別）
  Future<List<LeaderboardEntry>> getLeaderboard(
    LeaderboardCategory category, {
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('leaderboards').doc(category.toString()).collection('entries');

      // カテゴリーに応じたソート順序
      query = _applySortForCategory(query, category);

      query = query.limit(limit);

      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        entries.add(LeaderboardEntry.fromJson({
          'rank': rank,
          ...data,
        }));
        rank++;
      }

      return entries;
    } catch (e) {
      print('Failed to get leaderboard: $e');
      return [];
    }
  }

  /// ユーザーのランキング順位を取得
  Future<int?> getUserRank(String userId, LeaderboardCategory category) async {
    try {
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) return null;

      Query query = _firestore.collection('leaderboards').doc(category.toString()).collection('entries');
      query = _applySortForCategory(query, category);

      // ユーザーのスコア以上のエントリー数を取得
      final score = _getScoreForCategory(userProfile, category);
      query = query.where('score', isGreaterThan: score);

      final snapshot = await query.get();
      return snapshot.size + 1; // ランク（1位から始まる）
    } catch (e) {
      print('Failed to get user rank: $e');
      return null;
    }
  }

  /// 対戦可能な相手を検索
  Future<List<GameOpponent>> findGameOpponents({
    String? rankFilter,
    bool onlineOnly = false,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (rankFilter != null) {
        query = query.where('rank', isEqualTo: rankFilter);
      }

      if (onlineOnly) {
        query = query.where('isOnline', isEqualTo: true);
      }

      query = query.orderBy('lastPlayedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      final opponents = <GameOpponent>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        opponents.add(GameOpponent.fromJson(data));
      }

      return opponents;
    } catch (e) {
      print('Failed to find game opponents: $e');
      return [];
    }
  }

  /// ユーザー統計を更新
  Future<void> updateUserStats({
    required String userId,
    required bool isWin,
    required int gameDurationSeconds,
    required int criticalHitsCount,
  }) async {
    try {
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) return;

      final totalGames = userProfile.totalGames + 1;
      final wins = isWin ? userProfile.wins + 1 : userProfile.wins;
      final losses = !isWin ? userProfile.losses + 1 : userProfile.losses;
      final newWinRate = totalGames > 0 ? wins / totalGames : 0.0;
      final newAverageDuration = (userProfile.totalPlayTimeSeconds + gameDurationSeconds) / totalGames;
      final newLevel = _calculateLevel(wins, totalGames);
      final newRank = _calculateRank(newWinRate, newLevel);
      final newRatingScore = _updateElo(
        userProfile.ratingScore,
        isWin,
        userProfile.totalGames,
      );

      // 連勝数の更新
      final newCurrentWinStreak = isWin ? userProfile.currentWinStreak + 1 : 0;
      final newMaxWinStreak = newCurrentWinStreak > userProfile.maxWinStreak
          ? newCurrentWinStreak
          : userProfile.maxWinStreak;

      final updatedProfile = userProfile.copyWith(
        totalGames: totalGames,
        wins: wins,
        losses: losses,
        winRate: newWinRate,
        averageGameDurationSeconds: newAverageDuration,
        totalPlayTimeSeconds: userProfile.totalPlayTimeSeconds + gameDurationSeconds,
        totalCriticalHits: userProfile.totalCriticalHits + criticalHitsCount,
        level: newLevel,
        rank: newRank,
        ratingScore: newRatingScore,
        maxWinStreak: newMaxWinStreak,
        currentWinStreak: newCurrentWinStreak,
        lastPlayedAt: DateTime.now().toIso8601String(),
      );

      await updateUserProfile(updatedProfile);
    } catch (e) {
      print('Failed to update user stats: $e');
      rethrow;
    }
  }

  /// ユーザーをオンラインに設定
  Future<void> setUserOnline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastPlayedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to set user online: $e');
    }
  }

  /// ユーザーをオフラインに設定
  Future<void> setUserOffline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
      });
    } catch (e) {
      print('Failed to set user offline: $e');
    }
  }

  /// ランキングをリフレッシュ（全ユーザーのランク再計算）
  Future<void> refreshLeaderboards() async {
    try {
      // 各カテゴリーについて処理
      for (final category in LeaderboardCategory.values) {
        await _refreshCategoryLeaderboard(category);
      }
    } catch (e) {
      print('Failed to refresh leaderboards: $e');
      rethrow;
    }
  }

  /// カテゴリー別ランキングをリフレッシュ
  Future<void> _refreshCategoryLeaderboard(LeaderboardCategory category) async {
    try {
      // 全ユーザーを取得
      final snapshot = await _firestore.collection('users').get();
      final users = <UserProfile>[];

      for (final doc in snapshot.docs) {
        users.add(UserProfile.fromJson(doc.data() as Map<String, dynamic>));
      }

      // カテゴリーに応じてソート
      users.sort((a, b) {
        final scoreA = _getScoreForCategory(a, category);
        final scoreB = _getScoreForCategory(b, category);
        return scoreB.compareTo(scoreA); // 降順
      });

      // ランキングエントリーを作成・更新
      final batch = _firestore.batch();
      int rank = 1;

      for (final user in users) {
        final entry = LeaderboardEntry(
          rank: rank,
          userProfile: user,
          score: _getScoreForCategory(user, category),
        );

        final entryDoc = _firestore
            .collection('leaderboards')
            .doc(category.toString())
            .collection('entries')
            .doc(user.userId);

        batch.set(entryDoc, entry.toJson(), SetOptions(merge: true));
        rank++;
      }

      await batch.commit();
    } catch (e) {
      print('Failed to refresh category leaderboard: $e');
      rethrow;
    }
  }

  /// カテゴリーに応じてQueryをソート
  Query _applySortForCategory(Query query, LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.overall:
        return query.orderBy('score', descending: true);
      case LeaderboardCategory.winRate:
        return query.orderBy('userProfile.winRate', descending: true);
      case LeaderboardCategory.level:
        return query.orderBy('userProfile.level', descending: true);
      case LeaderboardCategory.playTime:
        return query.orderBy('userProfile.totalPlayTimeSeconds', descending: true);
      case LeaderboardCategory.achievements:
        return query.orderBy('userProfile.achievementCount', descending: true);
      case LeaderboardCategory.criticalHits:
        return query.orderBy('userProfile.totalCriticalHits', descending: true);
    }
  }

  /// カテゴリーに応じてスコアを計算
  double _getScoreForCategory(UserProfile user, LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.overall:
        return user.ratingScore;
      case LeaderboardCategory.winRate:
        return user.winRate * 100; // 0-100に正規化
      case LeaderboardCategory.level:
        return user.level.toDouble();
      case LeaderboardCategory.playTime:
        return user.totalPlayTimeSeconds.toDouble();
      case LeaderboardCategory.achievements:
        return user.achievementCount.toDouble();
      case LeaderboardCategory.criticalHits:
        return user.totalCriticalHits.toDouble();
    }
  }

  /// レベルを計算
  int _calculateLevel(int wins, int totalGames) {
    if (totalGames == 0) return 1;
    return (wins / (totalGames > 0 ? totalGames : 1)).ceil().clamp(1, 50);
  }

  /// 段位を計算
  String _calculateRank(double winRate, int level) {
    if (winRate < 0.4) return '初級';
    if (winRate < 0.55) return '中級';
    return '上級';
  }

  /// ELOレートを更新
  double _updateElo(double currentElo, bool isWin, int totalGames) {
    final kFactor = totalGames < 30 ? 32.0 : (totalGames < 100 ? 24.0 : 16.0);
    const opponentElo = 1200.0; // 相手の平均ELO

    final expectedScore = 1.0 / (1.0 + pow(10, (opponentElo - currentElo) / 400.0));
    final actualScore = isWin ? 1.0 : 0.0;
    final newElo = currentElo + kFactor * (actualScore - expectedScore);

    return newElo;
  }

  /// 数学的べき乗関数
  double pow(double base, double exponent) {
    return base * base;
  }
}

/// ランキング ストリーム プロバイダー用
class LeaderboardStreamProvider {
  static final LeaderboardStreamProvider _instance = LeaderboardStreamProvider._internal();

  late FirebaseFirestore _firestore;

  LeaderboardStreamProvider._internal();

  factory LeaderboardStreamProvider() {
    return _instance;
  }

  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// ランキングのストリーム
  Stream<List<LeaderboardEntry>> watchLeaderboard(
    LeaderboardCategory category, {
    int limit = 100,
  }) {
    return _firestore
        .collection('leaderboards')
        .doc(category.toString())
        .collection('entries')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        entries.add(LeaderboardEntry.fromJson({
          'rank': rank,
          ...data,
        }));
        rank++;
      }

      return entries;
    });
  }

  /// ユーザープロフィールのストリーム
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
