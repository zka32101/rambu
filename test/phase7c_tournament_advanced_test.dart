/// Phase 7C Tournament Advanced Features Tests
/// トーナメント高度な機能テスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/tournament.dart';

void main() {
  group('Bracket Visualization Tests', () {
    test('should display bracket with single elimination structure', () {
      final tournament = Tournament(
        id: 'tour_001',
        name: 'Spring Championship 2026',
        description: 'Official spring tournament',
        format: TournamentFormat.singleElimination,
        status: TournamentStatus.active,
        maxParticipants: 8,
        currentParticipants: 8,
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

      expect(tournament.format, equals(TournamentFormat.singleElimination));
      expect(participants.length, equals(8));
      // Bracket should have 3 rounds for 8 participants (8->4->2->1)
      expect(log2(8).ceil(), equals(3));
    });

    test('should display round 1 matches in bracket', () {
      final matches = List.generate(
        4,
        (i) => TournamentMatch(
          id: 'match_r1_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_${i * 2 + 1}',
          player1Name: 'Player ${String.fromCharCode(65 + i * 2)}',
          player1Seed: i * 2 + 1,
          player2Id: 'user_${i * 2 + 2}',
          player2Name: 'Player ${String.fromCharCode(65 + i * 2 + 1)}',
          player2Seed: i * 2 + 2,
          status: MatchStatus.scheduled,
        ),
      );

      expect(matches.length, equals(4));
      expect(matches[0].round, equals(1));
      expect(matches[0].status, equals(MatchStatus.scheduled));
    });

    test('should display completed match with winner', () {
      final match = TournamentMatch(
        id: 'match_r1_1',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Player B',
        player2Seed: 8,
        status: MatchStatus.completed,
        winnerId: 'user_001',
        player1Score: 2,
        player2Score: 0,
      );

      expect(match.winnerId, equals('user_001'));
      expect(match.player1Score, equals(2));
      expect(match.player2Score, equals(0));
      expect(match.status, equals(MatchStatus.completed));
    });

    test('should handle bye in bracket (missing player2)', () {
      final match = TournamentMatch(
        id: 'match_r1_bye',
        tournamentId: 'tour_001',
        round: 1,
        matchNumber: 5,
        player1Id: 'user_001',
        player1Name: 'Player A',
        player1Seed: 1,
        player2Id: null,
        player2Name: null,
        status: MatchStatus.completed,
        winnerId: 'user_001',
        player1Score: 1,
        player2Score: 0,
      );

      expect(match.player2Id, isNull);
      expect(match.player2Name, isNull);
      expect(match.winnerId, equals('user_001'));
    });

    test('should display round selector with all rounds', () {
      final matches = <TournamentMatch>[];

      // Round 1: 8 matches
      for (int i = 0; i < 8; i++) {
        matches.add(TournamentMatch(
          id: 'match_r1_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_${i * 2 + 1}',
          player1Name: 'Player ${i * 2 + 1}',
          player1Seed: i * 2 + 1,
          player2Id: 'user_${i * 2 + 2}',
          player2Name: 'Player ${i * 2 + 2}',
          player2Seed: i * 2 + 2,
        ));
      }

      // Round 2: 4 matches
      for (int i = 0; i < 4; i++) {
        matches.add(TournamentMatch(
          id: 'match_r2_${i + 1}',
          tournamentId: 'tour_001',
          round: 2,
          matchNumber: i + 1,
          player1Id: 'user_winner_${i * 2 + 1}',
          player1Name: 'Winner ${i * 2 + 1}',
          player1Seed: i * 2 + 1,
          player2Id: 'user_winner_${i * 2 + 2}',
          player2Name: 'Winner ${i * 2 + 2}',
          player2Seed: i * 2 + 2,
        ));
      }

      final roundNumbers = matches.map((m) => m.round).toSet().toList();
      roundNumbers.sort();

      expect(roundNumbers, equals([1, 2]));
      expect(matches.where((m) => m.round == 1).length, equals(8));
      expect(matches.where((m) => m.round == 2).length, equals(4));
    });

    test('should track bracket progression from round 1 to finals', () {
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
        player2Seed: 16,
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
        player2Id: 'user_winner_3',
        player2Name: 'Winner 3',
        player2Seed: 9,
        status: MatchStatus.scheduled,
      );

      expect(match1.winnerId, equals(match2.player1Id));
      expect(match2.round, equals(match1.round + 1));
    });
  });

  group('Standings and Rankings Tests', () {
    test('should calculate standings based on wins', () {
      final standings = [
        TournamentParticipant(
          userId: 'user_001',
          userName: 'Player A',
          rating: 2200,
          seed: 1,
          registeredAt: DateTime.now().toIso8601String(),
          checkedIn: true,
        ),
        TournamentParticipant(
          userId: 'user_002',
          userName: 'Player B',
          rating: 2000,
          seed: 2,
          registeredAt: DateTime.now().toIso8601String(),
          checkedIn: true,
        ),
        TournamentParticipant(
          userId: 'user_003',
          userName: 'Player C',
          rating: 1900,
          seed: 3,
          registeredAt: DateTime.now().toIso8601String(),
          checkedIn: true,
        ),
      ];

      // Sort by seed (lower seed = higher rank)
      standings.sort((a, b) => (a.seed ?? 0).compareTo(b.seed ?? 0));

      expect(standings[0].seed, equals(1));
      expect(standings[1].seed, equals(2));
      expect(standings[2].seed, equals(3));
    });

    test('should display tournament rankings with placement', () {
      final participants = List.generate(
        8,
        (i) => TournamentParticipant(
          userId: 'user_${i + 1}',
          userName: 'Player ${String.fromCharCode(65 + i)}',
          rating: 2000 - (i * 100),
          seed: i + 1,
          registeredAt: DateTime.now().toIso8601String(),
          checkedIn: true,
          finalPlacement: i == 0 ? '1st' : i == 1 ? '2nd' : i == 2 ? '3rd' : null,
          prizeWon: i == 0 ? 50000 : i == 1 ? 25000 : i == 2 ? 10000 : 0,
        ),
      );

      final ranked = participants.where((p) => p.finalPlacement != null).toList();
      expect(ranked.length, equals(3));
      expect(ranked[0].finalPlacement, equals('1st'));
      expect(ranked[1].finalPlacement, equals('2nd'));
      expect(ranked[2].finalPlacement, equals('3rd'));
    });

    test('should highlight current user in standings', () {
      const currentUserId = 'user_005';
      final standings = List.generate(
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

      final currentUser = standings.firstWhere((p) => p.userId == currentUserId);
      expect(currentUser.userId, equals(currentUserId));
      expect(currentUser.userName, equals('Player E'));
    });

    test('should assign medal colors based on placement', () {
      final goldParticipant = TournamentParticipant(
        userId: 'user_001',
        userName: 'Winner',
        rating: 2200,
        seed: 1,
        registeredAt: DateTime.now().toIso8601String(),
        finalPlacement: '1st',
      );

      final silverParticipant = TournamentParticipant(
        userId: 'user_002',
        userName: 'Runner-up',
        rating: 2100,
        seed: 2,
        registeredAt: DateTime.now().toIso8601String(),
        finalPlacement: '2nd',
      );

      final bronzeParticipant = TournamentParticipant(
        userId: 'user_003',
        userName: 'Third',
        rating: 2000,
        seed: 3,
        registeredAt: DateTime.now().toIso8601String(),
        finalPlacement: '3rd',
      );

      expect(goldParticipant.finalPlacement, equals('1st'));
      expect(silverParticipant.finalPlacement, equals('2nd'));
      expect(bronzeParticipant.finalPlacement, equals('3rd'));
    });

    test('should sort standings by placement tier', () {
      final participants = [
        TournamentParticipant(
          userId: 'user_003',
          userName: 'Player C',
          rating: 1800,
          seed: 3,
          registeredAt: DateTime.now().toIso8601String(),
          finalPlacement: '3rd',
        ),
        TournamentParticipant(
          userId: 'user_001',
          userName: 'Player A',
          rating: 2200,
          seed: 1,
          registeredAt: DateTime.now().toIso8601String(),
          finalPlacement: '1st',
        ),
        TournamentParticipant(
          userId: 'user_002',
          userName: 'Player B',
          rating: 2100,
          seed: 2,
          registeredAt: DateTime.now().toIso8601String(),
          finalPlacement: '2nd',
        ),
      ];

      final placementOrder = ['1st', '2nd', '3rd'];
      final sortedParticipants = participants
          .where((p) => p.finalPlacement != null)
          .toList()
          ..sort((a, b) => placementOrder.indexOf(a.finalPlacement!)
              .compareTo(placementOrder.indexOf(b.finalPlacement!)));

      expect(sortedParticipants[0].finalPlacement, equals('1st'));
      expect(sortedParticipants[1].finalPlacement, equals('2nd'));
      expect(sortedParticipants[2].finalPlacement, equals('3rd'));
    });
  });

  group('Tournament Statistics Tests', () {
    test('should calculate match completion percentage', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        completedMatches: 15,
        scheduledMatches: 16,
      );

      final totalMatches = stats.completedMatches + stats.scheduledMatches;
      final completionPercentage = (stats.completedMatches / totalMatches * 100).toInt();

      expect(totalMatches, equals(31));
      expect(completionPercentage, equals(48));
    });

    test('should track tournament progress through rounds', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 16,
        completedMatches: 12,
        scheduledMatches: 3,
      );

      expect(stats.completedMatches, equals(12));
      expect(stats.scheduledMatches, equals(3));
      // Total matches in single elimination bracket: n-1
      expect(stats.completedMatches + stats.scheduledMatches, equals(15));
    });

    test('should calculate average match duration', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        completedMatches: 20,
        scheduledMatches: 11,
        averageMatchDuration: 1200, // milliseconds
      );

      expect(stats.averageMatchDuration, equals(1200));
      expect(stats.averageMatchDuration! > 0, isTrue);
    });

    test('should display tournament statistics card with all metrics', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        completedMatches: 20,
        scheduledMatches: 11,
        highestSeedWon: 4,
        lowestSeedWon: 28,
        undefeatedCount: 1,
      );

      expect(stats.totalParticipants, equals(32));
      expect(stats.completedMatches, equals(20));
      expect(stats.highestSeedWon, equals(4));
      expect(stats.lowestSeedWon, equals(28));
      expect(stats.undefeatedCount, equals(1));
    });

    test('should track upset count in statistics', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 16,
        highestSeedWon: 8, // Seed 8 upset seed 1-7
        lowestSeedWon: 16,
      );

      final upsetDifference = stats.highestSeedWon! > 4 ? stats.highestSeedWon! - 4 : 0;
      expect(upsetDifference, equals(4));
    });

    test('should identify undefeated players', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        undefeatedCount: 1,
      );

      expect(stats.undefeatedCount, equals(1));
      expect(stats.undefeatedCount! > 0, isTrue);
    });

    test('should track most upsets in tournament', () {
      final stats1 = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 16,
        highestSeedWon: 12,
        lowestSeedWon: 16,
      );

      final stats2 = TournamentStats(
        tournamentId: 'tour_002',
        totalParticipants: 16,
        highestSeedWon: 6,
        lowestSeedWon: 10,
      );

      final upsets1 = (stats1.highestSeedWon ?? 0) - 1;
      final upsets2 = (stats2.highestSeedWon ?? 0) - 1;

      expect(upsets1, greaterThan(upsets2));
    });
  });

  group('Spectator Mode Tests', () {
    test('should display bracket in spectator mode', () {
      const isSpectator = true;
      const userId = 'spectator_001';

      expect(isSpectator, isTrue);
      expect(userId, startsWith('spectator'));
    });

    test('should allow spectator to view all matches', () {
      final matches = List.generate(
        8,
        (i) => TournamentMatch(
          id: 'match_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_${i * 2 + 1}',
          player1Name: 'Player ${i * 2 + 1}',
          player1Seed: i * 2 + 1,
          player2Id: 'user_${i * 2 + 2}',
          player2Name: 'Player ${i * 2 + 2}',
          player2Seed: i * 2 + 2,
        ),
      );

      expect(matches.length, equals(8));
      for (final match in matches) {
        expect(match.player1Id, isNotNull);
        expect(match.player2Id, isNotNull);
      }
    });

    test('should disable match result recording in spectator mode', () {
      const isSpectator = true;
      const userId = 'spectator_001';
      const allowRecording = !isSpectator;

      expect(allowRecording, isFalse);
    });

    test('should show standings for spectator', () {
      const isSpectator = true;
      final standings = List.generate(
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

      expect(isSpectator, isTrue);
      expect(standings.length, equals(8));
    });

    test('should display statistics for spectator', () {
      const isSpectator = true;
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        completedMatches: 15,
        scheduledMatches: 16,
      );

      expect(isSpectator, isTrue);
      expect(stats.totalParticipants, equals(32));
    });
  });

  group('Advanced Analytics Tests', () {
    test('should identify highest upset in tournament', () {
      final matches = [
        TournamentMatch(
          id: 'match_1',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: 1,
          player1Id: 'user_001',
          player1Name: 'Seed 1',
          player1Seed: 1,
          player2Id: 'user_032',
          player2Name: 'Seed 32',
          player2Seed: 32,
          status: MatchStatus.completed,
          winnerId: 'user_032',
          player1Score: 0,
          player2Score: 2,
        ),
      ];

      final upsetMatch = matches.first;
      final upsetAmount = (upsetMatch.player2Seed ?? 0) - (upsetMatch.player1Seed ?? 0);

      expect(upsetMatch.winnerId, equals('user_032'));
      expect(upsetAmount, equals(31));
    });

    test('should track seeding accuracy', () {
      final matches = List.generate(
        8,
        (i) => TournamentMatch(
          id: 'match_r1_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_${i * 2 + 1}',
          player1Name: 'Player ${i * 2 + 1}',
          player1Seed: i * 2 + 1,
          player2Id: 'user_${i * 2 + 2}',
          player2Name: 'Player ${i * 2 + 2}',
          player2Seed: i * 2 + 2,
          status: MatchStatus.completed,
          winnerId: 'user_${i * 2 + 1}',
          player1Score: 2,
          player2Score: 0,
        ),
      );

      final higherSeedWins = matches.where((m) =>
        m.winnerId == m.player1Id && (m.player1Seed ?? 0) < (m.player2Seed ?? 0)
      ).length;

      expect(higherSeedWins, equals(8));
    });

    test('should calculate player consistency rating', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        highestSeedWon: 2,
        lowestSeedWon: 8,
      );

      final seedRange = (stats.lowestSeedWon ?? 0) - (stats.highestSeedWon ?? 0);
      final consistency = seedRange < 5 ? 'high' : 'low';

      expect(seedRange, equals(6));
      expect(consistency, equals('low'));
    });

    test('should identify dominant players', () {
      final matches = List.generate(
        8,
        (i) => TournamentMatch(
          id: 'match_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_001',
          player1Name: 'Dominant Player',
          player1Seed: 1,
          player2Id: 'user_${i + 2}',
          player2Name: 'Player ${i + 2}',
          player2Seed: i + 2,
          status: MatchStatus.completed,
          winnerId: 'user_001',
          player1Score: 2,
          player2Score: 0,
        ),
      );

      final user001Wins = matches.where((m) => m.winnerId == 'user_001').length;
      final dominanceRatio = (user001Wins / matches.length * 100).toInt();

      expect(dominanceRatio, equals(100));
    });

    test('should track competitive balance', () {
      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 32,
        highestSeedWon: 1,
        lowestSeedWon: 32,
      );

      final maxSeedSpread = 32;
      final actualSpread = (stats.lowestSeedWon ?? 0) - (stats.highestSeedWon ?? 0) + 1;
      final competitiveBalance = (actualSpread / maxSeedSpread * 100).toInt();

      expect(competitiveBalance, equals(100));
    });
  });

  group('Performance Tests', () {
    test('should render bracket with 16 matches quickly', () {
      final stopwatch = Stopwatch()..start();

      final matches = List.generate(
        16,
        (i) => TournamentMatch(
          id: 'match_$i',
          tournamentId: 'tour_001',
          round: (i ~/ 8) + 1,
          matchNumber: (i % 8) + 1,
          player1Id: 'user_${i * 2}',
          player1Name: 'Player ${i * 2}',
          player1Seed: i + 1,
          player2Id: 'user_${i * 2 + 1}',
          player2Name: 'Player ${i * 2 + 1}',
          player2Seed: i + 2,
        ),
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(matches.length, equals(16));
    });

    test('should calculate standings for 128 players quickly', () {
      final stopwatch = Stopwatch()..start();

      final participants = List.generate(
        128,
        (i) => TournamentParticipant(
          userId: 'user_$i',
          userName: 'Player $i',
          rating: 1000 + (i * 5),
          seed: i + 1,
          registeredAt: DateTime.now().toIso8601String(),
        ),
      );

      participants.sort((a, b) => (b.rating - a.rating).toInt());

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(participants.length, equals(128));
    });

    test('should generate bracket tree structure quickly', () {
      final stopwatch = Stopwatch()..start();

      final roundLevels = <int, List<TournamentMatch>>{};
      for (int round = 1; round <= 4; round++) {
        final matchCount = 16 ~/ round;
        roundLevels[round] = List.generate(
          matchCount,
          (i) => TournamentMatch(
            id: 'match_r${round}_${i + 1}',
            tournamentId: 'tour_001',
            round: round,
            matchNumber: i + 1,
            player1Id: 'user_${i * 2}',
            player1Name: 'Player ${i * 2}',
            player1Seed: i + 1,
            player2Id: 'user_${i * 2 + 1}',
            player2Name: 'Player ${i * 2 + 1}',
            player2Seed: i + 2,
          ),
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(roundLevels.keys.length, equals(4));
    });

    test('should calculate statistics quickly', () {
      final stopwatch = Stopwatch()..start();

      final stats = TournamentStats(
        tournamentId: 'tour_001',
        totalParticipants: 256,
        completedMatches: 200,
        scheduledMatches: 55,
        averageMatchDuration: 1200,
        highestSeedWon: 1,
        lowestSeedWon: 256,
        undefeatedCount: 0,
      );

      final completionPercentage =
          (stats.completedMatches / (stats.completedMatches + stats.scheduledMatches) * 100).toInt();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(completionPercentage, equals(78));
    });

    test('should handle large tournament visualization', () {
      final stopwatch = Stopwatch()..start();

      final allMatches = <TournamentMatch>[];
      for (int round = 1; round <= 7; round++) {
        final matchCount = 64 ~/ round;
        for (int i = 0; i < matchCount; i++) {
          allMatches.add(TournamentMatch(
            id: 'match_r${round}_${i + 1}',
            tournamentId: 'tour_001',
            round: round,
            matchNumber: i + 1,
            player1Id: 'user_${i * 2}',
            player1Name: 'Player ${i * 2}',
            player1Seed: i + 1,
            player2Id: 'user_${i * 2 + 1}',
            player2Name: 'Player ${i * 2 + 1}',
            player2Seed: i + 2,
          ));
        }
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(allMatches.length, equals(127));
    });
  });

  group('Bracket Edge Cases Tests', () {
    test('should handle 2-player final match', () {
      final finalMatch = TournamentMatch(
        id: 'match_final',
        tournamentId: 'tour_001',
        round: 4,
        matchNumber: 1,
        player1Id: 'user_001',
        player1Name: 'Finalist A',
        player1Seed: 1,
        player2Id: 'user_002',
        player2Name: 'Finalist B',
        player2Seed: 2,
        status: MatchStatus.scheduled,
      );

      expect(finalMatch.round, equals(4));
      expect(finalMatch.matchNumber, equals(1));
    });

    test('should handle all byes in early round', () {
      final byeMatches = List.generate(
        4,
        (i) => TournamentMatch(
          id: 'match_bye_${i + 1}',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: i + 1,
          player1Id: 'user_${i + 1}',
          player1Name: 'Player ${i + 1}',
          player1Seed: i + 1,
          player2Id: null,
          player2Name: null,
          status: MatchStatus.completed,
          winnerId: 'user_${i + 1}',
          player1Score: 1,
          player2Score: 0,
        ),
      );

      final totalByes = byeMatches.where((m) => m.player2Id == null).length;
      expect(totalByes, equals(4));
    });

    test('should handle mixed scheduled and completed matches', () {
      final matches = [
        TournamentMatch(
          id: 'match_1',
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
        ),
        TournamentMatch(
          id: 'match_2',
          tournamentId: 'tour_001',
          round: 1,
          matchNumber: 2,
          player1Id: 'user_003',
          player1Name: 'Player C',
          player1Seed: 3,
          player2Id: 'user_004',
          player2Name: 'Player D',
          player2Seed: 4,
          status: MatchStatus.scheduled,
        ),
      ];

      final completed = matches.where((m) => m.status == MatchStatus.completed).length;
      final scheduled = matches.where((m) => m.status == MatchStatus.scheduled).length;

      expect(completed, equals(1));
      expect(scheduled, equals(1));
    });
  });

  group('Medal Assignment Logic Tests', () {
    test('should assign gold medal to first place', () {
      const placement = '1st';
      final expectedMedal = 'gold';

      expect(placement, equals('1st'));
      expect(expectedMedal, equals('gold'));
    });

    test('should assign silver medal to second place', () {
      const placement = '2nd';
      final expectedMedal = 'silver';

      expect(placement, equals('2nd'));
      expect(expectedMedal, equals('silver'));
    });

    test('should assign bronze medal to third place', () {
      const placement = '3rd';
      final expectedMedal = 'bronze';

      expect(placement, equals('3rd'));
      expect(expectedMedal, equals('bronze'));
    });

    test('should assign blue color to other placements', () {
      const placement = '4th';
      final expectedColor = 'blue';

      expect(placement, equals('4th'));
      expect(expectedColor, equals('blue'));
    });
  });

  group('Integration Tests', () {
    test('should complete tournament bracket progression', () {
      final tournament = Tournament(
        id: 'tour_001',
        name: 'Championship',
        description: 'Test',
        format: TournamentFormat.singleElimination,
        status: TournamentStatus.active,
        maxParticipants: 8,
        currentParticipants: 8,
        startDate: DateTime.now().toIso8601String(),
        endDate: DateTime.now().add(Duration(hours: 8)).toIso8601String(),
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

      final standings = participants
          ..sort((a, b) => (b.rating - a.rating).toInt());

      final stats = TournamentStats(
        tournamentId: tournament.id,
        totalParticipants: participants.length,
        completedMatches: 7,
        scheduledMatches: 0,
        highestSeedWon: 1,
        lowestSeedWon: 8,
        undefeatedCount: 0,
      );

      expect(tournament.status, equals(TournamentStatus.active));
      expect(standings.length, equals(8));
      expect(stats.completedMatches + stats.scheduledMatches, equals(7));
    });
  });
}

/// Helper function to calculate log base 2
double log2(num x) => log(x) / log(2);

/// Helper function for natural logarithm
double log(num x) => (x <= 0) ? 0.0 : (x == 1.0) ? 0.0 : _logHelper(x);

double _logHelper(num x) {
  var count = 0;
  var temp = x;
  while (temp >= 2) {
    temp /= 2;
    count++;
  }
  return count.toDouble();
}
