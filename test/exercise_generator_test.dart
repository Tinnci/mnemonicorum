import 'package:flutter_test/flutter_test.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/services/exercise_generator.dart';

void main() {
  late ExerciseGenerator exerciseGenerator;
  late Formula testFormula;
  late List<Formula> allFormulas;

  setUp(() {
    exerciseGenerator = ExerciseGenerator();

    // Create a test formula with components
    testFormula = Formula(
      id: 'test_formula_1',
      name: 'Pythagorean Identity',
      latexExpression: '\\sin^2 x + \\cos^2 x = 1',
      category: 'trigonometry',
      subcategory: 'identities',
      difficulty: DifficultyLevel.medium,
      tags: ['identity', 'trigonometry'],
      description: 'The fundamental trigonometric identity',
      semanticDescription: 'Sine squared plus cosine squared equals one',
      components: [
        FormulaComponent(
          id: 'left_side',
          latexPart: '\\sin^2 x + \\cos^2 x',
          type: ComponentType.leftSide,
          description: 'Sine squared plus cosine squared',
        ),
        FormulaComponent(
          id: 'right_side',
          latexPart: '1',
          type: ComponentType.rightSide,
          description: 'One',
        ),
      ],
    );

    // Create additional formulas for distractor generation
    final testFormula2 = Formula(
      id: 'test_formula_2',
      name: 'Double Angle Formula',
      latexExpression: '\\sin 2x = 2\\sin x \\cos x',
      category: 'trigonometry',
      subcategory: 'identities',
      difficulty: DifficultyLevel.medium,
      tags: ['identity', 'trigonometry'],
      description: 'Double angle formula for sine',
      semanticDescription:
          'Sine of two x equals two times sine of x times cosine of x',
      components: [
        FormulaComponent(
          id: 'left_side_2',
          latexPart: '\\sin 2x',
          type: ComponentType.leftSide,
          description: 'Sine of two x',
        ),
        FormulaComponent(
          id: 'right_side_2',
          latexPart: '2\\sin x \\cos x',
          type: ComponentType.rightSide,
          description: 'Two times sine of x times cosine of x',
        ),
      ],
    );

    final testFormula3 = Formula(
      id: 'test_formula_3',
      name: 'Cosine Double Angle Formula',
      latexExpression: '\\cos 2x = \\cos^2 x - \\sin^2 x',
      category: 'trigonometry',
      subcategory: 'identities',
      difficulty: DifficultyLevel.medium,
      tags: ['identity', 'trigonometry'],
      description: 'Double angle formula for cosine',
      semanticDescription:
          'Cosine of two x equals cosine squared of x minus sine squared of x',
      components: [
        FormulaComponent(
          id: 'left_side_3',
          latexPart: '\\cos 2x',
          type: ComponentType.leftSide,
          description: 'Cosine of two x',
        ),
        FormulaComponent(
          id: 'right_side_3',
          latexPart: '\\cos^2 x - \\sin^2 x',
          type: ComponentType.rightSide,
          description: 'Cosine squared of x minus sine squared of x',
        ),
      ],
    );

    allFormulas = [testFormula, testFormula2, testFormula3];
  });

  group('ExerciseGenerator - Recognition Exercise Tests', () {
    test('generateRecognitionExercise should create valid exercise', () {
      final exercise = exerciseGenerator.generateRecognitionExercise(
        testFormula,
        allFormulas,
      );

      // Verify exercise properties
      expect(exercise.type, equals(ExerciseType.recognition));
      expect(exercise.formula, equals(testFormula));
      expect(exercise.question, equals(testFormula.latexExpression));
      expect(exercise.correctAnswerId, equals(testFormula.id));

      // Verify options
      expect(exercise.options.length, equals(4)); // 1 correct + 3 distractors

      // Verify there's exactly one correct option
      final correctOptions = exercise.options
          .where((opt) => opt.isCorrect)
          .toList();
      expect(correctOptions.length, equals(1));
      expect(correctOptions.first.textLabel, equals(testFormula.name));

      // Verify distractors are different from correct answer
      final distractors = exercise.options
          .where((opt) => !opt.isCorrect)
          .toList();
      for (final distractor in distractors) {
        expect(distractor.textLabel, isNot(equals(testFormula.name)));
      }
    });

    test(
      'generateRecognitionExercise should handle insufficient distractors',
      () {
        // Test with only one formula (not enough for distractors)
        final exercise = exerciseGenerator.generateRecognitionExercise(
          testFormula,
          [testFormula],
        );

        // Should still generate 4 options (1 correct + 3 generated distractors)
        expect(exercise.options.length, equals(4));

        // Verify there's exactly one correct option
        final correctOptions = exercise.options
            .where((opt) => opt.isCorrect)
            .toList();
        expect(correctOptions.length, equals(1));
      },
    );
  });

  group('ExerciseGenerator - Matching Exercise Tests', () {
    test('generateMatchingExercise should create valid exercise', () {
      final exercise = exerciseGenerator.generateMatchingExercise(
        testFormula,
        allFormulas,
      );

      // Verify exercise properties
      expect(exercise.type, equals(ExerciseType.matching));
      expect(exercise.formula, equals(testFormula));

      // Question should be the left side component
      expect(exercise.question, equals(testFormula.components.first.latexPart));

      // Correct answer should be the right side component
      expect(exercise.correctAnswerId, equals(testFormula.components.last.id));

      // Verify options
      expect(exercise.options.length, equals(4)); // 1 correct + 3 distractors

      // Verify there's exactly one correct option
      final correctOptions = exercise.options
          .where((opt) => opt.isCorrect)
          .toList();
      expect(correctOptions.length, equals(1));
      expect(
        correctOptions.first.latexExpression,
        equals(testFormula.components.last.latexPart),
      );

      // Verify distractors are different from correct answer
      final correctLatex = correctOptions.first.latexExpression;
      final distractors = exercise.options
          .where((opt) => !opt.isCorrect)
          .toList();
      for (final distractor in distractors) {
        expect(distractor.latexExpression, isNot(equals(correctLatex)));
      }
    });
  });

  group('ExerciseGenerator - Completion Exercise Tests', () {
    test('generateCompletionExercise should create valid exercise', () {
      final exercise = exerciseGenerator.generateCompletionExercise(
        testFormula,
        allFormulas,
      );

      // Verify exercise properties
      expect(exercise.type, equals(ExerciseType.completion));
      expect(exercise.formula, equals(testFormula));

      // Question should contain the placeholder
      expect(exercise.question.contains('\\underline{\\hspace{2cm}}'), isTrue);

      // Verify options
      expect(exercise.options.length, equals(4)); // 1 correct + 3 distractors

      // Verify there's exactly one correct option
      final correctOptions = exercise.options
          .where((opt) => opt.isCorrect)
          .toList();
      expect(correctOptions.length, equals(1));

      // Verify distractors are different from correct answer
      final correctLatex = correctOptions.first.latexExpression;
      final distractors = exercise.options
          .where((opt) => !opt.isCorrect)
          .toList();
      for (final distractor in distractors) {
        expect(distractor.latexExpression, isNot(equals(correctLatex)));
      }
    });
  });

  group('ExerciseGenerator - Multi-Matching Exercise Tests', () {
    test('generateMultiMatchingExercise should create valid exercise', () {
      final exercise = exerciseGenerator.generateMultiMatchingExercise(
        allFormulas: allFormulas,
        pairCount: 2, // Generate 2 pairs (4 options total)
      );

      // Verify exercise properties
      expect(exercise.type, equals(ExerciseType.multiMatching));

      // Verify options
      expect(exercise.options.length, equals(4)); // 2 pairs = 4 options

      // Verify pairs
      final pairIds = exercise.options.map((opt) => opt.pairId).toSet();
      expect(pairIds.length, equals(2)); // Should have 2 unique pair IDs

      // Each pair ID should appear exactly twice
      for (final pairId in pairIds) {
        final pairOptions = exercise.options
            .where((opt) => opt.pairId == pairId)
            .toList();
        expect(pairOptions.length, equals(2));

        // One should have a name (textLabel) and one should have a formula (latexExpression)
        expect(
          pairOptions.where((opt) => opt.textLabel.isNotEmpty).length,
          equals(1),
        );
        expect(
          pairOptions.where((opt) => opt.latexExpression.isNotEmpty).length,
          equals(1),
        );
      }
    });
  });
}
