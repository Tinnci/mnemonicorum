import 'package:hive/hive.dart';

part 'formula.g.dart';

@HiveType(typeId: 5)
enum DifficultyLevel {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  hard,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get name {
    switch (this) {
      case DifficultyLevel.easy:
        return 'easy';
      case DifficultyLevel.medium:
        return 'medium';
      case DifficultyLevel.hard:
        return 'hard';
    }
  }
}

@HiveType(typeId: 6)
enum ComponentType {
  @HiveField(0)
  leftSide,
  @HiveField(1)
  rightSide,
  @HiveField(2)
  variable,
  @HiveField(3)
  constant,
}

@HiveType(typeId: 7)
class FormulaComponent {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String latexPart;
  @HiveField(2)
  final ComponentType type;
  @HiveField(3)
  final String description;

  FormulaComponent({
    required this.id,
    required this.latexPart,
    required this.type,
    required this.description,
  });

  factory FormulaComponent.fromJson(Map<String, dynamic> json) {
    return FormulaComponent(
      id: json['id'],
      latexPart: json['latexPart'],
      type: ComponentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latexPart': latexPart,
      'type': type.toString().split('.').last,
      'description': description,
    };
  }
}

@HiveType(typeId: 8)
class Formula {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String latexExpression;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String subcategory;
  @HiveField(5)
  final DifficultyLevel difficulty;
  @HiveField(6)
  final List<String> tags;
  @HiveField(7)
  final String description;
  @HiveField(8)
  final List<FormulaComponent> components;
  @HiveField(9)
  final String semanticDescription; // For accessibility

  Formula({
    required this.id,
    required this.name,
    required this.latexExpression,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.tags,
    required this.description,
    required this.components,
    required this.semanticDescription,
  });

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'],
      name: json['name'],
      latexExpression: json['latexExpression'],
      category: json['category'],
      subcategory: json['subcategory'],
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
      ),
      tags: List<String>.from(json['tags']),
      description: json['description'],
      components: (json['components'] as List)
          .map((e) => FormulaComponent.fromJson(e))
          .toList(),
      semanticDescription: json['semanticDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latexExpression': latexExpression,
      'category': category,
      'subcategory': subcategory,
      'difficulty': difficulty.toString().split('.').last,
      'tags': tags,
      'description': description,
      'components': components.map((e) => e.toJson()).toList(),
      'semanticDescription': semanticDescription,
    };
  }
}
