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
          // 改进后的公式展示区域 - 强化"主角"地位
          _buildFormulaDisplay(),

          const SizedBox(height: 16), // 缩小间距
          // 改进后的引导文字 - 弱化辅助说明
          Text(
            '这是什么公式?',
            style: TextStyle(
              fontSize: 16, // 调小字号
              color: Colors.grey[600], // 使用更柔和的颜色
              fontWeight: FontWeight.normal, // 取消加粗
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 将选项包裹在 Expanded 中，使其填充可用空间
          Expanded(child: SingleChildScrollView(child: _buildNameOptions())),

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
    return Card(
      elevation: 6, // 增加阴影，使其更突出
      margin: const EdgeInsets.all(24.0), // 增加外边距
      // 使用主题颜色，更好地适配深色/浅色模式
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0), // 增加内边距，提供更多呼吸空间
        child: FormulaRenderer(
          latexExpression: widget.exercise.formula.latexExpression,
          semanticDescription: widget.exercise.formula.semanticDescription,
          fontSize: 32, // 增大公式字号，强化焦点
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

        // 使用主题颜色
        Color? borderColor;
        Color? backgroundColor;

        if (isCorrect) {
          borderColor = Colors.green;
          backgroundColor = Colors.green.withAlpha(26);
        } else if (isIncorrect) {
          borderColor = Theme.of(context).colorScheme.error;
          backgroundColor = Theme.of(context).colorScheme.error.withAlpha(26);
        } else if (isSelected) {
          borderColor = Theme.of(context).colorScheme.primary;
          backgroundColor = Theme.of(context).colorScheme.primary.withAlpha(26);
        } else if (isFocused) {
          borderColor = Colors.orange;
          backgroundColor = Colors.orange.withAlpha(26);
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      color: (borderColor ?? Colors.grey).withOpacity(0.3),
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
                              ? Theme.of(context).colorScheme.primary
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
                    if (!widget.showFeedback) const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.textLabel,
                        style: TextStyle(
                          fontSize: 18, // 保持适中的字号
                          fontWeight: isSelected || isCorrect || isFocused
                              ? FontWeight
                                    .w600 // 使用 w600 (semi-bold) 替代 w700 (bold)
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
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
