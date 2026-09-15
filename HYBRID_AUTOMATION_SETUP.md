# ハイブリッド自動化セットアップガイド

**目標**: ビルドからストア提出まで、**5～8分で完全自動化**

---

## 🎯 3つの実行方法

### 1️⃣ **ローカル開発時** - シンプル実行
```bash
npm run deploy:release
```
✅ 自動実行内容:
- APK/AAB ビルド
- Firebase デプロイ
- Firestore config 更新
- Google Play Console にアップロード（ドラフト）
- 最終確認プロンプト

### 2️⃣ **CI/CD パイプライン** - 完全自動化
```bash
git tag v1.0.1
git push origin v1.0.1
```
✅ GitHub Actions が自動実行:
- ビルド
- テスト
- Firebase デプロイ
- Google Play アップロード
- Slack 通知

### 3️⃣ **手動トリガー** - GitHub の UI から
```
GitHub > Actions > Release Build & Deploy > Run workflow
```

---

## 📋 セットアップ手順

### ステップ 1: 環境変数設定

```bash
# .env.example から .env を作成
cp .env.example .env

# エディタで編集
nano .env
```

以下を設定:
```bash
KEYSTORE_PASSWORD=your_password
KEY_PASSWORD=your_key_password
FIREBASE_PROJECT_ID=rambusgame-prod
```

### ステップ 2: キーストア準備

```bash
# キーストア作成（初回のみ）
mkdir -p ~/.android_keys
keytool -genkey -v \
  -keystore ~/.android_keys/rambu_shogi.keystore \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -alias rambu_shogi

# 確認
ls -la ~/.android_keys/rambu_shogi.keystore
```

### ステップ 3: Google Play Console 設定

#### 3a. Service Account 作成
```
1. Google Cloud Console > IAM and Admin > Service Accounts
2. 「Create Service Account」
3. 名前: "GitHub-Actions-Deploy"
4. 権限: "Editor"
5. キーを作成 (JSON) → service-account-key.json
```

#### 3b. Google Play Console で権限付与
```
1. Google Play Console > 設定 > ユーザーとアクセス権
2. 新しいユーザーを招待
3. Service Account のメールアドレス: xxx@xxx.iam.gserviceaccount.com
4. 権限: 「管理者」を選択
```

### ステップ 4: GitHub Secrets 設定

```bash
# リポジトリ > Settings > Secrets and variables > Actions

以下を追加:
┌─────────────────────────────────────────────┐
│ GOOGLE_PLAY_SERVICE_ACCOUNT_JSON           │
│ (service-account-key.json の内容を JSON形式) │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ KEYSTORE_BASE64                            │
│ (base64 エンコード済みキーストア内容)       │
│                                             │
│ $ base64 ~/.android_keys/rambu_shogi.keystore │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ KEYSTORE_PASSWORD                          │
│ (キーストアのパスワード)                    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ KEY_PASSWORD                               │
│ (キーのパスワード)                         │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ GOOGLE_SERVICES_JSON (オプション)           │
│ (android/app/google-services.json)         │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ FIREBASE_SERVICE_ACCOUNT_JSON (オプション)  │
│ (Firebase CLI の認証用)                    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ SLACK_WEBHOOK_URL (オプション)              │
│ (Slack 通知用)                             │
└─────────────────────────────────────────────┘
```

### ステップ 5: npm/Node.js 導入（オプション）

```bash
# macOS
brew install node

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# npm スクリプト確認
npm run
```

### ステップ 6: Fastlane セットアップ（オプション）

```bash
# インストール
sudo gem install fastlane

# 初期化（自動で Fastfile が作成されます）
cd android
fastlane init

# テスト
fastlane android test_setup
```

---

## 🚀 実行方法

### パターン A: ローカルから実行（推奨・開発時）

```bash
cd ~/rambu_shogi

# 方法 1: npm スクリプト
npm run deploy:release

# 方法 2: bash スクリプト直接
bash scripts/deploy-release.sh

# 方法 3: Fastlane
cd android
fastlane android deploy_internal    # 内部テスト
fastlane android deploy_beta        # クローズドベータ
fastlane android deploy_production  # 本番（ドラフト）
```

### パターン B: GitHub Actions から実行（推奨・本番時）

```bash
# タグで自動トリガー
git tag v1.0.1
git push origin v1.0.1

# 確認
GitHub > Actions > Release Build & Deploy を監視
```

### パターン C: 手動トリガー

```
GitHub > Actions > Release Build & Deploy > Run workflow > Run workflow ボタン
```

---

## 📊 各実行方法の比較

| 方法 | 所要時間 | 手作業 | 推奨用途 |
|------|--------|------|--------|
| npm run deploy:release | 15-20分 | 最小限 | **開発・デバッグ** |
| GitHub Actions (tag) | 15-20分 | ワンクリック | **本番リリース** |
| Fastlane | 10-15分 | 最小限 | **頻繁なテスト** |
| 完全手動 | 30-40分 | 大量 | ❌ 非推奨 |

---

## 📋 実行フロー

### npm run deploy:release の流れ

```
1️⃣  環境チェック（2分）
    ✅ Flutter SDK
    ✅ Git リポジトリ
    ✅ キーストア
    ✅ 環境変数

2️⃣  依存関係インストール（3分）
    ✅ flutter pub get

3️⃣  解析・テスト（3分）
    ✅ flutter analyze
    ✅ flutter test

4️⃣  ビルド（8分）
    ✅ AAB ビルド
    ✅ APK ビルド（複数 ABI）

5️⃣  Firebase デプロイ（2分）
    ✅ Cloud Functions デプロイ
    ✅ Firestore config 更新

6️⃣  Google Play Console（1分）
    ✅ AAB アップロード（ドラフト）

7️⃣  最終確認（1分）
    ⏳ 手動レビュー準備

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合計: 20分
```

### GitHub Actions の流れ

```
push tag v1.0.1
    ↓
GitHub Actions 自動トリガー
    ↓
1️⃣  ビルド（8分）
2️⃣  テスト（3分）
3️⃣  Google Play アップロード（1分）
4️⃣  Firebase デプロイ（2分）
5️⃣  Slack 通知（1秒）
    ↓
✅ 完了メール受信
    ↓
Google Play Console で「リリース」をクリック（手動・1クリック）
```

---

## ✅ チェックリスト

### セットアップ前
- [ ] Flutter SDK インストール
- [ ] Git リポジトリ確認
- [ ] Node.js インストール（オプション）

### セットアップ時
- [ ] .env ファイル作成・設定
- [ ] キーストア作成 (~/.android_keys/rambu_shogi.keystore)
- [ ] Google Play Console Service Account 作成
- [ ] GitHub Secrets 設定（6つ）
- [ ] Fastlane セットアップ（オプション）

### 実行前
- [ ] .env ファイルが .gitignore に含まれているか確認
- [ ] キーストアが .gitignore に含まれているか確認
- [ ] Android build tools インストール確認
- [ ] Firebase CLI インストール確認（オプション）

### 実行後
- [ ] Google Play Console でドラフト確認
- [ ] Firestore config/launch_config ドキュメント確認
- [ ] Firebase Analytics が動作しているか確認
- [ ] ストア提出前に「リリース」ボタンをクリック

---

## 🔧 トラブルシューティング

### Issue: "KEYSTORE_PASSWORD: command not found"
**解決**: .env ファイルを作成して環境変数をセット
```bash
cp .env.example .env
source .env  # または export KEYSTORE_PASSWORD=...
```

### Issue: "google-services.json が見つからない"
**解決**: Firebase Console から再度ダウンロード
```bash
# Firebase Console > プロジェクト設定 > Google Play アプリ
# google-services.json をダウンロード → android/app/ に配置
```

### Issue: "GitHub Actions でビルド失敗"
**解決**: Secrets が正しく設定されているか確認
```bash
GitHub > Settings > Secrets and variables > Actions
→ GOOGLE_PLAY_SERVICE_ACCOUNT_JSON が base64 エンコードされているか確認
```

### Issue: "Google Play Console にアップロードできない"
**解決**: Service Account の権限確認
```bash
# Google Play Console > 設定 > ユーザーとアクセス権
# Service Account に「管理者」権限があるか確認
```

---

## 🎓 参考資料

| リソース | リンク | 用途 |
|---------|--------|------|
| APK ビルドガイド | `APK_BUILD_GUIDE.md` | ビルド詳細 |
| ストア提出ガイド | `PHASE_4_ACTION_SUMMARY.md` | 提出手順 |
| セキュリティチェック | `docs/security_checklist.md` | セキュリティ検証 |
| Google Play API | https://developers.google.com/play/developer-api | API リファレンス |
| Fastlane 公式 | https://docs.fastlane.tools/ | Fastlane ドキュメント |

---

## 🚀 今すぐ始める（クイックスタート）

```bash
# 1. 環境変数を設定
cp .env.example .env
nano .env  # KEYSTORE_PASSWORD, KEY_PASSWORD を入力

# 2. npm スクリプト実行
npm run deploy:release

# 3. Google Play Console で確認
→ Google Play Console > ドラフト確認 > 「リリース」クリック

完了！🎉
```

---

**最終更新**: 2026-08-28  
**次ステップ**: セットアップを実施して npm run deploy:release を実行
