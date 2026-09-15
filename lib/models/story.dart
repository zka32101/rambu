/// 乱舞将棋の世界観・ストーリー・キャラクター設定

import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';
part 'story.g.dart';

/// オーディオトラック（BGM/SE）
@freezed
class AudioTrack with _$AudioTrack {
  const factory AudioTrack({
    required String id,
    required String title,
    required String assetPath,
    Duration? duration,
  }) = _AudioTrack;

  factory AudioTrack.fromJson(Map<String, dynamic> json) =>
      _$AudioTrackFromJson(json);
}

/// ゲームキャラクター
@freezed
class GameCharacter with _$GameCharacter {
  const factory GameCharacter({
    required String id,
    required String name,
    required String description,
    required String portraitImagePath,
    @Default([]) List<String> voiceLineUrls,
    String? backgroundStory,
  }) = _GameCharacter;

  factory GameCharacter.fromJson(Map<String, dynamic> json) =>
      _$GameCharacterFromJson(json);
}

/// ストーリーシーン
@freezed
class StoryScene with _$StoryScene {
  const factory StoryScene({
    required String id,
    required String title,
    required String narrative,          // ストーリーテキスト
    @Default([]) List<String> characterIds,
    String? backgroundImagePath,
    String? voiceActorVoiceUrl,         // ナレーションまたはキャラボイス
    required Duration displayDuration,
    required AudioTrack bgm,
    @Default(true) bool canSkip,        // スキップ可能か
  }) = _StoryScene;

  factory StoryScene.fromJson(Map<String, dynamic> json) =>
      _$StorySceneFromJson(json);
}

/// ゲーム世界観定義
class GameWorldLore {
  /// 世界観の背景設定
  static const String worldTitle = '乱舞将棋の世界';

  static const String worldDescription = '''
古の魔法が支配する舞台 - そこは「乱舞の盤」と呼ばれる戦場。

蒼涼王（そうりょうおう）の統治する「氷の城」と、
赤炎皇（あかほのおこう）の統治する「炎の城」が、
千年間にわたって対峙してきた。

この度、いよいよ両陣営が激突する時が来たのだ。
駒たちは命がけで戦い、HP（生命力）を削られながらも、
絶望的な局面から逆転を狙う——
それが「乱舞将棋」の本質である。
  ''';

  /// キャラクタープロフィール
  static final Map<String, GameCharacter> characterProfiles = {
    'sente_king': GameCharacter(
      id: 'sente_king',
      name: '蒼涼王（そうりょうおう）',
      description: '氷の城の統治者。冷徹な戦術と、鋭い洞察で戦場を支配する。',
      portraitImagePath: 'assets/characters/sente_king.png',
      backgroundStory: '''
かつて、蒼涼王は赤炎皇と兄弟であった。
しかし、魔法の支配権を巡る争いの末、袂を分かつこととなった。

今、王は完璧さを求め、一切の妥協を許さない。
その目には、勝利のみが映っている。
      ''',
    ),
    'gote_king': GameCharacter(
      id: 'gote_king',
      name: '赤炎皇（あかほのおこう）',
      description: '炎の城の統治者。情熱的で大胆な戦略で、あらゆる困難に立ち向かう。',
      portraitImagePath: 'assets/characters/gote_king.png',
      backgroundStory: '''
赤炎皇は、兄・蒼涼王とは違い、変化を好む。
不可能を可能にすることが、彼の喜びである。

その烈火のような戦闘精神は、多くの駒から慕われ、
絶望的な局面でも、決して諦めることがない。
      ''',
    ),
    'sente_rook': GameCharacter(
      id: 'sente_rook',
      name: '蒼翼戦士（そうよくせんし）',
      description: '先手の飛車。冷静沈着で、縦横無尽に戦場を翔ける。',
      portraitImagePath: 'assets/characters/sente_rook.png',
    ),
    'sente_bishop': GameCharacter(
      id: 'sente_bishop',
      name: '氷晶術士（ひょうしょうじゅつし）',
      description: '先手の角。魔法の力で遠距離から敵を氷漬けにする。',
      portraitImagePath: 'assets/characters/sente_bishop.png',
    ),
    'gote_rook': GameCharacter(
      id: 'gote_rook',
      name: '炎翼戦士（えんよくせんし）',
      description: '後手の飛車。炎のような情熱で戦場を駆け抜ける。',
      portraitImagePath: 'assets/characters/gote_rook.png',
    ),
    'gote_bishop': GameCharacter(
      id: 'gote_bishop',
      name: '焔雷術士（えんらいじゅつし）',
      description: '後手の角。爆烈な炎で敵を焼き尽くす。',
      portraitImagePath: 'assets/characters/gote_bishop.png',
    ),
  };

  /// チュートリアルストーリー
  static List<StoryScene> getTutorialStory() => [
    StoryScene(
      id: 'tutorial_opening',
      title: 'チュートリアル - 物語開幕',
      narrative: '''
蒼涼王の統治する「氷の城」と、
赤炎皇の統治する「炎の城」。

千年間にわたる対峙の時が、
いよいよ終わりを告げようとしていた——

「盤上での決着をつけよう」

蒼涼王がそう告げた瞬間、
天地は揺らぎ、「乱舞の盤」が出現した。
      ''',
      characterIds: ['sente_king', 'gote_king'],
      backgroundImagePath: 'assets/backgrounds/castle_clash.png',
      displayDuration: Duration(seconds: 8),
      bgm: AudioTrack(
        id: 'bgm_opening',
        title: 'Opening Theme',
        assetPath: 'assets/sounds/bgm_opening.mp3',
      ),
    ),
    StoryScene(
      id: 'tutorial_hp_system',
      title: 'チュートリアル - HP制の説明',
      narrative: '''
通常の将棋とは異なり、
ここでは駒に「生命力（HP）」が存在する。

駒が攻撃を受けるたびにHPは減少し、
HPが0になれば、その駒は永遠に盤上から消える。

さらに、角と飛車は「飛び道具」を持つ——
遠く離れた敵を攻撃することができるのだ。
      ''',
      backgroundImagePath: 'assets/backgrounds/hp_system.png',
      displayDuration: Duration(seconds: 10),
      bgm: AudioTrack(
        id: 'bgm_tutorial',
        title: 'Tutorial Theme',
        assetPath: 'assets/sounds/bgm_tutorial.mp3',
      ),
    ),
    StoryScene(
      id: 'tutorial_second_hand_bonus',
      title: 'チュートリアル - 後手のハンデ',
      narrative: '''
しかし、ここに工夫がある。

先手の権利を持つ者が常に有利では、
ゲームは面白くない。

そこで、後手には「初手直後のボーナス移動」が与えられた。

先手が一手目を打ったその直後、
後手は通常の着手の外に、
もう一度、追加で駒を動かすことができるのだ。

これにより、先後の力は均衡する——
これが「乱舞将棋」の真髄である。
      ''',
      backgroundImagePath: 'assets/backgrounds/bonus_move.png',
      displayDuration: Duration(seconds: 12),
      bgm: AudioTrack(
        id: 'bgm_tutorial',
        title: 'Tutorial Theme',
        assetPath: 'assets/sounds/bgm_tutorial.mp3',
      ),
    ),
    StoryScene(
      id: 'tutorial_start_game',
      title: 'チュートリアル - 対局開始',
      narrative: '''
さあ、舞台は整った。

「乱舞の盤」の上で、
王たちの駒が激突する時が来たのだ。

君は、どちらの王に仕えるか？

あるいは、自らが王となるか——

いずれにせよ、この戦場では、
絶望的な局面からの逆転が、
いつでも起こりうるのだ。

さあ、一局、指してみよう。
      ''',
      backgroundImagePath: 'assets/backgrounds/game_start.png',
      displayDuration: Duration(seconds: 10),
      bgm: AudioTrack(
        id: 'bgm_battle',
        title: 'Battle Theme',
        assetPath: 'assets/sounds/bgm_battle.mp3',
      ),
    ),
  ];

  /// ゲーム内イベント用ストーリーシーン
  static StoryScene getCriticalHitStory() => StoryScene(
    id: 'critical_hit_scene',
    title: '必殺技が炸裂！',
    narrative: '''
遠くから放たれた魔法の一撃が、
敵の重要な駒に命中した！

HP満タンだった敵駒が、
一撃で倒れていく——

これが「乱舞将棋」の醍醐味！
    ''',
    backgroundImagePath: 'assets/backgrounds/critical_hit.png',
    displayDuration: Duration(seconds: 3),
    bgm: AudioTrack(
      id: 'bgm_critical',
      title: 'Critical Hit Theme',
      assetPath: 'assets/sounds/bgm_critical.mp3',
    ),
    canSkip: false,
  );

  /// 対局勝利時のストーリー
  static StoryScene getVictoryStory(String playerName, String difficulty) =>
      StoryScene(
        id: 'victory_scene_$difficulty',
        title: '栄光の瞬間',
        narrative: '''
$playerName よ！

君の洞察力と、大胆な決断が、
この戦場で勝利をもたらした。

王はその勇気を称える——

さあ、次なる戦場で、
また一局、差してみないか？
        ''',
        backgroundImagePath: 'assets/backgrounds/victory.png',
        displayDuration: Duration(seconds: 6),
        bgm: AudioTrack(
          id: 'bgm_victory',
          title: 'Victory Theme',
          assetPath: 'assets/sounds/bgm_victory.mp3',
        ),
      );
}
