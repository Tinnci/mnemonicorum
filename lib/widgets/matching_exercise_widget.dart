import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

class MatchingExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(String selectedOptionId) onOptionSelected;
  final bool showFeedback;
  final String? selectedOptionId;
  final String? correctAnswerId;

  const MatchingExerciseWidget({
    super.key,
    required this.exercise,
    required this.onOptionSelected,
    this.showFeedback = false,
    this.selectedOptionId,
    this.correctAnswerId,
  });

  @override
  State<MatchingExerciseWidget> createState() => _MatchingExerciseWidgetState();
}

class _MatchingExerciseWidgetState extends State<MatchingExerciseWidget> {
  int _focusedOptionIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && !widget.showFeedback) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          setState(() {
            _focusedOptionIndex =
                (_focusedOptionIndex - 1) % widget.exercise.options.length;
            if (_focusedOptionIndex < 0) {
              _focusedOptionIndex = widget.exercise.options.length - 1;
            }
          });
          break;
        case LogicalKeyboardKey.arrowDown:
          setState(() {
            _focusedOptionIndex =
                (_focusedOptionIndex + 1) % widget.exercise.options.length;
          });
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          final selectedOption = widget.exercise.options[_focusedOptionIndex];
          widget.onOptionSelected(selectedOption.id);
          break;
        case LogicalKeyboardKey.digit1:
          if (widget.exercise.options.isNotEmpty) {
            widget.onOptionSelected(widget.exercise.options[0].id);
          }
          break;
        case LogicalKeyboardKey.digit2:
          if (widget.exercise.options.length >= 2) {
            widget.onOptionSelected(widget.exercise.options[1].id);
          }
          break;
        case LogicalKeyboardKey.digit3:
          if (widget.exercise.options.length >= 3) {
            widget.onOptionSelected(widget.exercise.options[2].id);
          }
          break;
        case LogicalKeyboardKey.digit4:
          if (widget.exercise.options.length >= 4) {
            widget.onOptionSelected(widget.exercise.options[3].id);
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionFormulaComponent = widget.exercise.formula.components
        .firstWhere((comp) => comp.latexPart == widget.exercise.question);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question: Display the left side or a component of the formula
          FormulaRenderer(
            latexExpression: questionFormulaComponent.latexPart,
            semanticDescription: questionFormulaComponent.description,
            fontSize: 30,
          ),
          const SizedBox(height: 40),
          // Options
          Column(
            children: widget.exercise.options.asMap().entries.map((entry) {
              final int index = entry.key;
              final option = entry.value;
              final bool isSelected = widget.selectedOptionId == option.id;
              final bool isFocused =
                  _focusedOptionIndex == index && !widget.showFeedback;
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
              } else if (isFocused) {
                borderColor = Colors.orange;
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
                        ? Colors.blue.withAlpha(26)
                        : isCorrect
                        ? Colors.green.withAlpha(26)
                        : isIncorrect
                        ? Colors.red.withAlpha(26)
                        : isFocused
                        ? Colors.orange.withAlpha(26)
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (!widget.showFeedback)
                        Text(
                          '${index + 1}. ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isFocused
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                        ),
                      Expanded(
                        child: FormulaRenderer(
                          latexExpression: option.latexExpression,
                          semanticDescription: option.textLabel,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
