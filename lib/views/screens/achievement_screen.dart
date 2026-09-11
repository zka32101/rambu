/// Achievement Screen
/// 実績・チャレンジ・フレンド管理画面
///
/// 機能:
/// - 実績トロフィー表示
/// - チャレンジ進捗表示
/// - フレンド/ライバル管理
/// - 対局申請管理

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/achievement.dart';
import 'package:rambu_shogi/viewmodels/achievement_provider.dart';

/// 実績・チャレンジ スクリーン
class AchievementScreen extends ConsumerWidget {
  final String userId;

  const AchievementScreen({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(achievementScreenProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('実績・チャレンジ'),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.emoji_events), text: '実績'),
              Tab(icon: Icon(Icons.assignment), text: 'チャレンジ'),
              Tab(icon: Icon(Icons.people), text: 'フレンド'),
              Tab(icon: Icon(Icons.mail), text: '申請'),
            ],
            labelColor: Colors.amber[700],
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.amber[700],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAchievementsTab(context, ref, userId),
            _buildChallengesTab(context, ref, userId),
            _buildFriendsTab(context, ref, userId),
            _buildRequestsTab(context, ref, userId),
          ],
        ),
      ),
    );
  }

  /// 実績 タブ
  Widget _buildAchievementsTab(BuildContext context, WidgetRef ref, String userId) {
    final achievementsAsync = ref.watch(userAchievementsProvider(userId));

    return achievementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(child: Text('実績がまだありません'));
        }

        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        final totalPoints = achievements
            .where((a) => a.isUnlocked)
            .fold<int>(0, (sum, a) => sum + a.achievement.points);

        return SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー（統計情報）
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[850],
                child: Column(
                  children: [
                    Text(
                      '獲得実績: $unlockedCount / ${achievements.length}',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '獲得ポイント: $totalPoints pt',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                        minHeight: 8,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),

              // 実績リスト
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final userAchievement = achievements[index];
                  return _buildAchievementTile(context, userAchievement);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 実績 タイル
  Widget _buildAchievementTile(BuildContext context, UserAchievement userAchievement) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.isUnlocked;
    final rarityColor = _getRarityColor(achievement.rarity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.grey[800] : Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked ? rarityColor : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: rarityColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            achievement.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          achievement.name,
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.bold,
            decoration: isUnlocked ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isUnlocked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getRarityLabel(achievement.rarity),
                      style: TextStyle(color: rarityColor, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.points} pt',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  Text(
                    achievement.condition,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
        trailing: isUnlocked
            ? Icon(Icons.check_circle, color: rarityColor, size: 24)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 40,
                      height: 4,
                      child: LinearProgressIndicator(
                        value: userAchievement.progressPercent / 100,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation(rarityColor),
                      ),
                    ),
                  ),
                  Text(
                    '${userAchievement.currentProgress}/${achievement.requiredProgress}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
        onTap: () => _showAchievementDetail(context, userAchievement),
      ),
    );
  }

  /// チャレンジ タブ
  Widget _buildChallengesTab(BuildContext context, WidgetRef ref, String userId) {
    final challengesAsync = ref.watch(userActiveChallengesProvider(userId));

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(child: Text('アクティブなチャレンジはありません'));
        }

        return ListView.builder(
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final userChallenge = challenges[index];
            return _buildChallengeTile(context, ref, userId, userChallenge);
          },
        );
      },
    );
  }

  /// チャレンジ タイル
  Widget _buildChallengeTile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserChallenge userChallenge,
  ) {
    final challenge = userChallenge.challenge;
    final difficultyColor = _getDifficultyColor(challenge.difficulty);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: difficultyColor, width: 2),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${challenge.difficulty}★',
              style: TextStyle(color: difficultyColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          challenge.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.objective,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: userChallenge.progressPercent / 100,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
              ),
            ),
          ],
        ),
        trailing: userChallenge.isCompleted
            ? ElevatedButton(
                onPressed: () {
                  ref
                      .read(achievementScreenProvider.notifier)
                      .claimChallengeReward(userId, challenge.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                ),
                child: const Text(
                  '報酬',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            : Text(
                '${userChallenge.currentProgress}/${challenge.difficulty}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
        onTap: () => _showChallengeDetail(context, userChallenge),
      ),
    );
  }

  /// フレンド タブ
  Widget _buildFriendsTab(BuildContext context, WidgetRef ref, String userId) {
    final friendsAsync = ref.watch(userFriendsProvider(userId));
    final rivalsAsync = ref.watch(userRivalsProvider(userId));

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (friends) {
        return rivalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
          data: (rivals) {
            if (friends.isEmpty && rivals.isEmpty) {
              return const Center(child: Text('フレンド・ライバルを追加してください'));
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (friends.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'フレンド (${friends.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    ...friends.map((f) => _buildRelationshipTile(context, f, RelationshipType.friend)),
                  ],
                  if (rivals.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ライバル (${rivals.length})',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    ...rivals.map((r) => _buildRelationshipTile(context, r, RelationshipType.rival)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 関係タイル
  Widget _buildRelationshipTile(
    BuildContext context,
    UserRelationship relationship,
    RelationshipType type,
  ) {
    final isFriend = type == RelationshipType.friend;
    final borderColor = isFriend ? Colors.blue : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor[700]!, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[700],
          backgroundImage: relationship.otherUserProfileImage != null
              ? NetworkImage(relationship.otherUserProfileImage!)
              : null,
          child: relationship.otherUserProfileImage == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          relationship.otherUserName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '対局: ${relationship.gamesPlayed} | 勝: ${relationship.wins} | 敗: ${relationship.losses}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Text(
          '${(relationship.winRateAgainstUser * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: borderColor[700],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 申請 タブ
  Widget _buildRequestsTab(BuildContext context, WidgetRef ref, String userId) {
    final requestsAsync = ref.watch(receivedMatchRequestsProvider(userId));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('対局申請がありません'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildMatchRequestTile(context, ref, userId, request);
          },
        );
      },
    );
  }

  /// 対局申請 タイル
  Widget _buildMatchRequestTile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    MatchRequest request,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[700]!, width: 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[700],
          backgroundImage: request.requesterImage != null
              ? NetworkImage(request.requesterImage!)
              : null,
          child: request.requesterImage == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          request.requesterName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: request.message != null
            ? Text(
                request.message!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                ref
                    .read(achievementScreenProvider.notifier)
                    .respondToMatchRequest(request.id, MatchRequestStatus.declined);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                ref
                    .read(achievementScreenProvider.notifier)
                    .respondToMatchRequest(request.id, MatchRequestStatus.accepted);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('対局を開始します')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 実績詳細ダイアログ
  void _showAchievementDetail(BuildContext context, UserAchievement userAchievement) {
    final achievement = userAchievement.achievement;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.white70),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('説明: ${achievement.description}'),
              const SizedBox(height: 12),
              Text('条件: ${achievement.condition}'),
              const SizedBox(height: 12),
              Text('レアリティ: ${_getRarityLabel(achievement.rarity)}'),
              const SizedBox(height: 12),
              Text('報酬: ${achievement.points} ポイント'),
              if (achievement.reward != null) ...[
                const SizedBox(height: 8),
                Text('特典: ${achievement.reward}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  /// チャレンジ詳細ダイアログ
  void _showChallengeDetail(BuildContext context, UserChallenge userChallenge) {
    final challenge = userChallenge.challenge;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(challenge.name),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.white70),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('説明: ${challenge.description}'),
              const SizedBox(height: 12),
              Text('目標: ${challenge.objective}'),
              const SizedBox(height: 12),
              Text('難易度: ${challenge.difficulty}★'),
              const SizedBox(height: 12),
              Text('報酬: ${challenge.rewardPoints} ポイント'),
              const SizedBox(height: 12),
              Text('進捗: ${userChallenge.currentProgress}/${challenge.difficulty}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  /// レアリティ色を取得
  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey[400]!;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  /// レアリティラベルを取得
  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'コモン';
      case AchievementRarity.uncommon:
        return 'アンコモン';
      case AchievementRarity.rare:
        return 'レア';
      case AchievementRarity.epic:
        return 'エピック';
      case AchievementRarity.legendary:
        return 'レジェンダリー';
    }
  }

  /// 難易度色を取得
  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 1) return Colors.green;
    if (difficulty <= 2) return Colors.blue;
    if (difficulty <= 3) return Colors.purple;
    if (difficulty <= 4) return Colors.orange;
    return Colors.red;
  }
}
