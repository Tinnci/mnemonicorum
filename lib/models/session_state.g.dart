// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionStateAdapter extends TypeAdapter<SessionState> {
  @override
  final int typeId = 20;

  @override
  SessionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionState(
      formulaIds: (fields[0] as List).cast<String>(),
      currentExerciseIndex: fields[1] as int,
      correctAnswers: fields[2] as int,
      incorrectAnswers: fields[3] as int,
      lastUpdated: fields[4] as DateTime,
      sessionId: fields[5] as String,
      exerciseTypes: (fields[6] as List).cast<String>(),
      exerciseResults: (fields[7] as Map).cast<String, bool>(),
      sessionType: fields[8] as String?,
      reviewMode: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionState obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.formulaIds)
      ..writeByte(1)
      ..write(obj.currentExerciseIndex)
      ..writeByte(2)
      ..write(obj.correctAnswers)
      ..writeByte(3)
      ..write(obj.incorrectAnswers)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.sessionId)
      ..writeByte(6)
      ..write(obj.exerciseTypes)
      ..writeByte(7)
      ..write(obj.exerciseResults)
      ..writeByte(8)
      ..write(obj.sessionType)
      ..writeByte(9)
      ..write(obj.reviewMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
