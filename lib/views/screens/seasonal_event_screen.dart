/// Seasonal Event Screen
/// シーズナルイベント・バトルパス画面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/seasonal_event.dart';
import 'package:rambu_shogi/viewmodels/seasonal_event_provider.dart';

/// シーズナルイベント スクリーン
class SeasonalEventScreen extends ConsumerStatefulWidget {
  final String userId;

  const SeasonalEventScreen({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SeasonalEventScreen> createState() => _SeasonalEventScreenState();
}

class _SeasonalEventScreenState extends ConsumerState<SeasonalEventScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('シーズナルイベント'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'バトルパス'),
            Tab(text: 'チャレンジ'),
            Tab(text: '報酬'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBattlePassTab(),
          _buildChallengeTab(),
          _buildRewardTab(),
        ],
      ),
    );
  }

  /// バトルパス タブ
  Widget _buildBattlePassTab() {
    return Consumer(
      builder: (context, ref, child) {
        final currentSeasonAsync = ref.watch(currentSeasonProvider);
        final userBattlePassAsync = ref.watch(userBattlePassProvider((widget.userId, 'season_001')));

        return currentSeasonAsync.when(
          data: (season) {
            if (season == null) {
              return const Center(child: Text('シーズンが見つかりません'));
            }

            return userBattlePassAsync.when(
              data: (userBP) {
                if (userBP == null) {
                  return Center(
                    child: Text('バトルパスデータが見つかりません'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // シーズン情報
                      _buildSeasonCard(season),
                      const SizedBox(height: 24),

                      // バトルパス進捗
                      Text(
                        'バトルパス進捗',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildBattlePassProgressCard(userBP),
                      const SizedBox(height: 24),

                      // 購入状態
                      if (!userBP.isPurchased)
                        _buildPurchaseButton()
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700]),
                              const SizedBox(width: 12),
                              Text(
                                'プレミアムバトルパス購入済み',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // バトルパス詳細説明
                      _buildBattlePassInfo(),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('エラー: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('エラー: $err')),
        );
      },
    );
  }

  /// チャレンジ タブ
  Widget _buildChallengeTab() {
    return Consumer(
      builder: (context, ref, child) {
        final challengesAsync = ref.watch(seasonalChallengesProvider('season_001'));
        final userChallengesAsync =
            ref.watch(userSeasonalChallengesProvider((widget.userId, 'season_001')));
        final screenState = ref.watch(seasonalEventScreenProvider);

        return challengesAsync.when(
          data: (challenges) {
            return userChallengesAsync.when(
              data: (userChallenges) {
                // フィルター適用
                final filtered = screenState.difficultyFilter == null
                    ? challenges
                    : challenges.where((c) => c.difficulty == screenState.difficultyFilter).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 難易度フィルター
                      Text(
                        'チャレンジ一覧',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildDifficultyFilter(ref),
                      const SizedBox(height: 16),

                      // チャレンジリスト
                      if (filtered.isEmpty)
                        const Center(child: Text('チャレンジがありません'))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final challenge = filtered[index];
                            final userChallenge = userChallenges.firstWhere(
                              (uc) => uc.challengeId == challenge.id,
                              orElse: () => UserSeasonalChallenge(
                                userId: widget.userId,
                                challengeId: challenge.id,
                                seasonId: 'season_001',
                              ),
                            );

                            return _buildChallengeCard(challenge, userChallenge, ref);
                          },
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('エラー: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('エラー: $err')),
        );
      },
    );
  }

  /// 報酬 タブ
  Widget _buildRewardTab() {
    return Consumer(
      builder: (context, ref, child) {
        final userBattlePassAsync = ref.watch(userBattlePassProvider((widget.userId, 'season_001')));
        final rewardsAsync = ref.watch(battlePassRewardsProvider('bp_001'));

        return userBattlePassAsync.when(
          data: (userBP) {
            if (userBP == null) {
              return const Center(child: Text('バトルパスデータが見つかりません'));
            }

            return rewardsAsync.when(
              data: (rewards) {
                // レベル順でソート
                final sortedRewards = [...rewards]..sort((a, b) => a.level.compareTo(b.level));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'バトルパス報酬',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '現在のレベル: ${userBP.currentLevel}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // 報酬リスト
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedRewards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final reward = sortedRewards[index];
                          final isUnlocked = userBP.currentLevel >= reward.level;
                          final isClaimed = userBP.claimedRewards.contains(reward.id);
                          final isFreeTier = reward.isFreeTierAvailable;

                          return _buildRewardCard(
                            reward,
                            isUnlocked: isUnlocked,
                            isClaimed: isClaimed,
                            isFreeTier: isFreeTier,
                            onClaim: () => _claimReward(ref, userBP, reward),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('エラー: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('エラー: $err')),
        );
      },
    );
  }

  /// シーズン情報カード
  Widget _buildSeasonCard(Season season) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(int.parse(season.themeColor)), Colors.black12],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        season.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    season.status.toString().split('.').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'シーズン ${season.seasonNumber}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// バトルパス進捗カード
  Widget _buildBattlePassProgressCard(UserBattlePass userBP) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'レベル ${userBP.currentLevel}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userBP.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'マックスレベル達成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 進捗バー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: userBP.levelProgressPercent / 100,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userBP.currentProgress} / ${userBP.progressPerLevel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 獲得報酬数
            Text(
              '獲得報酬: ${userBP.claimedRewards.length}件',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// 購入ボタン
  Widget _buildPurchaseButton() {
    return Consumer(
      builder: (context, ref, child) {
        final notifier = ref.read(seasonalEventScreenProvider.notifier);

        return ElevatedButton(
          onPressed: () => _purchaseBattlePass(ref, notifier),
          child: const Text('プレミアムバトルパスを購入（¥999）'),
        );
      },
    );
  }

  /// バトルパス情報
  Widget _buildBattlePassInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'バトルパスについて',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          '• フリーバトルパス: 基本報酬のみ取得可能\n'
          '• プレミアムバトルパス: すべての報酬を取得可能\n'
          '• レベルアップでポイント報酬を獲得\n'
          '• チャレンジ完了でバトルパス進捗増加',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  /// 難易度フィルター
  Widget _buildDifficultyFilter(WidgetRef ref) {
    final notifier = ref.read(seasonalEventScreenProvider.notifier);
    final screenState = ref.watch(seasonalEventScreenProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: screenState.difficultyFilter == null,
            onSelected: (selected) {
              if (selected) {
                notifier.setChallengeDifficultyFilter(null);
              }
            },
          ),
          const SizedBox(width: 8),
          ...List.generate(5, (i) {
            final difficulty = i + 1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('★' * difficulty),
                selected: screenState.difficultyFilter == difficulty,
                onSelected: (selected) {
                  if (selected) {
                    notifier.setChallengeDifficultyFilter(difficulty);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// チャレンジカード
  Widget _buildChallengeCard(
    SeasonalChallenge challenge,
    UserSeasonalChallenge userChallenge,
    WidgetRef ref,
  ) {
    final progressPercent = userChallenge.isCompleted
        ? 100.0
        : (userChallenge.currentProgress / challenge.requiredProgress) * 100;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '★' * challenge.difficulty,
                      style: const TextStyle(color: Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${challenge.rewardPoints}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 進捗バー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userChallenge.currentProgress} / ${challenge.requiredProgress}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 完了・報酬ボタン
            if (userChallenge.isCompleted && !userChallenge.rewardClaimed)
              ElevatedButton(
                onPressed: () => _claimChallengeReward(ref, userChallenge),
                child: const Text('報酬を獲得'),
              )
            else if (userChallenge.isCompleted && userChallenge.rewardClaimed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '報酬獲得済み',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 報酬カード
  Widget _buildRewardCard(
    BattlePassReward reward, {
    required bool isUnlocked,
    required bool isClaimed,
    required bool isFreeTier,
    required VoidCallback onClaim,
  }) {
    return Card(
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? null : Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.blue[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  reward.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lv.${reward.level}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isFreeTier ? Colors.lightGreen[200] : Colors.purple[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isFreeTier ? 'FREE' : 'PREMIUM',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isUnlocked && !isClaimed)
              ElevatedButton(
                onPressed: onClaim,
                child: const Text('獲得'),
              )
            else if (isClaimed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '✓',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ロック',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// バトルパス購入処理
  Future<void> _purchaseBattlePass(WidgetRef ref, SeasonalEventScreenNotifier notifier) async {
    try {
      await notifier.purchaseBattlePass(widget.userId, 'season_001', 'bp_001');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プレミアムバトルパスを購入しました！')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('購入に失敗しました: $e')),
      );
    }
  }

  /// 報酬クレーム処理
  Future<void> _claimReward(WidgetRef ref, UserBattlePass userBP, BattlePassReward reward) async {
    final notifier = ref.read(seasonalEventScreenProvider.notifier);
    try {
      await notifier.claimReward(widget.userId, 'season_001', reward.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('報酬を獲得しました！')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('報酬の獲得に失敗しました: $e')),
      );
    }
  }

  /// チャレンジ報酬クレーム処理
  Future<void> _claimChallengeReward(WidgetRef ref, UserSeasonalChallenge userChallenge) async {
    final notifier = ref.read(seasonalEventScreenProvider.notifier);
    try {
      await notifier.claimChallengeReward(
        widget.userId,
        userChallenge.challengeId,
        userChallenge.seasonId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チャレンジ報酬を獲得しました！')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('報酬の獲得に失敗しました: $e')),
      );
    }
  }
}
