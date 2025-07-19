import 'package:flutter/material.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/widgets/formula_renderer.dart';

/// Optimized list widget for displaying formulas with smooth 60fps scrolling
class OptimizedFormulaList extends StatefulWidget {
  final List<Formula> formulas;
  final Function(Formula) onFormulaTap;
  final double itemHeight;
  final bool enableLazyLoading;

  const OptimizedFormulaList({
    super.key,
    required this.formulas,
    required this.onFormulaTap,
    this.itemHeight = 80.0,
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

    final currentIndex = (_scrollController.offset / widget.itemHeight).round();
    final visibleRange = 10; // Keep items within 10 positions of current view

    final keysToRemove = <int>[];
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
      height: widget.itemHeight,
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
      itemExtent: widget.itemHeight, // Fixed height for better performance
      cacheExtent: widget.itemHeight * 10, // Cache 10 items ahead/behind
      physics: const BouncingScrollPhysics(), // Smooth scrolling physics
      itemBuilder: _buildOptimizedItem,
    );
  }
}

/// Individual formula list item with optimized rendering
class _FormulaListItem extends StatelessWidget {
  final Formula formula;
  final VoidCallback onTap;
  final double height;

  const _FormulaListItem({
    required this.formula,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Formula preview with constrained size for performance
                SizedBox(
                  width: 80,
                  height: 40,
                  child: FormulaRenderer(
                    latexExpression: formula.latexExpression,
                    fontSize: 14,
                    semanticDescription: formula.description,
                    useCache: true, // Always use cache for list items
                  ),
                ),
                const SizedBox(width: 12),
                // Formula details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formula.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formula.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: FormulaRenderer(
                    latexExpression: formula.latexExpression,
                    fontSize: 16,
                    semanticDescription: formula.description,
                    useCache: true,
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
  }
}
