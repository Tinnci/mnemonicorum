import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

class CompletionExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(String selectedOptionId) onOptionSelected;
  final bool showFeedback;
  final String? selectedOptionId;
  final String? correctAnswerId;

  const CompletionExerciseWidget({
    super.key,
    required this.exercise,
    required this.onOptionSelected,
    this.showFeedback = false,
    this.selectedOptionId,
    this.correctAnswerId,
  });

  @override
  State<CompletionExerciseWidget> createState() =>
      _CompletionExerciseWidgetState();
}

class _CompletionExerciseWidgetState extends State<CompletionExerciseWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question: Display the partial formula with a blank
        FormulaRenderer(
          latexExpression: widget.exercise.question,
          fontSize: 30,
        ),
        const SizedBox(height: 40),
        // Options
        Column(
          children: widget.exercise.options.map((option) {
            final bool isSelected = widget.selectedOptionId == option.id;
            final bool isCorrect =
                widget.showFeedback && option.id == widget.correctAnswerId;
            final bool isIncorrect =
                widget.showFeedback && isSelected && !isCorrect;

            Color? borderColor;
            if (isCorrect) {
              borderColor = Colors.green;
            } else if (isIncorrect) {
              borderColor = Colors.red;
            } else if (isSelected) {
              borderColor = Colors.blue;
            }

            return GestureDetector(
              onTap: widget.showFeedback
                  ? null
                  : () => widget.onOptionSelected(option.id),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor ?? Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected && !widget.showFeedback
                      ? Colors.blue.withAlpha((255 * 0.1).round() & 0xFF)
                      : null,
                ),
                child: FormulaRenderer(
                  latexExpression: option.latexExpression,
                  semanticDescription: option.textLabel,
                  fontSize: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
