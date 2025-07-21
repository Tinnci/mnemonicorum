import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/widgets/adaptive_scaffold.dart';
import 'package:mnemonicorum/widgets/progress_dashboard.dart';
import 'package:mnemonicorum/services/progress_service.dart';
import 'package:mnemonicorum/services/achievement_system.dart';
import 'package:mnemonicorum/repositories/formula_repository.dart';
import 'package:mnemonicorum/screens/review_session_screen.dart';

/// Screen displaying comprehensive progress tracking and achievements
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentRoute: '/progress',
      title: 'Progress',
      body: const _ProgressContent(),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<FormulaRepository>(
                    builder: (context, formulaRepository, child) {
                      final categories = formulaRepository.getCategories();
                      return ProgressDashboard(categories: categories);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Achievements Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<AchievementSystem>(
                    builder: (context, achievementSystem, child) {
                      final achievements = achievementSystem
                          .getAllAchievements();

                      if (achievements.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No achievements yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start practicing to earn your first achievement!',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        // 使用自适应列数布局
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200, // 成就卡片可以更小一些
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = achievements[index];
                          return Card(
                            color: achievement.isUnlocked
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min, // 添加这行
                                children: [
                                  Icon(
                                    achievement.icon,
                                    size: 32,
                                    color: achievement.isUnlocked
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    // 使用Expanded包装文本
                                    child: Text(
                                      achievement.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: achievement.isUnlocked
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    achievement.description,
                                    style: TextStyle(
                                      fontSize: 11, // 稍微减小字号
                                      color: achievement.isUnlocked
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Practice Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice Statistics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<ProgressService>(
                    builder: (context, progressService, child) {
                      final stats = progressService.getOverallStats();

                      return Column(
                        children: [
                          _buildStatRow(
                            context,
                            'Total Practice Sessions',
                            stats['totalSessions']?.toString() ?? '0',
                            Icons.quiz,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            'Questions Answered',
                            stats['totalQuestions']?.toString() ?? '0',
                            Icons.help_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            'Overall Accuracy',
                            '${stats['overallAccuracy']?.toStringAsFixed(1) ?? '0.0'}%',
                            Icons.gps_fixed,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            'Current Streak',
                            '${stats['currentStreak'] ?? 0} days',
                            Icons.local_fire_department,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Adaptive Review Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focused Review',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<ProgressService>(
                    builder: (context, progressService, child) {
                      // Check if there are any formulas with incorrect answers
                      final hasIncorrectAnswers = progressService
                          .getFormulasWithIncorrectAnswers(limit: 1)
                          .isNotEmpty;

                      // Check if there are any formulas for spaced repetition
                      final hasSpacedRepetition = progressService
                          .getFormulasForSpacedRepetition(limit: 1)
                          .isNotEmpty;

                      // Check if there are any recently incorrect formulas
                      final hasRecentlyIncorrect = progressService
                          .getRecentlyIncorrectFormulas(limit: 1)
                          .isNotEmpty;

                      if (!hasIncorrectAnswers &&
                          !hasSpacedRepetition &&
                          !hasRecentlyIncorrect) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '没有复习数据',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '完成一些练习后，这里将显示针对性的复习选项',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          if (hasIncorrectAnswers)
                            _buildReviewOption(
                              context,
                              '错题回顾',
                              '针对你经常答错的公式进行重点练习',
                              Icons.error_outline,
                              Colors.red.shade700,
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReviewSessionScreen(
                                        reviewMode: ReviewMode.incorrectAnswers,
                                      ),
                                ),
                              ),
                            ),

                          if (hasIncorrectAnswers &&
                              (hasSpacedRepetition || hasRecentlyIncorrect))
                            const SizedBox(height: 12),

                          if (hasSpacedRepetition)
                            _buildReviewOption(
                              context,
                              '间隔复习',
                              '基于记忆曲线优化的复习计划',
                              Icons.schedule,
                              Colors.blue.shade700,
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReviewSessionScreen(
                                        reviewMode: ReviewMode.spacedRepetition,
                                      ),
                                ),
                              ),
                            ),

                          if (hasSpacedRepetition && hasRecentlyIncorrect)
                            const SizedBox(height: 12),

                          if (hasRecentlyIncorrect)
                            _buildReviewOption(
                              context,
                              '最近错题',
                              '复习你最近一周内答错的公式',
                              Icons.history,
                              Colors.orange.shade700,
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReviewSessionScreen(
                                        reviewMode:
                                            ReviewMode.recentlyIncorrect,
                                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
