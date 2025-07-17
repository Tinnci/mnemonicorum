// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FormulaSetAdapter extends TypeAdapter<FormulaSet> {
  @override
  final int typeId = 15;

  @override
  FormulaSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaSet(
      id: fields[0] as String,
      name: fields[1] as String,
      formulas: (fields[2] as List).cast<Formula>(),
      difficulty: fields[3] as DifficultyLevel,
    );
  }

  @override
  void write(BinaryWriter writer, FormulaSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.formulas)
      ..writeByte(3)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaCategoryAdapter extends TypeAdapter<FormulaCategory> {
  @override
  final int typeId = 16;

  @override
  FormulaCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      formulaSets: (fields[3] as List).cast<FormulaSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, FormulaCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.formulaSets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
