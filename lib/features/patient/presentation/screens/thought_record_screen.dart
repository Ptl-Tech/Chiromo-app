import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../widgets/controls/slider_number_input.dart';

class ThoughtRecordScreen extends ConsumerStatefulWidget {
  const ThoughtRecordScreen({super.key});

  @override
  ConsumerState<ThoughtRecordScreen> createState() =>
      _ThoughtRecordScreenState();
}

class _ThoughtRecordScreenState extends ConsumerState<ThoughtRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _situationCtrl = TextEditingController();
  final _autoThoughtCtrl = TextEditingController();
  final _emotionCtrl = TextEditingController();
  final _evidenceForCtrl = TextEditingController();
  final _evidenceAgainstCtrl = TextEditingController();
  final _balancedThoughtCtrl = TextEditingController();
  double _anxietyBefore = 5;
  double _anxietyAfter = 5;
  bool _isShared = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _situationCtrl.dispose();
    _autoThoughtCtrl.dispose();
    _emotionCtrl.dispose();
    _evidenceForCtrl.dispose();
    _evidenceAgainstCtrl.dispose();
    _balancedThoughtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Thought Record',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE0F2F1).withValues(alpha: 0.8),
                      const Color(0xFFB2DFDB).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF80CBC4).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4DB6AC).withValues(alpha: 0.08),
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
                        'assets/images/cbt_tools/thought_record.png',
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
                            'Thought Record',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Challenge negative thoughts and build cognitive flexibility',
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
                controller: _situationCtrl,
                label: 'Situation',
                hint: 'What happened? Where were you?',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _autoThoughtCtrl,
                label: 'Automatic Thought',
                hint: 'What went through your mind?',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emotionCtrl,
                label: 'Emotion',
                hint: 'What did you feel? (e.g., anxious, sad, angry)',
              ),
              const SizedBox(height: 24),

              SliderNumberInput(
                label: 'Anxiety Level Before',
                value: _anxietyBefore,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: _anxietyColor(_anxietyBefore),
                onChanged: (v) => setState(() => _anxietyBefore = v),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _evidenceForCtrl,
                label: 'Evidence For This Thought',
                hint: 'What facts support this thought?',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _evidenceAgainstCtrl,
                label: 'Evidence Against This Thought',
                hint: 'What facts contradict this thought?',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _balancedThoughtCtrl,
                label: 'Balanced Thought',
                hint: 'What is a more balanced way of thinking?',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SliderNumberInput(
                label: 'Anxiety Level After',
                value: _anxietyAfter,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: _anxietyColor(_anxietyAfter),
                onChanged: (v) => setState(() => _anxietyAfter = v),
              ),
              const SizedBox(height: 16),

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
                          'Save Thought Record',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
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

  Color _anxietyColor(double value) {
    if (value <= 3) return ChiromoColors.success;
    if (value <= 6) return ChiromoColors.warning;
    return ChiromoColors.error;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final reliefPercent = _anxietyBefore > 0
        ? ((_anxietyBefore - _anxietyAfter) / _anxietyBefore * 100).round()
        : 0;

    final exercise = CbtExerciseEntity(
      id: '',
      patientId: user.id,
      type: CbtExerciseType.thoughtRecord,
      title: _situationCtrl.text,
      data: {
        'situation': _situationCtrl.text,
        'automatic_thought': _autoThoughtCtrl.text,
        'emotion': _emotionCtrl.text,
        'evidence_for': _evidenceForCtrl.text,
        'evidence_against': _evidenceAgainstCtrl.text,
        'balanced_thought': _balancedThoughtCtrl.text,
        'anxiety_before': _anxietyBefore.round(),
        'anxiety_after': _anxietyAfter.round(),
        'relief_percent': reliefPercent,
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
            content: Text('Thought record saved! 🎉'),
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
