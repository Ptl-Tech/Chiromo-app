import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';
import 'package:chiromo/widgets/buttons/chiromo_button.dart';
import 'package:chiromo/widgets/glass_card.dart';
import '../providers/emergency_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/emergency_contact_entity.dart';

class EditEmergencyContactScreen extends ConsumerStatefulWidget {
  final EmergencyContactEntity? contact;

  const EditEmergencyContactScreen({super.key, this.contact});

  @override
  ConsumerState<EditEmergencyContactScreen> createState() => _EditEmergencyContactScreenState();
}

class _EditEmergencyContactScreenState extends ConsumerState<EditEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _relationshipController.text = widget.contact!.relationship ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      
      final newContact = EmergencyContactEntity(
        id: widget.contact?.id ?? '',
        patientId: user.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        createdAt: widget.contact?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.contact == null) {
        await repo.createEmergencyContact(newContact);
      } else {
        await repo.updateEmergencyContact(newContact);
      }
      
      // Refresh provider
      ref.invalidate(emergencyContactsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.contact == null ? 'Contact added' : 'Contact updated')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contact: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _deleteContact() async {
    if (widget.contact == null) return;
    
    setState(() => _isDeleting = true);
    
    try {
      final repo = ref.read(emergencyRepositoryProvider);
      await repo.deleteEmergencyContact(widget.contact!.id);
      
      ref.invalidate(emergencyContactsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.contact != null;

    return AppScaffold(
      title: isEditing ? 'Edit Contact' : 'Add Contact',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal Emergency Contact',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add someone you trust who can be contacted in case of a mental health emergency.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                label: 'Name',
                controller: _nameController,
                hint: 'e.g. Jane Doe',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                hint: 'e.g. +254 700 000 000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Relationship',
                controller: _relationshipController,
                hint: 'e.g. Mother, Spouse, Friend',
                icon: Icons.family_restroom_outlined,
              ),
              const SizedBox(height: 32),

              ChiromoButton(
                label: isEditing ? 'Update Contact' : 'Save Contact',
                onPressed: _isSaving ? null : _saveContact,
                isLoading: _isSaving,
              ),
              
              if (isEditing) ...[
                const SizedBox(height: 16),
                ChiromoButton(
                  label: 'Delete Contact',
                  onPressed: _isDeleting ? null : _deleteContact,
                  isLoading: _isDeleting,
                  variant: ChiromoButtonVariant.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ChiromoColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 12,
          elevation: 2,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
