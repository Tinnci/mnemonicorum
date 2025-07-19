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
  // Track which blank is currently selected
  String? _selectedBlankId;

  // Map to track which option is placed in which blank
  final Map<String, String> _filledBlanks = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display the formula with blanks
        _buildFormulaWithBlanks(),

        const SizedBox(height: 30),

        // Display the options
        _buildOptions(),
      ],
    );
  }

  Widget _buildFormulaWithBlanks() {
    // Get the formula components that need to be displayed
    final components = widget.exercise.formula.components;

    // Find the component that should be replaced with a blank
    final blankComponent = components.firstWhere(
      (comp) => comp.id == widget.exercise.question,
    );

    // Create a row of formula parts with a blank space
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display components before the blank
          ...components
              .where(
                (comp) =>
                    comp.id != blankComponent.id &&
                    components.indexOf(comp) <
                        components.indexOf(blankComponent),
              )
              .map(
                (comp) => FormulaRenderer(
                  latexExpression: comp.latexPart,
                  semanticDescription: comp.description,
                ),
              ),

          // Display the blank or the selected option
          _buildBlankSpace(blankComponent),

          // Display components after the blank
          ...components
              .where(
                (comp) =>
                    comp.id != blankComponent.id &&
                    components.indexOf(comp) >
                        components.indexOf(blankComponent),
              )
              .map(
                (comp) => FormulaRenderer(
                  latexExpression: comp.latexPart,
                  semanticDescription: comp.description,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBlankSpace(dynamic blankComponent) {
    // Check if a selection has been made
    final selectedOptionId =
        widget.selectedOptionId ?? _filledBlanks[blankComponent.id];

    if (selectedOptionId != null) {
      // Find the selected option
      final selectedOption = widget.exercise.options.firstWhere(
        (option) => option.id == selectedOptionId,
      );

      // Determine if the answer is correct (only when showing feedback)
      final bool isCorrect =
          widget.showFeedback && selectedOptionId == widget.correctAnswerId;
      final bool isIncorrect =
          widget.showFeedback && selectedOptionId != widget.correctAnswerId;

      // Apply appropriate styling based on correctness
      Color borderColor = Colors.blue;
      if (isCorrect) {
        borderColor = Colors.green;
      } else if (isIncorrect) {
        borderColor = Colors.red;
      }

      // Display the selected option
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: isCorrect
              ? Colors.green.withAlpha(26)
              : isIncorrect
              ? Colors.red.withAlpha(26)
              : Colors.blue.withAlpha(26),
        ),
        child: FormulaRenderer(
          latexExpression: selectedOption.latexExpression,
          semanticDescription: selectedOption.textLabel,
        ),
      );
    } else {
      // Display an empty blank space
      return GestureDetector(
        onTap: () {
          if (!widget.showFeedback) {
            setState(() {
              _selectedBlankId = blankComponent.id;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedBlankId == blankComponent.id
                  ? Colors.blue
                  : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedBlankId == blankComponent.id
                ? Colors.blue.withAlpha(26)
                : null,
          ),
          child: const Text('?', style: TextStyle(fontSize: 24)),
        ),
      );
    }
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: widget.exercise.options.map((option) {
        // Check if this option is already used in a blank
        final bool isUsed =
            _filledBlanks.containsValue(option.id) ||
            widget.selectedOptionId == option.id;

        // Determine if the answer is correct (only when showing feedback)
        final bool isCorrect =
            widget.showFeedback && option.id == widget.correctAnswerId;
        final bool isIncorrect =
            widget.showFeedback &&
            widget.selectedOptionId == option.id &&
            option.id != widget.correctAnswerId;

        // Apply appropriate styling based on correctness and selection
        Color borderColor = Colors.grey;
        if (isCorrect) {
          borderColor = Colors.green;
        } else if (isIncorrect) {
          borderColor = Colors.red;
        }

        return GestureDetector(
          onTap: () {
            if (!widget.showFeedback && _selectedBlankId != null && !isUsed) {
              // Fill the selected blank with this option
              setState(() {
                _filledBlanks[_selectedBlankId!] = option.id;
                _selectedBlankId = null;
              });

              // Notify parent about the selection
              widget.onOptionSelected(option.id);
            }
          },
          child: Opacity(
            opacity: isUsed && !widget.showFeedback ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: isCorrect
                    ? Colors.green.withAlpha(26)
                    : isIncorrect
                    ? Colors.red.withAlpha(26)
                    : null,
              ),
              child: FormulaRenderer(
                latexExpression: option.latexExpression,
                semanticDescription: option.textLabel,
                fontSize: 20,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
