/// Replay Screen
/// 対局記録の再生画面
///
/// 機能:
/// - ゲーム記録の再生・再現
/// - 再生制御（再生・一時停止・ステップ・シーク）
/// - 再生速度調整
/// - 手数情報・局面表示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/replay_engine.dart';

/// Replay Screen Provider
final replayScreenProvider =
    StateNotifierProvider<ReplayScreenNotifier, ReplayScreenState>((ref) {
  return ReplayScreenNotifier();
});

/// Replay Screen State
class ReplayScreenState {
  final GameRecord? gameRecord;
  final ReplayState? replayState;
  final bool isLoading;
  final String? errorMessage;

  ReplayScreenState({
    this.gameRecord,
    this.replayState,
    this.isLoading = false,
    this.errorMessage,
  });

  ReplayScreenState copyWith({
    GameRecord? gameRecord,
    ReplayState? replayState,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReplayScreenState(
      gameRecord: gameRecord ?? this.gameRecord,
      replayState: replayState ?? this.replayState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Replay Screen Notifier
class ReplayScreenNotifier extends StateNotifier<ReplayScreenState> {
  ReplayScreenNotifier() : super(ReplayScreenState());

  late ReplayEngine _replayEngine;

  /// ゲーム記録で再生を初期化
  void initializeReplay(GameRecord gameRecord) {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      _replayEngine = ReplayEngine();
      _replayEngine.initialize(gameRecord);

      state = state.copyWith(
        gameRecord: gameRecord,
        replayState: _replayEngine.currentState,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize replay: $e',
      );
    }
  }

  /// 再生開始
  void play() {
    try {
      _replayEngine.play();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Play failed: $e');
    }
  }

  /// 一時停止
  void pause() {
    try {
      _replayEngine.pause();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Pause failed: $e');
    }
  }

  /// 前の手に戻す
  void stepBackward() {
    try {
      _replayEngine.stepBackward();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Step backward failed: $e');
    }
  }

  /// 次の手に進める
  void stepForward() {
    try {
      _replayEngine.stepForward();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Step forward failed: $e');
    }
  }

  /// 指定した手数にジャンプ
  void jumpToMove(int moveIndex) {
    try {
      _replayEngine.jumpToMove(moveIndex);
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Jump failed: $e');
    }
  }

  /// 再生速度を変更
  void setPlaybackSpeed(double speed) {
    try {
      _replayEngine.setPlaybackSpeed(speed);
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Speed change failed: $e');
    }
  }

  /// リセット（開始位置に戻す）
  void reset() {
    try {
      _replayEngine.reset();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Reset failed: $e');
    }
  }

  /// 最後まで進める
  void jumpToEnd() {
    try {
      _replayEngine.jumpToEnd();
      state = state.copyWith(replayState: _replayEngine.currentState);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Jump to end failed: $e');
    }
  }
}

/// Replay Screen
class ReplayScreen extends ConsumerWidget {
  final GameRecord gameRecord;

  const ReplayScreen({
    required this.gameRecord,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(replayScreenProvider);
    final screenNotifier = ref.watch(replayScreenProvider.notifier);

    // 画面初期化
    ref.listen(replayScreenProvider, (previous, next) {
      if (screenState.gameRecord == null) {
        screenNotifier.initializeReplay(gameRecord);
      }
    });

    if (screenState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (screenState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Replay Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(screenState.errorMessage!),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (screenState.replayState == null) {
      return const Scaffold(
        body: Center(
          child: Text('Loading game record...'),
        ),
      );
    }

    final replayState = screenState.replayState!;
    final gameRecord = screenState.gameRecord!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ゲーム情報ヘッダー
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: _buildGameInfoHeader(gameRecord),
          ),

          // 盤面表示エリア（仮：テキスト表示）
          Expanded(
            child: Container(
              color: Colors.grey[850],
              child: _buildBoardArea(replayState),
            ),
          ),

          // 現在の手情報
          if (replayState.currentMove != null)
            Container(
              color: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildCurrentMoveInfo(replayState),
            ),

          // 再生制御
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: _buildPlaybackControls(context, ref, screenNotifier, replayState),
          ),

          // 手数スライダー
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildMoveSlider(screenNotifier, replayState),
          ),

          // 再生速度・統計情報
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: _buildSpeedAndStats(screenNotifier, replayState, gameRecord),
          ),
        ],
      ),
    );
  }

  /// ゲーム情報ヘッダー
  Widget _buildGameInfoHeader(GameRecord gameRecord) {
    final result = switch (gameRecord.result) {
      GameResult.whiteWon => '白勝',
      GameResult.blackWon => '黒勝',
      GameResult.draw => '中断',
      GameResult.aborted => '中止',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gameRecord.playerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '難易度: ${gameRecord.aiDifficulty} • 時間: ${(gameRecord.durationSeconds / 60).toStringAsFixed(1)}分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: result == '白勝'
                ? Colors.blue[700]
                : result == '黒勝'
                    ? Colors.red[700]
                    : Colors.grey[600],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 盤面表示エリア
  Widget _buildBoardArea(ReplayState replayState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Flame盤面レンダリングに置き換え
          Text(
            '盤面: 手数 ${replayState.moveIndex}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 2),
              color: Colors.brown[900],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '9×9 盤面',
                    style: TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Move ${replayState.moveIndex}/${replayState.totalMoves}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 現在の手情報
  Widget _buildCurrentMoveInfo(ReplayState replayState) {
    final move = replayState.currentMove;
    if (move == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move ${replayState.moveIndex}: ${move.player == PlayerColor.sente ? '白' : '黒'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${move.from.x},${move.from.y} → ${move.to.x},${move.to.y}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (move.damageDealt > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${move.damageDealt}ダメージ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// 再生制御ボタン
  Widget _buildPlaybackControls(
    BuildContext context,
    WidgetRef ref,
    ReplayScreenNotifier notifier,
    ReplayState replayState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // リセット
        IconButton(
          onPressed: () => notifier.reset(),
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Reset',
        ),

        // 戻る
        IconButton(
          onPressed: replayState.moveIndex > 0 ? () => notifier.stepBackward() : null,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Step Backward',
        ),

        // 再生/一時停止
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              if (replayState.isPlaying) {
                notifier.pause();
              } else {
                notifier.play();
              }
            },
            icon: Icon(
              replayState.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            tooltip: replayState.isPlaying ? 'Pause' : 'Play',
          ),
        ),

        // 進む
        IconButton(
          onPressed: replayState.moveIndex < replayState.totalMoves
              ? () => notifier.stepForward()
              : null,
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Step Forward',
        ),

        // 最後まで
        IconButton(
          onPressed: replayState.moveIndex < replayState.totalMoves
              ? () => notifier.jumpToEnd()
              : null,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Jump to End',
        ),
      ],
    );
  }

  /// 手数スライダー
  Widget _buildMoveSlider(ReplayScreenNotifier notifier, ReplayState replayState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Move',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
            Text(
              '${replayState.moveIndex}/${replayState.totalMoves}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: replayState.moveIndex.toDouble(),
          min: 0,
          max: replayState.totalMoves.toDouble(),
          onChanged: (value) {
            notifier.jumpToMove(value.toInt());
          },
          activeColor: Colors.blue[400],
          inactiveColor: Colors.grey[700],
        ),
      ],
    );
  }

  /// 再生速度・統計情報
  Widget _buildSpeedAndStats(
    ReplayScreenNotifier notifier,
    ReplayState replayState,
    GameRecord gameRecord,
  ) {
    return Column(
      children: [
        // 再生速度選択
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Speed',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
            Row(
              children: [0.5, 1.0, 2.0].map((speed) {
                final isSelected = (replayState.playbackSpeed - speed).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        notifier.setPlaybackSpeed(speed);
                      }
                    },
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontSize: 11,
                    ),
                    backgroundColor: Colors.grey[800],
                    selectedColor: Colors.blue[600],
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 統計情報
        if (gameRecord.stats.isNotEmpty)
          _buildStatsGrid(gameRecord),
      ],
    );
  }

  /// 統計情報グリッド
  Widget _buildStatsGrid(GameRecord gameRecord) {
    final stats = gameRecord.stats;
    final whiteHP = '${stats['white_current_hp']?.toString() ?? 'N/A'}/${stats['white_max_hp']?.toString() ?? 'N/A'}';
    final blackHP = '${stats['black_current_hp']?.toString() ?? 'N/A'}/${stats['black_max_hp']?.toString() ?? 'N/A'}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('White HP', whiteHP, Colors.blue),
              _buildStatItem('Black HP', blackHP, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Ranged Attacks',
                stats['white_ranged_attacks']?.toString() ?? '0',
                Colors.blue,
              ),
              _buildStatItem(
                'Critical Hits',
                stats['critical_hits']?.toString() ?? '0',
                Colors.amber,
              ),
              _buildStatItem(
                'Total Moves',
                stats['total_moves']?.toString() ?? '0',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計項目表示
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
