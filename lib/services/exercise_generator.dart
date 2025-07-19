import 'dart:math';

import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';

class ExerciseGenerator {
  final Random _random = Random();

  /// Generate a recognition exercise where user identifies the formula name
  /// from the displayed LaTeX expression
  Exercise generateRecognitionExercise(
    Formula formula,
    List<Formula> allFormulas,
  ) {
    // Use current Formula's latexExpression as the question
    final question = formula.latexExpression;

    // Use current Formula's name as the correct answer
    final correctOption = ExerciseOption(
      id: formula.id,
      latexExpression: formula.latexExpression,
      textLabel: formula.name,
      isCorrect: true,
    );

    // Generate distractors from same category: randomly select 3 other formula names
    final sameCategory = allFormulas
        .where((f) => f.category == formula.category && f.id != formula.id)
        .toList();

    final List<ExerciseOption> distractors = [];
    final usedNames = <String>{formula.name};

    // Try to get 3 distractors from same category
    while (distractors.length < 3 && sameCategory.isNotEmpty) {
      final randomFormula = sameCategory[_random.nextInt(sameCategory.length)];
      sameCategory.remove(randomFormula);

      if (!usedNames.contains(randomFormula.name)) {
        usedNames.add(randomFormula.name);
        distractors.add(
          ExerciseOption(
            id: 'distractor_${randomFormula.id}',
            latexExpression: '',
            textLabel: randomFormula.name,
            isCorrect: false,
          ),
        );
      }
    }

    // If we don't have enough distractors from same category, use any other formulas
    if (distractors.length < 3) {
      final otherFormulas = allFormulas
          .where((f) => f.id != formula.id && !usedNames.contains(f.name))
          .toList();

      while (distractors.length < 3 && otherFormulas.isNotEmpty) {
        final randomFormula =
            otherFormulas[_random.nextInt(otherFormulas.length)];
        otherFormulas.remove(randomFormula);

        usedNames.add(randomFormula.name);
        distractors.add(
          ExerciseOption(
            id: 'distractor_${randomFormula.id}',
            latexExpression: '',
            textLabel: randomFormula.name,
            isCorrect: false,
          ),
        );
      }
    }

    final options = [correctOption, ...distractors];
    options.shuffle(_random);

    return Exercise(
      id: '${formula.id}_recognition_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.recognition,
      question: question,
      options: options,
      correctAnswerId: formula.id,
      explanation: '这是公式 ${formula.name}。',
    );
  }

  /// Generate a matching exercise where user matches formula components
  Exercise generateMatchingExercise(
    Formula formula,
    List<Formula> allFormulas,
  ) {
    if (formula.components.length < 2) {
      throw ArgumentError(
        'Formula must have at least two components for matching exercise',
      );
    }

    // Use formula's key component (usually leftSide) latexPart as question
    final questionComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.leftSide,
      orElse: () => formula.components.first,
    );

    // Use formula's corresponding part (usually rightSide) latexPart as correct answer
    final correctAnswerComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.rightSide,
      orElse: () => formula.components.last,
    );

    final correctOption = ExerciseOption(
      id: correctAnswerComponent.id,
      latexExpression: correctAnswerComponent.latexPart,
      textLabel: correctAnswerComponent.description,
      isCorrect: true,
    );

    // Generate 3 structurally similar but mathematically incorrect distractors
    final distractors = _generateMatchingDistractors(
      formula,
      correctAnswerComponent,
      allFormulas,
    );

    final options = [correctOption, ...distractors];
    options.shuffle(_random);

    return Exercise(
      id: '${formula.id}_matching_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.matching,
      question: questionComponent.latexPart,
      options: options,
      correctAnswerId: correctAnswerComponent.id,
      explanation: '这是 ${formula.name} 的正确匹配部分。',
    );
  }

  /// Generate a completion exercise where user fills in missing parts
  Exercise generateCompletionExercise(
    Formula formula,
    List<Formula> allFormulas,
  ) {
    if (formula.components.isEmpty) {
      throw ArgumentError(
        'Formula must have components for completion exercise',
      );
    }

    // Randomly select a key FormulaComponent for blanking
    final blankedComponent =
        formula.components[_random.nextInt(formula.components.length)];

    // Replace corresponding part in latexExpression with placeholder to form question
    final questionLatex = formula.latexExpression.replaceAll(
      blankedComponent.latexPart,
      '\\underline{\\hspace{2cm}}',
    );

    // Use the blanked component's latexPart as correct answer
    final correctOption = ExerciseOption(
      id: blankedComponent.id,
      latexExpression: blankedComponent.latexPart,
      textLabel: blankedComponent.description,
      isCorrect: true,
    );

    // Generate distractors from same formula's other components or similar components from same formula set
    final distractors = _generateCompletionDistractors(
      formula,
      blankedComponent,
      allFormulas,
    );

    final options = [correctOption, ...distractors];
    options.shuffle(_random);

    return Exercise(
      id: '${formula.id}_completion_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.completion,
      question: questionLatex,
      options: options,
      correctAnswerId: blankedComponent.id,
      explanation: '这是 ${formula.name} 中缺失的部分。',
    );
  }

  /// Generate distractors for matching exercises using multiple strategies
  List<ExerciseOption> _generateMatchingDistractors(
    Formula formula,
    FormulaComponent correctAnswer,
    List<Formula> allFormulas,
  ) {
    final distractors = <ExerciseOption>[];
    final usedLatex = <String>{correctAnswer.latexPart};

    // Strategy 1: Component borrowing from other formulas in same category
    final sameCategory = allFormulas
        .where((f) => f.category == formula.category && f.id != formula.id)
        .toList();

    for (final otherFormula in sameCategory) {
      if (distractors.length >= 3) break;

      final similarComponents = otherFormula.components
          .where(
            (c) =>
                c.type == correctAnswer.type &&
                !usedLatex.contains(c.latexPart),
          )
          .toList();

      if (similarComponents.isNotEmpty) {
        final component =
            similarComponents[_random.nextInt(similarComponents.length)];
        usedLatex.add(component.latexPart);
        distractors.add(
          ExerciseOption(
            id: 'distractor_${component.id}',
            latexExpression: component.latexPart,
            textLabel: component.description,
            isCorrect: false,
          ),
        );
      }
    }

    // Strategy 2: Variable/symbol swapping (u ↔ v, + ↔ -, sin ↔ cos)
    while (distractors.length < 3) {
      final swappedLatex = _applySymbolSwapping(correctAnswer.latexPart);
      if (!usedLatex.contains(swappedLatex)) {
        usedLatex.add(swappedLatex);
        distractors.add(
          ExerciseOption(
            id: 'swapped_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}',
            latexExpression: swappedLatex,
            textLabel: '变换后的表达式',
            isCorrect: false,
          ),
        );
      } else {
        // Fallback: minor modifications
        final modifiedLatex = _applyMinorModifications(correctAnswer.latexPart);
        if (!usedLatex.contains(modifiedLatex)) {
          usedLatex.add(modifiedLatex);
          distractors.add(
            ExerciseOption(
              id: 'modified_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}',
              latexExpression: modifiedLatex,
              textLabel: '修改后的表达式',
              isCorrect: false,
            ),
          );
        }
      }
    }

    return distractors.take(3).toList();
  }

  /// Generate distractors for completion exercises
  List<ExerciseOption> _generateCompletionDistractors(
    Formula formula,
    FormulaComponent blankedComponent,
    List<Formula> allFormulas,
  ) {
    final distractors = <ExerciseOption>[];
    final usedLatex = <String>{blankedComponent.latexPart};

    // Use components from other formulas that could logically fit the blank space
    final sameCategory = allFormulas
        .where((f) => f.category == formula.category)
        .toList();

    for (final otherFormula in sameCategory) {
      if (distractors.length >= 3) break;

      final similarComponents = otherFormula.components
          .where(
            (c) =>
                c.type == blankedComponent.type &&
                !usedLatex.contains(c.latexPart) &&
                c.id != blankedComponent.id,
          )
          .toList();

      if (similarComponents.isNotEmpty) {
        final component =
            similarComponents[_random.nextInt(similarComponents.length)];
        usedLatex.add(component.latexPart);
        distractors.add(
          ExerciseOption(
            id: 'distractor_${component.id}',
            latexExpression: component.latexPart,
            textLabel: component.description,
            isCorrect: false,
          ),
        );
      }
    }

    // If we don't have enough distractors, use other components from the same formula
    if (distractors.length < 3) {
      final otherComponents = formula.components
          .where(
            (c) =>
                c.id != blankedComponent.id && !usedLatex.contains(c.latexPart),
          )
          .toList();

      for (final component in otherComponents) {
        if (distractors.length >= 3) break;

        usedLatex.add(component.latexPart);
        distractors.add(
          ExerciseOption(
            id: 'same_formula_${component.id}',
            latexExpression: component.latexPart,
            textLabel: component.description,
            isCorrect: false,
          ),
        );
      }
    }

    // Fill remaining slots with modified versions if needed
    while (distractors.length < 3) {
      final modifiedLatex = _applyMinorModifications(
        blankedComponent.latexPart,
      );
      if (!usedLatex.contains(modifiedLatex)) {
        usedLatex.add(modifiedLatex);
        distractors.add(
          ExerciseOption(
            id: 'modified_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}',
            latexExpression: modifiedLatex,
            textLabel: '修改后的表达式',
            isCorrect: false,
          ),
        );
      } else {
        break; // Avoid infinite loop
      }
    }

    return distractors.take(3).toList();
  }

  /// Apply symbol swapping transformations
  String _applySymbolSwapping(String latex) {
    final swaps = {
      'u': 'v',
      'v': 'u',
      'x': 'y',
      'y': 'x',
      '+': '-',
      '-': '+',
      '\\sin': '\\cos',
      '\\cos': '\\sin',
      '\\tan': '\\cot',
      '\\cot': '\\tan',
      'a': 'b',
      'b': 'a',
      'n': 'm',
      'm': 'n',
    };

    String result = latex;
    final swapKeys = swaps.keys.toList()..shuffle(_random);

    // Apply 1-2 random swaps
    final numSwaps = _random.nextInt(2) + 1;
    for (int i = 0; i < numSwaps && i < swapKeys.length; i++) {
      final key = swapKeys[i];
      if (result.contains(key)) {
        result = result.replaceAll(key, swaps[key]!);
        break; // Only apply one swap to avoid over-modification
      }
    }

    return result;
  }

  /// Apply minor modifications to create plausible distractors
  String _applyMinorModifications(String latex) {
    final modifications = [
      // Add/remove differential symbols
      (String s) => s.contains('d') ? s.replaceFirst('d', '') : '${s}d',
      // Change exponents
      (String s) => s.contains('^2')
          ? s.replaceAll('^2', '^3')
          : s.contains('^3')
          ? s.replaceAll('^3', '^2')
          : s,
      // Add/remove parentheses
      (String s) =>
          s.contains('(') ? s.replaceAll('(', '').replaceAll(')', '') : '($s)',
      // Change subscripts
      (String s) => s.contains('_0')
          ? s.replaceAll('_0', '_1')
          : s.contains('_1')
          ? s.replaceAll('_1', '_0')
          : s,
    ];

    final modification = modifications[_random.nextInt(modifications.length)];
    return modification(latex);
  }
}
