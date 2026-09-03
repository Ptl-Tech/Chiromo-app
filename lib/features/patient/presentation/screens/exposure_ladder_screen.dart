import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/exposure_ladder_model.dart';
import '../providers/exposure_providers.dart';

/// The patient's exposure ladders.
///
/// A ladder is a graded list of situations, worked one rung at a time. A
/// patient may run several at once, each toward a different fear, so this is a
/// list rather than a single ladder.
class ExposureLadderScreen extends ConsumerWidget {
  const ExposureLadderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ladders = ref.watch(exposureLaddersProvider);

    return AppScaffold(
      title: 'Exposure Ladders',
      body: ladders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(exposureLaddersProvider),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(onCreate: () => _createLadder(context))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(exposureLaddersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return _AddLadderTile(
                        onTap: () => _createLadder(context),
                      );
                    }
                    return _LadderCard(
                      ladder: items[index],
                      onTap: () => context.push(
                        '/patient/cbt/exposure-ladder/${items[index].entryNo}',
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _createLadder(BuildContext context) {
    context.push('/patient/cbt/exposure-ladder/new');
  }
}

class _LadderCard extends StatelessWidget {
  final ExposureLadder ladder;
  final VoidCallback onTap;

  const _LadderCard({required this.ladder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = ladder.steps.length;
    final current = ladder.currentStepNumber;

    return Material(
      color: ChiromoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChiromoColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ChiromoColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.stairs_outlined,
                      color: ChiromoColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ladder.fear,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ChiromoColors.textPrimary,
                          ),
                        ),
                        if (ladder.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Started ${_formatDate(ladder.createdAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChiromoColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: ChiromoColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (total > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step $current of $total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    Text(
                      ladder.currentStep?.description ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ladder.progress,
                    minHeight: 6,
                    backgroundColor: ChiromoColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ChiromoColors.primary,
                    ),
                  ),
                ),
              ] else
                const Text(
                  'This ladder has no steps yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLadderTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddLadderTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ChiromoColors.primaryLighter),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20, color: ChiromoColors.primary),
            SizedBox(width: 8),
            Text(
              'New ladder',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ChiromoColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stairs_outlined,
              size: 72,
              color: ChiromoColors.primaryLighter,
            ),
            const SizedBox(height: 20),
            const Text(
              'No ladders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'An exposure ladder breaks a fear into small steps, '
              'starting with one that feels manageable today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ChiromoColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ChiromoButton(
              label: 'Build a ladder',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
