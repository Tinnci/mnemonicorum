import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 17)
enum AchievementType {
  @HiveField(0)
  streak,
  @HiveField(1)
  mastery,
  @HiveField(2)
  accuracy,
  @HiveField(3)
  completion,
}

@HiveType(typeId: 18)
class Achievement {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final AchievementType type;
  @HiveField(4)
  final int targetValue;
  @HiveField(5)
  final String iconName;
  @HiveField(6)
  final bool isUnlocked;
  @HiveField(7)
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.iconName,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  // Getter to convert iconName string to IconData
  IconData get icon {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'functions':
        return Icons.functions;
      case 'change_history':
        return Icons.change_history;
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'school':
        return Icons.school;
      default:
        return Icons.emoji_events;
    }
  }

  // Getter for title (alias for name)
  String get title => name;

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    int? targetValue,
    String? iconName,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      iconName: iconName ?? this.iconName,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

@HiveType(typeId: 19)
class UserAchievements {
  @HiveField(0)
  final List<Achievement> achievements;
  @HiveField(1)
  int currentStreak;
  @HiveField(2)
  DateTime? lastPracticeDate;
  @HiveField(3)
  int totalPracticeDays;

  UserAchievements({
    required this.achievements,
    this.currentStreak = 0,
    this.lastPracticeDate,
    this.totalPracticeDays = 0,
  });
}
