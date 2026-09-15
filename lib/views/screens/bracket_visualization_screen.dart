/// Bracket Visualization Screen
/// トーナメントブラケット・ビジュアルアイゼーション・スペクテーター機能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/tournament.dart';
import 'package:rambu_shogi/viewmodels/tournament_provider.dart';

/// ブラケット ビジュアライゼーション スクリーン
class BracketVisualizationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String userId;
  final bool isSpectator;

  const BracketVisualizationScreen({
    required this.tournamentId,
    required this.userId,
    this.isSpectator = false,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BracketVisualizationScreen> createState() => _BracketVisualizationScreenState();
}

class _BracketVisualizationScreenState extends ConsumerState<BracketVisualizationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _selectedRound = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トーナメントブラケット'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ブラケット'),
            Tab(text: 'スタンディング'),
            Tab(text: '統計'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBracketTab(),
          _buildStandingsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  /// ブラケット タブ
  Widget _buildBracketTab() {
    return Consumer(
      builder: (context, ref, child) {
        final matchesAsync = ref.watch(tournamentMatchesProvider(widget.tournamentId));

        return matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return const Center(child: Text('マッチが見つかりません'));
            }

            // ラウンドを抽出
            final rounds = matches.map((m) => m.round).toSet().toList()..sort();

            return Column(
              children: [
                // ラウンド セレクター
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int round in rounds)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('ラウンド $round'),
                              selected: _selectedRound == round,
                              onSelected: (selected) {
                                setState(() => _selectedRound = round);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ブラケット表示
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: _buildBracketTree(matches, _selectedRound),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('エラー: $err')),
        );
      },
    );
  }

  /// スタンディング タブ
  Widget _buildStandingsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final participantsAsync =
            ref.watch(tournamentParticipantsProvider(widget.tournamentId));
        final matchesAsync = ref.watch(tournamentMatchesProvider(widget.tournamentId));

        return participantsAsync.when(
          data: (participants) {
            return matchesAsync.when(
              data: (matches) {
                // 各参加者の勝数を計算
                final playerWins = <String, int>{};
                for (final match in matches.where((m) => m.status == MatchStatus.completed)) {
                  if (match.winnerId != null) {
                    playerWins[match.winnerId!] = (playerWins[match.winnerId!] ?? 0) + 1;
                  }
                }

                // 勝数でソート
                final sorted = [...participants]
                  ..sort((a, b) {
                    final aWins = playerWins[a.userId] ?? 0;
                    final bWins = playerWins[b.userId] ?? 0;
                    return bWins.compareTo(aWins);
                  });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'トーナメント順位',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        sorted.length,
                        (index) {
                          final participant = sorted[index];
                          final wins = playerWins[participant.userId] ?? 0;
                          final isCurrentUser = participant.userId == widget.userId;

                          return Card(
                            color: isCurrentUser ? Colors.blue[50] : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // 順位
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getMedalColor(index),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // プレイヤー情報
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                participant.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[200],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'あなた',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'レート: ${participant.rating}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 勝数
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$wins勝',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'シード: ${participant.seed}',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

  /// 統計 タブ
  Widget _buildStatsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(tournamentStatsProvider(widget.tournamentId));

        return statsAsync.when(
          data: (stats) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'トーナメント統計',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // 統計カード
                  _buildStatCard('参加者数', '${stats.totalParticipants}'),
                  const SizedBox(height: 12),
                  _buildStatCard('完了マッチ', '${stats.completedMatches}'),
                  const SizedBox(height: 12),
                  _buildStatCard('予定マッチ', '${stats.scheduledMatches}'),
                  const SizedBox(height: 12),

                  // 進捗
                  const SizedBox(height: 16),
                  Text(
                    'トーナメント進捗',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(
                    'マッチ完了率',
                    stats.completedMatches,
                    stats.completedMatches + stats.scheduledMatches,
                  ),
                  const SizedBox(height: 12),

                  // 統計詳細
                  const SizedBox(height: 16),
                  Text(
                    '統計詳細',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(
                            '最高シード優勝',
                            stats.highestSeedWon.toString(),
                          ),
                          const Divider(),
                          _buildStatRow(
                            '最低シード進出',
                            stats.lowestSeedWon.toString(),
                          ),
                          const Divider(),
                          _buildStatRow(
                            '無敗プレイヤー数',
                            stats.undefeatedCount.toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('エラー: $err')),
        );
      },
    );
  }

  /// ブラケット ツリー（SVG ベース）
  Widget _buildBracketTree(List<TournamentMatch> allMatches, int round) {
    final roundMatches = allMatches.where((m) => m.round == round).toList()
      ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roundMatches.map((match) => _buildMatchBracket(match)).toList(),
    );
  }

  /// マッチ ブラケット（個別）
  Widget _buildMatchBracket(TournamentMatch match) {
    final isCompleted = match.status == MatchStatus.completed;
    final player1Won = match.winnerId == match.player1Id;
    final player2Won = match.winnerId == match.player2Id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'マッチ ${match.matchNumber}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),

            // プレイヤー1
            _buildBracketPlayer(
              match.player1Name,
              match.player1Seed,
              match.player1Score,
              isWinner: player1Won && isCompleted,
              isHighlighted: match.winnerId == match.player1Id,
            ),
            const SizedBox(height: 4),

            // VS
            const Center(
              child: Text('VS', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 4),

            // プレイヤー2
            if (match.player2Id != null)
              _buildBracketPlayer(
                match.player2Name ?? 'TBD',
                match.player2Seed,
                match.player2Score,
                isWinner: player2Won && isCompleted,
                isHighlighted: match.winnerId == match.player2Id,
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TBD (不戦勝)',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

            if (isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '結果: ${match.player1Name} ${match.player1Score} - ${match.player2Score} ${match.player2Name ?? ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ブラケット プレイヤー情報
  Widget _buildBracketPlayer(
    String name,
    int? seed,
    int score, {
    required bool isWinner,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlighted ? Colors.green[500]! : Colors.grey[300]!,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (seed != null)
                  Text(
                    'シード: $seed',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.green[200] : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$score',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 統計 カード
  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// プログレス バー
  Widget _buildProgressBar(String label, int current, int total) {
    final percentage = total == 0 ? 0.0 : current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(percentage * 100).toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  /// 統計 行
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// メダル色を取得
  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[600]!; // Gold
      case 1:
        return Colors.grey[400]!; // Silver
      case 2:
        return Colors.orange[600]!; // Bronze
      default:
        return Colors.blue[400]!; // Other
    }
  }
}
