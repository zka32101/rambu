/// Leaderboard Provider
/// ランキング状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/user_profile.dart';
import 'package:rambu_shogi/services/leaderboard_service.dart';

/// ランキング サービス プロバイダー
final leaderboardServiceProvider = Provider((ref) {
  return LeaderboardService();
});

/// ランキング ストリーム プロバイダー
final leaderboardStreamProvider = Provider((ref) {
  return LeaderboardStreamProvider();
});

/// ランキング カテゴリー フィルター
final leaderboardCategoryProvider = StateProvider<LeaderboardCategory>((ref) {
  return LeaderboardCategory.overall;
});

/// 総合ランキング（Overall）
final overallLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.overall, limit: 100);
});

/// 勝率ランキング
final winRateLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.winRate, limit: 100);
});

/// レベルランキング
final levelLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.level, limit: 100);
});

/// プレイ時間ランキング
final playTimeLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.playTime, limit: 100);
});

/// 実績ランキング
final achievementsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.achievements, limit: 100);
});

/// クリティカルヒット ランキング
final criticalHitsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(LeaderboardCategory.criticalHits, limit: 100);
});

/// 選択されたカテゴリーのランキング
final selectedLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final category = ref.watch(leaderboardCategoryProvider);
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(category, limit: 100);
});

/// ユーザープロフィール
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getUserProfile(userId);
});

/// ユーザーランク
final userRankProvider = FutureProvider.family<int?, String>((ref, userId) async {
  final service = ref.watch(leaderboardServiceProvider);
  final category = ref.watch(leaderboardCategoryProvider);
  return service.getUserRank(userId, category);
});

/// ゲーム対戦相手検索
final gameOpponentsProvider = FutureProvider.family<List<GameOpponent>, GameOpponentFilter>((ref, filter) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.findGameOpponents(
    rankFilter: filter.rankFilter,
    onlineOnly: filter.onlineOnly,
    limit: filter.limit,
  );
});

/// ユーザーランキング ストリーム
final userProfileStreamProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  final streamProvider = ref.watch(leaderboardStreamProvider);
  return streamProvider.watchUserProfile(userId);
});

/// ランキング ストリーム
final leaderboardStreamWatchProvider = StreamProvider.family<List<LeaderboardEntry>, LeaderboardCategory>((ref, category) {
  final streamProvider = ref.watch(leaderboardStreamProvider);
  return streamProvider.watchLeaderboard(category, limit: 100);
});

/// ランキング リフレッシュ トリガー
final leaderboardRefreshProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  await service.refreshLeaderboards();
});

/// ゲーム対戦相手フィルター
class GameOpponentFilter {
  final String? rankFilter;
  final bool onlineOnly;
  final int limit;

  GameOpponentFilter({
    this.rankFilter,
    this.onlineOnly = false,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameOpponentFilter &&
          runtimeType == other.runtimeType &&
          rankFilter == other.rankFilter &&
          onlineOnly == other.onlineOnly &&
          limit == other.limit;

  @override
  int get hashCode => rankFilter.hashCode ^ onlineOnly.hashCode ^ limit.hashCode;
}

/// ランキング スクリーン ノーティファイア
class LeaderboardScreenNotifier extends StateNotifier<LeaderboardScreenState> {
  final LeaderboardService _service;

  LeaderboardScreenNotifier(this._service) : super(LeaderboardScreenState());

  /// ランキング カテゴリーを変更
  void selectCategory(LeaderboardCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// 対戦相手フィルターを更新
  void updateOpponentFilter({
    String? rankFilter,
    bool? onlineOnly,
  }) {
    state = state.copyWith(
      opponentFilter: GameOpponentFilter(
        rankFilter: rankFilter ?? state.opponentFilter.rankFilter,
        onlineOnly: onlineOnly ?? state.opponentFilter.onlineOnly,
      ),
    );
  }

  /// ユーザープロフィール更新
  Future<void> updateUserProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUserProfile(profile);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile: $e',
      );
    }
  }

  /// ユーザー統計更新
  Future<void> updateUserStats({
    required String userId,
    required bool isWin,
    required int gameDurationSeconds,
    required int criticalHitsCount,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUserStats(
        userId: userId,
        isWin: isWin,
        gameDurationSeconds: gameDurationSeconds,
        criticalHitsCount: criticalHitsCount,
      );
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update stats: $e',
      );
    }
  }
}

/// ランキング スクリーン 状態
class LeaderboardScreenState {
  /// 選択されたランキング カテゴリー
  final LeaderboardCategory selectedCategory;

  /// 対戦相手フィルター
  final GameOpponentFilter opponentFilter;

  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  LeaderboardScreenState({
    this.selectedCategory = LeaderboardCategory.overall,
    this.opponentFilter = const GameOpponentFilter(),
    this.isLoading = false,
    this.errorMessage,
  });

  LeaderboardScreenState copyWith({
    LeaderboardCategory? selectedCategory,
    GameOpponentFilter? opponentFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LeaderboardScreenState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      opponentFilter: opponentFilter ?? this.opponentFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// ランキング スクリーン ノーティファイア プロバイダー
final leaderboardScreenProvider =
    StateNotifierProvider<LeaderboardScreenNotifier, LeaderboardScreenState>((ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return LeaderboardScreenNotifier(service);
});
