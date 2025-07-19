import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

/// Optimized list widget for displaying formulas with smooth 60fps scrolling
class OptimizedFormulaList extends StatefulWidget {
  final List<Formula> formulas;
  final Function(Formula) onFormulaTap;
  final bool enableLazyLoading;

  const OptimizedFormulaList({
    super.key,
    required this.formulas,
    required this.onFormulaTap,
    this.enableLazyLoading = true,
  });

  @override
  State<OptimizedFormulaList> createState() => _OptimizedFormulaListState();
}

class _OptimizedFormulaListState extends State<OptimizedFormulaList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, Widget> _itemCache = {};
  static const int _cacheSize = 50;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _itemCache.clear();
    super.dispose();
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    final formula = widget.formulas[index];
    final item = _FormulaListItem(
      formula: formula,
      onTap: () => widget.onFormulaTap(formula),
    );

    if (_itemCache.length < _cacheSize) {
      _itemCache[index] = item;
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.formulas.isEmpty) {
      return const Center(
        child: Text('没有找到匹配的公式。\n请尝试调整搜索或筛选条件。', textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.formulas.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemBuilder: _buildOptimizedItem,
    );
  }
}

/// Individual formula list item, refactored with Material 3 components
class _FormulaListItem extends StatelessWidget {
  final Formula formula;
  final VoidCallback onTap;

  const _FormulaListItem({required this.formula, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // 使用 M3 风格的填充卡片，视觉上更柔和
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        // 1. leading 用于放置公式，给予更宽敞的空间
        leading: Container(
          width: 140, // 增加宽度
          alignment: Alignment.center,
          child: FormulaRenderer(
            latexExpression: formula.latexExpression,
            fontSize: 18, // 调整基础字号以适应空间
            semanticDescription: formula.description,
            useCache: true,
          ),
        ),
        // 2. title 和 subtitle 用于显示名称和描述
        title: Text(
          formula.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            formula.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        // 3. trailing 用于放置类别标签 (Chip)
        trailing: Chip(
          label: Text(formula.category),
          labelStyle: TextStyle(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: colorScheme.secondaryContainer.withValues(
            alpha: 0.5,
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // 确保 ListTile 即使内容较少也能保持合理的最小高度
        minVerticalPadding: 16,
      ),
    );
  }
}

/// Grid version for category display with optimized performance
class OptimizedFormulaGrid extends StatefulWidget {
  final List<Formula> formulas;
  final Function(Formula) onFormulaTap;
  final int crossAxisCount;

  const OptimizedFormulaGrid({
    super.key,
    required this.formulas,
    required this.onFormulaTap,
    this.crossAxisCount = 2,
  });

  @override
  State<OptimizedFormulaGrid> createState() => _OptimizedFormulaGridState();
}

class _OptimizedFormulaGridState extends State<OptimizedFormulaGrid>
    with AutomaticKeepAliveClientMixin {
  final Map<int, Widget> _itemCache = {};
  static const int _cacheSize = 30;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _itemCache.clear();
    super.dispose();
  }

  Widget _buildGridItem(BuildContext context, int index) {
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    final formula = widget.formulas[index];
    final item = _FormulaGridItem(
      formula: formula,
      onTap: () => widget.onFormulaTap(formula),
    );

    if (_itemCache.length < _cacheSize) {
      _itemCache[index] = item;
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9, // 调整宽高比，让卡片更高一些
      ),
      padding: const EdgeInsets.all(8),
      itemCount: widget.formulas.length,
      cacheExtent: 600,
      physics: const BouncingScrollPhysics(),
      itemBuilder: _buildGridItem,
    );
  }
}

/// Individual formula grid item, refactored for better visual balance
class _FormulaGridItem extends StatelessWidget {
  final Formula formula;
  final VoidCallback onTap;

  const _FormulaGridItem({required this.formula, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // 均匀分布空间
            children: [
              // 给予公式渲染器更多空间
              Expanded(
                flex: 3, // 增加 flex 权重
                child: Center(
                  child: FormulaRenderer(
                    latexExpression: formula.latexExpression,
                    fontSize: 20,
                    semanticDescription: formula.description,
                    useCache: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 给予公式名称固定空间
              Text(
                formula.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
