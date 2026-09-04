import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/thought_record_model.dart';
import '../providers/thought_providers.dart';

/// The patient's thought records, newest first.
class ThoughtRecordScreen extends ConsumerWidget {
  const ThoughtRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(thoughtRecordsProvider);

    return AppScaffold(
      title: 'Thought Records',
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(thoughtRecordsProvider),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(onStart: () => _start(context))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(thoughtRecordsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _RecordCard(record: items[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _start(context),
        icon: const Icon(Icons.add),
        label: const Text('New record'),
        backgroundColor: ChiromoColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _start(BuildContext context) =>
      context.push('/patient/cbt/thought-record/new');
}

class _RecordCard extends StatelessWidget {
  final ThoughtRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final shift = record.shift;

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
          Row(
            children: [
              if (record.emotion.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ChiromoColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    record.emotion,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.primaryDark,
                    ),
                  ),
                ),
              const Spacer(),
              if (record.recordedAt != null)
                Text(
                  _shortDate(record.recordedAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // The thought is quoted rather than paraphrased: its wording is what
          // the exercise examined, and softening it here would misrepresent
          // what the patient actually did.
          Text(
            '“${record.automaticThought}”',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: ChiromoColors.textPrimary,
            ),
          ),
          if (record.balancedThought.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.subdirectory_arrow_right,
                  size: 16,
                  color: ChiromoColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.balancedThought,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${record.emotionBefore} → ${record.emotionAfter}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ChiromoColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              // Shown when it moved either way. A rise is real information and
              // hiding it would only flatter the tool.
              if (shift != 0)
                Text(
                  shift > 0 ? 'eased by $shift' : 'rose by ${-shift}',
                  style: TextStyle(
                    fontSize: 12,
                    color: shift > 0
                        ? ChiromoColors.statusCompleted
                        : ChiromoColors.warning,
                  ),
                ),
              const Spacer(),
              if (record.evidence.isNotEmpty)
                Text(
                  '${record.evidence.length} pieces of evidence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.psychology_outlined,
              size: 72,
              color: ChiromoColors.primaryLighter,
            ),
            const SizedBox(height: 20),
            const Text(
              'No thought records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When a thought keeps circling, this walks you through looking '
              'at what actually supports it — and what does not.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ChiromoButton(
              label: 'Work through a thought',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: onStart,
            ),
          ],
        ),
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
