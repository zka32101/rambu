/// Achievement Model
/// 実績・トロフィー・チャレンジ管理

/// 実績レベル
enum AchievementRarity {
  common,      // 一般
  uncommon,    // 珍しい
  rare,        // レア
  epic,        // エピック
  legendary,   // レジェンダリー
}

/// 実績
class Achievement {
  /// 実績ID
  final String id;

  /// 実績名
  final String name;

  /// 実績説明
  final String description;

  /// 実績アイコン（絵文字またはアセットパス）
  final String icon;

  /// レアリティ
  final AchievementRarity rarity;

  /// 達成条件（テキスト説明）
  final String condition;

  /// ポイント報酬
  final int points;

  /// 進捗タイプ
  final AchievementProgressType progressType;

  /// 必要進捗量
  final int requiredProgress;

  /// 非表示フラグ（達成まで非表示）
  final bool isHidden;

  /// 報酬テキスト
  final String? reward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.rarity = AchievementRarity.common,
    required this.condition,
    this.points = 0,
    this.progressType = AchievementProgressType.count,
    this.requiredProgress = 1,
    this.isHidden = false,
    this.reward,
  });

  /// JSONから復元
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: AchievementRarity.values[json['rarity'] as int? ?? 0],
      condition: json['condition'] as String,
      points: json['points'] as int? ?? 0,
      progressType: AchievementProgressType.values[json['progressType'] as int? ?? 0],
      requiredProgress: json['requiredProgress'] as int? ?? 1,
      isHidden: json['isHidden'] as bool? ?? false,
      reward: json['reward'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity.index,
      'condition': condition,
      'points': points,
      'progressType': progressType.index,
      'requiredProgress': requiredProgress,
      'isHidden': isHidden,
      'reward': reward,
    };
  }
}

/// 実績進捗タイプ
enum AchievementProgressType {
  count,           // カウント型（N回達成）
  milestone,       // マイルストーン型（レベルN到達など）
  winStreak,       // 連勝型
  timeLimit,       // 時間制限型
  specific,        // 特定条件型
}

/// ユーザー実績（進捗追跡）
class UserAchievement {
  /// ユーザーID
  final String userId;

  /// 実績ID
  final String achievementId;

  /// 実績オブジェクト
  final Achievement achievement;

  /// 現在の進捗
  final int currentProgress;

  /// 達成状態
  final bool isUnlocked;

  /// 達成日時（ISO 8601）
  final String? unlockedAt;

  /// 進捗パーセント（0-100）
  double get progressPercent {
    if (achievement.requiredProgress == 0) return 0;
    return (currentProgress / achievement.requiredProgress) * 100;
  }

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.achievement,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// JSONから復元
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      achievement: Achievement.fromJson(json['achievement'] as Map<String, dynamic>),
      currentProgress: json['currentProgress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'achievement': achievement.toJson(),
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt,
    };
  }

  /// copyWith
  UserAchievement copyWith({
    int? currentProgress,
    bool? isUnlocked,
    String? unlockedAt,
  }) {
    return UserAchievement(
      userId: userId,
      achievementId: achievementId,
      achievement: achievement,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// チャレンジ・クエスト
class Challenge {
  /// チャレンジID
  final String id;

  /// チャレンジ名
  final String name;

  /// チャレンジ説明
  final String description;

  /// 難易度（1-5）
  final int difficulty;

  /// 報酬ポイント
  final int rewardPoints;

  /// 目標（例：3連勝）
  final String objective;

  /// チャレンジタイプ
  final ChallengeType type;

  /// 有効期限（ISO 8601、nullなら無制限）
  final String? expiresAt;

  /// 公開フラグ
  final bool isPublic;

  /// リセット頻度（daily/weekly/monthly）
  final String resetFrequency;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    this.difficulty = 1,
    this.rewardPoints = 0,
    required this.objective,
    this.type = ChallengeType.seasonal,
    this.expiresAt,
    this.isPublic = true,
    this.resetFrequency = 'daily',
  });

  /// JSONから復元
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      objective: json['objective'] as String,
      type: ChallengeType.values[json['type'] as int? ?? 0],
      expiresAt: json['expiresAt'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      resetFrequency: json['resetFrequency'] as String? ?? 'daily',
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'rewardPoints': rewardPoints,
      'objective': objective,
      'type': type.index,
      'expiresAt': expiresAt,
      'isPublic': isPublic,
      'resetFrequency': resetFrequency,
    };
  }
}

/// チャレンジタイプ
enum ChallengeType {
  daily,      // デイリーチャレンジ
  weekly,     // ウィークリーチャレンジ
  monthly,    // マンスリーチャレンジ
  seasonal,   // シーズナルチャレンジ
  special,    // 特別チャレンジ
}

/// ユーザーチャレンジ（進捗追跡）
class UserChallenge {
  /// ユーザーID
  final String userId;

  /// チャレンジID
  final String challengeId;

  /// チャレンジオブジェクト
  final Challenge challenge;

  /// 現在の進捗
  final int currentProgress;

  /// 達成状態
  final bool isCompleted;

  /// 達成日時（ISO 8601）
  final String? completedAt;

  /// 報酬受け取り状態
  final bool rewardClaimed;

  /// 進捗パーセント（0-100）
  double get progressPercent {
    return (currentProgress / challenge.difficulty) * 100;
  }

  UserChallenge({
    required this.userId,
    required this.challengeId,
    required this.challenge,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.rewardClaimed = false,
  });

  /// JSONから復元
  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      userId: json['userId'] as String,
      challengeId: json['challengeId'] as String,
      challenge: Challenge.fromJson(json['challenge'] as Map<String, dynamic>),
      currentProgress: json['currentProgress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] as String?,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'challenge': challenge.toJson(),
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'rewardClaimed': rewardClaimed,
    };
  }

  /// copyWith
  UserChallenge copyWith({
    int? currentProgress,
    bool? isCompleted,
    String? completedAt,
    bool? rewardClaimed,
  }) {
    return UserChallenge(
      userId: userId,
      challengeId: challengeId,
      challenge: challenge,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }
}

/// フレンド・ライバル関係
class UserRelationship {
  /// ユーザーID
  final String userId;

  /// 相手ユーザーID
  final String otherUserId;

  /// 相手ユーザー名
  final String otherUserName;

  /// 相手プロフィール画像
  final String? otherUserProfileImage;

  /// 関係タイプ
  final RelationshipType type;

  /// 関係開始日時（ISO 8601）
  final String createdAt;

  /// 対局数
  final int gamesPlayed;

  /// 対このユーザーへの勝数
  final int wins;

  /// 対このユーザーへの敗数
  final int losses;

  /// 勝率
  double get winRateAgainstUser {
    if (gamesPlayed == 0) return 0.0;
    return wins / gamesPlayed;
  }

  UserRelationship({
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
    this.type = RelationshipType.friend,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
  });

  /// JSONから復元
  factory UserRelationship.fromJson(Map<String, dynamic> json) {
    return UserRelationship(
      userId: json['userId'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String,
      otherUserProfileImage: json['otherUserProfileImage'] as String?,
      type: RelationshipType.values[json['type'] as int? ?? 0],
      createdAt: json['createdAt'] as String,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserProfileImage': otherUserProfileImage,
      'type': type.index,
      'createdAt': createdAt,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
    };
  }

  /// copyWith
  UserRelationship copyWith({
    int? gamesPlayed,
    int? wins,
    int? losses,
  }) {
    return UserRelationship(
      userId: userId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserProfileImage: otherUserProfileImage,
      type: type,
      createdAt: createdAt,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
  }
}

/// 関係タイプ
enum RelationshipType {
  friend,    // フレンド
  rival,     // ライバル
  blocked,   // ブロック中
}

/// 対局申請
class MatchRequest {
  /// 申請ID
  final String id;

  /// 申請者ID
  final String requesterId;

  /// 申請者名
  final String requesterName;

  /// 申請者画像
  final String? requesterImage;

  /// 受信者ID
  final String receiverId;

  /// ステータス
  final MatchRequestStatus status;

  /// メモ
  final String? message;

  /// 作成日時（ISO 8601）
  final String createdAt;

  /// 応答日時（ISO 8601）
  final String? respondedAt;

  MatchRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterImage,
    required this.receiverId,
    this.status = MatchRequestStatus.pending,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  /// JSONから復元
  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    return MatchRequest(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      requesterImage: json['requesterImage'] as String?,
      receiverId: json['receiverId'] as String,
      status: MatchRequestStatus.values[json['status'] as int? ?? 0],
      message: json['message'] as String?,
      createdAt: json['createdAt'] as String,
      respondedAt: json['respondedAt'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterImage': requesterImage,
      'receiverId': receiverId,
      'status': status.index,
      'message': message,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }
}

/// 対局申請ステータス
enum MatchRequestStatus {
  pending,   // 待機中
  accepted,  // 受け入れ
  declined,  // 拒否
  cancelled, // キャンセル
  expired,   // 期限切れ
}
