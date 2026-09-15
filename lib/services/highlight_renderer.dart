/// ハイライト動画レンダリング
/// Flameゲーム画面をビデオフレーム列に変換

import 'dart:io';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/highlight_service.dart';
import 'package:rambu_shogi/utils/constants.dart';
import 'package:path_provider/path_provider.dart';

/// レンダリング進捗
class RenderProgress {
  final int currentFrame;
  final int totalFrames;
  final int percentComplete;

  RenderProgress({
    required this.currentFrame,
    required this.totalFrames,
  }) : percentComplete = totalFrames > 0
      ? ((currentFrame / totalFrames) * 100).toInt()
      : 0;

  @override
  String toString() => 'RenderProgress($currentFrame/$totalFrames, $percentComplete%)';
}

/// ハイライトレンダラー
/// Flameゲーム画面をビデオフレーム列に変換
class HighlightRenderer {
  // テンポラリディレクトリパス
  late Directory _tempDir;
  bool _initialized = false;

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _tempDir = Directory('${(await getTemporaryDirectory()).path}/rambu_highlights');
      if (!_tempDir.existsSync()) {
        _tempDir.createSync(recursive: true);
      }
      _initialized = true;
    } catch (e) {
      throw HighlightRenderException('Failed to initialize temp directory: $e');
    }
  }

  /// ゲームセッションを指定フレーム範囲でレンダリング
  /// 画像ファイルのシーケンスを返す
  ///
  /// [game]: ゲームセッション
  /// [event]: ハイライトイベント
  /// [onProgress]: 進捗コールバック
  ///
  /// Returns: レンダリングされた画像ファイルのリスト
  Future<List<File>> renderFrameSequence(
    GameSession game,
    HighlightEvent event, {
    Function(RenderProgress)? onProgress,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // フレーム範囲を計算
      final frameRange = _calculateFrameRange(event);

      // テンポラリディレクトリを作成
      final sessionTempDir = Directory(
        '${_tempDir.path}/${DateTime.now().millisecondsSinceEpoch}',
      );
      sessionTempDir.createSync(recursive: true);

      // フレームシーケンスをレンダリング
      // 注: 実際のFlameレンダリングはFlameGameWidgetで行われる
      // ここではシミュレーション実装を行う（実装時にFlame統合）
      final frames = <File>[];

      for (int i = frameRange.startFrame; i <= frameRange.endFrame; i++) {
        // 進捗報告
        onProgress?.call(
          RenderProgress(
            currentFrame: i - frameRange.startFrame,
            totalFrames: frameRange.totalFrames,
          ),
        );

        // フレーム画像をレンダリング（スタブ実装）
        // 実装時: Flameゲームの状態を指定フレーム時点のムーブで再構築し、
        // Widget画像としてレンダリング
        final framePath = '${sessionTempDir.path}/frame_${i.toString().padLeft(6, '0')}.png';
        final frameFile = File(framePath);

        // スタブ: ダミーファイルを作成
        // 実装時: 実際のレンダリング画像を保存
        await frameFile.create(recursive: true);
        await frameFile.writeAsBytes([]);

        frames.add(frameFile);

        // キャンセルチェック（キャンセル機能実装時）
        // if (_cancelToken.isCancelled) {
        //   await cleanup();
        //   throw HighlightRenderException('Rendering cancelled');
        // }
      }

      // 最終進捗報告
      onProgress?.call(
        RenderProgress(
          currentFrame: frameRange.totalFrames,
          totalFrames: frameRange.totalFrames,
        ),
      );

      return frames;
    } catch (e) {
      await cleanup();
      if (e is HighlightRenderException) {
        rethrow;
      }
      throw HighlightRenderException('Failed to render frame sequence: $e');
    }
  }

  /// ハイライトイベントからフレーム範囲を計算
  FrameRange _calculateFrameRange(HighlightEvent event) {
    const margin = HighlightConstants.eventMarginSeconds;
    const frameRate = HighlightConstants.frameRate;

    final eventTimestamp = event.timestamp;
    final startTime = (eventTimestamp - margin).clamp(0, double.infinity);
    final endTime = eventTimestamp + margin;

    final startFrame = (startTime * frameRate).toInt();
    final endFrame = (endTime * frameRate).toInt();

    return FrameRange(
      startFrame: startFrame,
      endFrame: endFrame,
      totalFrames: endFrame - startFrame,
    );
  }

  /// テンポラリファイルをクリーンアップ
  Future<void> cleanup() async {
    if (!_initialized) return;

    try {
      if (_tempDir.existsSync()) {
        // 古いディレクトリを削除（1時間以上前）
        final now = DateTime.now();
        final files = _tempDir.listSync();

        for (final file in files) {
          if (file is Directory) {
            final stat = file.statSync();
            final age = now.difference(stat.modified);

            if (age.inHours >= 1) {
              file.deleteSync(recursive: true);
            }
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup temp files: $e');
      // クリーンアップ失敗は重大エラーではないので続行
    }
  }

  /// 指定セッションのテンポラリファイルを削除
  Future<void> cleanupSession(String sessionId) async {
    try {
      final sessionDir = Directory('${_tempDir.path}/$sessionId');
      if (sessionDir.existsSync()) {
        sessionDir.deleteSync(recursive: true);
      }
    } catch (e) {
      print('Warning: Failed to cleanup session: $e');
    }
  }

  /// テンポラリディレクトリのサイズ（デバッグ用）
  int getTempDirSize() {
    if (!_initialized || !_tempDir.existsSync()) return 0;

    int size = 0;
    final files = _tempDir.listSync(recursive: true);
    for (final file in files) {
      if (file is File) {
        size += file.lengthSync();
      }
    }
    return size;
  }

  /// テンポラリディレクトリをクリア（デバッグ用）
  Future<void> clearTempDir() async {
    if (!_initialized) return;

    try {
      if (_tempDir.existsSync()) {
        _tempDir.deleteSync(recursive: true);
      }
      _tempDir.createSync(recursive: true);
    } catch (e) {
      throw HighlightRenderException('Failed to clear temp directory: $e');
    }
  }
}

/// ハイライトレンダリング例外
class HighlightRenderException implements Exception {
  final String message;

  HighlightRenderException(this.message);

  @override
  String toString() => 'HighlightRenderException: $message';
}
