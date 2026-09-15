/// シェアリンク生成サービス
/// Bitly API + Firebase Dynamic Links (Fallback)

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

/// シェアリンク生成結果
class ShareLinkResult {
  final String originalUrl;       // 元のビデオURL
  final String shortUrl;          // 短縮URL
  final String method;            // 生成方法: 'bitly' or 'dynamicLinks'
  final DateTime createdAt;

  ShareLinkResult({
    required this.originalUrl,
    required this.shortUrl,
    required this.method,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String toString() => 'ShareLinkResult(method=$method, shortUrl=$shortUrl)';
}

/// シェアリンク生成サービス
/// Bitly API で短縮URL生成、失敗時は Firebase Dynamic Links 使用
class ShareLinkService {
  // Bitly API設定
  static const String bitlyApiUrl = 'https://api-ssl.bitly.com/v4/shorten';
  static const String bitlyDomain = 'bit.ly';

  // Firebase Dynamic Links設定
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;
  final String _dynamicLinkDomain = 'rambu.page.link';  // Firebase プロジェクト依存

  // Bitly API キー（環境変数から取得）
  // 実装時: dotenv または Cloud Functions の環境変数から
  late final String _bitlyApiKey;

  ShareLinkService({String? bitlyApiKey}) {
    _bitlyApiKey = bitlyApiKey ?? _getBitlyApiKeyFromEnv();
  }

  /// 共有リンクを生成
  ///
  /// [videoUrl]: ビデオダウンロードURL
  /// [sessionId]: ゲームセッションID
  /// [eventType]: イベント種類
  /// Returns: シェアリンク結果
  ///
  /// 優先度:
  /// 1. Bitly API で短縮 (最優先)
  /// 2. Firebase Dynamic Links (Fallback)
  /// 3. 元のURL (最終 Fallback)
  Future<ShareLinkResult> generateShareLink({
    required String videoUrl,
    required String sessionId,
    required String eventType,
  }) async {
    // Bitly で試す
    try {
      final shortUrl = await shortenWithBitly(videoUrl);
      return ShareLinkResult(
        originalUrl: videoUrl,
        shortUrl: shortUrl,
        method: 'bitly',
      );
    } catch (e) {
      print('Warning: Bitly shortening failed: $e, trying Dynamic Links...');
    }

    // Firebase Dynamic Links で試す
    try {
      final shortUrl = await createDynamicLink(
        videoUrl: videoUrl,
        sessionId: sessionId,
        eventType: eventType,
      );
      return ShareLinkResult(
        originalUrl: videoUrl,
        shortUrl: shortUrl,
        method: 'dynamicLinks',
      );
    } catch (e) {
      print('Warning: Dynamic Links creation failed: $e, using original URL');
    }

    // 最終 Fallback: 元の URL を返す
    return ShareLinkResult(
      originalUrl: videoUrl,
      shortUrl: videoUrl,
      method: 'fallback',
    );
  }

  /// Bitly API で短縮URL生成
  ///
  /// [longUrl]: 長いURL
  /// Returns: 短縮URL
  ///
  /// API リクエスト形式:
  /// ```json
  /// {
  ///   "long_url": "https://...",
  ///   "domain": "bit.ly"
  /// }
  /// ```
  Future<String> shortenWithBitly(String longUrl) async {
    if (_bitlyApiKey.isEmpty) {
      throw ShareLinkException('Bitly API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse(bitlyApiUrl),
        headers: {
          'Authorization': 'Bearer $_bitlyApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'long_url': longUrl,
          'domain': bitlyDomain,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ShareLinkException('Bitly API request timed out'),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ShareLinkException(
          'Bitly API error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final shortUrl = data['link'] as String?;

      if (shortUrl == null) {
        throw ShareLinkException('Bitly response missing "link" field');
      }

      return shortUrl;
    } on ShareLinkException {
      rethrow;
    } catch (e) {
      throw ShareLinkException('Failed to shorten URL with Bitly: $e');
    }
  }

  /// Firebase Dynamic Links で短縮リンク生成
  ///
  /// [videoUrl]: ビデオURL
  /// [sessionId]: セッションID
  /// [eventType]: イベント種類
  /// Returns: 短縮リンク
  Future<String> createDynamicLink({
    required String videoUrl,
    required String sessionId,
    required String eventType,
  }) async {
    try {
      final dynamicLinkParams = DynamicLinkParameters(
        link: Uri.parse('$_dynamicLinkDomain/highlight?url=$videoUrl&sessionId=$sessionId'),
        uriPrefix: 'https://$_dynamicLinkDomain',
        androidParameters: const AndroidParameters(
          packageName: 'com.example.rambu_shogi',
        ),
        iosParameters: const IOSParameters(
          bundleId: 'com.example.rambushogi',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'ハイライト動画',
          description: '乱舞将棋のクリティカルハイライト',
          imageUrl: Uri.parse('https://example.com/highlight_icon.png'),
        ),
      );

      final shortLink = await _dynamicLinks.buildShortLink(dynamicLinkParams);

      return shortLink.shortUrl.toString();
    } catch (e) {
      throw ShareLinkException('Failed to create Dynamic Link: $e');
    }
  }

  /// 環境変数から Bitly API キーを取得
  String _getBitlyApiKeyFromEnv() {
    // 実装時: 以下から取得
    // 1. 環境変数 BITLY_API_KEY
    // 2. Cloud Functions 環境変数
    // 3. .env ファイル

    // スタブ実装
    return const String.fromEnvironment('BITLY_API_KEY', defaultValue: '');
  }
}

/// シェアリンク例外
class ShareLinkException implements Exception {
  final String message;

  ShareLinkException(this.message);

  @override
  String toString() => 'ShareLinkException: $message';
}
