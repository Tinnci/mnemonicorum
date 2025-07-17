import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;

  const ResultsScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions == 0
        ? 0.0
        : (correctAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习结果'),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '会话已完成！',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(
                '正确答案: $correctAnswers / $totalQuestions',
                style: TextStyle(fontSize: 22, color: Colors.green[700]),
              ),
              const SizedBox(height: 10),
              Text(
                '准确率: ${accuracy.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 22, color: Colors.blue[700]),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('返回主页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
