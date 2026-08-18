import 'package:chiromo/features/patient/domain/entities/cbt_exercise_entity.dart';
import 'package:chiromo/features/patient/presentation/providers/cbt_providers.dart';
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
      routes: [GoRoute(path: '/', builder: (_, __) => const CbtToolsScreen())],
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

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    // Verify dialog opened with Close button
    expect(find.text('Close'), findsOneWidget);

    // Verify exercise details are displayed
    expect(find.textContaining('Public speaking'), findsWidgets);
    expect(find.textContaining('Exposure'), findsWidgets);
  });
}
