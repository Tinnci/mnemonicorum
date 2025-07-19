import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/formula.dart';

part 'exercise.g.dart';

@HiveType(typeId: 9)
enum ExerciseType {
  @HiveField(0)
  matching,
  @HiveField(1)
  completion,
  @HiveField(2)
  recognition,
  @HiveField(3)
  multiMatching, // 多对多配对
}

@HiveType(typeId: 10)
class ExerciseOption {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String latexExpression;
  @HiveField(2)
  final String textLabel;
  @HiveField(3)
  final bool isCorrect;
  @HiveField(4)
  final String pairId; // 用于标识配对关系

  ExerciseOption({
    required this.id,
    required this.latexExpression,
    required this.textLabel,
    required this.isCorrect,
    required this.pairId,
  });
}

@HiveType(typeId: 11)
class Exercise {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Formula formula;
  @HiveField(2)
  final ExerciseType type;
  @HiveField(3)
  final String question;
  @HiveField(4)
  final List<ExerciseOption> options;
  @HiveField(5)
  final String correctAnswerId;
  @HiveField(6)
  final String explanation;

  Exercise({
    required this.id,
    required this.formula,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
  });
}
