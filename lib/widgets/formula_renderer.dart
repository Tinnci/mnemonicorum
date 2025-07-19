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
    // Wrap in LayoutBuilder to handle constraints properly
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate maximum width, leaving some padding
        final maxWidth = constraints.maxWidth == double.infinity
            ? MediaQuery.of(context).size.width - 32
            : constraints.maxWidth;

        Widget formulaWidget;

        // Use the cached version for better performance if enabled
        if (useCache) {
          formulaWidget = LatexRendererUtils.getCachedFormulaWidget(
            latexExpression: latexExpression,
            fontSize: fontSize,
            textColor: textColor,
            semanticDescription: semanticDescription,
          );
        } else {
          // Otherwise use direct rendering
          formulaWidget = Semantics(
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

        // Wrap with constraints to prevent overflow
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: constraints.maxHeight == double.infinity
                ? MediaQuery.of(context).size.height * 0.3
                : constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: formulaWidget,
          ),
        );
      },
    );
  }
}
