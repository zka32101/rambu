/// Narrative Screen
/// ストーリーシーン表示画面
///
/// 機能:
/// - キャラクター表示
/// - ナレーション・台詞表示
/// - シーン遷移
/// - インタラクティブな選択肢

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/story.dart';
import 'package:rambu_shogi/services/story_service.dart';

/// ナレーティブ スクリーン プロバイダー
final narrativeScreenProvider =
    StateNotifierProvider<NarrativeScreenNotifier, NarrativeScreenState>((ref) {
  return NarrativeScreenNotifier();
});

/// ナレーティブ スクリーン 状態
class NarrativeScreenState {
  /// 現在のシーン
  final GameCharacter? currentCharacter;

  /// シーンナレーション
  final String? narration;

  /// キャラクター台詞
  final String? dialogue;

  /// シーン背景
  final String? backgroundImage;

  /// 選択肢リスト
  final List<String> choices;

  /// シーン進行度（0-1）
  final double sceneProgress;

  /// ナレーション表示中フラグ
  final bool isNarrationDisplaying;

  /// 台詞表示中フラグ
  final bool isDialogueDisplaying;

  /// ストーリー進行状態
  final StoryProgression storyProgression;

  NarrativeScreenState({
    this.currentCharacter,
    this.narration,
    this.dialogue,
    this.backgroundImage,
    this.choices = const [],
    this.sceneProgress = 0.0,
    this.isNarrationDisplaying = false,
    this.isDialogueDisplaying = false,
    this.storyProgression = StoryProgression.notStarted,
  });

  NarrativeScreenState copyWith({
    GameCharacter? currentCharacter,
    String? narration,
    String? dialogue,
    String? backgroundImage,
    List<String>? choices,
    double? sceneProgress,
    bool? isNarrationDisplaying,
    bool? isDialogueDisplaying,
    StoryProgression? storyProgression,
  }) {
    return NarrativeScreenState(
      currentCharacter: currentCharacter ?? this.currentCharacter,
      narration: narration,
      dialogue: dialogue,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      choices: choices ?? this.choices,
      sceneProgress: sceneProgress ?? this.sceneProgress,
      isNarrationDisplaying: isNarrationDisplaying ?? this.isNarrationDisplaying,
      isDialogueDisplaying: isDialogueDisplaying ?? this.isDialogueDisplaying,
      storyProgression: storyProgression ?? this.storyProgression,
    );
  }
}

/// ナレーティブ スクリーン ノーティファイア
class NarrativeScreenNotifier extends StateNotifier<NarrativeScreenState> {
  late StoryService _storyService;

  NarrativeScreenNotifier() : super(NarrativeScreenState());

  /// 初期化
  void initialize() {
    final manager = StoryManager();
    manager.initialize();
    _storyService = manager.service;

    _storyService.startStory();
    state = state.copyWith(
      storyProgression: _storyService.progression,
    );
  }

  /// シーンを表示
  void displayScene(GameCharacter character, String narration) {
    state = state.copyWith(
      currentCharacter: character,
      narration: narration,
      isNarrationDisplaying: true,
    );
  }

  /// 台詞を表示
  void displayDialogue(String dialogue) {
    state = state.copyWith(
      dialogue: dialogue,
      isDialogueDisplaying: true,
    );
  }

  /// シーン進行を更新
  void updateSceneProgress(double progress) {
    state = state.copyWith(sceneProgress: progress);
  }

  /// 次のシーンに進む
  void nextScene() {
    state = state.copyWith(
      narration: null,
      dialogue: null,
      isNarrationDisplaying: false,
      isDialogueDisplaying: false,
    );
  }

  /// マイルストーンを完了
  void completeMilestone(String milestoneId) {
    _storyService.completeMilestone(milestoneId);
  }

  /// ストーリーを完了
  void completeStory() {
    _storyService.completeStory();
    state = state.copyWith(
      storyProgression: _storyService.progression,
    );
  }

  /// キャラクター情報を取得
  CharacterNarrative? getCharacterInfo(String characterId) {
    return _storyService.getCharacterNarrative(characterId);
  }
}

/// ナレーティブ スクリーン
class NarrativeScreen extends ConsumerWidget {
  final GameCharacter initialCharacter;
  final List<GameCharacter> scenes;

  const NarrativeScreen({
    required this.initialCharacter,
    required this.scenes,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(narrativeScreenProvider);
    final screenNotifier = ref.watch(narrativeScreenProvider.notifier);

    // 初期化
    ref.listen(narrativeScreenProvider, (previous, next) {
      if (screenState.storyProgression == StoryProgression.notStarted) {
        screenNotifier.initialize();
        screenNotifier.displayScene(initialCharacter, 'ゲーム開始...');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          _buildBackground(screenState),

          // コンテンツ
          Column(
            children: [
              // キャラクター表示エリア
              Expanded(
                flex: 2,
                child: _buildCharacterArea(screenState),
              ),

              // ナレーション・台詞表示エリア
              Expanded(
                flex: 1,
                child: _buildNarrationArea(context, screenState, screenNotifier),
              ),
            ],
          ),

          // 進行インジケーター
          Positioned(
            top: 16,
            left: 16,
            child: _buildProgressIndicator(screenState),
          ),

          // スキップボタン
          Positioned(
            top: 16,
            right: 16,
            child: _buildSkipButton(context, screenNotifier),
          ),
        ],
      ),
    );
  }

  /// 背景を構築
  Widget _buildBackground(NarrativeScreenState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple[900]!,
            Colors.indigo[800]!,
            Colors.blue[900]!,
          ],
        ),
      ),
      child: state.backgroundImage != null
          ? Image.asset(
              state.backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            )
          : const SizedBox.expand(),
    );
  }

  /// キャラクター表示エリアを構築
  Widget _buildCharacterArea(NarrativeScreenState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: state.currentCharacter != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // キャラクター名
                Text(
                  state.currentCharacter!.portraitImagePath ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // キャラクター表示（イメージプレースホルダー）
                Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 120,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  /// ナレーション・台詞表示エリアを構築
  Widget _buildNarrationArea(
    BuildContext context,
    NarrativeScreenState state,
    NarrativeScreenNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ナレーション
          if (state.narration != null)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  state.narration!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),

          // 台詞
          if (state.dialogue != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.dialogue!,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // 次へボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => notifier.nextScene(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '次へ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 進行インジケーターを構築
  Widget _buildProgressIndicator(NarrativeScreenState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: state.sceneProgress,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(state.sceneProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// スキップボタンを構築
  Widget _buildSkipButton(
    BuildContext context,
    NarrativeScreenNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close),
        color: Colors.white70,
        onPressed: () {
          notifier.completeStory();
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// ナレーティブ スクリーン ビルダー
class NarrativeScreenBuilder {
  /// ゲーム開始時のナレーション画面を構築
  static NarrativeScreen buildGameStartNarrative() {
    return NarrativeScreen(
      initialCharacter: GameCharacter(
        id: 'narrator',
        name: 'ナレーター',
        description: 'ゲーム世界のナレーター',
        portraitImagePath: 'assets/images/characters/narrator.png',
        voiceLineUrls: [],
      ),
      scenes: [],
    );
  }

  /// 勝利時のナレーション画面を構築
  static NarrativeScreen buildVictoryNarrative() {
    return NarrativeScreen(
      initialCharacter: GameCharacter(
        id: 'sente_king',
        name: '蒼涼王',
        description: '勝利を手にした王',
        portraitImagePath: 'assets/images/characters/sente_king_victory.png',
        voiceLineUrls: [],
      ),
      scenes: [],
    );
  }

  /// 敗北時のナレーション画面を構築
  static NarrativeScreen buildDefeatNarrative() {
    return NarrativeScreen(
      initialCharacter: GameCharacter(
        id: 'gote_king',
        name: '赤炎皇',
        description: '勝利を確実にした皇帝',
        portraitImagePath: 'assets/images/characters/gote_king_victory.png',
        voiceLineUrls: [],
      ),
      scenes: [],
    );
  }
}
