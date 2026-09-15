/// Cloud Storage インテグレーション
/// ビデオ＆サムネイル＆ファイルライフサイクル管理

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// ファイルアップロード結果
class StorageUploadResult {
  final String filePath;       // Cloud Storage上のパス
  final String downloadUrl;    // ダウンロードURL
  final int fileSizeBytes;     // ファイルサイズ
  final DateTime uploadedAt;

  StorageUploadResult({
    required this.filePath,
    required this.downloadUrl,
    required this.fileSizeBytes,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  @override
  String toString() => 'StorageUploadResult(path=$filePath, size=${fileSizeBytes}B)';
}

/// Cloud Storage サービス
/// ハイライトビデオ＆メタデータの保存管理
class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // バケット名（firebase.json から設定）
  static const String highlightBucket = 'highlights';

  // ファイル保持期限（日数）
  static const int retentionDays = 30;

  /// ビデオファイルをアップロード
  ///
  /// [videoFile]: ローカルビデオファイル
  /// [sessionId]: ゲームセッションID
  /// [eventType]: イベント種類（'critical', 'bigDamage', 'reversal'）
  /// Returns: アップロード結果
  ///
  /// パス形式: gs://bucket/videos/{sessionId}/{eventType}_{timestamp}.mp4
  Future<StorageUploadResult> uploadVideo({
    required File videoFile,
    required String sessionId,
    required String eventType,
  }) async {
    if (!videoFile.existsSync()) {
      throw StorageException('Video file not found: ${videoFile.path}');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${eventType}_${timestamp}.mp4';
      final filePath = 'videos/$sessionId/$fileName';

      final ref = _storage.ref(filePath);
      final uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'sessionId': sessionId,
            'eventType': eventType,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // アップロード完了を待機
      final taskSnapshot = await uploadTask;

      // ダウンロードURLを取得
      final downloadUrl = await ref.getDownloadURL();

      // ファイルサイズを取得
      final metadata = await ref.getMetadata();
      final fileSize = metadata?.size ?? 0;

      return StorageUploadResult(
        filePath: filePath,
        downloadUrl: downloadUrl,
        fileSizeBytes: fileSize,
        uploadedAt: DateTime.now(),
      );
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload video: ${e.message}', code: e.code);
    } catch (e) {
      throw StorageException('Unexpected error uploading video: $e');
    }
  }

  /// サムネイル画像をアップロード
  ///
  /// [thumbnailFile]: ローカルサムネイルファイル（PNG）
  /// [sessionId]: ゲームセッションID
  /// [videoFileName]: ビデオファイル名（対応付け用）
  /// Returns: アップロード結果
  ///
  /// パス形式: gs://bucket/thumbnails/{sessionId}/{videoFileName}.png
  Future<StorageUploadResult> uploadThumbnail({
    required File thumbnailFile,
    required String sessionId,
    required String videoFileName,
  }) async {
    if (!thumbnailFile.existsSync()) {
      throw StorageException('Thumbnail file not found: ${thumbnailFile.path}');
    }

    try {
      // ビデオファイル名から拡張子を除去
      final baseName = videoFileName.replaceAll('.mp4', '');
      final filePath = 'thumbnails/$sessionId/${baseName}.png';

      final ref = _storage.ref(filePath);
      final uploadTask = ref.putFile(
        thumbnailFile,
        SettableMetadata(
          contentType: 'image/png',
          customMetadata: {
            'sessionId': sessionId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final taskSnapshot = await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      final metadata = await ref.getMetadata();
      final fileSize = metadata?.size ?? 0;

      return StorageUploadResult(
        filePath: filePath,
        downloadUrl: downloadUrl,
        fileSizeBytes: fileSize,
        uploadedAt: DateTime.now(),
      );
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload thumbnail: ${e.message}', code: e.code);
    } catch (e) {
      throw StorageException('Unexpected error uploading thumbnail: $e');
    }
  }

  /// ファイルをダウンロード
  ///
  /// [storagePath]: Cloud Storage上のパス
  /// [localPath]: ローカル保存先パス
  /// Returns: ダウンロードしたファイル
  Future<File> downloadFile({
    required String storagePath,
    required String localPath,
  }) async {
    try {
      final ref = _storage.ref(storagePath);
      final localFile = File(localPath);

      await ref.writeToFile(localFile);

      return localFile;
    } on FirebaseException catch (e) {
      throw StorageException('Failed to download file: ${e.message}', code: e.code);
    } catch (e) {
      throw StorageException('Unexpected error downloading file: $e');
    }
  }

  /// ファイルを削除
  ///
  /// [storagePath]: 削除するファイルのパス
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw StorageException('Failed to delete file: ${e.message}', code: e.code);
    } catch (e) {
      throw StorageException('Unexpected error deleting file: $e');
    }
  }

  /// セッションのすべてのハイライトを削除
  ///
  /// [sessionId]: ゲームセッションID
  ///
  /// 注意: 実装時にはCloud Storageのライフサイクルルールで
  /// 自動削除（30日後）するため、このメソッドは手動削除用
  Future<void> deleteSessionHighlights(String sessionId) async {
    try {
      // ビデオ削除
      final videoRef = _storage.ref('videos/$sessionId');
      try {
        final videoList = await videoRef.listAll();
        for (final file in videoList.items) {
          await file.delete();
        }
      } catch (e) {
        print('Warning: Failed to delete videos: $e');
      }

      // サムネイル削除
      final thumbRef = _storage.ref('thumbnails/$sessionId');
      try {
        final thumbList = await thumbRef.listAll();
        for (final file in thumbList.items) {
          await file.delete();
        }
      } catch (e) {
        print('Warning: Failed to delete thumbnails: $e');
      }
    } catch (e) {
      throw StorageException('Failed to delete session highlights: $e');
    }
  }

  /// 署名付きダウンロードURLを生成
  ///
  /// [storagePath]: Cloud Storage上のパス
  /// [expirationDays]: 有効期限（日数）
  /// Returns: 署名付きURL
  ///
  /// 注意: 実装時には admin SDK or REST API が必要
  /// Dart SDK からは直接サポートされないため、
  /// Cloud Functions 経由で取得することを推奨
  Future<String> getSignedUrl(
    String storagePath, {
    int expirationDays = 7,
  }) async {
    try {
      final ref = _storage.ref(storagePath);
      // Dart SDK は署名付きURL生成をサポートしていないため、
      // 以下は将来の実装用プレースホルダー
      // 代替案: Cloud Functions で署名付きURL生成

      // 暫定: 通常のダウンロードURLを返す
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageException('Failed to get signed URL: $e');
    }
  }

  /// ストレージのメタデータを取得
  ///
  /// [storagePath]: ファイルパス
  /// Returns: メタデータ
  Future<FullMetadata?> getMetadata(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      throw StorageException('Failed to get metadata: ${e.message}', code: e.code);
    } catch (e) {
      throw StorageException('Unexpected error getting metadata: $e');
    }
  }

  /// ライフサイクルルール設定情報（ドキュメント用）
  ///
  /// Cloud Storage にライフサイクルルール設定を適用するには、
  /// gsutil コマンド、GCP Console、または Terraform を使用してください
  ///
  /// 設定例 (lifecycle.json):
  /// ```json
  /// {
  ///   "lifecycle": {
  ///     "rule": [
  ///       {
  ///         "action": {"type": "Delete"},
  ///         "condition": {
  ///           "age": 30,
  ///           "matchesPrefix": ["videos/", "thumbnails/"]
  ///         }
  ///       }
  ///     ]
  ///   }
  /// }
  /// ```
  ///
  /// 設定コマンド:
  /// ```bash
  /// gsutil lifecycle set lifecycle.json gs://rambu-highlights/
  /// ```
  static const String lifecycleConfigExample = '''
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "matchesPrefix": ["videos/", "thumbnails/"]
        }
      }
    ]
  }
}
  ''';
}

/// Cloud Storage 例外
class StorageException implements Exception {
  final String message;
  final String? code;

  StorageException(
    this.message, {
    this.code,
  });

  @override
  String toString() => 'StorageException: $message${code != null ? ' (code: $code)' : ''}';
}
