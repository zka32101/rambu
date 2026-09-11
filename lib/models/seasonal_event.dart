/// Seasonal Event Model
/// シーズナルイベント・バトルパス・シーズン管理

/// シーズンステータス
enum SeasonStatus {
  upcoming,   // 予定中
  active,     // 開催中
  ending,     // 終了間近
  closed,     // 終了
}

/// シーズン
class Season {
  /// シーズンID
  final String id;

  /// シーズン名
  final String name;

  /// シーズン説明
  final String description;

  /// シーズン番号（1, 2, 3...）
  final int seasonNumber;

  /// ステータス
  final SeasonStatus status;

  /// 開始日時（ISO 8601）
  final String startDate;

  /// 終了日時（ISO 8601）
  final String endDate;

  /// テーマ色（HEX）
  final String themeColor;

  /// シーズンイメージURL
  final String? imageUrl;

  /// 報酬プール
  final int totalRewardPool;

  Season({
    required this.id,
    required this.name,
    required this.description,
    required this.seasonNumber,
    this.status = SeasonStatus.upcoming,
    required this.startDate,
    required this.endDate,
    required this.themeColor,
    this.imageUrl,
    this.totalRewardPool = 0,
  });

  /// JSONから復元
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      seasonNumber: json['seasonNumber'] as int,
      status: SeasonStatus.values[json['status'] as int? ?? 0],
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      themeColor: json['themeColor'] as String,
      imageUrl: json['imageUrl'] as String?,
      totalRewardPool: json['totalRewardPool'] as int? ?? 0,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'seasonNumber': seasonNumber,
      'status': status.index,
      'startDate': startDate,
      'endDate': endDate,
      'themeColor': themeColor,
      'imageUrl': imageUrl,
      'totalRewardPool': totalRewardPool,
    };
  }
}

/// バトルパス
class BattlePass {
  /// バトルパスID
  final String id;

  /// シーズンID
  final String seasonId;

  /// パスタイプ
  final BattlePassType type;

  /// レベル
  final int maxLevel;

  /// 説明
  final String description;

  /// 価格（プレミアムのみ）
  final int? price;

  /// 通貨（USD, JPY, etc.）
  final String? currency;

  BattlePass({
    required this.id,
    required this.seasonId,
    required this.type,
    this.maxLevel = 100,
    required this.description,
    this.price,
    this.currency,
  });

  /// JSONから復元
  factory BattlePass.fromJson(Map<String, dynamic> json) {
    return BattlePass(
      id: json['id'] as String,
      seasonId: json['seasonId'] as String,
      type: BattlePassType.values[json['type'] as int? ?? 0],
      maxLevel: json['maxLevel'] as int? ?? 100,
      description: json['description'] as String,
      price: json['price'] as int?,
      currency: json['currency'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonId': seasonId,
      'type': type.index,
      'maxLevel': maxLevel,
      'description': description,
      'price': price,
      'currency': currency,
    };
  }
}

/// バトルパスタイプ
enum BattlePassType {
  free,     // フリー
  premium,  // プレミアム
}

/// ユーザーバトルパス進捗
class UserBattlePass {
  /// ユーザーID
  final String userId;

  /// バトルパスID
  final String battlePassId;

  /// シーズンID
  final String seasonId;

  /// 現在レベル
  final int currentLevel;

  /// 現在の進捗ポイント
  final int currentProgress;

  /// 次レベルに必要なポイント
  final int progressPerLevel;

  /// 購入状態（プレミアムの場合）
  final bool isPurchased;

  /// 購入日時（ISO 8601）
  final String? purchasedAt;

  /// 完成状態（Max Levelに到達したか）
  final bool isCompleted;

  /// 獲得報酬リスト
  final List<String> claimedRewards;

  /// レベル進捗パーセント（0-100）
  double get levelProgressPercent {
    return (currentProgress / progressPerLevel) * 100;
  }

  UserBattlePass({
    required this.userId,
    required this.battlePassId,
    required this.seasonId,
    this.currentLevel = 1,
    this.currentProgress = 0,
    this.progressPerLevel = 1000,
    this.isPurchased = false,
    this.purchasedAt,
    this.isCompleted = false,
    this.claimedRewards = const [],
  });

  /// JSONから復元
  factory UserBattlePass.fromJson(Map<String, dynamic> json) {
    return UserBattlePass(
      userId: json['userId'] as String,
      battlePassId: json['battlePassId'] as String,
      seasonId: json['seasonId'] as String,
      currentLevel: json['currentLevel'] as int? ?? 1,
      currentProgress: json['currentProgress'] as int? ?? 0,
      progressPerLevel: json['progressPerLevel'] as int? ?? 1000,
      isPurchased: json['isPurchased'] as bool? ?? false,
      purchasedAt: json['purchasedAt'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      claimedRewards: List<String>.from(json['claimedRewards'] as List? ?? []),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'battlePassId': battlePassId,
      'seasonId': seasonId,
      'currentLevel': currentLevel,
      'currentProgress': currentProgress,
      'progressPerLevel': progressPerLevel,
      'isPurchased': isPurchased,
      'purchasedAt': purchasedAt,
      'isCompleted': isCompleted,
      'claimedRewards': claimedRewards,
    };
  }

  /// copyWith
  UserBattlePass copyWith({
    int? currentLevel,
    int? currentProgress,
    bool? isPurchased,
    String? purchasedAt,
    bool? isCompleted,
    List<String>? claimedRewards,
  }) {
    return UserBattlePass(
      userId: userId,
      battlePassId: battlePassId,
      seasonId: seasonId,
      currentLevel: currentLevel ?? this.currentLevel,
      currentProgress: currentProgress ?? this.currentProgress,
      progressPerLevel: progressPerLevel,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      claimedRewards: claimedRewards ?? this.claimedRewards,
    );
  }
}

/// バトルパス報酬
class BattlePassReward {
  /// 報酬ID
  final String id;

  /// バトルパスID
  final String battlePassId;

  /// レベル（1-100）
  final int level;

  /// 報酬タイプ
  final RewardType type;

  /// 報酬内容（アイテムID、ポイント額など）
  final String rewardContent;

  /// 報酬説明
  final String description;

  /// アイコン
  final String icon;

  /// フリーパスで利用可能か
  final bool isFreeTierAvailable;

  BattlePassReward({
    required this.id,
    required this.battlePassId,
    required this.level,
    required this.type,
    required this.rewardContent,
    required this.description,
    required this.icon,
    this.isFreeTierAvailable = false,
  });

  /// JSONから復元
  factory BattlePassReward.fromJson(Map<String, dynamic> json) {
    return BattlePassReward(
      id: json['id'] as String,
      battlePassId: json['battlePassId'] as String,
      level: json['level'] as int,
      type: RewardType.values[json['type'] as int? ?? 0],
      rewardContent: json['rewardContent'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isFreeTierAvailable: json['isFreeTierAvailable'] as bool? ?? false,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'battlePassId': battlePassId,
      'level': level,
      'type': type.index,
      'rewardContent': rewardContent,
      'description': description,
      'icon': icon,
      'isFreeTierAvailable': isFreeTierAvailable,
    };
  }
}

/// 報酬タイプ
enum RewardType {
  cosmetic,      // コスメティック（スキン等）
  points,        // ポイント
  achievement,   // 実績
  badge,         // バッジ
  title,         // タイトル
  emoticon,      // エモート
}

/// シーズナルチャレンジ
class SeasonalChallenge {
  /// チャレンジID
  final String id;

  /// シーズンID
  final String seasonId;

  /// チャレンジ名
  final String name;

  /// チャレンジ説明
  final String description;

  /// 報酬ポイント（バトルパス進捗）
  final int rewardPoints;

  /// 目標
  final String objective;

  /// 難易度（1-5）
  final int difficulty;

  /// リセット頻度
  final ResetFrequency resetFrequency;

  /// 進捗タイプ
  final ProgressType progressType;

  /// 必要進捗量
  final int requiredProgress;

  SeasonalChallenge({
    required this.id,
    required this.seasonId,
    required this.name,
    required this.description,
    required this.rewardPoints,
    required this.objective,
    this.difficulty = 2,
    this.resetFrequency = ResetFrequency.weekly,
    this.progressType = ProgressType.count,
    this.requiredProgress = 1,
  });

  /// JSONから復元
  factory SeasonalChallenge.fromJson(Map<String, dynamic> json) {
    return SeasonalChallenge(
      id: json['id'] as String,
      seasonId: json['seasonId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rewardPoints: json['rewardPoints'] as int,
      objective: json['objective'] as String,
      difficulty: json['difficulty'] as int? ?? 2,
      resetFrequency: ResetFrequency.values[json['resetFrequency'] as int? ?? 1],
      progressType: ProgressType.values[json['progressType'] as int? ?? 0],
      requiredProgress: json['requiredProgress'] as int? ?? 1,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonId': seasonId,
      'name': name,
      'description': description,
      'rewardPoints': rewardPoints,
      'objective': objective,
      'difficulty': difficulty,
      'resetFrequency': resetFrequency.index,
      'progressType': progressType.index,
      'requiredProgress': requiredProgress,
    };
  }
}

/// リセット頻度
enum ResetFrequency {
  daily,    // 毎日
  weekly,   // 毎週
  monthly,  // 毎月
  seasonal, // シーズン終了時
}

/// 進捗タイプ
enum ProgressType {
  count,     // カウント
  milestone, // マイルストーン
  timeLimit, // 時間制限
}

/// ユーザーシーズナルチャレンジ進捗
class UserSeasonalChallenge {
  /// ユーザーID
  final String userId;

  /// チャレンジID
  final String challengeId;

  /// シーズンID
  final String seasonId;

  /// 現在の進捗
  final int currentProgress;

  /// 完了状態
  final bool isCompleted;

  /// 完了日時（ISO 8601）
  final String? completedAt;

  /// 報酬クレーム状態
  final bool rewardClaimed;

  /// 進捗パーセント（0-100）
  double get progressPercent {
    // この値は利用時に実際のrequiredProgressで計算される
    return 0.0;
  }

  UserSeasonalChallenge({
    required this.userId,
    required this.challengeId,
    required this.seasonId,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.rewardClaimed = false,
  });

  /// JSONから復元
  factory UserSeasonalChallenge.fromJson(Map<String, dynamic> json) {
    return UserSeasonalChallenge(
      userId: json['userId'] as String,
      challengeId: json['challengeId'] as String,
      seasonId: json['seasonId'] as String,
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
      'seasonId': seasonId,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'rewardClaimed': rewardClaimed,
    };
  }

  /// copyWith
  UserSeasonalChallenge copyWith({
    int? currentProgress,
    bool? isCompleted,
    String? completedAt,
    bool? rewardClaimed,
  }) {
    return UserSeasonalChallenge(
      userId: userId,
      challengeId: challengeId,
      seasonId: seasonId,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }
}

/// シーズンシステムデータ
class SeasonSystemData {
  /// 現在のシーズン
  final Season currentSeason;

  /// ユーザーバトルパス進捗
  final UserBattlePass userBattlePass;

  /// 利用可能なチャレンジ
  final List<SeasonalChallenge> availableChallenges;

  /// ユーザーのチャレンジ進捗
  final List<UserSeasonalChallenge> userChallengeProgress;

  /// バトルパス報酬
  final List<BattlePassReward> battlePassRewards;

  SeasonSystemData({
    required this.currentSeason,
    required this.userBattlePass,
    required this.availableChallenges,
    required this.userChallengeProgress,
    required this.battlePassRewards,
  });
}
