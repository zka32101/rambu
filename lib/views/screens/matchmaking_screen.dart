/// Matchmaking Screen
/// レーティングベース自動マッチング（対戦相手を探す）

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/matchmaking.dart';
import 'package:rambu_shogi/viewmodels/matchmaking_provider.dart';

/// マッチメイキング スクリーン
class MatchmakingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final double userRating;

  const MatchmakingScreen({
    required this.userId,
    required this.userName,
    required this.userRating,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  double _ratingRange = 200;
  bool _matchDialogShown = false;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer(DateTime startedAt) {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(startedAt));
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    setState(() => _elapsed = Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    final screenState = ref.watch(matchmakingScreenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('対戦相手を探す')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('あなたのレーティング', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      widget.userRating.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!screenState.isSearching) ...[
              Text('マッチング範囲', style: Theme.of(context).textTheme.labelMedium),
              Slider(
                value: _ratingRange,
                min: 50,
                max: 500,
                divisions: 9,
                label: '±${_ratingRange.toStringAsFixed(0)}',
                onChanged: (value) => setState(() => _ratingRange = value),
              ),
              Text('±${_ratingRange.toStringAsFixed(0)} の相手とマッチングします'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('対戦相手を探す'),
                onPressed: _startSearch,
              ),
            ] else
              _buildSearchingState(screenState),
            if (screenState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                screenState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingState(MatchmakingScreenState screenState) {
    final entryId = screenState.currentEntryId;
    if (entryId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer(
      builder: (context, ref, child) {
        final entryAsync = ref.watch(matchmakingQueueStreamProvider(entryId));

        return entryAsync.when(
          data: (entry) {
            if (entry != null && entry.status == MatchmakingStatus.matched) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _onMatchFound(entry));
            }

            return Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('対戦相手を検索中... ${_formatElapsed(_elapsed)}'),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _cancelSearch,
                  child: const Text('検索をやめる'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('エラー: $error'),
        );
      },
    );
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startSearch() async {
    final notifier = ref.read(matchmakingScreenProvider.notifier);
    await notifier.startSearching(
      userId: widget.userId,
      userName: widget.userName,
      rating: widget.userRating,
      ratingRange: _ratingRange,
    );
    _startElapsedTimer(DateTime.now());
  }

  void _cancelSearch() async {
    final notifier = ref.read(matchmakingScreenProvider.notifier);
    await notifier.cancelSearching();
    _stopElapsedTimer();
  }

  void _onMatchFound(MatchmakingEntry entry) async {
    if (_matchDialogShown || !mounted || entry.matchId == null) return;
    _matchDialogShown = true;
    _stopElapsedTimer();
    ref.read(matchmakingScreenProvider.notifier).onMatchFound();

    final match = await ref.read(matchmakingMatchProvider(entry.matchId!).future);
    final opponentName = match?.opponentNameFor(widget.userId) ?? '対戦相手';

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('対戦相手が見つかりました！'),
        content: Text('$opponentNameさんとマッチしました'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, entry.matchId);
            },
            child: const Text('対局を開始'),
          ),
        ],
      ),
    );
  }
}
