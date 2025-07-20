import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemonicorum/models/exercise.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/services/gemini_service.dart';

/// AI增强的练习生成器
/// 结合传统算法和AI生成，提供更智能的练习题
class AIEnhancedExerciseGenerator {
  final Random _random = Random();
  final WidgetRef ref;

  AIEnhancedExerciseGenerator(this.ref);

  /// 使用AI生成干扰项，如果失败则回退到传统方法
  Future<List<ExerciseOption>> _generateDistractorsWithAI(
    Formula formula,
    FormulaComponent correctAnswer,
  ) async {
    try {
      final aiService = AIService(ref);
      final aiDistractors = await aiService.generateDistractorsWithAI(
        correctAnswerLatex: correctAnswer.latexPart,
        category: formula.category,
        difficulty: formula.difficulty.name,
      );

      if (aiDistractors.isNotEmpty) {
        return aiDistractors.map((distractor) {
          return ExerciseOption(
            id: 'ai_distractor_${DateTime.now().microsecondsSinceEpoch}_${_random.nextDouble()}',
            latexExpression: distractor['latexExpression']!,
            textLabel: distractor['description']!,
            isCorrect: false,
            pairId: '',
          );
        }).toList();
      }
    } catch (e) {
      developer.log(
        'AI干扰项生成失败，使用传统方法: $e',
        name: 'AIEnhancedExerciseGenerator',
      );
    }

    // 回退到传统方法
    return _generateTraditionalDistractors(formula, correctAnswer);
  }

  /// 传统的干扰项生成方法（作为回退）
  List<ExerciseOption> _generateTraditionalDistractors(
    Formula formula,
    FormulaComponent correctAnswer,
  ) {
    final distractors = <ExerciseOption>[];
    final usedLatex = <String>{correctAnswer.latexPart};

    // 策略1: 符号交换
    while (distractors.length < 3) {
      final swappedLatex = _applySymbolSwapping(correctAnswer.latexPart);
      if (!usedLatex.contains(swappedLatex)) {
        usedLatex.add(swappedLatex);
        distractors.add(
          ExerciseOption(
            id: 'swapped_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}',
            latexExpression: swappedLatex,
            textLabel: '变换后的表达式',
            isCorrect: false,
            pairId: '',
          ),
        );
      } else {
        // 回退: 轻微修改
        final modifiedLatex = _applyMinorModifications(correctAnswer.latexPart);
        if (!usedLatex.contains(modifiedLatex)) {
          usedLatex.add(modifiedLatex);
          distractors.add(
            ExerciseOption(
              id: 'modified_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}',
              latexExpression: modifiedLatex,
              textLabel: '修改后的表达式',
              isCorrect: false,
              pairId: '',
            ),
          );
        } else {
          // 最终回退: 创建通用干扰项
          final genericLatex = [
            'x',
            'y',
            'z',
            'a',
            'b',
            'c',
            '1',
            '0',
            '\\alpha',
            '\\beta',
            '\\gamma',
            '\\theta',
          ];

          final genericLatexExpr =
              genericLatex[_random.nextInt(genericLatex.length)];
          final uniqueId =
              'generic_${DateTime.now().microsecondsSinceEpoch}_${distractors.length}';

          if (!usedLatex.contains(genericLatexExpr)) {
            usedLatex.add(genericLatexExpr);
            distractors.add(
              ExerciseOption(
                id: uniqueId,
                latexExpression: genericLatexExpr,
                textLabel: '通用表达式',
                isCorrect: false,
                pairId: '',
              ),
            );
          } else {
            break; // 避免无限循环
          }
        }
      }
    }

    return distractors.take(3).toList();
  }

  /// 生成匹配练习（使用AI增强）
  Future<Exercise> generateMatchingExercise(
    Formula formula,
    List<Formula> allFormulas,
  ) async {
    if (formula.components.length < 2) {
      throw ArgumentError(
        'Formula must have at least two components for matching exercise',
      );
    }

    // 使用公式的关键组件（通常是leftSide）作为问题
    final questionComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.leftSide,
      orElse: () => formula.components.first,
    );

    // 使用公式的对应部分（通常是rightSide）作为正确答案
    final correctAnswerComponent = formula.components.firstWhere(
      (c) => c.type == ComponentType.rightSide,
      orElse: () => formula.components.last,
    );

    final correctOption = ExerciseOption(
      id: correctAnswerComponent.id,
      latexExpression: correctAnswerComponent.latexPart,
      textLabel: correctAnswerComponent.description,
      isCorrect: true,
      pairId: '',
    );

    // 使用AI生成干扰项
    final distractors = await _generateDistractorsWithAI(
      formula,
      correctAnswerComponent,
    );

    final options = [correctOption, ...distractors];
    options.shuffle(_random);

    return Exercise(
      id: '${formula.id}_matching_ai_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.matching,
      question: questionComponent.latexPart,
      options: options,
      correctAnswerId: correctAnswerComponent.id,
      explanation: '这是 ${formula.name} 的正确匹配部分。',
    );
  }

  /// 生成填空练习（使用AI增强）
  Future<Exercise> generateCompletionExercise(
    Formula formula,
    List<Formula> allFormulas,
  ) async {
    if (formula.components.isEmpty) {
      throw ArgumentError(
        'Formula must have components for completion exercise',
      );
    }

    // 随机选择一个关键FormulaComponent作为空白
    final blankedComponent =
        formula.components[_random.nextInt(formula.components.length)];

    // 在latexExpression中用占位符替换相应部分形成问题
    final questionLatex = formula.latexExpression.replaceAll(
      blankedComponent.latexPart,
      '\\underline{\\hspace{2cm}}',
    );

    // 使用空白组件的latexPart作为正确答案
    final correctOption = ExerciseOption(
      id: blankedComponent.id,
      latexExpression: blankedComponent.latexPart,
      textLabel: blankedComponent.description,
      isCorrect: true,
      pairId: '',
    );

    // 使用AI生成干扰项
    final distractors = await _generateDistractorsWithAI(
      formula,
      blankedComponent,
    );

    final options = [correctOption, ...distractors];
    options.shuffle(_random);

    return Exercise(
      id: '${formula.id}_completion_ai_${DateTime.now().millisecondsSinceEpoch}',
      formula: formula,
      type: ExerciseType.completion,
      question: questionLatex,
      options: options,
      correctAnswerId: blankedComponent.id,
      explanation: '这是 ${formula.name} 中缺失的部分。',
    );
  }

  /// 符号交换策略
  String _applySymbolSwapping(String latex) {
    String result = latex;

    // 变量交换
    final variableSwaps = {
      'x': 'y',
      'y': 'x',
      'z': 'w',
      'w': 'z',
      'a': 'b',
      'b': 'a',
      'c': 'd',
      'd': 'c',
      'u': 'v',
      'v': 'u',
      't': 's',
      's': 't',
    };

    // 运算符交换
    final operatorSwaps = {
      '+': '-',
      '-': '+',
      '\\times': '\\div',
      '\\div': '\\times',
      '\\sin': '\\cos',
      '\\cos': '\\sin',
      '\\tan': '\\cot',
      '\\cot': '\\tan',
    };

    // 应用变量交换
    for (final entry in variableSwaps.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // 应用运算符交换（只交换一次）
    for (final entry in operatorSwaps.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceFirst(entry.key, entry.value);
        break; // 只交换一个运算符
      }
    }

    return result;
  }

  /// 轻微修改策略
  String _applyMinorModifications(String latex) {
    String result = latex;

    // 添加或删除符号
    if (result.contains('x')) {
      result = result.replaceFirst('x', 'x^2');
    } else if (result.contains('\\sin')) {
      result = result.replaceFirst('\\sin', '\\sin^2');
    } else if (result.contains('\\cos')) {
      result = result.replaceFirst('\\cos', '\\cos^2');
    } else {
      // 添加常数
      result = '$result + 1';
    }

    return result;
  }

  /// 获取AI解释（用于错误答案分析）
  Future<String> getAIExplanation({
    required Exercise exercise,
    required String userAnswerId,
  }) async {
    try {
      final aiService = AIService(ref);
      final incorrectOption = exercise.options.firstWhere(
        (opt) => opt.id == userAnswerId,
      );
      final correctOption = exercise.options.firstWhere((opt) => opt.isCorrect);

      return await aiService.analyzeIncorrectAnswer(
        questionLatex: exercise.question,
        correctAnswerLatex: correctOption.latexExpression,
        userAnswerLatex: incorrectOption.latexExpression,
      );
    } catch (e) {
      developer.log('AI解释生成失败: $e', name: 'AIEnhancedExerciseGenerator');
      return "抱歉，分析答案时遇到错误。";
    }
  }
}
