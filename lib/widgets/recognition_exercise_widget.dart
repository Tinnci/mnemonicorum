import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

class RecognitionExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(String selectedOptionId) onOptionSelected;
  final bool showFeedback;
  final String? selectedOptionId;
  final String? correctAnswerId;

  const RecognitionExerciseWidget({
    super.key,
    required this.exercise,
    required this.onOptionSelected,
    this.showFeedback = false,
    this.selectedOptionId,
    this.correctAnswerId,
  });

  @override
  State<RecognitionExerciseWidget> createState() =>
      _RecognitionExerciseWidgetState();
}

class _RecognitionExerciseWidgetState extends State<RecognitionExerciseWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question: Display the complete formula
        FormulaRenderer(
          latexExpression: widget.exercise.formula.latexExpression,
          semanticDescription: widget.exercise.formula.semanticDescription,
          fontSize: 30,
        ),
        const SizedBox(height: 40),
        // Options (formula names/types)
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
                child: Text(
                  option.textLabel,
                  style: TextStyle(
                    fontSize: 24,
                    color: isCorrect
                        ? Colors.green.shade900
                        : isIncorrect
                        ? Colors.red.shade900
                        : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
