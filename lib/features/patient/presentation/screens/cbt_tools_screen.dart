import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class CbtToolsScreen extends ConsumerWidget {
  const CbtToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentProgress = ref.watch(cbtRecentProgressProvider);

    return AppScaffold(
      title: 'CBT Tools',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Text(
                    'CBT Tools',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ChiromoColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF8F0).withValues(alpha: 0.7),
                          const Color(0xFFFFEFD5).withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD6A5).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: const Color(0xFFC17817).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Personalized for you',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFFC17817,
                            ).withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Evidence-based CBT exercises to support your mental health journey.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ChiromoColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // ── New Exposure Ladder Banner ──
              _BannerCard(
                imagePath: 'assets/images/cbt_tools/exposure_ladder.png',
                icon: Icons.format_list_numbered_rounded,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: ChiromoColors.primary,
                title: 'New Exposure Ladder',
                subtitle: 'Build a hierarchy of fears to face gradually',
                onTap: () => context.push('/patient/cbt/exposure-ladder'),
              ),
              const SizedBox(height: 28),

              // ── CBT Exercises ──
              Text(
                'CBT Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChiromoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _ExerciseCard(
                imagePath: 'assets/images/cbt_tools/thought_record.png',
                icon: Icons.psychology_outlined,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF00897B),
                title: 'Thought Record',
                subtitle:
                    'Challenge negative thoughts & improve cognitive flexibility',
                onTap: () => context.push('/patient/cbt/thought-record'),
              ),
              const SizedBox(height: 12),
              _ExerciseCard(
                imagePath: 'assets/images/quick_actions/log_activity.png',
                icon: Icons.check_box_outlined,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFEF6C00),
                title: 'Behavioral Activation',
                subtitle: 'Schedule activities and build healthy routines',
                onTap: () => context.push('/patient/cbt/behavioral-activation'),
              ),
              const SizedBox(height: 12),
              _ExerciseCard(
                imagePath: 'assets/images/cbt_tools/exposure_ladder.png',
                icon: Icons.trending_up_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                title: 'Exposure Ladder',
                subtitle: 'Face fears gradually with a guided hierarchy',
                onTap: () => context.push('/patient/cbt/exposure-ladder'),
              ),
              const SizedBox(height: 12),
              _ExerciseCard(
                imagePath: 'assets/images/quick_actions/cbt_tools.png',
                icon: Icons.event_note_rounded,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: ChiromoColors.primary,
                title: 'Daily Check-in',
                subtitle: 'Track your mood, symptoms, and daily wins',
                onTap: () => context.push('/patient/cbt/daily-checkin'),
              ),
              const SizedBox(height: 32),

              // ── Recent Progress ──
              Row(
                children: [
                  Text(
                    'Recent Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              recentProgress.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: ChiromoColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No progress entries yet.\nComplete a CBT exercise to see your progress here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ChiromoColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.self_improvement_rounded,
                              size: 56,
                              color: ChiromoColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No progress entries yet',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ChiromoColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete a CBT exercise to track your journey',
                              style: TextStyle(
                                color: ChiromoColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: exercises
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProgressCard(exercise: e),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════

class _BannerCard extends StatelessWidget {
  final String? imagePath;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BannerCard({
    this.imagePath,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      elevation: 0.5,
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            imagePath!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor.withValues(alpha: 0.95),
                          size: 28,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: ChiromoColors.textSecondary.withValues(
                            alpha: 0.85,
                          ),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: ChiromoColors.textTertiary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String? imagePath;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExerciseCard({
    this.imagePath,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shadowColor: Colors.grey.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ChiromoColors.border.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    imagePath!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor.withValues(alpha: 0.9),
                  size: 26,
                ),
              ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: ChiromoColors.textSecondary.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        trailing: Icon(
          Icons.expand_more,
          color: ChiromoColors.textTertiary.withValues(alpha: 0.6),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Detailed information about $title goes here.',
                  style: TextStyle(color: ChiromoColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CbtExerciseEntity exercise;
  const _ProgressCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_monthName(exercise.createdAt.month)} ${exercise.createdAt.day}, ${exercise.createdAt.year}';

    final imagePath = _imageForType(exercise.type);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ChiromoColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/patient/cbt/exercise-details', extra: exercise);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imagePath,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exercise.type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: ChiromoColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTypeContent(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (exercise.isShared) ...[
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: ChiromoColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: ChiromoColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Private',
                      style: TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                  ],
                  if (exercise.hasDoctorFeedback) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: ChiromoColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dr. Feedback',
                      style: TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: ChiromoColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeContent() {
    switch (exercise.type) {
      case CbtExerciseType.dailyCheckin:
        return Row(
          children: [
            _MetricChip('Mood', '${exercise.mood ?? 0}/10'),
            const SizedBox(width: 16),
            _MetricChip('Anxiety', '${exercise.anxiety ?? 0}/10'),
            const SizedBox(width: 16),
            _MetricChip('Sleep', '${exercise.sleepHours ?? 0}h'),
          ],
        );
      case CbtExerciseType.thoughtRecord:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Situation: ${exercise.situation ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MetricChip('Relief', '${exercise.reliefPercent ?? 0}%'),
                const SizedBox(width: 16),
                _MetricChip(
                  'Anxiety Level',
                  '${exercise.anxietyBefore ?? 0}/10 → ${exercise.anxietyAfter ?? 0}/10',
                ),
              ],
            ),
          ],
        );
      case CbtExerciseType.behavioralActivation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity: ${exercise.activity ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MetricChip('Mood Lift', '+${exercise.moodLift ?? 0} pts'),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text(
                      'Streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise.streak ?? 0} days 🔥',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      case CbtExerciseType.exposureLadder:
        final current = exercise.currentStep ?? 0;
        final total = exercise.totalSteps ?? 1;
        final progress = total > 0 ? current / total : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fear: ${exercise.fear ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Step $current of $total',
              style: TextStyle(
                fontSize: 12,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: ChiromoColors.border,
                valueColor: AlwaysStoppedAnimation(ChiromoColors.primary),
              ),
            ),
          ],
        );
    }
  }

  String _imageForType(CbtExerciseType type) {
    switch (type) {
      case CbtExerciseType.dailyCheckin:
        return 'assets/images/quick_actions/cbt_tools.png';
      case CbtExerciseType.thoughtRecord:
        return 'assets/images/cbt_tools/thought_record.png';
      case CbtExerciseType.behavioralActivation:
        return 'assets/images/quick_actions/log_activity.png';
      case CbtExerciseType.exposureLadder:
        return 'assets/images/cbt_tools/exposure_ladder.png';
    }
  }

  String _monthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: ChiromoColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
