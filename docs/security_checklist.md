# セキュリティチェックリスト

**バージョン**: 1.0  
**最終確認日**: 2026-08-27  
**対象**: 乱舞将棋 v1.0 本番環境（App Store / Google Play 提出前）

---

## 1. Firebase セキュリティ設定

### 1.1 Firestore Security Rules

#### データベース名: `rambusgame` (本番)

#### チェック項目

- [x] **ユーザーデータ隔離**
  ```dart
  match /users/{userId} {
    allow read, write: if request.auth.uid == userId;
  }
  ```
  確認: ユーザーが自分のデータにのみアクセス可能

- [x] **ゲームログの読み取り保護**
  ```dart
  match /games/{gameId} {
    allow read: if true;  // 統計用に公開読み取り許可
    allow write: if request.auth.uid == resource.data.playerId;
  }
  ```
  確認: ゲーム作成者のみが書き込み可能

- [x] **ハイライトデータの保護**
  ```dart
  match /highlights/{userId}/{allPaths=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ```
  確認: ユーザーのハイライトはそのユーザーのみアクセス

- [x] **Analytics イベントログの読み取り専用**
  ```dart
  match /analytics/{eventId} {
    allow read: if true;  // 統計分析のみ
    allow write: if false;  // 直接書き込み禁止（Firebase Analytics が書き込み）
  }
  ```

#### 確認方法
```bash
# Firebase Console > Firestore > Rules
# 上記の各ルールが正確に設定されていることを確認
firebase deploy --only firestore:rules --project rambusgame-prod
```

---

### 1.2 Firebase Authentication

#### チェック項目

- [x] **認証方式の限定**
  - ✅ 有効: Anonymous Login（ゲスト対応）
  - ✅ 有効: Email/Password（オプション）
  - ❌ 無効: Google Sign-In（初版は不要）
  - ❌ 無効: Facebook Login（初版は不要）

- [x] **パスワード要件**
  - 最小文字数: 6 字（Google デフォルト）
  - ❌ 複雑性要件: 不要（初版）

- [x] **セッション管理**
  - セッション有効期限: 1 時間（Google デフォルト）
  - セッション更新: 自動
  - ログアウト: ユーザーが明示的に実行

#### 確認方法
```bash
# Firebase Console > Authentication > Settings
# Sign-in providers が上記設定になっていることを確認
```

---

### 1.3 Cloud Storage Security Rules

#### バケット名: `rambusgame-highlights-prod`

#### チェック項目

- [x] **ハイライト動画の読み取り制限**
  ```
  match /highlights/{userId}/{allPaths=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ```
  確認: ユーザー本人のみが動画にアクセス可能

- [x] **公開動画（オプション）**
  ```
  match /public/{allPaths=**} {
    allow read: if true;  // 公開読み取り
    allow write: if false;  // 書き込みなし
  }
  ```

- [x] **HTTPS 強制**
  ```
  match /{allPaths=**} {
    allow read, write: if request.resource.contentType.startsWith("video/");
  }
  ```
  確認: 動画ファイルのみアップロード可能

#### 確認方法
```bash
# Firebase Console > Storage > Rules
# 上記の各ルールが設定されていることを確認
gsutil iam ch serviceAccount:rambusgame-functions@appspot.gserviceaccount.com:objectViewer gs://rambusgame-highlights-prod
```

---

### 1.4 Firebase Cloud Functions

#### チェック項目

- [x] **環境変数の暗号化**
  ```bash
  # 関数の環境変数に機密情報を含めない
  # .env.local ファイルは .gitignore に含める
  ```
  確認: Bitly API キーなど機密情報が Git コミットされていない

- [x] **実行権限の最小化**
  ```
  サービスアカウント: cloud-functions@rambusgame-prod.iam.gserviceaccount.com
  権限: Cloud Storage/Writer のみ
  ```
  確認: 必要最小限の権限に限定

- [x] **エラーログの安全性**
  ```bash
  # Firebase Functions ログに機密情報を含めない
  # パスワード・トークン・個人情報を避ける
  ```
  確認: console.log() に機密情報が含まれていない

- [x] **タイムアウト設定**
  ```javascript
  // functions/index.js
  functions.runWith({
    timeoutSeconds: 540,  // 最大 540 秒
    memory: '2GB'
  })
  ```
  確認: 適切なタイムアウト・メモリ制限が設定

#### 確認方法
```bash
# Firebase Console > Functions
# 各関数の詳細を確認
firebase deploy --only functions --project rambusgame-prod
firebase functions:log --project rambusgame-prod
```

---

## 2. データ暗号化

### 2.1 転送時の暗号化

#### チェック項目

- [x] **HTTPS/TLS の強制**
  ```dart
  // Firebase は自動的に HTTPS を使用
  // 全通信が TLS 1.3 で暗号化
  ```
  確認: `https://` で始まる URL のみを使用

- [x] **Certificate Pinning（オプション）**
  ```dart
  // 高度なセキュリティが必要な場合に検討
  // 初版は Firebase デフォルトの TLS で十分
  ```
  対象: ✅ Firestore, Cloud Storage, Cloud Functions
  対象外: Bitly（Trust on First Use）

#### 確認方法
```bash
# iOS
openssl s_client -connect rambusgame-prod.firebaseio.com:443 -tls1_3

# Android
curl -I https://rambusgame-prod.firebaseio.com
```

---

### 2.2 保存時の暗号化

#### チェック項目

- [x] **Firestore データの暗号化**
  ```
  Google Cloud Platform の自動暗号化が有効
  アルゴリズム: AES-256
  鍵管理: Google が管理（ユーザーは操作不可）
  ```
  確認: Firebase Console > Firestore > 保護設定 で "暗号化あり"

- [x] **Cloud Storage データの暗号化**
  ```
  バケット: rambusgame-highlights-prod
  暗号化: AES-256（Google 管理キー）
  ```
  確認: Firebase Console > Storage > ハイライト確認

- [x] **ログの暗号化**
  ```
  Firebase Crashlytics: 自動暗号化
  Cloud Logging: 自動暗号化
  ```

#### 確認方法
```bash
# Firebase Console > Settings > 暗号化設定
# 全データベースの暗号化ステータスを確認
gsutil encryption get gs://rambusgame-highlights-prod
```

---

## 3. アクセス制御

### 3.1 API キー・認証情報

#### チェック項目

- [x] **Bitly API キーの管理**
  ```dart
  // Flutter アプリ内にキーを含めない
  // Cloud Functions 環境変数に格納
  ```
  確認: `lib/services/share_link_service.dart` に API キーが埋め込まれていない

- [x] **Firebase 設定ファイルの管理**
  ```
  iOS: GoogleService-Info.plist → .gitignore
  Android: google-services.json → .gitignore
  Web: firebase-config.js → .gitignore
  ```
  確認: Git リポジトリに機密ファイルが含まれていない

- [x] **プロジェクト ID・パスワードの隔離**
  ```bash
  # 環境変数として管理
  export FIREBASE_PROJECT_ID="rambusgame-prod"
  export BITLY_API_KEY="<hidden>"
  ```

#### 確認方法
```bash
# Git に含まれているか確認
git log --all --full-history -- "**/GoogleService-Info.plist"
git log --all --full-history -- "**/google-services.json"

# 含まれていた場合は削除
git filter-branch --tree-filter 'rm -f **/GoogleService-Info.plist' -- --all
```

---

### 3.2 Role-Based Access Control (RBAC)

#### チェック項目

- [x] **ユーザー権限の区分**
  ```
  Anonymous ユーザー:
    - ゲームプレイ: ✅ 可
    - データ読み取り: ✅ 可（公開データのみ）
    - ハイライト生成: ✅ 可
    - ハイライト共有: ✅ 可

  登録ユーザー（メール認証）:
    - ゲームプレイ: ✅ 可
    - プロフィール編集: ✅ 可
    - データ削除: ✅ 可

  管理者ユーザー:
    - ユーザーデータ削除: ✅ 可
    - ゲーム統計閲覧: ✅ 可
  ```

#### 確認方法
```bash
# Firebase Console > Authentication > Users
# ユーザーのカスタムクレーム確認
```

---

## 4. ネットワークセキュリティ

### 4.1 CORS（Cross-Origin Resource Sharing）

#### チェック項目

- [x] **Firebase Hosting の CORS 設定**
  ```json
  {
    "hosting": {
      "public": "web",
      "headers": [
        {
          "source": "**",
          "headers": [
            {
              "key": "Access-Control-Allow-Origin",
              "value": "https://rambusgame.jp"
            }
          ]
        }
      ]
    }
  }
  ```

- [x] **Cloud Functions の CORS**
  ```javascript
  functions.https.onCall((data, context) => {
    // Callable Functions は CORS 対応
    // Firebase が自動的に処理
  });
  ```

#### 確認方法
```bash
# curl でテスト
curl -i -X OPTIONS https://rambusgame.jp/api/endpoint
# Access-Control-Allow-* ヘッダを確認
```

---

### 4.2 ネットワークセキュリティ設定

#### チェック項目

- [x] **Android Network Security Config**
  ```xml
  <!-- android/app/src/main/AndroidManifest.xml -->
  <domain-config cleartextTrafficPermitted="false">
    <domain includeSubdomains="true">rambusgame.jp</domain>
    <domain includeSubdomains="true">firebaseio.com</domain>
  </domain-config>
  ```
  確認: HTTP 通信が無効

- [x] **iOS App Transport Security (ATS)**
  ```plist
  <!-- ios/Runner/Info.plist -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
      <key>firebaseio.com</key>
      <dict>
        <key>NSExceptionAllowsInsecureHTTPLoads</key>
        <false/>
      </dict>
    </dict>
  </dict>
  ```
  確認: HTTPS 強制

#### 確認方法
```bash
# iOS
plutil -p ios/Runner/Info.plist | grep -A 5 NSAppTransportSecurity

# Android
grep -A 5 "domain-config" android/app/src/main/AndroidManifest.xml
```

---

## 5. コード品質とセキュリティ分析

### 5.1 依存パッケージの脆弱性チェック

#### チェック項目

- [x] **Dart/Flutter パッケージの確認**
  ```bash
  flutter pub upgrade
  flutter pub outdated  # 最新バージョン確認
  ```
  確認: 脆弱性のあるパッケージなし

- [x] **Node.js パッケージの確認**
  ```bash
  npm audit  # 脆弱性スキャン
  npm update  # 安全なバージョンに更新
  ```
  確認: High/Critical 脆弱性なし

#### 確認方法
```bash
# Dart
flutter pub get
flutter pub audit

# Node.js (functions/)
cd functions && npm audit --audit-level=moderate
```

---

### 5.2 OWASP Top 10 Mobile 対応

#### チェック項目

| # | 項目 | 対応状況 | 確認 |
|---|------|---------|------|
| 1 | Improper Platform Usage | ✅ | Flutter 最新版使用 |
| 2 | Insecure Data Storage | ✅ | Firestore 暗号化有効 |
| 3 | Insecure Communication | ✅ | HTTPS/TLS 強制 |
| 4 | Insecure Authentication | ✅ | Firebase Auth 使用 |
| 5 | Insufficient Cryptography | ✅ | AES-256 使用 |
| 6 | Insecure Authorization | ✅ | Firestore Rules 設定 |
| 7 | Client Code Quality | ✅ | 定期的なコード審査 |
| 8 | Code Tampering | ✅ | App Signing 有効 |
| 9 | Reverse Engineering | ✅ | Obfuscation 有効 |
| 10 | Extraneous Functionality | ✅ | デバッグ機能削除 |

---

## 6. アプリ署名とリリースビルド

### 6.1 iOS アプリ署名

#### チェック項目

- [x] **Distribution Certificate**
  ```bash
  # Xcode > Settings > Accounts > Team
  # Distribution Certificate が存在・有効確認
  ```
  確認: 2026-09-01 以降も有効

- [x] **App Store Signing**
  ```bash
  # Xcode > Build Settings > Code Signing
  # Signing Certificate: iPhone Distribution
  # Provisioning Profile: App Store
  ```

- [x] **Release ビルド**
  ```bash
  flutter build ios --release
  # アプリが署名されていることを確認
  codesign -v build/ios/iphoneos/Runner.app
  ```

#### 確認方法
```bash
# 署名情報の確認
codesign -dv build/ios/iphoneos/Runner.app

# App Store 提出
# Xcode > Product > Archive
```

---

### 6.2 Android アプリ署名

#### チェック項目

- [x] **Keystore ファイル**
  ```bash
  # keystore ファイル: ~/.android/release.keystore
  # パスワード: .env.local に記録（Git 除外）
  ```
  確認: Keystore ファイルが安全に保管

- [x] **Release ビルド**
  ```bash
  flutter build apk --release
  # または
  flutter build appbundle --release
  ```
  確認: APK/AAB が署名済み

- [x] **Play App Signing**
  ```
  Google Play Console > Release > Setup
  状態: "App Signing by Google Play" 有効
  ```

#### 確認方法
```bash
# 署名情報の確認
jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab

# Google Play に提出
# Google Play Console > Release > Production
```

---

## 7. ユーザーデータ保護

### 7.1 個人情報の最小化

#### チェック項目

- [x] **収集データの最小化**
  ```dart
  // 収集: Device ID, Game Events, Anonymous User ID
  // 未収集: 位置情報, 連絡先, 生年月日, 支払い情報
  ```
  確認: 不要な個人情報を収集していない

- [x] **データ保持期限の設定**
  ```
  Analytics: 14 ヶ月自動削除
  ハイライト: 30 日自動削除
  Crashlytics: 90 日自動削除
  ```
  確認: 長期保持データなし

#### 確認方法
```bash
# Firebase Console > Project Settings > Data retention
# 削除ポリシー確認
```

---

### 7.2 データの匿名化・仮名化

#### チェック項目

- [x] **User ID の匿名化**
  ```dart
  // User ID は UUID（ランダム文字列）
  // 個人識別情報への直結なし
  ```
  確認: Firebase Analytics では Advertising ID / User ID を個人識別に使用していない

- [x] **ゲームデータの仮名化**
  ```dart
  // ゲーム統計はユーザー ID でのみ結合
  // ユーザー名・メールアドレスと分離
  ```

#### 確認方法
```bash
# Firebase Console > Analytics > Data retention
# 匿名化設定確認
```

---

## 8. プライバシー関連

### 8.1 データ収集の透明性

#### チェック項目

- [x] **プライバシーポリシーの掲示**
  ```
  URL: https://rambusgame.jp/privacy
  内容: 収集データ・使用目的・保持期間・削除方法を明記
  ```

- [x] **App Store / Google Play での記載**
  ```
  App Store: "App Privacy"
  Google Play: "Data Safety"
  各項目を正確に記載
  ```

#### 確認方法
```bash
# App Store Connect > App Information > App Privacy
# 記載内容がプライバシーポリシーと一致確認
```

---

### 8.2 GDPR / CCPA 対応

#### チェック項目

- [x] **GDPR 対応**
  ```
  EU ユーザーの権利:
  - アクセス権: データ要求ページで対応
  - 削除権: アカウント削除で自動実施
  - 異議権: support@rambusgame.jp で対応
  ```

- [x] **CCPA 対応**
  ```
  California ユーザーの権利:
  - Know Right: プライバシーポリシーで開示
  - Delete Right: アカウント削除で実施
  - Opt-Out: トラッキング回避設定
  ```

#### 確認方法
```bash
# GDPR 要求テスト
# support@rambusgame.jp に "GDPR Request" と送信
# 30 日以内にデータを提供できるか確認
```

---

## 9. セキュリティインシデント対応

### 9.1 インシデント報告プロセス

#### チェック項目

- [x] **セキュリティ報告先**
  ```
  メール: security@rambusgame.jp
  対応 SLA: 24 時間以内に初期対応
  ```

- [x] **対応チェックリスト**
  ```
  1. インシデント検知（Crashlytics ・ログ）
  2. 重要度評価（High / Medium / Low）
  3. 初期対応（ホットフィックス検討）
  4. ユーザー通知（必要に応じて）
  5. 根本原因分析（事後報告書）
  ```

#### 確認方法
```bash
# Crashlytics で異常を検知できるか
firebase functions:log --project rambusgame-prod | grep -i "error"
```

---

### 9.2 脆弱性管理

#### チェック項次

- [x] **定期セキュリティアップデート**
  ```bash
  # 毎月第1週 に依存パッケージをアップデート
  flutter pub upgrade
  npm update
  
  # アップデート後、テストを再実行
  ```

- [x] **脆弱性スキャン**
  ```bash
  # GitHub Dependabot による自動スキャン（有効）
  # 脆弱性が検出されたら即座に対応
  ```

#### 確認方法
```bash
# GitHub > Settings > Code security > Dependabot
# Dependabot alerts が有効確認
```

---

## 10. ログ・監視

### 10.1 監査ログ

#### チェック項目

- [x] **Firestore アクセスログ**
  ```bash
  # Cloud Logging で記録
  # 重要操作（削除など）を監視
  ```

- [x] **Cloud Functions 実行ログ**
  ```bash
  firebase functions:log --project rambusgame-prod
  # エラー・重要イベントを記録
  ```

#### 確認方法
```bash
# Cloud Logging で検索
gcloud logging read "resource.type=cloud_functions" \
  --project=rambusgame-prod \
  --limit=100
```

---

### 10.2 セキュリティイベント監視

#### チェック項目

- [x] **Firebase Security Alerts**
  ```
  有効: Anomalous Sign-in Activity
  有効: Mass Download of Data
  有効: Bulk Deletion of Data
  ```

- [x] **Cloud Audit Logs**
  ```
  記録: 管理者アクティビティ
  記録: データアクセス（Firestore）
  ```

#### 確認方法
```bash
# Firebase Console > Security > Security Alerts
# アラート設定確認
```

---

## 11. 本番環境の分離

### 11.1 環境の区分

#### チェック項目

- [x] **開発環境**
  ```
  Project ID: rambusgame-dev
  Firestore: rambusgame-dev/firestore
  Storage: rambusgame-dev-highlights
  ```

- [x] **ステージング環境**
  ```
  Project ID: rambusgame-staging
  Firestore: rambusgame-staging/firestore
  Storage: rambusgame-staging-highlights
  ```

- [x] **本番環境**
  ```
  Project ID: rambusgame-prod
  Firestore: rambusgame-prod/firestore
  Storage: rambusgame-prod-highlights
  ```

#### 確認方法
```bash
# Firebase Project 確認
firebase projects:list

# アクティブプロジェクト確認
firebase use --add rambusgame-prod
```

---

## 12. 提出前最終チェックリスト

### 12.1 iOS 提出前確認

- [ ] Xcode: Signing Certificate が有効
- [ ] Xcode: Provisioning Profile が App Store 用
- [ ] Build Number がインクリメント (1 → 2)
- [ ] Build Settings: Release Mode
- [ ] Entitlements: 不要な機能を削除
- [ ] App Privacy で収集データを正確に記載
- [ ] GoogleService-Info.plist が含まれていない
- [ ] テスト用コード・デバッグ出力がない

### 12.2 Android 提出前確認

- [ ] Keystore: 正しいリリース Keystore を使用
- [ ] Build: Release APK / AAB を生成
- [ ] version Code / version Name をインクリメント
- [ ] Manifest: デバッグ機能を削除
- [ ] Data Safety: 収集データを正確に記載
- [ ] google-services.json が .gitignore に含まれている
- [ ] ProGuard/R8: Minification が有効
- [ ] テスト用コードがない

### 12.3 両プラットフォーム共通

- [ ] Secrets の環境変数化確認
- [ ] HTTPS/TLS 設定確認
- [ ] Firestore Rules が本番用に設定
- [ ] API キーが環境変数で管理
- [ ] クラッシュレポート・ロギングが機能
- [ ] Firebase アップデート完了
- [ ] プライバシーポリシー URL が有効
- [ ] セキュリティインシデント報告先がある

---

## 13. 承認署名

### 本番環境への提出承認

| 項目 | 担当者 | 確認日 | 署名 |
|------|--------|--------|------|
| セキュリティ設定 | DevOps | 2026-08-27 | ☐ |
| データ保護 | プライバシー | 2026-08-27 | ☐ |
| コード品質 | QA | 2026-08-27 | ☐ |
| リリース準備 | PM | 2026-08-27 | ☐ |

---

**最終確認日**: 2026-08-27  
**提出予定日**: 2026-09-01  
**ステータス**: 提出前チェック完了待ち

---

## 参考リンク

- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Developer Policy](https://play.google.com/about/developer-content-policy/)
- [GDPR Official](https://gdpr-info.eu/)
- [CCPA Official](https://oag.ca.gov/privacy/ccpa)
