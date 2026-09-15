/// ハイライト生成進捗インジケーターウィジェット
/// 生成中の進捗をリアルタイムで表示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/viewmodels/highlight_provider.dart';

/// ハイライト生成進捗インジケーター
class HighlightProgressIndicator extends ConsumerWidget {
  /// コンパクト表示モード（進度バーのみ）
  final bool compact;

  const HighlightProgressIndicator({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightState = ref.watch(highlightGenerationProvider);
    final progressPercent = ref.watch(highlightProgressPercentProvider);
    final stepLabel = ref.watch(highlightStepLabelProvider);
    final error = ref.watch(highlightErrorProvider);

    if (highlightState.isGenerating) {
      if (compact) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      stepLabel,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(3.0),
                child: LinearProgressIndicator(
                  value: progressPercent / 100.0,
                  minHeight: 4.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
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
                    child: CircularProgressIndicator(strokeWidth: 2.0),
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
                    style: const TextStyle(fontSize: 12.0, color: Colors.blue),
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
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                ),
              ),
            ],
          ),
        );
      }
    } else if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(fontSize: 12.0, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else if (highlightState.isSuccess) {
      final elapsedTime = highlightState.elapsedTime;
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
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
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// ハイライト生成ステータスバナー
/// より簡潔な表示用
class HighlightStatusBanner extends ConsumerWidget {
  const HighlightStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightState = ref.watch(highlightGenerationProvider);
    final progressPercent = ref.watch(highlightProgressPercentProvider);

    if (highlightState.isGenerating) {
      return LinearProgressIndicator(
        value: progressPercent / 100.0,
        minHeight: 3.0,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
      );
    } else if (highlightState.error != null) {
      return Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                highlightState.error!,
                style: const TextStyle(fontSize: 12.0, color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (highlightState.isSuccess) {
      return Container(
        color: Colors.green.shade50,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16.0),
            const SizedBox(width: 8.0),
            const Expanded(
              child: Text(
                '✅ ハイライト動画が準備完了',
                style: TextStyle(fontSize: 12.0, color: Colors.green),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
