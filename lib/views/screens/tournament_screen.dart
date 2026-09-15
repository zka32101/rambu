/// Tournament Screen
/// トーナメント発見・参加・ブラケット表示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/tournament.dart';
import 'package:rambu_shogi/viewmodels/tournament_provider.dart';

/// トーナメント スクリーン
class TournamentScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final int userRating;

  const TournamentScreen({
    required this.userId,
    required this.userName,
    required this.userRating,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> with TickerProviderStateMixin {
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
        title: const Text('トーナメント'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '発見'),
            Tab(text: '参加中'),
            Tab(text: 'ブラケット'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoveryTab(),
          _buildMyTournamentsTab(),
          _buildBracketTab(),
        ],
      ),
    );
  }

  /// 発見 タブ
  Widget _buildDiscoveryTab() {
    return Consumer(
      builder: (context, ref, child) {
        final recommendedAsync = ref.watch(recommendedTournamentsProvider(widget.userRating));
        final screenState = ref.watch(tournamentScreenProvider);

        return recommendedAsync.when(
          data: (tournaments) {
            // フォーマットフィルター適用
            final filtered = screenState.selectedFormat == null
                ? tournaments
                : tournaments.where((t) => t.format == screenState.selectedFormat).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // フィルター
                  _buildFormatFilter(ref),
                  const SizedBox(height: 16),

                  // トーナメント一覧
                  Text(
                    '推奨トーナメント (${filtered.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'あなたのレーティングに合うトーナメントがありません',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tournament = filtered[index];
                        return _buildTournamentCard(tournament);
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
    );
  }

  /// 参加中 タブ
  Widget _buildMyTournamentsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final tournamentsAsync = ref.watch(registrationTournamentsProvider);

        return tournamentsAsync.when(
          data: (tournaments) {
            // ここでは仮実装として、すべての登録受付中トーナメントを表示
            // 本実装では、ユーザーが登録しているトーナメントを抽出する必要がある
            final myTournaments =
                tournaments.where((t) => t.status == TournamentStatus.active).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '参加中のトーナメント',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  if (myTournaments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Text(
                              '参加中のトーナメントがありません',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _tabController.animateTo(0),
                              child: const Text('トーナメントを探す'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myTournaments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tournament = myTournaments[index];
                        return _buildMyTournamentCard(tournament);
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
    );
  }

  /// ブラケット タブ
  Widget _buildBracketTab() {
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'トーナメントブラケット',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // トーナメント選択
              _buildTournamentSelector(ref),
              const SizedBox(height: 16),

              // ブラケット表示
              _buildBracketVisualization(),
            ],
          ),
        );
      },
    );
  }

  /// トーナメント カード
  Widget _buildTournamentCard(Tournament tournament) {
    final isFull = tournament.currentParticipants >= tournament.maxParticipants;
    final spotsLeft = tournament.maxParticipants - tournament.currentParticipants;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTournamentDetails(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.red[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFull ? '満員' : '$spotsLeft空き',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // トーナメント情報
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '形式',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          _formatName(tournament.format),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '参加者',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${tournament.currentParticipants}/${tournament.maxParticipants}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '賞金',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '¥${tournament.prizePool}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 登録進捗
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tournament.currentParticipants / tournament.maxParticipants,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),

              // 登録ボタン
              if (!isFull)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _registerForTournament(tournament),
                    child: const Text('トーナメントに登録'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// マイトーナメント カード
  Widget _buildMyTournamentCard(Tournament tournament) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTournamentDetails(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusName(tournament.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '参加者',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${tournament.currentParticipants}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '賞金',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '¥${tournament.prizePool}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'BO',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${tournament.bestOf}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // アクションボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _checkInTournament(tournament),
                      child: const Text('チェックイン'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showTournamentDetails(tournament),
                      child: const Text('詳細'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// フォーマット フィルター
  Widget _buildFormatFilter(WidgetRef ref) {
    final notifier = ref.read(tournamentScreenProvider.notifier);
    final screenState = ref.watch(tournamentScreenProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: screenState.selectedFormat == null,
            onSelected: (selected) {
              if (selected) {
                notifier.setTournamentFormat(null);
              }
            },
          ),
          const SizedBox(width: 8),
          ...TournamentFormat.values.map(
            (format) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_formatName(format)),
                selected: screenState.selectedFormat == format,
                onSelected: (selected) {
                  if (selected) {
                    notifier.setTournamentFormat(format);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// トーナメント セレクター
  Widget _buildTournamentSelector(WidgetRef ref) {
    final tournamentsAsync = ref.watch(allTournamentsProvider);

    return tournamentsAsync.when(
      data: (tournaments) {
        final activeTournaments = tournaments.where((t) => t.status == TournamentStatus.active).toList();

        if (activeTournaments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '開催中のトーナメントがありません',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: activeTournaments.map((tournament) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text(tournament.name),
                  subtitle: Text('${tournament.currentParticipants} 参加者'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _showBracketDetails(tournament),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('エラー: $err'),
    );
  }

  /// ブラケット ビジュアライゼーション
  Widget _buildBracketVisualization() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // シンプルな予選ブラケット表示
          const Text('シングルエリミネーション'),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text('ブラケット表示'),
            ),
          ),
        ],
      ),
    );
  }

  /// トーナメント詳細を表示
  void _showTournamentDetails(Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tournament.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('説明: ${tournament.description}'),
              const SizedBox(height: 8),
              Text('形式: ${_formatName(tournament.format)}'),
              const SizedBox(height: 8),
              Text('参加者: ${tournament.currentParticipants}/${tournament.maxParticipants}'),
              const SizedBox(height: 8),
              Text('賞金: ¥${tournament.prizePool}'),
              const SizedBox(height: 8),
              Text('開始: ${tournament.startDate}'),
              const SizedBox(height: 8),
              Text('レーティング: ${tournament.minRating} - ${tournament.maxRating}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// ブラケット詳細を表示
  void _showBracketDetails(Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tournament.name} - ブラケット'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('トーナメント: ${tournament.name}'),
              const SizedBox(height: 8),
              Text('ステータス: ${_statusName(tournament.status)}'),
              const SizedBox(height: 8),
              Text('参加者: ${tournament.currentParticipants}'),
              const SizedBox(height: 16),
              const Text('ブラケット詳細は実装予定'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// トーナメント登録処理
  void _registerForTournament(Tournament tournament) {
    final notifier = ref.read(tournamentScreenProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('トーナメントに登録'),
        content: Text('${tournament.name}に登録しますか？\n参加費: ${tournament.entryFee}ポイント'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.registerForTournament(
                tournament.id,
                widget.userId,
                widget.userName,
                widget.userRating,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('トーナメントに登録しました')),
              );
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  /// チェックイン処理
  void _checkInTournament(Tournament tournament) {
    final notifier = ref.read(tournamentScreenProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チェックイン'),
        content: Text('${tournament.name}にチェックインしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.checkInTournament(tournament.id, widget.userId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('チェックインしました')),
              );
            },
            child: const Text('チェックイン'),
          ),
        ],
      ),
    );
  }

  /// トーナメント形式名を取得
  String _formatName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return 'シングル';
      case TournamentFormat.doubleElimination:
        return 'ダブル';
      case TournamentFormat.roundRobin:
        return 'リーグ戦';
      case TournamentFormat.swiss:
        return 'スイス式';
    }
  }

  /// ステータス名を取得
  String _statusName(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return '予定中';
      case TournamentStatus.registration:
        return '参加受付中';
      case TournamentStatus.active:
        return '開催中';
      case TournamentStatus.completed:
        return '終了';
      case TournamentStatus.cancelled:
        return 'キャンセル';
    }
  }
}
