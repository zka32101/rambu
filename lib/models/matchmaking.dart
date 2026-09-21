/// Matchmaking Models
/// レーティングベース自動マッチングの待機キュー・成立マッチの管理

/// マッチング待機エントリーの状態
enum MatchmakingStatus {
  waiting,   // 待機中
  matched,   // マッチ成立
  cancelled, // ユーザーによるキャンセル
  expired;   // タイムアウト失効

  String get label => switch (this) {
    MatchmakingStatus.waiting => '待機中',
    MatchmakingStatus.matched => 'マッチ成立',
    MatchmakingStatus.cancelled => 'キャンセル済み',
    MatchmakingStatus.expired => '期限切れ',
  };
}

/// マッチング待機キューのエントリー
class MatchmakingEntry {
  /// エントリーID（Firestore ドキュメントID）
  final String id;

  /// ユーザーID
  final String userId;

  /// ユーザー名
  final String userName;

  /// エントリー時点のレーティング
  final double rating;

  /// 対戦相手として許容するレーティング下限
  final double minRatingRange;

  /// 対戦相手として許容するレーティング上限
  final double maxRatingRange;

  /// 待機開始日時（ISO 8601）
  final String queuedAt;

  /// 状態
  final MatchmakingStatus status;

  /// マッチした相手のユーザーID
  final String? matchedWithUserId;

  /// 成立したマッチのID（MatchmakingMatch.id）
  final String? matchId;

  MatchmakingEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.minRatingRange,
    required this.maxRatingRange,
    required this.queuedAt,
    this.status = MatchmakingStatus.waiting,
    this.matchedWithUserId,
    this.matchId,
  });

  /// 相手のレーティングが自分の許容範囲内か
  bool canMatchRating(double otherRating) =>
      otherRating >= minRatingRange && otherRating <= maxRatingRange;

  /// 相手候補とのレーティング差（マッチング優先度の算出に使用）
  double ratingDistanceTo(double otherRating) => (rating - otherRating).abs();

  factory MatchmakingEntry.fromJson(Map<String, dynamic> json) {
    return MatchmakingEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: (json['rating'] as num).toDouble(),
      minRatingRange: (json['minRatingRange'] as num).toDouble(),
      maxRatingRange: (json['maxRatingRange'] as num).toDouble(),
      queuedAt: json['queuedAt'] as String,
      status: MatchmakingStatus.values[json['status'] as int? ?? 0],
      matchedWithUserId: json['matchedWithUserId'] as String?,
      matchId: json['matchId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'minRatingRange': minRatingRange,
        'maxRatingRange': maxRatingRange,
        'queuedAt': queuedAt,
        'status': status.index,
        'matchedWithUserId': matchedWithUserId,
        'matchId': matchId,
      };

  MatchmakingEntry copyWith({
    MatchmakingStatus? status,
    String? matchedWithUserId,
    String? matchId,
  }) {
    return MatchmakingEntry(
      id: id,
      userId: userId,
      userName: userName,
      rating: rating,
      minRatingRange: minRatingRange,
      maxRatingRange: maxRatingRange,
      queuedAt: queuedAt,
      status: status ?? this.status,
      matchedWithUserId: matchedWithUserId ?? this.matchedWithUserId,
      matchId: matchId ?? this.matchId,
    );
  }
}

/// 成立したマッチメイキング対局
class MatchmakingMatch {
  /// マッチID
  final String id;

  /// プレイヤー1（先手）
  final String player1Id;
  final String player1Name;
  final double player1Rating;

  /// プレイヤー2（後手）
  final String player2Id;
  final String player2Name;
  final double player2Rating;

  /// マッチング成立日時（ISO 8601）
  final String matchedAt;

  /// 対局セッションID（両プレイヤーが対局画面を開いた後に紐付け）
  final String? gameSessionId;

  MatchmakingMatch({
    required this.id,
    required this.player1Id,
    required this.player1Name,
    required this.player1Rating,
    required this.player2Id,
    required this.player2Name,
    required this.player2Rating,
    required this.matchedAt,
    this.gameSessionId,
  });

  /// レーティング差（マッチ品質の指標）
  double get ratingGap => (player1Rating - player2Rating).abs();

  factory MatchmakingMatch.fromJson(Map<String, dynamic> json) {
    return MatchmakingMatch(
      id: json['id'] as String,
      player1Id: json['player1Id'] as String,
      player1Name: json['player1Name'] as String,
      player1Rating: (json['player1Rating'] as num).toDouble(),
      player2Id: json['player2Id'] as String,
      player2Name: json['player2Name'] as String,
      player2Rating: (json['player2Rating'] as num).toDouble(),
      matchedAt: json['matchedAt'] as String,
      gameSessionId: json['gameSessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player1Id': player1Id,
        'player1Name': player1Name,
        'player1Rating': player1Rating,
        'player2Id': player2Id,
        'player2Name': player2Name,
        'player2Rating': player2Rating,
        'matchedAt': matchedAt,
        'gameSessionId': gameSessionId,
      };

  MatchmakingMatch copyWith({String? gameSessionId}) {
    return MatchmakingMatch(
      id: id,
      player1Id: player1Id,
      player1Name: player1Name,
      player1Rating: player1Rating,
      player2Id: player2Id,
      player2Name: player2Name,
      player2Rating: player2Rating,
      matchedAt: matchedAt,
      gameSessionId: gameSessionId ?? this.gameSessionId,
    );
  }

  /// 指定ユーザーから見た対戦相手の名前
  String opponentNameFor(String userId) =>
      userId == player1Id ? player2Name : player1Name;

  /// 指定ユーザーから見た対戦相手のレーティング
  double opponentRatingFor(String userId) =>
      userId == player1Id ? player2Rating : player1Rating;
}
