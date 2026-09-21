/// Spectator & Replay Sharing Models
/// 観戦（ライブ配信状態）・リプレイ共有・リプレイコメントの管理

/// ライブ対局のブロードキャスト状態
///
/// 対局中の盤面そのものはローカル状態（Riverpod）で完結させ、
/// 観戦者向けにはこの「要約ドキュメント」のみを Firestore にリアルタイム反映する
/// （CLAUDE.md の Firestore コスト削減方針に準拠）。
class LiveGameBroadcast {
  /// 対局セッションID（GameSession.sessionId と一致）
  final String gameSessionId;

  /// ホスト（先手）ユーザーID
  final String hostUserId;

  /// ホスト表示名
  final String hostUserName;

  /// ゲストユーザーID（vs Bot の場合は null）
  final String? guestUserId;

  /// ゲスト表示名（vs Bot の場合は 'CPU'）
  final String guestUserName;

  /// 観戦許可フラグ
  final bool allowSpectators;

  /// 現在の手数
  final int currentMoveNumber;

  /// ホスト側HP合計（演出用サマリー）
  final int hostTotalHP;

  /// ゲスト側HP合計（演出用サマリー）
  final int guestTotalHP;

  /// 現在の観戦者数
  final int viewerCount;

  /// 配信開始日時（ISO 8601）
  final String startedAt;

  /// 最終更新日時（ISO 8601）
  final String lastUpdatedAt;

  /// 対局終了フラグ
  final bool isFinished;

  LiveGameBroadcast({
    required this.gameSessionId,
    required this.hostUserId,
    required this.hostUserName,
    this.guestUserId,
    this.guestUserName = 'CPU',
    this.allowSpectators = true,
    this.currentMoveNumber = 0,
    this.hostTotalHP = 0,
    this.guestTotalHP = 0,
    this.viewerCount = 0,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.isFinished = false,
  });

  factory LiveGameBroadcast.fromJson(Map<String, dynamic> json) {
    return LiveGameBroadcast(
      gameSessionId: json['gameSessionId'] as String,
      hostUserId: json['hostUserId'] as String,
      hostUserName: json['hostUserName'] as String,
      guestUserId: json['guestUserId'] as String?,
      guestUserName: json['guestUserName'] as String? ?? 'CPU',
      allowSpectators: json['allowSpectators'] as bool? ?? true,
      currentMoveNumber: json['currentMoveNumber'] as int? ?? 0,
      hostTotalHP: json['hostTotalHP'] as int? ?? 0,
      guestTotalHP: json['guestTotalHP'] as int? ?? 0,
      viewerCount: json['viewerCount'] as int? ?? 0,
      startedAt: json['startedAt'] as String,
      lastUpdatedAt: json['lastUpdatedAt'] as String,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameSessionId': gameSessionId,
        'hostUserId': hostUserId,
        'hostUserName': hostUserName,
        'guestUserId': guestUserId,
        'guestUserName': guestUserName,
        'allowSpectators': allowSpectators,
        'currentMoveNumber': currentMoveNumber,
        'hostTotalHP': hostTotalHP,
        'guestTotalHP': guestTotalHP,
        'viewerCount': viewerCount,
        'startedAt': startedAt,
        'lastUpdatedAt': lastUpdatedAt,
        'isFinished': isFinished,
      };

  LiveGameBroadcast copyWith({
    int? currentMoveNumber,
    int? hostTotalHP,
    int? guestTotalHP,
    int? viewerCount,
    String? lastUpdatedAt,
    bool? isFinished,
  }) {
    return LiveGameBroadcast(
      gameSessionId: gameSessionId,
      hostUserId: hostUserId,
      hostUserName: hostUserName,
      guestUserId: guestUserId,
      guestUserName: guestUserName,
      allowSpectators: allowSpectators,
      currentMoveNumber: currentMoveNumber ?? this.currentMoveNumber,
      hostTotalHP: hostTotalHP ?? this.hostTotalHP,
      guestTotalHP: guestTotalHP ?? this.guestTotalHP,
      viewerCount: viewerCount ?? this.viewerCount,
      startedAt: startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

/// リプレイ共有リンク
class ReplayShare {
  /// 共有ID（Firestore ドキュメントID）
  final String id;

  /// 対象の対局記録ID（GameRecord.id）
  final String gameRecordId;

  /// 共有トークン（短縮URLの識別子として使用）
  final String shareToken;

  /// 共有元ユーザーID
  final String ownerUserId;

  /// 共有元ユーザー名
  final String ownerUserName;

  /// 公開設定（true: 誰でも閲覧可, false: リンクを知る人のみ）
  final bool isPublic;

  /// 閲覧数
  final int viewCount;

  /// 作成日時（ISO 8601）
  final String createdAt;

  ReplayShare({
    required this.id,
    required this.gameRecordId,
    required this.shareToken,
    required this.ownerUserId,
    required this.ownerUserName,
    this.isPublic = true,
    this.viewCount = 0,
    required this.createdAt,
  });

  factory ReplayShare.fromJson(Map<String, dynamic> json) {
    return ReplayShare(
      id: json['id'] as String,
      gameRecordId: json['gameRecordId'] as String,
      shareToken: json['shareToken'] as String,
      ownerUserId: json['ownerUserId'] as String,
      ownerUserName: json['ownerUserName'] as String,
      isPublic: json['isPublic'] as bool? ?? true,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameRecordId': gameRecordId,
        'shareToken': shareToken,
        'ownerUserId': ownerUserId,
        'ownerUserName': ownerUserName,
        'isPublic': isPublic,
        'viewCount': viewCount,
        'createdAt': createdAt,
      };

  ReplayShare copyWith({int? viewCount}) {
    return ReplayShare(
      id: id,
      gameRecordId: gameRecordId,
      shareToken: shareToken,
      ownerUserId: ownerUserId,
      ownerUserName: ownerUserName,
      isPublic: isPublic,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt,
    );
  }
}

/// リプレイに対するコメント（着手番号に紐づけ可能）
class ReplayComment {
  /// コメントID
  final String id;

  /// 対象の対局記録ID
  final String gameRecordId;

  /// コメント投稿者ID
  final String userId;

  /// コメント投稿者名
  final String userName;

  /// 紐づく手数（nullの場合は対局全体への感想）
  final int? moveIndex;

  /// コメント本文
  final String text;

  /// 投稿日時（ISO 8601）
  final String createdAt;

  ReplayComment({
    required this.id,
    required this.gameRecordId,
    required this.userId,
    required this.userName,
    this.moveIndex,
    required this.text,
    required this.createdAt,
  });

  factory ReplayComment.fromJson(Map<String, dynamic> json) {
    return ReplayComment(
      id: json['id'] as String,
      gameRecordId: json['gameRecordId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      moveIndex: json['moveIndex'] as int?,
      text: json['text'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameRecordId': gameRecordId,
        'userId': userId,
        'userName': userName,
        'moveIndex': moveIndex,
        'text': text,
        'createdAt': createdAt,
      };
}
