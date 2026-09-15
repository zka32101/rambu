/// AI Difficulty Limiter Tests
/// AI難易度制限機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/services/ai_difficulty_limiter.dart';

void main() {
  group('AI Limit Config Tests', () {
    test('should create config with all parameters', () {
      final config = AILimitConfig(
        difficulty: AIDifficulty.normal,
        maxDepth: 4,
        maxThinkingTimeMs: 3000,
        randomnessStrength: 1.0,
        winRateTarget: 50,
        strength: 1600,
      );

      expect(config.difficulty, equals(AIDifficulty.normal));
      expect(config.maxDepth, equals(4));
      expect(config.maxThinkingTimeMs, equals(3000));
      expect(config.randomnessStrength, equals(1.0));
      expect(config.winRateTarget, equals(50));
      expect(config.strength, equals(1600));
    });

    test('should convert to string representation', () {
      final config = AILimitConfig(
        difficulty: AIDifficulty.hard,
        maxDepth: 5,
        maxThinkingTimeMs: 5000,
        randomnessStrength: 0.3,
        winRateTarget: 70,
        strength: 2000,
      );

      final str = config.toString();
      expect(str, contains('AIDifficulty.hard'));
      expect(str, contains('depth=5'));
      expect(str, contains('5000ms'));
      expect(str, contains('strength=2000'));
    });
  });

  group('Device Performance Detection Tests', () {
    test('should initialize limiter', () async {
      final limiter = AIDifficultyLimiter();
      await limiter.initialize();

      expect(limiter.isInitialized, isTrue);
    });

    test('should provide device info after initialization', () async {
      final limiter = AIDifficultyLimiter();
      await limiter.initialize();

      final info = limiter.deviceInfo;
      expect(info, isNotNull);
      expect(info.level, isNotNull);
      expect(info.deviceName, isNotEmpty);
    });
  });

  group('Difficulty Config Generation Tests', () {
    late AIDifficultyLimiter limiter;

    setUp(() async {
      limiter = AIDifficultyLimiter();
      await limiter.initialize();
    });

    test('should generate easy difficulty config', () {
      final config = limiter.getConfig(AIDifficulty.easy);

      expect(config.difficulty, equals(AIDifficulty.easy));
      expect(config.maxDepth, greaterThanOrEqualTo(1));
      expect(config.maxThinkingTimeMs, greaterThan(0));
      expect(config.randomnessStrength, greaterThan(0));
      expect(config.winRateTarget, lessThan(50));
    });

    test('should generate normal difficulty config', () {
      final config = limiter.getConfig(AIDifficulty.normal);

      expect(config.difficulty, equals(AIDifficulty.normal));
      expect(config.winRateTarget, equals(50));
      expect(config.strength, greaterThan(1500));
    });

    test('should generate hard difficulty config', () {
      final config = limiter.getConfig(AIDifficulty.hard);

      expect(config.difficulty, equals(AIDifficulty.hard));
      expect(config.winRateTarget, greaterThan(60));
      expect(config.strength, greaterThan(config.difficulty == AIDifficulty.normal ? 1600 : 0));
    });

    test('should generate expert difficulty config', () {
      final config = limiter.getConfig(AIDifficulty.expert);

      expect(config.difficulty, equals(AIDifficulty.expert));
      expect(config.winRateTarget, equals(85));
      expect(config.strength, greaterThan(2000));
    });

    test('should increase depth with difficulty', () {
      final easyConfig = limiter.getConfig(AIDifficulty.easy);
      final normalConfig = limiter.getConfig(AIDifficulty.normal);
      final hardConfig = limiter.getConfig(AIDifficulty.hard);
      final expertConfig = limiter.getConfig(AIDifficulty.expert);

      expect(normalConfig.maxDepth, greaterThan(easyConfig.maxDepth));
      expect(hardConfig.maxDepth, greaterThanOrEqualTo(normalConfig.maxDepth));
      expect(expertConfig.maxDepth, greaterThanOrEqualTo(hardConfig.maxDepth));
    });

    test('should increase thinking time with difficulty', () {
      final easyConfig = limiter.getConfig(AIDifficulty.easy);
      final normalConfig = limiter.getConfig(AIDifficulty.normal);
      final hardConfig = limiter.getConfig(AIDifficulty.hard);
      final expertConfig = limiter.getConfig(AIDifficulty.expert);

      expect(normalConfig.maxThinkingTimeMs, greaterThan(easyConfig.maxThinkingTimeMs));
      expect(hardConfig.maxThinkingTimeMs, greaterThan(normalConfig.maxThinkingTimeMs));
      expect(expertConfig.maxThinkingTimeMs, greaterThan(hardConfig.maxThinkingTimeMs));
    });

    test('should decrease randomness with difficulty', () {
      final easyConfig = limiter.getConfig(AIDifficulty.easy);
      final normalConfig = limiter.getConfig(AIDifficulty.normal);
      final hardConfig = limiter.getConfig(AIDifficulty.hard);
      final expertConfig = limiter.getConfig(AIDifficulty.expert);

      expect(normalConfig.randomnessStrength, lessThan(easyConfig.randomnessStrength));
      expect(hardConfig.randomnessStrength, lessThan(normalConfig.randomnessStrength));
      expect(expertConfig.randomnessStrength, lessThan(hardConfig.randomnessStrength));
    });

    test('should increase strength with difficulty', () {
      final easyConfig = limiter.getConfig(AIDifficulty.easy);
      final normalConfig = limiter.getConfig(AIDifficulty.normal);
      final hardConfig = limiter.getConfig(AIDifficulty.hard);
      final expertConfig = limiter.getConfig(AIDifficulty.expert);

      expect(normalConfig.strength, greaterThan(easyConfig.strength));
      expect(hardConfig.strength, greaterThan(normalConfig.strength));
      expect(expertConfig.strength, greaterThan(hardConfig.strength));
    });
  });

  group('AI Engine With Limits Tests', () {
    late AIEngineWithLimits engine;
    late AIDifficultyLimiter limiter;

    setUp(() async {
      limiter = AIDifficultyLimiter();
      await limiter.initialize();
      engine = AIEngineWithLimits(limiter: limiter);
    });

    test('should initialize engine with default difficulty', () {
      expect(engine, isNotNull);
    });

    test('should set difficulty', () {
      engine.setDifficulty(AIDifficulty.hard);
      final config = engine.getCurrentConfig();
      expect(config.difficulty, equals(AIDifficulty.hard));
    });

    test('should track thinking time', () async {
      engine.startThinking();

      await Future.delayed(const Duration(milliseconds: 100));

      final elapsed = engine.getElapsedThinkingTime();
      expect(elapsed, greaterThanOrEqualTo(100));
      expect(elapsed, lessThan(200));
    });

    test('should detect thinking time exceeded', () async {
      engine.setDifficulty(AIDifficulty.easy);
      engine.startThinking();

      // Easy difficulty has 800ms limit
      await Future.delayed(const Duration(milliseconds: 850));

      expect(engine.isThinkingTimeExceeded(), isTrue);
    });

    test('should calculate remaining thinking time', () async {
      engine.setDifficulty(AIDifficulty.easy);
      engine.startThinking();

      await Future.delayed(const Duration(milliseconds: 200));

      final remaining = engine.getRemainingThinkingTime();
      expect(remaining, lessThan(800));
      expect(remaining, greaterThan(500));
    });

    test('should clamp remaining time to zero when exceeded', () async {
      engine.setDifficulty(AIDifficulty.easy);
      engine.startThinking();

      // Wait for time limit to be exceeded
      await Future.delayed(const Duration(milliseconds: 900));

      final remaining = engine.getRemainingThinkingTime();
      expect(remaining, equals(0));
    });

    test('should report search progress', () {
      engine.startThinking();

      // Should not throw
      engine.reportSearchProgress(
        currentDepth: 2,
        maxDepth: 4,
        nodesEvaluated: 1000,
      );
    });
  });

  group('Thinking Time Tests', () {
    late AIEngineWithLimits engine;

    setUp(() async {
      final limiter = AIDifficultyLimiter();
      await limiter.initialize();
      engine = AIEngineWithLimits(limiter: limiter);
    });

    test('thinking time should be zero before starting', () async {
      // Can't directly test this without modifying the class,
      // but we can verify elapsed time after start
      engine.setDifficulty(AIDifficulty.normal);
      engine.startThinking();

      final elapsed = engine.getElapsedThinkingTime();
      expect(elapsed, greaterThanOrEqualTo(0));
    });

    test('should track different thinking times for different difficulties', () async {
      // Easy difficulty
      engine.setDifficulty(AIDifficulty.easy);
      engine.startThinking();
      final easyConfig = engine.getCurrentConfig();
      final easyMax = easyConfig.maxThinkingTimeMs;

      // Normal difficulty
      engine.setDifficulty(AIDifficulty.normal);
      engine.startThinking();
      final normalConfig = engine.getCurrentConfig();
      final normalMax = normalConfig.maxThinkingTimeMs;

      expect(normalMax, greaterThan(easyMax));
    });
  });

  group('Config Manager Tests', () {
    test('should be singleton', () {
      final manager1 = AIConfigManager();
      final manager2 = AIConfigManager();

      expect(identical(manager1, manager2), isTrue);
    });

    test('should provide difficulty presets', () {
      final presets = AIConfigManager.getDifficultyPresets();

      expect(presets.length, equals(4));
      expect(presets[0].$1, equals('初級'));
      expect(presets[1].$1, equals('中級'));
      expect(presets[2].$1, equals('上級'));
      expect(presets[3].$1, equals('最難'));
    });

    test('difficulty presets should have descriptions', () {
      final presets = AIConfigManager.getDifficultyPresets();

      for (final (_, description, _) in presets) {
        expect(description, isNotEmpty);
        expect(description, contains('勝率'));
      }
    });

    test('difficulty presets should have correct difficulties', () {
      final presets = AIConfigManager.getDifficultyPresets();

      expect(presets[0].$3, equals(AIDifficulty.easy));
      expect(presets[1].$3, equals(AIDifficulty.normal));
      expect(presets[2].$3, equals(AIDifficulty.hard));
      expect(presets[3].$3, equals(AIDifficulty.expert));
    });
  });

  group('Device Performance Enum Tests', () {
    test('should have all performance levels', () {
      expect(DevicePerformanceLevel.values.length, greaterThanOrEqualTo(3));
      expect(DevicePerformanceLevel.values, contains(DevicePerformanceLevel.low));
      expect(DevicePerformanceLevel.values, contains(DevicePerformanceLevel.medium));
      expect(DevicePerformanceLevel.values, contains(DevicePerformanceLevel.high));
    });

    test('should have all difficulty levels', () {
      expect(AIDifficulty.values.length, equals(4));
      expect(AIDifficulty.values, contains(AIDifficulty.easy));
      expect(AIDifficulty.values, contains(AIDifficulty.normal));
      expect(AIDifficulty.values, contains(AIDifficulty.hard));
      expect(AIDifficulty.values, contains(AIDifficulty.expert));
    });
  });

  group('Performance Tests', () {
    test('config generation should be fast', () async {
      final limiter = AIDifficultyLimiter();
      await limiter.initialize();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        limiter.getConfig(AIDifficulty.normal);
      }

      stopwatch.stop();

      // 100 config generations should take < 10ms
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('thinking time tracking should be accurate', () async {
      final limiter = AIDifficultyLimiter();
      await limiter.initialize();
      final engine = AIEngineWithLimits(limiter: limiter);

      engine.setDifficulty(AIDifficulty.normal);
      engine.startThinking();

      const delayMs = 150;
      await Future.delayed(const Duration(milliseconds: delayMs));

      final elapsed = engine.getElapsedThinkingTime();

      // Should be approximately equal to delay (±50ms tolerance)
      expect(
        elapsed,
        inInclusiveRange(delayMs - 50, delayMs + 50),
      );
    });
  });
}
