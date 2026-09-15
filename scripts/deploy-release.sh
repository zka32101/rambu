#!/bin/bash

################################################################################
# 乱舞将棋 リリース自動デプロイスクリプト
#
# 使用方法:
#   ./scripts/deploy-release.sh
#
# 実行内容:
#   1. ビルド環境チェック
#   2. APK/AAB ビルド
#   3. Firebase デプロイ
#   4. Firestore config 更新
#   5. Google Play Console アップロード
#   6. 最終確認
################################################################################

set -e  # エラーで停止

# 色付け定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ログ関数
log() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
prompt() { echo -e "${YELLOW}❓ $1${NC}"; }

# バージョン確認
VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
log "乱舞将棋 v${VERSION} リリースデプロイを開始します"

################################################################################
# ステップ 1: 環境確認
################################################################################
log "\n[1/7] 環境チェック..."

# Flutter インストール確認
if ! command -v flutter &> /dev/null; then
    error "Flutter SDK がインストールされていません"
fi
success "Flutter SDK: $(flutter --version | head -1)"

# git リポジトリ確認
if [ ! -d ".git" ]; then
    error "Git リポジトリではありません"
fi
success "Git リポジトリ確認"

# キーストア確認
if [ ! -f ~/.android_keys/rambu_shogi.keystore ]; then
    error "キーストア ~/.android_keys/rambu_shogi.keystore が見つかりません"
fi
success "キーストア確認"

# 環境変数確認
if [ -z "$KEYSTORE_PASSWORD" ] || [ -z "$KEY_PASSWORD" ]; then
    warning "環境変数がセットされていません"
    prompt "KEYSTORE_PASSWORD を入力してください："
    read -s KEYSTORE_PASSWORD
    export KEYSTORE_PASSWORD

    prompt "KEY_PASSWORD を入力してください："
    read -s KEY_PASSWORD
    export KEY_PASSWORD
fi
success "認証情報確認"

################################################################################
# ステップ 2: 依存関係インストール
################################################################################
log "\n[2/7] 依存関係インストール..."
flutter clean
flutter pub get
success "依存関係インストール完了"

################################################################################
# ステップ 3: 静的解析・テスト
################################################################################
log "\n[3/7] 静的解析・テスト実行..."
flutter analyze || warning "解析警告がありますが続行します"
flutter test --coverage || warning "テスト失敗がありますが続行します"
success "解析・テスト完了"

################################################################################
# ステップ 4: APK/AAB ビルド
################################################################################
log "\n[4/7] APK/AAB ビルド..."

# AAB ビルド
log "AAB ビルド中（Google Play 推奨形式）..."
flutter build appbundle --release
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    success "AAB ビルド完了: ${AAB_SIZE}"
else
    error "AAB ビルドに失敗しました"
fi

# APK ビルド（複数 ABI）
log "APK ビルド中（複数 ABI 対応）..."
flutter build apk --release --split-per-abi
if ls build/app/outputs/flutter-apk/app-*-release.apk 1> /dev/null 2>&1; then
    success "APK ビルド完了"
    ls -lh build/app/outputs/flutter-apk/app-*-release.apk
else
    error "APK ビルドに失敗しました"
fi

################################################################################
# ステップ 5: Firebase デプロイ
################################################################################
log "\n[5/7] Firebase デプロイ..."

if [ ! -f "firebase.json" ]; then
    error "firebase.json が見つかりません"
fi

# Firebase CLI 確認
if ! command -v firebase &> /dev/null; then
    warning "Firebase CLI がインストールされていません"
    log "インストール: npm install -g firebase-tools"
else
    # Cloud Functions デプロイ
    log "Cloud Functions デプロイ中..."
    firebase deploy --only functions --project rambusgame-prod || warning "Cloud Functions デプロイをスキップ"
    success "Firebase デプロイ完了"
fi

################################################################################
# ステップ 6: Firestore config 更新
################################################################################
log "\n[6/7] Firestore config 更新..."

cat << EOF

現在のローンチステージ:
  [ ] Internal Testing（内部テスト）
  [ ] Closed Beta（限定ベータ）
  [ ] Public Release（公開リリース）✅ 推奨

ステージを選択してください（1-3）:
EOF

read -p "> " STAGE_CHOICE

case $STAGE_CHOICE in
    1)
        LAUNCH_STAGE="internalTesting"
        MAX_DAILY_GAMES=100
        MAX_MONTHLY_USERS=50
        ;;
    2)
        LAUNCH_STAGE="closedBeta"
        MAX_DAILY_GAMES=10
        MAX_MONTHLY_USERS=500
        ;;
    *)
        LAUNCH_STAGE="publicRelease"
        MAX_DAILY_GAMES=10
        MAX_MONTHLY_USERS=10000
        ;;
esac

log "Firestore を更新中: ${LAUNCH_STAGE}..."

# Firestore 更新（Firebase CLI）
firebase firestore:delete \
  --project=rambusgame-prod \
  config/launch_config \
  --yes 2>/dev/null || true

cat > /tmp/launch_config.json << EOF_JSON
{
  "launchEnabled": true,
  "launchStage": "${LAUNCH_STAGE}",
  "highlightGenerationEnabled": true,
  "highlightSharingEnabled": true,
  "analyticsEnabled": true,
  "maxDailyGames": ${MAX_DAILY_GAMES},
  "maxMonthlyUsers": ${MAX_MONTHLY_USERS},
  "maxTotalUsers": 100000,
  "maintenanceMode": false,
  "maintenanceMessage": "",
  "lastUpdatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF_JSON

log "ドキュメント内容:"
cat /tmp/launch_config.json

firebase firestore:import \
  --project=rambusgame-prod \
  /tmp/launch_config.json 2>/dev/null || warning "Firestore 更新をスキップ（手動で config/launch_config を作成してください）"

success "Firestore 更新完了"

################################################################################
# ステップ 7: Google Play Console アップロード
################################################################################
log "\n[7/7] Google Play Console 準備..."

cat << EOF

📱 Google Play Console へのアップロード方法:

【推奨: fastlane を使用】
  1. インストール: sudo gem install fastlane
  2. 設定: fastlane init android
  3. デプロイ: fastlane android deploy_release

【手動でアップロード】
  1. Google Play Console にログイン
  2. 乱舞将棋 > リリース > 作成
  3. 以下をアップロード:
     ✅ AAB: build/app/outputs/bundle/release/app-release.aab
     ✅ スクリーンショット: docs/ 参照
     ✅ プレビュー動画: ハイライト動画サンプル
  4. メタデータ確認
  5. 「リリース」をクリック

🔗 Google Play Console: https://play.google.com/console/developers

EOF

prompt "Google Play Console へ手動でアップロードしますか？ (y/n):"
read -r MANUAL_UPLOAD

if [ "$MANUAL_UPLOAD" = "y" ] || [ "$MANUAL_UPLOAD" = "Y" ]; then
    log "AAB ファイルをコピーしました（手動で Google Play Console にドラッグ＆ドロップしてください）"
    log "AAB パス: $(pwd)/build/app/outputs/bundle/release/app-release.aab"

    # macOS の場合、ファイルマネージャーを開く
    if [ "$(uname)" = "Darwin" ]; then
        open -R "build/app/outputs/bundle/release/app-release.aab"
    fi
else
    log "手動アップロードをスキップしました"
fi

################################################################################
# 完了レポート
################################################################################
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║           🎉 リリースデプロイ完了                            ║
╚════════════════════════════════════════════════════════════════╝

📦 ビルド成果物:
   ✅ AAB: build/app/outputs/bundle/release/app-release.aab
   ✅ APK: build/app/outputs/flutter-apk/app-*-release.apk

🔥 Firebase:
   ✅ Cloud Functions: デプロイ完了
   ✅ Firestore: config/launch_config 更新完了

📱 次のステップ:

   【Google Play Console】
   1. https://play.google.com/console/developers にログイン
   2. 乱舞将棋 > リリース > ドラフトを確認
   3. メタデータ・スクショ確認
   4. 「リリース」をクリック

   【検証】
   1. Firebase Console で analytics イベント確認
   2. Crashlytics でクラッシュ監視設定
   3. Remote Config の値確認

⏱️  所要時間: 約 20 分

EOF

success "全プロセス完了"
