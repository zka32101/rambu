/// Friend & Social Models
/// フレンド申請・フレンド関係・対戦招待・アクティビティフィードの管理

/// フレンド申請の状態
enum FriendRequestStatus {
  pending,   // 申請中
  accepted,  // 承認済み
  declined,  // 拒否済み
  blocked;   // ブロック

  String get label => switch (this) {
    FriendRequestStatus.pending => '申請中',
    FriendRequestStatus.accepted => '承認済み',
    FriendRequestStatus.declined => '拒否済み',
    FriendRequestStatus.blocked => 'ブロック中',
  };
}

/// 対戦招待の状態
enum BattleInviteStatus {
  pending,   // 招待中
  accepted,  // 承諾済み
  declined,  // 拒否済み
  expired,   // 期限切れ
  cancelled; // キャンセル済み

  String get label => switch (this) {
    BattleInviteStatus.pending => '招待中',
    BattleInviteStatus.accepted => '承諾済み',
    BattleInviteStatus.declined => '拒否済み',
    BattleInviteStatus.expired => '期限切れ',
    BattleInviteStatus.cancelled => 'キャンセル済み',
  };
}

/// フレンドアクティビティの種類
enum FriendActivityType {
  gameWon,             // 対局勝利
  achievementUnlocked, // 実績解除
  rankUp,              // ランクアップ
  tournamentJoined,    // トーナメント参加
  becameFriends;       // フレンド追加

  String get label => switch (this) {
    FriendActivityType.gameWon => '対局勝利',
    FriendActivityType.achievementUnlocked => '実績解除',
    FriendActivityType.rankUp => 'ランクアップ',
    FriendActivityType.tournamentJoined => 'トーナメント参加',
    FriendActivityType.becameFriends => 'フレンド追加',
  };
}

/// フレンド申請
class FriendRequest {
  /// 申請ID
  final String id;

  /// 送信元ユーザーID
  final String fromUserId;

  /// 送信元ユーザー名
  final String fromUserName;

  /// 送信先ユーザーID
  final String toUserId;

  /// 送信先ユーザー名
  final String toUserName;

  /// 申請状態
  final FriendRequestStatus status;

  /// 送信日時（ISO 8601）
  final String sentAt;

  /// 応答日時（ISO 8601）
  final String? respondedAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    this.status = FriendRequestStatus.pending,
    required this.sentAt,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      status: FriendRequestStatus.values[json['status'] as int? ?? 0],
      sentAt: json['sentAt'] as String,
      respondedAt: json['respondedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'status': status.index,
        'sentAt': sentAt,
        'respondedAt': respondedAt,
      };

  FriendRequest copyWith({
    FriendRequestStatus? status,
    String? respondedAt,
  }) {
    return FriendRequest(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      status: status ?? this.status,
      sentAt: sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// フレンド関係（成立済み）
class Friendship {
  /// フレンドのユーザーID
  final String friendId;

  /// フレンドの表示名
  final String friendName;

  /// フレンドのプロフィール画像URL
  final String? friendProfileImageUrl;

  /// フレンド成立日時（ISO 8601）
  final String becameFriendsAt;

  /// 対戦成績: 自分の勝利数
  final int headToHeadWins;

  /// 対戦成績: 自分の敗北数
  final int headToHeadLosses;

  /// 最終対戦日時（ISO 8601）
  final String? lastPlayedAt;

  /// オンライン状態
  final bool isOnline;

  Friendship({
    required this.friendId,
    required this.friendName,
    this.friendProfileImageUrl,
    required this.becameFriendsAt,
    this.headToHeadWins = 0,
    this.headToHeadLosses = 0,
    this.lastPlayedAt,
    this.isOnline = false,
  });

  /// 対戦成績の総数
  int get totalHeadToHeadGames => headToHeadWins + headToHeadLosses;

  /// フレンドに対する勝率（0-1.0）
  double get headToHeadWinRate =>
      totalHeadToHeadGames == 0 ? 0.0 : headToHeadWins / totalHeadToHeadGames;

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      friendProfileImageUrl: json['friendProfileImageUrl'] as String?,
      becameFriendsAt: json['becameFriendsAt'] as String,
      headToHeadWins: json['headToHeadWins'] as int? ?? 0,
      headToHeadLosses: json['headToHeadLosses'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'friendId': friendId,
        'friendName': friendName,
        'friendProfileImageUrl': friendProfileImageUrl,
        'becameFriendsAt': becameFriendsAt,
        'headToHeadWins': headToHeadWins,
        'headToHeadLosses': headToHeadLosses,
        'lastPlayedAt': lastPlayedAt,
        'isOnline': isOnline,
      };

  Friendship copyWith({
    int? headToHeadWins,
    int? headToHeadLosses,
    String? lastPlayedAt,
    bool? isOnline,
  }) {
    return Friendship(
      friendId: friendId,
      friendName: friendName,
      friendProfileImageUrl: friendProfileImageUrl,
      becameFriendsAt: becameFriendsAt,
      headToHeadWins: headToHeadWins ?? this.headToHeadWins,
      headToHeadLosses: headToHeadLosses ?? this.headToHeadLosses,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// フレンド対戦招待
class BattleInvite {
  /// 招待ID
  final String id;

  /// 送信元ユーザーID
  final String fromUserId;

  /// 送信元ユーザー名
  final String fromUserName;

  /// 送信先ユーザーID
  final String toUserId;

  /// 送信先ユーザー名
  final String toUserName;

  /// 招待状態
  final BattleInviteStatus status;

  /// 難易度設定（対戦条件）
  final String difficulty;

  /// 作成日時（ISO 8601）
  final String createdAt;

  /// 有効期限（ISO 8601）
  final String expiresAt;

  /// 承諾後に生成される対局セッションID
  final String? gameSessionId;

  BattleInvite({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    this.status = BattleInviteStatus.pending,
    this.difficulty = '中級',
    required this.createdAt,
    required this.expiresAt,
    this.gameSessionId,
  });

  /// 有効期限切れかどうか（判定時刻を明示的に渡す）
  bool isExpiredAt(DateTime now) {
    final expiry = DateTime.parse(expiresAt);
    return now.isAfter(expiry);
  }

  factory BattleInvite.fromJson(Map<String, dynamic> json) {
    return BattleInvite(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      status: BattleInviteStatus.values[json['status'] as int? ?? 0],
      difficulty: json['difficulty'] as String? ?? '中級',
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String,
      gameSessionId: json['gameSessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'status': status.index,
        'difficulty': difficulty,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'gameSessionId': gameSessionId,
      };

  BattleInvite copyWith({
    BattleInviteStatus? status,
    String? gameSessionId,
  }) {
    return BattleInvite(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      status: status ?? this.status,
      difficulty: difficulty,
      createdAt: createdAt,
      expiresAt: expiresAt,
      gameSessionId: gameSessionId ?? this.gameSessionId,
    );
  }
}

/// フレンドアクティビティ（フィード表示用）
class FriendActivity {
  /// アクティビティID
  final String id;

  /// アクティビティを起こしたフレンドのユーザーID
  final String friendId;

  /// フレンド名
  final String friendName;

  /// アクティビティ種別
  final FriendActivityType type;

  /// 表示用の説明文
  final String description;

  /// 発生日時（ISO 8601）
  final String occurredAt;

  FriendActivity({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.type,
    required this.description,
    required this.occurredAt,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      id: json['id'] as String,
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      type: FriendActivityType.values[json['type'] as int? ?? 0],
      description: json['description'] as String,
      occurredAt: json['occurredAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'friendId': friendId,
        'friendName': friendName,
        'type': type.index,
        'description': description,
        'occurredAt': occurredAt,
      };
}
