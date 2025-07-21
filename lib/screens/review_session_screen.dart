import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';
import 'package:mnemonicorum/services/practice_session_controller.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/widgets/completion_exercise_widget.dart';
import 'package:mnemonicorum/widgets/matching_exercise_widget.dart';
import 'package:mnemonicorum/widgets/recognition_exercise_widget.dart';
import 'package:mnemonicorum/widgets/multi_matching_exercise_widget.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

enum ReviewMode { incorrectAnswers, spacedRepetition, recentlyIncorrect }

class ReviewSessionScreen extends StatefulWidget {
  final ReviewMode reviewMode;
  final int limit;

  const ReviewSessionScreen({
    super.key,
    required this.reviewMode,
    this.limit = 10,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  late PracticeSessionController _sessionController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final formulaRepository = Provider.of<FormulaRepository>(
        context,
        listen: false,
      );
      final progressService = Provider.of<ProgressService>(
        context,
        listen: false,
      );
      final achievementSystem = Provider.of<AchievementSystem>(
        context,
        listen: false,
      );
      final exerciseGenerator = ExerciseGenerator();

      _sessionController = PracticeSessionController(
        exerciseGenerator: exerciseGenerator,
        progressService: progressService,
        achievementSystem: achievementSystem,
      );

      // Get formula IDs based on review mode
      List<String> formulaIds;
      String sessionName;

      switch (widget.reviewMode) {
        case ReviewMode.incorrectAnswers:
          formulaIds = progressService.getFormulasWithIncorrectAnswers(
            limit: widget.limit,
          );
          sessionName = '错题回顾';
          break;
        case ReviewMode.spacedRepetition:
          formulaIds = progressService.getFormulasForSpacedRepetition(
            limit: widget.limit,
          );
          sessionName = '间隔复习';
          break;
        case ReviewMode.recentlyIncorrect:
          formulaIds = progressService.getRecentlyIncorrectFormulas(
            limit: widget.limit,
          );
          sessionName = '最近错题';
          break;
      }

      if (formulaIds.isEmpty) {
        throw Exception('没有需要复习的公式。请先完成一些练习！');
      }

      // Get actual Formula objects from the repository
      final formulasToReview = <Formula>[];
      for (final formulaId in formulaIds) {
        final formula = formulaRepository.getFormulaById(formulaId);
        if (formula != null) {
          formulasToReview.add(formula);
        }
      }

      if (formulasToReview.isEmpty) {
        throw Exception('无法加载复习公式。请稍后再试！');
      }

      if (!mounted) return;
      _sessionController.initializeSession(formulasToReview);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        'Initialize review session',
        error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    await _initializeSession();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  String _getReviewModeTitle() {
    switch (widget.reviewMode) {
      case ReviewMode.incorrectAnswers:
        return '错题回顾';
      case ReviewMode.spacedRepetition:
        return '间隔复习';
      case ReviewMode.recentlyIncorrect:
        return '最近错题';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandler.errorBoundary(
      child: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _hasError
          ? Scaffold(
              appBar: AppBar(
                title: Text(_getReviewModeTitle()),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '复习会话初始化失败',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? '未知错误',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _retryInitialization,
                        child: const Text('重试'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: const Text('返回主页'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ChangeNotifierProvider<PracticeSessionController>.value(
              value: _sessionController,
              child: Consumer<PracticeSessionController>(
                builder: (context, controller, child) {
                  final totalQuestions = controller.totalQuestions;
                  final currentQuestionNumber =
                      controller.currentExerciseIndex + 1;

                  // Check if session is completed
                  if (controller.isSessionCompleted) {
                    // Complete session and check for achievements, then navigate to results screen
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;

                      // Store context reference before async gap
                      final currentContext = context;

                      final success = await ErrorHandler.handleProgressError(
                        () => controller.completeSession(),
                        'complete review session',
                        context: currentContext,
                      );

                      if (!mounted) return;
                      if (success) {
                        // Check if the context is still valid
                        if (currentContext.mounted) {
                          GoRouter.of(currentContext).go(
                            '/results?correct=${controller.correctAnswers}&total=$totalQuestions&reviewMode=${widget.reviewMode.index}',
                          );
                        }
                      }
                    });
                    return const Scaffold(body: Center(child: Text('会话完成！')));
                  }

                  // Get current exercise
                  final currentExercise = controller.currentExercise;

                  if (currentExercise == null) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  Widget exerciseWidget;
                  switch (currentExercise.type) {
                    case ExerciseType.matching:
                      exerciseWidget = MatchingExerciseWidget(
                        exercise: currentExercise,
                        onOptionSelected: controller.selectOption,
                        showFeedback: controller.showFeedback,
                        selectedOptionId: controller.selectedOptionId,
                        correctAnswerId: currentExercise.correctAnswerId,
                      );
                      break;
                    case ExerciseType.completion:
                      exerciseWidget = CompletionExerciseWidget(
                        exercise: currentExercise,
                        onOptionSelected: controller.selectOption,
                        showFeedback: controller.showFeedback,
                        selectedOptionId: controller.selectedOptionId,
                        correctAnswerId: currentExercise.correctAnswerId,
                      );
                      break;
                    case ExerciseType.recognition:
                      exerciseWidget = RecognitionExerciseWidget(
                        exercise: currentExercise,
                        onOptionSelected: controller.selectOption,
                        showFeedback: controller.showFeedback,
                        selectedOptionId: controller.selectedOptionId,
                        correctAnswerId: currentExercise.correctAnswerId,
                      );
                      break;
                    case ExerciseType.multiMatching:
                      exerciseWidget = MultiMatchingExerciseWidget(
                        exercise: currentExercise,
                        onOptionSelected: controller.selectOption,
                        showFeedback: controller.showFeedback,
                        selectedOptionId: controller.selectedOptionId,
                        correctAnswerId: currentExercise.correctAnswerId,
                      );
                      break;
                  }

                  return Scaffold(
                    appBar: AppBar(
                      title: Text(
                        '${_getReviewModeTitle()} ($currentQuestionNumber/$totalQuestions)',
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Formula name and category
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentExercise.formula.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${currentExercise.formula.category} > ${currentExercise.formula.subcategory}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Exercise widget
                          Expanded(child: Center(child: exerciseWidget)),

                          // Next button when feedback is shown
                          if (controller.showFeedback) ...[
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: controller.moveToNextExercise,
                              child: Text(
                                controller.isSessionCompleted ? '查看结果' : '下一题',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      errorMessage:
          'Failed to load review session. Please go back and try again.',
    );
  }
}
