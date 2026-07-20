import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../core/services/supabase_service.dart';

// This screen now queries real patient profiles (role == 'patient')

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Patient Directory',
      showBack: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patient name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ChiromoColors.surfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchPatients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading patients: ${snapshot.error}'),
                  );
                }

                final patients = snapshot.data ?? [];

                if (patients.isEmpty) {
                  return Center(child: Text('No patients found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: patients.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = patients[index] as Map<String, dynamic>;
                    final name =
                        '${(p['first_name'] as String?) ?? ''} ${(p['last_name'] as String?) ?? ''}';
                    final status = (p['is_active'] == false)
                        ? 'Inactive'
                        : 'Active';
                    final avatar = p['avatar_url'] as String?;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: ChiromoColors.primarySurface,
                        foregroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar == null
                            ? Text(
                                (name.trim().isEmpty ? 'P' : name.trim()[0]),
                                style: const TextStyle(
                                  color: ChiromoColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        name.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Last visit: --'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Active'
                              ? ChiromoColors.statusConfirmed.withValues(
                                  alpha: 0.1,
                                )
                              : ChiromoColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Active'
                                ? ChiromoColors.statusConfirmed
                                : ChiromoColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<dynamic>> _fetchPatients() async {
  final client = SupabaseService.client;
  final res = await client
      .from('profiles')
      .select()
      .eq('role', 'patient')
      .order('last_name', ascending: true);
  return (res as List).cast<dynamic>();
}
