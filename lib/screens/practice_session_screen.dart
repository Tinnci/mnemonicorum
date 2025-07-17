import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';
import 'package:mnemonicorum/services/practice_session_controller.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/widgets/completion_exercise_widget.dart';
import 'package:mnemonicorum/widgets/matching_exercise_widget.dart';
import 'package:mnemonicorum/widgets/recognition_exercise_widget.dart';

class PracticeSessionScreen extends StatefulWidget {
  final String formulaSetId;

  const PracticeSessionScreen({super.key, required this.formulaSetId});

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  late PracticeSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    final formulaRepository = Provider.of<FormulaRepository>(
      context,
      listen: false,
    );
    final progressService = Provider.of<ProgressService>(
      context,
      listen: false,
    );
    final exerciseGenerator = ExerciseGenerator();

    _sessionController = PracticeSessionController(
      exerciseGenerator: exerciseGenerator,
      progressService: progressService,
    );

    // Load formulas for the given formula set
    final formulas = formulaRepository
        .getAllCategories()
        .expand((category) => category.formulaSets)
        .firstWhere((set) => set.id == widget.formulaSetId)
        .formulas;

    _sessionController.initializeSession(formulas);
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PracticeSessionController>.value(
      value: _sessionController,
      child: Consumer<PracticeSessionController>(
        builder: (context, controller, child) {
          final currentExercise = controller.currentExercise;
          final totalQuestions = controller.totalQuestions;
          final currentQuestionNumber = controller.currentExerciseIndex + 1;

          if (controller.isSessionCompleted) {
            // Navigate to results screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(
                '/results?correct=${controller.correctAnswers}&total=$totalQuestions',
              );
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
              title: Text('练习会话 ($currentQuestionNumber/$totalQuestions)'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.pop(); // Go back to previous screen
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
    );
  }
}
