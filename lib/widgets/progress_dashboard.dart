import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/models/progress.dart';
import 'package:mnemonicorum/models/category.dart';
import 'package:mnemonicorum/services/progress_service.dart';

class ProgressDashboard extends StatelessWidget {
  final List<FormulaCategory> categories;

  const ProgressDashboard({super.key, required this.categories});

  String _getMasteryLevelText(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.learning:
        return '学习中';
      case MasteryLevel.practicing:
        return '练习中';
      case MasteryLevel.mastered:
        return '已掌握';
    }
  }

  Color _getMasteryLevelColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.learning:
        return Colors.red;
      case MasteryLevel.practicing:
        return Colors.orange;
      case MasteryLevel.mastered:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '你的学习进度',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...categories.map((category) {
              final categoryProgress = progressService
                  .getAllFormulaProgress()
                  .where(
                    (p) => category.formulaSets.any(
                      (set) => set.formulas.any((f) => f.id == p.formulaId),
                    ),
                  )
                  .toList(); // Remove .toList() here if it's unnecessary

              if (categoryProgress.isEmpty) {
                return const SizedBox.shrink();
              }

              final masteredCount = categoryProgress
                  .where((p) => p.masteryLevel == MasteryLevel.mastered)
                  .length;
              final totalFormulas = categoryProgress.length;
              final categoryMasteryPercentage = totalFormulas == 0
                  ? 0
                  : (masteredCount / totalFormulas * 100).round();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: totalFormulas == 0
                            ? 0
                            : masteredCount / totalFormulas,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '已掌握 $masteredCount / $totalFormulas ($categoryMasteryPercentage%)',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 10),
                      // Display individual formula progress (simplified for now)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryProgress.length,
                        itemBuilder: (context, index) {
                          final formulaProgress = categoryProgress[index];
                          // Find the actual formula name (requires FormulaRepository or passing formulas down)
                          // For now, using formulaId as placeholder
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '公式 ID: ${formulaProgress.formulaId}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getMasteryLevelColor(
                                    formulaProgress.masteryLevel,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _getMasteryLevelText(
                                    formulaProgress.masteryLevel,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
