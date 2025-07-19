import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/widgets/adaptive_scaffold.dart';
import 'package:mnemonicorum/utils/error_handler.dart';
import 'package:mnemonicorum/models/formula.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isLoading = true;
  List<dynamic> _formulaSets = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final result = await ErrorHandler.handleRepositoryError(
      () async {
        final formulaRepository = Provider.of<FormulaRepository>(
          context,
          listen: false,
        );

        // Preload formulas for this category for better performance
        await formulaRepository.preloadCategories([widget.categoryId]);

        final category = formulaRepository.getAllCategories().firstWhere(
          (cat) => cat.id == widget.categoryId,
          orElse: () => throw FormulaLoadingException(
            'Category ${widget.categoryId} not found',
          ),
        );

        return category.formulaSets;
      },
      'load category data',
      context: context,
    );

    setState(() {
      if (result != null) {
        _formulaSets = result;
      } else {
        _formulaSets = []; // Empty list on error
      }
      _isLoading = false;
    });
  }

  String _getDifficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'easy';
      case DifficultyLevel.medium:
        return 'medium';
      case DifficultyLevel.hard:
        return 'hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandler.errorBoundary(
      child: _buildCategoryContent(context),
      errorMessage: 'Failed to load category. Please go back and try again.',
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    final formulaRepository = Provider.of<FormulaRepository>(context);
    final category = formulaRepository.getAllCategories().firstWhere(
      (cat) => cat.id == widget.categoryId,
      orElse: () => throw FormulaLoadingException(
        'Category ${widget.categoryId} not found in build method',
      ),
    );

    return AdaptiveScaffold(
      currentRoute: '/category/${widget.categoryId}',
      title: category.name,
      body: Center(
        // 1. 将内容居中
        child: ConstrainedBox(
          // 2. 施加最大宽度约束
          constraints: const BoxConstraints(maxWidth: 1000), // 推荐的阅读宽度
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading formulas...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '公式集',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Use optimized ListView with better performance
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _formulaSets.length,
                        cacheExtent: 200, // Cache items for better performance
                        itemBuilder: (context, index) {
                          final formulaSet = _formulaSets[index];
                          return RepaintBoundary(
                            // Prevent unnecessary repaints
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  formulaSet.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '难度: ${_getDifficultyName(formulaSet.difficulty)}',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  // Navigate to Practice Session Screen
                                  context.go('/practice/${formulaSet.id}');
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
