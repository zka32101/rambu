/// AI Difficulty Limiter
/// デバイス性能に応じたAI思考制限
///
/// 機能:
/// - デバイスAPI レベル検出
/// - 難易度別のパラメータ設定
/// - 思考時間の厳密な制御
/// - 深さ制限（Depth Limit）

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

/// AI難易度レベル
enum AIDifficulty {
  easy,      // 初級: 勝率30-40%
  normal,    // 中級: 勝率50-55%
  hard,      // 上級: 勝率65-75%
  expert,    // 最難: 勝率85%+
}

/// デバイス性能レベル
enum DevicePerformanceLevel {
  low,       // 古端末 (API 29-30)
  medium,    // 中端末 (API 31-33)
  high,      // 新端末 (API 34+)
  unknown,   // 不明
}

/// AI難易度設定
class AILimitConfig {
  /// 難易度
  final AIDifficulty difficulty;

  /// 探索深さ制限
  final int maxDepth;

  /// 思考時間制限（ミリ秒）
  final int maxThinkingTimeMs;

  /// ランダムノイズの強度（評価値に加える）
  /// 値が大きいほどAIが弱くなる
  final double randomnessStrength;

  /// 勝率目標（%）
  final int winRateTarget;

  /// AI戦力値（ELOスコア相当）
  final int strength;

  AILimitConfig({
    required this.difficulty,
    required this.maxDepth,
    required this.maxThinkingTimeMs,
    required this.randomnessStrength,
    required this.winRateTarget,
    required this.strength,
  });

  @override
  String toString() =>
      'AILimitConfig(difficulty=$difficulty, depth=$maxDepth, time=${maxThinkingTimeMs}ms, strength=$strength)';
}

/// デバイス性能情報
class DevicePerformanceInfo {
  /// 性能レベル
  final DevicePerformanceLevel level;

  /// Android API レベル（Android のみ）
  final int? androidApiLevel;

  /// iOS バージョン（iOS のみ）
  final String? iosVersion;

  /// デバイス名
  final String deviceName;

  /// RAM容量（MB）
  final int? ramMB;

  /// プロセッサー情報
  final String? processor;

  DevicePerformanceInfo({
    required this.level,
    this.androidApiLevel,
    this.iosVersion,
    required this.deviceName,
    this.ramMB,
    this.processor,
  });

  @override
  String toString() =>
      'DevicePerformance($level, $deviceName, RAM=${ramMB}MB)';
}

/// AI Difficulty Limiter
class AIDifficultyLimiter {
  /// デバイス性能情報
  late DevicePerformanceInfo _deviceInfo;

  /// 現在の難易度設定
  late AILimitConfig _currentConfig;

  /// 初期化フラグ
  bool _initialized = false;

  /// 初期化
  Future<void> initialize() async {
    try {
      _deviceInfo = await _detectDevicePerformance();
      _initialized = true;
    } catch (e) {
      // デフォルト値を使用
      _deviceInfo = DevicePerformanceInfo(
        level: DevicePerformanceLevel.medium,
        deviceName: 'Unknown',
      );
      _initialized = true;
    }
  }

  /// デバイス性能を検出
  Future<DevicePerformanceInfo> _detectDevicePerformance() async {
    try {
      if (Platform.isAndroid) {
        return await _detectAndroidPerformance();
      } else if (Platform.isIOS) {
        return await _detectIOSPerformance();
      }
    } catch (e) {
      // Fallback
    }

    return DevicePerformanceInfo(
      level: DevicePerformanceLevel.medium,
      deviceName: 'Unknown',
    );
  }

  /// Android デバイス性能を検出
  Future<DevicePerformanceInfo> _detectAndroidPerformance() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    final apiLevel = androidInfo.version.sdkInt ?? 31;
    final deviceName = androidInfo.model ?? 'Unknown';

    DevicePerformanceLevel level;
    if (apiLevel <= 30) {
      level = DevicePerformanceLevel.low;      // 古端末
    } else if (apiLevel <= 33) {
      level = DevicePerformanceLevel.medium;   // 中端末
    } else {
      level = DevicePerformanceLevel.high;     // 新端末
    }

    return DevicePerformanceInfo(
      level: level,
      androidApiLevel: apiLevel,
      deviceName: deviceName,
    );
  }

  /// iOS デバイス性能を検出
  Future<DevicePerformanceInfo> _detectIOSPerformance() async {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;

    final version = iosInfo.systemVersion ?? '14.0';
    final deviceName = iosInfo.utsname.machine ?? 'Unknown';

    // iOSはAPI レベルがないため、バージョンで判定
    DevicePerformanceLevel level;
    try {
      final majorVersion = int.parse(version.split('.').first);
      if (majorVersion <= 14) {
        level = DevicePerformanceLevel.low;
      } else if (majorVersion <= 16) {
        level = DevicePerformanceLevel.medium;
      } else {
        level = DevicePerformanceLevel.high;
      }
    } catch (e) {
      level = DevicePerformanceLevel.medium;
    }

    return DevicePerformanceInfo(
      level: level,
      iosVersion: version,
      deviceName: deviceName,
    );
  }

  /// 難易度設定を取得（デバイス性能適応）
  AILimitConfig getConfig(AIDifficulty difficulty) {
    if (!_initialized) {
      // デフォルト設定を返す
      return _getDefaultConfig(difficulty);
    }

    return _buildConfig(difficulty, _deviceInfo.level);
  }

  /// 難易度設定を構築
  AILimitConfig _buildConfig(
    AIDifficulty difficulty,
    DevicePerformanceLevel deviceLevel,
  ) {
    // ベース設定（高性能デバイス用）
    late AILimitConfig baseConfig;
    switch (difficulty) {
      case AIDifficulty.easy:
        baseConfig = AILimitConfig(
          difficulty: difficulty,
          maxDepth: 2,
          maxThinkingTimeMs: 800,
          randomnessStrength: 5.0,
          winRateTarget: 35,
          strength: 1200,  // ELO
        );
        break;
      case AIDifficulty.normal:
        baseConfig = AILimitConfig(
          difficulty: difficulty,
          maxDepth: 4,
          maxThinkingTimeMs: 3000,
          randomnessStrength: 1.0,
          winRateTarget: 50,
          strength: 1600,
        );
        break;
      case AIDifficulty.hard:
        baseConfig = AILimitConfig(
          difficulty: difficulty,
          maxDepth: 5,
          maxThinkingTimeMs: 5000,
          randomnessStrength: 0.3,
          winRateTarget: 70,
          strength: 2000,
        );
        break;
      case AIDifficulty.expert:
        baseConfig = AILimitConfig(
          difficulty: difficulty,
          maxDepth: 6,
          maxThinkingTimeMs: 8000,
          randomnessStrength: 0.1,
          winRateTarget: 85,
          strength: 2400,
        );
        break;
    }

    // デバイス性能に応じて調整
    return _adjustForDevice(baseConfig, deviceLevel);
  }

  /// デバイス性能に応じて設定を調整
  AILimitConfig _adjustForDevice(
    AILimitConfig config,
    DevicePerformanceLevel deviceLevel,
  ) {
    switch (deviceLevel) {
      case DevicePerformanceLevel.low:
        // 古端末: 深さを1減らし、思考時間を30%短縮
        return AILimitConfig(
          difficulty: config.difficulty,
          maxDepth: (config.maxDepth - 1).clamp(1, 6),
          maxThinkingTimeMs: (config.maxThinkingTimeMs * 0.7).toInt(),
          randomnessStrength: config.randomnessStrength * 1.5,  // より弱く
          winRateTarget: config.winRateTarget,
          strength: (config.strength * 0.85).toInt(),
        );

      case DevicePerformanceLevel.medium:
        // 中端末: そのまま
        return config;

      case DevicePerformanceLevel.high:
        // 新端末: 深さを1増やし、思考時間を50%延長
        return AILimitConfig(
          difficulty: config.difficulty,
          maxDepth: (config.maxDepth + 1).clamp(1, 6),
          maxThinkingTimeMs: (config.maxThinkingTimeMs * 1.5).toInt(),
          randomnessStrength: config.randomnessStrength * 0.8,  // より強く
          winRateTarget: config.winRateTarget,
          strength: (config.strength * 1.15).toInt(),
        );

      case DevicePerformanceLevel.unknown:
        // 不明: 保守的に
        return config;
    }
  }

  /// デフォルト設定を取得
  AILimitConfig _getDefaultConfig(AIDifficulty difficulty) {
    return _buildConfig(difficulty, DevicePerformanceLevel.medium);
  }

  /// 現在のデバイス情報を取得
  DevicePerformanceInfo get deviceInfo => _deviceInfo;

  /// 初期化状態を確認
  bool get isInitialized => _initialized;

  /// デバッグ情報を出力
  void debugPrint() {
    print('=== AI Difficulty Limiter Info ===');
    print('Device: $_deviceInfo');
    print('Config: $_currentConfig');
  }
}

/// AIエンジンへの統合ラッパー
class AIEngineWithLimits {
  /// AI難易度制限器
  final AIDifficultyLimiter limiter;

  /// 現在の難易度
  AIDifficulty _currentDifficulty = AIDifficulty.normal;

  /// 思考開始時刻
  late DateTime _thinkingStartTime;

  /// 思考時間制限（ミリ秒）
  late int _maxThinkingTime;

  AIEngineWithLimits({required this.limiter});

  /// 難易度を設定
  void setDifficulty(AIDifficulty difficulty) {
    _currentDifficulty = difficulty;
  }

  /// 思考を開始
  void startThinking() {
    final config = limiter.getConfig(_currentDifficulty);
    _thinkingStartTime = DateTime.now();
    _maxThinkingTime = config.maxThinkingTimeMs;
  }

  /// 思考時間超過を確認
  bool isThinkingTimeExceeded() {
    final elapsed = DateTime.now().difference(_thinkingStartTime).inMilliseconds;
    return elapsed >= _maxThinkingTime;
  }

  /// 経過思考時間を取得（ミリ秒）
  int getElapsedThinkingTime() {
    return DateTime.now().difference(_thinkingStartTime).inMilliseconds;
  }

  /// 残り思考時間を取得（ミリ秒）
  int getRemainingThinkingTime() {
    final elapsed = getElapsedThinkingTime();
    return (_maxThinkingTime - elapsed).clamp(0, _maxThinkingTime);
  }

  /// 現在の難易度設定を取得
  AILimitConfig getCurrentConfig() {
    return limiter.getConfig(_currentDifficulty);
  }

  /// 思考進捗を報告（深さごと）
  void reportSearchProgress({
    required int currentDepth,
    required int maxDepth,
    required int nodesEvaluated,
  }) {
    final percent = (currentDepth / maxDepth * 100).toInt();
    final elapsed = getElapsedThinkingTime();
    final remaining = getRemainingThinkingTime();

    print('Search Progress: $currentDepth/$maxDepth ($percent%) '
        'Nodes: $nodesEvaluated '
        'Time: ${elapsed}ms/${_maxThinkingTime}ms');
  }

  /// デバッグ出力
  void debugPrint() {
    limiter.debugPrint();
    print('Current Difficulty: $_currentDifficulty');
    print('Elapsed: ${getElapsedThinkingTime()}ms / $_maxThinkingTime');
  }
}

/// グローバルな難易度設定マネージャー
class AIConfigManager {
  static final AIConfigManager _instance = AIConfigManager._internal();

  late AIDifficultyLimiter _limiter;

  AIConfigManager._internal();

  factory AIConfigManager() {
    return _instance;
  }

  /// 初期化
  Future<void> initialize() async {
    _limiter = AIDifficultyLimiter();
    await _limiter.initialize();
  }

  /// 難易度設定を取得
  AILimitConfig getConfig(AIDifficulty difficulty) {
    return _limiter.getConfig(difficulty);
  }

  /// 難易度制限器を取得
  AIDifficultyLimiter get limiter => _limiter;

  /// プリセット難易度をリスト取得
  static List<(String label, String description, AIDifficulty difficulty)> getDifficultyPresets() {
    return [
      (
        '初級',
        '勝率: 30-40% (初心者向け)',
        AIDifficulty.easy,
      ),
      (
        '中級',
        '勝率: 50-55% (標準)',
        AIDifficulty.normal,
      ),
      (
        '上級',
        '勝率: 65-75% (チャレンジ向け)',
        AIDifficulty.hard,
      ),
      (
        '最難',
        '勝率: 85%+ (エキスパート向け)',
        AIDifficulty.expert,
      ),
    ];
  }
}
