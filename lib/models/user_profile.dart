/// User Profile
/// ユーザープロフィール・統計情報管理

/// ユーザープロフィール
class UserProfile {
  /// ユーザーID（Firebase UID）
  final String userId;

  /// ユーザー名
  final String displayName;

  /// プロフィール画像URL
  final String? profileImageUrl;

  /// ユーザーレベル（1-50、1がルーキー、50がマスター）
  final int level;

  /// 段位（初級、中級、上級）
  final String rank;

  /// 総対局数
  final int totalGames;

  /// 勝利数
  final int wins;

  /// 敗北数
  final int losses;

  /// 引き分け数
  final int draws;

  /// 勝率（0-1.0）
  final double winRate;

  /// 平均対局時間（秒）
  final double averageGameDurationSeconds;

  /// 獲得実績数
  final int achievementCount;

  /// 総プレイ時間（秒）
  final int totalPlayTimeSeconds;

  /// 最高連勝数
  final int maxWinStreak;

  /// 現在の連勝数
  final int currentWinStreak;

  /// クリティカルヒット合計数
  final int totalCriticalHits;

  /// 得点（ランキング用）
  final double ratingScore;

  /// アカウント作成日時（ISO 8601）
  final String createdAt;

  /// 最終プレイ日時（ISO 8601）
  final String? lastPlayedAt;

  /// バイオ・自己紹介
  final String? bio;

  /// ソーシャルリンク（ツイッターIDなど）
  final Map<String, String>? socialLinks;

  /// 非表示フラグ
  final bool isPrivate;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    this.level = 1,
    this.rank = '初級',
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0.0,
    this.averageGameDurationSeconds = 0.0,
    this.achievementCount = 0,
    this.totalPlayTimeSeconds = 0,
    this.maxWinStreak = 0,
    this.currentWinStreak = 0,
    this.totalCriticalHits = 0,
    this.ratingScore = 1200.0,
    required this.createdAt,
    this.lastPlayedAt,
    this.bio,
    this.socialLinks,
    this.isPrivate = false,
  });

  /// JSONから復元
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      level: json['level'] as int? ?? 1,
      rank: json['rank'] as String? ?? '初級',
      totalGames: json['totalGames'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      averageGameDurationSeconds: (json['averageGameDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      achievementCount: json['achievementCount'] as int? ?? 0,
      totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
      maxWinStreak: json['maxWinStreak'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      totalCriticalHits: json['totalCriticalHits'] as int? ?? 0,
      ratingScore: (json['ratingScore'] as num?)?.toDouble() ?? 1200.0,
      createdAt: json['createdAt'] as String,
      lastPlayedAt: json['lastPlayedAt'] as String?,
      bio: json['bio'] as String?,
      socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.cast<String, String>(),
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'level': level,
      'rank': rank,
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': winRate,
      'averageGameDurationSeconds': averageGameDurationSeconds,
      'achievementCount': achievementCount,
      'totalPlayTimeSeconds': totalPlayTimeSeconds,
      'maxWinStreak': maxWinStreak,
      'currentWinStreak': currentWinStreak,
      'totalCriticalHits': totalCriticalHits,
      'ratingScore': ratingScore,
      'createdAt': createdAt,
      'lastPlayedAt': lastPlayedAt,
      'bio': bio,
      'socialLinks': socialLinks,
      'isPrivate': isPrivate,
    };
  }

  /// copyWith
  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? profileImageUrl,
    int? level,
    String? rank,
    int? totalGames,
    int? wins,
    int? losses,
    int? draws,
    double? winRate,
    double? averageGameDurationSeconds,
    int? achievementCount,
    int? totalPlayTimeSeconds,
    int? maxWinStreak,
    int? currentWinStreak,
    int? totalCriticalHits,
    double? ratingScore,
    String? createdAt,
    String? lastPlayedAt,
    String? bio,
    Map<String, String>? socialLinks,
    bool? isPrivate,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winRate: winRate ?? this.winRate,
      averageGameDurationSeconds: averageGameDurationSeconds ?? this.averageGameDurationSeconds,
      achievementCount: achievementCount ?? this.achievementCount,
      totalPlayTimeSeconds: totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
      maxWinStreak: maxWinStreak ?? this.maxWinStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      totalCriticalHits: totalCriticalHits ?? this.totalCriticalHits,
      ratingScore: ratingScore ?? this.ratingScore,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  @override
  String toString() => 'UserProfile(userId: $userId, displayName: $displayName, level: $level, ratingScore: $ratingScore)';
}

/// ランキングエントリー
class LeaderboardEntry {
  /// ランク（1位は1）
  final int rank;

  /// ユーザープロフィール
  final UserProfile userProfile;

  /// ランキングスコア
  final double score;

  /// 前週との順位変動（正：上昇、負：下降）
  final int? rankChange;

  LeaderboardEntry({
    required this.rank,
    required this.userProfile,
    required this.score,
    this.rankChange,
  });

  /// JSONから復元
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userProfile: UserProfile.fromJson(json['userProfile'] as Map<String, dynamic>),
      score: (json['score'] as num).toDouble(),
      rankChange: json['rankChange'] as int?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userProfile': userProfile.toJson(),
      'score': score,
      'rankChange': rankChange,
    };
  }
}

/// ランキングカテゴリー
enum LeaderboardCategory {
  overall,          // 総合ランキング
  winRate,          // 勝率ランキング
  level,            // レベルランキング
  playTime,         // プレイ時間
  achievements,     // 実績ランキング
  criticalHits,     // クリティカルヒット
}

/// レディース（対戦相手検索）
class GameOpponent {
  /// ユーザーID
  final String userId;

  /// ユーザー名
  final String displayName;

  /// プロフィール画像
  final String? profileImageUrl;

  /// ランク
  final String rank;

  /// 勝率
  final double winRate;

  /// 対局数
  final int totalGames;

  /// 最終プレイ時刻（ISO 8601）
  final String? lastPlayedAt;

  /// オンライン状態
  final bool isOnline;

  GameOpponent({
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.rank,
    required this.winRate,
    required this.totalGames,
    this.lastPlayedAt,
    this.isOnline = false,
  });

  /// JSONから復元
  factory GameOpponent.fromJson(Map<String, dynamic> json) {
    return GameOpponent(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      rank: json['rank'] as String,
      winRate: (json['winRate'] as num).toDouble(),
      totalGames: json['totalGames'] as int,
      lastPlayedAt: json['lastPlayedAt'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'rank': rank,
      'winRate': winRate,
      'totalGames': totalGames,
      'lastPlayedAt': lastPlayedAt,
      'isOnline': isOnline,
    };
  }
}
