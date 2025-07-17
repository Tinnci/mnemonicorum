import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/progress.dart';

class ProgressService {
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

  Future<void> recordExerciseAttempt(String formulaId, bool isCorrect) async {
    final progress = getFormulaProgress(formulaId);
    progress.totalAttempts++;
    progress.lastPracticed = DateTime.now();
    progress.attempts.add(
      ExerciseAttempt(timestamp: DateTime.now(), isCorrect: isCorrect),
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
  }

  List<FormulaProgress> getAllFormulaProgress() {
    return _progressBox.values.toList();
  }

  Future<void> clearAllProgress() async {
    await _progressBox.clear();
  }
}
