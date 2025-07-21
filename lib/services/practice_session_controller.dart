import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/models/session_state.dart';
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

        // Save session state after answer
        _updateSessionState();

        notifyListeners();
      }
      return;
    }

    _selectedOptionId = optionId;
    _showFeedback = true;

    final bool isAnswerCorrect = currentExercise!.correctAnswerId == optionId;

    if (isAnswerCorrect) {
      _correctAnswers++;
    } else {
      _incorrectAnswers++;
    }

    // 传递更详细的信息
    _progressService.recordExerciseAttempt(
      currentExercise!.formula.id,
      isAnswerCorrect,
      selectedOptionId: optionId,
      correctOptionId: currentExercise!.correctAnswerId,
    );

    // Save session state after answer
    _updateSessionState();

    notifyListeners();
  }

  void moveToNextExercise() {
    if (isSessionCompleted) return;

    _currentExerciseIndex++;
    _selectedOptionId = null;
    _showFeedback = false;

    // Save session state after moving to next exercise
    _updateSessionState();

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

  // Session persistence methods
  String? _sessionId;
  String? _sessionType;
  int? _reviewMode;

  void setSessionMetadata({String? sessionType, int? reviewMode}) {
    _sessionType = sessionType;
    _reviewMode = reviewMode;
  }

  Future<void> saveSession() async {
    if (_formulas.isEmpty || _exercises.isEmpty) return;

    try {
      final sessionBox = await Hive.openBox<SessionState>('sessionStates');

      // Create session state from current controller state
      final sessionState = SessionState.fromController(
        formulas: _formulas,
        currentExerciseIndex: _currentExerciseIndex,
        exercises: _exercises,
        correctAnswers: _correctAnswers,
        incorrectAnswers: _incorrectAnswers,
        sessionType: _sessionType,
        reviewMode: _reviewMode,
      );

      // Save session ID for later reference
      _sessionId = sessionState.sessionId;

      // Save to Hive
      await sessionBox.put(_sessionId, sessionState);

      // Clean up old sessions
      _cleanupOldSessions(sessionBox);
    } catch (e) {
      ErrorHandler.logError('Save session', e);
    }
  }

  Future<bool> loadSession(String sessionId) async {
    try {
      final sessionBox = await Hive.openBox<SessionState>('sessionStates');
      final sessionState = sessionBox.get(sessionId);

      if (sessionState == null || sessionState.isExpired) {
        return false;
      }

      // We need to reconstruct the formulas and exercises
      // This is a simplified approach - in a real app, you'd need to fetch
      // the actual Formula objects from a repository

      // For now, we'll just return false to indicate failure
      return false;
    } catch (e) {
      ErrorHandler.logError('Load session', e);
      return false;
    }
  }

  Future<List<SessionState>> getRecentSessions({int limit = 5}) async {
    try {
      final sessionBox = await Hive.openBox<SessionState>('sessionStates');
      final sessions = sessionBox.values.toList();

      // Sort by last updated (most recent first)
      sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      // Filter out expired sessions
      final validSessions = sessions.where((s) => !s.isExpired).toList();

      // Return limited number
      return validSessions.take(limit).toList();
    } catch (e) {
      ErrorHandler.logError('Get recent sessions', e);
      return [];
    }
  }

  Future<void> _cleanupOldSessions(Box<SessionState> sessionBox) async {
    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      // Find expired sessions (older than 24 hours)
      for (final key in sessionBox.keys) {
        final session = sessionBox.get(key);
        if (session != null) {
          final difference = now.difference(session.lastUpdated);
          if (difference.inHours > 24) {
            keysToDelete.add(key.toString());
          }
        }
      }

      // Delete expired sessions
      for (final key in keysToDelete) {
        await sessionBox.delete(key);
      }
    } catch (e) {
      ErrorHandler.logError('Cleanup old sessions', e);
    }
  }

  // Update session state after each action
  Future<void> _updateSessionState() async {
    if (_sessionId != null) {
      try {
        final sessionBox = await Hive.openBox<SessionState>('sessionStates');
        final existingState = sessionBox.get(_sessionId);

        if (existingState != null) {
          final updatedState = existingState.copyWith(
            currentExerciseIndex: _currentExerciseIndex,
            correctAnswers: _correctAnswers,
            incorrectAnswers: _incorrectAnswers,
            lastUpdated: DateTime.now(),
          );

          await sessionBox.put(_sessionId, updatedState);
        }
      } catch (e) {
        ErrorHandler.logError('Update session state', e);
      }
    }
  }
}
