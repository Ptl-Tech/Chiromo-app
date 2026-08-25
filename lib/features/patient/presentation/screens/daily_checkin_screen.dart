import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class DailyCheckinScreen extends ConsumerStatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  ConsumerState<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  double _mood = 5;
  double _anxiety = 5;
  double _sleepHours = 7.5;
  final TextEditingController _sleepCtrl = TextEditingController();
  final TextEditingController _moodCtrl = TextEditingController();
  final TextEditingController _anxietyCtrl = TextEditingController();
  bool _isShared = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sleepCtrl.text = _sleepHours.toStringAsFixed(1);
    _moodCtrl.text = _mood.round().toString();
    _anxietyCtrl.text = _anxiety.round().toString();
  }

  @override
  void dispose() {
    _sleepCtrl.dispose();
    _moodCtrl.dispose();
    _anxietyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Daily Check-in',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE3F2FD).withValues(alpha: 0.8),
                    const Color(0xFFBBDEFB).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF90CAF9).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/quick_actions/cbt_tools.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Check-in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your mood, anxiety, and sleep to notice patterns.',
                          style: TextStyle(
                            fontSize: 13,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mood
            Text(
              'Overall Mood',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_mood.round()}/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ChiromoColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _mood,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: ChiromoColors.primary,
                    onChanged: (v) => setState(() => _mood = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _moodCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Mood (0-10)',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null) {
                  setState(() => _mood = parsed.clamp(0, 10));
                }
              },
            ),
            const SizedBox(height: 24),

            // Anxiety
            Text(
              'Anxiety Level',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_anxiety.round()}/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _anxietyColor(_anxiety),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _anxiety,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _anxietyColor(_anxiety),
                    onChanged: (v) => setState(() => _anxiety = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _anxietyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Anxiety (0-10)',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null) {
                  setState(() => _anxiety = parsed.clamp(0, 10));
                }
              },
            ),
            const SizedBox(height: 24),

            // Sleep
            Text(
              'Hours of Sleep',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_sleepHours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5E35B1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _sleepHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    activeColor: const Color(0xFF5E35B1),
                    onChanged: (v) => setState(() => _sleepHours = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Share toggle
            SwitchListTile(
              title: const Text('Share with your therapist'),
              subtitle: const Text(
                'Your therapist can review and provide feedback',
              ),
              value: _isShared,
              onChanged: (v) => setState(() => _isShared = v),
              activeThumbColor: ChiromoColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: ChiromoColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Check-in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _anxietyColor(double value) {
    if (value <= 3) {
      return ChiromoColors.success;
    }
    if (value <= 6) {
      return ChiromoColors.warning;
    }
    return ChiromoColors.error;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final exercise = CbtExerciseEntity(
      id: '',
      patientId: user.id,
      type: CbtExerciseType.dailyCheckin,
      title: 'Daily Check-in',
      data: {
        'mood': _mood.round(),
        'anxiety': _anxiety.round(),
        'sleep_hours': _sleepHours,
      },
      isShared: _isShared,
      hasDoctorFeedback: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(cbtRepositoryProvider);
      await repo.createExercise(exercise);
      ref.invalidate(cbtExercisesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily Check-in saved! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
