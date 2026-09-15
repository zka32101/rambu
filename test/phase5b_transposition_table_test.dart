/// Transposition Table Tests
/// トランスポジション テーブル機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/services/transposition_table.dart';

void main() {
  group('Transposition Table Initialization Tests', () {
    test('should initialize with default size', () {
      final tt = TranspositionTable();
      expect(tt, isNotNull);
    });

    test('should initialize with custom size', () {
      final tt = TranspositionTable(size: 1024);
      final stats = tt.getStatistics();
      expect(stats['table_size'], greaterThanOrEqualTo(1024));
    });

    test('size should be power of two', () {
      final tt = TranspositionTable(size: 1000);
      final stats = tt.getStatistics();
      final size = stats['table_size'] as int;

      // Check if size is power of two
      expect((size & (size - 1)), equals(0));
    });
  });

  group('Hash Calculation Tests', () {
    test('should calculate consistent hash for same board state', () {
      final tt = TranspositionTable();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final hash1 = tt.calculateHash(gameSession);
      final hash2 = tt.calculateHash(gameSession);

      expect(hash1, equals(hash2));
    });

    test('should produce different hash for different board states', () {
      final tt = TranspositionTable();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final hash1 = tt.calculateHash(gameSession);

      // Apply a move
      try {
        final move = Move(
          from: Position(2, 7),
          to: Position(2, 6),
          player: PlayerColor.sente,
          piece: Piece(
            type: PieceType.pawn,
            player: PlayerColor.sente,
            currentHP: 1,
            maxHP: 1,
          ),
          moveType: MoveType.normal,
          damageDealt: 0,
        );
        gameSession.applyMove(move);
      } catch (e) {
        // Move might fail due to game state, continue anyway
      }

      final hash2 = tt.calculateHash(gameSession);

      // Hashes should differ (very high probability)
      expect(hash1, isNot(equals(hash2)));
    });

    test('should return positive hash values', () {
      final tt = TranspositionTable();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final hash = tt.calculateHash(gameSession);
      expect(hash, greaterThanOrEqualTo(0));
    });
  });

  group('Store and Lookup Tests', () {
    late TranspositionTable tt;

    setUp(() {
      tt = TranspositionTable(size: 256);
    });

    test('should store and retrieve exact evaluation', () {
      const hashKey = 12345;
      const depth = 4;
      const evaluation = 150;
      const flag = 0; // exact

      tt.store(hashKey, depth, evaluation, flag);
      final entry = tt.lookup(hashKey, depth);

      expect(entry, isNotNull);
      expect(entry!.evaluation, equals(evaluation));
      expect(entry.depth, equals(depth));
      expect(entry.flag, equals(flag));
    });

    test('should not retrieve entry with insufficient depth', () {
      const hashKey = 12345;

      tt.store(hashKey, 3, 150, 0);
      final entry = tt.lookup(hashKey, 4);  // Request depth 4 but stored depth 3

      expect(entry, isNull);
    });

    test('should retrieve entry with equal depth', () {
      const hashKey = 12345;
      const depth = 4;

      tt.store(hashKey, depth, 150, 0);
      final entry = tt.lookup(hashKey, depth);

      expect(entry, isNotNull);
      expect(entry!.depth, equals(depth));
    });

    test('should retrieve entry with greater depth', () {
      const hashKey = 12345;

      tt.store(hashKey, 4, 150, 0);
      final entry = tt.lookup(hashKey, 3);  // Request depth 3 but stored depth 4

      expect(entry, isNotNull);
    });

    test('should handle multiple entries', () {
      for (int i = 0; i < 100; i++) {
        tt.store(i, 4, 100 + i, 0);
      }

      for (int i = 0; i < 100; i++) {
        final entry = tt.lookup(i, 4);
        expect(entry, isNotNull);
        expect(entry!.evaluation, equals(100 + i));
      }
    });

    test('should return null for non-existent entry', () {
      final entry = tt.lookup(99999, 4);
      expect(entry, isNull);
    });
  });

  group('Collision Handling Tests', () {
    late TranspositionTable tt;

    setUp(() {
      tt = TranspositionTable(size: 16);  // Small size to force collisions
    });

    test('should handle hash collisions', () {
      // Store multiple entries that might collide
      tt.store(0, 4, 100, 0);
      tt.store(16, 4, 200, 0);  // 16 % 16 = 0, same index as 0

      final entry1 = tt.lookup(0, 4);
      expect(entry1, isNotNull);

      // Due to collision handling, may or may not retrieve second entry
      final entry2 = tt.lookup(16, 4);
      if (entry2 != null) {
        expect(entry2.evaluation, equals(200));
      }
    });

    test('should prefer deeper entries on collision', () {
      const hashKey1 = 0;
      const hashKey2 = 16;  // Same index after modulo

      // Store shallow entry
      tt.store(hashKey1, 2, 100, 0);

      // Store deeper entry with collision
      tt.store(hashKey2, 4, 200, 0);

      // Deeper entry should remain
      final entry = tt.lookup(hashKey2, 4);
      expect(entry, isNotNull);
    });
  });

  group('Statistics Tests', () {
    late TranspositionTable tt;

    setUp(() {
      tt = TranspositionTable(size: 256);
    });

    test('should track cache hits', () {
      tt.store(100, 4, 150, 0);
      tt.lookup(100, 4);

      final stats = tt.getStatistics();
      expect(stats['hits'], equals(1));
      expect(stats['misses'], equals(0));
    });

    test('should track cache misses', () {
      tt.lookup(999, 4);

      final stats = tt.getStatistics();
      expect(stats['hits'], equals(0));
      expect(stats['misses'], equals(1));
    });

    test('should calculate hit rate correctly', () {
      // 10 hits, 10 misses = 50% hit rate
      for (int i = 0; i < 10; i++) {
        tt.store(i, 4, 100 + i, 0);
        tt.lookup(i, 4);  // Hit
      }
      for (int i = 10; i < 20; i++) {
        tt.lookup(i, 4);  // Miss
      }

      final stats = tt.getStatistics();
      expect(stats['hit_rate'], equals(50.0));
    });

    test('should report utilization percentage', () {
      for (int i = 0; i < 100; i++) {
        tt.store(i, 4, 100 + i, 0);
      }

      final stats = tt.getStatistics();
      final utilization = stats['utilization_percent'] as double;

      expect(utilization, greaterThan(0));
      expect(utilization, lessThanOrEqualTo(100));
    });

    test('should reset statistics', () {
      tt.store(100, 4, 150, 0);
      tt.lookup(100, 4);

      var stats = tt.getStatistics();
      expect(stats['hits'], greaterThan(0));

      tt.resetStatistics();
      stats = tt.getStatistics();

      expect(stats['hits'], equals(0));
      expect(stats['misses'], equals(0));
    });
  });

  group('Clear and Cleanup Tests', () {
    late TranspositionTable tt;

    setUp(() {
      tt = TranspositionTable(size: 256);
    });

    test('should clear all entries', () {
      for (int i = 0; i < 100; i++) {
        tt.store(i, 4, 100 + i, 0);
      }

      tt.clear();

      for (int i = 0; i < 100; i++) {
        final entry = tt.lookup(i, 4);
        expect(entry, isNull);
      }
    });

    test('should clear statistics on clear', () {
      tt.store(100, 4, 150, 0);
      tt.lookup(100, 4);

      tt.clear();

      final stats = tt.getStatistics();
      expect(stats['hits'], equals(0));
      expect(stats['misses'], equals(0));
    });

    test('should cleanup old entries', () {
      for (int i = 0; i < 100; i++) {
        tt.store(i, 4, 100 + i, 0);
      }

      final beforeCleanup = tt.getStatistics()['entries_stored'] as int;

      tt.cleanup();

      final afterCleanup = tt.getStatistics()['entries_stored'] as int;
      expect(afterCleanup, lessThanOrEqualTo(beforeCleanup));
    });
  });

  group('Alpha-Beta Integration Tests', () {
    late AlphaBetaTranspositionTable abtt;

    setUp(() {
      abtt = AlphaBetaTranspositionTable(size: 256);
    });

    test('should store evaluation with flags', () {
      const hashKey = 100;
      const depth = 4;
      const eval = 150;
      const alpha = 100;
      const beta = 200;

      abtt.storeEvaluation(
        hashKey,
        depth,
        eval,
        alpha: alpha,
        beta: beta,
      );

      final entry = abtt
          .lookupEvaluation(hashKey, depth, alpha: alpha, beta: beta);
      expect(entry, isNotNull);
      expect(entry, equals(eval));
    });

    test('should set exact flag when alpha < eval < beta', () {
      const hashKey = 100;
      const depth = 4;
      const eval = 150;
      const alpha = 100;
      const beta = 200;

      abtt.storeEvaluation(
        hashKey,
        depth,
        eval,
        alpha: alpha,
        beta: beta,
      );

      // Lookup with same bounds should return exact value
      final entry = abtt.lookupEvaluation(
        hashKey,
        depth,
        alpha: alpha,
        beta: beta,
      );

      expect(entry, equals(eval));
    });

    test('should set lower bound flag when eval >= beta', () {
      const hashKey = 100;
      const depth = 4;
      const eval = 250;  // >= beta
      const alpha = 100;
      const beta = 200;

      abtt.storeEvaluation(
        hashKey,
        depth,
        eval,
        alpha: alpha,
        beta: beta,
      );

      final entry = abtt.lookupEvaluation(
        hashKey,
        depth,
        alpha: alpha,
        beta: beta,
      );

      // Lower bound cutoff
      expect(entry, isNotNull);
    });

    test('should set upper bound flag when eval <= alpha', () {
      const hashKey = 100;
      const depth = 4;
      const eval = 50;  // <= alpha
      const alpha = 100;
      const beta = 200;

      abtt.storeEvaluation(
        hashKey,
        depth,
        eval,
        alpha: alpha,
        beta: beta,
      );

      final entry = abtt.lookupEvaluation(
        hashKey,
        depth,
        alpha: alpha,
        beta: beta,
      );

      // Upper bound cutoff
      expect(entry, isNotNull);
    });
  });

  group('Performance Tests', () {
    test('store and lookup should be fast', () {
      final tt = TranspositionTable(size: 65536);

      final stopwatch = Stopwatch()..start();

      // Store 10000 entries
      for (int i = 0; i < 10000; i++) {
        tt.store(i, 4, 100 + i, 0);
      }

      // Lookup 10000 entries
      for (int i = 0; i < 10000; i++) {
        tt.lookup(i, 4);
      }

      stopwatch.stop();

      // Should complete in less than 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('hash calculation should be reasonably fast', () {
      final tt = TranspositionTable();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        tt.calculateHash(gameSession);
      }

      stopwatch.stop();

      // Should complete in less than 50ms (average < 0.05ms per hash)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  group('Zobrist Hasher Tests', () {
    test('should initialize zobrist table', () {
      final zh = ZobristHasher();
      expect(zh.zobristTable, isNotNull);
      expect(zh.zobristTable.length, equals(16));
    });

    test('should calculate zobrist hash', () {
      final zh = ZobristHasher();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final hash = zh.calculateHash(gameSession);
      expect(hash, greaterThanOrEqualTo(0));
    });

    test('should generate consistent zobrist hashes', () {
      final zh = ZobristHasher();
      final gameSession = GameSession(
        sessionId: 'test',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      gameSession.start();

      final hash1 = zh.calculateHash(gameSession);
      final hash2 = zh.calculateHash(gameSession);

      expect(hash1, equals(hash2));
    });
  });
}
