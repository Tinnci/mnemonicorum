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

  /// Get formulas with incorrect answers for focused review
  List<String> getFormulasWithIncorrectAnswers({int limit = 10}) {
    final allProgress = getAllFormulaProgress();

    // Create a map to track incorrect answer counts
    final incorrectCountMap = <String, int>{};

    // Count incorrect answers for each formula
    for (final progress in allProgress) {
      final incorrectCount = progress.attempts
          .where((attempt) => !attempt.isCorrect)
          .length;

      if (incorrectCount > 0) {
        incorrectCountMap[progress.formulaId] = incorrectCount;
      }
    }

    // Sort formulas by incorrect answer count (descending)
    final sortedFormulas = incorrectCountMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return the top formulas with most incorrect answers
    return sortedFormulas.take(limit).map((entry) => entry.key).toList();
  }

  /// Get formulas for spaced repetition review based on time since last practice
  /// and accuracy history
  List<String> getFormulasForSpacedRepetition({int limit = 10}) {
    final allProgress = getAllFormulaProgress();
    final now = DateTime.now();

    // Calculate a priority score for each formula based on:
    // 1. Time since last practice (higher = higher priority)
    // 2. Accuracy (lower = higher priority)
    // 3. Number of attempts (higher = lower priority, as we want to focus on less practiced formulas too)
    final formulaScores = <String, double>{};

    for (final progress in allProgress) {
      if (progress.totalAttempts == 0) continue;

      final daysSinceLastPractice = now
          .difference(progress.lastPracticed)
          .inDays;

      final accuracy = progress.correctAnswers / progress.totalAttempts;

      // Calculate priority score:
      // Higher score = higher priority for review
      // Weight factors can be adjusted for optimal learning
      final timeWeight = 1.0;
      final accuracyWeight = 2.0;
      final attemptsWeight = 0.5;

      final timeScore = daysSinceLastPractice * timeWeight;
      final accuracyScore =
          (1.0 - accuracy) *
          10 *
          accuracyWeight; // Invert accuracy so lower accuracy = higher score
      final attemptsScore =
          (10.0 / (progress.totalAttempts + 1)) *
          attemptsWeight; // Fewer attempts = higher score

      final totalScore = timeScore + accuracyScore + attemptsScore;
      formulaScores[progress.formulaId] = totalScore;
    }

    // Sort formulas by priority score (descending)
    final sortedFormulas = formulaScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return the top formulas with highest priority scores
    return sortedFormulas.take(limit).map((entry) => entry.key).toList();
  }

  /// Get formulas that were recently answered incorrectly
  List<String> getRecentlyIncorrectFormulas({
    int limit = 5,
    int daysThreshold = 7,
  }) {
    final allProgress = getAllFormulaProgress();
    final now = DateTime.now();

    // Create a map to track most recent incorrect attempts
    final recentIncorrectMap = <String, DateTime>{};

    // Find most recent incorrect attempt for each formula
    for (final progress in allProgress) {
      final incorrectAttempts = progress.attempts
          .where((attempt) => !attempt.isCorrect)
          .toList();

      if (incorrectAttempts.isNotEmpty) {
        // Sort by timestamp (descending)
        incorrectAttempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Get most recent incorrect attempt
        final mostRecentIncorrect = incorrectAttempts.first;

        // Only include if within the days threshold
        final daysSince = now.difference(mostRecentIncorrect.timestamp).inDays;
        if (daysSince <= daysThreshold) {
          recentIncorrectMap[progress.formulaId] =
              mostRecentIncorrect.timestamp;
        }
      }
    }

    // Sort formulas by recency of incorrect attempt (most recent first)
    final sortedFormulas = recentIncorrectMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return the most recently incorrect formulas
    return sortedFormulas.take(limit).map((entry) => entry.key).toList();
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

  /// Get weekly progress statistics
  Map<String, dynamic> getWeeklyProgressStats() {
    final allProgress = getAllFormulaProgress();
    final now = DateTime.now();

    // Initialize data structure for weekly stats
    final weeklyStats = <String, Map<String, dynamic>>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      weeklyStats[dateString] = {
        'attempts': 0,
        'correct': 0,
        'accuracy': 0.0,
        'uniqueFormulas': <String>{},
      };
    }

    // Collect data for the past 7 days
    for (final progress in allProgress) {
      for (final attempt in progress.attempts) {
        final attemptDate = attempt.timestamp;
        final daysDifference = now.difference(attemptDate).inDays;

        // Only include attempts from the past 7 days
        if (daysDifference <= 6) {
          final dateString =
              '${attemptDate.year}-${attemptDate.month.toString().padLeft(2, '0')}-${attemptDate.day.toString().padLeft(2, '0')}';

          if (weeklyStats.containsKey(dateString)) {
            weeklyStats[dateString]!['attempts'] =
                (weeklyStats[dateString]!['attempts'] as int) + 1;
            if (attempt.isCorrect) {
              weeklyStats[dateString]!['correct'] =
                  (weeklyStats[dateString]!['correct'] as int) + 1;
            }
            (weeklyStats[dateString]!['uniqueFormulas'] as Set<String>).add(
              progress.formulaId,
            );
          }
        }
      }
    }

    // Calculate accuracy for each day
    for (final dateString in weeklyStats.keys) {
      final attempts = weeklyStats[dateString]!['attempts'] as int;
      final correct = weeklyStats[dateString]!['correct'] as int;

      if (attempts > 0) {
        weeklyStats[dateString]!['accuracy'] = (correct / attempts) * 100;
      }

      // Convert set to count for JSON serialization
      weeklyStats[dateString]!['uniqueFormulas'] =
          (weeklyStats[dateString]!['uniqueFormulas'] as Set<String>).length;
    }

    // Calculate trends
    final accuracyTrend = _calculateTrend(
      weeklyStats.values.map((stats) => stats['accuracy'] as double).toList(),
    );
    final attemptsTrend = _calculateTrend(
      weeklyStats.values
          .map((stats) => stats['attempts'] as int)
          .toList()
          .map((v) => v.toDouble())
          .toList(),
    );

    return {
      'dailyStats': weeklyStats,
      'accuracyTrend': accuracyTrend,
      'attemptsTrend': attemptsTrend,
    };
  }

  /// Get category-wise progress analytics
  Map<String, dynamic> getCategoryAnalytics(List<dynamic> categories) {
    final allProgress = getAllFormulaProgress();
    final categoryStats = <String, Map<String, dynamic>>{};

    // Initialize category stats
    for (final category in categories) {
      categoryStats[category.id] = {
        'name': category.name,
        'totalFormulas': 0,
        'practicedFormulas': 0,
        'masteredFormulas': 0,
        'averageAccuracy': 0.0,
        'totalAttempts': 0,
        'correctAttempts': 0,
      };

      // Count total formulas in this category
      int totalFormulas = 0;
      for (final formulaSet in category.formulaSets) {
        totalFormulas += (formulaSet.formulas.length as num).toInt();
      }
      categoryStats[category.id]!['totalFormulas'] = totalFormulas;
    }

    // Map formula IDs to categories
    final formulaToCategoryMap = <String, String>{};
    for (final category in categories) {
      for (final formulaSet in category.formulaSets) {
        for (final formula in formulaSet.formulas) {
          formulaToCategoryMap[formula.id] = category.id;
        }
      }
    }

    // Collect progress data by category
    for (final progress in allProgress) {
      final categoryId = formulaToCategoryMap[progress.formulaId];
      if (categoryId != null && categoryStats.containsKey(categoryId)) {
        // Count practiced formulas
        categoryStats[categoryId]!['practicedFormulas'] =
            (categoryStats[categoryId]!['practicedFormulas'] as int) + 1;

        // Count mastered formulas
        if (progress.masteryLevel == MasteryLevel.mastered) {
          categoryStats[categoryId]!['masteredFormulas'] =
              (categoryStats[categoryId]!['masteredFormulas'] as int) + 1;
        }

        // Add attempts and correct answers
        categoryStats[categoryId]!['totalAttempts'] =
            (categoryStats[categoryId]!['totalAttempts'] as int) +
            progress.totalAttempts;
        categoryStats[categoryId]!['correctAttempts'] =
            (categoryStats[categoryId]!['correctAttempts'] as int) +
            progress.correctAnswers;
      }
    }

    // Calculate average accuracy for each category
    for (final categoryId in categoryStats.keys) {
      final totalAttempts = categoryStats[categoryId]!['totalAttempts'] as int;
      final correctAttempts =
          categoryStats[categoryId]!['correctAttempts'] as int;

      if (totalAttempts > 0) {
        categoryStats[categoryId]!['averageAccuracy'] =
            (correctAttempts / totalAttempts) * 100;
      }
    }

    return {'categoryStats': categoryStats};
  }

  /// Get learning patterns and recommendations
  Map<String, dynamic> getLearningInsights() {
    final allProgress = getAllFormulaProgress();
    // Remove unused variable
    // final now = DateTime.now();

    // Analyze time of day patterns
    final hourlyAttempts = List<int>.filled(24, 0);
    final hourlyCorrect = List<int>.filled(24, 0);

    // Track formula difficulty vs. accuracy (commented out as unused)
    // final difficultyAccuracy = <String, Map<String, dynamic>>{
    //   'easy': {'attempts': 0, 'correct': 0},
    //   'medium': {'attempts': 0, 'correct': 0},
    //   'hard': {'attempts': 0, 'correct': 0},
    // };

    // Analyze session length vs. accuracy
    final sessionLengths = <int>[];
    final sessionAccuracies = <double>[];

    // Collect data
    for (final progress in allProgress) {
      // Skip if no attempts
      if (progress.attempts.isEmpty) continue;

      // Group attempts by session (attempts within 30 minutes of each other)
      final sessions = <List<ExerciseAttempt>>[];
      List<ExerciseAttempt> currentSession = [];

      // Sort attempts by timestamp
      final sortedAttempts = List<ExerciseAttempt>.from(progress.attempts)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (int i = 0; i < sortedAttempts.length; i++) {
        final attempt = sortedAttempts[i];

        // Start a new session if this is the first attempt or if it's been more than 30 minutes
        if (currentSession.isEmpty ||
            attempt.timestamp
                    .difference(currentSession.last.timestamp)
                    .inMinutes >
                30) {
          if (currentSession.isNotEmpty) {
            sessions.add(currentSession);
          }
          currentSession = [attempt];
        } else {
          currentSession.add(attempt);
        }

        // Add the last session
        if (i == sortedAttempts.length - 1 && currentSession.isNotEmpty) {
          sessions.add(currentSession);
        }

        // Track hourly patterns
        final hour = attempt.timestamp.hour;
        hourlyAttempts[hour]++;
        if (attempt.isCorrect) {
          hourlyCorrect[hour]++;
        }
      }

      // Analyze sessions
      for (final session in sessions) {
        final sessionLength = session.length;
        final correctCount = session.where((a) => a.isCorrect).length;
        final sessionAccuracy = sessionLength > 0
            ? (correctCount / sessionLength) * 100
            : 0.0;

        sessionLengths.add(sessionLength);
        sessionAccuracies.add(sessionAccuracy);
      }
    }

    // Calculate optimal study time
    int bestHour = 0;
    double bestAccuracy = 0.0;

    for (int hour = 0; hour < 24; hour++) {
      if (hourlyAttempts[hour] >= 5) {
        // Minimum threshold for significance
        final accuracy = hourlyAttempts[hour] > 0
            ? (hourlyCorrect[hour] / hourlyAttempts[hour]) * 100
            : 0.0;

        if (accuracy > bestAccuracy) {
          bestAccuracy = accuracy;
          bestHour = hour;
        }
      }
    }

    // Calculate optimal session length
    int optimalSessionLength = 10; // Default
    if (sessionLengths.isNotEmpty && sessionAccuracies.isNotEmpty) {
      // Group by session length
      final lengthAccuracyMap = <int, List<double>>{};

      for (int i = 0; i < sessionLengths.length; i++) {
        final length = sessionLengths[i];
        final accuracy = sessionAccuracies[i];

        if (!lengthAccuracyMap.containsKey(length)) {
          lengthAccuracyMap[length] = [];
        }
        lengthAccuracyMap[length]!.add(accuracy);
      }

      // Find length with best average accuracy
      double bestAvgAccuracy = 0.0;

      for (final entry in lengthAccuracyMap.entries) {
        if (entry.value.length >= 3) {
          // Minimum threshold for significance
          final avgAccuracy =
              entry.value.reduce((a, b) => a + b) / entry.value.length;

          if (avgAccuracy > bestAvgAccuracy) {
            bestAvgAccuracy = avgAccuracy;
            optimalSessionLength = entry.key;
          }
        }
      }
    }

    return {
      'optimalStudyTime': bestHour,
      'optimalSessionLength': optimalSessionLength,
      'hourlyAttempts': hourlyAttempts,
      'hourlyAccuracy': List.generate(
        24,
        (hour) => hourlyAttempts[hour] > 0
            ? (hourlyCorrect[hour] / hourlyAttempts[hour]) * 100
            : 0.0,
      ),
    };
  }

  /// Calculate trend (positive or negative) from a list of values
  double _calculateTrend(List<double> values) {
    if (values.isEmpty || values.length < 2) return 0.0;

    // Simple linear regression
    final n = values.length;
    final indices = List.generate(n, (i) => i.toDouble());

    final sumX = indices.reduce((a, b) => a + b);
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = List.generate(
      n,
      (i) => indices[i] * values[i],
    ).reduce((a, b) => a + b);
    final sumX2 = indices.map((x) => x * x).reduce((a, b) => a + b);

    // Calculate slope
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    return slope;
  }

  Future<void> clearAllProgress() async {
    await _progressBox.clear();
    notifyListeners(); // Notify UI to update after clearing progress
  }
}
