# Phase 2 クイックスタートガイド

## 概要
Phase 2の目標は、AI（先手）の勝率を**50±3%**（中級難易度）に調整することです。

このガイドでは、実際にパラメータを調整してテストを実行する手順を説明します。

## 📋 事前チェック

- ✅ Dartがインストール済み
- ✅ rambu_shogiプロジェクトがセットアップ済み
- ✅ Phase 1が完了している

## 🚀 Phase 2 テストの実行

### ステップ 1: ベースラインテスト（10ゲーム、2-3分）

現在のパラメータで先手の勝率をチェック：

```bash
dart run test/phase2_parameter_test.dart
```

出力例：
```
🎯 乱舞将棋 Phase 2 パラメータ調整テスト
...
✅ ステップ 1: ベースラインテスト
先手勝率: 52.5% (5/10)
バランス評価: ⚠️ 先手優位（補正が必要）
```

**結果の見方**:
- **47-53%**: ✅ バランス取れてる → Phase 3へ進める
- **>53%**: ⚠️ 先手が勝ちすぎ → 調整が必要
- **<47%**: ⚠️ 後手が勝ちすぎ → 調整が必要

### ステップ 2: テンポボーナス変動テスト（7×5=35ゲーム、10-15分）

テンポボーナス（手番プレイヤーへの加点）を0.2〜0.8で変動させ、最適値を探索：

```bash
dart run test/phase2_parameter_test.dart
```

自動で実行され、各テンポボーナス値での結果が表示されます。

**期待される出力例**:
```
🔄 ステップ 2: テンポボーナス変動テスト
...
📈 ベンチマーク比較レポート
✅ TempoVariation-0.4: 先手50.0% (25/50)  ← 最適
⚠️  (先手優位) TempoVariation-0.6: 先手54.0% (27/50)
⚠️  (後手優位) TempoVariation-0.2: 先手46.0% (23/50)
```

### ステップ 3: パラメータセット比較（5×10=50ゲーム、15-20分）

複数の事前定義パラメータセットを比較：

```bash
dart run test/phase2_parameter_test.dart
```

自動で実行され、5つのパラメータセットが比較されます：
1. **baseline** - Phase 1の初期パラメータ
2. **senteReduced** - 先手ボーナス低減版
3. **senteStrengthened** - 先手ボーナス増加版
4. **criticalReduced** - クリティカルボーナス低減版
5. **balanced** - 全体的にバランス重視版

## 📊 結果の解釈

### バランス評価

```
✅ 良好（47-53%）
   → そのパラメータセットを採用してOK

⚠️ 先手優位（>53%）
   → テンポボーナスを低減する必要がある
   → 例: 0.5 → 0.3 or 0.4

⚠️ 後手優位（<47%）
   → テンポボーナスを増加する必要がある
   → 例: 0.5 → 0.6 or 0.7
```

### ゲーム時間が長い/短い場合

- **ゲーム時間が異常に長い（>100ターン）**
  - 評価関数がステイルメイトに陥っている可能性
  - クリティカルボーナスを上げる

- **ゲーム時間が異常に短い（<20ターン）**
  - 評価関数が急激な詰みを見つけすぎている
  - クリティカルボーナスを下げる

## 🔧 パラメータの手動調整

### 1. 新しいパラメータセットを作成

`lib/services/evaluation_params.dart` を開いて、新しい定数を追加：

```dart
/// カスタムパラメータセット
static const EvaluationParams myCustom = EvaluationParams(
  tempoBonus: 0.4,  // 0.5から0.4に低減
  criticalAdjacentBonus: 45.0,  // 50から45に低減
  criticalDamageBonus: 25.0,    // 30から25に低減
  enemyMajorPieceAttackBonus: 20.0,
  fullHPBonus: 5.0,
  enemyLowHPBonus: 15.0,
  pieceValueWeight: 0.5,
  pieceValueCoefficient: 1.0,
  hpValueCoefficient: 1.0,
  positionValueCoefficient: 1.0,
  criticalSituationCoefficient: 1.0,
  name: 'MyCustom',
  description: 'Custom adjustment for sente reduction',
);
```

### 2. テストファイルで新しいパラメータをテスト

`test/phase2_parameter_test.dart` の `_runParameterSetComparison()` を編集：

```dart
final paramsList = [
  EvaluationParams.baseline,
  EvaluationParams.myCustom,  // ← 新しいパラメータを追加
  EvaluationParams.balanced,
];
```

### 3. テストを実行

```bash
dart run test/phase2_parameter_test.dart
```

## ⚙️ よくある調整パターン

### パターン A: 先手が勝ちすぎている（>53%）

**最初に試す**:
```dart
tempoBonus: 0.4,  // 0.5 → 0.4に低減
```

**効果がない場合**:
```dart
tempoBonus: 0.3,
criticalAdjacentBonus: 40.0,  // 50 → 40に低減
pieceValueWeight: 0.48,  // 0.5 → 0.48に低減
```

### パターン B: 後手が勝ちすぎている（<47%）

**最初に試す**:
```dart
tempoBonus: 0.6,  // 0.5 → 0.6に増加
```

**効果がない場合**:
```dart
tempoBonus: 0.7,
criticalAdjacentBonus: 55.0,  // 50 → 55に増加
pieceValueWeight: 0.52,  // 0.5 → 0.52に増加
```

### パターン C: ゲームが不安定（結果がぶれている）

**クリティカルボーナスを低減** してゲーム進行を安定化：
```dart
criticalAdjacentBonus: 40.0,
criticalDamageBonus: 20.0,
criticalSituationCoefficient: 0.8,
```

## ✅ 最終検証（Phase 3へ進む前）

パラメータが決定したら、最低でも**40ゲーム**の検証テストを実行：

```bash
# 40ゲーム連続テスト
dart run test/phase2_parameter_test.dart
```

結果が47-53%の範囲内なら、Phase 2は完了です！

**次のステップ**:
1. 最終パラメータを `lib/utils/constants.dart` の `EvaluationConstants` に反映
2. `lib/services/evaluation_params.dart` から新しいパラメータセットを削除（またはコメント化）
3. `AIEngine` から手動のパラメータ上書き機能は削除可能（または保持）
4. Phase 3: ハイライト生成パイプラインへ進む

## 📚 参考資料

詳細なパラメータ理論については：
- `PHASE_2_BALANCE_TUNING.md` - 調整戦略の詳細
- `docs/PHASE_2_ANALYSIS.md` - 評価関数の理論背景

## 🆘 トラブルシューティング

### Q: テストが遅い（1ゲームに数秒かかる）

**A**: これは正常です。アルファベータ探索（depth=4）は計算負荷が高いです。
- ベースラインテスト（10ゲーム）: ~2-3分
- テンポテスト（35ゲーム）: ~10-15分
- パラメータセット比較（50ゲーム）: ~15-20分

### Q: 結果がぶれている（毎回異なる結果）

**A**: これは異常ではなく、統計的な変動です：
- ±3%の誤差は20-30ゲームで期待される
- より正確な測定には50+ゲーム必要

### Q: すべてのパラメータで>53%

**A**: テンポボーナスをさらに低減：
```dart
tempoBonus: 0.2  // 0.5 → 0.2への大幅低減
```

### Q: すべてのパラメータで<47%

**A**: テンポボーナスをさらに増加：
```dart
tempoBonus: 0.8  // 0.5 → 0.8への大幅増加
```

## 📞 サポート

質問や問題がある場合は、`CLAUDE.md` の「Implementation Tips」セクションを参照してください。
