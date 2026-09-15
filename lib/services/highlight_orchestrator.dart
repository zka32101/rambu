/// ハイライト動画生成オーケストレーター
/// 7ステップのパイプラインを統合実行

import 'dart:io';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/highlight_service.dart';
import 'package:rambu_shogi/services/highlight_renderer.dart';
import 'package:rambu_shogi/services/cloud_functions_service.dart';
import 'package:rambu_shogi/services/cloud_storage_service.dart';
import 'package:rambu_shogi/services/share_link_service.dart';

/// ハイライト生成ステップ
enum HighlightStep {
  detecting('イベント検出'),
  rendering('フレームレンダリング'),
  encoding('ビデオエンコード'),
  uploading('ファイルアップロード'),
  sharing('シェアリンク生成'),
  persisting('データ永続化'),
  completing('完了');

  final String label;
  const HighlightStep(this.label);
}

/// ハイライト生成進捗
class HighlightProgress {
  final HighlightStep step;
  final int percentComplete;  // 0-100
  final String? message;

  HighlightProgress({
    required this.step,
    required this.percentComplete,
    this.message,
  });

  @override
  String toString() =>
      'HighlightProgress(step=${step.label}, $percentComplete%, msg=$message)';
}

/// ハイライト生成結果
class HighlightGenerationResult {
  final HighlightVideoMetadata metadata;
  final String videoUrl;
  final String shareUrl;
  final Duration elapsedTime;
  final bool success;

  HighlightGenerationResult({
    required this.metadata,
    required this.videoUrl,
    required this.shareUrl,
    required this.elapsedTime,
    this.success = true,
  });

  @override
  String toString() =>
      'HighlightGenerationResult(status=${metadata.status}, shareUrl=$shareUrl, elapsed=${elapsedTime.inSeconds}s)';
}

/// ハイライト動画生成オーケストレーター
/// 7ステップのパイプラインを統合管理
class HighlightOrchestrator {
  final HighlightService _highlightService = HighlightService();
  final HighlightRenderer _renderer = HighlightRenderer();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final CloudStorageService _storage = CloudStorageService();
  final ShareLinkService _shareLink = ShareLinkService();

  // 進捗コールバック
  Function(HighlightProgress)? _onProgress;

  /// ハイライト動画生成パイプラインを実行
  ///
  /// [game]: ゲームセッション
  /// [onProgress]: 進捗コールバック
  /// Returns: 生成結果
  ///
  /// 7ステップパイプライン:
  /// 1. イベント検出 (5%)
  /// 2. フレームレンダリング (15%)
  /// 3. ビデオエンコード (40%)
  /// 4. ファイルアップロード (60%)
  /// 5. シェアリンク生成 (75%)
  /// 6. データ永続化 (85%)
  /// 7. 完了 (100%)
  Future<HighlightGenerationResult> generateHighlight(
    GameSession game, {
    Function(HighlightProgress)? onProgress,
  }) async {
    _onProgress = onProgress;
    final startTime = DateTime.now();

    try {
      // ステップ 1: イベント検出
      _reportProgress(HighlightStep.detecting, 5, 'ハイライトイベントを検出中...');
      final events = _highlightService.detectHighlightEvents(game);

      if (events.isEmpty) {
        throw OrchestratorException('No highlight events detected in game');
      }

      final event = events.first;  // 最重要イベントを使用
      final metadata = _highlightService.createHighlightMetadata(game, event);

      // ステップ 2: フレームレンダリング
      _reportProgress(HighlightStep.rendering, 15, 'ゲーム画面をレンダリング中...');
      final frameFiles = await _renderer.renderFrameSequence(
        game,
        event,
        onProgress: (renderProgress) {
          final overall = 15 + (renderProgress.percentComplete * 0.25).toInt();
          _reportProgress(HighlightStep.rendering, overall, 'フレーム ${renderProgress.currentFrame}/${renderProgress.totalFrames}');
        },
      );

      if (frameFiles.isEmpty) {
        throw OrchestratorException('No frames rendered');
      }

      _reportProgress(HighlightStep.rendering, 40, 'レンダリング完了');

      // ステップ 3: ビデオエンコード
      _reportProgress(HighlightStep.encoding, 40, 'ビデオをエンコード中...');
      final encodedVideoPath = await _encodeFramesToVideo(frameFiles, event);

      _reportProgress(HighlightStep.encoding, 60, 'エンコード完了');

      // ステップ 4: ファイルアップロード
      _reportProgress(HighlightStep.uploading, 60, 'ビデオファイルをアップロード中...');
      final uploadResult = await _storage.uploadVideo(
        videoFile: File(encodedVideoPath),
        sessionId: game.sessionId,
        eventType: event.eventType,
      );

      metadata.videoUrl = uploadResult.downloadUrl;

      _reportProgress(HighlightStep.uploading, 65, 'サムネイルをアップロード中...');
      // TODO: サムネイルファイルがある場合はアップロード

      _reportProgress(HighlightStep.uploading, 75, 'アップロード完了');

      // ステップ 5: シェアリンク生成
      _reportProgress(HighlightStep.sharing, 75, 'シェアリンクを生成中...');
      final shareLinkResult = await _shareLink.generateShareLink(
        videoUrl: uploadResult.downloadUrl,
        sessionId: game.sessionId,
        eventType: event.eventType,
      );

      metadata.shareLink = shareLinkResult.shortUrl;

      _reportProgress(HighlightStep.sharing, 85, 'シェアリンク生成完了');

      // ステップ 6: Firestore に保存
      _reportProgress(HighlightStep.persisting, 85, 'メタデータを保存中...');
      await _persistMetadata(metadata);

      metadata.status = 'success';

      _reportProgress(HighlightStep.persisting, 100, 'データ保存完了');

      // ステップ 7: 完了
      _reportProgress(HighlightStep.completing, 100, 'ハイライト生成完了！');

      // クリーンアップ
      await _cleanup(frameFiles, File(encodedVideoPath));

      final elapsedTime = DateTime.now().difference(startTime);

      return HighlightGenerationResult(
        metadata: metadata,
        videoUrl: uploadResult.downloadUrl,
        shareUrl: shareLinkResult.shortUrl,
        elapsedTime: elapsedTime,
        success: true,
      );
    } catch (e) {
      final elapsedTime = DateTime.now().difference(startTime);

      if (e is OrchestratorException) {
        print('❌ ハイライト生成失敗: ${e.message}');
      } else {
        print('❌ 予期しないエラー: $e');
      }

      // エラーメタデータを作成
      final errorMetadata = HighlightVideoMetadata(
        sessionId: game.sessionId,
        eventType: 'error',
        moveNumber: 0,
        frameStartIndex: 0,
        frameEndIndex: 0,
        durationSeconds: 0,
        createdAt: DateTime.now(),
        status: 'failed',
      );

      return HighlightGenerationResult(
        metadata: errorMetadata,
        videoUrl: '',
        shareUrl: '',
        elapsedTime: elapsedTime,
        success: false,
      );
    }
  }

  /// フレームをビデオにエンコード
  Future<String> _encodeFramesToVideo(
    List<File> frameFiles,
    HighlightEvent event,
  ) async {
    try {
      const frameRate = 30;
      const durationSeconds = 15;

      // Cloud Storage にフレーム画像をアップロード
      // 実装時: 画像列パスを指定
      const imageSequencePath = 'gs://rambu-highlights/frames/%06d.png';
      final outputPath = 'gs://rambu-highlights/videos/${DateTime.now().millisecondsSinceEpoch}.mp4';

      // エンコードジョブを開始
      final jobId = await _cloudFunctions.startVideoEncoding(
        VideoEncodeRequest(
          imageSequencePath: imageSequencePath,
          outputPath: outputPath,
          frameRate: frameRate,
          durationSeconds: durationSeconds,
        ),
      );

      // エンコード完了を待機
      final _encodedPath = await _cloudFunctions.waitForCompletion(jobId);

      return _encodedPath;
    } catch (e) {
      throw OrchestratorException('Failed to encode video: $e');
    }
  }

  /// メタデータを Firestore に保存
  Future<void> _persistMetadata(HighlightVideoMetadata metadata) async {
    try {
      // 実装時: Firestore に save
      // await _firestoreService.saveHighlight(metadata);

      // スタブ実装
      print('Saving highlight metadata: $metadata');
    } catch (e) {
      throw OrchestratorException('Failed to persist metadata: $e');
    }
  }

  /// テンポラリファイルをクリーンアップ
  Future<void> _cleanup(List<File> frameFiles, File videoFile) async {
    try {
      // フレームファイルを削除
      for (final file in frameFiles) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      }

      // ビデオファイルを削除
      if (videoFile.existsSync()) {
        videoFile.deleteSync();
      }

      // レンダラーをクリーンアップ
      await _renderer.cleanup();
    } catch (e) {
      print('Warning: Cleanup failed: $e');
      // クリーンアップ失敗は非致命的
    }
  }

  /// 進捗を報告
  void _reportProgress(
    HighlightStep step,
    int percent,
    String? message,
  ) {
    _onProgress?.call(
      HighlightProgress(
        step: step,
        percentComplete: percent.clamp(0, 100),
        message: message,
      ),
    );

    print('${step.label}: $percent% ${message ?? ''}');
  }

  /// オーケストレータをクリーンアップ
  Future<void> dispose() async {
    await _renderer.cleanup();
  }
}

/// オーケストレータ例外
class OrchestratorException implements Exception {
  final String message;

  OrchestratorException(this.message);

  @override
  String toString() => 'OrchestratorException: $message';
}
