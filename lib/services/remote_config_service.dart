/// Remote Config Service
/// Firestore からローンチ設定を動的に取得・管理
///
/// 機能:
/// - Remote Config の読み込み（キャッシュ付き）
/// - リアルタイムリスナー（設定変更の即座反映）
/// - ローカルオーバーライド（開発・テスト用）
/// - 自動フォールバック

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/config/launch_config.dart';

/// Remote Config Service Provider
final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((ref) => RemoteConfigService());

/// ローンチ設定 Provider（キャッシュ付き）
final launchConfigProvider =
    FutureProvider<LaunchConfig>((ref) async {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.getConfig();
});

/// ローンチ設定ストリーム Provider（リアルタイム更新）
final launchConfigStreamProvider =
    StreamProvider<LaunchConfig>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.watchConfig();
});

/// Remote Config Service
class RemoteConfigService {
  /// Firestore インスタンス
  final _firestore = FirebaseFirestore.instance;

  /// 設定ドキュメントパス
  static const String _configPath = 'config/launch_config';

  /// キャッシュ（最後に読み込んだ設定）
  LaunchConfig? _cachedConfig;

  /// キャッシュ有効期限（5分）
  static const Duration _cacheDuration = Duration(minutes: 5);
  DateTime? _cacheTime;

  /// ローカルオーバーライド（テスト用）
  LaunchConfig? _localOverride;

  /// 初期化済みフラグ
  bool _initialized = false;

  /// 初期化処理
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await getConfig();
      _initialized = true;
    } catch (e) {
      print('RemoteConfigService initialization error: $e');
      // フォールバック: デフォルト設定を使用
      _cachedConfig = LaunchScenarios.publicReleaseScenario();
      _cacheTime = DateTime.now();
      _initialized = true;
    }
  }

  /// 設定を取得（キャッシュ優先）
  Future<LaunchConfig> getConfig() async {
    // ローカルオーバーライドがある場合は優先
    if (_localOverride != null) {
      return _localOverride!;
    }

    // キャッシュが有効か確認
    if (_cachedConfig != null && _cacheTime != null) {
      final now = DateTime.now();
      if (now.difference(_cacheTime!) < _cacheDuration) {
        return _cachedConfig!;
      }
    }

    // Firestore から取得
    try {
      final doc = await _firestore.doc(_configPath).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _cachedConfig = LaunchConfig.fromJson(data);
      } else {
        // ドキュメントが存在しない場合はデフォルト
        _cachedConfig = LaunchScenarios.publicReleaseScenario();
        _initializeDocument(_cachedConfig!);
      }

      _cacheTime = DateTime.now();
      return _cachedConfig!;
    } catch (e) {
      print('RemoteConfigService.getConfig error: $e');

      // フォールバック
      if (_cachedConfig != null) {
        return _cachedConfig!;
      }
      return LaunchScenarios.publicReleaseScenario();
    }
  }

  /// 設定をリアルタイムで監視
  Stream<LaunchConfig> watchConfig() {
    return _firestore.doc(_configPath).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return LaunchConfig.fromJson(data);
      } else {
        return LaunchScenarios.publicReleaseScenario();
      }
    }).handleError((error) {
      print('RemoteConfigService.watchConfig error: $error');
      // エラー時はキャッシュまたはデフォルト値を返す
      if (_cachedConfig != null) {
        return _cachedConfig!;
      }
      return LaunchScenarios.publicReleaseScenario();
    });
  }

  /// 設定を更新（管理者用）
  Future<void> updateConfig(LaunchConfig newConfig) async {
    // 検証
    final errors = LaunchConfigValidator.validate(newConfig);
    if (errors.isNotEmpty) {
      throw Exception('設定の検証エラー: ${errors.join(', ')}');
    }

    try {
      await _firestore
          .doc(_configPath)
          .update(newConfig.toJson()..['lastUpdatedAt'] = FieldValue.serverTimestamp());

      // キャッシュを更新
      _cachedConfig = newConfig;
      _cacheTime = DateTime.now();
    } catch (e) {
      print('RemoteConfigService.updateConfig error: $e');
      rethrow;
    }
  }

  /// ステージを変更（管理者用）
  Future<void> setLaunchStage(LaunchStage stage) async {
    final currentConfig = await getConfig();

    final newConfig = currentConfig.copyWith(
      launchStage: stage,
      lastUpdatedAt: DateTime.now(),
    );

    await updateConfig(newConfig);
  }

  /// メンテナンスモードを有効化
  Future<void> enableMaintenance(String message) async {
    final maintenanceConfig = LaunchScenarios.maintenanceScenario(message);
    await updateConfig(maintenanceConfig);
  }

  /// メンテナンスモードを解除
  Future<void> disableMaintenance() async {
    final currentConfig = await getConfig();
    final newConfig = currentConfig.copyWith(
      maintenanceMode: false,
      maintenanceMessage: '',
    );
    await updateConfig(newConfig);
  }

  /// ローカルオーバーライドを設定（テスト用）
  void setLocalOverride(LaunchConfig? config) {
    _localOverride = config;
  }

  /// キャッシュをクリア
  void clearCache() {
    _cachedConfig = null;
    _cacheTime = null;
  }

  /// 設定のリセット（デフォルトに戻す）
  Future<void> resetToDefault() async {
    await updateConfig(LaunchScenarios.publicReleaseScenario());
  }

  /// ドキュメントを初期化（存在しない場合のみ）
  Future<void> _initializeDocument(LaunchConfig config) async {
    try {
      await _firestore.doc(_configPath).set({
        ...config.toJson(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('RemoteConfigService._initializeDocument error: $e');
    }
  }
}

/// 設定の統計情報を取得
extension LaunchConfigStats on RemoteConfigService {
  /// 推定メモリ使用量
  Future<double> getEstimatedMemoryMB() async {
    final config = await getConfig();
    return LaunchConfigStats.estimatedTotalMemory(config);
  }

  /// 推定 API 呼び出し数/日
  Future<int> getEstimatedDailyAPICalls() async {
    final config = await getConfig();
    return LaunchConfigStats.estimatedTotalAPICallsPerDay(config);
  }

  /// 推定ストレージ容量
  Future<double> getEstimatedStorageGB() async {
    final config = await getConfig();
    return LaunchConfigStats.estimatedStorageGB(config);
  }
}

/// 設定の検証と通知
extension LaunchConfigValidation on RemoteConfigService {
  /// 設定をログ出力（デバッグ用）
  Future<void> logConfig() async {
    final config = await getConfig();
    print('''
╔════════════════════════════════════════╗
║   Launch Configuration Status          ║
╚════════════════════════════════════════╝

Launch Enabled: ${config.launchEnabled}
Stage: ${config.launchStage.name}
Maintenance Mode: ${config.maintenanceMode}

Features:
  - Highlight Generation: ${config.highlightGenerationEnabled}
  - Highlight Sharing: ${config.highlightSharingEnabled}
  - Analytics: ${config.analyticsEnabled}

Limits:
  - Max Daily Games/User: ${config.maxDailyGames}
  - Max Monthly Users: ${config.maxMonthlyUsers}
  - Max Total Users: ${config.maxTotalUsers}

Last Updated: ${config.lastUpdatedAt}
    ''');
  }

  /// 設定の妥当性チェック
  Future<List<String>> validateCurrentConfig() async {
    final config = await getConfig();
    return LaunchConfigValidator.validate(config);
  }

  /// 設定が有効か
  Future<bool> isConfigValid() async {
    final config = await getConfig();
    return LaunchConfigValidator.isValid(config);
  }
}
