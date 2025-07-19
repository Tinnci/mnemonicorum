import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final String? formulaSetId;

  const ResultsScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    this.formulaSetId,
  });

  @override
  Widget build(BuildContext context) {
    // Handle edge cases for better user experience
    if (totalQuestions == 0) {
      return _buildEmptyStateScreen(context);
    }

    final accuracy = (correctAnswers / totalQuestions) * 100;
    final isExcellent = accuracy >= 90;
    final isGood = accuracy >= 70;
    final isPoor = accuracy < 50;

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
              // Congratulatory message based on performance
              _buildPerformanceMessage(accuracy, isExcellent, isGood, isPoor),
              const SizedBox(height: 30),

              // Results display
              _buildResultsDisplay(accuracy),

              const SizedBox(height: 40),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习结果'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 80, color: Colors.blue.shade300),
              const SizedBox(height: 24),
              const Text(
                '开始你的第一次练习！',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '选择一个公式类别开始学习吧',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/home');
                },
                icon: const Icon(Icons.home),
                label: const Text('返回主页'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMessage(
    double accuracy,
    bool isExcellent,
    bool isGood,
    bool isPoor,
  ) {
    String message;
    IconData icon;
    Color color;

    if (isExcellent) {
      message = '太棒了！';
      icon = Icons.emoji_events;
      color = Colors.amber;
    } else if (isGood) {
      message = '做得不错！';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (isPoor) {
      message = '继续努力！';
      icon = Icons.trending_up;
      color = Colors.orange;
    } else {
      message = '会话已完成！';
      icon = Icons.check_circle;
      color = Colors.blue;
    }

    return Column(
      children: [
        Icon(icon, size: 60, color: color),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsDisplay(double accuracy) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('正确', correctAnswers, Colors.green),
                _buildStatItem(
                  '错误',
                  totalQuestions - correctAnswers,
                  Colors.red,
                ),
                _buildStatItem('总计', totalQuestions, Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '准确率: ${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getAccuracyColor(accuracy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 70) return Colors.blue;
    if (accuracy >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action - Return to home
        ElevatedButton.icon(
          onPressed: () {
            context.go('/home');
          },
          icon: const Icon(Icons.home),
          label: const Text('返回主页'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 16),

        // Secondary actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: formulaSetId != null
                  ? () {
                      // Restart practice with the same formula set
                      context.go('/practice/$formulaSetId');
                    }
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('再次练习'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                context.go('/progress');
              },
              icon: const Icon(Icons.analytics),
              label: const Text('查看进度'),
            ),
          ],
        ),
      ],
    );
  }
}
