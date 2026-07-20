import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/consultation_providers.dart';
import '../providers/doctor_providers.dart';
import '../widgets/refer_patient_dialog.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String patientId;

  const ConsultationScreen({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Vitals
  final _bpCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // Notes
  final _chiefComplaintCtrl = TextEditingController();
  final _clinicalNotesCtrl = TextEditingController();

  // Diagnoses (Simplified for UI: single diagnosis for now)
  final _icd10Ctrl = TextEditingController();
  final _diagnosisDescCtrl = TextEditingController();

  // Prescription (Simplified for UI: single medication for now)
  final _medicationCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _bpCtrl.dispose();
    _hrCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _chiefComplaintCtrl.dispose();
    _clinicalNotesCtrl.dispose();
    _icd10Ctrl.dispose();
    _diagnosisDescCtrl.dispose();
    _medicationCtrl.dispose();
    _dosageCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final doctorProfile = await ref.read(currentDoctorProfileProvider.future);
      if (doctorProfile == null) throw Exception('Doctor profile not found');

      final repo = ref.read(consultationRepositoryProvider);
      
      // 1. Save Medical Record
      final record = MedicalRecordEntity(
        id: '',
        patientId: widget.patientId,
        doctorId: doctorProfile.id,
        appointmentId: widget.appointmentId,
        chiefComplaint: _chiefComplaintCtrl.text,
        clinicalNotes: _clinicalNotesCtrl.text,
        bloodPressure: _bpCtrl.text,
        heartRate: int.tryParse(_hrCtrl.text),
        temperature: double.tryParse(_tempCtrl.text),
        weight: double.tryParse(_weightCtrl.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final savedRecord = await repo.createMedicalRecord(record);

      // 2. Save Diagnosis
      if (_diagnosisDescCtrl.text.isNotEmpty) {
        final diagnosis = DiagnosisEntity(
          id: '',
          medicalRecordId: savedRecord.id,
          icd10Code: _icd10Ctrl.text,
          description: _diagnosisDescCtrl.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.addDiagnoses([diagnosis]);
      }

      // 3. Save Prescription
      if (_medicationCtrl.text.isNotEmpty) {
        final prescription = PrescriptionEntity(
          id: '',
          medicalRecordId: savedRecord.id,
          medicationName: _medicationCtrl.text,
          dosage: _dosageCtrl.text,
          frequency: 'As prescribed',
          durationDays: int.tryParse(_durationCtrl.text) ?? 1,
          isDispensed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.addPrescriptions([prescription]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation saved successfully.')),
        );
        context.pop(); // Go back to calendar/dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ChiromoColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Consultation'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final doctorProfile = await ref.read(currentDoctorProfileProvider.future);
              if (doctorProfile == null) return;
              if (!context.mounted) return;
              
              showDialog(
                context: context,
                builder: (ctx) => ReferPatientDialog(
                  patientId: widget.patientId,
                  referringDoctor: doctorProfile,
                ),
              );
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Refer'),
            style: TextButton.styleFrom(foregroundColor: ChiromoColors.primary),
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : _completeConsultation,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Complete'),
            style: TextButton.styleFrom(foregroundColor: ChiromoColors.primary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Vitals'),
              _buildVitalsCard(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Clinical Notes'),
              _buildNotesCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Diagnosis'),
              _buildDiagnosisCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Prescription'),
              _buildPrescriptionCard(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: ChiromoColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ChiromoColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bpCtrl,
                decoration: const InputDecoration(labelText: 'BP (mmHg)', hintText: '120/80'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _hrCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'HR (bpm)', hintText: '72'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _tempCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Temp (°C)', hintText: '37.0'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ChiromoColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _chiefComplaintCtrl,
              decoration: const InputDecoration(labelText: 'Chief Complaint', alignLabelWithHint: true),
              maxLines: 2,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicalNotesCtrl,
              decoration: const InputDecoration(labelText: 'Clinical Observations / Notes', alignLabelWithHint: true),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ChiromoColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _icd10Ctrl,
                    decoration: const InputDecoration(labelText: 'ICD-10 (Optional)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _diagnosisDescCtrl,
                    decoration: const InputDecoration(labelText: 'Diagnosis Description'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ChiromoColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _medicationCtrl,
              decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g., Fluoxetine 20mg'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageCtrl,
                    decoration: const InputDecoration(labelText: 'Dosage / Freq', hintText: '1 pill daily'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (Days)', hintText: '30'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
