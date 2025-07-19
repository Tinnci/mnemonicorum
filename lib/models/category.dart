import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:mnemonicorum/models/formula.dart';

part 'category.g.dart';

@HiveType(typeId: 15)
class FormulaSet {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<Formula> formulas;
  @HiveField(3)
  final DifficultyLevel difficulty;

  FormulaSet({
    required this.id,
    required this.name,
    required this.formulas,
    required this.difficulty,
  });

  factory FormulaSet.fromJson(Map<String, dynamic> json) {
    return FormulaSet(
      id: json['id'],
      name: json['name'],
      formulas: (json['formulas'] as List)
          .map((e) => Formula.fromJson(e))
          .toList(),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formulas': formulas.map((e) => e.toJson()).toList(),
      'difficulty': difficulty.toString().split('.').last,
    };
  }
}

@HiveType(typeId: 16)
class FormulaCategory {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final List<FormulaSet> formulaSets;
  @HiveField(4)
  final IconData icon;

  FormulaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.formulaSets,
    this.icon = Icons.category,
  });

  factory FormulaCategory.fromJson(Map<String, dynamic> json) {
    // Map icon names to IconData
    IconData getIconFromName(String? iconName) {
      switch (iconName) {
        case 'functions':
          return Icons.functions;
        case 'calculate':
          return Icons.calculate;
        case 'analytics':
          return Icons.analytics;
        case 'science':
          return Icons.science;
        default:
          return Icons.category;
      }
    }

    return FormulaCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      formulaSets: (json['formulaSets'] as List)
          .map((e) => FormulaSet.fromJson(e))
          .toList(),
      icon: getIconFromName(json['icon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'formulaSets': formulaSets.map((e) => e.toJson()).toList(),
    };
  }
}
