import 'package:go_router/go_router.dart';

import 'package:mnemonicorum/screens/onboarding_screen.dart';
import 'package:mnemonicorum/screens/home_screen.dart';
import 'package:mnemonicorum/screens/practice_screen.dart';
import 'package:mnemonicorum/screens/progress_screen.dart';
import 'package:mnemonicorum/screens/category_screen.dart';
import 'package:mnemonicorum/screens/practice_session_screen.dart';
import 'package:mnemonicorum/screens/results_screen.dart';
import 'package:mnemonicorum/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/practice',
      builder: (context, state) => const PracticeScreen(),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/category/:categoryId',
      builder: (context, state) =>
          CategoryScreen(categoryId: state.pathParameters['categoryId']!),
    ),
    GoRoute(
      path: '/practice/:formulaSetId',
      builder: (context, state) => PracticeSessionScreen(
        formulaSetId: state.pathParameters['formulaSetId']!,
      ),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final correct = int.parse(state.uri.queryParameters['correct'] ?? '0');
        final total = int.parse(state.uri.queryParameters['total'] ?? '0');
        return ResultsScreen(correctAnswers: correct, totalQuestions: total);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
