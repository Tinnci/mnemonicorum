import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/widgets/adaptive_scaffold.dart';
import 'package:mnemonicorum/widgets/progress_dashboard.dart';
import 'package:mnemonicorum/utils/error_handler.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mnemonicorum/utils/latex_renderer_utils.dart';
import 'package:mnemonicorum/models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Preload commonly used categories for better performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadCommonCategories();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Optimize memory usage when app goes to background
    if (state == AppLifecycleState.paused) {
      LatexRendererUtils.optimizeMemoryUsage();
    }
  }

  Future<void> _preloadCommonCategories() async {
    await ErrorHandler.handleRepositoryError(
      () async {
        final formulaRepository = Provider.of<FormulaRepository>(
          context,
          listen: false,
        );
        final categories = formulaRepository.getAllCategories();

        // Preload the first 2 categories for better performance
        if (categories.isNotEmpty) {
          final categoryIds = categories.take(2).map((c) => c.id).toList();
          await formulaRepository.preloadCategories(categoryIds);
        }
      },
      'preload common categories',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandler.errorBoundary(
      child: _buildHomeContent(context),
      errorMessage: 'Failed to load home screen. Please restart the app.',
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final formulaRepository = Provider.of<FormulaRepository>(context);
    final achievementSystem = Provider.of<AchievementSystem>(context);
    final categories = formulaRepository.getAllCategories();

    return AdaptiveScaffold(
      currentRoute: '/home',
      title: 'Home',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '每日连击',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          achievementSystem.currentStreak > 0
                              ? '你已经连续练习了 ${achievementSystem.currentStreak} 天！保持下去！'
                              : '开始你的练习连击吧！',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Quick practice logic (e.g., select a random formula set)
                      // For now, just navigate to a default category
                      if (categories.isNotEmpty) {
                        context.go('/category/${categories.first.id}');
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('快速练习'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/all-formulas');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('所有公式查询'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProgressDashboard(categories: categories),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '按类别学习',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // 使用 SliverGridDelegateWithMaxCrossAxisExtent 实现自适应布局
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250, // 设定每个元素的最大宽度
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2, // 根据需要调整宽高比
                        ),
                    itemCount: categories.length,
                    cacheExtent:
                        200, // Cache items for better scrolling performance
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _OptimizedCategoryCard(
                        category: category,
                        onTap: () {
                          context.go('/category/${category.id}');
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized category card widget with better performance
class _OptimizedCategoryCard extends StatelessWidget {
  final FormulaCategory category;
  final VoidCallback onTap;

  const _OptimizedCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // RepaintBoundary prevents unnecessary repaints
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optimized icon rendering
              Icon(Icons.category, size: 50, color: Colors.blue.shade700),
              const SizedBox(height: 10),
              AutoSizeText(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                minFontSize: 14, // 保证在小卡片上也能显示
              ),
            ],
          ),
        ),
      ),
    );
  }
}
