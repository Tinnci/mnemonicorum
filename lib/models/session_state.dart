import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/models/exercise.dart';

part 'session_state.g.dart';

@HiveType(typeId: 20)
class SessionState {
  @HiveField(0)
  final List<String> formulaIds;

  @HiveField(1)
  final int currentExerciseIndex;

  @HiveField(2)
  final int correctAnswers;

  @HiveField(3)
  final int incorrectAnswers;

  @HiveField(4)
  final DateTime lastUpdated;

  @HiveField(5)
  final String sessionId;

  @HiveField(6)
  final List<String> exerciseTypes; // Store exercise types as strings

  @HiveField(7)
  final Map<String, bool> exerciseResults; // Map of exerciseId to result (correct/incorrect)

  @HiveField(8)
  final String? sessionType; // 'practice', 'review', etc.

  @HiveField(9)
  final int? reviewMode; // For review sessions

  SessionState({
    required this.formulaIds,
    required this.currentExerciseIndex,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.lastUpdated,
    required this.sessionId,
    required this.exerciseTypes,
    required this.exerciseResults,
    this.sessionType,
    this.reviewMode,
  });

  // Create from controller state
  factory SessionState.fromController({
    required List<Formula> formulas,
    required int currentExerciseIndex,
    required List<Exercise> exercises,
    required int correctAnswers,
    required int incorrectAnswers,
    String? sessionType,
    int? reviewMode,
  }) {
    final formulaIds = formulas.map((f) => f.id).toList();
    final exerciseTypes = exercises.map((e) => e.type.toString()).toList();
    final exerciseResults = <String, bool>{};

    // Store results of completed exercises
    for (int i = 0; i < currentExerciseIndex && i < exercises.length; i++) {
      final exercise = exercises[i];
      // We don't have the actual results here, so we'll need to update this map
      // when recording answers
      exerciseResults[exercise.id] = false; // Default to false
    }

    return SessionState(
      formulaIds: formulaIds,
      currentExerciseIndex: currentExerciseIndex,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      lastUpdated: DateTime.now(),
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseTypes: exerciseTypes,
      exerciseResults: exerciseResults,
      sessionType: sessionType,
      reviewMode: reviewMode,
    );
  }

  // Create a copy with updated values
  SessionState copyWith({
    List<String>? formulaIds,
    int? currentExerciseIndex,
    int? correctAnswers,
    int? incorrectAnswers,
    DateTime? lastUpdated,
    String? sessionId,
    List<String>? exerciseTypes,
    Map<String, bool>? exerciseResults,
    String? sessionType,
    int? reviewMode,
  }) {
    return SessionState(
      formulaIds: formulaIds ?? this.formulaIds,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sessionId: sessionId ?? this.sessionId,
      exerciseTypes: exerciseTypes ?? this.exerciseTypes,
      exerciseResults: exerciseResults ?? this.exerciseResults,
      sessionType: sessionType ?? this.sessionType,
      reviewMode: reviewMode ?? this.reviewMode,
    );
  }

  // Update exercise result
  SessionState updateExerciseResult(String exerciseId, bool isCorrect) {
    final updatedResults = Map<String, bool>.from(exerciseResults);
    updatedResults[exerciseId] = isCorrect;

    return copyWith(
      exerciseResults: updatedResults,
      lastUpdated: DateTime.now(),
      correctAnswers: isCorrect ? correctAnswers + 1 : correctAnswers,
      incorrectAnswers: isCorrect ? incorrectAnswers : incorrectAnswers + 1,
    );
  }

  // Move to next exercise
  SessionState moveToNextExercise() {
    return copyWith(
      currentExerciseIndex: currentExerciseIndex + 1,
      lastUpdated: DateTime.now(),
    );
  }

  // Check if session is expired (older than 24 hours)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours > 24;
  }
}
