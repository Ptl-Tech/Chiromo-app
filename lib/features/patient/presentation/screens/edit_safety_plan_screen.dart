import 'package:flutter/material.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';
import 'package:chiromo/widgets/buttons/chiromo_button.dart';

class EditSafetyPlanScreen extends StatefulWidget {
  const EditSafetyPlanScreen({super.key});

  @override
  State<EditSafetyPlanScreen> createState() => _EditSafetyPlanScreenState();
}

class _EditSafetyPlanScreenState extends State<EditSafetyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _warningSignsController = TextEditingController();
  final _copingStrategiesController = TextEditingController();
  final _reasonsToLiveController = TextEditingController();
  final _professionalContactsController = TextEditingController();

  bool _isSaving = false;

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
    
    setState(() => _isSaving = true);
    
    // Simulate API call for now since we don't have the provider fully hooked up
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safety plan saved successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Safety Plan',
      body: SingleChildScrollView(
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
                text: 'Save Safety Plan',
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
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ChiromoColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
