# APK ビルドガイド - 乱舞将棋

**対象**: 本番環境への APK ビルド  
**ビルドタイプ**: Release APK（App Store / Google Play 提出用）  
**推奨環境**: macOS / Linux / Windows + Android SDK

---

## 📋 前提条件

以下が整っていることを確認してください：

### 1. Flutter SDK インストール
```bash
# Flutter SDK がインストール済みか確認
flutter --version

# 未インストールの場合
# https://flutter.dev/docs/get-started/install からダウンロード
# または Homebrew (macOS):
brew install flutter

# インストール後
flutter doctor -v  # 依存関係確認
```

### 2. Android SDK セットアップ
```bash
# Android SDK がインストール済みか確認
flutter doctor -v | grep -A 10 "Android toolchain"

# 必要なコンポーネント：
#  ✅ Android SDK Platform 33 以上
#  ✅ Android Build Tools 33.0.0 以上
#  ✅ Android Emulator（テスト用・オプション）

# セットアップが不完全の場合
flutter pub get
flutter clean
flutter doctor --android-licenses  # ライセンス同意
```

### 3. プロジェクト依存関係
```bash
cd /path/to/rambu_shogi
flutter pub get
flutter pub upgrade
```

### 4. Firebase 設定確認
```bash
# android/app/google-services.json が存在するか確認
ls -la android/app/google-services.json

# 未存在の場合：
# 1. Firebase Console > プロジェクト設定
# 2. Android アプリを追加
# 3. google-services.json をダウンロード
# 4. android/app/ に配置
```

---

## 🚀 APK ビルド手順

### ステップ 1: ビルド環境検証

```bash
flutter clean
flutter pub get
flutter analyze  # 静的解析
flutter test     # ユニットテスト実行

# エラーがないことを確認
```

### ステップ 2: キーストア準備（初回のみ）

Android アプリに署名するためのキーストアを作成します。

#### 2a. キーストア生成
```bash
# キーストア格納ディレクトリ作成
mkdir -p ~/.android_keys

# キーストア生成（対話形式）
keytool -genkey -v \
  -keystore ~/.android_keys/rambu_shogi.keystore \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10950 \
  -alias rambu_shogi

# 対話形式で以下を入力：
# Keystore Password:      [安全なパスワード]
# Key Password:           [キーパスワード]
# CN (First/Last Name):   Rambu Shogi
# OU (Organization Unit): Rambu
# O (Organization):       Rambu Shogi Project
# L (City/Locality):      Tokyo
# ST (State/Province):    Tokyo
# C (Country Code):       JP
```

#### 2b. キーストア情報をプロジェクトに登録
```bash
# android/key.properties を作成
cat > android/key.properties << EOF
storePassword=<キーストア作成時に入力したパスワード>
keyPassword=<キーパスワード>
keyAlias=rambu_shogi
storeFile=~/.android_keys/rambu_shogi.keystore
EOF

# パーミッション設定（git管理対象外）
chmod 600 android/key.properties
# git管理対象外に追加
echo "android/key.properties" >> .gitignore
```

#### 2c. android/app/build.gradle を編正
```gradle
// android/app/build.gradle の android {} ブロック内に追加

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... 既存設定 ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? 
                file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### ステップ 3: APK ビルド実行

```bash
# Release APK ビルド
flutter build apk --release

# 出力: build/app/outputs/flutter-apk/app-release.apk

# 複数 ABI 対応 APK（推奨：ファイルサイズ削減）
flutter build apk --release --split-per-abi

# 出力:
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### ステップ 4: ビルド検証

```bash
# ファイルサイズ確認
ls -lh build/app/outputs/flutter-apk/app-*release.apk

# APK の有効性チェック（オプション）
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# インストール・テスト（オプション）
flutter install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 AAB ビルド（Google Play 提出用・推奨）

Google Play 推奨は APK ではなく **AAB（Android App Bundle）** です。

```bash
# AAB ビルド
flutter build appbundle --release

# 出力: build/app/outputs/bundle/release/app-release.aab

# ファイルサイズ確認
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**AAB のメリット**:
- ファイルサイズが APK より小さい（自動最適化）
- Google Play が対応デバイス別に APK を自動生成
- Dynamic Feature Module をサポート

---

## 🔍 トラブルシューティング

### Issue: "keytool: command not found"
**解決**:
```bash
# Java Development Kit (JDK) をインストール
# macOS:
brew install openjdk

# Linux:
sudo apt-get install openjdk-11-jdk-headless

# Windows:
# https://www.oracle.com/java/technologies/downloads/ からダウンロード

# PATH に追加
export PATH="$(brew --prefix openjdk)/bin:$PATH"  # macOS
```

### Issue: "Gradle build failed"
**解決**:
```bash
# キャッシュをクリア＋再ビルド
flutter clean
flutter pub get
rm -rf build/
flutter build apk --release -v  # 詳細ログ表示
```

### Issue: "google-services.json が見つからない"
**解決**:
```bash
# Firebase Console から再度ダウンロード
# 1. Firebase Console: プロジェクト設定
# 2. Android アプリ設定
# 3. google-services.json をダウンロード
# 4. android/app/ に配置
```

### Issue: "キーストアファイルが見つからない"
**解決**:
```bash
# key.properties が正しいパスを指しているか確認
cat android/key.properties

# 絶対パスを使用することを推奨
# 例: storeFile=/Users/username/.android_keys/rambu_shogi.keystore
```

### Issue: APK サイズが大きすぎる
**解決**:
```bash
# Split-per-ABI でサイズ削減
flutter build apk --release --split-per-abi

# または AAB を使用（Google Play 推奨）
flutter build appbundle --release
```

---

## ✅ ビルド成功確認

### Android デバイスでテスト

```bash
# USB デバッグが有効なデバイスに接続
flutter devices  # 接続されたデバイス確認

# APK をインストール・実行
flutter install build/app/outputs/flutter-apk/app-release.apk

# または
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.rambusgame.shogi/.MainActivity
```

### ストア提出前の最終チェック

```bash
# Firebase Analytics が正常に動作しているか
# → Firebase Console > Analytics > ダッシュボード で確認

# Crashlytics が正常に動作しているか
# → Firebase Console > Crashlytics > ダッシュボード で確認

# Remote Config が取得可能か
# → Firestore > config/launch_config ドキュメント確認

# ハイライト生成が動作するか
# → アプリで 1 局プレイ → ハイライト自動生成確認
```

---

## 📋 提出用 APK チェックリスト

### App Store（iOS）の場合
```
注）iOS は APK ではなく IPA ビルドが必要です

# IPA ビルド
flutter build ios --release

# さらに Xcode でコード署名が必要
# 参考: docs/security_checklist.md > iOS コード署名手順
```

### Google Play（Android）の場合
```bash
✅ チェックリスト:
  [ ] AAB（アプリバンドル）がビルド成功
  [ ] APK サイズが 100MB 以下（Google Play 要件）
  [ ] ファイル署名が正しい（keytool で確認）
  [ ] google-services.json が含まれている
  [ ] version code がインクリメント済み (pubspec.yaml)
  [ ] minSdkVersion ≥ 21
  [ ] targetSdkVersion ≥ 31

# 最終確認
ls -lh build/app/outputs/bundle/release/app-release.aab
file build/app/outputs/bundle/release/app-release.aab
```

---

## 🔐 セキュリティ注意事項

### キーストア管理
```
⚠️ 重要:
  • キーストア（.keystore）は絶対に git に含めない
  • 安全な場所（~/.android_keys など）に保管
  • パスワードは安全に管理（パスワード管理ツール推奨）
  • key.properties は git/Version Control に含めない
```

### ビルド成果物管理
```
✅ git に含める:
  - pubspec.yaml, pubspec.lock
  - lib/ (Dart ソースコード)
  - android/ (build.gradle など)

❌ git に含めない:
  - build/
  - android/key.properties
  - .android_keys/
  - google-services.json（個人の Firebase プロジェクトの場合）
```

---

## 📞 ビルド失敗時の対応

| エラー | 原因 | 対応 |
|------|------|------|
| `Gradle build failed` | 依存関係の競合 | `flutter clean && flutter pub get` |
| `Signing failed` | キーストア設定エラー | key.properties を確認 |
| `APK too large` | 最適化不足 | `--split-per-abi` で分割 |
| `Firebase SDK error` | google-services.json 不在 | Firebase Console で再作成 |
| `Memory error` | ビルドメモリ不足 | `gradle.properties` で heap size 増加 |

---

## 🚀 推奨ビルドコマンド（本番用）

```bash
# 本番環境用 AAB ビルド（推奨）
flutter build appbundle --release

# または APK の場合（複数 ABI）
flutter build apk --release --split-per-abi

# ビルド完了後：
# • google-services.json が含まれていることを確認
# • ファイルが署名済みであることを確認（keytool）
# • Firebase にテストインストール
# • ハイライト生成、Remote Config 動作確認
# • App Store / Google Play にアップロード
```

---

## 📝 CI/CD パイプライン（Advanced）

GitHub Actions で自動ビルドを設定する場合：

```yaml
# .github/workflows/build-apk.yml
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.x'
      - run: flutter pub get
      - run: flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v3
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/
```

参考: `.github/workflows/` ディレクトリ

---

## 🎯 次のステップ

1. ✅ ローカル環境で APK ビルド実行
2. ✅ Android デバイスでテスト
3. ✅ ハイライト生成・Remote Config 動作確認
4. ✅ AAB / APK を Google Play Console にアップロード
5. ✅ App Store（iOS 版）の IPA ビルド・提出

---

**最終更新**: 2026-08-28  
**次ステップ**: ローカル環境での APK ビルド実行
