import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';

class PracticeSessionController extends ChangeNotifier {
  final ExerciseGenerator _exerciseGenerator;
  final ProgressService _progressService;
  final AchievementSystem? _achievementSystem;

  List<Formula> _formulas = [];
  int _currentExerciseIndex = 0;
  List<Exercise> _exercises = [];
  String? _selectedOptionId;
  bool _showFeedback = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;

  PracticeSessionController({
    required ExerciseGenerator exerciseGenerator,
    required ProgressService progressService,
    AchievementSystem? achievementSystem,
  }) : _exerciseGenerator = exerciseGenerator,
       _progressService = progressService,
       _achievementSystem = achievementSystem;

  List<Formula> get formulas => _formulas;
  int get currentExerciseIndex => _currentExerciseIndex;
  List<Exercise> get exercises => _exercises;
  Exercise? get currentExercise =>
      _exercises.isNotEmpty ? _exercises[_currentExerciseIndex] : null;
  String? get selectedOptionId => _selectedOptionId;
  bool get showFeedback => _showFeedback;
  int get correctAnswers => _correctAnswers;
  int get incorrectAnswers => _incorrectAnswers;
  int get totalQuestions => _exercises.length;

  bool get isSessionCompleted => _currentExerciseIndex >= _exercises.length;

  void initializeSession(List<Formula> formulas) {
    _formulas = formulas;
    _currentExerciseIndex = 0;
    _exercises = _generateExercises(formulas);
    _selectedOptionId = null;
    _showFeedback = false;
    _correctAnswers = 0;
    _incorrectAnswers = 0;
    notifyListeners();
  }

  List<Exercise> _generateExercises(List<Formula> formulas) {
    final generated = <Exercise>[];
    for (var formula in formulas) {
      generated.add(
        _exerciseGenerator.generateMatchingExercise(formula, formulas),
      );
      generated.add(
        _exerciseGenerator.generateCompletionExercise(formula, formulas),
      );
      generated.add(
        _exerciseGenerator.generateRecognitionExercise(formula, formulas),
      );
    }
    generated.shuffle(); // Shuffle the order of exercises
    return generated;
  }

  void selectOption(String optionId) {
    if (_showFeedback) return; // Prevent re-selection when feedback is shown

    _selectedOptionId = optionId;
    _showFeedback = true;

    if (currentExercise!.correctAnswerId == optionId) {
      _correctAnswers++;
    } else {
      _incorrectAnswers++;
    }
    _progressService.recordExerciseAttempt(
      currentExercise!.formula.id,
      currentExercise!.correctAnswerId == optionId,
    );
    notifyListeners();
  }

  void moveToNextExercise() {
    if (isSessionCompleted) return;

    _currentExerciseIndex++;
    _selectedOptionId = null;
    _showFeedback = false;
    notifyListeners();
  }

  Future<void> completeSession() async {
    if (_achievementSystem != null) {
      final allProgress = _progressService.getAllFormulaProgress();
      final sessionAccuracy = totalQuestions == 0
          ? 0
          : ((_correctAnswers / totalQuestions) * 100).round();

      await _achievementSystem.checkForNewAchievements(
        allProgress: allProgress,
        sessionAccuracy: sessionAccuracy,
      );
    }
  }

  void resetSession() {
    _formulas = [];
    _currentExerciseIndex = 0;
    _exercises = [];
    _selectedOptionId = null;
    _showFeedback = false;
    _correctAnswers = 0;
    _incorrectAnswers = 0;
    notifyListeners();
  }

  // For session persistence (to be implemented with Hive later)
  // Future<void> saveSession() async { ... }
  // Future<void> loadSession() async { ... }
}
