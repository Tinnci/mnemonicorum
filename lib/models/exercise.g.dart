// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseOptionAdapter extends TypeAdapter<ExerciseOption> {
  @override
  final int typeId = 10;

  @override
  ExerciseOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseOption(
      id: fields[0] as String,
      latexExpression: fields[1] as String,
      textLabel: fields[2] as String,
      isCorrect: fields[3] as bool,
      pairId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseOption obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latexExpression)
      ..writeByte(2)
      ..write(obj.textLabel)
      ..writeByte(3)
      ..write(obj.isCorrect)
      ..writeByte(4)
      ..write(obj.pairId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 11;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      formula: fields[1] as Formula,
      type: fields[2] as ExerciseType,
      question: fields[3] as String,
      options: (fields[4] as List).cast<ExerciseOption>(),
      correctAnswerId: fields[5] as String,
      explanation: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.formula)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.question)
      ..writeByte(4)
      ..write(obj.options)
      ..writeByte(5)
      ..write(obj.correctAnswerId)
      ..writeByte(6)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseTypeAdapter extends TypeAdapter<ExerciseType> {
  @override
  final int typeId = 9;

  @override
  ExerciseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseType.matching;
      case 1:
        return ExerciseType.completion;
      case 2:
        return ExerciseType.recognition;
      case 3:
        return ExerciseType.multiMatching;
      default:
        return ExerciseType.matching;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseType obj) {
    switch (obj) {
      case ExerciseType.matching:
        writer.writeByte(0);
        break;
      case ExerciseType.completion:
        writer.writeByte(1);
        break;
      case ExerciseType.recognition:
        writer.writeByte(2);
        break;
      case ExerciseType.multiMatching:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
