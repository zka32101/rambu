/// Tournament Provider
/// トーナメント状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/tournament.dart';
import 'package:rambu_shogi/services/tournament_service.dart';

/// トーナメント サービス プロバイダー
final tournamentServiceProvider = Provider((ref) {
  return TournamentService();
});

/// すべてのトーナメント
final allTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getAllTournaments();
});

/// 登録受付中のトーナメント
final registrationTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getAllTournaments(status: 'registration');
});

/// 推奨トーナメント
final recommendedTournamentsProvider =
    FutureProvider.family<List<Tournament>, int>((ref, userRating) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getRecommendedTournaments(userRating);
});

/// 特定トーナメント詳細
final tournamentDetailProvider = FutureProvider.family<Tournament?, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournamentById(tournamentId);
});

/// トーナメント参加者
final tournamentParticipantsProvider =
    FutureProvider.family<List<TournamentParticipant>, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournamentParticipants(tournamentId);
});

/// トーナメントマッチ
final tournamentMatchesProvider = FutureProvider.family<List<TournamentMatch>, String>(
  (ref, tournamentId) async {
    final service = ref.watch(tournamentServiceProvider);
    return service.getTournamentMatches(tournamentId);
  },
);

/// 特定ラウンドのマッチ
final tournamentRoundMatchesProvider =
    FutureProvider.family<List<TournamentMatch>, (String, int)>((ref, args) async {
  final (tournamentId, round) = args;
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournamentMatches(tournamentId, round: round);
});

/// トーナメント統計
final tournamentStatsProvider = FutureProvider.family<TournamentStats, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.calculateTournamentStats(tournamentId);
});

/// トーナメント スクリーン ノーティファイア
class TournamentScreenNotifier extends StateNotifier<TournamentScreenState> {
  final TournamentService _service;

  TournamentScreenNotifier(this._service) : super(TournamentScreenState());

  /// トーナメントタイプフィルターを設定
  void setTournamentFormat(TournamentFormat? format) {
    state = state.copyWith(selectedFormat: format);
  }

  /// 参加者を登録
  Future<void> registerForTournament(
    String tournamentId,
    String userId,
    String userName,
    int rating,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.registerParticipant(tournamentId, userId, userName, rating);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'トーナメントに登録しました',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: $e',
      );
    }
  }

  /// チェックイン
  Future<void> checkInTournament(String tournamentId, String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.checkInParticipant(tournamentId, userId);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'チェックインしました',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Check-in failed: $e',
      );
    }
  }

  /// ブラケット生成
  Future<void> generateBracket(String tournamentId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.generateSingleEliminationBracket(tournamentId);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'ブラケットを生成しました',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Bracket generation failed: $e',
      );
    }
  }

  /// マッチ結果を記録
  Future<void> recordMatchResult(
    String tournamentId,
    String matchId,
    String winnerId,
    int player1Score,
    int player2Score,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.recordMatchResult(
        tournamentId,
        matchId,
        winnerId,
        player1Score,
        player2Score,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'マッチ結果を記録しました',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Match recording failed: $e',
      );
    }
  }

  /// 最終順位を記録
  Future<void> recordFinalPlacement(
    String tournamentId,
    String userId,
    String placement,
    int prizeWon,
  ) async {
    try {
      await _service.recordFinalPlacement(tournamentId, userId, placement, prizeWon);
      state = state.copyWith(
        errorMessage: null,
        successMessage: 'Final placement recorded',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to record placement: $e',
      );
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 成功メッセージをクリア
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

/// トーナメント スクリーン 状態
class TournamentScreenState {
  /// 選択されたトーナメント形式
  final TournamentFormat? selectedFormat;

  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  /// 成功メッセージ
  final String? successMessage;

  /// 参加状態フラグ
  final bool isRegistered;

  TournamentScreenState({
    this.selectedFormat,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isRegistered = false,
  });

  TournamentScreenState copyWith({
    TournamentFormat? selectedFormat,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isRegistered,
  }) {
    return TournamentScreenState(
      selectedFormat: selectedFormat ?? this.selectedFormat,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }
}

/// トーナメント スクリーン ノーティファイア プロバイダー
final tournamentScreenProvider =
    StateNotifierProvider<TournamentScreenNotifier, TournamentScreenState>((ref) {
  final service = ref.watch(tournamentServiceProvider);
  return TournamentScreenNotifier(service);
});
