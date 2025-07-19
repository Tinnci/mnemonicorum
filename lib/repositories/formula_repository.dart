import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/models/category.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

class FormulaRepository {
  List<FormulaCategory> _categories = [];
  final Map<String, List<Formula>> _formulaCache = {};
  final Map<String, bool> _loadedCategories = {};

  Future<void> loadFormulas() async {
    final result = await ErrorHandler.handleDataLoadingError(
      () async {
        // Load category data from a JSON file (e.g., categories.json)
        final String response = await rootBundle.loadString(
          'assets/formulas/categories.json',
        );

        late final dynamic data;
        try {
          data = await json.decode(response);
        } catch (e) {
          throw FormulaLoadingException(
            'Invalid JSON format in categories.json. Please check LaTeX expressions are properly escaped.',
            e,
          );
        }

        // Assuming categories.json contains a list of categories
        final categories = (data as List)
            .map((categoryJson) => FormulaCategory.fromJson(categoryJson))
            .toList();

        if (categories.isEmpty) {
          throw const FormulaLoadingException(
            'No categories found in data file',
          );
        }

        return categories;
      },
      'load formula categories',
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
    );

    if (result != null) {
      _categories = result;
    } else {
      // Fallback to empty categories if loading fails completely
      _categories = [];
      throw const FormulaLoadingException(
        'Failed to load formula categories after all retry attempts',
      );
    }
  }

  /// Lazy load formulas for a specific category to improve performance
  Future<void> _lazyLoadCategoryFormulas(String categoryId) async {
    if (_loadedCategories[categoryId] == true) {
      return; // Already loaded
    }

    final result = await ErrorHandler.handleDataLoadingError(
      () async {
        // Load formulas for this specific category
        final String response = await rootBundle.loadString(
          'assets/formulas/$categoryId.json',
        );
        final data = await json.decode(response);

        if (data['formulas'] == null) {
          throw FormulaLoadingException(
            'No formulas found for category $categoryId',
            categoryId,
          );
        }

        // Cache the formulas for this category
        final formulas = (data['formulas'] as List)
            .map((formulaJson) => Formula.fromJson(formulaJson))
            .toList();

        return formulas;
      },
      'lazy load category $categoryId',
      maxRetries: 2,
      retryDelay: const Duration(milliseconds: 500),
      showUserMessage: false, // Don't show user message for lazy loading
    );

    if (result != null) {
      _formulaCache[categoryId] = result;
    }

    _loadedCategories[categoryId] = true; // Mark as attempted regardless
  }

  List<FormulaCategory> getAllCategories() {
    return _categories;
  }

  List<FormulaCategory> getCategories() {
    return _categories;
  }

  Future<List<Formula>> getFormulasByCategory(String categoryId) async {
    // Use lazy loading for better performance
    await _lazyLoadCategoryFormulas(categoryId);

    // Return cached formulas if available
    if (_formulaCache.containsKey(categoryId)) {
      return _formulaCache[categoryId]!;
    }

    // Fallback to existing data structure
    return _categories
        .firstWhere((cat) => cat.id == categoryId)
        .formulaSets
        .expand((set) => set.formulas)
        .toList();
  }

  Formula? getFormulaById(String formulaId) {
    for (var category in _categories) {
      for (var set in category.formulaSets) {
        for (var formula in set.formulas) {
          if (formula.id == formulaId) {
            return formula;
          }
        }
      }
    }
    return null;
  }

  Future<List<Formula>> searchFormulas(String query) async {
    final lowerCaseQuery = query.toLowerCase();
    List<Formula> allFormulas = [];

    // Load all categories lazily for search
    for (var category in _categories) {
      await _lazyLoadCategoryFormulas(category.id);
      if (_formulaCache.containsKey(category.id)) {
        allFormulas.addAll(_formulaCache[category.id]!);
      } else {
        // Fallback to existing data structure
        allFormulas.addAll(
          category.formulaSets.expand((set) => set.formulas).toList(),
        );
      }
    }

    return allFormulas
        .where(
          (formula) =>
              formula.name.toLowerCase().contains(lowerCaseQuery) ||
              formula.description.toLowerCase().contains(lowerCaseQuery) ||
              formula.latexExpression.toLowerCase().contains(lowerCaseQuery),
        )
        .toList();
  }

  /// Clear cache to free memory when needed
  void clearCache() {
    _formulaCache.clear();
    _loadedCategories.clear();
  }

  /// Get memory usage statistics for monitoring
  Map<String, int> getMemoryStats() {
    int totalFormulas = 0;
    for (var formulas in _formulaCache.values) {
      totalFormulas += formulas.length;
    }

    return {
      'cachedCategories': _formulaCache.length,
      'totalCachedFormulas': totalFormulas,
      'loadedCategories': _loadedCategories.length,
    };
  }

  /// Preload specific categories for better performance
  Future<void> preloadCategories(List<String> categoryIds) async {
    for (String categoryId in categoryIds) {
      await _lazyLoadCategoryFormulas(categoryId);
    }
  }
}
