# Firebase 设置指南

## 🚨 重要安全提醒

以下文件包含敏感信息，**不要提交到版本控制系统**：
- `firebase.json`
- `lib/firebase_options.dart`
- `lib/firebase_options.dart.backup`

这些文件已被添加到 `.gitignore` 中。

## 📋 设置步骤

### 1. 安装 Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. 登录 Firebase
```bash
firebase login
```

### 3. 初始化 Firebase 项目
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. 选择项目
运行 `flutterfire configure` 后：
1. 选择您的 Firebase 项目
2. 选择要配置的平台（Android、iOS、Web、Windows 等）
3. 工具会自动生成 `lib/firebase_options.dart` 文件

### 5. 验证配置
确保 `lib/main.dart` 中正确初始化了 Firebase：

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:mnemonicorum/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## 🔧 开发环境设置

### 新开发者加入项目
1. 克隆项目
2. 运行 `flutterfire configure` 生成自己的 Firebase 配置
3. 确保 `firebase_options.dart` 文件被 `.gitignore` 忽略

### 环境变量（可选）
如果需要更安全的配置，可以创建 `.env` 文件：

```env
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here
```

然后在代码中使用环境变量：

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  // ... 其他配置
);
```

## 🛡️ 安全最佳实践

1. **永远不要提交敏感文件**
   - `firebase.json`
   - `lib/firebase_options.dart`
   - 任何包含 API 密钥的文件

2. **使用环境变量**
   - 在生产环境中使用环境变量
   - 避免在代码中硬编码敏感信息

3. **定期轮换密钥**
   - 定期更新 Firebase API 密钥
   - 监控异常访问

4. **限制 API 密钥权限**
   - 在 Firebase Console 中设置适当的权限
   - 只授予必要的权限

## 📝 故障排除

### 常见问题

1. **"Firebase has not been correctly initialized"**
   - 确保在 `main()` 中调用了 `Firebase.initializeApp()`
   - 检查 `firebase_options.dart` 文件是否存在

2. **"API key not valid"**
   - 验证 API 密钥是否正确
   - 检查 Firebase 项目设置

3. **"Project not found"**
   - 确认项目 ID 正确
   - 检查是否有访问权限

### 调试技巧

```dart
// 在开发时启用 Firebase 调试
if (kDebugMode) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

## 📚 相关文档

- [Firebase Flutter 文档](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) 