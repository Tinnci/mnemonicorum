import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/models/category.dart';

class FormulaRepository {
  List<FormulaCategory> _categories = [];

  Future<void> loadFormulas() async {
    // Load category data from a JSON file (e.g., categories.json)
    final String response = await rootBundle.loadString(
      'assets/formulas/categories.json',
    );
    final data = await json.decode(response);

    // Assuming categories.json contains a list of categories
    _categories = (data as List)
        .map((categoryJson) => FormulaCategory.fromJson(categoryJson))
        .toList();
  }

  List<FormulaCategory> getAllCategories() {
    return _categories;
  }

  List<Formula> getFormulasByCategory(String categoryId) {
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

  List<Formula> searchFormulas(String query) {
    final lowerCaseQuery = query.toLowerCase();
    return _categories
        .expand(
          (category) => category.formulaSets.expand((set) => set.formulas),
        )
        .where(
          (formula) =>
              formula.name.toLowerCase().contains(lowerCaseQuery) ||
              formula.description.toLowerCase().contains(lowerCaseQuery) ||
              formula.latexExpression.toLowerCase().contains(lowerCaseQuery),
        )
        .toList();
  }
}
