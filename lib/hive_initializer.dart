import 'package:hive_flutter/hive_flutter.dart';
import 'package:mnemonicorum/models/category.dart';
import 'package:mnemonicorum/models/formula.dart';
import 'package:mnemonicorum/models/progress.dart';

void registerHiveAdapters() {
  Hive.registerAdapter(MasteryLevelAdapter());
  Hive.registerAdapter(ExerciseAttemptAdapter());
  Hive.registerAdapter(FormulaProgressAdapter());
  Hive.registerAdapter(DifficultyLevelAdapter());
  Hive.registerAdapter(ComponentTypeAdapter());
  Hive.registerAdapter(FormulaComponentAdapter());
  Hive.registerAdapter(FormulaAdapter());
  Hive.registerAdapter(FormulaSetAdapter());
  Hive.registerAdapter(FormulaCategoryAdapter());
}
