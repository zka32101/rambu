/// Spectator Provider
/// 観戦・リプレイ共有の状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/spectator.dart';
import 'package:rambu_shogi/services/spectator_service.dart';

/// Spectator Service Provider
final spectatorServiceProvider = Provider((ref) => SpectatorService());

/// 観戦可能な対局一覧
final activeBroadcastsProvider = FutureProvider<List<LiveGameBroadcast>>((ref) async {
  final service = ref.watch(spectatorServiceProvider);
  return service.getActiveBroadcasts();
});

/// 特定対局のライブ状態（リアルタイム）
final liveBroadcastStreamProvider =
    StreamProvider.family<LiveGameBroadcast?, String>((ref, gameSessionId) {
  final service = ref.watch(spectatorServiceProvider);
  return service.watchBroadcast(gameSessionId);
});

/// トークンによるリプレイ共有情報取得
final replayShareByTokenProvider =
    FutureProvider.family<ReplayShare?, String>((ref, token) async {
  final service = ref.watch(spectatorServiceProvider);
  return service.getReplayShareByToken(token);
});

/// 対局記録に紐づく共有一覧
final replaySharesForRecordProvider =
    FutureProvider.family<List<ReplayShare>, String>((ref, gameRecordId) async {
  final service = ref.watch(spectatorServiceProvider);
  return service.getReplaySharesForRecord(gameRecordId);
});

/// リプレイコメント一覧
final replayCommentsProvider =
    FutureProvider.family<List<ReplayComment>, String>((ref, gameRecordId) async {
  final service = ref.watch(spectatorServiceProvider);
  return service.getReplayComments(gameRecordId);
});

/// 観戦画面 状態
class SpectatorScreenState {
  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  /// 成功メッセージ
  final String? successMessage;

  /// 直近で発行した共有トークン
  final String? lastGeneratedToken;

  SpectatorScreenState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.lastGeneratedToken,
  });

  SpectatorScreenState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? lastGeneratedToken,
  }) {
    return SpectatorScreenState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lastGeneratedToken: lastGeneratedToken ?? this.lastGeneratedToken,
    );
  }
}

/// 観戦画面 ノーティファイア
class SpectatorScreenNotifier extends StateNotifier<SpectatorScreenState> {
  final SpectatorService _service;

  SpectatorScreenNotifier(this._service) : super(SpectatorScreenState());

  /// リプレイ共有リンクを生成
  Future<void> generateReplayShare({
    required String gameRecordId,
    required String ownerUserId,
    required String ownerUserName,
    bool isPublic = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final share = await _service.createReplayShare(
        gameRecordId: gameRecordId,
        ownerUserId: ownerUserId,
        ownerUserName: ownerUserName,
        isPublic: isPublic,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: '共有リンクを作成しました',
        lastGeneratedToken: share.shareToken,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  /// コメントを投稿
  Future<void> postComment({
    required String gameRecordId,
    required String userId,
    required String userName,
    int? moveIndex,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'コメントを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.addReplayComment(
        gameRecordId: gameRecordId,
        userId: userId,
        userName: userName,
        moveIndex: moveIndex,
        text: text.trim(),
      );
      state = state.copyWith(isLoading: false, successMessage: 'コメントを投稿しました');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
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

/// 観戦画面 ノーティファイア プロバイダー
final spectatorScreenProvider =
    StateNotifierProvider<SpectatorScreenNotifier, SpectatorScreenState>((ref) {
  final service = ref.watch(spectatorServiceProvider);
  return SpectatorScreenNotifier(service);
});
