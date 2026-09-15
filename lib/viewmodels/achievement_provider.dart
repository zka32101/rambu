/// Achievement Provider
/// 実績・チャレンジ状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/achievement.dart';
import 'package:rambu_shogi/services/achievement_service.dart';

/// 実績 サービス プロバイダー
final achievementServiceProvider = Provider((ref) {
  return AchievementService();
});

/// 実績 ストリーム プロバイダー
final achievementStreamProvider = Provider((ref) {
  return AchievementStreamProvider();
});

/// すべての実績
final allAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getAllAchievements();
});

/// すべてのチャレンジ
final allChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getAllChallenges();
});

/// チャレンジタイプで取得
final challengesByTypeProvider =
    FutureProvider.family<List<Challenge>, ChallengeType>((ref, type) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getChallengesByType(type);
});

/// ユーザーの実績
final userAchievementsProvider = FutureProvider.family<List<UserAchievement>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserAchievements(userId);
});

/// ユーザーのチャレンジ
final userChallengesProvider = FutureProvider.family<List<UserChallenge>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserChallenges(userId);
});

/// ユーザーのアクティブなチャレンジ
final userActiveChallengesProvider =
    FutureProvider.family<List<UserChallenge>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserActiveChallenges(userId);
});

/// ユーザーの実績ストリーム
final userAchievementsStreamProvider = StreamProvider.family<List<UserAchievement>, String>((ref, userId) {
  final streamProvider = ref.watch(achievementStreamProvider);
  return streamProvider.watchUserAchievements(userId);
});

/// ユーザーのチャレンジストリーム
final userChallengesStreamProvider =
    StreamProvider.family<List<UserChallenge>, String>((ref, userId) {
  final streamProvider = ref.watch(achievementStreamProvider);
  return streamProvider.watchUserChallenges(userId);
});

/// ユーザーの関係（フレンド/ライバル）
final userRelationshipsProvider = FutureProvider.family<List<UserRelationship>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserRelationships(userId);
});

/// ユーザーのフレンド
final userFriendsProvider = FutureProvider.family<List<UserRelationship>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserRelationships(userId, type: RelationshipType.friend);
});

/// ユーザーのライバル
final userRivalsProvider = FutureProvider.family<List<UserRelationship>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getUserRelationships(userId, type: RelationshipType.rival);
});

/// 受信した対局申請
final receivedMatchRequestsProvider =
    FutureProvider.family<List<MatchRequest>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getReceivedMatchRequests(userId);
});

/// 送信した対局申請
final sentMatchRequestsProvider = FutureProvider.family<List<MatchRequest>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return service.getSentMatchRequests(userId);
});

/// 受信申請ストリーム
final receivedMatchRequestsStreamProvider =
    StreamProvider.family<List<MatchRequest>, String>((ref, userId) {
  final streamProvider = ref.watch(achievementStreamProvider);
  return streamProvider.watchReceivedMatchRequests(userId);
});

/// 実績・チャレンジ スクリーン ノーティファイア
class AchievementScreenNotifier extends StateNotifier<AchievementScreenState> {
  final AchievementService _service;

  AchievementScreenNotifier(this._service) : super(AchievementScreenState());

  /// タブを変更
  void selectTab(AchievementTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  /// チャレンジ難易度フィルターを更新
  void setDifficultyFilter(int? difficulty) {
    state = state.copyWith(difficultyFilter: difficulty);
  }

  /// 実績進捗を更新
  Future<void> updateAchievementProgress(
    String userId,
    String achievementId,
    int progress,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUserAchievementProgress(userId, achievementId, progress);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update achievement: $e',
      );
    }
  }

  /// チャレンジ進捗を更新
  Future<void> updateChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUserChallengeProgress(userId, challengeId, progress);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update challenge: $e',
      );
    }
  }

  /// チャレンジ報酬をクレーム
  Future<void> claimChallengeReward(String userId, String challengeId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.claimChallengeReward(userId, challengeId);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to claim reward: $e',
      );
    }
  }

  /// 関係を追加
  Future<void> addRelationship(
    String userId,
    String otherUserId,
    String otherUserName,
    String? otherUserProfileImage,
    RelationshipType type,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.addRelationship(
        userId,
        otherUserId,
        otherUserName,
        otherUserProfileImage,
        type,
      );
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add relationship: $e',
      );
    }
  }

  /// 対局申請を送信
  Future<void> sendMatchRequest(
    String requesterId,
    String requesterName,
    String? requesterImage,
    String receiverId,
    String? message,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.sendMatchRequest(
        requesterId,
        requesterName,
        requesterImage,
        receiverId,
        message,
      );
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send match request: $e',
      );
    }
  }

  /// 対局申請に応答
  Future<void> respondToMatchRequest(
    String requestId,
    MatchRequestStatus status,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.respondToMatchRequest(requestId, status);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to respond to request: $e',
      );
    }
  }
}

/// 実績タブ
enum AchievementTab {
  achievements,  // 実績
  challenges,    // チャレンジ
  friends,       // フレンド
  requests,      // 申請
}

/// 実績・チャレンジ スクリーン 状態
class AchievementScreenState {
  /// 選択されたタブ
  final AchievementTab selectedTab;

  /// チャレンジ難易度フィルター
  final int? difficultyFilter;

  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  AchievementScreenState({
    this.selectedTab = AchievementTab.achievements,
    this.difficultyFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  AchievementScreenState copyWith({
    AchievementTab? selectedTab,
    int? difficultyFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AchievementScreenState(
      selectedTab: selectedTab ?? this.selectedTab,
      difficultyFilter: difficultyFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// 実績・チャレンジ スクリーン ノーティファイア プロバイダー
final achievementScreenProvider =
    StateNotifierProvider<AchievementScreenNotifier, AchievementScreenState>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return AchievementScreenNotifier(service);
});
