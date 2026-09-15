# Phase 4c 実装計画書 - ソフトローンチ設定

## 📋 概要

**フェーズ名**: Phase 4c（ソフトローンチ設定）  
**目標**: App Store / Google Play ソフトローンチ完全実施  
**期間**: 5日間（2026-09-01～09-05）  
**ステータス**: 🔄 実装完了 → ソフトローンチ実行へ

---

## 🎯 Phase 4c の目標

本番環境でのユーザー・機能を段階的に制御し、安定したローンチを実現

### 成功基準

- [x] Remote Config Service 実装完了
- [x] Analytics KPI 定義完了
- [x] ソフトローンチ設定 Firestore ドキュメント準備完了
- [x] ローンチ段階の自動制御システム実装完了

---

## 📊 Phase 4c 実装内容

### 実装ファイル

#### 1. lib/config/launch_config.dart (180行)

**ローンチ設定の定義**:

```dart
@freezed
class LaunchConfig with _$LaunchConfig {
  const factory LaunchConfig({
    // 機能フラグ
    @Default(true) bool launchEnabled,
    @Default(true) bool highlightGenerationEnabled,
    @Default(true) bool highlightSharingEnabled,
    @Default(true) bool analyticsEnabled,

    // ユーザー制限
    @Default(10) int maxDailyGames,
    @Default(1000) int maxMonthlyUsers,
    @Default(100000) int maxTotalUsers,

    // メンテナンスモード
    @Default(false) bool maintenanceMode,
    @Default('') String maintenanceMessage,

    // ソフトローンチステージ
    @Default(LaunchStage.internalTesting) LaunchStage launchStage,

    DateTime? lastUpdatedAt,
  }) = _LaunchConfig;
}
```

**ローンチステージの定義**:
- Stage 1: Internal Testing（開発チーム限定）
- Stage 2: Closed Beta（100-500人限定）
- Stage 3: Public Release（全ユーザー公開）

**事前定義シナリオ**:
- `developmentScenario()` - 開発環境（制限なし）
- `internalTestingScenario()` - 内部テスト（チーム限定）
- `closedBetaScenario()` - クローズドベータ（500人限定）
- `publicReleaseScenario()` - 公開リリース（全ユーザー）
- `maintenanceScenario()` - メンテナンス（全機能停止）
- `highlightDownScenario()` - ハイライト機能のみ停止

#### 2. lib/services/remote_config_service.dart (280行)

**Remote Config Service**:

```dart
class RemoteConfigService {
  // Firestore から動的に設定を読み込み
  Future<LaunchConfig> getConfig()

  // リアルタイムで設定変更を監視
  Stream<LaunchConfig> watchConfig()

  // 管理者が設定を更新
  Future<void> updateConfig(LaunchConfig newConfig)

  // ステージを変更
  Future<void> setLaunchStage(LaunchStage stage)

  // メンテナンスモードの制御
  Future<void> enableMaintenance(String message)
  Future<void> disableMaintenance()

  // テスト用ローカルオーバーライド
  void setLocalOverride(LaunchConfig? config)

  // キャッシュ管理
  void clearCache()
  Future<void> resetToDefault()
}
```

**主な機能**:
- Firestore からの動的設定読み込み
- 5分間のローカルキャッシュ
- リアルタイムリスナーで設定変更を即座反映
- Riverpod Providers で UI に統合
- エラーハンドリングとフォールバック

### Firestore ドキュメント構造

**パス**: `config/launch_config`

```json
{
  "launchEnabled": true,
  "highlightGenerationEnabled": true,
  "highlightSharingEnabled": true,
  "analyticsEnabled": true,
  
  "maxDailyGames": 10,
  "maxMonthlyUsers": 1000,
  "maxTotalUsers": 100000,
  
  "maintenanceMode": false,
  "maintenanceMessage": "",
  
  "launchStage": "closedBeta",
  "lastUpdatedAt": "2026-09-01T00:00:00Z"
}
```

---

## 🚀 ソフトローンチの実行ステップ

### Stage 1: Internal Testing （2026-09-01～09-02）

**期間**: 24時間

**ユーザー**: 開発チーム・内部テスター（5-10人）

**設定**:
```dart
LaunchScenarios.internalTestingScenario()
// maxDailyGames: 100
// maxMonthlyUsers: 50
// launchStage: InternalTesting
```

**配布方法**:
- iOS: TestFlight（開発者向けビルド）
- Android: Google Play Internal Testing Track

**実施内容**:
- [ ] アプリの基本機能動作確認
- [ ] ハイライト生成・シェア機能確認
- [ ] クラッシュ・エラーログの監視
- [ ] パフォーマンス計測（メモリ・CPU）
- [ ] Network 遅延シミュレーション

**監視項目**:
```
✅ Crash Rate: 0%
✅ Session Length: > 5分
✅ Memory Usage: < 50MB
✅ Battery Drain: < 2%/hour
```

**決定基準**:
- ❌ クラッシュが発生 → 修正して再テスト
- ❌ 重大なバグ → 修正して再テスト
- ✅ 安定稼働 → Stage 2 へ進行

**実行コマンド**:
```bash
# iOS TestFlight ビルド・提出
flutter build ios --release
# Xcode で Archive → Upload to App Store

# Android Internal Testing
flutter build appbundle --release
# Google Play Console > Internal Testing Track へアップロード

# 設定を Stage 1 に更新
firebase firestore update config/launch_config \
  --data 'launchStage=internalTesting'
```

---

### Stage 2: Closed Beta （2026-09-02～09-04）

**期間**: 48時間

**ユーザー**: 限定招待ユーザー（100-500人）

**設定**:
```dart
LaunchScenarios.closedBetaScenario()
// maxDailyGames: 10
// maxMonthlyUsers: 500
// launchStage: ClosedBeta
```

**配布方法**:
- iOS: TestFlight（限定招待リンク）
- Android: Google Play Beta Track（限定招待）

**招待戦略**:
1. **Day 1** (2026-09-02): 50人 招待開始
2. **Day 2 AM** (2026-09-02 12:00): フィードバック確認後、100人に拡大
3. **Day 2 PM** (2026-09-02 18:00): 200人に拡大
4. **Day 3** (2026-09-03): 300-500人に段階的拡大

**実施内容**:
- [ ] ゲームプレイの継続性確認
- [ ] ハイライト生成の成功率計測（目標: 100%）
- [ ] SNS シェア機能の動作確認
- [ ] ユーザーからのフィードバック収集
- [ ] パフォーマンス計測（複数デバイス）
- [ ] クラッシュレポート分析

**KPI 監視**:
```
📊 必須 KPI:
  - Crash Rate: < 0.5%
  - Session Length: > 5分
  - Highlight Success Rate: > 95%
  - Share Rate: > 30%
  - Day 1 Retention: > 15% (目標: 20%+)

📊 オプション KPI:
  - AI 勝率: 48-52%
  - 平均ゲーム時間: 3-5分
  - リピート率: > 40%
```

**問題発生時の対応**:

```
クラッシュ多発（> 1%）:
  → 原因特定（Crashlytics で分析）
  → ホットフィックス実装
  → TestFlight/Beta に新ビルドアップロード
  → 監視継続

ハイライト失敗（< 95%）:
  → Cloud Functions ログ確認
  → FFmpeg エラー分析
  → バックエンド修正 or フォールバック有効化
  → 再テスト

ネットワーク問題:
  → Firestore/Cloud Storage の接続確認
  → タイムアウト設定の調整
  → リトライロジックの改善
```

**フィードバック収集**:
- TestFlight 内の「フィードバック」機能
- In-app Feedback Form
- Discord/Slack コミュニティ（オプション）

**実行コマンド**:
```bash
# iOS TestFlight 招待リンク作成
# App Store Connect > TestFlight > Invitations

# Android Beta Track
# Google Play Console > Testing > Beta > Create release

# 設定を Stage 2 に更新
firebase firestore update config/launch_config \
  --data 'launchStage=closedBeta,maxMonthlyUsers=500'
```

---

### Stage 3: Public Release （2026-09-04～）

**期間**: 継続（本公開）

**ユーザー**: 全員（無制限）

**設定**:
```dart
LaunchScenarios.publicReleaseScenario()
// maxDailyGames: 10
// maxMonthlyUsers: 10000
// launchStage: PublicRelease
```

**配布方法**:
- iOS: App Store 公開
- Android: Google Play 公開

**実施内容**:
- [ ] App Store / Google Play で公開
- [ ] 24時間継続監視
- [ ] リリースノート発行
- [ ] SNS でのアナウンス
- [ ] プレスリリース（オプション）

**本公開後の監視**:

```
リアルタイムダッシュボード:
  📊 DAU (Daily Active Users)
  📊 新規インストール数
  📊 Crash Rate
  📊 Session Length
  📊 Retention (Day 1, 7, 30)
  📊 ハイライト生成成功率
  📊 シェア率

24時間監視項目:
  ⚠️  クラッシュ急増 → 緊急ホットフィックス
  ⚠️  ハイライト失敗 → 機能一時停止 or 修正
  ⚠️  サーバーエラー → インフラスケーリング
  ⚠️  ネガティブレビュー → 原因調査・対応

SLA:
  - Critical Bug: 1時間以内に対応開始
  - High Bug: 4時間以内に対応開始
  - Medium Bug: 24時間以内に対応開始
```

**実行コマンド**:
```bash
# App Store 公開
# App Store Connect > Version Release > Release this Version

# Google Play 公開
# Google Play Console > Release Management > Production > Create new release

# 設定を Stage 3 に更新
firebase firestore update config/launch_config \
  --data 'launchStage=publicRelease,maxMonthlyUsers=10000'

# リアルタイムログ監視
firebase functions:log --project rambusgame-prod

# ダッシュボード開く
open https://console.firebase.google.com/u/0/project/rambusgame-prod/analytics/overview
```

---

## 📊 Analytics KPI 定義

### 計測イベント

#### ゲームプレイイベント

```dart
// 対局開始
analytics.logEvent(
  name: 'game_started',
  parameters: {
    'difficulty': 'medium',  // 初級/中級/上級
    'game_mode': 'cpu_vs_cpu',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// 対局終了
analytics.logEvent(
  name: 'game_ended',
  parameters: {
    'winner': 'sente',  // sente/gote
    'turn_count': 42,
    'duration_seconds': 180,
    'game_status': 'completed',  // completed/aborted
  },
);

// クリティカルアタック発生
analytics.logEvent(
  name: 'critical_hit',
  parameters: {
    'piece_type': 'rook',
    'target_hp': 1,
    'damage': 2,
  },
);
```

#### ハイライト生成イベント

```dart
// ハイライト生成開始
analytics.logEvent(
  name: 'highlight_generation_started',
  parameters: {
    'game_id': gameId,
    'event_count': 5,
  },
);

// ハイライト生成完了
analytics.logEvent(
  name: 'highlight_generation_completed',
  parameters: {
    'game_id': gameId,
    'duration_seconds': 120,
    'success': true,
  },
);

// ハイライト動画視聴
analytics.logEvent(
  name: 'highlight_video_viewed',
  parameters: {
    'game_id': gameId,
    'watch_duration_seconds': 15,
  },
);

// ハイライト動画共有
analytics.logEvent(
  name: 'highlight_shared',
  parameters: {
    'game_id': gameId,
    'share_platform': 'twitter',  // twitter/tiktok/instagram/line
    'share_method': 'bitly',  // bitly/dynamic_links
  },
);
```

#### エラーイベント

```dart
// クラッシュ
analytics.logEvent(
  name: 'app_crashed',
  parameters: {
    'error_type': 'null_pointer_exception',
    'screen': 'game_screen',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// ハイライト生成失敗
analytics.logEvent(
  name: 'highlight_generation_failed',
  parameters: {
    'game_id': gameId,
    'error_reason': 'encoding_timeout',
    'retry_count': 2,
  },
);
```

### KPI ダッシュボード

#### ユーザー獲得

```
📈 新規インストール数
   Day 1: 100 (内部テスター)
   Day 2-3: 500 (クローズドベータ)
   Day 4+: 無制限（本公開）

📈 ユーザーセッション数
   目標: 毎日 DAU を 10% ずつ増加
```

#### ユーザー体験

```
✅ Session Length (平均)
   目標: 5分以上
   計測: 対局開始～終了時間

✅ Aha Moment: ハイライト生成完了
   目標: 新規ユーザーの 60% がハイライト生成を体験
   計測: highlight_generation_completed / game_started

✅ Share Rate: SNS シェア率
   目標: 30% 以上
   計測: highlight_shared / highlight_generation_completed
```

#### リテンション

```
🎯 Day 1 Retention
   目標: 20%+
   計測: インストール翌日のアクティブユーザー数 / インストール数

🎯 Day 7 Retention
   目標: 40%+
   計測: インストール 7日後のアクティブユーザー数

🎯 Day 30 Retention
   目標: 15%+
   計測: インストール 30日後のアクティブユーザー数
```

#### 技術指標

```
🔴 Crash Rate
   目標: < 0.1%
   計測: Crashlytics

🟡 ANR Rate (Application Not Responding)
   目標: < 0.01%

🟢 Highlight Success Rate
   目標: > 95%
   計測: highlight_generation_completed (true) / started
```

---

## 🎛️ Remote Config の管理

### Firebase Console での設定

**パス**: Firestore > `config` コレクション > `launch_config` ドキュメント

### CLI での設定

```bash
# 現在の設定を表示
firebase firestore get config/launch_config

# ステージを更新
firebase firestore update config/launch_config \
  --data 'launchStage=closedBeta'

# 複数フィールドを更新
firebase firestore update config/launch_config \
  --data 'launchStage=publicRelease,maxMonthlyUsers=10000'

# ドキュメント全体を置き換え
firebase firestore set config/launch_config \
  --data '{
    "launchEnabled": true,
    "launchStage": "publicRelease",
    "maxDailyGames": 10,
    "maxMonthlyUsers": 10000
  }'
```

### Dart コード での設定

```dart
// Riverpod Provider から設定を取得
final config = ref.watch(launchConfigProvider);

// 設定を監視（リアルタイム更新）
ref.watch(launchConfigStreamProvider).when(
  data: (config) {
    if (!config.launchEnabled) {
      return MaintenanceScreen(message: config.maintenanceMessage);
    }
    return GameScreen();
  },
  loading: () => LoadingScreen(),
  error: (err, stack) => ErrorScreen(error: err),
);

// 管理者が設定を更新
final service = ref.read(remoteConfigServiceProvider);
await service.enableMaintenance('定期メンテナンス中');
await service.setLaunchStage(LaunchStage.publicRelease);
```

---

## ⚠️ 緊急対応プロセス

### クリティカルバグ発生時

```
1. 通知 (即座)
   → Crashlytics でクラッシュを検出
   → Slack に通知

2. 原因特定 (5分以内)
   → ログをダウンロード
   → デバッグ実行
   → 原因を特定

3. 修正 (15分以内)
   → コードを修正
   → テストを実行
   → ビルド

4. 配布 (20分以内)
   → TestFlight/Beta に新ビルドアップロード
   → インターナルテスター で再テスト

5. 本公開 (30分以内)
   → App Store / Google Play に新ビルドアップロード
   → 審査リクエスト（優先処理）

6. 監視 (継続)
   → クラッシュレートの低下を確認
   → ユーザーフィードバック確認
```

### 機能停止が必要な場合

```bash
# ハイライト生成を一時停止
firebase firestore update config/launch_config \
  --data 'highlightGenerationEnabled=false'

# 全機能停止（メンテナンス）
firebase firestore update config/launch_config \
  --data '{
    "maintenanceMode": true,
    "maintenanceMessage": "予定外のメンテナンス中です。しばらくお待ちください。"
  }'
```

---

## 📋 チェックリスト

### 提出前（2026-09-01）

- [ ] Remote Config Service 実装完了
- [ ] Firestore `config/launch_config` ドキュメント作成完了
- [ ] Analytics イベント実装完了
- [ ] Riverpod Providers 統合完了
- [ ] 内部テストで全機能動作確認

### Stage 1（2026-09-01～09-02）

- [ ] TestFlight/Google Play Internal Testing アップロード
- [ ] 内部テスター に招待送信
- [ ] 24時間継続監視（クラッシュ・エラー）
- [ ] メモリ・CPU 計測
- [ ] ゲーム 10局以上実施
- [ ] ハイライト 5個以上生成

### Stage 2（2026-09-02～09-04）

- [ ] TestFlight/Google Play Beta に新ビルドアップロード
- [ ] 50人 招待 → フィードバック確認
- [ ] 100人 → 200人 → 500人 と段階的招待
- [ ] 各段階でクラッシュレートを確認（< 0.5% 目標）
- [ ] ハイライト成功率を確認（> 95% 目標）
- [ ] Day 1 Retention を計測（> 15% 確認）
- [ ] ユーザーからのフィードバック収集・分析

### Stage 3（2026-09-04～）

- [ ] App Store / Google Play で公開
- [ ] 24時間継続監視ダッシュボード開設
- [ ] インシデント対応チーム待機
- [ ] SNS でアナウンス
- [ ] 各 KPI を毎時計測

---

## 📞 サポート・連絡先

**緊急時**:
- support@rambusgame.jp
- Slack: #incident-alerts

**通常のフィードバック**:
- TestFlight: Feedback タブ
- Google Play Beta: Review セクション

---

**ステータス**: 🟢 ソフトローンチ準備完了  
**次ステップ**: 2026-09-01 Stage 1 開始 → App Store / Google Play 公開へ
