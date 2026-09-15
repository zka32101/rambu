/// Story Service
/// ゲーム世界の物語・ナレーティブ管理
///
/// 機能:
/// - ストーリー シーン管理
/// - キャラクター プロフィール管理
/// - ゲームイベント連携
/// - ナレーティブ フロー制御

import 'package:rambu_shogi/models/story.dart';

/// ストーリー進行状態
enum StoryProgression {
  notStarted,     // 未開始
  inProgress,     // 進行中
  completed,      // 完了
  paused,         // 一時停止
}

/// ストーリー エピソード
class StoryEpisode {
  /// エピソード ID
  final String id;

  /// エピソード タイトル
  final String title;

  /// エピソード 説明
  final String description;

  /// シーンリスト
  final List<GameCharacter> characters;

  /// 背景イメージ
  final String? backgroundImagePath;

  /// 関連ゲーム イベント
  final List<String> relatedEvents;

  /// エピソード完了条件
  final String completionCondition;

  StoryEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.characters,
    this.backgroundImagePath,
    required this.relatedEvents,
    required this.completionCondition,
  });
}

/// ストーリー キャラクター ナレーティブ
class CharacterNarrative {
  /// キャラクター ID
  final String characterId;

  /// キャラクター名
  final String characterName;

  /// 物語上の役割
  final String role;  // 主人公, 敵, 相棒, etc.

  /// キャラクター背景
  final String background;

  /// 目的・動機
  final String motivation;

  /// キャラクターの変化（ストーリー進行での成長）
  final List<String> characterArc;

  CharacterNarrative({
    required this.characterId,
    required this.characterName,
    required this.role,
    required this.background,
    required this.motivation,
    required this.characterArc,
  });
}

/// ストーリー マイルストーン
class StoryMilestone {
  /// マイルストーン ID
  final String id;

  /// マイルストーン 名
  final String name;

  /// 説明
  final String description;

  /// 達成条件
  final String achievementCondition;

  /// 報酬
  final Map<String, dynamic> rewards;

  /// ストーリー進行への影響
  final double narrativeImpact;

  StoryMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.achievementCondition,
    required this.rewards,
    required this.narrativeImpact,
  });
}

/// ストーリー トリガー
class StoryTrigger {
  /// トリガー ID
  final String id;

  /// トリガー条件
  final String condition;

  /// トリガー時のアクション
  final String action;

  /// 関連シーン
  final String? relatedSceneId;

  /// 実行済みフラグ
  bool isExecuted;

  StoryTrigger({
    required this.id,
    required this.condition,
    required this.action,
    this.relatedSceneId,
    this.isExecuted = false,
  });
}

/// ストーリー サービス
class StoryService {
  /// ストーリー シーン マップ
  final Map<String, GameCharacter> _characters = {};

  /// エピソード マップ
  final Map<String, StoryEpisode> _episodes = {};

  /// マイルストーン マップ
  final Map<String, StoryMilestone> _milestones = {};

  /// トリガー リスト
  final List<StoryTrigger> _triggers = [];

  /// 現在のストーリー進行状態
  StoryProgression _progression = StoryProgression.notStarted;

  /// 完了した マイルストーン
  final Set<String> _completedMilestones = {};

  /// ストーリー開始時刻
  DateTime? _startTime;

  /// キャラクター ナレーティブ
  final Map<String, CharacterNarrative> _characterNarratives = {};

  /// ゲーム世界設定
  final GameWorldLore worldLore = GameWorldLore.instance;

  /// 初期化
  void initialize() {
    _progression = StoryProgression.notStarted;
    _completedMilestones.clear();
    _loadDefaultStories();
  }

  /// デフォルト ストーリーを読み込み
  void _loadDefaultStories() {
    // チュートリアル ストーリー
    _loadTutorialStory();

    // 勝利 ストーリー
    _loadVictoryStory();

    // キャラクター ナレーティブ
    _loadCharacterNarratives();
  }

  /// チュートリアル ストーリーを読み込み
  void _loadTutorialStory() {
    final scenes = worldLore.getTutorialStory();

    for (int i = 0; i < scenes.length; i++) {
      final scene = scenes[i];
      // シーン情報をストレージに保存
      // 実装は省略（UI側で使用）
    }
  }

  /// 勝利 ストーリーを読み込み
  void _loadVictoryStory() {
    final scenes = worldLore.getVictoryStory();

    for (int i = 0; i < scenes.length; i++) {
      final scene = scenes[i];
      // シーン情報をストレージに保存
      // 実装は省略（UI側で使用）
    }
  }

  /// キャラクター ナレーティブを読み込み
  void _loadCharacterNarratives() {
    // 蒼涼王（先手の王）
    _characterNarratives['sente_king'] = CharacterNarrative(
      characterId: 'sente_king',
      characterName: '蒼涼王',
      role: '主人公',
      background: '古来より乱舞将棋の世界を統治する王。'
          '無限の戦いの中で、新しい未来を求めている。',
      motivation: '後手の皇帝との最終決戦に勝利し、'
          '新しい時代を切り開くこと',
      characterArc: [
        '初期: 苦悩の中で戦いを続ける',
        '中盤: 民の期待に応えるため覚悟を決める',
        '終盤: 究極の力を目覚めさせる',
        '完結: 新世代への希望を託す',
      ],
    );

    // 赤炎皇（後手の王）
    _characterNarratives['gote_king'] = CharacterNarrative(
      characterId: 'gote_king',
      characterName: '赤炎皇',
      role: '敵',
      background: '永遠の闇の中から現れた皇帝。'
          '蒼涼王の対極として存在する。',
      motivation: '乱舞将棋の世界を完全に支配し、'
          '永遠の秩序を築くこと',
      characterArc: [
        '初期: 絶対的な力で支配を広げる',
        '中盤: 蒼涼王の抵抗に驚愕する',
        '終盤: 最後の切り札を使う',
        '完結: 運命の決別',
      ],
    );

    // 金の将（相棒キャラ）
    _characterNarratives['gold_ally'] = CharacterNarrative(
      characterId: 'gold_ally',
      characterName: '黄金の将',
      role: '相棒',
      background: '蒼涼王を支える古い将軍。'
          '幾度もの戦いを見てきた知恵者。',
      motivation: '蒼涼王を守り、次世代へ平和を託すこと',
      characterArc: [
        '初期: 若き王を導く',
        '中盤: 自らの限界を知る',
        '終盤: 最後の力を尽くす',
        '完結: 使命を全うする',
      ],
    );
  }

  /// ストーリーを開始
  void startStory() {
    _progression = StoryProgression.inProgress;
    _startTime = DateTime.now();
  }

  /// ストーリーを一時停止
  void pauseStory() {
    _progression = StoryProgression.paused;
  }

  /// ストーリーを再開
  void resumeStory() {
    if (_progression == StoryProgression.paused) {
      _progression = StoryProgression.inProgress;
    }
  }

  /// ストーリーを完了
  void completeStory() {
    _progression = StoryProgression.completed;
  }

  /// マイルストーンを完了
  void completeMilestone(String milestoneId) {
    _completedMilestones.add(milestoneId);
  }

  /// マイルストーン完了を確認
  bool isMilestoneCompleted(String milestoneId) {
    return _completedMilestones.contains(milestoneId);
  }

  /// トリガーを確認・実行
  void checkTriggers(String condition) {
    for (final trigger in _triggers) {
      if (!trigger.isExecuted && trigger.condition == condition) {
        trigger.isExecuted = true;
        _executeTrigger(trigger);
      }
    }
  }

  /// トリガーを実行
  void _executeTrigger(StoryTrigger trigger) {
    // トリガー実行ロジック
    print('Story Trigger Executed: ${trigger.action}');
  }

  /// キャラクター ナレーティブを取得
  CharacterNarrative? getCharacterNarrative(String characterId) {
    return _characterNarratives[characterId];
  }

  /// 全キャラクター ナレーティブを取得
  Iterable<CharacterNarrative> getAllCharacterNarratives() {
    return _characterNarratives.values;
  }

  /// ストーリー進行状態を取得
  StoryProgression get progression => _progression;

  /// ストーリー開始からの経過時間（秒）
  int? get elapsedSeconds {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  /// 完了マイルストーン数
  int get completedMilestoneCount => _completedMilestones.length;

  /// JSON形式で出力
  Map<String, dynamic> toJson() => {
    'progression': _progression.toString(),
    'completed_milestones': _completedMilestones.toList(),
    'elapsed_seconds': elapsedSeconds,
    'characters': _characterNarratives.keys.toList(),
  };

  /// デバッグ情報を出力
  void debugPrint() {
    print('=== Story Service Debug ===');
    print('Progression: $_progression');
    print('Completed Milestones: ${_completedMilestones.length}');
    print('Characters: ${_characterNarratives.length}');
    print('Elapsed: ${elapsedSeconds}s');
  }
}

/// ストーリー マネージャー（Singleton）
class StoryManager {
  static final StoryManager _instance = StoryManager._internal();

  late StoryService _service;

  StoryManager._internal();

  factory StoryManager() {
    return _instance;
  }

  /// 初期化
  void initialize() {
    _service = StoryService();
    _service.initialize();
  }

  /// サービスを取得
  StoryService get service => _service;

  /// ストーリーを開始
  void startStory() => _service.startStory();

  /// ストーリーを完了
  void completeStory() => _service.completeStory();

  /// マイルストーンを完了
  void completeMilestone(String id) => _service.completeMilestone(id);

  /// キャラクター ナレーティブを取得
  CharacterNarrative? getCharacterNarrative(String id) =>
      _service.getCharacterNarrative(id);

  /// 進行状態を取得
  StoryProgression get progression => _service.progression;
}

/// ストーリー イベント リスナー
abstract class StoryEventListener {
  void onStoryStarted();
  void onStoryCompleted();
  void onMilestoneCompleted(String milestoneId);
  void onCharacterArcProgressed(String characterId);
  void onTriggerExecuted(String triggerId);
}

/// ストーリー イベント マネージャー
class StoryEventManager {
  static final StoryEventManager _instance = StoryEventManager._internal();

  final List<StoryEventListener> _listeners = [];

  StoryEventManager._internal();

  factory StoryEventManager() {
    return _instance;
  }

  /// リスナーを登録
  void addListener(StoryEventListener listener) {
    _listeners.add(listener);
  }

  /// リスナーを削除
  void removeListener(StoryEventListener listener) {
    _listeners.remove(listener);
  }

  /// ストーリー開始イベントを発火
  void notifyStoryStarted() {
    for (final listener in _listeners) {
      listener.onStoryStarted();
    }
  }

  /// ストーリー完了イベントを発火
  void notifyStoryCompleted() {
    for (final listener in _listeners) {
      listener.onStoryCompleted();
    }
  }

  /// マイルストーン完了イベントを発火
  void notifyMilestoneCompleted(String milestoneId) {
    for (final listener in _listeners) {
      listener.onMilestoneCompleted(milestoneId);
    }
  }

  /// キャラクター成長イベントを発火
  void notifyCharacterArcProgressed(String characterId) {
    for (final listener in _listeners) {
      listener.onCharacterArcProgressed(characterId);
    }
  }

  /// トリガー実行イベントを発火
  void notifyTriggerExecuted(String triggerId) {
    for (final listener in _listeners) {
      listener.onTriggerExecuted(triggerId);
    }
  }
}
