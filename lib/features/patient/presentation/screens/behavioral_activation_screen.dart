import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/controls/slider_number_input.dart';

class BehavioralActivationScreen extends ConsumerStatefulWidget {
  const BehavioralActivationScreen({super.key});

  @override
  ConsumerState<BehavioralActivationScreen> createState() =>
      _BehavioralActivationScreenState();
}

class _BehavioralActivationScreenState
    extends ConsumerState<BehavioralActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityCtrl = TextEditingController();
  double _moodLift = 3;
  bool _isShared = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _activityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Behavioral Activation',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/quick_actions/log_activity.png',
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
                            'Behavioral Activation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Schedule activities and build healthy routines to improve mood.',
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
              const SizedBox(height: 28),

              _buildTextField(
                controller: _activityCtrl,
                label: 'Activity',
                hint: 'What did you do? (e.g., Morning walk in the park)',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SliderNumberInput(
                label: 'Mood Lift (Points)',
                value: _moodLift,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: ChiromoColors.success,
                onChanged: (v) => setState(() => _moodLift = v),
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
                          'Save Activity',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ChiromoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: ChiromoColors.textTertiary),
            filled: true,
            fillColor: ChiromoColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'This field is required' : null,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final exercise = CbtExerciseEntity(
      id: '',
      patientId: user.id,
      type: CbtExerciseType.behavioralActivation,
      title: _activityCtrl.text,
      data: {
        'activity': _activityCtrl.text,
        'mood_lift': _moodLift.round(),
        'streak': 1, // Ideally computed from previous entries
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
            content: Text('Activity saved! 🎉'),
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
