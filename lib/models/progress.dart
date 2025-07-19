import 'package:hive/hive.dart';

part 'progress.g.dart';

@HiveType(typeId: 12)
enum MasteryLevel {
  @HiveField(0)
  learning,
  @HiveField(1)
  practicing,
  @HiveField(2)
  mastered,
}

@HiveType(typeId: 13)
class ExerciseAttempt {
  @HiveField(0)
  final DateTime timestamp;
  @HiveField(1)
  final bool isCorrect;
  @HiveField(2) // 新增字段
  final String? selectedOptionId;
  @HiveField(3) // 新增字段
  final String? correctOptionId;

  ExerciseAttempt({
    required this.timestamp,
    required this.isCorrect,
    this.selectedOptionId, // 设为可选
    this.correctOptionId, // 设为可选
  });
}

@HiveType(typeId: 14)
class FormulaProgress {
  @HiveField(0)
  final String formulaId;
  @HiveField(1)
  int correctAnswers;
  @HiveField(2)
  int totalAttempts;
  @HiveField(3)
  DateTime lastPracticed;
  @HiveField(4)
  MasteryLevel masteryLevel;
  @HiveField(5)
  final List<ExerciseAttempt> attempts;

  FormulaProgress({
    required this.formulaId,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    required this.lastPracticed,
    this.masteryLevel = MasteryLevel.learning,
    required this.attempts,
  });
}
