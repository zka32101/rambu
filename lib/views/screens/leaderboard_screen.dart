/// Leaderboard Screen
/// ランキング表示・対戦相手検索画面
///
/// 機能:
/// - 複数カテゴリーのランキング表示
/// - ユーザーランクの検索
/// - 対戦相手（レディース）検索
/// - ユーザープロフィール表示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/user_profile.dart';
import 'package:rambu_shogi/viewmodels/leaderboard_provider.dart';

/// ランキング スクリーン
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(leaderboardScreenProvider);
    final selectedCategory = screenState.selectedCategory;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ランキング'),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'ランキング'),
              Tab(text: 'レディース'),
            ],
            labelColor: Colors.amber[700],
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.amber[700],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeaderboardTab(context, ref, selectedCategory),
            _buildReediesTab(context, ref),
          ],
        ),
      ),
    );
  }

  /// ランキング タブ
  Widget _buildLeaderboardTab(
    BuildContext context,
    WidgetRef ref,
    LeaderboardCategory selectedCategory,
  ) {
    return Column(
      children: [
        // カテゴリー選択
        _buildCategorySelector(context, ref, selectedCategory),

        // ランキングリスト
        Expanded(
          child: _buildLeaderboardList(context, ref, selectedCategory),
        ),
      ],
    );
  }

  /// カテゴリー セレクター
  Widget _buildCategorySelector(
    BuildContext context,
    WidgetRef ref,
    LeaderboardCategory selectedCategory,
  ) {
    final categories = [
      (LeaderboardCategory.overall, '総合'),
      (LeaderboardCategory.winRate, '勝率'),
      (LeaderboardCategory.level, 'レベル'),
      (LeaderboardCategory.playTime, 'プレイ時間'),
      (LeaderboardCategory.achievements, '実績'),
      (LeaderboardCategory.criticalHits, 'クリティカル'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[850],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map((category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FilterChip(
                      label: Text(category.$2),
                      selected: selectedCategory == category.$1,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(leaderboardScreenProvider.notifier).selectCategory(category.$1);
                        }
                      },
                      backgroundColor: Colors.grey[700],
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: selectedCategory == category.$1 ? Colors.black : Colors.white70,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// ランキング リスト
  Widget _buildLeaderboardList(
    BuildContext context,
    WidgetRef ref,
    LeaderboardCategory selectedCategory,
  ) {
    final leaderboardAsync = ref.watch(selectedLeaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('エラー: $err'),
      ),
      data: (leaderboard) {
        if (leaderboard.isEmpty) {
          return const Center(
            child: Text('ランキングデータはまだありません'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(selectedLeaderboardProvider.future);
          },
          child: ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return _buildLeaderboardEntry(context, ref, entry);
            },
          ),
        );
      },
    );
  }

  /// ランキング エントリー タイル
  Widget _buildLeaderboardEntry(
    BuildContext context,
    WidgetRef ref,
    LeaderboardEntry entry,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRankBorderColor(entry.rank),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(entry.rank),
          child: Text(
            '${entry.rank}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry.userProfile.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.userProfile.rank,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '対局数: ${entry.userProfile.totalGames}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score.toStringAsFixed(1)}',
              style: TextStyle(
                color: Colors.amber[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (entry.rankChange != null)
              Text(
                entry.rankChange! > 0 ? '↑${entry.rankChange}' : '↓${entry.rankChange!.abs()}',
                style: TextStyle(
                  color: entry.rankChange! > 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        onTap: () {
          _showUserProfile(context, ref, entry.userProfile);
        },
      ),
    );
  }

  /// ランク色を取得
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.orange[700]!;
    return Colors.purple[600]!;
  }

  /// ランク枠色を取得
  Color _getRankBorderColor(int rank) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.grey[300]!;
    if (rank == 3) return Colors.orange[600]!;
    return Colors.purple[500]!;
  }

  /// レディース（対戦相手検索）タブ
  Widget _buildReediesTab(BuildContext context, WidgetRef ref) {
    final screenNotifier = ref.read(leaderboardScreenProvider.notifier);

    return Column(
      children: [
        // フィルター
        _buildOpponentFilter(context, ref, screenNotifier),

        // 対戦相手リスト
        Expanded(
          child: _buildOpponentsList(context, ref),
        ),
      ],
    );
  }

  /// 対戦相手 フィルター
  Widget _buildOpponentFilter(
    BuildContext context,
    WidgetRef ref,
    LeaderboardScreenNotifier screenNotifier,
  ) {
    final ranks = ['全て', '初級', '中級', '上級'];

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[850],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '段位フィルター',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          DropdownButton<String>(
            value: '全て',
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: ranks
                .map((rank) => DropdownMenuItem(
                      value: rank,
                      child: Text(rank),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null && value != '全て') {
                screenNotifier.updateOpponentFilter(rankFilter: value);
              }
            },
          ),
        ],
      ),
    );
  }

  /// 対戦相手 リスト
  Widget _buildOpponentsList(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(leaderboardScreenProvider);
    final opponentsAsync = ref.watch(gameOpponentsProvider(screenState.opponentFilter));

    return opponentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('エラー: $err'),
      ),
      data: (opponents) {
        if (opponents.isEmpty) {
          return const Center(
            child: Text('対戦可能なプレイヤーがいません'),
          );
        }

        return ListView.builder(
          itemCount: opponents.length,
          itemBuilder: (context, index) {
            final opponent = opponents[index];
            return _buildOpponentTile(context, opponent);
          },
        );
      },
    );
  }

  /// 対戦相手 タイル
  Widget _buildOpponentTile(BuildContext context, GameOpponent opponent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: opponent.isOnline ? Colors.green : Colors.grey[600]!,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundImage: opponent.profileImageUrl != null
                  ? NetworkImage(opponent.profileImageUrl!)
                  : null,
              backgroundColor: Colors.purple[700],
              child: opponent.profileImageUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            if (opponent.isOnline)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
          ],
        ),
        title: Text(
          opponent.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                opponent.rank,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '勝率: ${(opponent.winRate * 100).toStringAsFixed(1)}% (${opponent.totalGames}局)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // 対戦申請機能（Phase 6B で実装）
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('対戦申請機能は近日実装予定です')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
          ),
          child: const Text(
            '挑戦',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          _showOpponentProfile(context, opponent);
        },
      ),
    );
  }

  /// ユーザー プロフィール ダイアログ
  void _showUserProfile(BuildContext context, WidgetRef ref, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile.displayName),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.white70),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('段位: ${profile.rank}'),
              Text('レベル: ${profile.level}'),
              Text('対局数: ${profile.totalGames}'),
              Text('勝利数: ${profile.wins}'),
              Text('敗北数: ${profile.losses}'),
              Text('勝率: ${(profile.winRate * 100).toStringAsFixed(1)}%'),
              Text('ELOレート: ${profile.ratingScore.toStringAsFixed(0)}'),
              Text('最大連勝: ${profile.maxWinStreak}'),
              Text('総プレイ時間: ${(profile.totalPlayTimeSeconds / 3600).toStringAsFixed(1)}時間'),
              Text('獲得実績: ${profile.achievementCount}'),
              Text('クリティカルヒット: ${profile.totalCriticalHits}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  /// 対戦相手 プロフィール ダイアログ
  void _showOpponentProfile(BuildContext context, GameOpponent opponent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(opponent.displayName),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.white70),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('段位: ${opponent.rank}'),
              Text('対局数: ${opponent.totalGames}'),
              Text('勝率: ${(opponent.winRate * 100).toStringAsFixed(1)}%'),
              Text('ステータス: ${opponent.isOnline ? 'オンライン' : 'オフライン'}'),
              if (opponent.lastPlayedAt != null)
                Text('最終プレイ: ${opponent.lastPlayedAt}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('対戦申請を送信しました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
            ),
            child: const Text(
              '対戦申請',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
