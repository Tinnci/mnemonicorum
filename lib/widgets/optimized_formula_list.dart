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
  static const double _preloadThreshold = 200.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.enableLazyLoading) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _itemCache.clear();
    super.dispose();
  }

  void _onScroll() {
    // Preload items when approaching the end of the list
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - _preloadThreshold) {
      _preloadNextItems();
    }

    // Clean up cache for items that are far from current view
    _cleanupDistantCacheItems();
  }

  void _preloadNextItems() {
    // This would trigger loading more items in a paginated scenario
    // For now, it's a placeholder for future enhancement
  }

  void _cleanupDistantCacheItems() {
    if (_itemCache.length <= _cacheSize) return;

    // Since we no longer have fixed item height, use a simpler cleanup strategy
    final keysToRemove = <int>[];
    final currentIndex = _scrollController.hasClients
        ? (_scrollController.offset / 100)
              .round() // Approximate item height
        : 0;
    final visibleRange = 10; // Keep items within 10 positions of current view

    for (var key in _itemCache.keys) {
      if ((key - currentIndex).abs() > visibleRange) {
        keysToRemove.add(key);
      }
    }

    for (var key in keysToRemove) {
      _itemCache.remove(key);
    }
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    // Use cached item if available
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    final formula = widget.formulas[index];
    final item = _FormulaListItem(
      formula: formula,
      onTap: () => widget.onFormulaTap(formula),
    );

    // Cache the item if we haven't exceeded cache size
    if (_itemCache.length < _cacheSize) {
      _itemCache[index] = item;
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.formulas.length,
      padding: const EdgeInsets.only(bottom: 80), // Add padding for FAB etc.
      physics: const BouncingScrollPhysics(), // Smooth scrolling physics
      itemBuilder: _buildOptimizedItem,
    );
  }
}

/// Individual formula list item with optimized rendering
class _FormulaListItem extends StatelessWidget {
  final Formula formula;
  final VoidCallback onTap;

  const _FormulaListItem({required this.formula, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // No longer needs a fixed-height SizedBox
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 120,
                  height: 60, // 固定高度
                  child: FittedBox(
                    // 关键：向内 scaleDown
                    fit: BoxFit.scaleDown,
                    child: FormulaRenderer(
                      latexExpression: formula.latexExpression,
                      fontSize: 28, // 不要再传过大的 fontSize
                      semanticDescription: formula.description,
                      useCache: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formula.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formula.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Category indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formula.category,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildGridItem(BuildContext context, int index) {
    // Use cached item if available
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    final formula = widget.formulas[index];
    final item = _FormulaGridItem(
      formula: formula,
      onTap: () => widget.onFormulaTap(formula),
    );

    // Cache the item if we haven't exceeded cache size
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
        childAspectRatio: 1.2,
      ),
      itemCount: widget.formulas.length,
      cacheExtent: 600, // Cache more items for grid
      physics: const BouncingScrollPhysics(),
      itemBuilder: _buildGridItem,
    );
  }

  @override
  void dispose() {
    _itemCache.clear();
    super.dispose();
  }
}

/// Individual formula grid item
class _FormulaGridItem extends StatelessWidget {
  final Formula formula;
  final VoidCallback onTap;

  const _FormulaGridItem({required this.formula, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = (constraints.maxWidth / 8).clamp(12.0, 28.0); // 随宽度变化
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Formula preview
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        width: constraints.maxWidth * 0.8,
                        height: constraints.maxHeight * 0.6,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: FormulaRenderer(
                            latexExpression: formula.latexExpression,
                            fontSize: fontSize,
                            semanticDescription: formula.description,
                            useCache: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Formula name
                  Expanded(
                    flex: 1,
                    child: Text(
                      formula.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
