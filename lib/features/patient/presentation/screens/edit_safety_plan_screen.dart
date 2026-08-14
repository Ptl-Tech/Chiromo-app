import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';
import 'package:chiromo/widgets/buttons/chiromo_button.dart';
import 'package:chiromo/widgets/glass_card.dart';
import '../providers/emergency_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/safety_plan_entity.dart';

class EditSafetyPlanScreen extends ConsumerStatefulWidget {
  const EditSafetyPlanScreen({super.key});

  @override
  ConsumerState<EditSafetyPlanScreen> createState() => _EditSafetyPlanScreenState();
}

class _EditSafetyPlanScreenState extends ConsumerState<EditSafetyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _warningSignsController = TextEditingController();
  final _copingStrategiesController = TextEditingController();
  final _reasonsToLiveController = TextEditingController();
  final _professionalContactsController = TextEditingController();

  bool _isSaving = false;
  String? _existingPlanId;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingPlan = ref.read(safetyPlanProvider).valueOrNull;
      if (existingPlan != null) {
        setState(() {
          _existingPlanId = existingPlan.id;
          _createdAt = existingPlan.createdAt;
          _warningSignsController.text = existingPlan.warningSigns ?? '';
          _copingStrategiesController.text = existingPlan.copingStrategies ?? '';
          _reasonsToLiveController.text = existingPlan.reasonsToLive ?? '';
          _professionalContactsController.text = existingPlan.professionalContacts ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _warningSignsController.dispose();
    _copingStrategiesController.dispose();
    _reasonsToLiveController.dispose();
    _professionalContactsController.dispose();
    super.dispose();
  }

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      final newPlan = SafetyPlanEntity(
        id: _existingPlanId ?? '',
        patientId: user.id,
        warningSigns: _warningSignsController.text,
        copingStrategies: _copingStrategiesController.text,
        reasonsToLive: _reasonsToLiveController.text,
        professionalContacts: _professionalContactsController.text,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.upsertSafetyPlan(newPlan);
      
      // Refresh provider
      ref.invalidate(safetyPlanProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safety plan saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncPlan = ref.watch(safetyPlanProvider);

    return AppScaffold(
      title: 'Safety Plan',
      body: asyncPlan.isLoading && _existingPlanId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Your Safety Plan',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A safety plan is a guide that you can create with your doctor to help you navigate through a crisis. Keep this updated and easily accessible.',
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    _buildSection(
                      title: 'Step 1: Warning Signs',
                      description: 'What thoughts, images, moods, situations, or behaviors indicate that a crisis may be developing?',
                      controller: _warningSignsController,
                      hint: 'e.g., isolating myself, sleeping too much...',
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Step 2: Internal Coping Strategies',
                      description: 'What can I do, on my own, if I become suicidal again, to help myself not to act on my thoughts or urges?',
                      controller: _copingStrategiesController,
                      hint: 'e.g., deep breathing, going for a walk, listening to music...',
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Step 3: Reasons to Live',
                      description: 'What are the things that are most important to me and worth living for?',
                      controller: _reasonsToLiveController,
                      hint: 'e.g., my family, my pets, future goals...',
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Step 4: Professional Contacts',
                      description: 'Professionals or agencies I can contact during a crisis.',
                      controller: _professionalContactsController,
                      hint: 'e.g., Dr. Smith, Therapist Name...',
                    ),
                    const SizedBox(height: 32),

                    ChiromoButton(
                      label: 'Save Safety Plan',
                      onPressed: _isSaving ? null : _savePlan,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required TextEditingController controller,
    required String hint,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ChiromoColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 12,
          elevation: 2,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
