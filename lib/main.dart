import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/app_router.dart';
import 'package:mnemonicorum/hive_initializer.dart';
import 'package:mnemonicorum/utils/latex_renderer_utils.dart';
import 'package:mnemonicorum/utils/error_handler.dart';
import 'package:mnemonicorum/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize app with comprehensive error handling
    await _initializeApp();
  } catch (error, stackTrace) {
    // Critical error during app initialization
    debugPrint('Critical error during app initialization: $error');
    debugPrint('Stack trace: $stackTrace');

    // Run app with error state
    runApp(const ErrorApp());
    return;
  }
}

Future<void> _initializeApp() async {
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Preload mathematics fonts to avoid rendering delays
  await ErrorHandler.handleDataLoadingError(
    () => LatexRendererUtils.preloadMathematicsFonts(),
    'preload mathematics fonts',
    maxRetries: 2,
    showUserMessage: false,
  );

  await Hive.initFlutter();

  // Register Hive Adapters
  registerHiveAdapters();

  final progressService = ProgressService();
  await ErrorHandler.handleDataLoadingError(
    () => progressService.init(),
    'initialize progress service',
    maxRetries: 3,
    showUserMessage: false,
  );

  final achievementSystem = AchievementSystem();
  await ErrorHandler.handleDataLoadingError(
    () => achievementSystem.init(),
    'initialize achievement system',
    maxRetries: 3,
    showUserMessage: false,
  );

  final formulaRepository = FormulaRepository();
  await ErrorHandler.handleDataLoadingError(
    () => formulaRepository.loadFormulas(),
    'load formulas',
    maxRetries: 3,
    showUserMessage: false,
  );

  // Set up periodic memory optimization
  _setupPeriodicMemoryOptimization();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<ProgressService>(
            create: (_) => progressService,
          ),
          provider.Provider<FormulaRepository>(
            create: (_) => formulaRepository,
          ),
          provider.ChangeNotifierProvider<AchievementSystem>(
            create: (_) => achievementSystem,
          ),
        ],
        child: const MainApp(),
      ),
    ),
  );
}

/// Set up periodic memory optimization to maintain smooth performance
void _setupPeriodicMemoryOptimization() {
  // Run memory optimization every 5 minutes
  Stream.periodic(const Duration(minutes: 5)).listen((_) {
    LatexRendererUtils.optimizeMemoryUsage();

    // Print memory stats in debug mode
    debugPrint('Memory optimization completed');
    debugPrint('Cache stats: ${LatexRendererUtils.getCacheStats()}');
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Mnemonicorum',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    );
  }
}

/// Error app displayed when critical initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Formula App - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 64),
                const SizedBox(height: 24),
                Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The app failed to initialize properly. This could be due to missing data files or system issues.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Show more details
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Troubleshooting'),
                        content: const Text(
                          'Try the following steps:\n\n'
                          '1. Restart the app\n'
                          '2. Check your device storage\n'
                          '3. Reinstall the app if the problem persists\n\n'
                          'If the issue continues, please contact support.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Troubleshooting'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
