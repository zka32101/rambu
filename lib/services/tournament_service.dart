/// Tournament Service
/// トーナメント・マッチング・ブラケット管理

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rambu_shogi/models/tournament.dart';

/// トーナメント サービス
class TournamentService {
  static final TournamentService _instance = TournamentService._internal();

  late FirebaseFirestore _firestore;

  TournamentService._internal();

  factory TournamentService() {
    return _instance;
  }

  /// 初期化
  void initialize(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  // ================== Tournament Methods ==================

  /// トーナメント一覧を取得
  Future<List<Tournament>> getAllTournaments({String? status}) async {
    try {
      Query query = _firestore.collection('tournaments');

      if (status != null) {
        query = query.where('status', isEqualTo: TournamentStatus.values
            .indexWhere((s) => s.toString().split('.').last == status));
      }

      final snapshot = await query
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => Tournament.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Failed to get all tournaments: $e');
      return [];
    }
  }

  /// トーナメントをIDで取得
  Future<Tournament?> getTournamentById(String tournamentId) async {
    try {
      final doc = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (doc.exists) {
        return Tournament.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Failed to get tournament: $e');
      return null;
    }
  }

  /// 推奨トーナメント取得（ユーザーレーティングに基づく）
  Future<List<Tournament>> getRecommendedTournaments(int userRating) async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .where('status', isEqualTo: TournamentStatus.registration.index)
          .where('minRating', isLessThanOrEqualTo: userRating)
          .where('maxRating', isGreaterThanOrEqualTo: userRating)
          .orderBy('minRating', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => Tournament.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Failed to get recommended tournaments: $e');
      return [];
    }
  }

  /// トーナメント作成
  Future<String> createTournament(Tournament tournament) async {
    try {
      final docRef = _firestore.collection('tournaments').doc();
      await docRef.set(tournament.copyWith(id: docRef.id).toJson());
      return docRef.id;
    } catch (e) {
      print('Failed to create tournament: $e');
      rethrow;
    }
  }

  // ================== Tournament Participant Methods ==================

  /// 参加者登録
  Future<void> registerParticipant(
    String tournamentId,
    String userId,
    String userName,
    int rating,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .get();

      final seed = snapshot.size + 1;

      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .doc(userId)
          .set(
            TournamentParticipant(
              userId: userId,
              userName: userName,
              rating: rating,
              seed: seed,
              registeredAt: DateTime.now().toIso8601String(),
            ).toJson(),
          );

      // 参加者数を更新
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .update({
        'currentParticipants': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to register participant: $e');
      rethrow;
    }
  }

  /// 参加者一覧を取得（シード順）
  Future<List<TournamentParticipant>> getTournamentParticipants(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .orderBy('seed')
          .get();

      return snapshot.docs
          .map((doc) => TournamentParticipant.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get tournament participants: $e');
      return [];
    }
  }

  /// チェックイン
  Future<void> checkInParticipant(String tournamentId, String userId) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .doc(userId)
          .update({'checkedIn': true});
    } catch (e) {
      print('Failed to check in participant: $e');
      rethrow;
    }
  }

  // ================== Match Methods ==================

  /// マッチ一覧を取得
  Future<List<TournamentMatch>> getTournamentMatches(
    String tournamentId, {
    int? round,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches');

      if (round != null) {
        query = query.where('round', isEqualTo: round);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: MatchStatus.values
            .indexWhere((s) => s.toString().split('.').last == status));
      }

      final snapshot = await query
          .orderBy('round')
          .orderBy('matchNumber')
          .get();

      return snapshot.docs
          .map((doc) => TournamentMatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to get tournament matches: $e');
      return [];
    }
  }

  /// ブラケット生成（シングルエリミネーション）
  Future<void> generateSingleEliminationBracket(String tournamentId) async {
    try {
      final participants = await getTournamentParticipants(tournamentId);

      // 参加者を2の累乗に最小化
      final nextPowerOfTwo = _nextPowerOfTwo(participants.length);
      final matches = <TournamentMatch>[];

      // ラウンド1マッチを生成
      for (int i = 0; i < nextPowerOfTwo ~/ 2; i++) {
        final player1 = i < participants.length ? participants[i] : null;
        final player2 = (i + nextPowerOfTwo ~/ 2) < participants.length
            ? participants[i + nextPowerOfTwo ~/ 2]
            : null;

        if (player1 != null) {
          final match = TournamentMatch(
            id: '${tournamentId}_r1_m${i + 1}',
            tournamentId: tournamentId,
            round: 1,
            matchNumber: i + 1,
            player1Id: player1.userId,
            player1Name: player1.userName,
            player1Seed: player1.seed,
            player2Id: player2?.userId,
            player2Name: player2?.userName,
            player2Seed: player2?.seed,
          );

          matches.add(match);
        }
      }

      // バッチ書き込み
      final batch = _firestore.batch();
      for (final match in matches) {
        final docRef = _firestore
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(match.id);
        batch.set(docRef, match.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('Failed to generate bracket: $e');
      rethrow;
    }
  }

  /// マッチ結果を記録
  Future<void> recordMatchResult(
    String tournamentId,
    String matchId,
    String winnerId,
    int player1Score,
    int player2Score,
  ) async {
    try {
      final matchRef = _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId);

      final matchDoc = await matchRef.get();
      if (!matchDoc.exists) return;

      final match = TournamentMatch.fromJson(matchDoc.data() as Map<String, dynamic>);

      // マッチ結果を更新
      await matchRef.update({
        'status': MatchStatus.completed.index,
        'winnerId': winnerId,
        'player1Score': player1Score,
        'player2Score': player2Score,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // 次のラウンドへの進出を自動生成（シングルエリミネーション）
      if (match.round < 10) {
        // 次のラウンドのマッチを作成
        final nextRound = match.round + 1;
        final nextMatchNumber = ((match.matchNumber - 1) ~/ 2) + 1;
        final isPlayer1Position = match.matchNumber % 2 == 1;

        final nextMatchId = '${tournamentId}_r${nextRound}_m${nextMatchNumber}';
        final nextMatchRef = _firestore
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(nextMatchId);

        final nextMatchDoc = await nextMatchRef.get();

        if (nextMatchDoc.exists) {
          // 既存のマッチに勝者を更新
          final updateData = isPlayer1Position
              ? {
                  'player1Id': winnerId,
                  'player1Name': winnerId == match.player1Id ? match.player1Name : match.player2Name,
                  'player1Seed': winnerId == match.player1Id ? match.player1Seed : match.player2Seed,
                }
              : {
                  'player2Id': winnerId,
                  'player2Name': winnerId == match.player1Id ? match.player1Name : match.player2Name,
                  'player2Seed': winnerId == match.player1Id ? match.player1Seed : match.player2Seed,
                };

          await nextMatchRef.update(updateData);
        } else {
          // 新規マッチを作成
          final nextMatch = isPlayer1Position
              ? TournamentMatch(
                  id: nextMatchId,
                  tournamentId: tournamentId,
                  round: nextRound,
                  matchNumber: nextMatchNumber,
                  player1Id: winnerId,
                  player1Name: winnerId == match.player1Id ? match.player1Name : match.player2Name,
                  player1Seed: winnerId == match.player1Id ? match.player1Seed : match.player2Seed,
                )
              : TournamentMatch(
                  id: nextMatchId,
                  tournamentId: tournamentId,
                  round: nextRound,
                  matchNumber: nextMatchNumber,
                  player1Id: 'TBD',
                  player1Name: 'TBD',
                  player1Seed: 0,
                  player2Id: winnerId,
                  player2Name: winnerId == match.player1Id ? match.player1Name : match.player2Name,
                  player2Seed: winnerId == match.player1Id ? match.player1Seed : match.player2Seed,
                );

          await nextMatchRef.set(nextMatch.toJson());
        }
      }
    } catch (e) {
      print('Failed to record match result: $e');
      rethrow;
    }
  }

  // ================== Prize Distribution Methods ==================

  /// 賞金配分を計算
  List<PrizeStructure> calculatePrizeDistribution(int totalPrizePool, int participantCount) {
    final prizeStructure = <PrizeStructure>[];

    // シングルエリミネーションの場合の標準的な賞金配分（16人）
    const distributionRatios = {
      1: 0.50, // 1位: 50%
      2: 0.25, // 2位: 25%
      3: 0.10, // 3位: 10%
      4: 0.10, // 4位: 10%
      5: 0.03, // 5-8位: 3%
      6: 0.02, // 9-16位: 2%
    };

    int placement = 1;
    for (final entry in distributionRatios.entries) {
      final ratio = entry.value;
      final prizeAmount = (totalPrizePool * ratio).toInt();

      prizeStructure.add(
        PrizeStructure(
          placement: placement,
          prizeAmount: prizeAmount,
          percentage: ratio * 100,
        ),
      );

      placement++;
    }

    return prizeStructure;
  }

  /// 最終順位と賞金を記録
  Future<void> recordFinalPlacement(
    String tournamentId,
    String userId,
    String placement,
    int prizeWon,
  ) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .doc(userId)
          .update({
        'finalPlacement': placement,
        'prizeWon': prizeWon,
      });

      // ユーザーの総ポイントを更新
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'totalPoints': FieldValue.increment(prizeWon),
        'tournamentWinnings': FieldValue.increment(prizeWon),
      });
    } catch (e) {
      print('Failed to record final placement: $e');
      rethrow;
    }
  }

  // ================== Tournament Stats Methods ==================

  /// トーナメント統計を計算
  Future<TournamentStats> calculateTournamentStats(String tournamentId) async {
    try {
      final matches = await getTournamentMatches(tournamentId);
      final participants = await getTournamentParticipants(tournamentId);

      final completedMatches = matches.where((m) => m.status == MatchStatus.completed).length;
      final scheduledMatches = matches.where((m) => m.status == MatchStatus.scheduled).length;

      // 各参加者の勝率を計算
      final playerWins = <String, int>{};
      for (final match in matches.where((m) => m.status == MatchStatus.completed)) {
        if (match.winnerId != null) {
          playerWins[match.winnerId!] = (playerWins[match.winnerId!] ?? 0) + 1;
        }
      }

      // シード番号と勝利者を比較
      int highestSeedWon = 1;
      int lowestSeedWon = participants.length;
      int undefeatedCount = 0;

      for (final participant in participants) {
        final wins = playerWins[participant.userId] ?? 0;
        if (wins > 0) {
          if (participant.seed < highestSeedWon) {
            highestSeedWon = participant.seed;
          }
          if (participant.seed > lowestSeedWon) {
            lowestSeedWon = participant.seed;
          }
        }
        // 無敗: 参加者がいる場合、ラウンド数만큼 이길 경우
        if (wins >= 5) {
          undefeatedCount++;
        }
      }

      return TournamentStats(
        tournamentId: tournamentId,
        totalParticipants: participants.length,
        completedMatches: completedMatches,
        scheduledMatches: scheduledMatches,
        highestSeedWon: highestSeedWon,
        lowestSeedWon: lowestSeedWon,
        undefeatedCount: undefeatedCount,
      );
    } catch (e) {
      print('Failed to calculate tournament stats: $e');
      rethrow;
    }
  }

  // ================== Helper Methods ==================

  /// 次の2の累乗を計算
  int _nextPowerOfTwo(int n) {
    if (n == 0) return 1;
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
  }
}

/// Tournament extensions for copyWith
extension TournamentExt on Tournament {
  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    TournamentFormat? format,
    TournamentStatus? status,
    int? maxParticipants,
    int? currentParticipants,
    int? entryFee,
    int? prizePool,
    String? startDate,
    String? endDate,
    int? bestOf,
    String? organizerId,
    int? minRating,
    int? maxRating,
    String? region,
    bool? allowSpectators,
    bool? allowStreaming,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bestOf: bestOf ?? this.bestOf,
      organizerId: organizerId ?? this.organizerId,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      region: region ?? this.region,
      allowSpectators: allowSpectators ?? this.allowSpectators,
      allowStreaming: allowStreaming ?? this.allowStreaming,
    );
  }
}
