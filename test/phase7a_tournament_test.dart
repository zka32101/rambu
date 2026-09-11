/// Phase 7A Tournament System Tests
/// トーナメントシステムのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/tournament.dart';

void main() {
  group('Tournament Model Tests', () {
    test('should create tournament', () {
      final tournament = Tournament(
        id: 'tour_001',
        name: 'Spring Championship 2026',
        description: 'Official spring tournament',
        format: TournamentFormat.singleElimination,
        status: TournamentStatus.registration,
        maxParticipants: 32,
        currentParticipants: 12,
        entryFee: 1000,
        prizePool: 100000,
        startDate: '2026-09-15T10:00:00Z',
        endDate: '2026-09-15T18:00:00Z',
        bestOf: 3,
        organizerId: 'org_001',
      );

      expect(tournament.id, equals('tour_001'));
      expect(tournament.name, equals('Spring Championship 2026'));
      expect(tournament.format, equals(TournamentFormat.singleElimination));
      expect(tournament.status, equals(TournamentStatus.registration));
      expect(tournament.maxParticipants, equals(32));
      expect(tournament.prizePool, equals(100000));
    });

    test('should convert to JSON', () {
      final tournament = Tournament(
        id: 'tour_001',
        name: 'Championship',
        description: 'Test tournament',
        format: TournamentFormat.roundRobin,
        startDate: '2026-09-15T10:00:00Z',
        endDate: '2026-09-15T18:00:00Z',
        organizerId: 'org_001',
        maxParticipants: 16,
      );

      final json = tournament.toJson();

      expect(json['id'], equals('tour_001'));
      expect(json['name'], equals('Championship'));
      expect(json['format'], equals(TournamentFormat.roundRobin.index));
      expect(json['maxParticipants'], equals(16));
    });

    test('should create from JSON', () {
      final json = {
        'id': 'tour_001',
        'name': 'Tournament',
        'description': 'Test',
        'format': 0,
        'status': 1,
        'maxParticipants': 32,
        'currentParticipants': 10,
        'entryFee': 500,
        'prizePool': 50000,
        'startDate': '2026-09-15T10:00:00Z',
        'endDate': '2026-09-15T18:00:00Z',
        'organizerId': 'org_001',
      };

      final tournament = Tournament.fromJson(json);

      expect(tournament.id, equals('tour_001'));
      expect(tournament.format, equals(TournamentFormat.singleElimination));
      expect(tournament.status, equals(TournamentStatus.registration));
    });

    test('should have all tournament formats', () {
      expect(TournamentFormat.values.length, equals(4));
      expect(TournamentFormat.values, contains(TournamentFormat.singleElimination));
      expect(TournamentFormat.values, contains(TournamentFormat.swiss));
    });

    test('should have all tournament statuses', () {
      expect(TournamentStatus.values.length, equals(5));
      expect(TournamentStatus.values, contains(TournamentStatus.registration));
      expect(TournamentStatus.values, contains(TournamentStatus.completed));
    });
  });

  group('Tournament Participant Tests', () {
    test('should create tournament participant', () {
      final participant = TournamentParticipant(
        userId: 'user_001',
        userName: 'Player A',
        rating: 1800,
        seed: 1,
        registeredAt: '2026-09-01T10:00:00Z',
      );

      expect(participant.userId, equals('user_001'));
      expect(participant.userName, equals('Player A'));
      expect(participant.rating, equals(1800));
      expect(participant.seed, equals(1));
      expect(participant.feePaid, isFalse);
    });

    test('should convert participant to JSON', () {
      final participant = TournamentParticipant(
        userId: 'user_001',
        userName: 'Player A',
        rating: 2000,
        seed: 2,
        registeredAt: '2026-09-01T10:00:00Z',
        feePaid: true,
        checkedIn: true,
      );

      final json = participant.toJson();

      expect(json['userId'], equals('user_001'));
      expect(json['rating'], equals(2000));
      expect(json['feePaid'], isTrue);
      expect(json['checkedIn'], isTrue);
    });

    test('should track check-in status', () {
      final participant = TournamentParticipant(
        userId: 'user_001',
        userName: 'Player',
        rating: 1600,
        seed: 5,
        registeredAt: DateTime.now().toIso8601String(),
        checkedIn: true,
      );

      expect(participant.checkedIn, isTrue);
    });

    test('should track prize won', () {
      final participant = TournamentParticipant(
        userId: 'user_001',
        userName: 'Winner',
        rating: 2100,
        seed: 1,
        registeredAt: DateTime.now().toIso8601String(),
        finalPlacement: '1st',
        prizeWon: 50000,
      );

      expect(participant.finalPlacement, equals('1st'));
      expect(participant.prizeWon, equals(50000));
    });

    test('should copyWith correctly', () {
      final original = TournamentParticipant(
        userId: 'user_001',
        userName: 'Player',
        rating: 1800,
        seed: 3,
        registeredAt: DateTime.now().toIso8601String(),
      );

      final updated = original.copyWith(
        feePaid: true,
        checkedIn: true,
        finalPlacement: '3rd',
        prizeWon: 10000,
      );

      expect(updated.feePaid, isTrue);
      expect(updated.checkedIn, isTrue);
      expect(updated.finalPlacement, equals('3rd'));
      expect(updated.prizeWon, equals(10000));
      expect(updated.userId, equals(original.userId));
    });
  });

  group('Tournament Match Tests', () {
    test('should create tournament match', () {
      final match = TournamentMatch(
        id: 'match_001',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Seed: 32,
      );

      expect(match.id, equals('match_001'));
      expect(match.round, equals(1));
      expect(match.player1Id, equals('user_001'));
      expect(match.player2Id, equals('user_002'));
      expect(match.status, equals(MatchStatus.scheduled));
    });

    test('should track match status', () {
      final match = TournamentMatch(
        id: 'match_001',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Seed: 2,
        status: MatchStatus.completed,
        winnerId: 'user_001',
        player1Score: 2,
        player2Score: 0,
      );

      expect(match.status, equals(MatchStatus.completed));
      expect(match.winnerId, equals('user_001'));
      expect(match.player1Score, equals(2));
      expect(match.player2Score, equals(0));
    });

    test('should handle bye (missing player2)', () {
      final match = TournamentMatch(
        id: 'match_001',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: null,
        player2Name: null,
      );

      expect(match.player2Id, isNull);
      expect(match.player2Name, isNull);
    });

    test('should convert match to JSON', () {
      final match = TournamentMatch(
        id: 'match_001',
        tournamentId: 'tour_001',
        round: 2,
        matchNumber: 3,
        player1Id: 'user_001',
        player1Name: 'Winner A',
        player1Seed: 1,
        player2Id: 'user_003',
        player2Name: 'Player C',
        player2Seed: 4,
        status: MatchStatus.inProgress,
      );

      final json = match.toJson();

      expect(json['id'], equals('match_001'));
      expect(json['round'], equals(2));
      expect(json['status'], equals(MatchStatus.inProgress.index));
    });

    test('should copyWith correctly', () {
      final original = TournamentMatch(
        id: 'match_001',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Seed: 2,
      );

      final updated = original.copyWith(
        status: MatchStatus.completed,
        winnerId: 'user_001',
        player1Score: 2,
        player2Score: 1,
      );

      expect(updated.status, equals(MatchStatus.completed));
      expect(updated.winnerId, equals('user_001'));
      expect(updated.player1Score, equals(2));
      expect(updated.player2Score, equals(1));
      expect(updated.round, equals(original.round));
    });
  });

  group('Prize Structure Tests', () {
    test('should create prize structure', () {
      final prize = PrizeStructure(
        placement: 1,
        prizeAmount: 50000,
        percentage: 50.0,
      );

      expect(prize.placement, equals(1));
      expect(prize.prizeAmount, equals(50000));
      expect(prize.percentage, equals(50.0));
    });

    test('should convert to JSON', () {
      final prize = PrizeStructure(
        placement: 2,
        prizeAmount: 25000,
        percentage: 25.0,
      );

      final json = prize.toJson();

      expect(json['placement'], equals(2));
      expect(json['prizeAmount'], equals(25000));
      expect(json['percentage'], equals(25.0));
    });

    test('should create from JSON', () {
      final json = {
        'placement': 3,
        'prizeAmount': 15000,
        'percentage': 15.0,
      };

      final prize = PrizeStructure.fromJson(json);

      expect(prize.placement, equals(3));
      expect(prize.prizeAmount, equals(15000));
    });
  });

  group('Tournament Stats Tests', () {
    test('should create tournament stats', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        completedMatches: 5,
        scheduledMatches: 11,
      );

      expect(stats.tournamentId, equals('tour_001'));
      expect(stats.totalParticipants, equals(32));
      expect(stats.completedMatches, equals(5));
      expect(stats.scheduledMatches, equals(11));
    });

    test('should track upsets', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 16,
        highestSeedWon: 8,
        lowestSeedWon: 16,
      );

      expect(stats.highestSeedWon, equals(8));
      expect(stats.lowestSeedWon, equals(16));
    });

    test('should track undefeated players', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 16,
        undefeatedCount: 1,
      );

      expect(stats.undefeatedCount, equals(1));
    });
  });

  group('Match Status Tests', () {
    test('should have all match statuses', () {
      expect(MatchStatus.values.length, equals(4));
      expect(MatchStatus.values, contains(MatchStatus.scheduled));
      expect(MatchStatus.values, contains(MatchStatus.completed));
      expect(MatchStatus.values, contains(MatchStatus.cancelled));
    });
  });

  group('Tournament Integration Tests', () {
    test('should create complete tournament structure', () {
      final tournament = Tournament(
        id: 'tour_001',
        name: 'Grand Championship',
        description: 'Main tournament event',
        format: TournamentFormat.singleElimination,
        status: TournamentStatus.active,
        maxParticipants: 32,
        currentParticipants: 32,
        prizePool: 200000,
        startDate: '2026-09-15T10:00:00Z',
        endDate: '2026-09-15T18:00:00Z',
        organizerId: 'org_001',
      );

      final participants = List.generate(
        8,
        (i) => TournamentParticipant(
          userId: 'user_${i + 1}',
          userName: 'Player ${String.fromCharCode(65 + i)}',
          rating: 2000 - (i * 100),
          seed: i + 1,
          registeredAt: DateTime.now().toIso8601String(),
          checkedIn: true,
        ),
      );

      final matches = List.generate(
        4,
        (i) => TournamentMatch(
          id: 'match_${i + 1}',
          tournamentId: tournament.id,
          round: 1,
          matchNumber: i + 1,
          player1Id: participants[i * 2].userId,
          player1Name: participants[i * 2].userName,
          player1Seed: participants[i * 2].seed,
          player2Id: participants[i * 2 + 1].userId,
          player2Name: participants[i * 2 + 1].userName,
          player2Seed: participants[i * 2 + 1].seed,
        ),
      );

      expect(tournament.maxParticipants, equals(32));
      expect(participants.length, equals(8));
      expect(matches.length, equals(4));
      expect(matches[0].player1Seed, lessThan(matches[0].player2Seed!));
    });

    test('should track tournament progression', () {
      final match1 = TournamentMatch(
        id: 'match_r1_1',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Seed: 32,
        status: MatchStatus.completed,
        winnerId: 'user_001',
        player1Score: 2,
        player2Score: 0,
      );

      final match2 = TournamentMatch(
        id: 'match_r2_1',
        tournamentId: 'tour_001',
        round: 2,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
      );

      expect(match1.winnerId, equals('user_001'));
      expect(match2.player1Id, equals(match1.winnerId));
      expect(match2.round, equals(match1.round + 1));
    });
  });

  group('Performance Tests', () {
    test('should create tournaments quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        Tournament(
          id: 'tour_$i',
          name: 'Tournament $i',
          description: 'Description $i',
          format: i % 2 == 0 ? TournamentFormat.singleElimination : TournamentFormat.roundRobin,
          maxParticipants: 32,
          startDate: DateTime.now().toIso8601String(),
          endDate: DateTime.now().add(Duration(hours: 8)).toIso8601String(),
          organizerId: 'org_001',
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should create participants quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 128; i++) {
        TournamentParticipant(
          userId: 'user_$i',
          userName: 'Player $i',
          rating: 1000 + (i * 5),
          seed: i + 1,
          registeredAt: DateTime.now().toIso8601String(),
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('should create matches quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 64; i++) {
        TournamentMatch(
          id: 'match_$i',
          tournamentId: 'tour_001',
          round: (i ~/ 32) + 1,
          matchNumber: (i % 32) + 1,
          player1Id: 'user_${i * 2}',
          player1Name: 'Player ${i * 2}',
          player1Seed: i + 1,
          player2Id: 'user_${i * 2 + 1}',
          player2Name: 'Player ${i * 2 + 1}',
          player2Seed: i + 2,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
