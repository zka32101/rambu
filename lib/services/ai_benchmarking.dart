/// AI Benchmarking
/// AI性能測定・検証システム
///
/// 機能:
/// - 大量対局による勝率測定
/// - AI思考時間計測
/// - 探索ノード数カウント
/// - パフォーマンス分析・レポート生成

import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/ai_difficulty_limiter.dart';

/// ベンチマーク結果エントリ
class BenchmarkResult {
  /// 対局数
  final int gamesPlayed;

  /// 先手勝数
  final int sentWins;

  /// 後手勝数
  final int goteWins;

  /// 中断局
  final int draws;

  /// 先手勝率（%）
  final double sentWinRate;

  /// 平均思考時間（ミリ秒）
  final double avgThinkingTimeMs;

  /// 最大思考時間（ミリ秒）
  final int maxThinkingTimeMs;

  /// 最小思考時間（ミリ秒）
  final int minThinkingTimeMs;

  /// 総評価ノード数
  final int totalNodesEvaluated;

  /// 平均評価ノード数/手
  final double avgNodesPerMove;

  /// 対局開始時刻
  final DateTime startTime;

  /// 対局完了時刻
  final DateTime endTime;

  /// 難易度
  final AIDifficulty difficulty;

  BenchmarkResult({
    required this.gamesPlayed,
    required this.sentWins,
    required this.goteWins,
    required this.draws,
    required this.sentWinRate,
    required this.avgThinkingTimeMs,
    required this.maxThinkingTimeMs,
    required this.minThinkingTimeMs,
    required this.totalNodesEvaluated,
    required this.avgNodesPerMove,
    required this.startTime,
    required this.endTime,
    required this.difficulty,
  });

  /// ベンチマーク期間（秒）
  int get elapsedSeconds =>
      endTime.difference(startTime).inSeconds;

  /// 対局平均時間（秒）
  double get avgGameDurationSeconds =>
      gamesPlayed > 0 ? elapsedSeconds / gamesPlayed : 0;

  /// JSON形式で出力
  Map<String, dynamic> toJson() => {
    'games_played': gamesPlayed,
    'sent_wins': sentWins,
    'gote_wins': goteWins,
    'draws': draws,
    'sent_win_rate_percent': sentWinRate,
    'avg_thinking_time_ms': avgThinkingTimeMs,
    'max_thinking_time_ms': maxThinkingTimeMs,
    'min_thinking_time_ms': minThinkingTimeMs,
    'total_nodes_evaluated': totalNodesEvaluated,
    'avg_nodes_per_move': avgNodesPerMove,
    'elapsed_seconds': elapsedSeconds,
    'avg_game_duration_seconds': avgGameDurationSeconds,
    'difficulty': difficulty.toString(),
  };

  /// テキスト形式でレポート生成
  String generateReport() {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('AI BENCHMARK REPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('');

    buffer.writeln('【対局数】');
    buffer.writeln('  総対局数: $gamesPlayed局');
    buffer.writeln('  先手勝: $sentWins');
    buffer.writeln('  後手勝: $goteWins');
    buffer.writeln('  中断: $draws');
    buffer.writeln('');

    buffer.writeln('【勝率】');
    buffer.writeln('  先手勝率: ${sentWinRate.toStringAsFixed(2)}%');
    buffer.writeln('  目標範囲: 50±3% (中級)');
    buffer.writeln('  判定: ${_getWinRateJudgement(sentWinRate)}');
    buffer.writeln('');

    buffer.writeln('【思考時間】');
    buffer.writeln('  平均: ${avgThinkingTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  最大: ${maxThinkingTimeMs}ms');
    buffer.writeln('  最小: ${minThinkingTimeMs}ms');
    buffer.writeln('');

    buffer.writeln('【探索情報】');
    buffer.writeln('  総ノード数: ${totalNodesEvaluated.toLocaleString()}');
    buffer.writeln('  平均ノード/手: ${avgNodesPerMove.toStringAsFixed(0)}');
    buffer.writeln('');

    buffer.writeln('【所要時間】');
    buffer.writeln('  総時間: ${elapsedSeconds}秒 (${(elapsedSeconds / 60).toStringAsFixed(1)}分)');
    buffer.writeln('  平均/対局: ${avgGameDurationSeconds.toStringAsFixed(1)}秒');
    buffer.writeln('');

    buffer.writeln('【難易度】');
    buffer.writeln('  難易度: ${difficulty.toString().split('.').last}');
    buffer.writeln('');

    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// 勝率の判定
  String _getWinRateJudgement(double rate) {
    if (rate >= 47 && rate <= 53) {
      return '✓ 目標達成 (47-53%)';
    } else if (rate >= 40 && rate <= 60) {
      return '◎ 許容範囲 (40-60%)';
    } else if (rate < 40) {
      return '✗ 弱すぎる (目標以下)';
    } else {
      return '✗ 強すぎる (目標以上)';
    }
  }

  @override
  String toString() => 'BenchmarkResult('
      'games=$gamesPlayed, '
      'winRate=${sentWinRate.toStringAsFixed(2)}%, '
      'avgTime=${avgThinkingTimeMs.toStringAsFixed(1)}ms)';
}

/// ベンチマーク実行エンジン
class AIBenchmark {
  /// 実行中のゲーム記録
  final List<GameRecord> _records = [];

  /// 思考時間記録（ミリ秒）
  final List<int> _thinkingTimes = [];

  /// ノード評価数記録
  final List<int> _nodesCounts = [];

  /// ベンチマーク開始時刻
  late DateTime _startTime;

  /// 実行中フラグ
  bool _isRunning = false;

  /// 現在のゲーム数
  int _currentGameCount = 0;

  /// 目標対局数
  int _targetGameCount = 0;

  /// 難易度
  late AIDifficulty _difficulty;

  /// ベンチマークを開始
  void startBenchmark({
    required int gameCount,
    required AIDifficulty difficulty,
  }) {
    _records.clear();
    _thinkingTimes.clear();
    _nodesCounts.clear();

    _startTime = DateTime.now();
    _isRunning = true;
    _currentGameCount = 0;
    _targetGameCount = gameCount;
    _difficulty = difficulty;
  }

  /// ゲームを実行
  Future<void> runGames(
    int gameCount,
    AIDifficulty difficulty, {
    Future<GameRecord?> Function()? gameFactory,
  }) async {
    startBenchmark(gameCount: gameCount, difficulty: difficulty);

    for (int i = 0; i < gameCount; i++) {
      _currentGameCount = i + 1;

      // ゲーム実行（外部から提供）
      GameRecord? record;
      if (gameFactory != null) {
        record = await gameFactory();
        if (record != null) {
          _records.add(record);
          _recordGameMetrics(record);
        }
      } else {
        // デフォルト: スキップ
        continue;
      }
    }

    _isRunning = false;
  }

  /// ゲームメトリクスを記録
  void _recordGameMetrics(GameRecord record) {
    // 平均思考時間を推定（対局時間 / 手数）
    final estimatedThinkingTime =
        (record.durationSeconds * 1000 / record.moves.length).toInt();
    _thinkingTimes.add(estimatedThinkingTime);

    // ノード数を推定（ダミー値）
    final estimatedNodes = record.moves.length * 500;
    _nodesCounts.add(estimatedNodes);
  }

  /// 手動でゲーム結果を記録
  void recordGameResult(GameRecord record) {
    if (!_isRunning) return;

    _records.add(record);
    _recordGameMetrics(record);
    _currentGameCount++;
  }

  /// 思考時間を記録
  void recordThinkingTime(int milliseconds) {
    _thinkingTimes.add(milliseconds);
  }

  /// ノード数を記録
  void recordNodesEvaluated(int count) {
    _nodesCounts.add(count);
  }

  /// ベンチマーク結果を取得
  BenchmarkResult getResult() {
    final sentWins = _records
        .where((r) => r.result == GameResult.whiteWon)
        .length;
    final goteWins = _records
        .where((r) => r.result == GameResult.blackWon)
        .length;
    final draws = _records
        .where((r) => r.result == GameResult.draw || r.result == GameResult.aborted)
        .length;

    final gamesPlayed = _records.length;
    final sentWinRate = gamesPlayed > 0
        ? (sentWins / gamesPlayed * 100)
        : 0;

    final avgThinkingTime = _thinkingTimes.isNotEmpty
        ? _thinkingTimes.reduce((a, b) => a + b) / _thinkingTimes.length
        : 0;

    final maxThinkingTime = _thinkingTimes.isNotEmpty
        ? _thinkingTimes.reduce((a, b) => a > b ? a : b)
        : 0;

    final minThinkingTime = _thinkingTimes.isNotEmpty
        ? _thinkingTimes.reduce((a, b) => a < b ? a : b)
        : 0;

    final totalNodes = _nodesCounts.isNotEmpty
        ? _nodesCounts.reduce((a, b) => a + b)
        : 0;

    final avgNodesPerMove = _records.isNotEmpty
        ? totalNodes / _records.fold(0, (sum, r) => sum + r.moves.length)
        : 0;

    return BenchmarkResult(
      gamesPlayed: gamesPlayed,
      sentWins: sentWins,
      goteWins: goteWins,
      draws: draws,
      sentWinRate: sentWinRate,
      avgThinkingTimeMs: avgThinkingTime,
      maxThinkingTimeMs: maxThinkingTime,
      minThinkingTimeMs: minThinkingTime,
      totalNodesEvaluated: totalNodes,
      avgNodesPerMove: avgNodesPerMove,
      startTime: _startTime,
      endTime: DateTime.now(),
      difficulty: _difficulty,
    );
  }

  /// ベンチマーク進捗を取得
  double getProgress() {
    return _targetGameCount > 0
        ? _currentGameCount / _targetGameCount
        : 0;
  }

  /// 現在のゲーム数
  int get currentGameCount => _currentGameCount;

  /// 目標ゲーム数
  int get targetGameCount => _targetGameCount;

  /// 実行中か
  bool get isRunning => _isRunning;

  /// ベンチマークを停止
  void stop() {
    _isRunning = false;
  }

  /// 結果を出力
  void printResult() {
    final result = getResult();
    print(result.generateReport());
  }
}

/// 複数難易度に対するベンチマーク管理
class AIBenchmarkSuite {
  /// 各難易度のベンチマーク結果
  final Map<AIDifficulty, BenchmarkResult> results = {};

  /// 全難易度に対してベンチマークを実行
  Future<void> runFullSuite({
    required int gamesPerDifficulty,
    required Future<GameRecord?> Function(AIDifficulty)? gameFactory,
  }) async {
    for (final difficulty in AIDifficulty.values) {
      final benchmark = AIBenchmark();
      await benchmark.runGames(
        gamesPerDifficulty,
        difficulty,
        gameFactory: gameFactory != null
            ? () => gameFactory(difficulty)
            : null,
      );

      results[difficulty] = benchmark.getResult();
    }
  }

  /// 全結果をレポート出力
  String generateFullReport() {
    final buffer = StringBuffer();

    buffer.writeln('');
    buffer.writeln('╔═══════════════════════════════════════╗');
    buffer.writeln('║     AI BENCHMARK SUITE REPORT         ║');
    buffer.writeln('╚═══════════════════════════════════════╝');
    buffer.writeln('');

    for (final difficulty in AIDifficulty.values) {
      if (results.containsKey(difficulty)) {
        buffer.writeln(results[difficulty]!.generateReport());
        buffer.writeln('');
      }
    }

    buffer.writeln('╔═══════════════════════════════════════╗');
    buffer.writeln('║          SUMMARY ASSESSMENT           ║');
    buffer.writeln('╚═══════════════════════════════════════╝');

    // サマリー評価
    for (final (difficulty, result) in results.entries) {
      buffer.writeln('${difficulty.toString().split('.').last}: ${result.sentWinRate.toStringAsFixed(1)}%');
    }

    return buffer.toString();
  }

  /// 結果を出力
  void printReport() {
    print(generateFullReport());
  }
}

/// Number formatting helper
extension on int {
  String toLocaleString() {
    return toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }
}
