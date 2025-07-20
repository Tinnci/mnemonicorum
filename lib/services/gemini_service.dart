import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_service.g.dart';

// 提供 system_prompt 内容
@riverpod
Future<String> systemPrompt(SystemPromptRef ref) async {
  return await rootBundle.loadString('assets/prompts/system_prompt.md');
}

// 提供 Gemini 模型
@riverpod
Future<GenerativeModel> geminiModel(GeminiModelRef ref) async {
  await Firebase.initializeApp();
  final systemPromptText = await ref.watch(systemPromptProvider.future);

  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',
    systemInstruction: Content.system(systemPromptText),
  );
  return model;
}

// AI服务类，封装AI相关操作
class AIService {
  final WidgetRef ref;

  AIService(this.ref);

  /// 使用AI生成干扰项
  Future<List<Map<String, String>>> generateDistractorsWithAI({
    required String correctAnswerLatex,
    required String category,
    required String difficulty,
  }) async {
    try {
      final model = await ref.read(geminiModelProvider.future);

      // 让AI直接在文本中返回JSON格式的选项
      final refinedResponse = await model.generateContent([
        Content.text(
          '请为LaTeX表达式 `$correctAnswerLatex` 生成3个结构相似但错误的干扰项。'
          '公式类别是 "$category"。'
          '以JSON数组格式返回，每个对象包含 "latexExpression" 和 "description" 字段。'
          '例如: [{"latexExpression": "...", "description": "..."}, ...]',
        ),
      ]);

      final responseText = refinedResponse.text;
      if (responseText != null) {
        try {
          // 尝试从响应中提取JSON
          final jsonMatch = RegExp(r'\[.*\]').firstMatch(responseText);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            final optionsJson = json.decode(jsonStr) as List;
            return optionsJson.map((optJson) {
              return {
                'latexExpression': optJson['latexExpression'] as String,
                'description': optJson['description'] as String,
              };
            }).toList();
          }
        } catch (e) {
          developer.log('JSON解析失败: $e', name: 'AIService');
        }
      }
    } catch (e) {
      developer.log('AI干扰项生成失败: $e', name: 'AIService');
    }

    // 返回空列表作为回退
    return [];
  }

  /// 使用AI分析错误答案
  Future<String> analyzeIncorrectAnswer({
    required String questionLatex,
    required String correctAnswerLatex,
    required String userAnswerLatex,
  }) async {
    try {
      final model = await ref.read(geminiModelProvider.future);

      final response = await model.generateContent([
        Content.text(
          '用户在一道数学题中选错了答案。请分析原因并提供简单的解释。\n'
          '题目: `$questionLatex`\n'
          '正确答案: `$correctAnswerLatex`\n'
          '用户的错误答案: `$userAnswerLatex`\n'
          '请用中文回答，解释为什么这个答案是错误的，以及正确的思路是什么。',
        ),
      ]);

      return response.text ?? "无法生成解释，请检查公式并重试。";
    } catch (e) {
      developer.log('AI解释生成失败: $e', name: 'AIService');
      return "抱歉，分析答案时遇到错误。";
    }
  }
}
