import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class ExposureLadderScreen extends ConsumerStatefulWidget {
  const ExposureLadderScreen({super.key});

  @override
  ConsumerState<ExposureLadderScreen> createState() =>
      _ExposureLadderScreenState();
}

class _ExposureLadderScreenState extends ConsumerState<ExposureLadderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fearCtrl = TextEditingController();
  double _currentStep = 1;
  double _totalSteps = 5;
  bool _isShared = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Exposure Ladder',
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
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/cbt_tools/exposure_ladder.png',
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
                            'Exposure Ladder',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Face fears gradually with a guided hierarchy.',
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
                controller: _fearCtrl,
                label: 'Fear or Avoided Situation',
                hint: 'e.g., Social anxiety - attending group events',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Total Steps
              Text(
                'Total Steps in Hierarchy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_totalSteps.round()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _totalSteps,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: ChiromoColors.primary,
                      onChanged: (v) {
                        setState(() {
                          _totalSteps = v;
                          if (_currentStep > _totalSteps) {
                            _currentStep = _totalSteps;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Step
              Text(
                'Current Step Completed',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_currentStep.round()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _currentStep,
                      min: 0,
                      max: _totalSteps,
                      divisions: _totalSteps.round() > 0
                          ? _totalSteps.round()
                          : 1,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (v) => setState(() => _currentStep = v),
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
                          'Save Ladder',
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
      type: CbtExerciseType.exposureLadder,
      title: _fearCtrl.text,
      data: {
        'fear': _fearCtrl.text,
        'current_step': _currentStep.round(),
        'total_steps': _totalSteps.round(),
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
            content: Text('Exposure Ladder saved! 🎉'),
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
