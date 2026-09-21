/// Friend Provider
/// フレンド・ソーシャル機能の状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/friend.dart';
import 'package:rambu_shogi/models/user_profile.dart';
import 'package:rambu_shogi/services/friend_service.dart';

/// Friend Service Provider
final friendServiceProvider = Provider((ref) => FriendService());

/// フレンド一覧
final friendsListProvider =
    FutureProvider.family<List<Friendship>, String>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getFriends(userId);
});

/// 受信中のフレンド申請
final incomingFriendRequestsProvider =
    FutureProvider.family<List<FriendRequest>, String>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getIncomingRequests(userId);
});

/// 送信済みのフレンド申請
final outgoingFriendRequestsProvider =
    FutureProvider.family<List<FriendRequest>, String>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getOutgoingRequests(userId);
});

/// 受信中の対戦招待
final pendingBattleInvitesProvider =
    FutureProvider.family<List<BattleInvite>, String>((ref, userId) async {
  final service = ref.watch(friendServiceProvider);
  return service.getPendingInvites(userId);
});

/// ユーザー検索結果
final userSearchProvider =
    FutureProvider.family<List<GameOpponent>, String>((ref, query) async {
  final service = ref.watch(friendServiceProvider);
  return service.searchUsers(query);
});

/// フレンドアクティビティフィード
final friendActivityFeedProvider =
    FutureProvider.family<List<FriendActivity>, List<String>>((ref, friendIds) async {
  final service = ref.watch(friendServiceProvider);
  return service.getFriendActivityFeed(friendIds);
});

/// フレンド画面 状態
class FriendScreenState {
  /// 検索クエリ
  final String searchQuery;

  /// ローディング中フラグ
  final bool isLoading;

  /// エラーメッセージ
  final String? errorMessage;

  /// 成功メッセージ
  final String? successMessage;

  FriendScreenState({
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  FriendScreenState copyWith({
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return FriendScreenState(
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// フレンド画面 ノーティファイア
class FriendScreenNotifier extends StateNotifier<FriendScreenState> {
  final FriendService _service;

  FriendScreenNotifier(this._service) : super(FriendScreenState());

  /// 検索クエリを更新
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// フレンド申請を送信
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.sendFriendRequest(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
      );
      state = state.copyWith(isLoading: false, successMessage: 'フレンド申請を送信しました');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  /// フレンド申請に応答
  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.respondToFriendRequest(requestId, accept);
      state = state.copyWith(
        isLoading: false,
        successMessage: accept ? 'フレンドになりました' : '申請を拒否しました',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  /// フレンドを削除
  Future<void> removeFriend(String userId, String friendId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.removeFriend(userId, friendId);
      state = state.copyWith(isLoading: false, successMessage: 'フレンドを削除しました');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  /// 対戦招待を送信
  Future<void> sendBattleInvite({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    String difficulty = '中級',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.sendBattleInvite(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        difficulty: difficulty,
      );
      state = state.copyWith(isLoading: false, successMessage: '対戦招待を送信しました');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  /// 対戦招待に応答
  Future<void> respondToBattleInvite(String inviteId, bool accept) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.respondToBattleInvite(inviteId, accept);
      state = state.copyWith(
        isLoading: false,
        successMessage: accept ? '対戦を開始します' : '招待を拒否しました',
      );
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

/// フレンド画面 ノーティファイア プロバイダー
final friendScreenProvider =
    StateNotifierProvider<FriendScreenNotifier, FriendScreenState>((ref) {
  final service = ref.watch(friendServiceProvider);
  return FriendScreenNotifier(service);
});
