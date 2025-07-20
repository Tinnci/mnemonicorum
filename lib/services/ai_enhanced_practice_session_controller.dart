import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/services/ai_enhanced_exercise_generator.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';

/// AI增强的练习会话控制器
/// 提供智能练习生成和错误分析功能
class AIEnhancedPracticeSessionController extends ChangeNotifier {
  final AIEnhancedExerciseGenerator _exerciseGenerator;
  final ProgressService _progressService;
  final AchievementSystem _achievementSystem;

  List<Formula> _formulas = [];
  List<Exercise> _exercises = [];
  int _currentExerciseIndex = 0;
  bool _isSessionCompleted = false;
  bool _isLoading = false;
  String? _aiExplanation;
  bool _showAIExplanation = false;

  AIEnhancedPracticeSessionController({
    required AIEnhancedExerciseGenerator exerciseGenerator,
    required ProgressService progressService,
    required AchievementSystem achievementSystem,
    required WidgetRef ref,
  }) : _exerciseGenerator = exerciseGenerator,
       _progressService = progressService,
       _achievementSystem = achievementSystem;

  // Getters
  List<Exercise> get exercises => _exercises;
  int get currentExerciseIndex => _currentExerciseIndex;
  Exercise? get currentExercise =>
      _exercises.isNotEmpty && _currentExerciseIndex < _exercises.length
      ? _exercises[_currentExerciseIndex]
      : null;
  int get totalQuestions => _exercises.length;
  bool get isSessionCompleted => _isSessionCompleted;
  bool get isLoading => _isLoading;
  String? get aiExplanation => _aiExplanation;
  bool get showAIExplanation => _showAIExplanation;

  /// 初始化会话
  Future<void> initializeSession(List<Formula> formulas) async {
    _formulas = formulas;
    _isLoading = true;
    _isSessionCompleted = false;
    _currentExerciseIndex = 0;
    _exercises.clear();
    _aiExplanation = null;
    _showAIExplanation = false;
    notifyListeners();

    try {
      // 使用AI增强的练习生成器生成练习题
      await _generateAIEnhancedExercises();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 使用AI生成增强的练习题
  Future<void> _generateAIEnhancedExercises() async {
    final exercises = <Exercise>[];

    // 为每个公式生成多种类型的练习
    for (final formula in _formulas) {
      try {
        // 生成匹配练习
        if (formula.components.length >= 2) {
          final matchingExercise = await _exerciseGenerator
              .generateMatchingExercise(formula, _formulas);
          exercises.add(matchingExercise);
        }

        // 生成填空练习
        if (formula.components.isNotEmpty) {
          final completionExercise = await _exerciseGenerator
              .generateCompletionExercise(formula, _formulas);
          exercises.add(completionExercise);
        }
      } catch (e) {
        developer.log(
          '生成练习失败: $e',
          name: 'AIEnhancedPracticeSessionController',
        );
        // 继续生成其他练习
      }
    }

    // 打乱练习顺序
    exercises.shuffle();
    _exercises = exercises;
  }

  /// 提交答案
  Future<void> submitAnswer(String selectedOptionId) async {
    if (_isSessionCompleted || _exercises.isEmpty) return;

    final currentExercise = _exercises[_currentExerciseIndex];
    final selectedOption = currentExercise.options.firstWhere(
      (option) => option.id == selectedOptionId,
    );

    final isCorrect = selectedOption.isCorrect;

    // 更新进度
    await _progressService.recordExerciseAttempt(
      currentExercise.formula.id,
      isCorrect,
      selectedOptionId: selectedOptionId,
      correctOptionId: currentExercise.correctAnswerId,
    );

    // 如果答案错误，获取AI解释
    if (!isCorrect) {
      await _getAIExplanation(currentExercise, selectedOptionId);
    } else {
      _aiExplanation = null;
      _showAIExplanation = false;
    }

    // 检查是否完成会话
    if (_currentExerciseIndex >= _exercises.length - 1) {
      _isSessionCompleted = true;
      await _checkAchievements();
    } else {
      _currentExerciseIndex++;
    }

    notifyListeners();
  }

  /// 获取AI解释
  Future<void> _getAIExplanation(Exercise exercise, String userAnswerId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final explanation = await _exerciseGenerator.getAIExplanation(
        exercise: exercise,
        userAnswerId: userAnswerId,
      );

      _aiExplanation = explanation;
      _showAIExplanation = true;
    } catch (e) {
      developer.log(
        '获取AI解释失败: $e',
        name: 'AIEnhancedPracticeSessionController',
      );
      _aiExplanation = "抱歉，无法生成解释。";
      _showAIExplanation = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 隐藏AI解释
  void hideAIExplanation() {
    _showAIExplanation = false;
    notifyListeners();
  }

  /// 检查成就
  Future<void> _checkAchievements() async {
    try {
      final sessionResults = _exercises.asMap().entries.map((entry) {
        final exercise = entry.value;
        final isCorrect = exercise.options.any(
          (opt) => opt.isCorrect && opt.id == exercise.correctAnswerId,
        );
        return isCorrect;
      }).toList();

      final correctCount = sessionResults.where((result) => result).length;
      final accuracy = correctCount / sessionResults.length;

      // 检查各种成就
      final allProgress = _progressService.getAllFormulaProgress();
      await _achievementSystem.checkForNewAchievements(
        allProgress: allProgress,
        sessionAccuracy: (accuracy * 100).round(),
      );
    } catch (e) {
      developer.log('检查成就失败: $e', name: 'AIEnhancedPracticeSessionController');
    }
  }

  /// 获取会话统计
  Map<String, dynamic> getSessionStats() {
    if (_exercises.isEmpty) return {};

    final results = _exercises.asMap().entries.map((entry) {
      final exercise = entry.value;
      final isCorrect = exercise.options.any(
        (opt) => opt.isCorrect && opt.id == exercise.correctAnswerId,
      );
      return {
        'exerciseId': exercise.id,
        'formulaId': exercise.formula.id,
        'type': exercise.type.toString(),
        'isCorrect': isCorrect,
      };
    }).toList();

    final correctCount = results
        .where((result) => result['isCorrect'] as bool)
        .length;
    final totalCount = results.length;
    final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;

    return {
      'totalQuestions': totalCount,
      'correctAnswers': correctCount,
      'accuracy': accuracy,
      'results': results,
    };
  }

  /// 重置会话
  void resetSession() {
    _currentExerciseIndex = 0;
    _isSessionCompleted = false;
    _aiExplanation = null;
    _showAIExplanation = false;
    notifyListeners();
  }
}
