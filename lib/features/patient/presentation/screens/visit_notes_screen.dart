import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/clinical_model.dart';
import '../providers/clinical_providers.dart';

/// Notes the patient's doctors have written for them, newest first.
class VisitNotesScreen extends StatelessWidget {
  const VisitNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Notes From Your Visits',
      body: VisitNotesView(),
    );
  }
}

/// The list itself, without a scaffold, so it can sit either on its own
/// screen or as a tab inside My Records without the two drifting apart.
class VisitNotesView extends ConsumerWidget {
  const VisitNotesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(visitNotesProvider);

    return notes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetryWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(visitNotesProvider),
      ),
      data: (items) {
        if (items.isEmpty) return const _EmptyState();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(visitNotesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => VisitNoteCard(note: items[index]),
          ),
        );
      },
    );
  }
}

/// One note. Public because the appointment detail screen renders the same
/// card under an attended appointment — the same note should not look like two
/// different things depending on where it is read.
class VisitNoteCard extends StatelessWidget {
  final VisitNote note;

  const VisitNoteCard({required this.note, super.key});

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
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: ChiromoColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.doctorName.isEmpty ? 'Your care team' : note.doctorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
              ),
              if (note.date != null)
                Text(
                  _shortDate(note.date!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
            ],
          ),
          if (note.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              note.summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: ChiromoColors.textPrimary,
              ),
            ),
          ],
          if (note.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChiromoColors.goldSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHAT TO DO NEXT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ChiromoColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.nextSteps,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: ChiromoColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: ChiromoColors.primaryLighter,
            ),
            SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'After a visit, anything your doctor writes for you will appear '
              'here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
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
