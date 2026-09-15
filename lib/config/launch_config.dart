/// Launch Configuration - ソフトローンチ設定
/// 本番環境でのユーザー・機能の段階的制御
///
/// 使用例:
/// final config = await LaunchConfig.loadConfig();
/// if (!config.isLaunchEnabled) {
///   showMaintenanceScreen();
///   return;
/// }

import 'package:freezed_annotation/freezed_annotation.dart';

part 'launch_config.freezed.dart';
part 'launch_config.g.dart';

/// ローンチ設定データクラス
@freezed
class LaunchConfig with _$LaunchConfig {
  const factory LaunchConfig({
    /// 機能有効化フラグ
    @Default(true) bool launchEnabled,
    @Default(true) bool highlightGenerationEnabled,
    @Default(true) bool highlightSharingEnabled,
    @Default(true) bool analyticsEnabled,

    /// ユーザー制限
    @Default(10) int maxDailyGames,
    @Default(1000) int maxMonthlyUsers,
    @Default(100000) int maxTotalUsers,

    /// メンテナンスモード
    @Default(false) bool maintenanceMode,
    @Default('') String maintenanceMessage,

    /// ソフトローンチステージ
    @Default(LaunchStage.internalTesting) LaunchStage launchStage,

    /// 最終更新日時
    DateTime? lastUpdatedAt,
  }) = _LaunchConfig;

  factory LaunchConfig.fromJson(Map<String, dynamic> json) =>
      _$LaunchConfigFromJson(json);
}

/// ローンチステージ
enum LaunchStage {
  /// ステージ 1: 内部テスター限定（開発チーム）
  internalTesting,

  /// ステージ 2: クローズドベータ（100-500人限定）
  closedBeta,

  /// ステージ 3: 公開リリース（全ユーザー）
  publicRelease,
}

/// ローンチ制限条件
class LaunchLimits {
  /// 1ユーザーあたりの1日のゲーム数上限
  static const int defaultMaxDailyGamesPerUser = 10;

  /// 全体のアクティブユーザー数上限
  static const int defaultMaxMonthlyActiveUsers = 1000;

  /// 全体の登録ユーザー数上限
  static const int defaultMaxTotalUsers = 100000;

  /// テスター向けの1日ゲーム数上限（制限なし）
  static const int testerMaxDailyGames = 999;

  /// パフォーマンステスト時の同時実行ゲーム上限
  static const int maxConcurrentGames = 5;
}

/// ローンチシナリオ（事前定義）
class LaunchScenarios {
  /// シナリオ 1: 開発環境（制限なし）
  static LaunchConfig developmentScenario() {
    return LaunchConfig(
      launchEnabled: true,
      maxDailyGames: 999,
      maxMonthlyUsers: 999999,
      launchStage: LaunchStage.internalTesting,
    );
  }

  /// シナリオ 2: 内部テスト（開発チーム限定）
  static LaunchConfig internalTestingScenario() {
    return LaunchConfig(
      launchEnabled: true,
      highlightGenerationEnabled: true,
      highlightSharingEnabled: true,
      analyticsEnabled: true,
      maxDailyGames: 100, // テスター向けに緩和
      maxMonthlyUsers: 50, // 開発チーム程度
      launchStage: LaunchStage.internalTesting,
    );
  }

  /// シナリオ 3: クローズドベータ（100-500人）
  static LaunchConfig closedBetaScenario() {
    return LaunchConfig(
      launchEnabled: true,
      highlightGenerationEnabled: true,
      highlightSharingEnabled: true,
      analyticsEnabled: true,
      maxDailyGames: 10, // 通常制限
      maxMonthlyUsers: 500, // 限定招待
      launchStage: LaunchStage.closedBeta,
    );
  }

  /// シナリオ 4: 公開リリース（全ユーザー）
  static LaunchConfig publicReleaseScenario() {
    return LaunchConfig(
      launchEnabled: true,
      highlightGenerationEnabled: true,
      highlightSharingEnabled: true,
      analyticsEnabled: true,
      maxDailyGames: 10,
      maxMonthlyUsers: 10000,
      launchStage: LaunchStage.publicRelease,
    );
  }

  /// シナリオ 5: メンテナンス（全機能停止）
  static LaunchConfig maintenanceScenario(String message) {
    return LaunchConfig(
      launchEnabled: false,
      maintenanceMode: true,
      maintenanceMessage: message,
      launchStage: LaunchStage.publicRelease,
    );
  }

  /// シナリオ 6: ハイライト機能のみ停止
  static LaunchConfig highlightDownScenario() {
    return LaunchConfig(
      launchEnabled: true,
      highlightGenerationEnabled: false,
      highlightSharingEnabled: false,
      analyticsEnabled: true,
      launchStage: LaunchStage.publicRelease,
    );
  }
}

/// ローンチ設定の検証ルール
class LaunchConfigValidator {
  /// 設定が有効か検証
  static List<String> validate(LaunchConfig config) {
    final errors = <String>[];

    // メンテナンスモード中は他の設定をチェックしない
    if (config.maintenanceMode) {
      if (config.maintenanceMessage.isEmpty) {
        errors.add('メンテナンスメッセージが空です');
      }
      return errors;
    }

    // ユーザー数制限の整合性チェック
    if (config.maxMonthlyUsers > config.maxTotalUsers) {
      errors.add('月間ユーザー数が全体ユーザー数を超えています');
    }

    if (config.maxDailyGames <= 0) {
      errors.add('1日あたりのゲーム数は1以上である必要があります');
    }

    if (config.maxMonthlyUsers <= 0) {
      errors.add('月間ユーザー数は1以上である必要があります');
    }

    // ステージに応じた制約チェック
    switch (config.launchStage) {
      case LaunchStage.internalTesting:
        if (config.maxMonthlyUsers > 100) {
          errors.add('内部テストは100ユーザー以下である必要があります');
        }
        break;
      case LaunchStage.closedBeta:
        if (config.maxMonthlyUsers > 5000) {
          errors.add('クローズドベータは5000ユーザー以下である必要があります');
        }
        break;
      case LaunchStage.publicRelease:
        // 制限なし
        break;
    }

    return errors;
  }

  /// 設定が有効か（エラーなし）
  static bool isValid(LaunchConfig config) {
    return validate(config).isEmpty;
  }
}

/// ローンチ設定の統計情報
class LaunchConfigStats {
  /// 推定ユーザーあたりのリソース使用量（MB）
  static const double estimatedMemoryPerUser = 2.5;

  /// 推定ユーザーあたりの API 呼び出し数/日
  static const int estimatedAPICallsPerUser = 50;

  /// メモリ使用量の推定
  static double estimatedTotalMemory(LaunchConfig config) {
    return config.maxMonthlyUsers * estimatedMemoryPerUser;
  }

  /// API 呼び出し数の推定
  static int estimatedTotalAPICallsPerDay(LaunchConfig config) {
    return config.maxMonthlyUsers * estimatedAPICallsPerUser;
  }

  /// ストレージ使用量の推定（ハイライト動画 30日保持）
  static double estimatedStorageGB(LaunchConfig config) {
    // 1ゲーム = 約15MB のハイライト動画
    final gamesPerUserPerDay = config.maxDailyGames;
    final videoSizeMB = 15.0;
    final totalUserGamesPerDay = config.maxMonthlyUsers * gamesPerUserPerDay;
    final thirtyDayStorageBytes = totalUserGamesPerDay * videoSizeMB * 30;
    return thirtyDayStorageBytes / 1024; // MB to GB
  }
}
