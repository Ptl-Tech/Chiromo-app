import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/clinical_model.dart';
import '../providers/clinical_providers.dart';

/// The patient's medication list, as their doctor maintains it.
///
/// Read-only. Nothing here is a reminder, an alarm, or an instruction the app
/// generates on its own — every word comes from the clinician who wrote it.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'My Medications', body: MedicationsView());
  }
}

/// The list itself, without a scaffold, so it can sit either on its own
/// screen or as a tab inside My Records without the two drifting apart.
class MedicationsView extends ConsumerWidget {
  const MedicationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationsProvider);

    return medications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetryWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(medicationsProvider),
      ),
      data: (all) {
        if (all.isEmpty) return const _EmptyState();

        final current = all.where((m) => m.active).toList();
        final past = all.where((m) => !m.active).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(medicationsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _ReviewBanner(),
              if (current.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionLabel('TAKING NOW'),
                const SizedBox(height: 8),
                for (final medication in current)
                  _MedicationCard(medication: medication),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionLabel('NO LONGER TAKING'),
                const SizedBox(height: 8),
                for (final medication in past)
                  _MedicationCard(medication: medication),
              ],
              const SizedBox(height: 20),
              const _Disclaimer(),
            ],
          ),
        );
      },
    );
  }
}

/// Says when a doctor last confirmed the list, and says so plainly when nobody
/// has in a long while.
///
/// This is the whole reason `lastReviewedOn` exists. A medication list is at
/// its most dangerous when it is stale and looks current — the patient has no
/// way to tell a list checked this morning from one nobody has opened in a
/// year, and both would otherwise be rendered with equal confidence.
class _ReviewBanner extends ConsumerWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewed = ref.watch(medicationsLastReviewedProvider).valueOrNull;
    final isStale = ref.watch(medicationsAreStaleProvider).valueOrNull ?? false;

    final Color background = isStale
        ? ChiromoColors.warningLight
        : ChiromoColors.primarySurface;
    final Color foreground = isStale
        ? ChiromoColors.warning
        : ChiromoColors.primaryDark;

    final String text;
    if (reviewed == null) {
      text =
          'This list has not been confirmed by your doctor yet. '
          'Please check it with them at your next visit.';
    } else if (isStale) {
      text =
          'Last checked by your doctor on ${_longDate(reviewed)}. '
          'It may be out of date — worth going through at your next visit.';
    } else {
      text = 'Last checked by your doctor on ${_longDate(reviewed)}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isStale || reviewed == null
                ? Icons.info_outline
                : Icons.verified_outlined,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.5, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    final active = medication.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? ChiromoColors.surface : ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  medication.drugName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? ChiromoColors.textPrimary
                        : ChiromoColors.textSecondary,
                  ),
                ),
              ),
              if (!active)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ChiromoColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    medication.status == MedicationStatus.stopped
                        ? 'Stopped'
                        : 'Finished',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          if (medication.instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              medication.instructions,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? ChiromoColors.textPrimary
                    : ChiromoColors.textSecondary,
              ),
            ),
          ],
          if (medication.regimen.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              medication.regimen,
              style: const TextStyle(
                fontSize: 12,
                color: ChiromoColors.textTertiary,
              ),
            ),
          ],
          if (!active && medication.stopReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ChiromoColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                medication.stopReason,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: ChiromoColors.textSecondary,
                ),
              ),
            ),
          ],
          if (medication.doctorName.isNotEmpty ||
              medication.startDate != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (medication.startDate != null)
                  'Started ${_longDate(medication.startDate!)}',
                if (medication.doctorName.isNotEmpty) medication.doctorName,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 11,
                color: ChiromoColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'This list is kept by your care team. If something here does not match '
        'what you were told, or you are unsure, contact the clinic rather than '
        'changing what you take.',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: ChiromoColors.textTertiary,
        ),
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
              Icons.medication_outlined,
              size: 64,
              color: ChiromoColors.primaryLighter,
            ),
            SizedBox(height: 16),
            Text(
              'No medications listed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anything your doctor prescribes and adds to your list will '
              'appear here after your visit.',
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

String _longDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
