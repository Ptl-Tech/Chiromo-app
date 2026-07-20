import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<dynamic>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _fetchProfiles();
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    final client = SupabaseService.client;
    await client.from('profiles').update({'role': newRole}).eq('id', userId);

    if (newRole == AppConstants.roleDoctor) {
      final existing = await client
          .from('doctors')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) {
        await client.from('doctors').insert({
          'user_id': userId,
          'specialty': 'General',
          'qualifications': '',
          'consultation_fee': 0,
          'is_available': true,
        });
      }
    } else {
      await client.from('doctors').delete().eq('user_id', userId);
    }

    setState(() {
      _profilesFuture = _fetchProfiles();
    });
  }

  Future<void> _syncDoctorRecords() async {
    final client = SupabaseService.client;
    final doctors = await client
        .from('profiles')
        .select('id')
        .eq('role', AppConstants.roleDoctor);

    final created = <String>[];

    for (final profile in (doctors as List)) {
      final id = profile['id'] as String?;
      if (id == null) continue;
      final existing = await client
          .from('doctors')
          .select()
          .eq('user_id', id)
          .maybeSingle();
      if (existing == null) {
        await client.from('doctors').insert({
          'user_id': id,
          'specialty': 'General',
          'qualifications': '',
          'consultation_fee': 0,
          'is_available': true,
        });
        created.add(id);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created ${created.length} missing doctor records.'),
        ),
      );
      setState(() {
        _profilesFuture = _fetchProfiles();
      });
    }
  }

  Future<void> _showCreateStaffDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var selectedRole = AppConstants.roleDoctor;
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Staff Account'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items:
                            [
                              AppConstants.roleDoctor,
                              AppConstants.roleNurse,
                              AppConstants.roleReceptionist,
                              AppConstants.roleHospitalAdmin,
                              AppConstants.roleCashier,
                              AppConstants.roleLaboratory,
                            ].map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role.replaceAll('_', ' ').capitalize(),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _createStaffAccount(
                              fullName: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              password: passwordCtrl.text,
                              role: selectedRole,
                            );
                            nav.pop();
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to create account: $error',
                                ),
                              ),
                            );
                          } finally {
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
  }

  Future<void> _createStaffAccount({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final auth = SupabaseService.auth;
    final client = SupabaseService.client;
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final res = await auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'phone_number': phone,
      },
    );

    final newUserId = res.user?.id;
    if (newUserId == null) {
      throw StateError('Unable to create staff user account.');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (role == AppConstants.roleDoctor) {
      await client.from('doctors').insert({
        'user_id': newUserId,
        'specialty': 'General',
        'qualifications': '',
        'consultation_fee': 0,
        'is_available': true,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staff account created for $fullName')),
      );
      setState(() {
        _profilesFuture = _fetchProfiles();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync doctor records',
            onPressed: _syncDoctorRecords,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Create staff account',
            onPressed: _showCreateStaffDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or role...',
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
                const SizedBox(width: 16),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: ChiromoColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: 'All Roles',
                      items:
                          [
                                'All Roles',
                                'Doctor',
                                'Nurse',
                                'Receptionist',
                                'Admin',
                              ]
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync doctor records'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChiromoColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _syncDoctorRecords,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<dynamic>>(
              future: _profilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text('Error loading users: ${snapshot.error}'),
                  );
                }

                final users = snapshot.data ?? [];

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ChiromoColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        ChiromoColors.surfaceVariant,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Role',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Branch',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: users.map((u) {
                        final id = u['id'] as String? ?? '';
                        final name =
                            '${(u['first_name'] as String?) ?? ''} ${(u['last_name'] as String?) ?? ''}';
                        final email = u['email'] as String? ?? '';
                        final role =
                            u['role'] as String? ?? AppConstants.rolePatient;
                        final branch = u['branch_id'] as String? ?? '—';
                        final status = (u['is_active'] == false)
                            ? 'Inactive'
                            : 'Active';

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                name.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(email)),
                            DataCell(
                              Chip(label: Text(role), padding: EdgeInsets.zero),
                            ),
                            DataCell(Text(branch)),
                            DataCell(
                              Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Active'
                                      ? ChiromoColors.statusConfirmed
                                      : ChiromoColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await _changeUserRole(id, value);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Updated role to $value for ${name.trim()}',
                                          ),
                                        ),
                                      );
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: AppConstants.rolePatient,
                                        child: Text('Make Patient'),
                                      ),
                                      const PopupMenuItem(
                                        value: AppConstants.roleDoctor,
                                        child: Text('Promote to Doctor'),
                                      ),
                                      const PopupMenuItem(
                                        value: AppConstants.roleHospitalAdmin,
                                        child: Text('Make Admin'),
                                      ),
                                    ],
                                    child: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<dynamic>> _fetchProfiles() async {
  final client = SupabaseService.client;
  final response = await client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return (response as List).cast<dynamic>();
}

extension StringCapitalization on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
