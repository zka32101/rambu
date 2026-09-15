# Phase 4b 実装計画書 - ストア提出準備

## 📋 概要

**フェーズ名**: Phase 4b（ストア提出準備）  
**目標**: App Store / Google Play への提出準備完了  
**期間**: 2日間（計画）  
**ステータス**: 🔄 実装開始

---

## 🎯 Phase 4b の目標

本番リリース前の最終申請準備。メタデータ・スクリーンショット・プライバシー関連文書をすべて準備

### 成功基準

- [ ] App Store メタデータ 完成（アプリ名・説明・キーワード・URL・スクショ）
- [ ] Google Play メタデータ 完成（同上、プラットフォーム独自項目含む）
- [ ] プライバシーポリシー 作成完了（Firebase/Analytics トラッキング記載）
- [ ] 利用規約 作成完了
- [ ] セキュリティチェックリスト 完了（Firestore ルール・データ暗号化確認）
- [ ] スクリーンショット 5枚以上準備完了
- [ ] プレビュー動画 15秒版準備完了

---

## 📁 Phase 4b 実装タスク

### タスク 4b-1: App Store メタデータ作成

**ファイル**: `docs/app_store_metadata.md`

**内容**:

```markdown
# App Name
乱舞将棋

# Subtitle  
HP制で観戦映えする将棋バリアント

# Description (1000字程度)
[詳細説明]

# Keywords (5個推奨)
- 将棋
- ゲーム
- ボードゲーム
- AI
- 配信

# Support URL
https://...

# Privacy URL
https://...

# Screenshots (5枚)
1. ホーム画面
2. ゲーム盤面
3. HP表示・飛び道具演出
4. ハイライト動画プレビュー
5. シェア機能

# Preview Video
- ファイル名: preview.mp4
- 長さ: 15秒
- 内容: ゲームプレイ＆ハイライト自動生成
- 解像度: 1080x1920 or 1920x1080
```

**承認プロセス**:
- App Store Connect で「価格と配信」→ 「メタデータ」 入力
- 英語版: 日本語を英訳（AI利用可）
- ローカライズ言語: 日本語のみ（初版）

---

### タスク 4b-2: Google Play メタデータ作成

**ファイル**: `docs/google_play_metadata.md`

**内容**:

```markdown
# App Name
乱舞将棋

# Short Description
HP制で観戦映えする将棋バリアント

# Full Description
[詳細説明（同 App Store）]

# Graphic Assets
- 512x512 アイコン
- 1024x500 フィーチャーグラフィック
- スクリーンショット (5-8枚)
- プレビュー動画

# Content Rating
- 年齢制限: 4+ (Age appropriate)
- コンテンツ: ゲーム・パズル

# Store Listing
- 左記と同じ

# Privacy Policy URL
https://...

# Categories
- Games > Strategy
```

**特有項目**:
- **Privacy Manifest**: プラッシボード用コード追加
- **Google Play Policies**: ガイドライン確認

---

### タスク 4b-3: プライバシーポリシー作成

**ファイル**: `docs/privacy_policy.md`

**必須記載項目**:

```markdown
# プライバシーポリシー

## 1. 収集データ
- Firebase Analytics: ゲームプレイイベント
- Firebase Auth: メールアドレス（オプション）
- Firestore: 対局ログ・ユーザー名（匿名化）
- Cloud Storage: ハイライト動画（30日自動削除）

## 2. データ使用目的
- ゲーム体験改善
- KPI分析（DAU・セッション時間など）
- バグ修正・パフォーマンス改善

## 3. 第三者提供
- Firebase（Google） - 暗号化送信
- Bitly（URL短縮） - 匿名化

## 4. セキュリティ
- Firestore SSL/TLS
- Cloud Storage アクセス制限（認証ユーザーのみ）
- データ暗号化（保存時）

## 5. データ保持期限
- Analytics: 14個月自動削除
- ハイライト動画: 30日自動削除
- Firestore: ユーザー削除時に削除

## 6. ユーザー権利
- データアクセス要求可能
- データ削除権（右を行使可能）

## 7. お問い合わせ
support@rambusgame.jp
```

**注意点**:
- GDPR 準拠（EU ユーザー向け）
- 日本語版は日本法準拠
- プライバシー/セキュリティポリシーは分離ファイル

---

### タスク 4b-4: 利用規約作成

**ファイル**: `docs/terms_of_service.md`

**必須セクション**:

```markdown
# 利用規約

## 1. 定義
- 本サービス: 乱舞将棋アプリケーション
- ユーザー: 本サービス利用者

## 2. 利用ライセンス
- 個人非商用利用のみ
- 複製・改変・再配布禁止

## 3. 免責事項
- 「現状有姿」で提供
- バグ・エラーについて責任を負わない
- サービス停止時について責任を負わない

## 4. 禁止行為
- AI 学習データとしての使用
- 不正アクセス
- スクレイピング
- 著作権侵害

## 5. ハイライト動画共有
- 生成動画の利用は本サービス内のみ
- 外部サイトでの商用利用禁止

## 6. 有料機能
- 購入後、キャンセル・払戻なし
- プラットフォーム規約に従う

## 7. 管理者権利
- サービス内容変更
- ユーザーアカウント停止権

## 8. 準拠法
- 日本法

## 9. 施行日
- 2026-09-01 施行
```

---

### タスク 4b-5: セキュリティチェックリスト

**ファイル**: `docs/security_checklist.md`

**実装確認項目**:

```markdown
# セキュリティチェックリスト

## Firebase セキュリティルール

### Firestore ルール
- [ ] 認証ユーザーのみ読み取り可
  ```
  match /users/{userId} {
    allow read, write: if request.auth.uid == userId;
  }
  ```
- [ ] 公開データと非公開データ分離
  ```
  match /games/{gameId} {
    allow read: if true;  // 公開
    allow write: if request.auth.uid == resource.data.playerId;
  }
  ```

### Storage ルール
- [ ] ハイライト動画は認証ユーザーのみ
  ```
  match /highlights/{userId}/{allPaths=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ```

## データ暗号化

- [x] Firestore: Google Cloud Platform 側で自動暗号化
- [x] Cloud Storage: HTTPS 転送 + サーバー側暗号化
- [x] Transit: 全通信 SSL/TLS

## Authentication

- [x] Firebase Auth: Email/Password + Anonymous ログイン
- [x] シッション管理: Firebase が自動処理
- [x] CORS: Firebase Hosting で自動配置

## API キー管理

- [ ] Bitly API キー: `.env.local` に格納（Git に含めない）
- [ ] Firebase キー: `google-services.json` は Git ignore
- [ ] Cloud Functions: 環境変数で注入

## ネットワークセキュリティ

- [x] HTTPS 強制
- [ ] Certificate Pinning (オプション・高レベル)
- [x] DNS over HTTPS (DoH) 対応

## コード品質

- [ ] 依存パッケージ: pub.dev で検証（脆弱性なし）
  - `flutter pub outdated` で確認
- [ ] 暗号化ライブラリ: `crypto` パッケージ（公式推奨）

## プライバシー

- [ ] Analytics: 個人識別情報 (PII) を含めない
- [ ] ハイライト動画: 自動削除 30日確認
- [ ] ログ: 機密情報（パスワード・トークン）を含めない

## インシデント対応

- [ ] セキュリティ問題報告先: security@rambusgame.jp
- [ ] 対応SLA: 24時間以内確認
- [ ] パッチ適用体制: 準備完了

## コンプライアンス

### 日本
- [x] 特定商取引法: 表記ページ準備
- [x] 景表法: 広告表現検証

### 国際
- [x] GDPR (EU): プライバシーポリシー準拠
- [x] CCPA (California): オプトアウト機能検討

---

## 本番前チェック

- [ ] 全テスト実行完了
- [ ] 本番環境への最終アクセス確認
- [ ] バックアップ戦略確認
- [ ] ホットフィックスプロセス確認
```

---

## 📸 スクリーンショット準備

### 5枚の主要スクリーン

| # | 画面 | 説明 | 解像度 |
|---|------|------|--------|
| 1 | ホーム | メニュー・ゲーム開始ボタン | 1080x1920 |
| 2 | ゲーム盤面 | 駒の配置・HP表示 | 1080x1920 |
| 3 | クリティカル | 飛び道具着弾・相手HP0 | 1080x1920 |
| 4 | ハイライト | 動画プレビュー + 再生ボタン | 1080x1920 |
| 5 | シェア | Bitly URL + SNS ボタン | 1080x1920 |

**撮影手順**:
```bash
# iOS シミュレータ
open -a Simulator
# Android エミュレータ
emulator -avd Pixel_4_API_30
# フローター実行
flutter run
# スクショ保存
xcrun simctl io booted screenshot ~/Desktop/screen_1.png
```

---

## 🎬 プレビュー動画（15秒）

**構成**:
```
0-3秒:   タイトル＆オンボーディング画面
3-8秒:   ゲーム盤面・通常着手
8-12秒:  飛び道具クリティカル演出
12-15秒: ハイライト動画共有画面
```

**技術要件**:
- 解像度: 1920x1080 (16:9) or 1080x1920 (9:16)
- コーデック: H.264 / AAC
- ファイルサイズ: 50MB 以下
- フレームレート: 30fps

**作成方法**:
```bash
# FFmpeg を使用
ffmpeg -f image2 -i screenshot_%02d.png \
  -vf scale=1920:1080 \
  -c:v libx264 -preset medium \
  -c:a aac -b:a 128k \
  preview.mp4

# または iOS 画面録画 → Quicktime → MP4
```

---

## 📝 メタデータ言語対応

### 初版（2026-09-01）
- 日本語版のみ
- 英語版は後続バージョンで追加予定

### 日本語翻訳チェック
```
App Name:        乱舞将棋  ✅
Subtitle:        HP制で観戦映えする将棋バリアント  ✅
Description:     (確認中)
Keywords:        将棋, ゲーム, ボードゲーム, AI, 配信  ✅
Support URL:     日本語ページへ  ✅
Privacy URL:     日本語ポリシーへ  ✅
```

---

## ✅ Phase 4b チェックリスト

### メタデータ作成
- [ ] App Store メタデータ作成完了
- [ ] Google Play メタデータ作成完了
- [ ] 日本語版ローカライズ確認
- [ ] 英語版翻訳（機械翻訳OK・人間確認推奨）

### 法務・コンプライアンス
- [ ] プライバシーポリシー作成完了
- [ ] 利用規約作成完了
- [ ] セキュリティチェックリスト完了
- [ ] 法務レビュー完了（オプション）

### メディア準備
- [ ] スクリーンショット 5枚撮影完了
- [ ] プレビュー動画 15秒作成完了
- [ ] 画像フォーマット確認（PNG/JPG）
- [ ] ファイルサイズ確認（App Store max 2MB/枚）

### App Store Connect
- [ ] アプリ情報入力完了
- [ ] メタデータ入力完了
- [ ] ビルド番号設定完了
- [ ] テストアカウント作成完了

### Google Play Console
- [ ] アプリ情報入力完了
- [ ] コンテンツレーティング質問回答完了
- [ ] プライバシーマニフェスト設定完了
- [ ] プライバシー許可一覧設定完了

---

## 📊 提出前最終チェック

| 項目 | 確認 | 備考 |
|------|------|------|
| アプリ署名 | iOS: App Store | Android: Play Store |
| ビルド | Release モード | flutter build ios/apk |
| テスト | 実機テスト | 全機能確認 |
| クラッシュ | Fabric/Crashlytics | 0件 |
| レビュー | 人間確認 | 30分以上 |

---

## 🚀 提出スケジュール

**Day 1 (提出前日)**:
- [ ] 最終テスト実行
- [ ] メタデータ最終チェック
- [ ] スクショ最終確認

**Day 2 (提出日)**:
- [ ] App Store Connect に提出
- [ ] Google Play Console に提出
- [ ] 両ストア「審査中」ステータス確認

**Day 3-5 (審査期間)**:
- App Store: 24-48時間（平均）
- Google Play: 数時間～24時間（平均）
- 審査中の質問に対応可能な体制を整備

---

## 📞 よくある質問（FAQ）

### Q: 日本語オンリーで大丈夫？
**A**: 初版は OK。ただし将来的には英語対応推奨（海外ユーザー拡大時）

### Q: スクリーンショットはいくつ必要？
**A**: 最低 2枚、推奨 5枚、最大 10枚（App Store は 8枚まで）

### Q: プレビュー動画は必須？
**A**: iOS: オプション、Android: オプション。ただし CV（コンバージョン率）+15-20% の実績あり

### Q: リジェクトされたら？
**A**: ストアから理由が届く → コードまたはメタデータ修正 → 再提出（平均 48時間後）

---

## 📚 参考リンク

### App Store
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Google Play
- [Google Play Console Help](https://support.google.com/googleplay/)
- [Google Play Policies](https://play.google.com/about/developer-content-policy/)

### セキュリティ
- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [OWASP Top 10 Mobile](https://owasp.org/www-project-mobile-top-10/)

---

**Last Updated**: 2026-08-27  
**Status**: Phase 4b 計画立案完了 📋 → 実装開始へ
