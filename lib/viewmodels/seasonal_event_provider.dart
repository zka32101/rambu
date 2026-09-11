/// Seasonal Event Provider
/// シーズナルイベント状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/seasonal_event.dart';
import 'package:rambu_shogi/services/seasonal_event_service.dart';

/// シーズナルイベント サービス プロバイダー
final seasonalEventServiceProvider = Provider((ref) {
  return SeasonalEventService();
});

/// シーズナルイベント ストリーム プロバイダー
final seasonalEventStreamProvider = Provider((ref) {
  return SeasonalEventStreamProvider();
});

/// 現在のシーズン
final currentSeasonProvider = FutureProvider<Season?>((ref) async {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getCurrentSeason();
});

/// すべてのシーズン
final allSeasonsProvider = FutureProvider<List<Season>>((ref) async {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getAllSeasons();
});

/// ユーザーのバトルパス進捗
final userBattlePassProvider =
    FutureProvider.family<UserBattlePass?, (String, String)>((ref, args) async {
  final (userId, seasonId) = args;
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getUserBattlePass(userId, seasonId);
});

/// シーズンのバトルパス報酬
final battlePassRewardsProvider =
    FutureProvider.family<List<BattlePassReward>, String>((ref, battlePassId) async {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getBattlePassRewards(battlePassId);
});

/// シーズナルチャレンジ
final seasonalChallengesProvider =
    FutureProvider.family<List<SeasonalChallenge>, String>((ref, seasonId) async {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getSeasonalChallenges(seasonId);
});

/// ユーザーのシーズナルチャレンジ進捗
final userSeasonalChallengesProvider =
    FutureProvider.family<List<UserSeasonalChallenge>, (String, String)>((ref, args) async {
  final (userId, seasonId) = args;
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getUserSeasonalChallenges(userId, seasonId);
});

/// シーズンシステムデータ
final seasonSystemDataProvider = FutureProvider.family<SeasonSystemData?, String>((ref, userId) async {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getSeasonSystemData(userId);
});

/// ユーザーバトルパスストリーム
final userBattlePassStreamProvider =
    StreamProvider.family<UserBattlePass?, (String, String)>((ref, args) {
  final (userId, seasonId) = args;
  final streamProvider = ref.watch(seasonalEventStreamProvider);
  return streamProvider.watchUserBattlePass(userId, seasonId);
});

/// ユーザーシーズナルチャレンジストリーム
final userSeasonalChallengesStreamProvider =
    StreamProvider.family<List<UserSeasonalChallenge>, (String, String)>((ref, args) {
  final (userId, seasonId) = args;
  final streamProvider = ref.watch(seasonalEventStreamProvider);
  return streamProvider.watchUserSeasonalChallenges(userId, seasonId);
});

/// 現在のシーズンストリーム
final currentSeasonStreamProvider = StreamProvider<Season?>((ref) {
  final streamProvider = ref.watch(seasonalEventStreamProvider);
  return streamProvider.watchCurrentSeason();
});

/// シーズナルイベント スクリーン ノーティファイア
class SeasonalEventScreenNotifier extends StateNotifier<SeasonalEventScreenState> {
  final SeasonalEventService _service;

  SeasonalEventScreenNotifier(this._service) : super(SeasonalEventScreenState());

  /// バトルパスタブを選択
  void selectBattlePassType(BattlePassType type) {
    state = state.copyWith(selectedBattlePassType: type);
  }

  /// チャレンジ難易度フィルターを更新
  void setChallengeDifficultyFilter(int? difficulty) {
    state = state.copyWith(difficultyFilter: difficulty);
  }

  /// バトルパス進捗を更新
  Future<void> updateBattlePassProgress(
    String userId,
    String seasonId,
    String battlePassId,
    int pointsGained,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateUserBattlePassProgress(userId, seasonId, battlePassId, pointsGained);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update progress: $e',
      );
    }
  }

  /// バトルパスを購入
  Future<void> purchaseBattlePass(
    String userId,
    String seasonId,
    String battlePassId,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.purchaseBattlePass(userId, seasonId, battlePassId);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to purchase: $e',
      );
    }
  }

  /// 報酬をクレーム
  Future<void> claimReward(
    String userId,
    String seasonId,
    String rewardId,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.claimReward(userId, seasonId, rewardId);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to claim reward: $e',
      );
    }
  }

  /// シーズナルチャレンジ進捗を更新
  Future<void> updateSeasonalChallengeProgress(
    String userId,
    String challengeId,
    String seasonId,
    int progress,
    int requiredProgress,
  ) async {
    try {
      await _service.updateSeasonalChallengeProgress(
        userId,
        challengeId,
        seasonId,
        progress,
        requiredProgress,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update challenge: $e');
    }
  }

  /// チャレンジ報酬をクレーム
  Future<void> claimChallengeReward(
    String userId,
    String challengeId,
    String seasonId,
  ) async {
    try {
      await _service.claimSeasonalChallengeReward(userId, challengeId, seasonId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to claim challenge reward: $e');
    }
  }
}

/// シーズナルイベント スクリーン 状態
class SeasonalEventScreenState {
  /// 選択されたバトルパスタイプ
  final BattlePassType selectedBattlePassType;

  /// チャレンジ難易度フィルター
  final int? difficultyFilter;

  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  SeasonalEventScreenState({
    this.selectedBattlePassType = BattlePassType.free,
    this.difficultyFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  SeasonalEventScreenState copyWith({
    BattlePassType? selectedBattlePassType,
    int? difficultyFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SeasonalEventScreenState(
      selectedBattlePassType: selectedBattlePassType ?? this.selectedBattlePassType,
      difficultyFilter: difficultyFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// シーズナルイベント スクリーン ノーティファイア プロバイダー
final seasonalEventScreenProvider =
    StateNotifierProvider<SeasonalEventScreenNotifier, SeasonalEventScreenState>((ref) {
  final service = ref.watch(seasonalEventServiceProvider);
  return SeasonalEventScreenNotifier(service);
});
