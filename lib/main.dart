import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/app_router.dart'; // 更正导入路径
import 'package:mnemonicorum/hive_initializer.dart'; // 导入新的初始化文件

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive Adapters
  registerHiveAdapters(); // 调用新的注册函数

  final progressService = ProgressService();
  await progressService.init();

  final formulaRepository = FormulaRepository();
  await formulaRepository.loadFormulas();

  runApp(
    MultiProvider(
      providers: [
        Provider<ProgressService>(create: (_) => progressService),
        Provider<FormulaRepository>(create: (_) => formulaRepository),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: appRouter);
  }
}
