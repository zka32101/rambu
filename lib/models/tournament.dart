/// Tournament Model
/// トーナメント・マッチング・ブラケット管理

/// トーナメント形式
enum TournamentFormat {
  singleElimination,  // シングルエリミネーション
  doubleElimination,  // ダブルエリミネーション
  roundRobin,         // リーグ戦
  swiss,              // スイス式
}

/// トーナメントステータス
enum TournamentStatus {
  upcoming,    // 予定中
  registration, // 参加受付中
  active,      // 開催中
  completed,   // 終了
  cancelled,   // キャンセル
}

/// マッチステータス
enum MatchStatus {
  scheduled,   // 予定
  inProgress,  // 進行中
  completed,   // 終了
  cancelled,   // キャンセル
}

/// トーナメント
class Tournament {
  /// トーナメントID
  final String id;

  /// トーナメント名
  final String name;

  /// トーナメント説明
  final String description;

  /// トーナメント形式
  final TournamentFormat format;

  /// ステータス
  final TournamentStatus status;

  /// 最大参加人数
  final int maxParticipants;

  /// 現在の参加者数
  final int currentParticipants;

  /// 参加費（ポイント）
  final int entryFee;

  /// 賞金プール合計
  final int prizePool;

  /// 開始日時（ISO 8601）
  final String startDate;

  /// 終了日時（ISO 8601）
  final String endDate;

  /// ベストオブ（3 = BO3, 5 = BO5）
  final int bestOf;

  /// トーナメント主催者ID
  final String organizerId;

  /// 規定レーティング以上
  final int minRating;

  /// 規定レーティング以下
  final int maxRating;

  /// 地域（JP, EN, etc.）
  final String region;

  /// スペクテーター許可
  final bool allowSpectators;

  /// ストリーミング許可
  final bool allowStreaming;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    this.status = TournamentStatus.upcoming,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.entryFee = 0,
    this.prizePool = 0,
    required this.startDate,
    required this.endDate,
    this.bestOf = 3,
    required this.organizerId,
    this.minRating = 0,
    this.maxRating = 3000,
    this.region = 'JP',
    this.allowSpectators = true,
    this.allowStreaming = true,
  });

  /// JSONから復元
  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      format: TournamentFormat.values[json['format'] as int? ?? 0],
      status: TournamentStatus.values[json['status'] as int? ?? 0],
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      entryFee: json['entryFee'] as int? ?? 0,
      prizePool: json['prizePool'] as int? ?? 0,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      bestOf: json['bestOf'] as int? ?? 3,
      organizerId: json['organizerId'] as String,
      minRating: json['minRating'] as int? ?? 0,
      maxRating: json['maxRating'] as int? ?? 3000,
      region: json['region'] as String? ?? 'JP',
      allowSpectators: json['allowSpectators'] as bool? ?? true,
      allowStreaming: json['allowStreaming'] as bool? ?? true,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'format': format.index,
      'status': status.index,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'startDate': startDate,
      'endDate': endDate,
      'bestOf': bestOf,
      'organizerId': organizerId,
      'minRating': minRating,
      'maxRating': maxRating,
      'region': region,
      'allowSpectators': allowSpectators,
      'allowStreaming': allowStreaming,
    };
  }
}

/// トーナメント参加者
class TournamentParticipant {
  /// ユーザーID
  final String userId;

  /// ユーザー名
  final String userName;

  /// ユーザーレーティング
  final int rating;

  /// シード順位（1位 = 最強）
  final int seed;

  /// 登録日時（ISO 8601）
  final String registeredAt;

  /// 参加費納付済み
  final bool feePaid;

  /// チェックイン完了
  final bool checkedIn;

  /// 最終成績（1位/2位/ベスト4など）
  final String finalPlacement;

  /// 獲得賞金
  final int prizeWon;

  TournamentParticipant({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.seed,
    required this.registeredAt,
    this.feePaid = false,
    this.checkedIn = false,
    this.finalPlacement = '',
    this.prizeWon = 0,
  });

  /// JSONから復元
  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: json['rating'] as int,
      seed: json['seed'] as int,
      registeredAt: json['registeredAt'] as String,
      feePaid: json['feePaid'] as bool? ?? false,
      checkedIn: json['checkedIn'] as bool? ?? false,
      finalPlacement: json['finalPlacement'] as String? ?? '',
      prizeWon: json['prizeWon'] as int? ?? 0,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'seed': seed,
      'registeredAt': registeredAt,
      'feePaid': feePaid,
      'checkedIn': checkedIn,
      'finalPlacement': finalPlacement,
      'prizeWon': prizeWon,
    };
  }

  /// copyWith
  TournamentParticipant copyWith({
    int? seed,
    bool? feePaid,
    bool? checkedIn,
    String? finalPlacement,
    int? prizeWon,
  }) {
    return TournamentParticipant(
      userId: userId,
      userName: userName,
      rating: rating,
      seed: seed ?? this.seed,
      registeredAt: registeredAt,
      feePaid: feePaid ?? this.feePaid,
      checkedIn: checkedIn ?? this.checkedIn,
      finalPlacement: finalPlacement ?? this.finalPlacement,
      prizeWon: prizeWon ?? this.prizeWon,
    );
  }
}

/// トーナメントマッチ
class TournamentMatch {
  /// マッチID
  final String id;

  /// トーナメントID
  final String tournamentId;

  /// ラウンド（1 = 1回戦, 2 = 2回戦など）
  final int round;

  /// マッチ番号（各ラウンド内での番号）
  final int matchNumber;

  /// プレイヤー1 ID
  final String player1Id;

  /// プレイヤー1 名前
  final String player1Name;

  /// プレイヤー1 シード
  final int player1Seed;

  /// プレイヤー2 ID
  final String? player2Id;

  /// プレイヤー2 名前
  final String? player2Name;

  /// プレイヤー2 シード
  final int? player2Seed;

  /// ステータス
  final MatchStatus status;

  /// マッチ開始時刻（ISO 8601）
  final String? scheduledTime;

  /// マッチ終了時刻（ISO 8601）
  final String? completedAt;

  /// 勝者プレイヤーID
  final String? winnerId;

  /// プレイヤー1スコア
  final int player1Score;

  /// プレイヤー2スコア
  final int player2Score;

  /// ゲームログURL
  final String? gameLogUrl;

  /// ストリーム URL
  final String? streamUrl;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.matchNumber,
    required this.player1Id,
    required this.player1Name,
    required this.player1Seed,
    this.player2Id,
    this.player2Name,
    this.player2Seed,
    this.status = MatchStatus.scheduled,
    this.scheduledTime,
    this.completedAt,
    this.winnerId,
    this.player1Score = 0,
    this.player2Score = 0,
    this.gameLogUrl,
    this.streamUrl,
  });

  /// JSONから復元
  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      round: json['round'] as int,
      matchNumber: json['matchNumber'] as int,
      player1Id: json['player1Id'] as String,
      player1Name: json['player1Name'] as String,
      player1Seed: json['player1Seed'] as int,
      player2Id: json['player2Id'] as String?,
      player2Name: json['player2Name'] as String?,
      player2Seed: json['player2Seed'] as int?,
      status: MatchStatus.values[json['status'] as int? ?? 0],
      scheduledTime: json['scheduledTime'] as String?,
      completedAt: json['completedAt'] as String?,
      winnerId: json['winnerId'] as String?,
      player1Score: json['player1Score'] as int? ?? 0,
      player2Score: json['player2Score'] as int? ?? 0,
      gameLogUrl: json['gameLogUrl'] as String?,
      streamUrl: json['streamUrl'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'round': round,
      'matchNumber': matchNumber,
      'player1Id': player1Id,
      'player1Name': player1Name,
      'player1Seed': player1Seed,
      'player2Id': player2Id,
      'player2Name': player2Name,
      'player2Seed': player2Seed,
      'status': status.index,
      'scheduledTime': scheduledTime,
      'completedAt': completedAt,
      'winnerId': winnerId,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'gameLogUrl': gameLogUrl,
      'streamUrl': streamUrl,
    };
  }

  /// copyWith
  TournamentMatch copyWith({
    MatchStatus? status,
    String? scheduledTime,
    String? completedAt,
    String? winnerId,
    int? player1Score,
    int? player2Score,
    String? gameLogUrl,
    String? streamUrl,
  }) {
    return TournamentMatch(
      id: id,
      tournamentId: tournamentId,
      round: round,
      matchNumber: matchNumber,
      player1Id: player1Id,
      player1Name: player1Name,
      player1Seed: player1Seed,
      player2Id: player2Id,
      player2Name: player2Name,
      player2Seed: player2Seed,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedAt: completedAt ?? this.completedAt,
      winnerId: winnerId ?? this.winnerId,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      gameLogUrl: gameLogUrl ?? this.gameLogUrl,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }
}

/// トーナメント賞金構成
class PrizeStructure {
  /// 順位
  final int placement;

  /// 賞金（ポイント）
  final int prizeAmount;

  /// パーセンテージ（プール比）
  final double percentage;

  PrizeStructure({
    required this.placement,
    required this.prizeAmount,
    required this.percentage,
  });

  /// JSONから復元
  factory PrizeStructure.fromJson(Map<String, dynamic> json) {
    return PrizeStructure(
      placement: json['placement'] as int,
      prizeAmount: json['prizeAmount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'placement': placement,
      'prizeAmount': prizeAmount,
      'percentage': percentage,
    };
  }
}

/// トーナメント統計
class TournamentStats {
  /// トーナメントID
  final String tournamentId;

  /// 総参加者数
  final int totalParticipants;

  /// 完了マッチ数
  final int completedMatches;

  /// 予定マッチ数
  final int scheduledMatches;

  /// 平均マッチ長（分）
  final int averageMatchDuration;

  /// 最高シード進出
  final int highestSeedWon;

  /// 最低シード進出
  final int lowestSeedWon;

  /// 無敗の参加者
  final int undefeatedCount;

  TournamentStats({
    required this.tournamentId,
    required this.totalParticipants,
    this.completedMatches = 0,
    this.scheduledMatches = 0,
    this.averageMatchDuration = 0,
    this.highestSeedWon = 1,
    this.lowestSeedWon = 1,
    this.undefeatedCount = 0,
  });

  /// JSONから復元
  factory TournamentStats.fromJson(Map<String, dynamic> json) {
    return TournamentStats(
      tournamentId: json['tournamentId'] as String,
      totalParticipants: json['totalParticipants'] as int,
      completedMatches: json['completedMatches'] as int? ?? 0,
      scheduledMatches: json['scheduledMatches'] as int? ?? 0,
      averageMatchDuration: json['averageMatchDuration'] as int? ?? 0,
      highestSeedWon: json['highestSeedWon'] as int? ?? 1,
      lowestSeedWon: json['lowestSeedWon'] as int? ?? 1,
      undefeatedCount: json['undefeatedCount'] as int? ?? 0,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'totalParticipants': totalParticipants,
      'completedMatches': completedMatches,
      'scheduledMatches': scheduledMatches,
      'averageMatchDuration': averageMatchDuration,
      'highestSeedWon': highestSeedWon,
      'lowestSeedWon': lowestSeedWon,
      'undefeatedCount': undefeatedCount,
    };
  }
}

/// トーナメント詳細データ
class TournamentDetail {
  /// トーナメント
  final Tournament tournament;

  /// 参加者リスト
  final List<TournamentParticipant> participants;

  /// マッチリスト
  final List<TournamentMatch> matches;

  /// 賞金構成
  final List<PrizeStructure> prizeStructure;

  /// トーナメント統計
  final TournamentStats stats;

  TournamentDetail({
    required this.tournament,
    required this.participants,
    required this.matches,
    required this.prizeStructure,
    required this.stats,
  });
}
