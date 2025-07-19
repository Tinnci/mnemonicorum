import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/achievement.dart';
import 'package:mnemonicorum/models/progress.dart';

class AchievementSystem extends ChangeNotifier {
  late Box<UserAchievements> _achievementsBox;
  UserAchievements? _userAchievements;

  List<Achievement> get achievements => _userAchievements?.achievements ?? [];
  int get currentStreak => _userAchievements?.currentStreak ?? 0;
  int get totalPracticeDays => _userAchievements?.totalPracticeDays ?? 0;

  Future<void> init() async {
    _achievementsBox = await Hive.openBox<UserAchievements>('achievements');
    _userAchievements =
        _achievementsBox.get('user_achievements') ??
        UserAchievements(achievements: _getDefaultAchievements());
    await _achievementsBox.put('user_achievements', _userAchievements!);
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      // Streak achievements
      Achievement(
        id: 'streak_3',
        name: '三日连击',
        description: '连续练习3天',
        type: AchievementType.streak,
        targetValue: 3,
        iconName: 'local_fire_department',
      ),
      Achievement(
        id: 'streak_7',
        name: '一周连击',
        description: '连续练习7天',
        type: AchievementType.streak,
        targetValue: 7,
        iconName: 'local_fire_department',
      ),
      Achievement(
        id: 'streak_30',
        name: '月度连击',
        description: '连续练习30天',
        type: AchievementType.streak,
        targetValue: 30,
        iconName: 'local_fire_department',
      ),

      // Mastery achievements
      Achievement(
        id: 'mastery_5',
        name: '初学者',
        description: '掌握5个公式',
        type: AchievementType.mastery,
        targetValue: 5,
        iconName: 'school',
      ),
      Achievement(
        id: 'mastery_20',
        name: '学者',
        description: '掌握20个公式',
        type: AchievementType.mastery,
        targetValue: 20,
        iconName: 'school',
      ),
      Achievement(
        id: 'mastery_50',
        name: '专家',
        description: '掌握50个公式',
        type: AchievementType.mastery,
        targetValue: 50,
        iconName: 'school',
      ),

      // Accuracy achievements
      Achievement(
        id: 'accuracy_90',
        name: '精准射手',
        description: '在一次练习中达到90%准确率',
        type: AchievementType.accuracy,
        targetValue: 90,
        iconName: 'gps_fixed',
      ),
      Achievement(
        id: 'accuracy_100',
        name: '完美主义者',
        description: '在一次练习中达到100%准确率',
        type: AchievementType.accuracy,
        targetValue: 100,
        iconName: 'stars',
      ),

      // Completion achievements
      Achievement(
        id: 'completion_calculus',
        name: '微积分大师',
        description: '完成所有微积分公式',
        type: AchievementType.completion,
        targetValue: 1,
        iconName: 'functions',
      ),
      Achievement(
        id: 'completion_trigonometry',
        name: '三角学专家',
        description: '完成所有三角学公式',
        type: AchievementType.completion,
        targetValue: 1,
        iconName: 'change_history',
      ),
    ];
  }

  Future<List<Achievement>> checkForNewAchievements({
    required List<FormulaProgress> allProgress,
    int? sessionAccuracy,
    String? completedCategory,
  }) async {
    final newAchievements = <Achievement>[];
    final updatedAchievements = <Achievement>[];

    // Update practice streak
    await _updatePracticeStreak();

    for (var achievement in _userAchievements!.achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          shouldUnlock = currentStreak >= achievement.targetValue;
          break;

        case AchievementType.mastery:
          final masteredCount = allProgress
              .where((p) => p.masteryLevel == MasteryLevel.mastered)
              .length;
          shouldUnlock = masteredCount >= achievement.targetValue;
          break;

        case AchievementType.accuracy:
          if (sessionAccuracy != null) {
            shouldUnlock = sessionAccuracy >= achievement.targetValue;
          }
          break;

        case AchievementType.completion:
          if (completedCategory != null) {
            shouldUnlock = _checkCategoryCompletion(
              completedCategory,
              allProgress,
            );
          }
          break;
      }

      if (shouldUnlock) {
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updatedAchievements.add(unlockedAchievement);
        newAchievements.add(unlockedAchievement);
      } else {
        updatedAchievements.add(achievement);
      }
    }

    // Update achievements list
    _userAchievements = UserAchievements(
      achievements: updatedAchievements,
      currentStreak: _userAchievements!.currentStreak,
      lastPracticeDate: _userAchievements!.lastPracticeDate,
      totalPracticeDays: _userAchievements!.totalPracticeDays,
    );

    await _achievementsBox.put('user_achievements', _userAchievements!);
    notifyListeners();

    return newAchievements;
  }

  Future<void> _updatePracticeStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPractice = _userAchievements!.lastPracticeDate;

    if (lastPractice == null) {
      // First time practicing
      _userAchievements = UserAchievements(
        achievements: _userAchievements!.achievements,
        currentStreak: 1,
        lastPracticeDate: today,
        totalPracticeDays: 1,
      );
    } else {
      final lastPracticeDay = DateTime(
        lastPractice.year,
        lastPractice.month,
        lastPractice.day,
      );
      final daysDifference = today.difference(lastPracticeDay).inDays;

      if (daysDifference == 0) {
        // Same day, no change to streak
        return;
      } else if (daysDifference == 1) {
        // Consecutive day, increment streak
        _userAchievements = UserAchievements(
          achievements: _userAchievements!.achievements,
          currentStreak: _userAchievements!.currentStreak + 1,
          lastPracticeDate: today,
          totalPracticeDays: _userAchievements!.totalPracticeDays + 1,
        );
      } else {
        // Streak broken, reset to 1
        _userAchievements = UserAchievements(
          achievements: _userAchievements!.achievements,
          currentStreak: 1,
          lastPracticeDate: today,
          totalPracticeDays: _userAchievements!.totalPracticeDays + 1,
        );
      }
    }

    await _achievementsBox.put('user_achievements', _userAchievements!);
  }

  bool _checkCategoryCompletion(
    String categoryId,
    List<FormulaProgress> allProgress,
  ) {
    // This would need to be implemented based on the specific category
    // For now, return false as a placeholder
    return false;
  }

  List<Achievement> getUnlockedAchievements() {
    return achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return achievements.where((a) => !a.isUnlocked).toList();
  }

  List<Achievement> getAllAchievements() {
    return achievements;
  }

  Future<void> showAchievementNotification(
    BuildContext context,
    Achievement achievement,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.yellow),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '成就解锁！',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(achievement.name),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
