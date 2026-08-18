import 'package:flutter/material.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../../../../theme/chiromo_colors.dart';

class CbtExerciseDetailsScreen extends StatelessWidget {
  final CbtExerciseEntity exercise;

  const CbtExerciseDetailsScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          exercise.type.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ChiromoColors.primary.withValues(alpha: 0.8),
                    ChiromoColors.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForType(exercise.type),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.type.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(exercise.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (exercise.isShared) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Shared with therapist',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Exercise Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildExerciseContent(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseContent() {
    final widgets = <Widget>[];

    switch (exercise.type) {
      case CbtExerciseType.dailyCheckin:
        widgets.addAll([
          _buildMetricsSection(
            title: 'Daily Check-in',
            children: [
              _MetricCard(
                icon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Mood',
                value: '${exercise.mood ?? 0}/10',
                color: const Color(0xFFFFC107),
              ),
              _MetricCard(
                icon: Icons.sentiment_very_dissatisfied,
                label: 'Anxiety',
                value: '${exercise.anxiety ?? 0}/10',
                color: const Color(0xFFFF6B6B),
              ),
              _MetricCard(
                icon: Icons.nights_stay_rounded,
                label: 'Sleep',
                value: '${exercise.sleepHours ?? 0}h',
                color: const Color(0xFF2196F3),
              ),
            ],
          ),
        ]);
        break;

      case CbtExerciseType.thoughtRecord:
        widgets.addAll([
          _buildSectionTitle('Situation'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChiromoColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exercise.situation ?? 'N/A',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricsSection(
            title: 'Impact',
            children: [
              _MetricCard(
                icon: Icons.trending_down_rounded,
                label: 'Relief',
                value: '${exercise.reliefPercent ?? 0}%',
                color: Colors.green,
              ),
              _MetricCard(
                icon: Icons.show_chart,
                label: 'Anxiety Before',
                value: '${exercise.anxietyBefore ?? 0}/10',
                color: const Color(0xFFFF6B6B),
              ),
              _MetricCard(
                icon: Icons.check_circle,
                label: 'Anxiety After',
                value: '${exercise.anxietyAfter ?? 0}/10',
                color: Colors.green,
              ),
            ],
          ),
        ]);
        break;

      case CbtExerciseType.behavioralActivation:
        widgets.addAll([
          _buildSectionTitle('Activity'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChiromoColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exercise.activity ?? 'N/A',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricsSection(
            title: 'Results',
            children: [
              _MetricCard(
                icon: Icons.trending_up_rounded,
                label: 'Mood Lift',
                value: '+${exercise.moodLift ?? 0} pts',
                color: Colors.green,
              ),
              _MetricCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${exercise.streak ?? 0} days',
                color: const Color(0xFFFFC107),
              ),
            ],
          ),
        ]);
        break;

      case CbtExerciseType.exposureLadder:
        widgets.addAll([
          _buildSectionTitle('Fear/Challenge'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChiromoColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exercise.fear ?? 'N/A',
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Progress'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChiromoColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${exercise.currentStep ?? 0} of ${exercise.totalSteps ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(((exercise.currentStep ?? 0) / (exercise.totalSteps ?? 1)) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: ChiromoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (exercise.currentStep ?? 0) /
                        (exercise.totalSteps ?? 1),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ]);
        break;
    }

    // ── Add Reflection Questions Section ──
    final reflectionAnswers = _extractReflectionAnswers();
    if (reflectionAnswers.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 24),
        _buildSectionTitle('Your Reflections'),
        const SizedBox(height: 12),
        ...reflectionAnswers.map(
          (qa) => _ReflectionCard(
            question: qa['question'] as String,
            answer: qa['answer'] as String,
          ),
        ),
      ]);
    }

    return widgets;
  }

  List<Map<String, String>> _extractReflectionAnswers() {
    final answers = <Map<String, String>>[];

    switch (exercise.type) {
      case CbtExerciseType.exposureLadder:
        // For exposure ladder, answers are stored in steps array
        final steps = exercise.data['steps'] as List<dynamic>?;
        if (steps != null && steps.isNotEmpty) {
          for (final step in steps) {
            if (step is Map) {
              final stepAnswers =
                  step['reflectionAnswers'] as Map<dynamic, dynamic>?;
              if (stepAnswers != null && stepAnswers.isNotEmpty) {
                for (final entry in stepAnswers.entries) {
                  final answer = entry.value?.toString() ?? '';
                  if (answer.isNotEmpty) {
                    answers.add({
                      'question': entry.key.toString(),
                      'answer': answer,
                    });
                  }
                }
              }
            }
          }
        }
        break;
      case CbtExerciseType.thoughtRecord:
        // Thought record has its own Q&A structure embedded in data
        final thoughtQAPairs = [
          ('Automatic Thought', exercise.automaticThought),
          ('Emotion', exercise.emotion),
          ('Evidence For', exercise.evidenceFor),
          ('Evidence Against', exercise.evidenceAgainst),
          ('Balanced Thought', exercise.balancedThought),
        ];

        for (final (question, answer) in thoughtQAPairs) {
          if (answer != null && answer.isNotEmpty) {
            answers.add({'question': question, 'answer': answer});
          }
        }
        break;
      case CbtExerciseType.behavioralActivation:
      case CbtExerciseType.dailyCheckin:
        // These types don't have reflection questions
        break;
    }

    return answers;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ChiromoColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMetricsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ),
      ],
    );
  }

  IconData _getIconForType(CbtExerciseType type) {
    switch (type) {
      case CbtExerciseType.dailyCheckin:
        return Icons.event_note_rounded;
      case CbtExerciseType.thoughtRecord:
        return Icons.psychology_outlined;
      case CbtExerciseType.behavioralActivation:
        return Icons.check_box_outlined;
      case CbtExerciseType.exposureLadder:
        return Icons.trending_up_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ChiromoColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _ReflectionCard extends StatelessWidget {
  final String question;
  final String answer;

  const _ReflectionCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: ChiromoColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChiromoColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: ChiromoColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
