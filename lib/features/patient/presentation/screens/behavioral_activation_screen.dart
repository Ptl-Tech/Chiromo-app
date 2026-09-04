import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/activity_plan_model.dart';
import '../providers/activity_providers.dart';
import '../widgets/activity_plan_sheet.dart';

/// Behavioural activation: plan something, predict how it will go, then record
/// what actually happened.
///
/// The screen leads with activities whose day has passed and were never marked
/// either way. Those are the ones that matter most — the prompt to say what
/// happened is the step that produces the evidence, and an activity that
/// quietly ages out produces none.
class BehavioralActivationScreen extends ConsumerWidget {
  const BehavioralActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(activityPlansProvider);

    return AppScaffold(
      title: 'Activities',
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(activityPlansProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return _EmptyState(onPlan: () => _plan(context, ref));
          }

          final awaiting = all.where((a) => a.isOverdue).toList();
          final upcoming = all.where((a) => a.isUpcoming).toList();
          final finished = all.where((a) => !a.isPlanned).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activityPlansProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (awaiting.isNotEmpty) ...[
                  const _SectionLabel('HOW DID THESE GO?'),
                  const SizedBox(height: 8),
                  for (final plan in awaiting)
                    _PlanCard(
                      plan: plan,
                      onTap: () => _record(context, ref, plan),
                    ),
                  const SizedBox(height: 20),
                ],
                if (upcoming.isNotEmpty) ...[
                  const _SectionLabel('COMING UP'),
                  const SizedBox(height: 8),
                  for (final plan in upcoming)
                    _PlanCard(
                      plan: plan,
                      onTap: () => _record(context, ref, plan),
                    ),
                  const SizedBox(height: 20),
                ],
                if (finished.isNotEmpty) ...[
                  const _SectionLabel('ALREADY DONE'),
                  const SizedBox(height: 8),
                  for (final plan in finished) _PlanCard(plan: plan),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _plan(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Plan something'),
        backgroundColor: ChiromoColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _plan(BuildContext context, WidgetRef ref) =>
      showActivityPlanSheet(context: context, ref: ref);

  void _record(BuildContext context, WidgetRef ref, ActivityPlan plan) =>
      showActivityPlanSheet(context: context, ref: ref, existing: plan);
}

class _PlanCard extends StatelessWidget {
  final ActivityPlan plan;
  final VoidCallback? onTap;

  const _PlanCard({required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = plan.status == ActivityStatus.done;
    final skipped = plan.status == ActivityStatus.skipped;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: skipped
                ? ChiromoColors.surfaceVariant
                : ChiromoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: plan.isOverdue
                  ? ChiromoColors.warning
                  : ChiromoColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.activity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                  ),
                  if (plan.plannedAt != null)
                    Text(
                      _shortDate(plan.plannedAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                ],
              ),
              if (plan.isPlanned) ...[
                const SizedBox(height: 8),
                Text(
                  'You expect ${plan.anticipatedPleasure}/10 enjoyment · '
                  '${plan.anticipatedAchievement}/10 sense of achievement',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
                if (plan.isOverdue) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Tap to record what happened — including if it did not.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ChiromoColors.warning,
                    ),
                  ),
                ],
              ],
              if (skipped) ...[
                const SizedBox(height: 8),
                Text(
                  plan.skipReason.isEmpty
                      ? 'Did not happen'
                      : 'Did not happen — ${plan.skipReason}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
              ],
              if (done) ...[
                const SizedBox(height: 12),
                _Comparison(
                  label: 'Enjoyment',
                  expected: plan.anticipatedPleasure,
                  actual: plan.actualPleasure,
                  surprise: plan.pleasureSurprise,
                ),
                const SizedBox(height: 6),
                _Comparison(
                  label: 'Achievement',
                  expected: plan.anticipatedAchievement,
                  actual: plan.actualAchievement,
                  surprise: plan.achievementSurprise,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Expected against actual, on one line.
///
/// The difference is shown in both directions. A tool that only reports
/// pleasant surprises is flattering itself, and an activity that went worse
/// than expected is information the patient and their clinician can use.
class _Comparison extends StatelessWidget {
  final String label;
  final int expected;
  final int actual;
  final int? surprise;

  const _Comparison({
    required this.label,
    required this.expected,
    required this.actual,
    required this.surprise,
  });

  @override
  Widget build(BuildContext context) {
    final delta = surprise ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ChiromoColors.textTertiary,
            ),
          ),
        ),
        Text(
          'expected $expected',
          style: const TextStyle(
            fontSize: 13,
            color: ChiromoColors.textSecondary,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward,
            size: 13,
            color: ChiromoColors.textTertiary,
          ),
        ),
        Text(
          'was $actual',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ChiromoColors.textPrimary,
          ),
        ),
        if (surprise != null && delta != 0) ...[
          const SizedBox(width: 8),
          Text(
            delta > 0 ? '+$delta' : '$delta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: delta > 0
                  ? ChiromoColors.statusCompleted
                  : ChiromoColors.warning,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPlan;

  const _EmptyState({required this.onPlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 72,
              color: ChiromoColors.primaryLighter,
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing planned yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting to feel like doing something often means waiting a long '
              'time. Plan one small thing, guess how it will go, then see what '
              'actually happens.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ChiromoButton(
              label: 'Plan something',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: onPlan,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ChiromoColors.textTertiary,
      ),
    );
  }
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
