import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the complete formula
          _buildFormulaDisplay(),

          const SizedBox(height: 30),

          // Question prompt
          const Text(
            'What is this formula called?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Display the name options
          _buildNameOptions(),

          // Display explanation if showing feedback and answer is incorrect
          if (widget.showFeedback &&
              widget.selectedOptionId != null &&
              widget.selectedOptionId != widget.correctAnswerId)
            _buildExplanation(),
        ],
      ),
    );
  }

  Widget _buildFormulaDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FormulaRenderer(
            latexExpression: widget.exercise.formula.latexExpression,
            semanticDescription: widget.exercise.formula.semanticDescription,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildNameOptions() {
    return Column(
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
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor ?? Colors.grey, width: 2),
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
                  child: Text(
                    option.textLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected || isCorrect || isFocused
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExplanation() {
    // Find the correct option
    final correctOption = widget.exercise.options.firstWhere(
      (option) => option.id == widget.correctAnswerId,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explanation:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.exercise.explanation,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Text(
            'Correct answer: ${correctOption.textLabel}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
