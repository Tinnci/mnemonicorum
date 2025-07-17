import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final formulaRepository = Provider.of<FormulaRepository>(context);
    final category = formulaRepository.getAllCategories().firstWhere(
      (cat) => cat.id == categoryId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Text(
              '公式集',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.formulaSets.length,
              itemBuilder: (context, index) {
                final formulaSet = category.formulaSets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      formulaSet.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('难度: ${formulaSet.difficulty.name}'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to Practice Session Screen
                      context.go('/practice/${formulaSet.id}');
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
