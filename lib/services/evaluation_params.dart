/// 評価関数パラメータ管理クラス
/// Phase 2: 先手勝率 50±3% への調整用

import 'package:rambu_shogi/utils/constants.dart';

/// 評価関数の調整可能なパラメータセット
class EvaluationParams {
  /// テンポボーナス（手番プレイヤーへの加点）
  /// 値が高い = 手番プレイヤー有利
  final double tempoBonus;

  /// クリティカル局面の特殊加算
  final double criticalAdjacentBonus;        // 王に隣接
  final double criticalDamageBonus;          // クリティカルダメージ可能
  final double enemyMajorPieceAttackBonus;  // 角/飛を攻撃可能
  final double fullHPBonus;                  // 自駒HP満タン
  final double enemyLowHPBonus;              // 相手駒HP1

  /// 駒価値ウェイト（0.0-1.0）
  /// 1.0に近い = 駒価値を重視、0.0に近い = HP価値を重視
  final double pieceValueWeight;

  /// スコア計算時の係数
  /// これらは全スコアに対する倍率として使用
  final double pieceValueCoefficient;
  final double hpValueCoefficient;
  final double positionValueCoefficient;
  final double criticalSituationCoefficient;

  /// パラメータセットの名前（ログ用）
  final String name;

  /// パラメータの説明（調整理由）
  final String? description;

  const EvaluationParams({
    required this.tempoBonus,
    required this.criticalAdjacentBonus,
    required this.criticalDamageBonus,
    required this.enemyMajorPieceAttackBonus,
    required this.fullHPBonus,
    required this.enemyLowHPBonus,
    required this.pieceValueWeight,
    required this.pieceValueCoefficient,
    required this.hpValueCoefficient,
    required this.positionValueCoefficient,
    required this.criticalSituationCoefficient,
    required this.name,
    this.description,
  });

  /// Phase 1 ベースラインパラメータ
  /// 初期実装時のバランス設定
  static const EvaluationParams baseline = EvaluationParams(
    tempoBonus: 0.5,
    criticalAdjacentBonus: 50.0,
    criticalDamageBonus: 30.0,
    enemyMajorPieceAttackBonus: 20.0,
    fullHPBonus: 5.0,
    enemyLowHPBonus: 15.0,
    pieceValueWeight: 0.5,
    pieceValueCoefficient: 1.0,
    hpValueCoefficient: 1.0,
    positionValueCoefficient: 1.0,
    criticalSituationCoefficient: 1.0,
    name: 'Phase1-Baseline',
    description: 'Initial implementation parameters',
  );

  /// Phase 2a: テンポボーナス削減版
  /// 先手が勝ちすぎている場合の調整案
  static const EvaluationParams senteReduced = EvaluationParams(
    tempoBonus: 0.3,  // 0.5 → 0.3: 手番ボーナス低減
    criticalAdjacentBonus: 40.0,  // 50 → 40: 王隣接ボーナス低減
    criticalDamageBonus: 30.0,
    enemyMajorPieceAttackBonus: 20.0,
    fullHPBonus: 5.0,
    enemyLowHPBonus: 15.0,
    pieceValueWeight: 0.48,  // 0.5 → 0.48: 駒価値低減
    pieceValueCoefficient: 1.0,
    hpValueCoefficient: 1.0,
    positionValueCoefficient: 1.0,
    criticalSituationCoefficient: 1.0,
    name: 'Phase2a-SenteReduced',
    description: 'Reduced sente advantage (tempo bonus 0.5→0.3)',
  );

  /// Phase 2b: テンポボーナス増加版
  /// 後手が勝ちすぎている場合の調整案
  static const EvaluationParams senteStrengthened = EvaluationParams(
    tempoBonus: 0.7,  // 0.5 → 0.7: 手番ボーナス増加
    criticalAdjacentBonus: 50.0,
    criticalDamageBonus: 30.0,
    enemyMajorPieceAttackBonus: 20.0,
    fullHPBonus: 5.0,
    enemyLowHPBonus: 15.0,
    pieceValueWeight: 0.52,  // 0.5 → 0.52: 駒価値増加
    pieceValueCoefficient: 1.0,
    hpValueCoefficient: 1.0,
    positionValueCoefficient: 1.0,
    criticalSituationCoefficient: 1.0,
    name: 'Phase2b-SenteStrengthened',
    description: 'Increased sente advantage (tempo bonus 0.5→0.7)',
  );

  /// Phase 2c: クリティカルボーナス低減版
  /// 終盤が急すぎる場合の調整案
  static const EvaluationParams criticalReduced = EvaluationParams(
    tempoBonus: 0.5,
    criticalAdjacentBonus: 35.0,  // 50 → 35: 王隣接ボーナス大幅低減
    criticalDamageBonus: 20.0,    // 30 → 20: クリティカルボーナス低減
    enemyMajorPieceAttackBonus: 15.0,  // 20 → 15: 主要駒攻撃ボーナス低減
    fullHPBonus: 5.0,
    enemyLowHPBonus: 10.0,        // 15 → 10: 弱い駒ボーナス低減
    pieceValueWeight: 0.5,
    pieceValueCoefficient: 1.0,
    hpValueCoefficient: 1.0,
    positionValueCoefficient: 1.0,
    criticalSituationCoefficient: 0.8,  // 全クリティカル係数低減
    name: 'Phase2c-CriticalReduced',
    description: 'Reduced critical bonuses (makes mid-game matter more)',
  );

  /// Phase 2d: バランス重視版
  /// 全体的に慎重な調整
  static const EvaluationParams balanced = EvaluationParams(
    tempoBonus: 0.4,  // 中程度
    criticalAdjacentBonus: 45.0,  // 中程度
    criticalDamageBonus: 25.0,    // 中程度
    enemyMajorPieceAttackBonus: 18.0,
    fullHPBonus: 5.0,
    enemyLowHPBonus: 12.0,
    pieceValueWeight: 0.5,
    pieceValueCoefficient: 1.0,
    hpValueCoefficient: 1.0,
    positionValueCoefficient: 1.0,
    criticalSituationCoefficient: 0.9,
    name: 'Phase2d-Balanced',
    description: 'Conservative balanced parameters (all reduced slightly)',
  );

  @override
  String toString() => '$name${description != null ? ": $description" : ""}';

  /// パラメータをバリエーション生成
  /// テンポボーナスを段階的に変更した複数のパラメータセットを返す
  static List<EvaluationParams> generateTempoVariations() {
    final variations = <EvaluationParams>[];
    for (double tempo = 0.2; tempo <= 0.8; tempo += 0.1) {
      variations.add(EvaluationParams(
        tempoBonus: tempo,
        criticalAdjacentBonus: 50.0,
        criticalDamageBonus: 30.0,
        enemyMajorPieceAttackBonus: 20.0,
        fullHPBonus: 5.0,
        enemyLowHPBonus: 15.0,
        pieceValueWeight: 0.5,
        pieceValueCoefficient: 1.0,
        hpValueCoefficient: 1.0,
        positionValueCoefficient: 1.0,
        criticalSituationCoefficient: 1.0,
        name: 'TempoVariation-${tempo.toStringAsFixed(1)}',
        description: 'Tempo bonus = $tempo',
      ));
    }
    return variations;
  }

  /// パラメータを定数クラスから取得
  /// （既存の EvaluationConstants との互換性用）
  static EvaluationParams fromConstants() {
    return const EvaluationParams(
      tempoBonus: EvaluationConstants.tempoBonus,
      criticalAdjacentBonus: EvaluationConstants.criticalAdjacentBonus,
      criticalDamageBonus: EvaluationConstants.criticalDamageBonus,
      enemyMajorPieceAttackBonus: EvaluationConstants.enemyMajorPieceAttackBonus,
      fullHPBonus: EvaluationConstants.fullHPBonus,
      enemyLowHPBonus: EvaluationConstants.enemyLowHPBonus,
      pieceValueWeight: EvaluationConstants.normalPieceValueWeight,
      pieceValueCoefficient: 1.0,
      hpValueCoefficient: 1.0,
      positionValueCoefficient: 1.0,
      criticalSituationCoefficient: 1.0,
      name: 'FromConstants',
      description: 'Imported from EvaluationConstants',
    );
  }
}
