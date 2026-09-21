/// Analytics Service
/// Firebase Analytics へのイベント送信 ＋ ソフトローンチKPI集計（Firestore）
///
/// CLAUDE.md ソフトローンチゲート条件:
/// - Day1 Retention: 20%+
/// - Aha Moment（ハイライト生成体験）: 60%+
/// - Bot勝率: 50±3%
///
/// 機能:
/// - 標準イベント送信（Firebase Analytics）
/// - KPI集計用の生データ記録（Firestore）
/// - ゲート判定（Remote Config と連携）

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// KPIサマリー Provider
final kpiSummaryProvider = FutureProvider<KpiSummary>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.calculateKpiSummary();
});

/// ソフトローンチKPIサマリー
class KpiSummary {
  /// Day1 リテンション率（%）
  final double day1RetentionRate;

  /// Aha Moment 体験率（%）- ハイライト生成経験ユーザーの割合
  final double ahaMomentRate;

  /// 平均セッション時間（秒）
  final double averageSessionSeconds;

  /// Day7 リテンション率（%）
  final double day7RetentionRate;

  /// Day30 リテンション率（%）
  final double day30RetentionRate;

  /// 集計対象の新規ユーザー数
  final int totalNewUsers;

  KpiSummary({
    this.day1RetentionRate = 0.0,
    this.ahaMomentRate = 0.0,
    this.averageSessionSeconds = 0.0,
    this.day7RetentionRate = 0.0,
    this.day30RetentionRate = 0.0,
    this.totalNewUsers = 0,
  });

  /// ソフトローンチゲート基準を満たしているか（CLAUDE.md 基準）
  bool get meetsLaunchGate =>
      day1RetentionRate >= 20.0 && ahaMomentRate >= 60.0;

  Map<String, dynamic> toJson() => {
        'day1RetentionRate': day1RetentionRate,
        'ahaMomentRate': ahaMomentRate,
        'averageSessionSeconds': averageSessionSeconds,
        'day7RetentionRate': day7RetentionRate,
        'day30RetentionRate': day30RetentionRate,
        'totalNewUsers': totalNewUsers,
      };
}

/// Analytics Service
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// KPI集計用の生データコレクション
  static const String _usersCollection = 'analytics_users';
  static const String _sessionsCollection = 'analytics_sessions';

  // ---------------------------------------------------------------------
  // イベント送信（Firebase Analytics）
  // ---------------------------------------------------------------------

  /// ユーザー初回起動を記録（Day1リテンション計測の基準日として保存）
  Future<void> logFirstOpen(String userId) async {
    await _analytics.logEvent(name: 'first_open_tracked');

    final userDoc = _firestore.collection(_usersCollection).doc(userId);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'userId': userId,
        'firstOpenAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'ahaMomentAchieved': false,
        'activeDays': <String>[],
      });
    }
  }

  /// ユーザーのセッション開始を記録（リテンション・エンゲージメント計測用）
  Future<void> logSessionStart(String userId) async {
    await _analytics.logEvent(name: 'session_start');

    final today = _dateKey(DateTime.now());
    final userDoc = _firestore.collection(_usersCollection).doc(userId);

    await userDoc.set({
      'lastSeenAt': FieldValue.serverTimestamp(),
      'activeDays': FieldValue.arrayUnion([today]),
    }, SetOptions(merge: true));
  }

  /// セッション終了を記録（セッション時間の計測）
  Future<void> logSessionEnd(String userId, Duration sessionDuration) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {'duration_seconds': sessionDuration.inSeconds},
    );

    await _firestore.collection(_sessionsCollection).add({
      'userId': userId,
      'durationSeconds': sessionDuration.inSeconds,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 対局開始を記録
  Future<void> logGameStart({
    required String difficulty,
    required bool isSecondHandHandicapUsed,
  }) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {
        'difficulty': difficulty,
        'second_hand_handicap': isSecondHandHandicapUsed,
      },
    );
  }

  /// 対局終了を記録
  Future<void> logGameEnd({
    required String winner,
    required int turnCount,
    required Duration gameDuration,
  }) async {
    await _analytics.logEvent(
      name: 'game_end',
      parameters: {
        'winner': winner,
        'turn_count': turnCount,
        'duration_seconds': gameDuration.inSeconds,
      },
    );
  }

  /// Aha Moment（ハイライト生成体験）を記録
  ///
  /// 「飛び道具のクリティカルアタックで HP が0になる」演出を体験し、
  /// ハイライト動画の生成に成功したタイミングで呼び出す。
  Future<void> logAhaMoment(String userId) async {
    await _analytics.logEvent(name: 'aha_moment_highlight_generated');

    await _firestore.collection(_usersCollection).doc(userId).set({
      'ahaMomentAchieved': true,
      'ahaMomentAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ハイライト共有を記録
  Future<void> logHighlightShared(String platform) async {
    await _analytics.logEvent(
      name: 'highlight_shared',
      parameters: {'platform': platform},
    );
  }

  // ---------------------------------------------------------------------
  // KPI 集計（ソフトローンチゲート判定用）
  // ---------------------------------------------------------------------

  /// ソフトローンチKPIサマリーを計算
  ///
  /// CLAUDE.md ゲート条件:
  /// - Day1 Retention 20%+
  /// - Aha Moment 60%+
  Future<KpiSummary> calculateKpiSummary() async {
    final usersSnapshot = await _firestore.collection(_usersCollection).get();

    if (usersSnapshot.docs.isEmpty) {
      return KpiSummary();
    }

    int totalUsers = 0;
    int day1Retained = 0;
    int day7Retained = 0;
    int day30Retained = 0;
    int ahaMomentUsers = 0;

    final now = DateTime.now();

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      totalUsers++;

      if (data['ahaMomentAchieved'] == true) {
        ahaMomentUsers++;
      }

      final firstOpenTimestamp = data['firstOpenAt'] as Timestamp?;
      final activeDays = List<String>.from(data['activeDays'] ?? const []);

      if (firstOpenTimestamp != null) {
        final firstOpen = firstOpenTimestamp.toDate();
        if (_hasActivityOnOffset(activeDays, firstOpen, 1, now)) day1Retained++;
        if (_hasActivityOnOffset(activeDays, firstOpen, 7, now)) day7Retained++;
        if (_hasActivityOnOffset(activeDays, firstOpen, 30, now)) day30Retained++;
      }
    }

    final avgSessionSeconds = await _calculateAverageSessionSeconds();

    return KpiSummary(
      day1RetentionRate: _percentage(day1Retained, totalUsers),
      ahaMomentRate: _percentage(ahaMomentUsers, totalUsers),
      averageSessionSeconds: avgSessionSeconds,
      day7RetentionRate: _percentage(day7Retained, totalUsers),
      day30RetentionRate: _percentage(day30Retained, totalUsers),
      totalNewUsers: totalUsers,
    );
  }

  /// 指定日オフセットに活動していたか（かつ現在時点でそのオフセットを評価可能か）
  bool _hasActivityOnOffset(
    List<String> activeDays,
    DateTime firstOpen,
    int offsetDays,
    DateTime now,
  ) {
    final targetDate = firstOpen.add(Duration(days: offsetDays));
    // 対象日がまだ来ていない場合は評価対象外（false扱い＝分母には残るが未達）
    if (now.isBefore(targetDate)) return false;
    return activeDays.contains(_dateKey(targetDate));
  }

  Future<double> _calculateAverageSessionSeconds() async {
    final sessionsSnapshot =
        await _firestore.collection(_sessionsCollection).get();
    if (sessionsSnapshot.docs.isEmpty) return 0.0;

    final total = sessionsSnapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['durationSeconds'] as num?)?.toInt() ?? 0),
    );

    return total / sessionsSnapshot.docs.length;
  }

  double _percentage(int part, int total) {
    if (total == 0) return 0.0;
    return (part / total) * 100;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
