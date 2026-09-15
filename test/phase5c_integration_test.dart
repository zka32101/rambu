/// Phase 5C Integration Tests
/// 世界観・UI・オーディオ統合テスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/services/story_service.dart';
import 'package:rambu_shogi/services/audio_manager.dart';
import 'package:rambu_shogi/services/theme_manager.dart';
import 'package:rambu_shogi/models/story.dart';

void main() {
  group('Story + Audio Integration Tests', () {
    late StoryManager storyManager;
    late AudioManagerService audioManager;

    setUp(() async {
      storyManager = StoryManager();
      audioManager = AudioManagerService();
      storyManager.initialize();
      await audioManager.initialize();
    });

    test('should initialize story and audio together', () {
      expect(storyManager.progression, equals(StoryProgression.notStarted));
      expect(audioManager.manager.getMasterVolume(), equals(1.0));
    });

    test('should start story and play BGM', () async {
      storyManager.startStory();
      expect(storyManager.progression, equals(StoryProgression.inProgress));

      final testBGM = AudioTrack(
        name: 'game_start_bgm',
        filePath: 'assets/audio/bgm/game_start.mp3',
        duration: 60,
      );
      await audioManager.playBGM(testBGM);

      expect(
        audioManager.manager.getPlayingTrack(AudioChannel.bgm),
        isNotNull,
      );
    });

    test('should stop audio when story completes', () async {
      storyManager.startStory();
      final testBGM = AudioTrack(
        name: 'test_bgm',
        filePath: 'assets/audio/bgm/test.mp3',
        duration: 60,
      );
      await audioManager.playBGM(testBGM);

      storyManager.completeStory();
      await audioManager.stopBGM();

      expect(
        audioManager.manager.getPlayingTrack(AudioChannel.bgm),
        isNull,
      );
    });
  });

  group('Theme + Story Integration Tests', () {
    late ThemeManager themeManager;
    late StoryManager storyManager;

    setUp(() {
      themeManager = ThemeManager();
      storyManager = StoryManager();
      themeManager.initialize();
      storyManager.initialize();
    });

    test('should apply theme when story starts', () {
      themeManager.setThemeMode(ThemeMode.dark);
      storyManager.startStory();

      expect(themeManager.currentTheme.themeName, equals('Dark'));
      expect(storyManager.progression, equals(StoryProgression.inProgress));
    });

    test('should switch theme during gameplay', () {
      themeManager.setThemeMode(ThemeMode.dark);
      expect(themeManager.currentTheme.themeName, equals('Dark'));

      themeManager.setThemeMode(ThemeMode.light);
      expect(themeManager.currentTheme.themeName, equals('Light'));
    });

    test('should have consistent colors across theme', () {
      themeManager.initialize();

      final darkColors = themeManager.colors;
      expect(darkColors.primary, equals(GameColorPalette.primary));
      expect(darkColors.accent, equals(GameColorPalette.accent));
    });
  });

  group('Full Integration Tests', () {
    late StoryManager storyManager;
    late AudioManagerService audioManager;
    late ThemeManager themeManager;

    setUp(() async {
      storyManager = StoryManager();
      audioManager = AudioManagerService();
      themeManager = ThemeManager();

      storyManager.initialize();
      await audioManager.initialize();
      themeManager.initialize();
    });

    test('should manage game start sequence', () async {
      // 1. Initialize systems
      expect(storyManager.progression, equals(StoryProgression.notStarted));
      expect(themeManager.currentTheme, isNotNull);

      // 2. Start story
      storyManager.startStory();
      expect(storyManager.progression, equals(StoryProgression.inProgress));

      // 3. Play intro music
      final introBGM = AudioTrack(
        name: 'intro',
        filePath: 'assets/audio/bgm/intro.mp3',
        duration: 30,
      );
      await audioManager.playBGM(introBGM);
      expect(
        audioManager.manager.getPlayingTrack(AudioChannel.bgm),
        isNotNull,
      );

      // 4. Complete milestone
      storyManager.completeMilestone('game_started');
      expect(storyManager.service.isMilestoneCompleted('game_started'), isTrue);
    });

    test('should manage victory sequence', () async {
      // 1. Setup game state
      storyManager.startStory();
      themeManager.setThemeMode(ThemeMode.dark);

      // 2. Complete game milestones
      storyManager.completeMilestone('reached_final_battle');
      storyManager.completeMilestone('defeated_final_boss');

      // 3. Play victory music
      final victoryBGM = AudioTrack(
        name: 'victory',
        filePath: 'assets/audio/bgm/victory.mp3',
        duration: 45,
      );
      await audioManager.playBGM(victoryBGM);

      // 4. Complete story
      storyManager.completeStory();

      expect(storyManager.progression, equals(StoryProgression.completed));
      expect(storyManager.service.completedMilestoneCount, equals(2));
    });

    test('should manage defeat sequence', () async {
      storyManager.startStory();
      themeManager.setThemeMode(ThemeMode.dark);

      storyManager.completeMilestone('game_over');

      final defeatBGM = AudioTrack(
        name: 'defeat',
        filePath: 'assets/audio/bgm/defeat.mp3',
        duration: 30,
      );
      await audioManager.playBGM(defeatBGM);

      storyManager.completeStory();

      expect(storyManager.progression, equals(StoryProgression.completed));
      expect(storyManager.service.isMilestoneCompleted('game_over'), isTrue);
    });

    test('should pause and resume all systems', () async {
      storyManager.startStory();

      final bgm = AudioTrack(
        name: 'gameplay',
        filePath: 'assets/audio/bgm/gameplay.mp3',
        duration: 120,
      );
      await audioManager.playBGM(bgm);

      // Pause story
      storyManager.service.pauseStory();
      expect(
        storyManager.service.progression,
        equals(StoryProgression.paused),
      );

      // Resume story
      storyManager.service.resumeStory();
      expect(
        storyManager.service.progression,
        equals(StoryProgression.inProgress),
      );
    });

    test('should manage audio volume during story', () {
      storyManager.startStory();

      // Set different volumes for different channels
      audioManager.setVolume(AudioChannel.bgm, 0.7);
      audioManager.setVolume(AudioChannel.se, 0.8);
      audioManager.setVolume(AudioChannel.voice, 0.9);

      expect(audioManager.manager.getChannelVolume(AudioChannel.bgm), equals(0.7));
      expect(audioManager.manager.getChannelVolume(AudioChannel.se), equals(0.8));
      expect(audioManager.manager.getChannelVolume(AudioChannel.voice), equals(0.9));

      // Adjust master volume
      audioManager.setMasterVolume(0.5);
      expect(audioManager.manager.getMasterVolume(), equals(0.5));
    });
  });

  group('Story Character Integration Tests', () {
    late StoryManager storyManager;

    setUp(() {
      storyManager = StoryManager();
      storyManager.initialize();
    });

    test('should provide character information', () {
      final sentKing = storyManager.getCharacterNarrative('sente_king');
      expect(sentKing, isNotNull);
      expect(sentKing!.characterName, equals('蒼涼王'));

      final goteKing = storyManager.getCharacterNarrative('gote_king');
      expect(goteKing, isNotNull);
      expect(goteKing!.role, equals('敵'));

      final ally = storyManager.getCharacterNarrative('gold_ally');
      expect(ally, isNotNull);
      expect(ally!.role, equals('相棒'));
    });

    test('should track all main characters', () {
      final chars = storyManager.service.getAllCharacterNarratives();
      expect(chars.length, greaterThanOrEqualTo(3));
    });
  });

  group('System Performance Tests', () {
    test('story + audio + theme initialization should be fast', () {
      final stopwatch = Stopwatch()..start();

      final storyManager = StoryManager();
      storyManager.initialize();

      final audioManager = AudioManagerService();
      final themeManager = ThemeManager();
      themeManager.initialize();

      stopwatch.stop();

      // All systems should initialize in < 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('concurrent milestone tracking should be efficient', () {
      final storyManager = StoryManager();
      storyManager.initialize();
      storyManager.startStory();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        storyManager.completeMilestone('milestone_$i');
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
