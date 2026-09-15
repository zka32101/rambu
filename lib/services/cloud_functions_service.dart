/// Cloud Functions インテグレーション
/// ビデオエンコード＆ジョブ管理

import 'package:cloud_functions/cloud_functions.dart';

/// エンコード進捗情報
class EncodeProgress {
  final String jobId;
  final String status;  // 'pending', 'encoding', 'completed', 'failed'
  final int percentComplete;
  final String? errorMessage;
  final DateTime timestamp;

  EncodeProgress({
    required this.jobId,
    required this.status,
    required this.percentComplete,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isComplete => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isEncoding => status == 'encoding';

  @override
  String toString() =>
      'EncodeProgress(jobId=$jobId, status=$status, $percentComplete%, timestamp=$timestamp)';
}

/// ビデオエンコード要求
class VideoEncodeRequest {
  final String imageSequencePath;  // Cloud Storage上のパス
  final String outputPath;         // 出力先パス
  final int frameRate;             // FPS
  final int durationSeconds;       // 動画長
  final String videoCodec;         // 'h264' (デフォルト)
  final int bitrate;               // ビットレート（kbps）

  VideoEncodeRequest({
    required this.imageSequencePath,
    required this.outputPath,
    required this.frameRate,
    required this.durationSeconds,
    this.videoCodec = 'h264',
    this.bitrate = 2000,  // 2Mbps
  });

  Map<String, dynamic> toMap() => {
    'imageSequencePath': imageSequencePath,
    'outputPath': outputPath,
    'frameRate': frameRate,
    'durationSeconds': durationSeconds,
    'videoCodec': videoCodec,
    'bitrate': bitrate,
  };
}

/// Cloud Functions サービス
/// ビデオエンコードジョブの管理
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  // エンコードタイムアウト: 540秒（9分）
  static const int encodeTimeoutSeconds = 540;

  /// ビデオエンコードジョブを開始
  ///
  /// [request]: エンコード要求パラメータ
  /// Returns: ジョブID
  ///
  /// Cloud Functions が受け取る形式:
  /// ```json
  /// {
  ///   "imageSequencePath": "gs://bucket/path/frame_%06d.png",
  ///   "outputPath": "gs://bucket/path/output.mp4",
  ///   "frameRate": 30,
  ///   "durationSeconds": 15,
  ///   "videoCodec": "h264",
  ///   "bitrate": 2000
  /// }
  /// ```
  Future<String> startVideoEncoding(VideoEncodeRequest request) async {
    try {
      final callable = _functions.httpsCallable('encodeHighlightVideo');

      final result = await callable.call(request.toMap());

      final jobId = result.data['jobId'] as String?;
      if (jobId == null) {
        throw CloudFunctionsException(
          'Invalid response from encodeHighlightVideo: missing jobId',
        );
      }

      return jobId;
    } on FirebaseFunctionsException catch (e) {
      throw CloudFunctionsException(
        'Failed to start video encoding: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CloudFunctionsException('Unexpected error starting video encoding: $e');
    }
  }

  /// エンコード進捗を確認
  ///
  /// [jobId]: ジョブID
  /// Returns: 進捗情報
  Future<EncodeProgress> checkProgress(String jobId) async {
    try {
      final callable = _functions.httpsCallable('checkEncodeProgress');

      final result = await callable.call({'jobId': jobId});

      final data = result.data as Map<dynamic, dynamic>;

      return EncodeProgress(
        jobId: jobId,
        status: data['status'] as String,
        percentComplete: (data['percentComplete'] as num).toInt(),
        errorMessage: data['errorMessage'] as String?,
        timestamp: _parseTimestamp(data['timestamp']),
      );
    } on FirebaseFunctionsException catch (e) {
      throw CloudFunctionsException(
        'Failed to check encode progress: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CloudFunctionsException('Unexpected error checking progress: $e');
    }
  }

  /// エンコード完了を待機
  ///
  /// [jobId]: ジョブID
  /// [timeout]: タイムアウト（デフォルト: 9分）
  /// [pollInterval]: ポーリング間隔（デフォルト: 5秒）
  /// Returns: 出力ビデオパス
  ///
  /// 完了までポーリングを続ける
  Future<String> waitForCompletion(
    String jobId, {
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    timeout ??= Duration(seconds: encodeTimeoutSeconds);
    pollInterval ??= const Duration(seconds: 5);

    final startTime = DateTime.now();
    int pollCount = 0;

    while (true) {
      try {
        final progress = await checkProgress(jobId);

        if (progress.isComplete) {
          return progress.jobId;  // 実装時: Cloud Functionsが出力パスを返す
        }

        if (progress.isFailed) {
          throw CloudFunctionsException(
            'Video encoding failed: ${progress.errorMessage}',
          );
        }

        // タイムアウト確認
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed > timeout) {
          throw CloudFunctionsException(
            'Video encoding timed out after ${elapsed.inSeconds}s',
          );
        }

        // 次のポーリングまで待機
        await Future.delayed(pollInterval);
        pollCount++;

        // ログ出力（デバッグ用）
        if (pollCount % 6 == 0) {
          // 30秒ごと
          print('Encoding progress: ${progress.percentComplete}% (${progress.status})');
        }
      } catch (e) {
        if (e is CloudFunctionsException) {
          rethrow;
        }
        throw CloudFunctionsException('Error waiting for completion: $e');
      }
    }
  }

  /// エンコードジョブをキャンセル
  ///
  /// [jobId]: ジョブID
  Future<void> cancelEncoding(String jobId) async {
    try {
      final callable = _functions.httpsCallable('cancelEncoding');
      await callable.call({'jobId': jobId});
    } on FirebaseFunctionsException catch (e) {
      throw CloudFunctionsException(
        'Failed to cancel encoding: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CloudFunctionsException('Unexpected error canceling encoding: $e');
    }
  }

  /// タイムスタンプをパース（複数形式対応）
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }
}

/// Cloud Functions 例外
class CloudFunctionsException implements Exception {
  final String message;
  final String? code;

  CloudFunctionsException(
    this.message, {
    this.code,
  });

  @override
  String toString() => 'CloudFunctionsException: $message${code != null ? ' (code: $code)' : ''}';
}
