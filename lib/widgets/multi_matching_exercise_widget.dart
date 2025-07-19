import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

class MultiMatchingExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(String selectedOptionId) onOptionSelected;
  final bool showFeedback;
  final String? selectedOptionId;
  final String? correctAnswerId;

  const MultiMatchingExerciseWidget({
    super.key,
    required this.exercise,
    required this.onOptionSelected,
    this.showFeedback = false,
    this.selectedOptionId,
    this.correctAnswerId,
  });

  @override
  State<MultiMatchingExerciseWidget> createState() =>
      _MultiMatchingExerciseWidgetState();
}

class _MultiMatchingExerciseWidgetState
    extends State<MultiMatchingExerciseWidget> {
  ExerciseOption? _selectedOption;
  final Set<String> _matchedPairIds = {}; // 存放已匹配对的 pairId
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
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowRight:
          // 键盘导航逻辑可以在这里实现
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          // 选择当前焦点选项
          break;
      }
    }
  }

  void _onOptionTap(ExerciseOption option) {
    if (widget.showFeedback) return; // 反馈模式下不允许交互

    if (_matchedPairIds.contains(option.pairId)) {
      return; // 如果已经匹配，则不作任何反应
    }

    setState(() {
      if (_selectedOption == null) {
        // 这是第一次选择
        _selectedOption = option;
      } else {
        // 这是第二次选择，进行匹配判断
        if (_selectedOption!.pairId == option.pairId &&
            _selectedOption!.id != option.id) {
          // 匹配成功！
          _matchedPairIds.add(option.pairId);
          _selectedOption = null; // 清空选择

          // 检查是否所有配对都完成了
          final totalPairs = widget.exercise.options.length / 2;
          if (_matchedPairIds.length == totalPairs) {
            // 所有都匹配完成，通知父组件
            widget.onOptionSelected('completed');
          }
        } else {
          // 匹配失败
          _selectedOption = null; // 清空选择
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 题目说明
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.exercise.question,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // 匹配区域
          Expanded(child: _buildMatchingArea()),

          // 进度指示器
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '已匹配: ${_matchedPairIds.length}/${widget.exercise.options.length ~/ 2}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingArea() {
    final options = widget.exercise.options;
    // 将选项分为左右两列
    final List<ExerciseOption> leftColumn = options
        .where((o) => o.latexExpression.isEmpty)
        .toList();
    final List<ExerciseOption> rightColumn = options
        .where((o) => o.textLabel.isEmpty)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 左侧：公式名称
        Expanded(child: _buildColumn(leftColumn, '公式名称')),

        // 中间：连接线区域
        SizedBox(width: 100, child: _buildConnectionLines()),

        // 右侧：公式表达式
        Expanded(child: _buildColumn(rightColumn, '公式表达式')),
      ],
    );
  }

  Widget _buildColumn(List<ExerciseOption> options, String title) {
    return Column(
      children: [
        // 列标题
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // 选项列表
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              return _buildOptionCard(options[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(ExerciseOption option) {
    final bool isSelected = _selectedOption?.id == option.id;
    final bool isMatched = _matchedPairIds.contains(option.pairId);

    // 根据状态给卡片不同的样式
    Color cardColor;
    Color borderColor;

    if (isMatched) {
      cardColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
    } else if (isSelected) {
      cardColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
      borderColor = Theme.of(context).colorScheme.primary;
    } else {
      cardColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: isSelected || isMatched ? 4 : 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: () => _onOptionTap(option),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: option.textLabel.isNotEmpty
                  ? Text(
                      option.textLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected || isMatched
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : FormulaRenderer(
                      latexExpression: option.latexExpression,
                      semanticDescription: '公式表达式',
                      fontSize: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionLines() {
    // 这里可以添加连接线的可视化
    // 暂时返回一个占位符
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          '← 匹配 →',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }
}
