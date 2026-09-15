# 乱舞将棋 (rambu_shogi) 🎮

HP制と飛び道具を持つ観戦映え特化の将棋バリアント

## 📱 プロジェクト概要

**乱舞将棋**は本将棋の駒構成・初期配置を維持しながら、HP（体力）制と飛び道具駒（角・飛）を追加したゲームです。配信やSNS切り抜き文化向けに「観戦映え」を最優先で設計しています。

### 🎯 Vision & Mission

**Vision**: 将棋を知らない視聴者でも「うわ、今の一撃やばい」で盛り上がる、切り抜き文化に乗る将棋バリアント

**Mission**: 将棋の「静かな読み合い」に「殴り合いの爽快感」を足し、配信・SNSで拡散される将棋を作る

### 🎮 Aha Moment

**飛び道具のクリティカルアタックが相手の主力にヒットして HP が0になる瞬間**

## 🛠️ テック・スタック

```
Frontend:  Flutter/Dart 3.x + Flame + Riverpod + Lottie
Backend:   Firebase (Firestore/Auth/Analytics/Cloud Functions)
External:  RevenueCat, Bitly API
```

## 📋 開発フェーズ

| Phase | 状況 | 目標 | 進捗 |
|-------|------|------|------|
| **Phase 0** | ✅ 完了 | 企画・ゲームバランス検証済み | 100% |
| **Phase 1** | ✅ 完了 | UI + Bot初期実装 | 100% |
| **Phase 2** | ✅ 完了 | Bot先手勝率50%調整（パラメータ・テスト） | 100% |
| **Phase 3** | ✅ 完了 | ハイライト生成パイプライン（3a/3b/3c） | 100% |
| **Phase 4** | 🔄 進行中 | テスト・ストア準備 → ソフトローンチ | 0% |

### 📊 Phase 3 実装内訳

| サブフェーズ | 内容 | 状態 |
|-----------|------|------|
| **Phase 3a** | サービス層（Orchestrator, Renderer, Storage, Share） | ✅ 完了 |
| **Phase 3b** | UI統合＆テスト（Riverpod, Progress UI, 20個テスト） | ✅ 完了 |
| **Phase 3c** | Cloud Functions（encodeHighlightVideo, checkProgress, cancel） | ✅ 完了 |

## 📁 プロジェクト構成

```
rambu_shogi/
├── lib/
│   ├── models/              # ゲームデータモデル
│   │   ├── piece.dart       # 駒定義（HP・飛び道具）
│   │   ├── move.dart        # 着手情報
│   │   ├── board.dart       # 9x9盤面管理
│   │   ├── game_session.dart # 対局全体管理
│   │   └── highlight.dart   # ハイライト動画entity (TODO)
│   │
│   ├── services/            # ビジネスロジック
│   │   ├── game_logic.dart      # ✅ 着手判定・詰み判定
│   │   ├── ai_engine.dart       # ✅ 評価関数・アルファベータ
│   │   ├── evaluation_params.dart   # ✅ Phase 2: パラメータ調整用
│   │   ├── benchmark_utils.dart     # ✅ Phase 2: テスト用ユーティリティ
│   │   ├── highlight_service.dart   # ✅ Phase 3: ハイライト検出・メタデータ
│   │   ├── highlight_renderer.dart   # ✅ Phase 3a: フレームレンダリング
│   │   ├── highlight_orchestrator.dart # ✅ Phase 3a: 7段階パイプライン統合
│   │   ├── cloud_functions_service.dart # ✅ Phase 3a: FFmpegエンコード管理
│   │   ├── cloud_storage_service.dart # ✅ Phase 3a: ビデオアップロード
│   │   ├── share_link_service.dart # ✅ Phase 3a: シェアリンク生成
│   │   ├── firestore_service.dart   # (TODO)
│   │   └── analytics_service.dart   # (TODO)
│   │
│   ├── viewmodels/          # Riverpod プロバイダ
│   │   ├── game_provider.dart   # (TODO)
│   │   ├── board_provider.dart  # (TODO)
│   │   ├── ai_provider.dart     # (TODO)
│   │   └── highlight_provider.dart # ✅ Phase 3b: ハイライト生成状態管理
│   │
│   ├── views/               # UI画面
│   │   ├── screens/         # (TODO)
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── game_screen.dart
│   │   │   ├── tutorial_screen.dart
│   │   │   ├── result_screen.dart # ✅ Phase 3b: ハイライト自動生成統合
│   │   │   └── ...
│   │   └── widgets/
│   │       └── highlight_progress_indicator.dart # ✅ Phase 3b: 進捗表示UI
│   │
│   ├── utils/
│   │   ├── constants.dart       # ✅ 駒価値表・盤面定義
│   │   └── enums.dart           # (TODO)
│   │
│   └── main.dart            # (TODO)
│
├── test/                    # ユニットテスト
│   ├── models/
│   │   └── board_test.dart  # ✅
│   ├── services/
│   │   ├── game_logic_test.dart  # ✅
│   │   └── ai_engine_test.dart   # ✅
│   ├── benchmarks/
│   │   └── bot_benchmark.dart    # ✅ Phase 1: 100ゲーム検証
│   ├── phase2_parameter_test.dart    # ✅ Phase 2: パラメータ調整（95ゲーム）
│   └── phase3_highlight_test.dart    # ✅ Phase 3b: 統合テスト（20個テスト）
│
├── pubspec.yaml             # ✅ 依存パッケージ
├── CLAUDE.md                # ✅ 開発ガイド
├── firebase.json            # ✅ Firebase プロジェクト設定
├── functions/               # ✅ Phase 3c: Cloud Functions
│   ├── index.js            # ハイライト動画エンコード実装
│   ├── package.json        # Node.js 依存パッケージ
│   └── .gitignore
└── README.md                # このファイル
```

## 🚀 クイックスタート

### 前提条件

- Flutter 3.2.0 以上
- Dart 3.2.0 以上
- Firebase プロジェクト（Firestore, Auth, Analytics, Cloud Functions）
- RevenueCat アカウント

### セットアップ

```bash
# 依存パッケージをインストール
flutter pub get

# テストを実行
flutter test

# アプリを実行
flutter run
```

## 🎮 ゲームルール

### 駒のHP

| 駒 | HP | 説明 |
|---|---|---|
| 歩/香/桂 | 1 | 即死維持 |
| 銀/金 | 2 | 耐久UP |
| 角/飛 | 2 | 遠隔攻撃可能 |
| 王 | — | HP制度対象外・通常詰みルール |

### 飛び道具駒

角・飛が飛び道具を装備（射程3マス・威力1・クールタイム3手）

### 先後バランス補正

後手が初手直後に「追加移動1回」を得る（通常移動のみ）

## 🤖 AI（ボット）

**難易度別パラメータ**:

| 難易度 | 駒価値:HP価値 | 目標勝率 | ノイズ |
|---|---|---|---|
| 初級 | 70:30 | 40-50% | ±5.0 |
| 中級 | 50:50 | 50±3% | ±1.0 |
| 上級 | 30:70 | 60%+ | ±0.3 |

**実装**: アルファベータ探索（depth=4）+ 駒価値・HP価値・位置評価・テンポ・クリティカル局面の特殊評価

詳細は `CLAUDE.md` と `docs/rambu_shogi_ai_evaluation_spec_v1_0.md` を参照

## 📊 計測・分析

- **Day 1 リテンション**: 16%目標
- **Aha 達成率**: 60%目標（クリティカルヒット体験）
- **有料転換率**: 3%目標

Firebase Analytics でリアルタイム計測中

## 🧪 テスト

### ユニットテスト

```bash
flutter test
```

実装済み:
- ✅ `test/models/board_test.dart` - 盤面・駒配置
- ✅ `test/services/game_logic_test.dart` - 着手・詰み判定
- ✅ `test/services/ai_engine_test.dart` - AI評価・探索

**目標カバレッジ**: 50%+ （AI エンジンは 70%+）

### AI ベンチマーク

#### Phase 1 検証用ベンチマーク
100局自動対局で先手勝率を計測

```bash
dart run test/benchmarks/bot_benchmark.dart
```

#### Phase 2 パラメータ調整テスト
先手勝率 50±3% を達成するための系統的なパラメータ調整

```bash
# 推奨: 段階的なテストを実行
dart run test/phase2_parameter_test.dart

# または個別に実行:
# 1. ベースライン確認（10ゲーム）
# 2. テンポボーナス変動テスト（5〜7テンポ × 5ゲーム）
# 3. パラメータセット比較（5セット × 10ゲーム）
```

詳細は `docs/PHASE_2_ANALYSIS.md` と `PHASE_2_BALANCE_TUNING.md` を参照

## 📚 参考資料

すべて `/docs/` ディレクトリ に保存済み:

1. **企画設計書** - ゲーム企画・バランス検証
2. **AI 評価関数仕様** - 駒価値表・評価ロジック
3. **ハイライト生成フロー** - 動画自動生成仕様
4. **実装スケジュール** - Phase 0-4 の工程・人日
5. **Code 引き継ぎ書** - 実装ガイド

### Phase 2 関連ドキュメント

- **PHASE_2_BALANCE_TUNING.md** - 先手勝率50%調整戦略
- **docs/PHASE_2_ANALYSIS.md** - 詳細な評価関数分析と理論背景

## 🔗 関連リンク

- **プロジェクト管理**: GitHub Issues & Projects
- **CI/CD**: GitHub Actions
- **設計レビュー**: `CLAUDE.md`

## 📝 コミット規約

```
[Phase/機能] 説明

例:
[Phase 1] データモデル実装（Piece/Move/Board）
[Phase 1] AI評価関数 + アルファベータ探索
[Phase 2] Bot先手勝率50%調整
```

各コミットメッセージの末尾に:
```
Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_<ID>
```

## 🎯 次のステップ

### Phase 1 残り作業（3週間）

**トラック A: UI 実装 (Week 2-4)**
- [ ] オンボーディング＋ホーム画面（3日）
- [ ] Flame 盤面実装（4日）
- [ ] チュートリアル画面（2日）
- [ ] 結果画面（2日）
- [ ] 設定＋ペイウォール（2日）

**トラック B: Bot 統合**
- [ ] Riverpod プロバイダ
- [ ] AI 思考フロー (async)
- [ ] UI ← → AI ロジック統合

**終了条件**:
- [ ] オンボーディング → 盤面 → 結果フロー実装完了
- [ ] ユーザー vs CPU で 1局プレイ可能
- [ ] 盤面・HP表示・SE が正常動作

### Phase 2: Bot 調整（3週間）

100局自動対局で先手勝率 50±3% を達成

## 📞 開発中の意思決定

詳細は `CLAUDE.md` 内の「開発中の判断ポイント」セクションを参照

---

**プロジェクト開始日**: 2026-08-22  
**目標ローンチ**: 2026-11-07（ソフトローンチ）  
**ステータス**: Phase 1 進行中 🔄

🚀 See you at launch!