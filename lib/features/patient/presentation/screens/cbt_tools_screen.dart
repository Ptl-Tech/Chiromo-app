import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../providers/activity_providers.dart';
import '../providers/checkin_providers.dart';
import '../providers/exposure_providers.dart';
import '../providers/thought_providers.dart';

/// The four tools, each showing where the patient actually is with it.
///
/// The status lines replace what used to be a separate "Recent Progress"
/// section. That section read the Supabase `cbt_exercises` table, which
/// nothing writes to any more now that all four tools are backed by Business
/// Central — so it could only ever have rendered empty or stale. Per-tool
/// state is also more use than a combined feed: the question someone opens
/// this screen with is "what should I pick up?", not "what did I do?".
class CbtToolsScreen extends ConsumerWidget {
  const CbtToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'CBT Tools',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(thoughtRecordsProvider);
          ref.invalidate(activityPlansProvider);
          ref.invalidate(exposureLaddersProvider);
          ref.invalidate(checkinHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Practical exercises to work through between visits. '
              'Pick up whichever fits today.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _ToolCard(
              imagePath: 'assets/images/quick_actions/cbt_tools.png',
              icon: Icons.event_note_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: ChiromoColors.primary,
              title: 'Daily Check-in',
              blurb: 'Track your mood, sleep and how the day went',
              status: _checkinStatus(ref),
              onTap: () => context.push('/patient/cbt/daily-checkin'),
            ),
            _ToolCard(
              imagePath: 'assets/images/cbt_tools/thought_record.png',
              icon: Icons.psychology_outlined,
              iconBg: const Color(0xFFE0F2F1),
              iconColor: const Color(0xFF00897B),
              title: 'Thought Record',
              blurb: 'Take a thought apart and look at what supports it',
              status: _thoughtStatus(ref),
              onTap: () => context.push('/patient/cbt/thought-record'),
            ),
            _ToolCard(
              imagePath: 'assets/images/quick_actions/log_activity.png',
              icon: Icons.check_box_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFEF6C00),
              title: 'Activities',
              blurb: 'Plan something, then see how it actually went',
              status: _activityStatus(ref),
              onTap: () => context.push('/patient/cbt/behavioral-activation'),
            ),
            _ToolCard(
              imagePath: 'assets/images/cbt_tools/exposure_ladder.png',
              icon: Icons.stairs_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              title: 'Exposure Ladder',
              blurb: 'Face a fear one manageable step at a time',
              status: _ladderStatus(ref),
              onTap: () => context.push('/patient/cbt/exposure-ladder'),
            ),
          ],
        ),
      ),
    );
  }

  /// A status is only shown when there is something true to say. No data means
  /// no line, rather than a zero dressed up as progress.
  _Status? _checkinStatus(WidgetRef ref) {
    final checkins = ref.watch(checkinHistoryProvider).valueOrNull;
    if (checkins == null || checkins.isEmpty) return null;

    final last = checkins.first.recordedAt;
    if (last == null) return null;

    final today = DateTime.now();
    final sameDay =
        last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;

    return sameDay
        ? const _Status('Checked in today')
        : _Status('Last check-in ${_shortDate(last)}');
  }

  _Status? _thoughtStatus(WidgetRef ref) {
    final records = ref.watch(thoughtRecordsProvider).valueOrNull;
    if (records == null || records.isEmpty) return null;
    return _Status(
      '${records.length} ${records.length == 1 ? 'record' : 'records'}',
    );
  }

  _Status? _activityStatus(WidgetRef ref) {
    final plans = ref.watch(activityPlansProvider).valueOrNull;
    if (plans == null || plans.isEmpty) return null;

    // An activity whose day has passed unmarked is the one thing here worth
    // interrupting for: recording what happened is the step that produces the
    // evidence, and it stops being possible to recall accurately with time.
    final awaiting = plans.where((p) => p.isOverdue).length;
    if (awaiting > 0) {
      return _Status('$awaiting waiting to be recorded', needsAttention: true);
    }

    final upcoming = plans.where((p) => p.isUpcoming).length;
    if (upcoming > 0) return _Status('$upcoming planned');

    return _Status('${plans.length} recorded');
  }

  _Status? _ladderStatus(WidgetRef ref) {
    final ladders = ref.watch(exposureLaddersProvider).valueOrNull;
    if (ladders == null || ladders.isEmpty) return null;
    return _Status(
      ladders.length == 1
          ? 'Step ${ladders.first.currentStepNumber} of '
                '${ladders.first.steps.length}'
          : '${ladders.length} ladders on the go',
    );
  }
}

class _Status {
  final String text;
  final bool needsAttention;

  const _Status(this.text, {this.needsAttention = false});
}

class _ToolCard extends StatelessWidget {
  final String? imagePath;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String blurb;
  final _Status? status;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.blurb,
    required this.onTap,
    this.imagePath,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final current = status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: current?.needsAttention ?? false
                    ? ChiromoColors.warning
                    : ChiromoColors.border,
              ),
            ),
            child: Row(
              children: [
                _Leading(
                  imagePath: imagePath,
                  icon: icon,
                  iconBg: iconBg,
                  iconColor: iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ChiromoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        blurb,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: ChiromoColors.textSecondary,
                        ),
                      ),
                      if (current != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          current.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: current.needsAttention
                                ? ChiromoColors.warning
                                : ChiromoColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ChiromoColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final String? imagePath;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _Leading({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          // A missing asset should cost an image, not the screen.
          errorBuilder: (_, _, _) => _iconBox(),
        ),
      );
    }
    return _iconBox();
  }

  Widget _iconBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 24),
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
