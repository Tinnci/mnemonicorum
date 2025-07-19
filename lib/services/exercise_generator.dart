import 'dart:math';

import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

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
      if (sameCategory.isEmpty) break; // Additional safety check
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

    final exercise = Exercise(
      id: '${formula.id}_recognition_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.recognition,
      question: question,
      options: options,
      correctAnswerId: formula.id,
      explanation: '这是公式 ${formula.name}。',
    );

    // Validate exercise quality
    if (!_validateExerciseQuality(exercise)) {
      throw ExerciseGenerationException(
        'Generated exercise failed quality validation',
        formula.id,
      );
    }

    return exercise;
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
        } else {
          break; // Avoid infinite loop
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
    // Use more targeted swaps to avoid breaking LaTeX commands
    final swaps = {
      // Variable swaps - only swap standalone variables
      r'\bu\b': 'v',
      r'\bv\b': 'u',
      r'\bx\b': 'y',
      r'\by\b': 'x',
      r'\ba\b': 'b',
      r'\bb\b': 'a',
      // Operator swaps
      r'\+': '-',
      r'-': '+',
      // Function swaps - only swap complete function names
      r'\\sin\b': '\\cos',
      r'\\cos\b': '\\sin',
      r'\\tan\b': '\\cot',
      r'\\cot\b': '\\tan',
    };

    String result = latex;
    final swapEntries = swaps.entries.toList()..shuffle(_random);

    // Apply 1 random swap to avoid over-modification
    for (final entry in swapEntries) {
      if (RegExp(entry.key).hasMatch(result)) {
        result = result.replaceAll(RegExp(entry.key), entry.value);
        break; // Only apply one swap
      }
    }

    // Validate the result before returning
    if (_isValidLatex(result)) {
      return result;
    } else {
      // Return original if transformation created invalid LaTeX
      return latex;
    }
  }

  /// Validate LaTeX expression for basic syntax correctness
  bool _isValidLatex(String latex) {
    // Check for common LaTeX command integrity
    final invalidPatterns = [
      r'\\inf[^t]', // \inf not followed by 't' (should be \infty)
      r'\\fr[^a]', // \fr not followed by 'a' (should be \frac)
      r'\\su[^m]', // \su not followed by 'm' (should be \sum)
      r'\\in[^t]', // \in not followed by 't' (should be \int)
      r'\\lim[^i]', // \lim not followed by 'i' (should be \lim)
    ];

    for (final pattern in invalidPatterns) {
      if (RegExp(pattern).hasMatch(latex)) {
        return false;
      }
    }

    // Check for balanced braces
    int braceCount = 0;
    for (int i = 0; i < latex.length; i++) {
      if (latex[i] == '{') braceCount++;
      if (latex[i] == '}') braceCount--;
      if (braceCount < 0) return false; // More closing than opening
    }

    return braceCount == 0; // Should be balanced
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

  /// Validate exercise quality to ensure it meets educational standards
  bool _validateExerciseQuality(Exercise exercise) {
    try {
      // Check basic exercise structure
      if (exercise.options.isEmpty) {
        ErrorHandler.logError('Exercise validation', 'No options provided');
        return false;
      }

      if (exercise.options.length < 2) {
        ErrorHandler.logError(
          'Exercise validation',
          'Insufficient options (need at least 2)',
        );
        return false;
      }

      // Ensure there's exactly one correct answer
      final correctOptions = exercise.options
          .where((opt) => opt.isCorrect)
          .toList();
      if (correctOptions.length != 1) {
        ErrorHandler.logError(
          'Exercise validation',
          'Must have exactly one correct answer, found ${correctOptions.length}',
        );
        return false;
      }

      // Ensure correct answer ID matches
      final correctOption = correctOptions.first;
      if (correctOption.id != exercise.correctAnswerId) {
        ErrorHandler.logError(
          'Exercise validation',
          'Correct answer ID mismatch',
        );
        return false;
      }

      // Validate LaTeX expressions in options
      for (final option in exercise.options) {
        if (option.latexExpression.isNotEmpty &&
            !ErrorHandler.isValidLatexExpression(option.latexExpression)) {
          ErrorHandler.logError(
            'Exercise validation',
            'Invalid LaTeX in option: ${option.latexExpression}',
          );
          return false;
        }
      }

      // Validate question LaTeX (if it contains LaTeX)
      if (exercise.question.contains('\\') &&
          !ErrorHandler.isValidLatexExpression(exercise.question)) {
        ErrorHandler.logError(
          'Exercise validation',
          'Invalid LaTeX in question: ${exercise.question}',
        );
        return false;
      }

      // Ensure distractors are different from correct answer
      final correctText = correctOption.textLabel.toLowerCase().trim();
      final correctLatex = correctOption.latexExpression.toLowerCase().trim();

      for (final option in exercise.options) {
        if (!option.isCorrect) {
          final optionText = option.textLabel.toLowerCase().trim();
          final optionLatex = option.latexExpression.toLowerCase().trim();

          // Check for duplicate text labels
          if (optionText == correctText && optionText.isNotEmpty) {
            ErrorHandler.logError(
              'Exercise validation',
              'Distractor text matches correct answer: $optionText',
            );
            return false;
          }

          // Check for duplicate LaTeX expressions
          if (optionLatex == correctLatex && optionLatex.isNotEmpty) {
            ErrorHandler.logError(
              'Exercise validation',
              'Distractor LaTeX matches correct answer: $optionLatex',
            );
            return false;
          }
        }
      }

      // Exercise type specific validations
      switch (exercise.type) {
        case ExerciseType.recognition:
          return _validateRecognitionExercise(exercise);
        case ExerciseType.matching:
          return _validateMatchingExercise(exercise);
        case ExerciseType.completion:
          return _validateCompletionExercise(exercise);
      }
    } catch (error) {
      ErrorHandler.logError('Exercise validation', error);
      return false;
    }
  }

  /// Validate recognition exercise specific requirements
  bool _validateRecognitionExercise(Exercise exercise) {
    // Question should be a valid LaTeX expression
    if (!ErrorHandler.isValidLatexExpression(exercise.question)) {
      ErrorHandler.logError(
        'Recognition validation',
        'Invalid question LaTeX: ${exercise.question}',
      );
      return false;
    }

    // All options should have meaningful text labels (formula names)
    for (final option in exercise.options) {
      if (option.textLabel.trim().isEmpty) {
        ErrorHandler.logError(
          'Recognition validation',
          'Empty text label in option',
        );
        return false;
      }
    }

    return true;
  }

  /// Validate matching exercise specific requirements
  bool _validateMatchingExercise(Exercise exercise) {
    // Question should be a valid LaTeX expression (formula component)
    if (!ErrorHandler.isValidLatexExpression(exercise.question)) {
      ErrorHandler.logError(
        'Matching validation',
        'Invalid question LaTeX: ${exercise.question}',
      );
      return false;
    }

    // All options should have valid LaTeX expressions
    for (final option in exercise.options) {
      if (option.latexExpression.isEmpty ||
          !ErrorHandler.isValidLatexExpression(option.latexExpression)) {
        ErrorHandler.logError(
          'Matching validation',
          'Invalid option LaTeX: ${option.latexExpression}',
        );
        return false;
      }
    }

    return true;
  }

  /// Validate completion exercise specific requirements
  bool _validateCompletionExercise(Exercise exercise) {
    // Question should contain a blank placeholder
    if (!exercise.question.contains('\\underline{\\hspace{2cm}}')) {
      ErrorHandler.logError(
        'Completion validation',
        'Question missing blank placeholder',
      );
      return false;
    }

    // All options should have valid LaTeX expressions
    for (final option in exercise.options) {
      if (option.latexExpression.isEmpty ||
          !ErrorHandler.isValidLatexExpression(option.latexExpression)) {
        ErrorHandler.logError(
          'Completion validation',
          'Invalid option LaTeX: ${option.latexExpression}',
        );
        return false;
      }
    }

    return true;
  }
}
