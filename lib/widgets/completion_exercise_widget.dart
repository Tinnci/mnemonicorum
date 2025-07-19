import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Keyboard navigation state
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
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowUp:
          setState(() {
            _focusedOptionIndex =
                (_focusedOptionIndex - 1) % widget.exercise.options.length;
            if (_focusedOptionIndex < 0) {
              _focusedOptionIndex = widget.exercise.options.length - 1;
            }
          });
          break;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.arrowDown:
          setState(() {
            _focusedOptionIndex =
                (_focusedOptionIndex + 1) % widget.exercise.options.length;
          });
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          _selectFocusedOption();
          break;
        case LogicalKeyboardKey.digit1:
          if (widget.exercise.options.isNotEmpty) {
            _selectOptionByIndex(0);
          }
          break;
        case LogicalKeyboardKey.digit2:
          if (widget.exercise.options.length >= 2) {
            _selectOptionByIndex(1);
          }
          break;
        case LogicalKeyboardKey.digit3:
          if (widget.exercise.options.length >= 3) {
            _selectOptionByIndex(2);
          }
          break;
        case LogicalKeyboardKey.digit4:
          if (widget.exercise.options.length >= 4) {
            _selectOptionByIndex(3);
          }
          break;
        case LogicalKeyboardKey.tab:
          // Tab to select the blank (if not already selected)
          if (_selectedBlankId == null) {
            final blankComponent = _findBlankComponent();
            if (blankComponent != null) {
              setState(() {
                _selectedBlankId = blankComponent.id;
              });
            }
          }
          break;
      }
    }
  }

  void _selectFocusedOption() {
    final option = widget.exercise.options[_focusedOptionIndex];
    final isUsed =
        _filledBlanks.containsValue(option.id) ||
        widget.selectedOptionId == option.id;

    if (!isUsed) {
      // Auto-select blank if none selected
      if (_selectedBlankId == null) {
        final blankComponent = _findBlankComponent();
        if (blankComponent != null) {
          _selectedBlankId = blankComponent.id;
        }
      }

      if (_selectedBlankId != null) {
        setState(() {
          _filledBlanks[_selectedBlankId!] = option.id;
          _selectedBlankId = null;
        });
        widget.onOptionSelected(option.id);
      }
    }
  }

  void _selectOptionByIndex(int index) {
    if (index < widget.exercise.options.length) {
      setState(() {
        _focusedOptionIndex = index;
      });
      _selectFocusedOption();
    }
  }

  dynamic _findBlankComponent() {
    final components = widget.exercise.formula.components;
    if (components.isEmpty) return null;

    return components.firstWhere(
      (comp) => widget.exercise.question.contains('\\underline{\\hspace{2cm}}'),
      orElse: () => components.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the formula with blanks
          _buildFormulaWithBlanks(),

          const SizedBox(height: 30),

          // Display the options
          _buildOptions(),
        ],
      ),
    );
  }

  Widget _buildFormulaWithBlanks() {
    // Get the formula components that need to be displayed
    final components = widget.exercise.formula.components;

    // Find the component that should be replaced with a blank
    if (components.isEmpty) {
      return const Center(
        child: Text(
          'Error: No formula components available',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    final blankComponent = components.firstWhere(
      (comp) => comp.id == widget.exercise.question,
      orElse: () => components.first,
    );

    // Create a wrapping row of formula parts with a blank space
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                    (comp) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: FormulaRenderer(
                        latexExpression: comp.latexPart,
                        semanticDescription: comp.description,
                      ),
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
                    (comp) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: FormulaRenderer(
                        latexExpression: comp.latexPart,
                        semanticDescription: comp.description,
                      ),
                    ),
                  ),
            ],
          ),
        ),
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
      children: widget.exercise.options.asMap().entries.map((entry) {
        final int index = entry.key;
        final option = entry.value;

        // Check if this option is already used in a blank
        final bool isUsed =
            _filledBlanks.containsValue(option.id) ||
            widget.selectedOptionId == option.id;
        final bool isFocused =
            _focusedOptionIndex == index && !widget.showFeedback;

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
        } else if (isFocused) {
          borderColor = Colors.orange;
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
                    : isFocused
                    ? Colors.orange.withAlpha(26)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.showFeedback && !isUsed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isFocused
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  FormulaRenderer(
                    latexExpression: option.latexExpression,
                    semanticDescription: option.textLabel,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
