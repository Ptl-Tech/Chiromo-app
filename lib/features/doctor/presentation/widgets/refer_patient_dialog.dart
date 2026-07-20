import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/features/doctor/domain/entities/doctor_entity.dart';
import 'package:chiromo/features/doctor/presentation/providers/doctor_providers.dart';
import 'package:chiromo/features/doctor/presentation/providers/clinical_providers.dart';
import 'package:chiromo/features/doctor/data/models/referral_model.dart';

class ReferPatientDialog extends ConsumerStatefulWidget {
  final String patientId;
  final DoctorEntity referringDoctor;

  const ReferPatientDialog({
    super.key,
    required this.patientId,
    required this.referringDoctor,
  });

  @override
  ConsumerState<ReferPatientDialog> createState() => _ReferPatientDialogState();
}

class _ReferPatientDialogState extends ConsumerState<ReferPatientDialog> {
  DoctorEntity? _selectedDoctor;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReferral() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a doctor to refer to.')));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason for the referral.')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(clinicalRepositoryProvider);
      
      final referral = ReferralModel(
        id: '',
        patientId: widget.patientId,
        referringDoctorId: widget.referringDoctor.id,
        referredDoctorId: _selectedDoctor!.id,
        reason: _reasonController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createReferral(referral);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient referred successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDoctorsAsync = ref.watch(allDoctorsProvider);

    return AlertDialog(
      title: const Text('Refer Patient'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            allDoctorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading doctors: $e'),
              data: (doctors) {
                // Filter out the referring doctor
                final availableDoctors = doctors.where((d) => d.id != widget.referringDoctor.id).toList();
                
                if (availableDoctors.isEmpty) {
                  return const Text('No other doctors available.');
                }

                return DropdownButtonFormField<DoctorEntity>(
                  decoration: const InputDecoration(
                    labelText: 'Refer to Specialist',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedDoctor,
                  items: availableDoctors.map((doc) {
                    return DropdownMenuItem(
                      value: doc,
                      child: Text('${doc.userProfile?.fullName ?? 'Unknown'} (${doc.specialty})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDoctor = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for referral',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReferral,
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Referral'),
        ),
      ],
    );
  }
}
