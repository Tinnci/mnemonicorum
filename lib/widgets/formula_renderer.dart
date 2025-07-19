import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:mnemonicorum/utils/latex_renderer_utils.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

class FormulaRenderer extends StatelessWidget {
  final String latexExpression;
  final double fontSize;
  final Color textColor;
  final String semanticDescription;
  final bool useCache;

  const FormulaRenderer({
    super.key,
    required this.latexExpression,
    this.fontSize = 24,
    this.textColor = Colors.black,
    this.semanticDescription = '',
    this.useCache = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use the cached version for better performance if enabled
    if (useCache) {
      return LatexRendererUtils.getCachedFormulaWidget(
        latexExpression: latexExpression,
        fontSize: fontSize,
        textColor: textColor,
        semanticDescription: semanticDescription,
      );
    }

    // Otherwise use direct rendering
    return Semantics(
      label: semanticDescription.isNotEmpty
          ? semanticDescription
          : 'Mathematical formula: $latexExpression',
      child: Math.tex(
        latexExpression,
        textStyle: TextStyle(fontSize: fontSize, color: textColor),
        onErrorFallback: (error) {
          // Use comprehensive error handling for LaTeX parsing errors
          return GestureDetector(
            onTap: () {
              // Retry rendering when user taps
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
            child: ErrorHandler.handleLatexError(
              latexExpression,
              error,
              fontSize: fontSize,
              textColor: textColor,
            ),
          );
        },
      ),
    );
  }
}
