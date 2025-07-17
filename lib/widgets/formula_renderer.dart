import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaRenderer extends StatelessWidget {
  final String latexExpression;
  final double fontSize;
  final Color textColor;
  final String semanticDescription;

  const FormulaRenderer({
    super.key,
    required this.latexExpression,
    this.fontSize = 24,
    this.textColor = Colors.black,
    this.semanticDescription = '',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticDescription.isNotEmpty
          ? semanticDescription
          : 'Mathematical formula: $latexExpression',
      child: Math.tex(
        latexExpression,
        textStyle: TextStyle(fontSize: fontSize, color: textColor),
        onErrorFallback: (error) {
          // Implement graceful degradation for malformed LaTeX expressions
          return Text(
            'Error rendering formula: $latexExpression',
            style: TextStyle(color: Colors.red, fontSize: fontSize),
          );
        },
      ),
    );
  }
}
