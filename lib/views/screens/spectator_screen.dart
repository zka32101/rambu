/// Spectator Screen
/// 観戦（ライブ配信中の対局一覧）・リプレイ共有・リプレイコメント

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/spectator.dart';
import 'package:rambu_shogi/services/firestore_service.dart';
import 'package:rambu_shogi/viewmodels/spectator_provider.dart';

/// 観戦・リプレイ共有 スクリーン
class SpectatorScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const SpectatorScreen({
    required this.userId,
    required this.userName,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('観戦・共有'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '観戦中の対局'),
            Tab(text: 'リプレイ共有'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBroadcastsTab(),
          _buildReplaySharingTab(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 観戦中の対局タブ
  // -----------------------------------------------------------------

  Widget _buildBroadcastsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final broadcastsAsync = ref.watch(activeBroadcastsProvider);

        return broadcastsAsync.when(
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.live_tv_outlined,
                message: '現在観戦できる対局はありません',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(activeBroadcastsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: broadcasts.length,
                itemBuilder: (context, index) => _buildBroadcastCard(broadcasts[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildBroadcastCard(LiveGameBroadcast broadcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.circle, color: Colors.white, size: 12),
        ),
        title: Text('${broadcast.hostUserName} vs ${broadcast.guestUserName}'),
        subtitle: Text(
          '${broadcast.currentMoveNumber}手目 · HP ${broadcast.hostTotalHP} - ${broadcast.guestTotalHP} '
          '· 観戦者${broadcast.viewerCount}人',
        ),
        trailing: ElevatedButton(
          onPressed: () => _openLiveView(broadcast),
          child: const Text('観戦する'),
        ),
      ),
    );
  }

  void _openLiveView(LiveGameBroadcast broadcast) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LiveBroadcastViewScreen(gameSessionId: broadcast.gameSessionId),
      ),
    );
  }

  // -----------------------------------------------------------------
  // リプレイ共有タブ
  // -----------------------------------------------------------------

  Widget _buildReplaySharingTab() {
    return Consumer(
      builder: (context, ref, child) {
        final recordsAsync = ref.watch(gameRecordsProvider);

        return recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return _buildEmptyState(
                icon: Icons.movie_outlined,
                message: 'まだ対局記録がありません',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) => _buildRecordShareCard(records[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
    );
  }

  Widget _buildRecordShareCard(GameRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.sports_kabaddi)),
        title: Text('${record.result.label} · ${record.aiDifficulty}'),
        subtitle: Text('${record.moves.length}手 · ${_formatDate(record.playedAt)}'),
        trailing: IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _showShareDialog(record),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  void _showShareDialog(GameRecord record) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final screenState = ref.watch(spectatorScreenProvider);

          return AlertDialog(
            title: const Text('リプレイを共有'),
            content: screenState.lastGeneratedToken == null
                ? const Text('この対局のリプレイ共有リンクを作成しますか？')
                : SelectableText('共有コード: ${screenState.lastGeneratedToken}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
              if (screenState.lastGeneratedToken == null)
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(spectatorScreenProvider.notifier).generateReplayShare(
                          gameRecordId: record.id,
                          ownerUserId: widget.userId,
                          ownerUserName: widget.userName,
                        );
                  },
                  child: const Text('リンクを作成'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // ダイアログを閉じたら状態をリセット
      ref.read(spectatorScreenProvider.notifier).clearSuccess();
    });
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/// ライブ対局観戦ビュー（要約情報のみリアルタイム表示・読み取り専用）
class _LiveBroadcastViewScreen extends ConsumerStatefulWidget {
  final String gameSessionId;

  const _LiveBroadcastViewScreen({required this.gameSessionId});

  @override
  ConsumerState<_LiveBroadcastViewScreen> createState() =>
      _LiveBroadcastViewScreenState();
}

class _LiveBroadcastViewScreenState extends ConsumerState<_LiveBroadcastViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spectatorServiceProvider).adjustViewerCount(widget.gameSessionId, 1);
    });
  }

  @override
  void dispose() {
    ref.read(spectatorServiceProvider).adjustViewerCount(widget.gameSessionId, -1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastAsync = ref.watch(liveBroadcastStreamProvider(widget.gameSessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('観戦中')),
      body: broadcastAsync.when(
        data: (broadcast) {
          if (broadcast == null || broadcast.isFinished) {
            return const Center(child: Text('この対局は終了しました'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${broadcast.hostUserName} vs ${broadcast.guestUserName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('${broadcast.currentMoveNumber}手目'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHPColumn(broadcast.hostUserName, broadcast.hostTotalHP),
                    const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildHPColumn(broadcast.guestUserName, broadcast.guestTotalHP),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 18),
                    const SizedBox(width: 4),
                    Text('観戦者 ${broadcast.viewerCount}人'),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildHPColumn(String name, int hp) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('HP $hp', style: const TextStyle(fontSize: 24)),
      ],
    );
  }
}
