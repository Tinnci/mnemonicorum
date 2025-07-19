import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';
import 'package:mnemonicorum/services/practice_session_controller.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/widgets/completion_exercise_widget.dart';
import 'package:mnemonicorum/widgets/matching_exercise_widget.dart';
import 'package:mnemonicorum/widgets/recognition_exercise_widget.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

class PracticeSessionScreen extends StatefulWidget {
  final String formulaSetId;

  const PracticeSessionScreen({super.key, required this.formulaSetId});

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
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

      // Load formulas for the given formula set with error handling
      final formulaSet = formulaRepository
          .getAllCategories()
          .expand((category) => category.formulaSets)
          .firstWhere(
            (set) => set.id == widget.formulaSetId,
            orElse: () => throw ExerciseGenerationException(
              'Formula set ${widget.formulaSetId} not found',
              widget.formulaSetId,
            ),
          );

      if (formulaSet.formulas.isEmpty) {
        throw ExerciseGenerationException(
          'No formulas found in formula set ${widget.formulaSetId}',
          widget.formulaSetId,
        );
      }

      if (!mounted) return;
      _sessionController.initializeSession(formulaSet.formulas);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        'Initialize practice session',
        error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Failed to initialize practice session. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return ErrorHandler.errorBoundary(
      child: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _hasError
          ? Scaffold(
              appBar: AppBar(
                title: const Text('练习会话'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home'); // 修改：从'/'改为'/home'
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
                        '会话初始化失败',
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
                            context.go('/home'); // 修改：从'/'改为'/home'
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
                  final currentExercise = controller.currentExercise;
                  final totalQuestions = controller.totalQuestions;
                  final currentQuestionNumber =
                      controller.currentExerciseIndex + 1;
                  if (controller.isSessionCompleted) {
                    // Complete session and check for achievements, then navigate to results screen
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;

                      // Store context reference before async gap
                      final currentContext = context;

                      final success = await ErrorHandler.handleProgressError(
                        () => controller.completeSession(),
                        'complete practice session',
                        context: currentContext,
                      );

                      if (!mounted) return;
                      if (success) {
                        // Check if the context is still valid
                        if (currentContext.mounted) {
                          GoRouter.of(currentContext).go(
                            '/results?correct=${controller.correctAnswers}&total=$totalQuestions&formulaSetId=${widget.formulaSetId}',
                          );
                        }
                      }
                    });
                    return const Scaffold(body: Center(child: Text('会话完成！')));
                  }
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
                  }

                  return Scaffold(
                    appBar: AppBar(
                      title: Text(
                        '练习会话 ($currentQuestionNumber/$totalQuestions)',
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop(); // Go back to previous screen
                          } else {
                            context.go(
                              '/home', // 修改：从'/'改为'/home'
                            ); // Go to home screen if nothing to pop
                          }
                        },
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Expanded(child: Center(child: exerciseWidget)),
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
          'Failed to load practice session. Please go back and try again.',
    );
  }
}
