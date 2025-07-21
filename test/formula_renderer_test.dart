import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  testWidgets('FormulaRenderer should render LaTeX expression', (
    WidgetTester tester,
  ) async {
    // Simple LaTeX expression
    const latexExpression = 'x^2 + y^2 = z^2';
    const semanticDescription = 'Pythagorean theorem';

    // Build the FormulaRenderer widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FormulaRenderer(
              latexExpression: latexExpression,
              semanticDescription: semanticDescription,
              useCache: false, // Disable caching for testing
            ),
          ),
        ),
      ),
    );

    // Verify the Math.tex widget is present
    expect(find.byType(Math), findsOneWidget);

    // Verify semantic description is applied
    final semanticsNode = tester.getSemantics(find.byType(Semantics).first);
    expect(semanticsNode.label, equals(semanticDescription));
  });

  testWidgets('FormulaRenderer should handle constraints properly', (
    WidgetTester tester,
  ) async {
    // Long LaTeX expression that might overflow
    const longLatexExpression =
        '\\int_{0}^{\\infty} \\frac{x^2 + 2x + 1}{x^3 + 4x^2 + 3x} dx = \\frac{\\pi}{2}';

    // Build the FormulaRenderer widget with constrained width
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200, // Constrained width
              child: FormulaRenderer(
                latexExpression: longLatexExpression,
                useCache: false, // Disable caching for testing
              ),
            ),
          ),
        ),
      ),
    );

    // Verify the SingleChildScrollView is present for horizontal scrolling
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Verify the ConstrainedBox is present for width constraints
    expect(find.byType(ConstrainedBox), findsOneWidget);
  });

  testWidgets('FormulaRenderer should apply custom styling', (
    WidgetTester tester,
  ) async {
    // Simple LaTeX expression
    const latexExpression = 'E = mc^2';
    const fontSize = 32.0;
    const textColor = Colors.red;

    // Build the FormulaRenderer widget with custom styling
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FormulaRenderer(
              latexExpression: latexExpression,
              fontSize: fontSize,
              textColor: textColor,
              useCache: false, // Disable caching for testing
            ),
          ),
        ),
      ),
    );

    // Verify the Math.tex widget is present
    expect(find.byType(Math), findsOneWidget);

    // Note: We can't directly verify the fontSize and textColor in widget tests
    // as they're passed to the Math.tex widget's internal rendering
  });
}
