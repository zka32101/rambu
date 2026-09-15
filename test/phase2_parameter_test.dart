/// Phase 2: パラメータ調整テスト
///
/// 実行: `dart run test/phase2_parameter_test.dart`
/// 目的: 先手勝率 50±3% を達成するパラメータを発見
///
/// テスト戦略:
/// 1. ベースラインパラメータで10ゲーム実行
/// 2. テンポボーナス変動テストで最適値を探索（各5ゲーム）
/// 3. 最適パラメータで40ゲーム検証

import 'dart:io';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/benchmark_utils.dart';
import 'package:rambu_shogi/services/evaluation_params.dart';

void main() async {
  print('🎯 乱舞将棋 Phase 2 パラメータ調整テスト');
  print('═' * 60);
  print('目標: 先手勝率 50±3%（中級）\n');

  // ステップ 1: ベースラインテスト
  await _runBaselineTest();

  // ステップ 2: テンポボーナス変動テスト
  await _runTempoVariationTest();

  // ステップ 3: 他のパラメータセット比較
  await _runParameterSetComparison();

  print('\n✅ Phase 2 テスト完了！');
}

/// ステップ 1: ベースラインパラメータテスト
Future<void> _runBaselineTest() async {
  print('\n📊 ステップ 1: ベースラインテスト');
  print('─' * 60);

  final result = await BenchmarkUtils.runBenchmark(
    Difficulty.normal,
    games: 10,
    params: EvaluationParams.baseline,
  );

  print('\n' + result.toReport());

  if (!result.isBalanced) {
    print('ℹ️  ベースライン: バランス調整が必要');
    if (result.isSenteAdvantage) {
      print('   → 先手が勝ちすぎています（先手勝率: ${(result.senteWinRate * 100).toStringAsFixed(1)}%）');
      print('   → テンポボーナス削減を検討します');
    } else {
      print('   → 後手が勝ちすぎています（先手勝率: ${(result.senteWinRate * 100).toStringAsFixed(1)}%）');
      print('   → テンポボーナス増加を検討します');
    }
  }
}

/// ステップ 2: テンポボーナス変動テスト
Future<void> _runTempoVariationTest() async {
  print('\n🔄 ステップ 2: テンポボーナス変動テスト');
  print('─' * 60);
  print('各テンポボーナス値で5ゲーム実行して最適値を探索\n');

  final results = await BenchmarkUtils.tempoVariationTest(
    difficulty: Difficulty.normal,
    gamesPerTempo: 5,
  );

  BenchmarkUtils.printComparisonReport(results);

  // 最適パラメータを特定
  results.sort((a, b) =>
      (a.senteWinRate - 0.5).abs()
          .compareTo((b.senteWinRate - 0.5).abs()));

  if (results.isNotEmpty) {
    final best = results.first;
    print('\n💡 推奨: テンポボーナスを ${best.paramName} に設定');
  }
}

/// ステップ 3: 複数パラメータセット比較
Future<void> _runParameterSetComparison() async {
  print('\n🔀 ステップ 3: パラメータセット比較テスト');
  print('─' * 60);
  print('複数の事前定義パラメータセットで10ゲーム実行\n');

  final paramsList = [
    EvaluationParams.baseline,
    EvaluationParams.senteReduced,
    EvaluationParams.senteStrengthened,
    EvaluationParams.criticalReduced,
    EvaluationParams.balanced,
  ];

  final results = await BenchmarkUtils.compareParameters(
    Difficulty.normal,
    paramsList: paramsList,
    gamesPerParam: 10,
  );

  BenchmarkUtils.printComparisonReport(results);

  // 結果分析
  print('\n📋 結果分析:');
  final balanced =
      results.where((r) => r.isBalanced).toList();
  final sente = results.where((r) => r.isSenteAdvantage).toList();
  final gote = results.where((r) => r.isGoteAdvantage).toList();

  print('バランス型: ${balanced.length}/${results.length}');
  if (balanced.isNotEmpty) {
    print('  → ${balanced.map((r) => r.paramName).join(', ')}');
  }

  print('先手優位型: ${sente.length}/${results.length}');
  if (sente.isNotEmpty) {
    print('  → ${sente.map((r) => r.paramName).join(', ')}');
  }

  print('後手優位型: ${gote.length}/${results.length}');
  if (gote.isNotEmpty) {
    print('  → ${gote.map((r) => r.paramName).join(', ')}');
  }
}
