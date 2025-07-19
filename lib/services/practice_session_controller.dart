import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

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

    // 首先添加一个多对多匹配练习
    final multiMatchingExercise = ErrorHandler.handleExerciseError(
      () => _exerciseGenerator.generateMultiMatchingExercise(
        allFormulas: formulas,
      ),
      'Generate multi-matching exercise',
      fallbackStrategies: [
        () => _exerciseGenerator.generateRecognitionExercise(
          formulas.first,
          formulas,
        ),
      ],
    );
    if (multiMatchingExercise != null) generated.add(multiMatchingExercise);

    for (var formula in formulas) {
      // Use error handling for each exercise generation with fallback strategies
      final matchingExercise = ErrorHandler.handleExerciseError(
        () => _exerciseGenerator.generateMatchingExercise(formula, formulas),
        'Generate matching exercise for ${formula.name}',
        fallbackStrategies: [
          () =>
              _exerciseGenerator.generateRecognitionExercise(formula, formulas),
        ],
      );
      if (matchingExercise != null) generated.add(matchingExercise);

      final completionExercise = ErrorHandler.handleExerciseError(
        () => _exerciseGenerator.generateCompletionExercise(formula, formulas),
        'Generate completion exercise for ${formula.name}',
        fallbackStrategies: [
          () =>
              _exerciseGenerator.generateRecognitionExercise(formula, formulas),
        ],
      );
      if (completionExercise != null) generated.add(completionExercise);

      final recognitionExercise = ErrorHandler.handleExerciseError(
        () => _exerciseGenerator.generateRecognitionExercise(formula, formulas),
        'Generate recognition exercise for ${formula.name}',
      );
      if (recognitionExercise != null) generated.add(recognitionExercise);
    }

    // Ensure we have at least some exercises
    if (generated.isEmpty) {
      throw ExerciseGenerationException(
        'Failed to generate any exercises from ${formulas.length} formulas',
      );
    }

    generated.shuffle(); // Shuffle the order of exercises
    return generated;
  }

  void selectOption(String optionId) {
    if (_showFeedback) return; // Prevent re-selection when feedback is shown

    // 特殊处理多对多匹配练习
    if (currentExercise!.type == ExerciseType.multiMatching) {
      if (optionId == 'completed') {
        // 多对多匹配完成
        _correctAnswers++;
        _showFeedback = true;
        _progressService.recordExerciseAttempt(
          currentExercise!.formula.id,
          true, // 多对多匹配完成算作正确
        );
        notifyListeners();
      }
      return;
    }

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
