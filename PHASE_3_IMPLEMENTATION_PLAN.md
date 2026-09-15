# Phase 3: ハイライト動画生成パイプライン実装計画

## 📊 Phase 3 概要

**目標**: 対局終了から15秒ハイライト動画の自動生成が完全に機能する

**期間**: 約11日間（2フェーズ）

**成功基準**:
- ✅ ハイライト生成成功率 100%（5回中5回）
- ✅ 生成時間 100-180秒以内（エンコード含む）
- ✅ 30日自動削除が機能

---

## 🏗️ アーキテクチャ

### 全体フロー図

```
対局終了
    ↓
[1] イベント検出（highlight_service.dart）
    ├─ クリティカルヒット検出
    ├─ 大ダメージ検出
    └─ 逆転検出
    ↓
[2] フレーム範囲計算（highlight_service.dart）
    └─ event ± 7.5秒 → フレーム数計算
    ↓
[3] メタデータ生成（highlight_service.dart）
    └─ HighlightVideoMetadata 作成
    ↓
[4] ビデオレンダリング（highlight_renderer.dart - NEW）
    ├─ Flameゲーム再レンダリング
    ├─ フレーム範囲を画像シーケンス化
    └─ 一時保存 (Cloud Storage staging)
    ↓
[5] エンコード実行（cloud_functions_service.dart - NEW）
    ├─ Cloud Functions 呼び出し
    ├─ ffmpeg エンコード実行
    └─ MP4ビデオ生成
    ↓
[6] アップロード（cloud_storage_service.dart - NEW）
    ├─ MP4ファイルをCloud Storageへ
    ├─ サムネイル生成＆アップロード
    └─ ライフサイクル設定（30日後削除）
    ↓
[7] シェアリンク生成（share_link_service.dart - NEW）
    ├─ Bitly API で短縮URL生成
    ├─ Fallback: Firebase Dynamic Links
    └─ ハイライト.shareLink に保存
    ↓
[8] Firestore保存（firestore_service.dart - EXTEND）
    └─ HighlightVideoMetadata.status = 'success'
    ↓
[9] 通知送信（analytics_service.dart - EXTEND）
    └─ "ハイライト生成完了" イベント記録
```

---

## 📁 Phase 3 新規実装ファイル

### 1. `lib/services/highlight_renderer.dart` (NEW)
Flameゲーム画面をビデオフレーム列に変換

**責務**:
- Flameゲーム再レンダリング
- 指定フレーム範囲を画像シーケンスに
- 一時ファイル管理

**主要クラス**:
```dart
class HighlightRenderer {
  /// ゲームセッションを指定フレーム範囲でレンダリング
  Future<List<File>> renderFrameSequence(
    GameSession game,
    HighlightEvent event,
  )
  
  /// レンダリング中止＆リソース解放
  Future<void> cleanup()
}
```

**行数予定**: 150-200行

---

### 2. `lib/services/cloud_functions_service.dart` (NEW)
Cloud Functionsを使用したビデオエンコード

**責務**:
- Cloud Functions へのリクエスト実行
- ffmpeg エンコードジョブ管理
- エラーハンドリング＆リトライ

**主要クラス**:
```dart
class CloudFunctionsService {
  /// エンコードジョブを開始
  Future<String> startVideoEncoding({
    required String imageSequencePath,
    required String outputPath,
    required int frameRate,
    required int durationSeconds,
  })
  
  /// エンコード進捗確認
  Future<EncodeProgress> checkProgress(String jobId)
  
  /// エンコード完了待機
  Future<String> waitForCompletion(String jobId, {Duration timeout})
}
```

**行数予定**: 180-250行

---

### 3. `lib/services/cloud_storage_service.dart` (NEW)
Cloud Storage へのアップロードと生存期間管理

**責務**:
- MP4ビデオファイルアップロード
- サムネイル画像アップロード
- ライフサイクル設定（30日後削除）
- 一時ファイルクリーンアップ

**主要クラス**:
```dart
class CloudStorageService {
  /// ビデオをアップロード
  Future<String> uploadVideo({
    required File videoFile,
    required String sessionId,
    required String eventType,
  })
  
  /// サムネイルをアップロード
  Future<String> uploadThumbnail({
    required File thumbnailFile,
    required String sessionId,
  })
  
  /// ライフサイクル設定（自動削除）
  Future<void> setAutoDeleteLifecycle(String bucketName)
}
```

**行数予定**: 160-220行

---

### 4. `lib/services/share_link_service.dart` (NEW)
共有リンク生成（Bitly + Fallback）

**責務**:
- Bitly APIで短縮URL生成
- Fallback: Firebase Dynamic Links
- エラー時の処理

**主要クラス**:
```dart
class ShareLinkService {
  /// 共有リンクを生成
  Future<String> generateShareLink({
    required String videoUrl,
    required String sessionId,
    required String eventType,
  })
  
  /// Bitly API呼び出し
  Future<String> shortenWithBitly(String longUrl)
  
  /// Firebase Dynamic Links呼び出し（Fallback）
  Future<String> createDynamicLink(String videoUrl)
}
```

**行数予定**: 120-180行

---

### 5. `lib/services/highlight_orchestrator.dart` (NEW)
Phase 3 全体のオーケストレーション

**責務**:
- 7つのステップを順序立てて実行
- 各ステップの成功/失敗判定
- エラーハンドリング＆トランザクション管理
- 進捗通知

**主要クラス**:
```dart
class HighlightOrchestrator {
  /// ハイライト生成パイプライン全体を実行
  Future<HighlightVideoMetadata> generateHighlight(
    GameSession game,
    HighlightEvent event,
  )
  
  // 内部: 7つのステップを順序立て実行
  Future<List<File>> _renderFrames(...)
  Future<String> _encodeVideo(...)
  Future<String> _uploadVideo(...)
  Future<String> _generateShareLink(...)
  Future<void> _saveToFirestore(...)
}
```

**行数予定**: 200-280行

---

### 6. `lib/viewmodels/highlight_provider.dart` (NEW - EXTEND game_provider.dart)
Riverpodプロバイダ - ハイライト生成状態管理

**責務**:
- ハイライト生成の非同期管理
- 進捗状態の監視
- キャンセル機能

**主要プロバイダ**:
```dart
// ハイライト生成中フラグ
final highlightGeneratingProvider = StateProvider<bool>(...)

// ハイライト生成進捗（0-100%）
final highlightProgressProvider = StateProvider<int>(...)

// ハイライト完成後の結果
final lastHighlightProvider = StateProvider<HighlightVideoMetadata?>(...))

// ハイライト生成エラー
final highlightErrorProvider = StateProvider<String?>(...)
```

**行数予定**: 80-120行

---

### 7. `lib/utils/highlight_constants.dart` (EXTEND)
ハイライト関連の定数追加

**追加内容**:
- Cloud Functions エンドポイント
- Cloud Storage バケット名
- Bitly API キー（環境変数から）
- タイムアウト時間
- リトライ設定

**行数予定**: 30-50行

---

## 📊 実装フェーズ分割

### Phase 3a: コア サービス層（4日）
- [x] highlight_renderer.dart - Flame再レンダリング
- [x] cloud_functions_service.dart - エンコード管理
- [x] cloud_storage_service.dart - ストレージ管理
- [x] share_link_service.dart - リンク生成

### Phase 3b: オーケストレーション（3日）
- [x] highlight_orchestrator.dart - パイプライン統合
- [x] highlight_provider.dart - 状態管理
- [x] result_screen.dart 修正 - ハイライト表示

### Phase 3c: テスト＆ドキュメント（4日）
- [x] 統合テスト
- [x] エラーシナリオテスト
- [x] ドキュメント作成
- [x] Cloud Functions 実装ガイド

---

## 🔗 依存関係

### Firebase 設定必須

```yaml
# pubspec.yaml に既に含まれるべき
firebase_core: ^2.x
cloud_firestore: ^4.x
firebase_storage: ^11.x
firebase_functions: ^4.x
```

### 外部 API キー

1. **Bitly API Key**
   - 環境変数: `BITLY_API_KEY`
   - Cloud Functions環境変数に設定

2. **Firebase プロジェクト**
   - Firestore: ハイライトメタデータ保存
   - Cloud Storage: ビデオ＆サムネイル
   - Cloud Functions: ffmpeg エンコード

---

## 📈 進捗トラッキング

### Phase 3a チェックリスト

- [ ] highlight_renderer.dart 実装
  - [ ] Flame再レンダリング機能
  - [ ] フレームシーケンス生成
  - [ ] テンポラリファイル管理

- [ ] cloud_functions_service.dart 実装
  - [ ] Cloud Functions 呼び出し
  - [ ] ジョブ管理
  - [ ] エラーハンドリング

- [ ] cloud_storage_service.dart 実装
  - [ ] アップロード機能
  - [ ] ライフサイクル設定
  - [ ] 署名付きURL生成

- [ ] share_link_service.dart 実装
  - [ ] Bitly 統合
  - [ ] Fallback リンク生成
  - [ ] エラーハンドリング

### Phase 3b チェックリスト

- [ ] highlight_orchestrator.dart 実装
  - [ ] 7ステップパイプライン実装
  - [ ] トランザクション管理
  - [ ] エラー回復

- [ ] highlight_provider.dart 実装
  - [ ] 状態管理プロバイダ
  - [ ] 進捗通知
  - [ ] キャンセル機能

- [ ] UI 統合
  - [ ] result_screen.dart修正（ハイライト表示）
  - [ ] 生成中フローUI
  - [ ] 成功/エラー通知

### Phase 3c チェックリスト

- [ ] 統合テスト (5回以上の完全実行)
- [ ] エラーシナリオテスト
- [ ] パフォーマンステスト (100-180秒以内)
- [ ] ドキュメント作成
- [ ] Cloud Functions 実装ガイド
- [ ] トラブルシューティングガイド

---

## 🚀 実装上の注意点

### 1. メモリ管理（重要）
Flameゲームの再レンダリングは大量のメモリを消費する可能性

```dart
// ✅ 実装方針
- テンポラリファイルを段階的に処理
- 画像シーケンス生成後、即座にエンコード開始
- メモリ使用量をモニタリング
- 大規模フレーム数の場合は分割処理
```

### 2. タイムアウト管理
ビデオエンコードは時間がかかる可能性（100-180秒）

```dart
// ✅ 実装方針
- Cloud Functions タイムアウト: 540秒（9分）に設定
- クライアント側で定期的に進捗確認
- キャンセル機能を実装
```

### 3. エラーハンドリング
各ステップで失敗する可能性を想定

```dart
// ✅ 実装方針
- 各ステップで詳細なエラーログ
- 部分的なロールバック（クリーンアップ）
- ユーザーへの明確なエラー通知
- 再試行ロジック実装
```

### 4. 進捗通知
ユーザーにリアルタイム進捗を表示

```dart
// ✅ 実装方針
- 各ステップ開始時に UI 更新
- 進捗パーセンテージ表示（粗い推定でOK）
- バックグラウンド完了通知
```

---

## 📚 参考資料

### 既存実装
- `lib/services/highlight_service.dart` - イベント検出（基本実装済）

### Firebase ドキュメント
- Cloud Functions: `https://firebase.google.com/docs/functions`
- Cloud Storage: `https://firebase.google.com/docs/storage`
- Firestore: `https://firebase.google.com/docs/firestore`

### 外部 API
- Bitly API: `https://dev.bitly.com/docs/apis/bitlinks`
- Firebase Dynamic Links: `https://firebase.google.com/docs/dynamic-links`

---

## ✅ Phase 3 完了条件

1. **ハイライト生成成功率 100%**
   - 5回連続でハイライト生成に成功
   - エラー発生なし

2. **生成時間 100-180秒以内**
   - 対局終了からビデオ再生可能まで
   - エンコード含む

3. **30日自動削除が機能**
   - Cloud Storage ライフサイクル設定済み
   - 古いハイライトが自動削除される

4. **共有機能が動作**
   - 生成されたハイライトをシェア可能
   - 短縮URL生成完了

---

## 🎯 次のステップ（Phase 3a スタート）

1. highlight_renderer.dart 実装開始
2. Flame再レンダリング機能の構築
3. フレームシーケンス生成ロジック実装
4. テンポラリファイル管理実装

---

**Last Updated**: 2026-08-27  
**Status**: Phase 3 計画完成 ✅ → 実装開始待機中 ⏳
