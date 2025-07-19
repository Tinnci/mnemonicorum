import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/screens/all_formulas_screen.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';

void main() {
  testWidgets('AllFormulasScreen should show loading indicator initially', (
    WidgetTester tester,
  ) async {
    final mockRepository = FormulaRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<FormulaRepository>.value(
          value: mockRepository,
          child: const AllFormulasScreen(),
        ),
      ),
    );

    // 验证加载指示器是否存在
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AllFormulasScreen should display title', (
    WidgetTester tester,
  ) async {
    final mockRepository = FormulaRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<FormulaRepository>.value(
          value: mockRepository,
          child: const AllFormulasScreen(),
        ),
      ),
    );

    // 验证标题是否存在
    expect(find.text('所有公式'), findsOneWidget);
  });
}
