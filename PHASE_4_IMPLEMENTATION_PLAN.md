# Phase 4 実装計画書 - テスト・ストア準備

## 📋 概要

**フェーズ名**: Phase 4（最終段階）  
**目標**: ソフトローンチゴー  
**期間**: 5日間（2026-08-28～09-01）  
**ステータス**: 🔄 計画立案中

---

## 🎯 Phase 4 の目標

本番リリースに向けた最終準備段階

### 成功基準

- [ ] 統合テスト 25局全クリア
- [ ] パフォーマンステスト合格（メモリ/CPU/ネットワーク）
- [ ] エラーシナリオテスト完了
- [ ] App Store / Google Play 提出準備完了
- [ ] ソフトローンチゲート設定完了
- [ ] 計測基盤（Analytics）準備完了

---

## 📊 Phase 4 構成

### 4a: 統合テスト実装（2日）

**タスク 4a-1: エンドツーエンドテスト**
```
目標: 25局の完全ゲーム実行
実装:
- test/phase4_e2e_test.dart (予想: 150行)
- CPU vs CPU 25局自動実行
- 勝率検証（50±5% 想定）
- 実行時間計測

成功基準:
- ✅ 25局全て正常終了
- ✅ ハイライト生成成功率 100%
- ✅ ハイライト生成時間 100-180秒以内
```

**タスク 4a-2: パフォーマンステスト**
```
目標: リソース使用率の計測・最適化
実装:
- メモリリークテスト（連続100ゲーム）
- CPU 使用率監視
- ネットワーク遅延シミュレーション
- バッテリー消費率推定

成功基準:
- ✅ メモリ: 初期 < 50MB、ピーク < 200MB
- ✅ CPU: 平均 < 60%、ピーク < 90%
- ✅ ネットワーク: 遅延時の自動復帰
```

**タスク 4a-3: エラーシナリオテスト**
```
目標: 予期しない状況への対応検証
実装:
- ネットワーク切断時の復帰
- Cloud Functions タイムアウト
- Cloud Storage 容量超過
- ハイライト生成失敗時の表示
- Bitly API 失敗時のフォールバック

成功基準:
- ✅ 全エラーシナリオで適切にハンドル
- ✅ ユーザー操作が常に可能
- ✅ エラーメッセージが明確
```

### 4b: ストア提出準備（2日）

**タスク 4b-1: App Store メタデータ**
```
App Name:       乱舞将棋
Subtitle:       HP制で観戦映えする将棋バリアント
Description:    (1000字程度)
                - ビジョン＆ミッション
                - ゲームルール
                - AI の難易度
                - ハイライト動画共有機能
Keywords:       将棋, ゲーム, ボードゲーム, AI, 配信
Support URL:    https://...
Privacy URL:    https://...

スクリーンショット (5枚):
1. ホーム画面
2. ゲーム盤面
3. 対局結果
4. ハイライト動画
5. ハイライト共有

Preview Video:  (15秒程度)
                ゲームプレイ＆ハイライト自動生成
```

**タスク 4b-2: Google Play メタデータ**
```
同様に App Store と同じ形式で
プライバシーマニフェスト設定も必要
```

**タスク 4b-3: プライバシー＆セキュリティ**
```
チェックリスト:
- [ ] プライバシーポリシー作成・リンク
- [ ] Firebase セキュリティルール確認
- [ ] Firestore データ暗号化確認
- [ ] Cloud Storage アクセス制御確認
- [ ] Analytics トラッキング通知
- [ ] iOS App Privacy (データ収集項目)
- [ ] Google Play の安全性チェック
```

### 4c: ソフトローンチ設定（1日）

**タスク 4c-1: Remote Config ゲーティング**
```
Firestore での制御:
```json
{
  "features": {
    "launch_enabled": true,
    "highlight_generation": true,
    "highlight_sharing": true,
    "analytics_enabled": true
  },
  "limits": {
    "max_daily_games": 10,
    "max_monthly_users": 1000
  },
  "maintenance": {
    "maintenance_mode": false,
    "message": ""
  }
}
```

**タスク 4c-2: Analytics 計測準備**
```
KPI 計測項目:

Day 1 Retention:
- インストール → 1日後のDAU
- 目標: 20% 以上

Aha Moment:
- ハイライト生成成功
- 目標: 60% 以上がハイライト生成経験

Engagement:
- 平均セッション時間
- 目標: 5分以上

Retention (Day 7, 30):
- 7日リテンション: 目標 40%
- 30日リテンション: 目標 15%
```

**タスク 4c-3: ソフトローンチ段階**
```
Stage 1: Internal Testing (Day 1)
- 開発チーム・テスター限定
- TestFlight (iOS) / Google Play Beta (Android)

Stage 2: Closed Beta (Day 2-3)
- 100～500人程度の限定ユーザー
- Feedback 収集

Stage 3: Public Release (Day 4-5)
- 全ユーザーへ公開
- Daily KPI 監視
```

---

## 📁 新規実装ファイル（予想）

### テスト関連
```
test/
├── phase4_e2e_test.dart           (150行)
├── phase4_performance_test.dart   (120行)
└── phase4_error_scenario_test.dart (100行)
```

### ストア準備関連
```
docs/
├── app_store_metadata.md          (200行)
├── google_play_metadata.md        (200行)
├── privacy_policy.md              (300行)
├── terms_of_service.md            (300行)
└── security_checklist.md          (150行)

assets/
├── screenshots/
│   ├── home.png
│   ├── game.png
│   ├── result.png
│   ├── highlight.png
│   └── share.png
└── preview_video.mp4
```

### ソフトローンチ関連
```
lib/
├── config/
│   └── launch_config.dart         (100行)

lib/services/
├── remote_config_service.dart     (150行)
└── analytics_service.dart (修正)   (50行追加)
```

---

## 🚀 実装スケジュール（日別）

### Day 1: 統合テスト基盤構築
- [ ] E2E テスト フレームワーク作成
- [ ] パフォーマンステスト 実装
- [ ] 初回実行・結果確認

### Day 2: テスト実行＆調整
- [ ] 25局完全実行
- [ ] パフォーマンス計測
- [ ] ボトルネック特定・改善

### Day 3: エラーシナリオ＆ストア準備開始
- [ ] エラーシナリオテスト実装
- [ ] スクリーンショット撮影
- [ ] メタデータ作成開始

### Day 4: ストア準備完了＆ソフトローンチ設定
- [ ] プライバシーポリシー確認
- [ ] Remote Config 準備
- [ ] Analytics 計測設定

### Day 5: 最終確認＆ソフトローンチ
- [ ] 全テスト再実行
- [ ] ストア提出準備最終確認
- [ ] TestFlight / Beta 配布

---

## 📊 テスト設計

### E2E テスト（25局）

```dart
// test/phase4_e2e_test.dart
group('Phase 4: End-to-End Tests', () {
  // 25局の連続ゲーム実行
  test('25 consecutive games should complete successfully', () async {
    const numGames = 25;
    int successCount = 0;
    final results = <GameResult>[];

    for (int i = 0; i < numGames; i++) {
      final game = startNewGame();
      
      // ゲーム実行
      while (!game.isGameOver()) {
        final move = ai.getBestMove(game);
        game.applyMove(move);
      }

      // ハイライト生成
      final highlight = await highlightOrchestrator.generateHighlight(game);

      results.add(GameResult(
        gameNumber: i + 1,
        winner: game.winner,
        duration: game.duration,
        highlightSuccess: highlight.success,
        highlightDuration: highlight.elapsedTime,
      ));

      if (highlight.success) {
        successCount++;
      }
    }

    // 結果検証
    expect(successCount, equals(numGames)); // 全て成功
    expect(calculateWinRate(results), inInclusiveRange(0.45, 0.55)); // 勝率50±5%
  });
});
```

### パフォーマンステスト

```dart
// test/phase4_performance_test.dart
group('Phase 4: Performance Tests', () {
  test('Memory usage should stay under 200MB peak', () async {
    final initialMemory = await getMemoryUsage();
    
    // 100局実行
    for (int i = 0; i < 100; i++) {
      final game = startNewGame();
      while (!game.isGameOver()) {
        game.applyMove(ai.getBestMove(game));
      }
    }

    final peakMemory = await getPeakMemoryUsage();
    final finalMemory = await getMemoryUsage();

    print('Memory - Initial: ${initialMemory}MB, Peak: ${peakMemory}MB, Final: ${finalMemory}MB');
    
    expect(peakMemory, lessThan(200)); // ピーク < 200MB
    expect((finalMemory - initialMemory).abs(), lessThan(10)); // 最終的にリーク < 10MB
  });

  test('CPU usage should not exceed 90%', () async {
    // CPU使用率監視
    await monitorCPUDuring(() async {
      for (int i = 0; i < 10; i++) {
        final game = startNewGame();
        while (!game.isGameOver()) {
          game.applyMove(ai.getBestMove(game));
        }
      }
    });

    // CPU 関連の検証
  });
});
```

---

## ✅ チェックリスト

### 統合テスト
- [ ] E2E テスト フレームワーク実装
- [ ] 25局完全実行可能
- [ ] パフォーマンス計測実装
- [ ] エラーシナリオ 10個以上カバー

### ストア準備
- [ ] App Store メタデータ完成
- [ ] Google Play メタデータ完成
- [ ] スクリーンショット 5枚以上
- [ ] プライバシーポリシー作成
- [ ] セキュリティチェックリスト完了

### ソフトローンチ
- [ ] Remote Config 設定完了
- [ ] Analytics イベント定義完了
- [ ] TestFlight / Beta 配布準備
- [ ] KPI 監視ダッシュボード準備

### ドキュメント
- [ ] Phase 4 実装計画書
- [ ] テスト結果レポート
- [ ] パフォーマンス分析レポート
- [ ] ストア提出ガイド
- [ ] ソフトローンチガイド

---

## 📈 期待される成果

### コード品質
- ✅ テスト カバレッジ > 80%
- ✅ メモリリーク なし
- ✅ エラーハンドリング 完全
- ✅ パフォーマンス ベンチマーク達成

### ユーザー体験
- ✅ エラー時の復帰スムーズ
- ✅ ハイライト生成 100% 成功率
- ✅ UI 応答性 良好
- ✅ 共有機能 問題なし

### ビジネス指標
- ✅ Day 1 Retention: 20% 以上
- ✅ Aha Moment: 60% 以上
- ✅ Session Length: 5分以上
- ✅ Day 7 Retention: 40% 以上

---

## 🎓 重要ポイント

### 1. テスト網羅性
- 単体テスト → 統合テスト → E2E テスト
- エラーパスも同じくらい重要

### 2. パフォーマンス
- 実機での計測（エミュレータではなく）
- ネットワーク遅延も再現テスト

### 3. ストア最適化
- メタデータは SEO 観点からも重要
- スクリーンショットはユーザー体験を反映

### 4. ソフトローンチの価値
- 本格リリース前の学習機会
- KPI は毎日確認

---

## 📞 参考リンク

- [App Store Connect Guide](https://developer.apple.com/app-store/)
- [Google Play Console](https://play.google.com/console/)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)

---

**Last Updated**: 2026-08-27  
**Status**: Phase 4 計画立案完了 📋 → 実装開始へ

