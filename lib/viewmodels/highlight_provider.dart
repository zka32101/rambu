/// ハイライト生成の状態管理
/// Riverpod provider でハイライト動画生成の進捗・結果・エラーを管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/highlight_orchestrator.dart';

/// ハイライト生成状態
class HighlightGenerationState {
  final bool isGenerating;
  final HighlightProgress? currentProgress;
  final HighlightGenerationResult? result;
  final String? error;
  final Duration? elapsedTime;

  HighlightGenerationState({
    this.isGenerating = false,
    this.currentProgress,
    this.result,
    this.error,
    this.elapsedTime,
  });

  /// 生成完了フラグ
  bool get isComplete => result != null && !isGenerating;

  /// 成功フラグ
  bool get isSuccess => result?.success ?? false;

  /// シェアリンク取得可否
  bool get canShare => isSuccess && (result?.shareUrl.isNotEmpty ?? false);

  /// 次の状態を返す
  HighlightGenerationState copyWith({
    bool? isGenerating,
    HighlightProgress? currentProgress,
    HighlightGenerationResult? result,
    String? error,
    Duration? elapsedTime,
  }) {
    return HighlightGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      currentProgress: currentProgress ?? this.currentProgress,
      result: result ?? this.result,
      error: error ?? this.error,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  @override
  String toString() => '''HighlightGenerationState(
    isGenerating=$isGenerating,
    progress=${currentProgress?.percentComplete}%,
    success=$isSuccess,
    error=$error
  )''';
}

/// ハイライト生成状態通知機
class HighlightGenerationNotifier
    extends StateNotifier<HighlightGenerationState> {
  final HighlightOrchestrator _orchestrator = HighlightOrchestrator();

  HighlightGenerationNotifier()
      : super(HighlightGenerationState(isGenerating: false));

  /// ハイライト動画生成を開始
  Future<void> generateHighlight(GameSession game) async {
    // 既に生成中なら何もしない
    if (state.isGenerating) {
      return;
    }

    state = state.copyWith(isGenerating: true, error: null, result: null);

    try {
      final result = await _orchestrator.generateHighlight(
        game,
        onProgress: (progress) {
          state = state.copyWith(currentProgress: progress);
        },
      );

      final elapsedTime = result.elapsedTime;

      state = state.copyWith(
        isGenerating: false,
        result: result,
        elapsedTime: elapsedTime,
        error: result.success ? null : 'ハイライト生成に失敗しました',
      );

      print('✅ ハイライト生成完了: ${result.shareUrl}');
    } catch (e) {
      print('❌ ハイライト生成エラー: $e');
      state = state.copyWith(
        isGenerating: false,
        error: 'ハイライト生成中にエラーが発生しました: $e',
      );
    }
  }

  /// 生成状態をリセット
  void reset() {
    state = HighlightGenerationState(isGenerating: false);
  }

  /// クリーンアップ
  Future<void> dispose() async {
    await _orchestrator.dispose();
  }
}

/// ハイライト生成状態プロバイダ
final highlightGenerationProvider =
    StateNotifierProvider<HighlightGenerationNotifier, HighlightGenerationState>(
  (ref) => HighlightGenerationNotifier(),
);

/// ハイライト生成の進捗パーセンテージプロバイダ
final highlightProgressPercentProvider = Provider<int>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  return state.currentProgress?.percentComplete ?? 0;
});

/// ハイライト生成のステップラベルプロバイダ
final highlightStepLabelProvider = Provider<String>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  if (!state.isGenerating && state.result == null) {
    return '準備中...';
  }
  return state.currentProgress?.step.label ?? '処理中...';
});

/// ハイライトシェアリンクプロバイダ
final highlightShareLinkProvider = Provider<String?>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  if (state.isSuccess) {
    return state.result?.shareUrl;
  }
  return null;
});

/// ハイライトビデオURLプロバイダ
final highlightVideoUrlProvider = Provider<String?>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  if (state.isSuccess) {
    return state.result?.videoUrl;
  }
  return null;
});

/// ハイライト生成エラーメッセージプロバイダ
final highlightErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  return state.error;
});

/// ハイライト生成完了フラグプロバイダ
final highlightCompleteProvider = Provider<bool>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  return state.isComplete;
});

/// ハイライト生成経過時間プロバイダ
final highlightElapsedTimeProvider = Provider<Duration?>((ref) {
  final state = ref.watch(highlightGenerationProvider);
  return state.elapsedTime;
});
