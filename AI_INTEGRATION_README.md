# AI 集成指南 - Mnemonicorum 数学公式记忆应用

本指南详细说明如何将 Firebase AI (Gemini) 集成到您的数学公式记忆应用中，以实现智能练习生成和错误分析功能。

## 🚀 功能特性

### 已实现的AI功能

1. **智能干扰项生成**: 使用AI生成具有迷惑性的错误选项，替代传统的符号交换方法
2. **错误答案分析**: 当用户答错时，AI提供详细的错误分析和正确思路
3. **个性化练习**: 根据公式类别和难度级别生成相应的练习题
4. **优雅降级**: 如果AI服务不可用，自动回退到传统算法

### 技术架构

```
lib/
├── services/
│   ├── gemini_service.dart          # Firebase AI 服务
│   ├── ai_enhanced_exercise_generator.dart  # AI增强练习生成器
│   └── ai_enhanced_practice_session_controller.dart  # AI增强会话控制器
├── screens/
│   └── ai_enhanced_practice_screen.dart     # AI增强练习界面
└── assets/
    └── prompts/
        └── system_prompt.md         # AI系统提示
```

## 📋 安装和配置

### 1. 依赖安装

确保您的 `pubspec.yaml` 包含以下依赖：

```yaml
dependencies:
  firebase_core: ^3.1.1
  firebase_ai: ^2.2.1
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1

dev_dependencies:
  riverpod_generator: ^2.4.0
```

运行依赖安装：
```bash
dart pub get
```

### 2. Firebase 项目设置

1. 访问 [Firebase 控制台](https://console.firebase.google.com/)
2. 创建新项目或使用现有项目
3. 在项目设置中启用 AI Logic 功能
4. 确保启用了 Gemini API

### 3. 代码生成

运行代码生成器以生成必要的文件：
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🔧 使用方法

### 基本使用

1. **初始化AI服务**:
```dart
// 在 main.dart 中已经配置
await Firebase.initializeApp();
```

2. **使用AI增强的练习生成器**:
```dart
final exerciseGenerator = AIEnhancedExerciseGenerator(ref);
final exercise = await exerciseGenerator.generateMatchingExercise(formula, allFormulas);
```

3. **使用AI增强的会话控制器**:
```dart
final sessionController = AIEnhancedPracticeSessionController(
  exerciseGenerator: exerciseGenerator,
  progressService: progressService,
  achievementSystem: achievementSystem,
  ref: ref,
);

await sessionController.initializeSession(formulas);
```

### 高级功能

#### 1. 自定义AI提示

编辑 `assets/prompts/system_prompt.md` 来自定义AI行为：

```markdown
# 自定义系统提示

你是一个专业的数学教育助手...

## 你的能力
1. 生成新的数学公式
2. 生成练习题选项
3. 分析错误答案

## 输出格式
...
```

#### 2. 错误分析

当用户答错时，AI会自动提供解释：

```dart
// 在练习界面中显示AI解释
if (controller.showAIExplanation && controller.aiExplanation != null) {
  // 显示AI解释UI
}
```

#### 3. 优雅降级

如果AI服务不可用，系统会自动回退到传统算法：

```dart
try {
  // 尝试使用AI生成
  final aiDistractors = await aiService.generateDistractorsWithAI(...);
} catch (e) {
  // 回退到传统方法
  return _generateTraditionalDistractors(...);
}
```

## 🎯 集成到现有应用

### 1. 替换现有练习生成器

将现有的 `ExerciseGenerator` 替换为 `AIEnhancedExerciseGenerator`：

```dart
// 旧代码
final exerciseGenerator = ExerciseGenerator();

// 新代码
final exerciseGenerator = AIEnhancedExerciseGenerator(ref);
```

### 2. 更新练习界面

使用 `AIEnhancedPracticeScreen` 替代现有的练习界面：

```dart
// 在路由中使用
GoRoute(
  path: '/ai-practice/:formulaSetId',
  builder: (context, state) => AIEnhancedPracticeScreen(
    formulaSetId: state.pathParameters['formulaSetId']!,
  ),
),
```

### 3. 添加AI功能到现有界面

在现有的练习界面中添加AI解释功能：

```dart
// 在答案提交后检查是否需要AI解释
if (!isCorrect) {
  final explanation = await exerciseGenerator.getAIExplanation(
    exercise: exercise,
    userAnswerId: selectedOptionId,
  );
  // 显示解释
}
```

## 🔍 调试和故障排除

### 常见问题

1. **Firebase 初始化失败**
   - 检查 Firebase 项目配置
   - 确保网络连接正常
   - 验证 API 密钥

2. **AI 生成失败**
   - 检查系统提示文件格式
   - 验证 Gemini API 配额
   - 查看控制台错误日志

3. **性能问题**
   - AI 调用可能需要几秒钟
   - 考虑添加加载指示器
   - 实现缓存机制

### 调试技巧

1. **启用详细日志**:
```dart
// 在 gemini_service.dart 中添加
print('AI调用开始: $prompt');
print('AI响应: $response');
```

2. **测试AI服务**:
```dart
// 创建测试方法
Future<void> testAIService() async {
  final aiService = AIService(ref);
  final result = await aiService.generateDistractorsWithAI(
    correctAnswerLatex: 'x^2 + 2x + 1',
    category: 'calculus',
    difficulty: 'medium',
  );
  print('AI测试结果: $result');
}
```

## 📈 性能优化

### 1. 缓存策略

```dart
// 实现简单的内存缓存
class AICache {
  static final Map<String, List<Map<String, String>>> _cache = {};
  
  static List<Map<String, String>>? get(String key) => _cache[key];
  static void set(String key, List<Map<String, String>> value) => _cache[key] = value;
}
```

### 2. 异步加载

```dart
// 在后台预加载AI生成的练习
Future<void> preloadAIExercises() async {
  // 在用户浏览时预加载
}
```

### 3. 错误处理

```dart
// 实现重试机制
Future<T> retry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 1 << i));
    }
  }
}
```

## 🔮 未来扩展

### 1. 个性化学习

- 根据用户历史表现调整练习难度
- 生成针对用户弱点的专项练习
- 智能推荐学习路径

### 2. 高级分析

- 错误模式识别
- 学习进度预测
- 个性化反馈

### 3. 多模态支持

- 语音输入
- 手写公式识别
- 图像公式识别

## 📞 支持和反馈

如果您在使用过程中遇到问题或有改进建议，请：

1. 检查本文档的故障排除部分
2. 查看控制台错误日志
3. 提交 Issue 或 Pull Request

---

**注意**: 本AI集成功能需要有效的Firebase项目和Gemini API访问权限。请确保您有足够的API配额来支持您的应用使用。 