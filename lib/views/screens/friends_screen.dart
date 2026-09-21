/// Friends Screen
/// フレンド一覧・申請・対戦招待・ユーザー検索

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/friend.dart';
import 'package:rambu_shogi/models/user_profile.dart';
import 'package:rambu_shogi/viewmodels/friend_provider.dart';

/// フレンド スクリーン
class FriendsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const FriendsScreen({
    required this.userId,
    required this.userName,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'フレンド'),
            Tab(text: '申請'),
            Tab(text: '対戦招待'),
            Tab(text: '検索'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildInvitesTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // フレンド一覧タブ
  // -----------------------------------------------------------------

  Widget _buildFriendsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final friendsAsync = ref.watch(friendsListProvider(widget.userId));

        return friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) {
              return _buildEmptyState(
                icon: Icons.people_outline,
                message: 'まだフレンドがいません',
                actionLabel: 'ユーザーを検索する',
                onAction: () => _tabController.animateTo(3),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friends.length,
              itemBuilder: (context, index) => _buildFriendCard(friends[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildFriendCard(Friendship friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: friend.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
          child: Text(friend.friendName.isNotEmpty ? friend.friendName[0] : '?'),
        ),
        title: Text(friend.friendName),
        subtitle: Text(
          '対戦成績: ${friend.headToHeadWins}勝${friend.headToHeadLosses}敗'
          '${friend.totalHeadToHeadGames > 0 ? ' (勝率${(friend.headToHeadWinRate * 100).toStringAsFixed(0)}%)' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'invite') {
              _showBattleInviteDialog(friend);
            } else if (value == 'remove') {
              _showRemoveFriendDialog(friend);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'invite', child: Text('対戦に招待')),
            PopupMenuItem(value: 'remove', child: Text('フレンド削除')),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // 申請タブ
  // -----------------------------------------------------------------

  Widget _buildRequestsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final requestsAsync = ref.watch(incomingFriendRequestsProvider(widget.userId));

        return requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return _buildEmptyState(
                icon: Icons.mail_outline,
                message: '新しいフレンド申請はありません',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) => _buildRequestCard(requests[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(request.fromUserName[0])),
        title: Text(request.fromUserName),
        subtitle: const Text('フレンド申請が届いています'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _respondToRequest(request.id, true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _respondToRequest(request.id, false),
            ),
          ],
        ),
      ),
    );
  }

  void _respondToRequest(String requestId, bool accept) async {
    final notifier = ref.read(friendScreenProvider.notifier);
    await notifier.respondToFriendRequest(requestId, accept);
    ref.invalidate(incomingFriendRequestsProvider(widget.userId));
    ref.invalidate(friendsListProvider(widget.userId));
    _showSnackBarFromState();
  }

  // -----------------------------------------------------------------
  // 対戦招待タブ
  // -----------------------------------------------------------------

  Widget _buildInvitesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final invitesAsync = ref.watch(pendingBattleInvitesProvider(widget.userId));

        return invitesAsync.when(
          data: (invites) {
            if (invites.isEmpty) {
              return _buildEmptyState(
                icon: Icons.sports_esports_outlined,
                message: '対戦招待はありません',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invites.length,
              itemBuilder: (context, index) => _buildInviteCard(invites[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildInviteCard(BattleInvite invite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.sports_kabaddi)),
        title: Text('${invite.fromUserName}さんからの対戦招待'),
        subtitle: Text('難易度: ${invite.difficulty}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _respondToInvite(invite.id, true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _respondToInvite(invite.id, false),
            ),
          ],
        ),
      ),
    );
  }

  void _respondToInvite(String inviteId, bool accept) async {
    final notifier = ref.read(friendScreenProvider.notifier);
    await notifier.respondToBattleInvite(inviteId, accept);
    ref.invalidate(pendingBattleInvitesProvider(widget.userId));
    _showSnackBarFromState();
  }

  // -----------------------------------------------------------------
  // 検索タブ
  // -----------------------------------------------------------------

  Widget _buildSearchTab() {
    return Consumer(
      builder: (context, ref, child) {
        final screenState = ref.watch(friendScreenProvider);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ユーザー名で検索',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) {
                  ref.read(friendScreenProvider.notifier).setSearchQuery(value);
                },
              ),
            ),
            Expanded(
              child: screenState.searchQuery.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.person_search,
                      message: 'ユーザー名を入力して検索してください',
                    )
                  : Consumer(
                      builder: (context, ref, child) {
                        final resultsAsync = ref.watch(userSearchProvider(screenState.searchQuery));

                        return resultsAsync.when(
                          data: (results) {
                            if (results.isEmpty) {
                              return _buildEmptyState(
                                icon: Icons.search_off,
                                message: '該当するユーザーが見つかりませんでした',
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: results.length,
                              itemBuilder: (context, index) =>
                                  _buildSearchResultCard(results[index]),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('エラー: $error')),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultCard(GameOpponent opponent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(opponent.displayName[0])),
        title: Text(opponent.displayName),
        subtitle: Text('${opponent.rank} · 勝率${(opponent.winRate * 100).toStringAsFixed(0)}%'),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(opponent),
          child: const Text('申請'),
        ),
      ),
    );
  }

  void _sendFriendRequest(GameOpponent opponent) async {
    final notifier = ref.read(friendScreenProvider.notifier);
    await notifier.sendFriendRequest(
      fromUserId: widget.userId,
      fromUserName: widget.userName,
      toUserId: opponent.userId,
      toUserName: opponent.displayName,
    );
    _showSnackBarFromState();
  }

  // -----------------------------------------------------------------
  // ダイアログ・共通UI
  // -----------------------------------------------------------------

  void _showBattleInviteDialog(Friendship friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${friend.friendName}さんを対戦に招待'),
        content: const Text('中級難易度で対戦を招待します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(friendScreenProvider.notifier);
              await notifier.sendBattleInvite(
                fromUserId: widget.userId,
                fromUserName: widget.userName,
                toUserId: friend.friendId,
                toUserName: friend.friendName,
              );
              _showSnackBarFromState();
            },
            child: const Text('招待する'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(Friendship friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${friend.friendName}さんをフレンド解除'),
        content: const Text('本当にフレンドを解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(friendScreenProvider.notifier);
              await notifier.removeFriend(widget.userId, friend.friendId);
              ref.invalidate(friendsListProvider(widget.userId));
              _showSnackBarFromState();
            },
            child: const Text('解除する'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnackBarFromState() {
    final state = ref.read(friendScreenProvider);
    final message = state.successMessage ?? state.errorMessage;
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(friendScreenProvider.notifier).clearSuccess();
      ref.read(friendScreenProvider.notifier).clearError();
    }
  }
}
