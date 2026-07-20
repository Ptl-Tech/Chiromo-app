import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';
import 'package:chiromo/features/doctor/presentation/providers/clinical_providers.dart';
import 'package:intl/intl.dart';

class PatientRecordsScreen extends ConsumerStatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  ConsumerState<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Records',
      showBack: true,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: ChiromoColors.primary,
            unselectedLabelColor: ChiromoColors.textSecondary,
            indicatorColor: ChiromoColors.primary,
            tabs: const [
              Tab(text: 'Prescriptions'),
              Tab(text: 'Medical History'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrescriptionsTab(),
                _buildMedicalHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);

    return prescriptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (prescriptions) {
        if (prescriptions.isEmpty) {
          return const Center(child: Text('No prescriptions found.', style: TextStyle(color: ChiromoColors.textSecondary)));
        }
        return ListView.builder(
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = prescriptions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(prescription.medicationName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Dosage: ${prescription.dosage}'),
                    Text('Frequency: ${prescription.frequency}'),
                    Text('Duration: ${prescription.durationDays} days'),
                    if (prescription.instructions != null) ...[
                      const SizedBox(height: 4),
                      Text('Notes: ${prescription.instructions}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
                trailing: Chip(
                  label: Text(prescription.isDispensed ? 'Dispensed' : 'Pending'),
                  backgroundColor: prescription.isDispensed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: prescription.isDispensed ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicalHistoryTab() {
    final recordsAsync = ref.watch(patientMedicalRecordsProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No medical history found.', style: TextStyle(color: ChiromoColors.textSecondary)));
        }
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(record.createdAt),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: ChiromoColors.primary),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (record.chiefComplaint != null) ...[
                      const Text('Complaint', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: ChiromoColors.textSecondary)),
                      Text(record.chiefComplaint!),
                      const SizedBox(height: 8),
                    ],
                    if (record.clinicalNotes != null) ...[
                      const Text('Clinical Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: ChiromoColors.textSecondary)),
                      Text(record.clinicalNotes!),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (record.bloodPressure != null) _buildVitalsBadge('BP', record.bloodPressure!),
                        if (record.heartRate != null) _buildVitalsBadge('HR', '${record.heartRate} bpm'),
                        if (record.temperature != null) _buildVitalsBadge('Temp', '${record.temperature}°C'),
                        if (record.weight != null) _buildVitalsBadge('Weight', '${record.weight} kg'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVitalsBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
