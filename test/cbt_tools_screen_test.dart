import 'package:chiromo/features/patient/domain/entities/cbt_exercise_entity.dart';
import 'package:chiromo/features/patient/presentation/providers/cbt_providers.dart';
import 'package:chiromo/features/patient/presentation/screens/cbt_exercise_details_screen.dart';
import 'package:chiromo/features/patient/presentation/screens/cbt_tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('tapping recent progress card shows real exercise details', (
    tester,
  ) async {
    final exercise = CbtExerciseEntity(
      id: 'exercise-1',
      patientId: 'patient-1',
      type: CbtExerciseType.exposureLadder,
      title: 'Exposure Ladder',
      data: {'fear': 'Public speaking', 'current_step': 3, 'total_steps': 7},
      isShared: false,
      hasDoctorFeedback: false,
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CbtToolsScreen()),
        GoRoute(
          path: '/patient/cbt/exercise-details',
          builder: (_, state) => CbtExerciseDetailsScreen(
            exercise: state.extra as CbtExerciseEntity,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cbtRecentProgressProvider.overrideWith((ref) async => [exercise]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('DETAILS').first);
    await tester.pumpAndSettle();

    // Verify exercise details are displayed on the details screen
    expect(find.textContaining('Public speaking'), findsWidgets);
    expect(find.textContaining('Exposure'), findsWidgets);
  });

  testWidgets(
    'exposure ladder details show a clear empty state when no fear is set',
    (tester) async {
      final exercise = CbtExerciseEntity(
        id: 'exercise-empty',
        patientId: 'patient-1',
        type: CbtExerciseType.exposureLadder,
        title: 'Exposure Ladder',
        data: {'fear': '', 'current_step': 0, 'total_steps': 0},
        isShared: false,
        hasDoctorFeedback: false,
        createdAt: DateTime(2026, 8, 12),
        updatedAt: DateTime(2026, 8, 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cbtRecentProgressProvider.overrideWith((ref) async => [exercise]),
          ],
          child: MaterialApp(
            home: Scaffold(body: CbtExerciseDetailsScreen(exercise: exercise)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No fear or challenge added yet.'), findsOneWidget);
      expect(
        find.text(
          'No progress yet. Complete your first step to start tracking.',
        ),
        findsOneWidget,
      );
    },
  );
}
