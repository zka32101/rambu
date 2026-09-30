/// Matchmaking Provider
/// レーティングベース自動マッチングの状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/matchmaking.dart';
import 'package:rambu_shogi/services/matchmaking_service.dart';

/// Matchmaking Service Provider
final matchmakingServiceProvider = Provider((ref) => MatchmakingService());

/// 待機エントリーのリアルタイム監視
final matchmakingQueueStreamProvider =
    StreamProvider.family<MatchmakingEntry?, String>((ref, entryId) {
  final service = ref.watch(matchmakingServiceProvider);
  return service.watchQueueEntry(entryId);
});

/// マッチ情報の取得
final matchmakingMatchProvider =
    FutureProvider.family<MatchmakingMatch?, String>((ref, matchId) async {
  final service = ref.watch(matchmakingServiceProvider);
  return service.getMatch(matchId);
});

/// マッチメイキング画面 状態
class MatchmakingScreenState {
  /// 現在の待機エントリーID（null = 未検索）
  final String? currentEntryId;

  /// 検索中フラグ
  final bool isSearching;

  /// エラーメッセージ
  final String? errorMessage;

  /// 検索開始時刻（経過時間表示用）
  final DateTime? searchStartedAt;

  MatchmakingScreenState({
    this.currentEntryId,
    this.isSearching = false,
    this.errorMessage,
    this.searchStartedAt,
  });

  MatchmakingScreenState copyWith({
    String? currentEntryId,
    bool? isSearching,
    String? errorMessage,
    DateTime? searchStartedAt,
    bool clearEntryId = false,
  }) {
    return MatchmakingScreenState(
      currentEntryId: clearEntryId ? null : (currentEntryId ?? this.currentEntryId),
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      searchStartedAt: clearEntryId ? null : (searchStartedAt ?? this.searchStartedAt),
    );
  }
}

/// マッチメイキング画面 ノーティファイア
class MatchmakingScreenNotifier extends StateNotifier<MatchmakingScreenState> {
  final MatchmakingService _service;

  MatchmakingScreenNotifier(this._service) : super(MatchmakingScreenState());

  /// 対戦相手を探す
  Future<void> startSearching({
    required String userId,
    required String userName,
    required double rating,
    double ratingRange = MatchmakingService.defaultRatingRange,
  }) async {
    state = state.copyWith(
      isSearching: true,
      errorMessage: null,
      searchStartedAt: DateTime.now(),
    );
    try {
      final entry = await _service.joinQueue(
        userId: userId,
        userName: userName,
        rating: rating,
        ratingRange: ratingRange,
      );
      state = state.copyWith(currentEntryId: entry.id);
    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: '$e');
    }
  }

  /// 検索をキャンセル
  Future<void> cancelSearching() async {
    final entryId = state.currentEntryId;
    if (entryId != null) {
      try {
        await _service.cancelQueue(entryId);
      } catch (e) {
        state = state.copyWith(errorMessage: '$e');
      }
    }
    state = state.copyWith(isSearching: false, clearEntryId: true);
  }

  /// マッチ成立を検知した際に呼び出す（検索状態を終了）
  void onMatchFound() {
    state = state.copyWith(isSearching: false);
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// マッチメイキング画面 ノーティファイア プロバイダー
final matchmakingScreenProvider =
    StateNotifierProvider<MatchmakingScreenNotifier, MatchmakingScreenState>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return MatchmakingScreenNotifier(service);
});
