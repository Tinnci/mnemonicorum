// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 18;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as AchievementType,
      targetValue: fields[4] as int,
      iconName: fields[5] as String,
      isUnlocked: fields[6] as bool,
      unlockedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.targetValue)
      ..writeByte(5)
      ..write(obj.iconName)
      ..writeByte(6)
      ..write(obj.isUnlocked)
      ..writeByte(7)
      ..write(obj.unlockedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAchievementsAdapter extends TypeAdapter<UserAchievements> {
  @override
  final int typeId = 19;

  @override
  UserAchievements read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAchievements(
      achievements: (fields[0] as List).cast<Achievement>(),
      currentStreak: fields[1] as int,
      lastPracticeDate: fields[2] as DateTime?,
      totalPracticeDays: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserAchievements obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.achievements)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.lastPracticeDate)
      ..writeByte(3)
      ..write(obj.totalPracticeDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAchievementsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 17;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.streak;
      case 1:
        return AchievementType.mastery;
      case 2:
        return AchievementType.accuracy;
      case 3:
        return AchievementType.completion;
      default:
        return AchievementType.streak;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.streak:
        writer.writeByte(0);
        break;
      case AchievementType.mastery:
        writer.writeByte(1);
        break;
      case AchievementType.accuracy:
        writer.writeByte(2);
        break;
      case AchievementType.completion:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
