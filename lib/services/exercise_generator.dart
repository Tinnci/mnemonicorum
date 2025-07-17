import 'dart:math';

import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';

class ExerciseGenerator {
  Exercise generateMatchingExercise(Formula formula) {
    if (formula.components.length < 2) {
      throw ArgumentError(
        'Formula must have at least two components for matching exercise',
      );
    }

    final random = Random();

    // Select a random component as the question (e.g., left side)
    final questionComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.leftSide,
      orElse: () => formula.components.first,
    );

    // Create options: include the correct answer and some plausible incorrect ones
    final List<ExerciseOption> options = [];

    // Add the correct answer
    final correctAnswerComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.rightSide,
      orElse: () => formula.components.last,
    );
    options.add(
      ExerciseOption(
        id: correctAnswerComponent.id,
        latexExpression: correctAnswerComponent.latexPart,
        textLabel: '正确答案', // This might need to be dynamic later
        isCorrect: true,
      ),
    );

    // Add incorrect options from other formulas or random components
    // For simplicity, let's add random components from the same formula for now
    final otherComponents = formula.components
        .where(
          (c) =>
              c.id != correctAnswerComponent.id &&
              c.type == ComponentType.rightSide,
        )
        .toList();

    while (options.length < 4 && otherComponents.isNotEmpty) {
      final randomIndex = random.nextInt(otherComponents.length);
      final randomComponent = otherComponents.removeAt(randomIndex);
      options.add(
        ExerciseOption(
          id: randomComponent.id,
          latexExpression: randomComponent.latexPart,
          textLabel: '错误答案', // This might need to be dynamic later
          isCorrect: false,
        ),
      );
    }

    // Shuffle options
    options.shuffle(random);

    return Exercise(
      id: '${formula.id}_matching_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.matching,
      question:
          questionComponent.id, // Storing the ID of the question component
      options: options,
      correctAnswerId: correctAnswerComponent.id,
      explanation: '这是分部积分法的右侧。', // Placeholder
    );
  }

  Exercise generateCompletionExercise(Formula formula) {
    if (formula.components.isEmpty) {
      throw ArgumentError(
        'Formula must have components for completion exercise',
      );
    }

    final random = Random();

    // Select a component to be blanked out
    final blankedComponent =
        formula.components[random.nextInt(formula.components.length)];

    // Create the question LaTeX by replacing the blanked component with a placeholder
    String questionLatex = formula.latexExpression.replaceAll(
      blankedComponent.latexPart,
      '\\underline{\\hspace{2cm}}',
    ); // Placeholder for a blank line

    // Create options: include the correct answer and some plausible incorrect ones
    final List<ExerciseOption> options = [];
    options.add(
      ExerciseOption(
        id: blankedComponent.id,
        latexExpression: blankedComponent.latexPart,
        textLabel: blankedComponent.description,
        isCorrect: true,
      ),
    );

    // Add incorrect options (for simplicity, just generate some random strings for now)
    for (int i = 0; i < 3; i++) {
      options.add(
        ExerciseOption(
          id: 'fake_option_${DateTime.now().microsecondsSinceEpoch}_$i',
          latexExpression: '\text{假选项${i + 1}}',
          textLabel: '假选项${i + 1}',
          isCorrect: false,
        ),
      );
    }

    options.shuffle(random);

    return Exercise(
      id: '${formula.id}_completion_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.completion,
      question: questionLatex,
      options: options,
      correctAnswerId: blankedComponent.id,
      explanation: '这是缺失的部分。', // Placeholder
    );
  }

  Exercise generateRecognitionExercise(Formula formula) {
    final random = Random();

    // Create options: include the correct answer (formula name) and some plausible incorrect ones
    final List<ExerciseOption> options = [];
    options.add(
      ExerciseOption(
        id: formula.id,
        latexExpression:
            formula.latexExpression, // Not used for display in this widget
        textLabel: formula.name,
        isCorrect: true,
      ),
    );

    // Add incorrect options (for simplicity, just generate some random names for now)
    for (int i = 0; i < 3; i++) {
      options.add(
        ExerciseOption(
          id: 'fake_name_${DateTime.now().microsecondsSinceEpoch}_$i',
          latexExpression: '',
          textLabel: '错误公式名称${i + 1}',
          isCorrect: false,
        ),
      );
    }

    options.shuffle(random);

    return Exercise(
      id: '${formula.id}_recognition_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.recognition,
      question: formula.latexExpression, // Question is the full formula
      options: options,
      correctAnswerId: formula.id,
      explanation: '这是公式 ${formula.name}。', // Placeholder
    );
  }
}
