/// 結果画面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/viewmodels/game_provider.dart';
import 'package:rambu_shogi/viewmodels/highlight_provider.dart';

class ResultScreen extends ConsumerWidget {
  final GameSession game;

  const ResultScreen({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = game.getGameDurationSeconds() ?? 0;
    final winner = game.winner;

    // ハイライト生成を自動開始（一度だけ）
    ref.listen(highlightGenerationProvider, (prev, next) {
      // 生成完了時のコールバック
      if (next.isComplete) {
        if (next.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ ハイライト動画が生成されました！'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    // マウント時にハイライト生成を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(highlightGenerationProvider);
      if (!state.isGenerating && state.result == null) {
        ref.read(highlightGenerationProvider.notifier).generateHighlight(game);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('対局結果'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 結果表示
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (winner == PlayerColor.sente)
                      const Text(
                        '🎉 先手勝利！',
                        style: TextStyle(
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      )
                    else
                      const Text(
                        '🎉 後手勝利！',
                        style: TextStyle(
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 12.0),
                    Text(
                      'おめでとうございます！',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ゲーム統計
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('ターン数', '${game.turnCount}手'),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      'ゲーム時間',
                      '${duration}秒',
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '難易度',
                      game.aiDifficulty.label,
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '先手HP',
                      game.getWhiteTotalHP().toStringAsFixed(1),
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '後手HP',
                      game.getBlackTotalHP().toStringAsFixed(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              // ハイライト生成の進捗表示
              Consumer(
                builder: (context, ref, child) {
                  final highlightState = ref.watch(highlightGenerationProvider);
                  final progressPercent =
                      ref.watch(highlightProgressPercentProvider);
                  final stepLabel = ref.watch(highlightStepLabelProvider);
                  final error = ref.watch(highlightErrorProvider);

                  if (highlightState.isGenerating) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    stepLabel,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$progressPercent%',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: LinearProgressIndicator(
                                value: progressPercent / 100.0,
                                minHeight: 6.0,
                                backgroundColor: Colors.blue.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.blue.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (error != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                error,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (highlightState.isSuccess) {
                    final elapsedTime = highlightState.elapsedTime;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✅ ハイライト動画が生成されました！',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (elapsedTime != null)
                                    Text(
                                      '生成時間: ${elapsedTime.inSeconds}秒',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),

              const SizedBox(height: 24.0),

              // ボタングループ
              Consumer(
                builder: (context, ref, child) {
                  final highlightState = ref.watch(highlightGenerationProvider);
                  final videoUrl = ref.watch(highlightVideoUrlProvider);
                  final shareUrl = ref.watch(highlightShareLinkProvider);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            onPressed: (videoUrl != null && !highlightState.isGenerating)
                                ? () {
                                    // TODO: ハイライト動画プレイヤーを開く
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                              'ハイライト動画プレイヤーは後で実装予定です')),
                                    );
                                  }
                                : null,
                            child: const Text('ハイライト動画を見る'),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              backgroundColor: Colors.grey.shade600,
                            ),
                            onPressed: (shareUrl != null && !highlightState.isGenerating)
                                ? () {
                                    // TODO: シェア機能実装
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('シェアリンク: $shareUrl'),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text('シェアする'),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            onPressed: () {
                              // ホームに戻る
                              Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                              );
                            },
                            child: const Text('ホームに戻る'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 統計行を表示
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
