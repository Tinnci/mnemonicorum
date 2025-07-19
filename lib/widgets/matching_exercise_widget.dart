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

  /// Get appropriate relation symbol based on formula type
  String _getRelationSymbol() {
    final formula = widget.exercise.formula;

    // Check if the original formula contains an equals sign
    if (formula.latexExpression.contains('=')) {
      return '=';
    }

    // For trigonometric identities and equations
    if (formula.category == 'trigonometry' &&
        (formula.subcategory == 'identities' ||
            formula.tags.contains('identity'))) {
      return '=';
    }

    // For calculus formulas (derivatives, integrals, series)
    if (formula.category == 'calculus') {
      if (formula.subcategory == 'integration' ||
          formula.subcategory == 'series') {
        return '=';
      }
      // For approximations or limits
      if (formula.tags.contains('approximation') ||
          formula.tags.contains('limit')) {
        return '\\approx';
      }
    }

    // For physics formulas
    if (formula.category == 'physics') {
      return '=';
    }

    // For algebraic expressions that might be equivalences
    if (formula.category == 'algebra') {
      if (formula.tags.contains('identity') ||
          formula.tags.contains('equation')) {
        return '=';
      }
      // For factorizations or transformations
      return '\\equiv';
    }

    // Default to equals for most mathematical relationships
    return '=';
  }

  @override
  Widget build(BuildContext context) {
    final questionFormulaComponent = widget.exercise.formula.components
        .firstWhere((comp) => comp.latexPart == widget.exercise.question);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2), // 顶部留白
            // 问题区域：分栏对齐设计
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：题目已知部分
                FormulaRenderer(
                  latexExpression: questionFormulaComponent.latexPart,
                  semanticDescription: questionFormulaComponent.description,
                  fontSize: 28,
                ),
                const SizedBox(width: 16),

                // 中间：突出的关系符号
                FormulaRenderer(
                  latexExpression: _getRelationSymbol(),
                  semanticDescription: "等于",
                  fontSize: 40, // 放大等号
                ),
                const SizedBox(width: 16),

                // 右侧：目标区域（虚线框占位符）
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: const Text(
                    '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 1), // 中间留白

            Text(
              "请选择正确的部分来完成等式",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 选项区域 - 使用Expanded填充剩余空间
            Expanded(
              flex: 8, // 分配更多空间给选项
              child: SingleChildScrollView(
                child: Column(
                  children: widget.exercise.options.asMap().entries.map((
                    entry,
                  ) {
                    final int index = entry.key;
                    final option = entry.value;
                    final bool isSelected =
                        widget.selectedOptionId == option.id;
                    final bool isFocused =
                        _focusedOptionIndex == index && !widget.showFeedback;
                    final bool isCorrect =
                        widget.showFeedback &&
                        option.id == widget.correctAnswerId;
                    final bool isIncorrect =
                        widget.showFeedback && isSelected && !isCorrect;

                    // 使用主题颜色
                    Color? borderColor;
                    Color? backgroundColor;

                    if (isCorrect) {
                      borderColor = Colors.green;
                      backgroundColor = Colors.green.withAlpha(26);
                    } else if (isIncorrect) {
                      borderColor = Theme.of(context).colorScheme.error;
                      backgroundColor = Theme.of(
                        context,
                      ).colorScheme.error.withAlpha(26);
                    } else if (isSelected) {
                      borderColor = Theme.of(context).colorScheme.primary;
                      backgroundColor = Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(26);
                    } else if (isFocused) {
                      borderColor = Colors.orange;
                      backgroundColor = Colors.orange.withAlpha(26);
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor ?? Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: backgroundColor,
                        boxShadow: isSelected || isFocused
                            ? [
                                BoxShadow(
                                  color: (borderColor ?? Colors.grey)
                                      .withValues(alpha: (0.3)),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: widget.showFeedback
                              ? null
                              : () => widget.onOptionSelected(option.id),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                if (!widget.showFeedback)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isFocused
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isFocused
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isFocused
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!widget.showFeedback)
                                  const SizedBox(width: 16),
                                Expanded(
                                  child: FormulaRenderer(
                                    latexExpression: option.latexExpression,
                                    semanticDescription: option.textLabel,
                                    fontSize: 24, // 选项公式字号
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
