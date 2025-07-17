// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formula.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FormulaComponentAdapter extends TypeAdapter<FormulaComponent> {
  @override
  final int typeId = 7;

  @override
  FormulaComponent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaComponent(
      id: fields[0] as String,
      latexPart: fields[1] as String,
      type: fields[2] as ComponentType,
      description: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FormulaComponent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latexPart)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaComponentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaAdapter extends TypeAdapter<Formula> {
  @override
  final int typeId = 8;

  @override
  Formula read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Formula(
      id: fields[0] as String,
      name: fields[1] as String,
      latexExpression: fields[2] as String,
      category: fields[3] as String,
      subcategory: fields[4] as String,
      difficulty: fields[5] as DifficultyLevel,
      tags: (fields[6] as List).cast<String>(),
      description: fields[7] as String,
      components: (fields[8] as List).cast<FormulaComponent>(),
      semanticDescription: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Formula obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latexExpression)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subcategory)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.components)
      ..writeByte(9)
      ..write(obj.semanticDescription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 5;

  @override
  DifficultyLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DifficultyLevel.easy;
      case 1:
        return DifficultyLevel.medium;
      case 2:
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.easy;
    }
  }

  @override
  void write(BinaryWriter writer, DifficultyLevel obj) {
    switch (obj) {
      case DifficultyLevel.easy:
        writer.writeByte(0);
        break;
      case DifficultyLevel.medium:
        writer.writeByte(1);
        break;
      case DifficultyLevel.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ComponentTypeAdapter extends TypeAdapter<ComponentType> {
  @override
  final int typeId = 6;

  @override
  ComponentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ComponentType.leftSide;
      case 1:
        return ComponentType.rightSide;
      case 2:
        return ComponentType.variable;
      case 3:
        return ComponentType.constant;
      default:
        return ComponentType.leftSide;
    }
  }

  @override
  void write(BinaryWriter writer, ComponentType obj) {
    switch (obj) {
      case ComponentType.leftSide:
        writer.writeByte(0);
        break;
      case ComponentType.rightSide:
        writer.writeByte(1);
        break;
      case ComponentType.variable:
        writer.writeByte(2);
        break;
      case ComponentType.constant:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
