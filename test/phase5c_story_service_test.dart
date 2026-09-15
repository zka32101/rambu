/// Story Service Tests
/// ストーリー・ナレーティブ機能のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/services/story_service.dart';
import 'package:rambu_shogi/models/story.dart';

void main() {
  group('Story Progression Enum Tests', () {
    test('should have all progression states', () {
      expect(StoryProgression.values.length, equals(4));
      expect(StoryProgression.values, contains(StoryProgression.notStarted));
      expect(StoryProgression.values, contains(StoryProgression.inProgress));
      expect(StoryProgression.values, contains(StoryProgression.completed));
      expect(StoryProgression.values, contains(StoryProgression.paused));
    });
  });

  group('Story Milestone Tests', () {
    test('should create story milestone', () {
      final milestone = StoryMilestone(
        id: 'milestone_001',
        name: '初戦勝利',
        description: '最初の敵に勝利する',
        achievementCondition: 'player_wins == 1',
        rewards: {
          'gold': 100,
          'experience': 50,
        },
        narrativeImpact: 0.1,
      );

      expect(milestone.id, equals('milestone_001'));
      expect(milestone.name, equals('初戦勝利'));
      expect(milestone.rewards['gold'], equals(100));
      expect(milestone.narrativeImpact, equals(0.1));
    });

    test('should store milestone rewards', () {
      final milestone = StoryMilestone(
        id: 'milestone_001',
        name: 'Test',
        description: 'Test milestone',
        achievementCondition: 'test_condition',
        rewards: {
          'gold': 500,
          'item': 'legendary_sword',
        },
        narrativeImpact: 0.5,
      );

      expect(milestone.rewards['gold'], equals(500));
      expect(milestone.rewards['item'], equals('legendary_sword'));
    });
  });

  group('Story Trigger Tests', () {
    test('should create story trigger', () {
      final trigger = StoryTrigger(
        id: 'trigger_001',
        condition: 'player_hp_low',
        action: 'show_rescue_scene',
        relatedSceneId: 'scene_001',
      );

      expect(trigger.id, equals('trigger_001'));
      expect(trigger.condition, equals('player_hp_low'));
      expect(trigger.action, equals('show_rescue_scene'));
      expect(trigger.isExecuted, isFalse);
    });

    test('should track trigger execution', () {
      final trigger = StoryTrigger(
        id: 'trigger_001',
        condition: 'test_condition',
        action: 'test_action',
      );

      expect(trigger.isExecuted, isFalse);
      trigger.isExecuted = true;
      expect(trigger.isExecuted, isTrue);
    });
  });

  group('Character Narrative Tests', () {
    test('should create character narrative', () {
      final narrative = CharacterNarrative(
        characterId: 'sente_king',
        characterName: '蒼涼王',
        role: '主人公',
        background: 'テスト用背景',
        motivation: 'テスト用動機',
        characterArc: ['段階1', '段階2', '段階3'],
      );

      expect(narrative.characterId, equals('sente_king'));
      expect(narrative.characterName, equals('蒼涼王'));
      expect(narrative.role, equals('主人公'));
      expect(narrative.characterArc.length, equals(3));
    });

    test('should store character arc', () {
      final arc = ['初期状態', '成長段階', '最終形態'];
      final narrative = CharacterNarrative(
        characterId: 'test',
        characterName: 'Test Character',
        role: '主人公',
        background: 'background',
        motivation: 'motivation',
        characterArc: arc,
      );

      expect(narrative.characterArc, equals(arc));
    });
  });

  group('Story Service Initialization Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
    });

    test('should initialize story service', () {
      service.initialize();

      expect(service.progression, equals(StoryProgression.notStarted));
      expect(service.completedMilestoneCount, equals(0));
    });

    test('should load default stories on initialization', () {
      service.initialize();

      expect(service.getAllCharacterNarratives().isNotEmpty, isTrue);
    });

    test('should load character narratives', () {
      service.initialize();

      final sentKing = service.getCharacterNarrative('sente_king');
      expect(sentKing, isNotNull);
      expect(sentKing!.characterName, equals('蒼涼王'));
      expect(sentKing.role, equals('主人公'));
    });
  });

  group('Story Progression Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
      service.initialize();
    });

    test('should start story', () {
      expect(service.progression, equals(StoryProgression.notStarted));

      service.startStory();

      expect(service.progression, equals(StoryProgression.inProgress));
    });

    test('should pause story', () {
      service.startStory();
      expect(service.progression, equals(StoryProgression.inProgress));

      service.pauseStory();

      expect(service.progression, equals(StoryProgression.paused));
    });

    test('should resume paused story', () {
      service.startStory();
      service.pauseStory();
      expect(service.progression, equals(StoryProgression.paused));

      service.resumeStory();

      expect(service.progression, equals(StoryProgression.inProgress));
    });

    test('should complete story', () {
      service.startStory();

      service.completeStory();

      expect(service.progression, equals(StoryProgression.completed));
    });

    test('should track elapsed time', () async {
      service.startStory();

      await Future.delayed(const Duration(milliseconds: 100));

      final elapsed = service.elapsedSeconds;
      expect(elapsed, isNotNull);
      expect(elapsed, greaterThanOrEqualTo(0));
    });

    test('should return null elapsed time before start', () {
      expect(service.elapsedSeconds, isNull);
    });
  });

  group('Milestone Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
      service.initialize();
    });

    test('should complete milestone', () {
      service.startStory();

      service.completeMilestone('milestone_001');

      expect(service.isMilestoneCompleted('milestone_001'), isTrue);
    });

    test('should track multiple milestones', () {
      service.startStory();

      service.completeMilestone('milestone_001');
      service.completeMilestone('milestone_002');
      service.completeMilestone('milestone_003');

      expect(service.completedMilestoneCount, equals(3));
    });

    test('should not count same milestone twice', () {
      service.startStory();

      service.completeMilestone('milestone_001');
      service.completeMilestone('milestone_001');

      expect(service.completedMilestoneCount, equals(1));
    });

    test('should check milestone completion status', () {
      service.startStory();

      service.completeMilestone('milestone_complete');

      expect(service.isMilestoneCompleted('milestone_complete'), isTrue);
      expect(service.isMilestoneCompleted('milestone_incomplete'), isFalse);
    });
  });

  group('Character Narrative Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
      service.initialize();
    });

    test('should retrieve character narrative', () {
      final narrative = service.getCharacterNarrative('sente_king');

      expect(narrative, isNotNull);
      expect(narrative!.characterName, equals('蒼涼王'));
    });

    test('should return null for non-existent character', () {
      final narrative = service.getCharacterNarrative('non_existent');

      expect(narrative, isNull);
    });

    test('should retrieve all character narratives', () {
      final narratives = service.getAllCharacterNarratives().toList();

      expect(narratives.isNotEmpty, isTrue);
      expect(narratives.length, greaterThanOrEqualTo(1));
    });

    test('should have sente king narrative', () {
      final narrative = service.getCharacterNarrative('sente_king');

      expect(narrative, isNotNull);
      expect(narrative!.role, equals('主人公'));
    });

    test('should have gote king narrative', () {
      final narrative = service.getCharacterNarrative('gote_king');

      expect(narrative, isNotNull);
      expect(narrative!.role, equals('敵'));
    });

    test('should have ally narrative', () {
      final narrative = service.getCharacterNarrative('gold_ally');

      expect(narrative, isNotNull);
      expect(narrative!.role, equals('相棒'));
    });
  });

  group('Story JSON Export Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
      service.initialize();
    });

    test('should export to JSON', () {
      service.startStory();
      service.completeMilestone('milestone_001');

      final json = service.toJson();

      expect(json['progression'], contains('inProgress'));
      expect(json['completed_milestones'], isA<List>());
      expect(json['characters'], isA<List>());
    });

    test('should include completed milestones in JSON', () {
      service.startStory();
      service.completeMilestone('milestone_001');
      service.completeMilestone('milestone_002');

      final json = service.toJson();
      final milestones = json['completed_milestones'] as List;

      expect(milestones.length, equals(2));
      expect(milestones.contains('milestone_001'), isTrue);
      expect(milestones.contains('milestone_002'), isTrue);
    });
  });

  group('Story Manager Singleton Tests', () {
    test('should be singleton', () {
      final manager1 = StoryManager();
      final manager2 = StoryManager();

      expect(identical(manager1, manager2), isTrue);
    });

    test('should initialize manager', () {
      final manager = StoryManager();
      manager.initialize();

      expect(manager.service, isNotNull);
      expect(manager.progression, equals(StoryProgression.notStarted));
    });

    test('should start story via manager', () {
      final manager = StoryManager();
      manager.initialize();

      manager.startStory();

      expect(manager.progression, equals(StoryProgression.inProgress));
    });

    test('should complete milestone via manager', () {
      final manager = StoryManager();
      manager.initialize();
      manager.startStory();

      manager.completeMilestone('test_milestone');

      expect(manager.service.isMilestoneCompleted('test_milestone'), isTrue);
    });

    test('should get character narrative via manager', () {
      final manager = StoryManager();
      manager.initialize();

      final narrative = manager.getCharacterNarrative('sente_king');

      expect(narrative, isNotNull);
      expect(narrative!.characterName, equals('蒼涼王'));
    });
  });

  group('Story Event Listener Tests', () {
    late StoryEventManager eventManager;
    late TestStoryEventListener listener;

    setUp(() {
      eventManager = StoryEventManager();
      listener = TestStoryEventListener();
    });

    test('should register event listener', () {
      eventManager.addListener(listener);

      expect(eventManager.hasListener(listener), isTrue);
    });

    test('should remove event listener', () {
      eventManager.addListener(listener);
      eventManager.removeListener(listener);

      expect(eventManager.hasListener(listener), isFalse);
    });

    test('should notify story started', () {
      eventManager.addListener(listener);

      eventManager.notifyStoryStarted();

      expect(listener.storyStartedCalled, isTrue);
    });

    test('should notify story completed', () {
      eventManager.addListener(listener);

      eventManager.notifyStoryCompleted();

      expect(listener.storyCompletedCalled, isTrue);
    });

    test('should notify milestone completed', () {
      eventManager.addListener(listener);

      eventManager.notifyMilestoneCompleted('milestone_001');

      expect(listener.milestoneCompletedId, equals('milestone_001'));
    });

    test('should notify character arc progressed', () {
      eventManager.addListener(listener);

      eventManager.notifyCharacterArcProgressed('sente_king');

      expect(listener.characterArcProgressedId, equals('sente_king'));
    });

    test('should notify trigger executed', () {
      eventManager.addListener(listener);

      eventManager.notifyTriggerExecuted('trigger_001');

      expect(listener.triggerExecutedId, equals('trigger_001'));
    });
  });

  group('Story Service Debug Tests', () {
    late StoryService service;

    setUp(() {
      service = StoryService();
      service.initialize();
    });

    test('should print debug info without error', () {
      service.startStory();
      service.completeMilestone('test_milestone');

      // Should not throw
      service.debugPrint();
    });
  });

  group('Performance Tests', () {
    test('story service initialization should be fast', () {
      final stopwatch = Stopwatch()..start();

      final service = StoryService();
      service.initialize();

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('milestone completion should be fast', () {
      final service = StoryService();
      service.initialize();
      service.startStory();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        service.completeMilestone('milestone_$i');
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}

/// Test implementation of StoryEventListener
class TestStoryEventListener implements StoryEventListener {
  bool storyStartedCalled = false;
  bool storyCompletedCalled = false;
  String? milestoneCompletedId;
  String? characterArcProgressedId;
  String? triggerExecutedId;

  @override
  void onStoryStarted() {
    storyStartedCalled = true;
  }

  @override
  void onStoryCompleted() {
    storyCompletedCalled = true;
  }

  @override
  void onMilestoneCompleted(String milestoneId) {
    milestoneCompletedId = milestoneId;
  }

  @override
  void onCharacterArcProgressed(String characterId) {
    characterArcProgressedId = characterId;
  }

  @override
  void onTriggerExecuted(String triggerId) {
    triggerExecutedId = triggerId;
  }
}

/// Extension for testing StoryEventManager
extension StoryEventManagerTest on StoryEventManager {
  bool hasListener(StoryEventListener listener) {
    return _listeners.contains(listener);
  }

  List<StoryEventListener> get listeners => _listeners;
}
