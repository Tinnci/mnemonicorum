import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/widgets/matching_exercise_widget.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

void main() {
  late Exercise testExercise;

  setUp(() {
    // Create a test formula with components
    final testFormula = Formula(
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

    // Create test exercise options
    final correctOption = ExerciseOption(
      id: 'right_side',
      latexExpression: '1',
      textLabel: 'One',
      isCorrect: true,
      pairId: '',
    );

    final distractor1 = ExerciseOption(
      id: 'distractor_1',
      latexExpression: '0',
      textLabel: 'Zero',
      isCorrect: false,
      pairId: '',
    );

    final distractor2 = ExerciseOption(
      id: 'distractor_2',
      latexExpression: '\\sin x',
      textLabel: 'Sine of x',
      isCorrect: false,
      pairId: '',
    );

    final distractor3 = ExerciseOption(
      id: 'distractor_3',
      latexExpression: '\\cos x',
      textLabel: 'Cosine of x',
      isCorrect: false,
      pairId: '',
    );

    // Create test exercise
    testExercise = Exercise(
      id: 'test_exercise_1',
      formula: testFormula,
      type: ExerciseType.matching,
      question: '\\sin^2 x + \\cos^2 x',
      options: [correctOption, distractor1, distractor2, distractor3],
      correctAnswerId: 'right_side',
      explanation: 'This is the Pythagorean identity.',
    );
  });

  testWidgets('MatchingExerciseWidget should display question and options', (
    WidgetTester tester,
  ) async {
    // Track selected option
    String? selectedOptionId;

    // Build the MatchingExerciseWidget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchingExerciseWidget(
            exercise: testExercise,
            onOptionSelected: (optionId) {
              selectedOptionId = optionId;
            },
          ),
        ),
      ),
    );

    // Wait for any animations to complete
    await tester.pumpAndSettle();

    // Verify FormulaRenderer widgets are present (question + options)
    expect(find.byType(FormulaRenderer), findsAtLeast(2));

    // Verify the question is displayed
    expect(find.text('请选择正确的部分来完成等式'), findsOneWidget);

    // Verify option numbers are displayed (1, 2, 3, 4)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Tap on the first option
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // Verify the option was selected
    expect(selectedOptionId, isNotNull);
  });

  testWidgets(
    'MatchingExerciseWidget should show feedback when showFeedback is true',
    (WidgetTester tester) async {
      // Build the MatchingExerciseWidget with feedback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchingExerciseWidget(
              exercise: testExercise,
              onOptionSelected: (_) {},
              showFeedback: true,
              selectedOptionId: 'distractor_1', // Selected wrong answer
              correctAnswerId: 'right_side',
            ),
          ),
        ),
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // In feedback mode, option numbers should not be displayed
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsNothing);

      // Verify FormulaRenderer widgets are still present
      expect(find.byType(FormulaRenderer), findsAtLeast(2));
    },
  );
}
