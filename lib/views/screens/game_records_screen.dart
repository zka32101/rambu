/// Game Records Screen
/// 対局記録一覧と検索・フィルタ機能
///
/// 機能:
/// - 対局記録一覧表示（最新順）
/// - フィルタリング（結果・難易度・日付）
/// - ソート（日時・難易度・対局時間）
/// - 記録の詳細表示
/// - 再生画面への遷移

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/services/firestore_service.dart';

/// フィルタ条件
class GameRecordFilter {
  final GameResult? resultFilter;      // 結果でフィルタ
  final String? difficultyFilter;      // 難易度でフィルタ
  final SortBy sortBy;                 // ソート順
  final bool descending;               // 降順か

  GameRecordFilter({
    this.resultFilter,
    this.difficultyFilter,
    this.sortBy = SortBy.playedAt,
    this.descending = true,
  });

  GameRecordFilter copyWith({
    GameResult? resultFilter,
    String? difficultyFilter,
    SortBy? sortBy,
    bool? descending,
  }) {
    return GameRecordFilter(
      resultFilter: resultFilter ?? this.resultFilter,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }
}

/// ソート順序
enum SortBy {
  playedAt,      // 対局日時
  difficulty,    // AI難易度
  duration,      // 対局時間
}

/// ゲーム記録リストプロバイダー
final filteredGameRecordsProvider = StateNotifierProvider<
    GameRecordsNotifier,
    AsyncValue<List<GameRecord>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return GameRecordsNotifier(firestoreService);
});

/// フィルタ条件プロバイダー
final gameRecordFilterProvider =
    StateNotifierProvider<GameRecordFilterNotifier, GameRecordFilter>(
        (ref) {
  return GameRecordFilterNotifier();
});

/// Game Records State Notifier
class GameRecordsNotifier extends StateNotifier<AsyncValue<List<GameRecord>>> {
  final FirestoreService _firestoreService;

  GameRecordsNotifier(this._firestoreService)
      : super(const AsyncValue.loading()) {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _firestoreService.listGameRecords(limit: 100);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(String recordId) async {
    try {
      await _firestoreService.deleteGameRecord(recordId);
      // リロード
      await _loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadRecords();
  }
}

/// Game Record Filter State Notifier
class GameRecordFilterNotifier extends StateNotifier<GameRecordFilter> {
  GameRecordFilterNotifier() : super(GameRecordFilter());

  void setResultFilter(GameResult? result) {
    state = state.copyWith(resultFilter: result);
  }

  void setDifficultyFilter(String? difficulty) {
    state = state.copyWith(difficultyFilter: difficulty);
  }

  void setSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setDescending(bool desc) {
    state = state.copyWith(descending: desc);
  }

  void reset() {
    state = GameRecordFilter();
  }
}

/// Game Records Screen
class GameRecordsScreen extends ConsumerWidget {
  const GameRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(filteredGameRecordsProvider);
    final filter = ref.watch(gameRecordFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('棋譜'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // フィルタ・ソートバー
          _buildFilterBar(context, ref, filter),

          // 対局記録一覧
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                final filteredRecords =
                    _applyFiltersAndSort(records, filter);

                if (filteredRecords.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(filteredGameRecordsProvider.notifier)
                        .refresh();
                  },
                  child: ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      return _GameRecordTile(
                        record: filteredRecords[index],
                        gameNumber: index + 1,
                        onTap: () => _onRecordTap(context, filteredRecords[index]),
                        onDelete: () =>
                            _onRecordDelete(context, ref, filteredRecords[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('エラー: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// フィルタ・ソートバーを構築
  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, GameRecordFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // 結果フィルタ
            _FilterChip(
              label: filter.resultFilter == null ? '全て' : filter.resultFilter!.label,
              onSelected: (selected) {
                if (!selected) {
                  ref.read(gameRecordFilterProvider.notifier)
                      .setResultFilter(null);
                }
              },
              onPressed: () => _showResultFilterDialog(context, ref, filter),
            ),

            const SizedBox(width: 8),

            // 難易度フィルタ
            _FilterChip(
              label: filter.difficultyFilter ?? '難易度',
              onSelected: (selected) {
                if (!selected) {
                  ref.read(gameRecordFilterProvider.notifier)
                      .setDifficultyFilter(null);
                }
              },
              onPressed: () => _showDifficultyFilterDialog(context, ref, filter),
            ),

            const SizedBox(width: 8),

            // ソート順
            _FilterChip(
              label: _sortByLabel(filter.sortBy),
              onSelected: (selected) {},
              onPressed: () => _showSortDialog(context, ref, filter),
            ),

            const SizedBox(width: 8),

            // リセットボタン
            if (filter.resultFilter != null ||
                filter.difficultyFilter != null ||
                filter.sortBy != SortBy.playedAt)
              OutlinedButton(
                onPressed: () {
                  ref.read(gameRecordFilterProvider.notifier).reset();
                },
                child: const Text('リセット'),
              ),
          ],
        ),
      ),
    );
  }

  /// 結果フィルタダイアログ
  void _showResultFilterDialog(
      BuildContext context, WidgetRef ref, GameRecordFilter filter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('結果でフィルタ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameResult.values
              .map((result) => RadioListTile<GameResult>(
                    title: Text(result.label),
                    value: result,
                    groupValue: filter.resultFilter,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(gameRecordFilterProvider.notifier)
                            .setResultFilter(value);
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// 難易度フィルタダイアログ
  void _showDifficultyFilterDialog(
      BuildContext context, WidgetRef ref, GameRecordFilter filter) {
    const difficulties = ['初級', '中級', '上級'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('難易度でフィルタ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: difficulties
              .map((difficulty) => RadioListTile<String>(
                    title: Text(difficulty),
                    value: difficulty,
                    groupValue: filter.difficultyFilter,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(gameRecordFilterProvider.notifier)
                            .setDifficultyFilter(value);
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// ソートダイアログ
  void _showSortDialog(
      BuildContext context, WidgetRef ref, GameRecordFilter filter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ソート順'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SortBy>(
              title: const Text('対局日時'),
              value: SortBy.playedAt,
              groupValue: filter.sortBy,
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameRecordFilterProvider.notifier).setSortBy(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortBy>(
              title: const Text('AI難易度'),
              value: SortBy.difficulty,
              groupValue: filter.sortBy,
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameRecordFilterProvider.notifier).setSortBy(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortBy>(
              title: const Text('対局時間'),
              value: SortBy.duration,
              groupValue: filter.sortBy,
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameRecordFilterProvider.notifier).setSortBy(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// フィルタと並び替えを適用
  List<GameRecord> _applyFiltersAndSort(
      List<GameRecord> records, GameRecordFilter filter) {
    // フィルタ適用
    var filtered = records.where((record) {
      // 結果フィルタ
      if (filter.resultFilter != null &&
          record.result != filter.resultFilter) {
        return false;
      }

      // 難易度フィルタ
      if (filter.difficultyFilter != null &&
          record.aiDifficulty != filter.difficultyFilter) {
        return false;
      }

      return true;
    }).toList();

    // ソート適用
    switch (filter.sortBy) {
      case SortBy.playedAt:
        filtered.sort(
            (a, b) => filter.descending
                ? b.playedAt.compareTo(a.playedAt)
                : a.playedAt.compareTo(b.playedAt));
      case SortBy.difficulty:
        const difficultyOrder = {'初級': 0, '中級': 1, '上級': 2};
        filtered.sort((a, b) {
          final aOrder = difficultyOrder[a.aiDifficulty] ?? 0;
          final bOrder = difficultyOrder[b.aiDifficulty] ?? 0;
          return filter.descending ? bOrder.compareTo(aOrder) : aOrder.compareTo(bOrder);
        });
      case SortBy.duration:
        filtered.sort(
            (a, b) => filter.descending
                ? b.durationSeconds.compareTo(a.durationSeconds)
                : a.durationSeconds.compareTo(b.durationSeconds));
    }

    return filtered;
  }

  /// SortBy を文字列に変換
  String _sortByLabel(SortBy sortBy) {
    return switch (sortBy) {
      SortBy.playedAt => '日時',
      SortBy.difficulty => '難易度',
      SortBy.duration => '時間',
    };
  }

  /// 空状態を表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '対局記録がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 記録をタップしたときの処理
  void _onRecordTap(BuildContext context, GameRecord record) {
    // TODO: ReplayScreen へ遷移
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('再生: ${record.id}')),
    );
  }

  /// 記録を削除したときの処理
  void _onRecordDelete(BuildContext context, WidgetRef ref, GameRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('この対局記録を削除しますか？\n${record.id}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(filteredGameRecordsProvider.notifier)
                  .deleteRecord(record.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('削除しました')),
              );
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final Function(bool) onSelected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.onSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      onSelected: onSelected,
      onPressed: onPressed,
    );
  }
}

/// Game Record Tile Widget
class _GameRecordTile extends StatelessWidget {
  final GameRecord record;
  final int gameNumber;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GameRecordTile({
    required this.record,
    required this.gameNumber,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final playedDate = dateFormat.format(record.playedAt);
    final durationMin = record.durationSeconds ~/ 60;
    final durationSec = record.durationSeconds % 60;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          '第$gameNumber局 ${record.result.label}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(playedDate),
                const SizedBox(width: 12),
                Text('${durationMin}m${durationSec}s'),
                const SizedBox(width: 12),
                Chip(
                  label: Text(record.aiDifficulty),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 統計情報
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                const SizedBox(width: 4),
                Text(
                  'ダメージ: ${(record.stats['white_current_hp'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.bolt, size: 16, color: Colors.orange[300]),
                const SizedBox(width: 4),
                Text(
                  '飛び道具: ${record.stats['white_ranged_attacks'] as int? ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'share',
              child: Text('共有'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('削除'),
            ),
          ],
          onSelected: (String value) {
            if (value == 'delete') {
              onDelete();
            } else if (value == 'share') {
              // TODO: 共有機能
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
