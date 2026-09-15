/// Transposition Table
/// アルファベータ探索のキャッシング機構
///
/// 機能:
/// - 局面の評価値キャッシング
/// - ハッシュテーブルによる高速検索
/// - Zobrist Hashing での競合最小化
/// - LRU（最近使用）キャッシュ削除

import 'dart:math' as math;
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/game_session.dart';

/// トランスポジション テーブル エントリ
class TranspositionEntry {
  /// ハッシュキー（局面を一意に識別）
  final int hashKey;

  /// 深さ（この深さで評価）
  final int depth;

  /// 評価値
  final int evaluation;

  /// フラグ（exact / lower bound / upper bound）
  final int flag;  // 0=exact, 1=lower, 2=upper

  /// このエントリーが最後にアクセスされた時刻（LRU用）
  int lastAccessTime;

  /// エントリーが格納された時刻
  final int createdTime;

  TranspositionEntry({
    required this.hashKey,
    required this.depth,
    required this.evaluation,
    required this.flag,
    required int timestamp,
  })  : lastAccessTime = timestamp,
        createdTime = timestamp;

  /// エントリーの情報を文字列化
  @override
  String toString() =>
      'TTE(key=$hashKey, depth=$depth, eval=$evaluation, flag=$flag)';
}

/// Transposition Table
///
/// アルファベータ探索で訪問した局面を記録し、同じ局面の再評価を避ける
class TranspositionTable {
  /// テーブルサイズ（デフォルト: 65536エントリー）
  /// メモリ効率: 各エントリー ~64bytes × 65536 = 4MB
  static const int defaultSize = 65536;

  /// ハッシュテーブル
  late final List<TranspositionEntry?> _table;

  /// テーブルサイズ
  late final int _size;

  /// アクセスカウント（LRU用）
  int _accessCounter = 0;

  /// キャッシュヒット数
  int _hits = 0;

  /// キャッシュミス数
  int _misses = 0;

  /// 衝突数
  int _collisions = 0;

  /// 初期化
  TranspositionTable({int size = defaultSize}) {
    _size = _nextPowerOfTwo(size);
    _table = List<TranspositionEntry?>(_size);
  }

  /// 次の2の累乗を取得
  static int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  /// ハッシュキーを計算（Zobrist Hashing風）
  ///
  /// 簡略版: ボード全体をスキャンしてハッシュ生成
  int calculateHash(GameSession gameSession) {
    int hash = 0;

    // ボードの全升をスキャン
    for (int x = 0; x < 9; x++) {
      for (int y = 0; y < 9; y++) {
        final piece = gameSession.board.getPiece(x, y);
        if (piece != null) {
          // 駒タイプ × プレイヤー × 位置でハッシュ生成
          final typeHash = piece.type.hashCode ^ piece.player.hashCode;
          final posHash = (x * 100 + y).hashCode;
          hash ^= (typeHash * 73856093) ^ (posHash * 19349663);
        }
      }
    }

    // ターン情報も含める
    hash ^= gameSession.currentTurn.hashCode * 83492791;

    return hash.abs();  // 負の数を避ける
  }

  /// テーブルにエントリーを格納
  void store(
    int hashKey,
    int depth,
    int evaluation,
    int flag,
  ) {
    _accessCounter++;

    final index = hashKey & (_size - 1);  // hashKey % _size（ビット演算最適化）

    // 衝突をチェック
    if (_table[index] != null && _table[index]!.hashKey != hashKey) {
      _collisions++;

      // 置き換え戦略: 浅い深さのエントリーを上書き
      if (_table[index]!.depth >= depth) {
        return;  // 既存が深いならスキップ
      }
    }

    _table[index] = TranspositionEntry(
      hashKey: hashKey,
      depth: depth,
      evaluation: evaluation,
      flag: flag,
      timestamp: _accessCounter,
    );
  }

  /// テーブルからエントリーを取得
  TranspositionEntry? lookup(int hashKey, int depth) {
    _accessCounter++;

    final index = hashKey & (_size - 1);
    final entry = _table[index];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.hashKey != hashKey) {
      _misses++;
      return null;  // ハッシュ値不一致（衝突）
    }

    if (entry.depth < depth) {
      _misses++;
      return null;  // 要求深さより浅いエントリー
    }

    // ヒット
    _hits++;
    entry.lastAccessTime = _accessCounter;
    return entry;
  }

  /// テーブルをクリア
  void clear() {
    _table.fillRange(0, _size, null);
    _hits = 0;
    _misses = 0;
    _collisions = 0;
    _accessCounter = 0;
  }

  /// メモリ使用状況をリセット（古いエントリーを削除）
  void cleanup() {
    // 最も古いエントリーを削除（LRU戦略）
    final threshold = (_accessCounter * 0.7).toInt();

    for (int i = 0; i < _size; i++) {
      final entry = _table[i];
      if (entry != null && entry.lastAccessTime < threshold) {
        _table[i] = null;
      }
    }
  }

  /// キャッシュ統計情報を取得
  Map<String, dynamic> getStatistics() {
    final total = _hits + _misses;
    final hitRate = total > 0 ? (_hits / total * 100) : 0;

    return {
      'hits': _hits,
      'misses': _misses,
      'hit_rate': hitRate,
      'collisions': _collisions,
      'total_lookups': total,
      'table_size': _size,
      'entries_stored': _table.where((e) => e != null).length,
      'utilization_percent': (_table.where((e) => e != null).length / _size * 100),
    };
  }

  /// 統計情報をリセット
  void resetStatistics() {
    _hits = 0;
    _misses = 0;
    _collisions = 0;
  }

  /// デバッグ用: テーブル内容を表示
  void debugPrint() {
    final stats = getStatistics();
    print('=== Transposition Table Statistics ===');
    print('Hits: ${stats['hits']}');
    print('Misses: ${stats['misses']}');
    print('Hit Rate: ${(stats['hit_rate'] as double).toStringAsFixed(2)}%');
    print('Collisions: ${stats['collisions']}');
    print('Entries Stored: ${stats['entries_stored']}/${stats['table_size']}');
    print('Utilization: ${(stats['utilization_percent'] as double).toStringAsFixed(1)}%');
  }
}

/// Zobrist Hashing Manager
///
/// より高度なハッシング戦略用（将来の拡張）
class ZobristHasher {
  /// ランダムハッシュ値テーブル
  /// zobristTable[piece][x][y] = 駒がx,yにいる時のハッシュ値
  late final List<List<List<int>>> zobristTable;

  /// ターン用ハッシュ値
  final int turnHash = 0x123456789;

  /// 初期化
  ZobristHasher() {
    _initializeTable();
  }

  /// Zobristテーブルを初期化
  void _initializeTable() {
    final random = math.Random(0xDEADBEEF);  // 再現可能なRNG

    // 駒種 × 位置 のハッシュテーブル初期化
    zobristTable = List.generate(
      16,  // 駒タイプ数（簡略化）
      (_) => List.generate(
        9,
        (_) => List.generate(
          9,
          (_) => random.nextInt(0x7FFFFFFF),
        ),
      ),
    );
  }

  /// Zobrist法でハッシュを計算
  int calculateHash(GameSession gameSession) {
    int hash = turnHash;

    for (int x = 0; x < 9; x++) {
      for (int y = 0; y < 9; y++) {
        final piece = gameSession.board.getPiece(x, y);
        if (piece != null) {
          final pieceIndex = _getPieceIndex(piece);
          hash ^= zobristTable[pieceIndex][x][y];
        }
      }
    }

    return hash.abs();
  }

  /// 駒をインデックス化
  int _getPieceIndex(Piece piece) {
    // 簡略実装: type.hashCode の下位4ビット × player.hashCode
    return (piece.type.hashCode ^ (piece.player.hashCode << 4)) & 0x0F;
  }
}

/// Alpha-Beta 探索用 Transposition Table Wrapper
class AlphaBetaTranspositionTable {
  /// 基本テーブル
  final TranspositionTable _table;

  /// 検索深さ
  int _currentDepth = 0;

  AlphaBetaTranspositionTable({int size = TranspositionTable.defaultSize})
      : _table = TranspositionTable(size: size);

  /// Alpha-Beta 用フラグ定数
  static const int flagExact = 0;    // α < eval < β
  static const int flagLower = 1;    // eval >= β（カットオフ）
  static const int flagUpper = 2;    // eval <= α（カットオフ）

  /// 評価値を格納
  void storeEvaluation(
    int hashKey,
    int depth,
    int evaluation, {
    required int alpha,
    required int beta,
  }) {
    late int flag;

    if (evaluation <= alpha) {
      flag = flagUpper;
    } else if (evaluation >= beta) {
      flag = flagLower;
    } else {
      flag = flagExact;
    }

    _table.store(hashKey, depth, evaluation, flag);
  }

  /// 評価値を取得（Alpha-Beta用）
  int? lookupEvaluation(
    int hashKey,
    int depth, {
    required int alpha,
    required int beta,
  }) {
    final entry = _table.lookup(hashKey, depth);
    if (entry == null) return null;

    // フラグに応じて利用可能な情報を返す
    switch (entry.flag) {
      case flagExact:
        return entry.evaluation;  // 正確な値
      case flagLower:
        // entry.evaluation >= beta なら、αβ剪定に使える
        return entry.evaluation >= beta ? entry.evaluation : null;
      case flagUpper:
        // entry.evaluation <= alpha なら、αβ剪定に使える
        return entry.evaluation <= alpha ? entry.evaluation : null;
      default:
        return null;
    }
  }

  /// テーブルクリア
  void clear() => _table.clear();

  /// 統計情報取得
  Map<String, dynamic> getStatistics() => _table.getStatistics();

  /// 統計情報リセット
  void resetStatistics() => _table.resetStatistics();

  /// デバッグ出力
  void debugPrint() => _table.debugPrint();

  /// クリーンアップ
  void cleanup() => _table.cleanup();
}
