/// Kifu Formatter
/// 対局記録の棋譜フォーマット出力
///
/// サポートフォーマット:
/// - KIF (日本将棋協会標準フォーマット)
/// - KI2 (コンパクト棋譜フォーマット)
/// - JSON（構造化フォーマット）

import 'package:rambu_shogi/models/game_record.dart';
import 'package:rambu_shogi/models/move.dart';

/// Kifu Formatter Service
class KifuFormatter {
  /// KIF形式で出力
  ///
  /// 日本将棋協会標準の.kif形式
  /// メタデータ + 棋譜をテキスト形式で出力
  static String toKIF(GameRecord record) {
    final buffer = StringBuffer();

    // メタデータセクション
    buffer.writeln('開始日時：${_formatDateTime(record.playedAt)}');
    buffer.writeln('プレイヤー：${record.playerName}');
    buffer.writeln('対手：将棋エンジン (${record.aiDifficulty})');
    buffer.writeln('難易度：${record.aiDifficulty}');
    buffer.writeln('手数：${record.moves.length}');
    buffer.writeln('時間：${(record.durationSeconds / 60).toStringAsFixed(1)}分');
    buffer.writeln('先手：${record.playerColor == 'sente' ? record.playerName : '将棋エンジン'}');
    buffer.writeln('後手：${record.playerColor == 'sente' ? '将棋エンジン' : record.playerName}');
    buffer.writeln('結果：${_formatResult(record.result)}');
    buffer.writeln('');

    // 棋譜セクション
    int moveCount = 1;
    for (int i = 0; i < record.moves.length; i++) {
      final moveData = record.moves[i];
      final fromX = moveData['from']['x'] as int;
      final fromY = moveData['from']['y'] as int;
      final toX = moveData['to']['x'] as int;
      final toY = moveData['to']['y'] as int;
      final player = moveData['player'] as String;
      final pieceType = moveData['piece_type'] as String;
      final damage = moveData['damage'] as int? ?? 0;

      buffer.write('$moveCount. ');
      buffer.write(_formatMoveNotation(fromX, fromY, toX, toY, pieceType));
      buffer.write('  ');
      buffer.write('(${damage > 0 ? '$damage点' : 'ノーダメ'})');
      buffer.writeln('');

      // 偶数手ごとに手数をインクリメント
      if (i % 2 == 1) {
        moveCount++;
      }
    }

    // 最終結果
    buffer.writeln('');
    buffer.writeln(_formatResult(record.result));

    return buffer.toString();
  }

  /// KI2形式で出力
  ///
  /// コンパクト棋譜フォーマット（単行形式）
  static String toKI2(GameRecord record) {
    final buffer = StringBuffer();

    // ヘッダー
    buffer.writeln('# 棋譜ファイル');
    buffer.writeln('# プレイヤー: ${record.playerName}');
    buffer.writeln('# 日時: ${_formatDateTime(record.playedAt)}');
    buffer.writeln('# 難易度: ${record.aiDifficulty}');
    buffer.writeln('# 結果: ${_formatResult(record.result)}');
    buffer.writeln('');

    // 棋譜（コンパクト形式）
    final moves = <String>[];
    for (int i = 0; i < record.moves.length; i++) {
      final moveData = record.moves[i];
      final fromX = moveData['from']['x'] as int;
      final fromY = moveData['from']['y'] as int;
      final toX = moveData['to']['x'] as int;
      final toY = moveData['to']['y'] as int;
      final pieceType = moveData['piece_type'] as String;

      moves.add(_formatCompactMove(fromX, fromY, toX, toY, pieceType));
    }

    // 1行に20手まで表示
    for (int i = 0; i < moves.length; i += 20) {
      final chunk = moves.sublist(i, (i + 20).clamp(0, moves.length));
      buffer.writeln(chunk.join(' '));
    }

    return buffer.toString();
  }

  /// JSON形式で出力
  ///
  /// 構造化フォーマット（アプリ間連携用）
  static String toJSON(GameRecord record, {bool pretty = false}) {
    final json = record.toJson();

    if (pretty) {
      return _prettyPrintJson(json);
    } else {
      return _jsonEncode(json);
    }
  }

  /// JSONエンコード（簡易実装）
  static String _jsonEncode(dynamic obj) {
    if (obj == null) return 'null';

    if (obj is String) {
      // エスケープ処理
      final escaped = obj
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('\t', '\\t');
      return '"$escaped"';
    }

    if (obj is bool) return obj ? 'true' : 'false';
    if (obj is num) return obj.toString();

    if (obj is List) {
      final items = obj.map((item) => _jsonEncode(item)).join(',');
      return '[$items]';
    }

    if (obj is Map) {
      final items = obj.entries
          .map((e) => '${_jsonEncode(e.key)}:${_jsonEncode(e.value)}')
          .join(',');
      return '{$items}';
    }

    return '"unknown"';
  }

  /// JSON美整形（インデント付き）
  static String _prettyPrintJson(dynamic obj, {int indent = 0}) {
    final padding = '  ' * indent;
    final nextPadding = '  ' * (indent + 1);

    if (obj == null) return 'null';
    if (obj is String) return '"${obj.replaceAll('"', '\\"')}"';
    if (obj is bool) return obj ? 'true' : 'false';
    if (obj is num) return obj.toString();

    if (obj is List) {
      if (obj.isEmpty) return '[]';
      final items = obj
          .map((item) => '$nextPadding${_prettyPrintJson(item, indent: indent + 1)}')
          .join(',\n');
      return '[\n$items\n$padding]';
    }

    if (obj is Map) {
      if (obj.isEmpty) return '{}';
      final items = obj.entries
          .map((e) =>
              '$nextPadding"${e.key}": ${_prettyPrintJson(e.value, indent: indent + 1)}')
          .join(',\n');
      return '{\n$items\n$padding}';
    }

    return '"unknown"';
  }

  /// 移動表記をフォーマット（標準形式）
  ///
  /// 例: "26歩打" or "55歩-54歩"
  static String _formatMoveNotation(
    int fromX,
    int fromY,
    int toX,
    int toY,
    String pieceType,
  ) {
    final pieceName = _getPieceName(pieceType);

    // 到達地点を標準座標で表記
    final toPos = '${toX}${toY}';

    // 出発地点があれば表記（駒打ちはなし）
    if (fromX >= 1 && fromX <= 9 && fromY >= 1 && fromY <= 9) {
      return '$toPos$pieceName(${fromX}${fromY})';
    } else {
      // 駒打ち（盤外から）
      return '$toPos${pieceName}打';
    }
  }

  /// コンパクト移動表記
  ///
  /// 例: "2626" (from 2,6 to 2,6)
  static String _formatCompactMove(
    int fromX,
    int fromY,
    int toX,
    int toY,
    String pieceType,
  ) {
    return '$fromX$fromY$toX$toY';
  }

  /// 駒タイプを名前に変換
  static String _getPieceName(String pieceType) {
    return switch (pieceType) {
      'pawn' => '歩',
      'lance' => '香',
      'knight' => '桂',
      'silver' => '銀',
      'gold' => '金',
      'bishop' => '角',
      'rook' => '飛',
      'king' => '玉',
      _ => '？',
    };
  }

  /// 日付時刻をフォーマット
  static String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year年$month月$day日 $hour時$minute分';
  }

  /// ゲーム結果をフォーマット
  static String _formatResult(GameResult result) {
    return switch (result) {
      GameResult.whiteWon => '白の勝ち',
      GameResult.blackWon => '黒の勝ち',
      GameResult.draw => '中断',
      GameResult.aborted => '中止',
    };
  }

  /// 複数ゲーム記録をまとめてエクスポート
  static String exportMultiple(
    List<GameRecord> records, {
    String format = 'json',
  }) {
    if (format.toLowerCase() == 'json') {
      return _jsonEncode(records.map((r) => r.toJson()).toList());
    } else {
      // KIF形式の場合は各記録をセパレーターで区切る
      return records.map((r) => toKIF(r)).join('\n${_separator()}\n\n');
    }
  }

  /// セパレーター
  static String _separator() {
    return '=' * 60;
  }
}

/// Kifu Formatter Service Provider
class KifuFormatterService {
  /// ゲーム記録をKIF形式で文字列化
  String formatAsKIF(GameRecord record) {
    return KifuFormatter.toKIF(record);
  }

  /// ゲーム記録をKI2形式で文字列化
  String formatAsKI2(GameRecord record) {
    return KifuFormatter.toKI2(record);
  }

  /// ゲーム記録をJSON形式で文字列化
  String formatAsJSON(GameRecord record, {bool pretty = false}) {
    return KifuFormatter.toJSON(record, pretty: pretty);
  }

  /// ファイルに保存する形式で出力
  Future<String> exportToFile(
    GameRecord record, {
    String format = 'kif',
  }) async {
    return switch (format.toLowerCase()) {
      'kif' => formatAsKIF(record),
      'ki2' => formatAsKI2(record),
      'json' => formatAsJSON(record, pretty: true),
      _ => formatAsKIF(record),
    };
  }

  /// 複数ゲーム記録をまとめてエクスポート
  Future<String> exportMultiple(
    List<GameRecord> records, {
    String format = 'json',
  }) async {
    return KifuFormatter.exportMultiple(records, format: format);
  }

  /// ファイル拡張子を取得
  static String getFileExtension(String format) {
    return switch (format.toLowerCase()) {
      'kif' => '.kif',
      'ki2' => '.ki2',
      'json' => '.json',
      _ => '.txt',
    };
  }

  /// ファイル名を生成（タイムスタンプ付き）
  static String generateFileName(
    String playerName,
    DateTime dateTime, {
    String format = 'kif',
  }) {
    final date = '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}';
    final ext = getFileExtension(format);

    return '$playerName\_$date\_$time$ext';
  }
}
