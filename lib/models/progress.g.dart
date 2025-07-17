// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAttemptAdapter extends TypeAdapter<ExerciseAttempt> {
  @override
  final int typeId = 13;

  @override
  ExerciseAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseAttempt(
      timestamp: fields[0] as DateTime,
      isCorrect: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseAttempt obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.isCorrect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaProgressAdapter extends TypeAdapter<FormulaProgress> {
  @override
  final int typeId = 14;

  @override
  FormulaProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaProgress(
      formulaId: fields[0] as String,
      correctAnswers: fields[1] as int,
      totalAttempts: fields[2] as int,
      lastPracticed: fields[3] as DateTime,
      masteryLevel: fields[4] as MasteryLevel,
      attempts: (fields[5] as List).cast<ExerciseAttempt>(),
    );
  }

  @override
  void write(BinaryWriter writer, FormulaProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.formulaId)
      ..writeByte(1)
      ..write(obj.correctAnswers)
      ..writeByte(2)
      ..write(obj.totalAttempts)
      ..writeByte(3)
      ..write(obj.lastPracticed)
      ..writeByte(4)
      ..write(obj.masteryLevel)
      ..writeByte(5)
      ..write(obj.attempts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MasteryLevelAdapter extends TypeAdapter<MasteryLevel> {
  @override
  final int typeId = 12;

  @override
  MasteryLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MasteryLevel.learning;
      case 1:
        return MasteryLevel.practicing;
      case 2:
        return MasteryLevel.mastered;
      default:
        return MasteryLevel.learning;
    }
  }

  @override
  void write(BinaryWriter writer, MasteryLevel obj) {
    switch (obj) {
      case MasteryLevel.learning:
        writer.writeByte(0);
        break;
      case MasteryLevel.practicing:
        writer.writeByte(1);
        break;
      case MasteryLevel.mastered:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
