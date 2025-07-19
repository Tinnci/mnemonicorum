import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/progress.dart';

class ProgressService extends ChangeNotifier {
  late Box<FormulaProgress> _progressBox;

  Future<void> init() async {
    _progressBox = await Hive.openBox<FormulaProgress>('formulaProgress');
  }

  FormulaProgress getFormulaProgress(String formulaId) {
    return _progressBox.get(formulaId) ??
        FormulaProgress(
          formulaId: formulaId,
          lastPracticed: DateTime.now(),
          attempts: [],
        );
  }

  Future<void> recordExerciseAttempt(
    String formulaId,
    bool isCorrect, {
    String? selectedOptionId,
    String? correctOptionId,
  }) async {
    final progress = getFormulaProgress(formulaId);
    progress.totalAttempts++;
    progress.lastPracticed = DateTime.now();
    progress.attempts.add(
      ExerciseAttempt(
        timestamp: DateTime.now(),
        isCorrect: isCorrect,
        selectedOptionId: selectedOptionId, // 保存选择的选项ID
        correctOptionId: correctOptionId, // 保存正确的选项ID
      ),
    );

    if (isCorrect) {
      progress.correctAnswers++;
    }

    // Simple mastery level calculation (can be improved later)
    if (progress.totalAttempts >= 5) {
      final accuracy = progress.correctAnswers / progress.totalAttempts;
      if (accuracy >= 0.9) {
        progress.masteryLevel = MasteryLevel.mastered;
      } else if (accuracy >= 0.6) {
        progress.masteryLevel = MasteryLevel.practicing;
      } else {
        progress.masteryLevel = MasteryLevel.learning;
      }
    }

    await _progressBox.put(formulaId, progress);
    notifyListeners(); // Notify UI to update
  }

  List<FormulaProgress> getAllFormulaProgress() {
    return _progressBox.values.toList();
  }

  /// Get overall statistics for the progress screen
  Map<String, dynamic> getOverallStats() {
    final allProgress = getAllFormulaProgress();

    if (allProgress.isEmpty) {
      return {
        'totalSessions': 0,
        'totalQuestions': 0,
        'overallAccuracy': 0.0,
        'currentStreak': 0,
      };
    }

    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalSessions = 0;

    for (final progress in allProgress) {
      totalQuestions += progress.totalAttempts;
      totalCorrect += progress.correctAnswers;
      totalSessions += progress.attempts.length;
    }

    final overallAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;

    // Calculate current streak (simplified - count consecutive days with practice)
    final currentStreak = _calculateCurrentStreak(allProgress);

    return {
      'totalSessions': totalSessions,
      'totalQuestions': totalQuestions,
      'overallAccuracy': overallAccuracy,
      'currentStreak': currentStreak,
    };
  }

  /// Get progress for a specific category
  Map<String, dynamic> getCategoryProgress(String categoryId) {
    // This is a simplified implementation
    // In a real app, you'd filter by category
    final allProgress = getAllFormulaProgress();

    if (allProgress.isEmpty) {
      return {'percentage': 0.0, 'masteredCount': 0, 'totalCount': 0};
    }

    final masteredCount = allProgress
        .where((p) => p.masteryLevel == MasteryLevel.mastered)
        .length;
    final totalCount = allProgress.length;
    final percentage = totalCount > 0
        ? (masteredCount / totalCount) * 100
        : 0.0;

    return {
      'percentage': percentage,
      'masteredCount': masteredCount,
      'totalCount': totalCount,
    };
  }

  /// Get formulas that need practice (low accuracy or not practiced recently)
  List<String> getFormulasNeedingPractice() {
    final allProgress = getAllFormulaProgress();
    final now = DateTime.now();

    return allProgress
        .where((progress) {
          // Need practice if accuracy is low or not practiced in last 3 days
          final accuracy = progress.totalAttempts > 0
              ? progress.correctAnswers / progress.totalAttempts
              : 0.0;
          final daysSinceLastPractice = now
              .difference(progress.lastPracticed)
              .inDays;

          return accuracy < 0.8 || daysSinceLastPractice > 3;
        })
        .map((progress) => progress.formulaId)
        .toList();
  }

  /// Calculate current practice streak
  int _calculateCurrentStreak(List<FormulaProgress> allProgress) {
    if (allProgress.isEmpty) return 0;

    // Get all practice dates
    final practiceDates = <DateTime>[];
    for (final progress in allProgress) {
      for (final attempt in progress.attempts) {
        final date = DateTime(
          attempt.timestamp.year,
          attempt.timestamp.month,
          attempt.timestamp.day,
        );
        if (!practiceDates.any((d) => d.isAtSameMomentAs(date))) {
          practiceDates.add(date);
        }
      }
    }

    if (practiceDates.isEmpty) return 0;

    // Sort dates in descending order
    practiceDates.sort((a, b) => b.compareTo(a));

    // Count consecutive days from today
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDate;

    for (final practiceDate in practiceDates) {
      if (practiceDate.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (practiceDate.isBefore(checkDate)) {
        // Gap in practice, streak ends
        break;
      }
    }

    return streak;
  }

  /// Get commonly wrong options for a specific formula
  List<String> getCommonlyWrongOptions(String formulaId, {int limit = 3}) {
    final allProgress = getAllFormulaProgress();
    final wrongAttempts = <String>[];

    for (final progress in allProgress) {
      // 找到与目标公式相关的错误尝试
      if (progress.formulaId == formulaId) {
        for (final attempt in progress.attempts) {
          if (!attempt.isCorrect && attempt.selectedOptionId != null) {
            wrongAttempts.add(attempt.selectedOptionId!);
          }
        }
      }
    }

    if (wrongAttempts.isEmpty) return [];

    // 计算每个错误选项的频率
    final frequencyMap = <String, int>{};
    for (final optionId in wrongAttempts) {
      frequencyMap[optionId] = (frequencyMap[optionId] ?? 0) + 1;
    }

    // 按频率排序并返回最高频的几个
    final sortedOptions = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedOptions.take(limit).map((e) => e.key).toList();
  }

  Future<void> clearAllProgress() async {
    await _progressBox.clear();
    notifyListeners(); // Notify UI to update after clearing progress
  }
}
