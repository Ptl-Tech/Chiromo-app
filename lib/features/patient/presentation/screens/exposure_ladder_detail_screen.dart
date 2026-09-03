import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/exposure_ladder_model.dart';
import '../providers/exposure_providers.dart';

/// One ladder: its rungs, the one the patient is on, and what they have logged
/// against it.
///
/// The rungs are drawn bottom-up, easiest at the bottom, because that is what
/// a ladder looks like and because it puts the next step directly above where
/// the patient is now.
class ExposureLadderDetailScreen extends ConsumerWidget {
  final int entryNo;

  const ExposureLadderDetailScreen({required this.entryNo, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ladderAsync = ref.watch(exposureLadderProvider(entryNo));

    return AppScaffold(
      title: 'Your Ladder',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete ladder',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
      body: ladderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(exposureLaddersProvider),
        ),
        data: (ladder) {
          if (ladder == null) {
            return const Center(child: Text('That ladder is no longer here.'));
          }
          return _LadderBody(ladder: ladder);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this ladder?'),
        content: const Text(
          'The ladder and every session you have logged against it will be '
          'removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChiromoColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(exposureNotifierProvider.notifier).deleteLadder(entryNo);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _LadderBody extends ConsumerWidget {
  final ExposureLadder ladder;

  const _LadderBody({required this.ladder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ladder.currentStep;
    // Highest rung first, so the list reads as a ladder standing up.
    final rungs = ladder.steps.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _FearHeader(ladder: ladder),
        const SizedBox(height: 20),
        for (final step in rungs)
          _RungTile(
            step: step,
            ladder: ladder,
            isCurrent: step.rank == ladder.currentStepRank,
            onTap: () => _moveTo(context, ref, step.rank),
          ),
        const SizedBox(height: 24),
        if (current != null) ...[
          _CurrentStepCard(ladder: ladder, step: current),
          const SizedBox(height: 20),
          _StepHistory(ladderEntryNo: ladder.entryNo, rank: current.rank),
        ],
      ],
    );
  }

  /// Moving between rungs is always the patient's own action. Nothing here
  /// advances a ladder for them, and moving back down is offered as plainly as
  /// moving up — after a hard session that is often the right call, and a UI
  /// that only goes one way pushes people to either stall or overreach.
  Future<void> _moveTo(BuildContext context, WidgetRef ref, int rank) async {
    if (rank == ladder.currentStepRank) return;

    try {
      await ref
          .read(exposureNotifierProvider.notifier)
          .setCurrentStep(ladderEntryNo: ladder.entryNo, stepRank: rank);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _FearHeader extends StatelessWidget {
  final ExposureLadder ladder;

  const _FearHeader({required this.ladder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORKING TOWARDS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ChiromoColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ladder.fear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ChiromoColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (ladder.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Step ${ladder.currentStepNumber} of ${ladder.steps.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ChiromoColors.primaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RungTile extends StatelessWidget {
  final ExposureStep step;
  final ExposureLadder ladder;
  final bool isCurrent;
  final VoidCallback onTap;

  const _RungTile({
    required this.step,
    required this.ladder,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Rungs below where the patient is are ones they have moved past. They are
    // shown in full and stay tappable: this is a record of their own choices,
    // not a game board, so nothing here is locked.
    final isBelow = step.rank < ladder.currentStepRank;

    final Color accent = isCurrent
        ? ChiromoColors.primary
        : isBelow
        ? ChiromoColors.success
        : ChiromoColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent
                ? ChiromoColors.primarySurface
                : ChiromoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? ChiromoColors.primary : ChiromoColors.border,
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${step.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    if (step.suggestedSuds > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Often around ${step.suggestedSuds}/10 to start',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ChiromoColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrent)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.my_location,
                    size: 18,
                    color: ChiromoColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentStepCard extends StatelessWidget {
  final ExposureLadder ladder;
  final ExposureStep step;

  const _CurrentStepCard({required this.ladder, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR CURRENT STEP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ChiromoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: ChiromoColors.textPrimary,
            ),
          ),
          if (step.guidance.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChiromoColors.goldSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                step.guidance,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ChiromoButton(
            label: 'Log a session',
            icon: Icons.add,
            onPressed: () => context.push(
              '/patient/cbt/exposure-ladder/${ladder.entryNo}/log?rank=${step.rank}',
            ),
          ),
        ],
      ),
    );
  }
}

/// The patient's own recent attempts at this rung, oldest first.
///
/// This is the whole reason trials are kept rather than counted. Inside any
/// one session the anxiety just feels bad — that is what makes it a session.
/// The evidence that the work is doing something only appears across repeats,
/// and without seeing it people reasonably conclude it is not helping and stop.
///
/// Deliberately just the numbers: no praise, no "ready to move up", no verdict.
/// The moment this interprets, it makes a clinical claim that will be wrong for
/// someone. It also stays hidden until there are at least two attempts, because
/// a single row framed as a trend says nothing, and a flat line labelled
/// progress is discouraging.
class _StepHistory extends ConsumerWidget {
  final int ladderEntryNo;
  final int rank;

  const _StepHistory({required this.ladderEntryNo, required this.rank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(
      stepTrialsProvider((ladderEntryNo: ladderEntryNo, rank: rank)),
    );

    return trials.maybeWhen(
      data: (items) {
        if (items.length < 2) return const SizedBox.shrink();

        final recent = items.length > 5
            ? items.sublist(items.length - 5)
            : items;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ChiromoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChiromoColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR RECENT ATTEMPTS AT THIS STEP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ChiromoColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              for (final trial in recent) _TrialRow(trial: trial),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TrialRow extends StatelessWidget {
  final ExposureTrial trial;

  const _TrialRow({required this.trial});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              trial.recordedAt == null ? '' : _shortDate(trial.recordedAt!),
              style: const TextStyle(
                fontSize: 12,
                color: ChiromoColors.textTertiary,
              ),
            ),
          ),
          Text(
            '${trial.sudsBefore}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ChiromoColors.textPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward,
              size: 14,
              color: ChiromoColors.textTertiary,
            ),
          ),
          Text(
            '${trial.sudsAfter}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ChiromoColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (trial.notes.isNotEmpty)
            const Icon(
              Icons.sticky_note_2_outlined,
              size: 15,
              color: ChiromoColors.textTertiary,
            ),
        ],
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
