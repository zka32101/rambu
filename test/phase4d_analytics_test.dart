/// Phase 4d Analytics Service Tests
/// ソフトローンチKPI集計ロジックのテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/services/analytics_service.dart';

void main() {
  group('KpiSummary Tests', () {
    test('should create KPI summary with default values', () {
      final summary = KpiSummary();

      expect(summary.day1RetentionRate, equals(0.0));
      expect(summary.ahaMomentRate, equals(0.0));
      expect(summary.totalNewUsers, equals(0));
    });

    test('should meet launch gate when Day1 retention >= 20% and Aha Moment >= 60%', () {
      final summary = KpiSummary(
        day1RetentionRate: 22.0,
        ahaMomentRate: 65.0,
        totalNewUsers: 100,
      );

      expect(summary.meetsLaunchGate, isTrue);
    });

    test('should NOT meet launch gate when Day1 retention below threshold', () {
      final summary = KpiSummary(
        day1RetentionRate: 15.0,
        ahaMomentRate: 70.0,
        totalNewUsers: 100,
      );

      expect(summary.meetsLaunchGate, isFalse);
    });

    test('should NOT meet launch gate when Aha Moment below threshold', () {
      final summary = KpiSummary(
        day1RetentionRate: 25.0,
        ahaMomentRate: 45.0,
        totalNewUsers: 100,
      );

      expect(summary.meetsLaunchGate, isFalse);
    });

    test('should meet launch gate exactly at threshold boundary', () {
      final summary = KpiSummary(
        day1RetentionRate: 20.0,
        ahaMomentRate: 60.0,
        totalNewUsers: 50,
      );

      expect(summary.meetsLaunchGate, isTrue);
    });

    test('should convert to JSON correctly', () {
      final summary = KpiSummary(
        day1RetentionRate: 24.5,
        ahaMomentRate: 61.2,
        averageSessionSeconds: 320.0,
        day7RetentionRate: 42.0,
        day30RetentionRate: 16.0,
        totalNewUsers: 250,
      );

      final json = summary.toJson();

      expect(json['day1RetentionRate'], equals(24.5));
      expect(json['ahaMomentRate'], equals(61.2));
      expect(json['averageSessionSeconds'], equals(320.0));
      expect(json['day7RetentionRate'], equals(42.0));
      expect(json['day30RetentionRate'], equals(16.0));
      expect(json['totalNewUsers'], equals(250));
    });

    test('should track engagement above 5-minute target', () {
      final summary = KpiSummary(averageSessionSeconds: 320.0);

      expect(summary.averageSessionSeconds, greaterThan(300));
    });

    test('should track Day7 and Day30 retention independently from Day1', () {
      final summary = KpiSummary(
        day1RetentionRate: 25.0,
        day7RetentionRate: 40.0,
        day30RetentionRate: 15.0,
      );

      expect(summary.day7RetentionRate, equals(40.0));
      expect(summary.day30RetentionRate, equals(15.0));
      // ゲート判定はDay1とAhaのみに依存
      expect(summary.meetsLaunchGate, isFalse); // ahaMomentRate未設定=0
    });
  });

  group('KPI Gate Boundary Tests', () {
    test('should fail gate with zero users', () {
      final summary = KpiSummary(totalNewUsers: 0);
      expect(summary.meetsLaunchGate, isFalse);
    });

    test('should handle 100% retention and aha rates', () {
      final summary = KpiSummary(
        day1RetentionRate: 100.0,
        ahaMomentRate: 100.0,
        totalNewUsers: 10,
      );
      expect(summary.meetsLaunchGate, isTrue);
    });

    test('should fail gate just below Day1 threshold', () {
      final summary = KpiSummary(
        day1RetentionRate: 19.99,
        ahaMomentRate: 80.0,
      );
      expect(summary.meetsLaunchGate, isFalse);
    });

    test('should fail gate just below Aha Moment threshold', () {
      final summary = KpiSummary(
        day1RetentionRate: 30.0,
        ahaMomentRate: 59.99,
      );
      expect(summary.meetsLaunchGate, isFalse);
    });
  });

  group('Performance Tests', () {
    test('should create many KPI summaries quickly', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        KpiSummary(
          day1RetentionRate: i.toDouble() % 100,
          ahaMomentRate: (i * 2).toDouble() % 100,
          totalNewUsers: i,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
