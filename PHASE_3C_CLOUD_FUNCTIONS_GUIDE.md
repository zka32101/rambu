# Phase 3c Cloud Functions実装ガイド

## 📋 概要

Phase 3c では、ハイライト動画のエンコーディングを行う Cloud Functions を実装・デプロイします。

**関連ファイル**:
- `functions/index.js` - Cloud Functions 実装
- `functions/package.json` - 依存関係
- `firebase.json` - Firebase プロジェクト設定

---

## 🎯 実装済み機能

### 1. `encodeHighlightVideo()` 関数

**目的**: フレーム画像をMP4ビデオにエンコード

**リクエスト形式**:
```json
{
  "imageSequencePath": "gs://rambu-highlights/frames/frame_%06d.png",
  "outputPath": "gs://rambu-highlights/videos/output.mp4",
  "frameRate": 30,
  "durationSeconds": 15,
  "videoCodec": "h264",
  "bitrate": 2000
}
```

**レスポンス形式**:
```json
{
  "jobId": "job_1234567890_abc123",
  "status": "pending",
  "message": "Video encoding started"
}
```

**処理フロー**:
1. ジョブ ID 生成
2. 状態を「pending」に設定
3. エンコーディングを非同期で開始
4. すぐに jobId を返却（ユーザーが即座に進捗確認可能）

### 2. `checkEncodeProgress()` 関数

**目的**: エンコーディングジョブの進捗を確認

**リクエスト形式**:
```json
{
  "jobId": "job_1234567890_abc123"
}
```

**レスポンス形式**:
```json
{
  "jobId": "job_1234567890_abc123",
  "status": "encoding",
  "percentComplete": 45,
  "errorMessage": null,
  "timestamp": "2026-08-27T10:30:45.123Z"
}
```

**ステータス値**:
- `"pending"` - 待機中
- `"encoding"` - エンコード中
- `"completed"` - 完了
- `"failed"` - 失敗
- `"cancelled"` - キャンセル済み

### 3. `cancelEncoding()` 関数

**目的**: エンコーディングジョブをキャンセル

**リクエスト形式**:
```json
{
  "jobId": "job_1234567890_abc123"
}
```

**レスポンス形式**:
```json
{
  "jobId": "job_1234567890_abc123",
  "status": "cancelled",
  "message": "Video encoding cancelled"
}
```

**キャンセル可能ステータス**:
- `"pending"` ✅
- `"encoding"` ✅
- `"completed"` ❌
- `"failed"` ❌
- `"cancelled"` ❌

---

## 🚀 デプロイ手順

### 前提条件

```bash
# Node.js 18+ と Firebase CLI インストール確認
node --version        # v18.0.0以上
firebase --version    # 12.0.0以上
```

### ステップ 1: Firebase プロジェクト初期化

```bash
# Firebase にログイン
firebase login

# プロジェクトを初期化
firebase init functions

# または既存プロジェクトと紐付け
firebase use rambu-shogi  # プロジェクト ID
```

### ステップ 2: 依存関係インストール

```bash
cd functions
npm install
```

**インストール確認**:
```bash
npm list firebase-functions firebase-admin fluent-ffmpeg
```

### ステップ 3: ローカル環境でテスト（オプション）

```bash
# Cloud Functions エミュレータ起動
firebase emulators:start --only functions

# 別ターミナルでテスト
curl -X POST http://localhost:5001/rambu-shogi/asia-northeast1/encodeHighlightVideo \
  -H "Content-Type: application/json" \
  -d '{
    "imageSequencePath": "gs://test-bucket/frames/frame_%06d.png",
    "outputPath": "gs://test-bucket/videos/output.mp4",
    "frameRate": 30,
    "durationSeconds": 15
  }'
```

### ステップ 4: Cloud Functions へデプロイ

```bash
# 単一関数のデプロイ
firebase deploy --only functions:encodeHighlightVideo

# 全関数のデプロイ
firebase deploy --only functions

# 特定リージョンのみデプロイ
firebase deploy --only functions:region/asia-northeast1
```

**デプロイ確認**:
```bash
# デプロイ済み関数一覧表示
firebase functions:list

# ログ確認
firebase functions:log
firebase functions:log --region asia-northeast1
```

### ステップ 5: Cloud Storage ライフサイクル設定

```bash
# lifecycle.json ファイル作成
cat > lifecycle.json << 'EOF'
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
EOF

# ライフサイクルルール適用
gsutil lifecycle set lifecycle.json gs://rambu-highlights/
```

---

## 🔧 設定と環境変数

### Cloud Functions の設定

Cloud Functions で環境変数が必要な場合は、以下のように設定します：

```bash
# 環境変数設定
firebase functions:config:set ffmpeg.binary="/opt/ffmpeg/bin/ffmpeg"

# 確認
firebase functions:config:get

# デプロイ
firebase deploy --only functions
```

### Dart側の設定確認

`lib/services/cloud_functions_service.dart` で正しいリージョンが設定されているか確認：

```dart
final FirebaseFunctions _functions = 
  FirebaseFunctions.instanceFor(region: 'asia-northeast1');
```

---

## 📊 進捗トラッキング仕様

### 進捗パーセンテージ配分

```
0%    ─ 初期状態
5%    ─ フレームダウンロード開始
20%   ─ フレームダウンロード完了
20-80% ─ FFmpeg エンコード中（進捗比例）
80%   ─ エンコード完了
100%  ─ アップロード完了
```

### メモリ管理

**In-Memory Job Tracker**:
- 各関数が状態を保持（メモリ効率的）
- `cleanupOldJobs()` で1時間ごとに古いジョブを削除
- 完了/失敗後のジョブは1時間で自動削除

**本番環境での推奨事項**:
- 分散デプロイの場合は Firestore を使用
- Pub/Sub で非同期ジョブ管理
- Cloud Tasks での重試管理

```dart
// Firestore での実装例（今後）
await db.collection('highlight_jobs')
  .doc(jobId)
  .set({
    'status': 'encoding',
    'percentComplete': 45,
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

---

## 🐛 トラブルシューティング

### デプロイエラー

**Error: `functions/package.json not found`**
```bash
# 解決策: 関数ディレクトリが作成されているか確認
ls -la functions/
# functions/package.json が存在することを確認
```

**Error: `firebase-functions not found`**
```bash
# 解決策: 依存関係をインストール
cd functions
npm install
cd ..
```

### ランタイムエラー

**Error: `ffmpeg not found`**
```bash
# Cloud Functions の実行環境で ffmpeg が利用可能か確認
# 通常は利用可能（node:18 イメージに含まれる）
firebase functions:log | grep -i ffmpeg
```

**Error: `Permission denied: gs://...`**
```bash
# Cloud Storage へのアクセス権限確認
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/storage.objectAdmin"
```

### パフォーマンス問題

**エンコードが遅い場合**:
1. 解像度を下げる
2. ビットレートを調整
3. フレームレートを下げる
4. Cloud Functions のメモリ設定を増加

```bash
# メモリ設定を2GBに設定
firebase deploy --only functions:encodeHighlightVideo \
  --memory 2GB
```

---

## 📈 監視とログ

### ログ確認

```bash
# リアルタイムログ
firebase functions:log --follow

# 特定関数のログ
firebase functions:log encodeHighlightVideo

# タイムスタンプ付きログ
firebase functions:log --limit 50
```

### エラー監視

```bash
# Error Reporting を有効化
gcloud error-reporting list

# Cloud Logging でカスタムメトリクス設定
# console.log('ℹ️  Message') - Info
# console.warn('⚠️  Warning') - Warning
# console.error('❌ Error') - Error
```

---

## 🧪 テスト手順

### ローカル テスト

```bash
# 1. エミュレータ起動
firebase emulators:start --only functions

# 2. テスト API 呼び出し
curl -X POST http://localhost:5001/rambu-shogi/asia-northeast1/encodeHighlightVideo \
  -H "Content-Type: application/json" \
  -d '{
    "imageSequencePath": "gs://test/frames/frame_%06d.png",
    "outputPath": "gs://test/output.mp4"
  }'

# 3. 進捗確認
curl -X POST http://localhost:5001/rambu-shogi/asia-northeast1/checkEncodeProgress \
  -H "Content-Type: application/json" \
  -d '{"jobId": "job_1234567890_abc"}'
```

### 本番環境 テスト

```bash
# 実際の Cloud Functions を呼び出し
gcloud functions call encodeHighlightVideo \
  --region asia-northeast1 \
  --gen2 \
  --data '{
    "imageSequencePath": "gs://rambu-highlights/test/frame_%06d.png",
    "outputPath": "gs://rambu-highlights/test/output.mp4"
  }'
```

### Dart から テスト

```dart
// lib/services/cloud_functions_service.dart から直接テスト
final service = CloudFunctionsService();
final jobId = await service.startVideoEncoding(
  VideoEncodeRequest(
    imageSequencePath: 'gs://...',
    outputPath: 'gs://...',
    frameRate: 30,
    durationSeconds: 15,
  ),
);

// 進捗確認ループ
for (int i = 0; i < 30; i++) {
  final progress = await service.checkProgress(jobId);
  print('Progress: ${progress.percentComplete}%');
  if (progress.isComplete) break;
  await Future.delayed(Duration(seconds: 5));
}
```

---

## 📋 チェックリスト

### デプロイ前

- [ ] Firebase CLI インストール済み
- [ ] Node.js 18+ インストール済み
- [ ] `functions/package.json` 存在確認
- [ ] `npm install` で依存関係インストール完了
- [ ] ローカルテスト実行確認

### デプロイ

- [ ] `firebase deploy --only functions` 実行
- [ ] デプロイ完了ログ確認
- [ ] `firebase functions:list` で関数一覧表示確認

### デプロイ後

- [ ] Cloud Console で関数表示確認
- [ ] ログ確認（`firebase functions:log`）
- [ ] テスト呼び出し実行
- [ ] Cloud Storage ライフサイクル設定適用
- [ ] Dart クライアントからの呼び出し確認

---

## 🚀 運用ガイド

### 継続的なデプロイ

```bash
# コードを修正した後
cd /home/user/rambu
git add functions/
git commit -m "feat: Update Cloud Functions"

# デプロイ
firebase deploy --only functions --region asia-northeast1
```

### ローテーションリリース

```bash
# 新バージョンをテスト環境で検証
firebase deploy --only functions:encodeHighlightVideo \
  --project rambu-shogi-staging

# 本番環境にデプロイ
firebase deploy --only functions:encodeHighlightVideo \
  --project rambu-shogi
```

### スケーリング設定

```bash
# 最大同時実行数を設定
gcloud functions update encodeHighlightVideo \
  --max-instances 100 \
  --region asia-northeast1
```

---

## 📞 参考リンク

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Cloud Storage Lifecycle Rules](https://cloud.google.com/storage/docs/lifecycle)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

---

**Last Updated**: 2026-08-27  
**Status**: Phase 3c Cloud Functions 実装完了 ✅

