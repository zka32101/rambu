/// Phase 9A Spectator & Replay Sharing Tests
/// ライブ観戦・リプレイ共有・リプレイコメントのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/spectator.dart';

void main() {
  group('LiveGameBroadcast Model Tests', () {
    test('should create broadcast with default values', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      expect(broadcast.guestUserName, equals('CPU'));
      expect(broadcast.allowSpectators, isTrue);
      expect(broadcast.currentMoveNumber, equals(0));
      expect(broadcast.viewerCount, equals(0));
      expect(broadcast.isFinished, isFalse);
    });

    test('should convert to JSON and back', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        guestUserId: 'user_002',
        guestUserName: 'Player B',
        currentMoveNumber: 12,
        hostTotalHP: 8,
        guestTotalHP: 5,
        viewerCount: 3,
        startedAt: '2026-09-21T10:00:00Z',
        lastUpdatedAt: '2026-09-21T10:05:00Z',
      );

      final json = broadcast.toJson();
      final restored = LiveGameBroadcast.fromJson(json);

      expect(restored.gameSessionId, equals('session_001'));
      expect(restored.currentMoveNumber, equals(12));
      expect(restored.hostTotalHP, equals(8));
      expect(restored.viewerCount, equals(3));
    });

    test('should copyWith updated progress', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      final updated = broadcast.copyWith(
        currentMoveNumber: 5,
        hostTotalHP: 7,
        guestTotalHP: 6,
        viewerCount: 2,
      );

      expect(updated.currentMoveNumber, equals(5));
      expect(updated.hostTotalHP, equals(7));
      expect(updated.viewerCount, equals(2));
      expect(updated.gameSessionId, equals(broadcast.gameSessionId));
    });

    test('should copyWith finished status', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      final finished = broadcast.copyWith(isFinished: true);
      expect(finished.isFinished, isTrue);
    });

    test('should default guestUserName to CPU for bot games', () {
      final broadcast = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        guestUserId: null,
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      expect(broadcast.guestUserId, isNull);
      expect(broadcast.guestUserName, equals('CPU'));
    });
  });

  group('ReplayShare Model Tests', () {
    test('should create replay share with defaults', () {
      final share = ReplayShare(
        id: 'share_001',
        gameRecordId: 'record_001',
        shareToken: 'ABCD1234',
        ownerUserId: 'user_001',
        ownerUserName: 'Player A',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(share.isPublic, isTrue);
      expect(share.viewCount, equals(0));
    });

    test('should convert to JSON and back', () {
      final share = ReplayShare(
        id: 'share_001',
        gameRecordId: 'record_001',
        shareToken: 'ABCD1234',
        ownerUserId: 'user_001',
        ownerUserName: 'Player A',
        isPublic: false,
        viewCount: 15,
        createdAt: '2026-09-21T10:00:00Z',
      );

      final json = share.toJson();
      final restored = ReplayShare.fromJson(json);

      expect(restored.shareToken, equals('ABCD1234'));
      expect(restored.isPublic, isFalse);
      expect(restored.viewCount, equals(15));
    });

    test('should copyWith updated view count', () {
      final share = ReplayShare(
        id: 'share_001',
        gameRecordId: 'record_001',
        shareToken: 'ABCD1234',
        ownerUserId: 'user_001',
        ownerUserName: 'Player A',
        viewCount: 5,
        createdAt: DateTime.now().toIso8601String(),
      );

      final updated = share.copyWith(viewCount: 6);
      expect(updated.viewCount, equals(6));
      expect(updated.shareToken, equals(share.shareToken));
    });
  });

  group('ReplayComment Model Tests', () {
    test('should create comment without move index (general comment)', () {
      final comment = ReplayComment(
        id: 'comment_001',
        gameRecordId: 'record_001',
        userId: 'user_001',
        userName: 'Player A',
        text: '素晴らしい対局でした！',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(comment.moveIndex, isNull);
      expect(comment.text, equals('素晴らしい対局でした！'));
    });

    test('should create comment pinned to a move index', () {
      final comment = ReplayComment(
        id: 'comment_001',
        gameRecordId: 'record_001',
        userId: 'user_001',
        userName: 'Player A',
        moveIndex: 15,
        text: 'この一手が決め手でしたね',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(comment.moveIndex, equals(15));
    });

    test('should convert to JSON and back', () {
      final comment = ReplayComment(
        id: 'comment_001',
        gameRecordId: 'record_001',
        userId: 'user_001',
        userName: 'Player A',
        moveIndex: 8,
        text: 'クリティカルヒット！',
        createdAt: '2026-09-21T10:00:00Z',
      );

      final json = comment.toJson();
      final restored = ReplayComment.fromJson(json);

      expect(restored.moveIndex, equals(8));
      expect(restored.text, equals('クリティカルヒット！'));
    });
  });

  group('Spectator System Integration Tests', () {
    test('should model full broadcast lifecycle', () {
      final started = LiveGameBroadcast(
        gameSessionId: 'session_001',
        hostUserId: 'user_001',
        hostUserName: 'Player A',
        guestUserId: 'user_002',
        guestUserName: 'Player B',
        startedAt: DateTime.now().toIso8601String(),
        lastUpdatedAt: DateTime.now().toIso8601String(),
      );

      expect(started.isFinished, isFalse);

      final progressed = started.copyWith(
        currentMoveNumber: 20,
        hostTotalHP: 4,
        guestTotalHP: 6,
      );

      expect(progressed.currentMoveNumber, equals(20));

      final finished = progressed.copyWith(isFinished: true);
      expect(finished.isFinished, isTrue);
      // 対局の状態は維持
      expect(finished.currentMoveNumber, equals(20));
    });

    test('should model replay share to comment flow', () {
      final share = ReplayShare(
        id: 'share_001',
        gameRecordId: 'record_001',
        shareToken: 'XYZ98765',
        ownerUserId: 'user_001',
        ownerUserName: 'Player A',
        createdAt: DateTime.now().toIso8601String(),
      );

      final viewed = share.copyWith(viewCount: 1);
      expect(viewed.viewCount, equals(1));

      final comment = ReplayComment(
        id: 'comment_001',
        gameRecordId: share.gameRecordId,
        userId: 'user_002',
        userName: 'Viewer',
        moveIndex: 3,
        text: 'いい手ですね',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(comment.gameRecordId, equals(share.gameRecordId));
    });

    test('should sort comments by move index then by post time', () {
      final comments = [
        ReplayComment(
          id: 'c1',
          gameRecordId: 'record_001',
          userId: 'u1',
          userName: 'A',
          moveIndex: 5,
          text: 'Comment at move 5',
          createdAt: '2026-09-21T10:00:00Z',
        ),
        ReplayComment(
          id: 'c2',
          gameRecordId: 'record_001',
          userId: 'u2',
          userName: 'B',
          text: 'General comment',
          createdAt: '2026-09-21T09:00:00Z',
        ),
        ReplayComment(
          id: 'c3',
          gameRecordId: 'record_001',
          userId: 'u3',
          userName: 'C',
          moveIndex: 2,
          text: 'Comment at move 2',
          createdAt: '2026-09-21T10:01:00Z',
        ),
      ];

      final sorted = [...comments]
        ..sort((a, b) {
          final aIndex = a.moveIndex ?? -1;
          final bIndex = b.moveIndex ?? -1;
          if (aIndex != bIndex) return aIndex.compareTo(bIndex);
          return a.createdAt.compareTo(b.createdAt);
        });

      expect(sorted[0].id, equals('c2')); // moveIndex null -> -1, sorts first
      expect(sorted[1].id, equals('c3')); // moveIndex 2
      expect(sorted[2].id, equals('c1')); // moveIndex 5
    });
  });

  group('Performance Tests', () {
    test('should create many broadcasts quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        LiveGameBroadcast(
          gameSessionId: 'session_$i',
          hostUserId: 'user_$i',
          hostUserName: 'Player $i',
          currentMoveNumber: i,
          startedAt: DateTime.now().toIso8601String(),
          lastUpdatedAt: DateTime.now().toIso8601String(),
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should create and sort many comments quickly', () {
      final stopwatch = Stopwatch()..start();

      final comments = List.generate(
        200,
        (i) => ReplayComment(
          id: 'comment_$i',
          gameRecordId: 'record_001',
          userId: 'user_$i',
          userName: 'Player $i',
          moveIndex: i % 30,
          text: 'Comment $i',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      comments.sort((a, b) => (a.moveIndex ?? -1).compareTo(b.moveIndex ?? -1));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(comments.length, equals(200));
    });
  });
}
