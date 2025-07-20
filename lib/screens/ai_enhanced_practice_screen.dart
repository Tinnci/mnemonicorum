import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/ai_enhanced_exercise_generator.dart';
import 'package:mnemonicorum/services/ai_enhanced_practice_session_controller.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/widgets/completion_exercise_widget.dart';
import 'package:mnemonicorum/widgets/matching_exercise_widget.dart';
import 'package:mnemonicorum/widgets/recognition_exercise_widget.dart';
import 'package:mnemonicorum/widgets/multi_matching_exercise_widget.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

/// AI增强的练习界面
/// 展示AI生成的练习题和智能错误分析
class AIEnhancedPracticeScreen extends ConsumerStatefulWidget {
  final String formulaSetId;

  const AIEnhancedPracticeScreen({super.key, required this.formulaSetId});

  @override
  ConsumerState<AIEnhancedPracticeScreen> createState() =>
      _AIEnhancedPracticeScreenState();
}

class _AIEnhancedPracticeScreenState
    extends ConsumerState<AIEnhancedPracticeScreen> {
  late AIEnhancedPracticeSessionController _sessionController;
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
      final formulaRepository = provider.Provider.of<FormulaRepository>(
        context,
        listen: false,
      );
      final progressService = provider.Provider.of<ProgressService>(
        context,
        listen: false,
      );
      final achievementSystem = provider.Provider.of<AchievementSystem>(
        context,
        listen: false,
      );

      final exerciseGenerator = AIEnhancedExerciseGenerator(ref);

      _sessionController = AIEnhancedPracticeSessionController(
        exerciseGenerator: exerciseGenerator,
        progressService: progressService,
        achievementSystem: achievementSystem,
        ref: ref,
      );

      // 加载公式集
      final formulaSet = formulaRepository
          .getAllCategories()
          .expand((category) => category.formulaSets)
          .firstWhere(
            (set) => set.id == widget.formulaSetId,
            orElse: () =>
                throw Exception('Formula set ${widget.formulaSetId} not found'),
          );

      if (formulaSet.formulas.isEmpty) {
        throw Exception(
          'No formulas found in formula set ${widget.formulaSetId}',
        );
      }

      if (!mounted) return;

      // 使用AI增强的会话控制器初始化
      await _sessionController.initializeSession(formulaSet.formulas);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        'Initialize AI enhanced practice session',
        error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'AI练习会话初始化失败，请重试。';
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
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI正在生成练习题...'),
                  ],
                ),
              ),
            )
          : _hasError
          ? Scaffold(
              appBar: AppBar(
                title: const Text('AI练习会话'),
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
                        'AI会话初始化失败',
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
          : provider.ChangeNotifierProvider<
              AIEnhancedPracticeSessionController
            >.value(
              value: _sessionController,
              child: provider.Consumer<AIEnhancedPracticeSessionController>(
                builder: (context, controller, child) {
                  final totalQuestions = controller.totalQuestions;
                  final currentQuestionNumber =
                      controller.currentExerciseIndex + 1;

                  // 检查会话是否已完成
                  if (controller.isSessionCompleted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;

                      final stats = controller.getSessionStats();

                      // 导航到结果页面
                      context.push('/results', extra: stats);
                    });

                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final currentExercise = controller.currentExercise;
                  if (currentExercise == null) {
                    return const Scaffold(
                      body: Center(child: Text('没有可用的练习题')),
                    );
                  }

                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('AI练习会话'),
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
                      actions: [
                        // 显示进度
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '$currentQuestionNumber / $totalQuestions',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    body: Column(
                      children: [
                        // 进度条
                        LinearProgressIndicator(
                          value: totalQuestions > 0
                              ? currentQuestionNumber / totalQuestions
                              : 0.0,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),

                        // 练习内容
                        Expanded(child: _buildExerciseWidget(currentExercise)),

                        // AI解释区域
                        if (controller.showAIExplanation &&
                            controller.aiExplanation != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI解释',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: controller.hideAIExplanation,
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  controller.aiExplanation!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildExerciseWidget(Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.matching:
        return MatchingExerciseWidget(
          exercise: exercise,
          onOptionSelected: (optionId) async {
            await _sessionController.submitAnswer(optionId);
          },
        );
      case ExerciseType.completion:
        return CompletionExerciseWidget(
          exercise: exercise,
          onOptionSelected: (optionId) async {
            await _sessionController.submitAnswer(optionId);
          },
        );
      case ExerciseType.recognition:
        return RecognitionExerciseWidget(
          exercise: exercise,
          onOptionSelected: (optionId) async {
            await _sessionController.submitAnswer(optionId);
          },
        );
      case ExerciseType.multiMatching:
        return MultiMatchingExerciseWidget(
          exercise: exercise,
          onOptionSelected: (optionId) async {
            await _sessionController.submitAnswer(optionId);
          },
        );
    }
  }
}
