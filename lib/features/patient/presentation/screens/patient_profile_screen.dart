import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/storage_providers.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _saveAvatar() async {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    if (user == null || _pickedImage == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final uploadedUrl = await storage.uploadFile(
        bucketName: 'avatars',
        file: _pickedImage!,
        pathPrefix: 'users/${user.id}',
        fileName: _pickedImage!.name,
      );

      final updatedUser = await ref
          .read(authRepositoryProvider)
          .updateProfile(avatarUrl: uploadedUrl);
      ref.read(authNotifierProvider.notifier).updateCurrentUser(updatedUser);
      // Refresh patient appointments (or other patient specific providers if needed)
      ref.invalidate(patientAppointmentsProvider);

      setState(() {
        _pickedImage = null;
        _pickedImageBytes = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e, st) {
      // log and show a helpful message
      // ignore: avoid_print
      print('Avatar upload error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update profile image: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pickedImage = null;
    _pickedImageBytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'My Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditProfileDialog(context, user),
        ),
      ],
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final horizontalPadding = isNarrow ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 18,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('Personal Profile'),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(88),
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: isNarrow ? 44 : 50,
                                  backgroundColor: ChiromoColors.primarySurface,
                                  foregroundImage: _pickedImageBytes != null
                                      ? MemoryImage(_pickedImageBytes!)
                                      : user?.avatarUrl != null
                                      ? NetworkImage(user!.avatarUrl!)
                                            as ImageProvider
                                      : null,
                                  child:
                                      _pickedImageBytes == null &&
                                          user?.avatarUrl == null
                                      ? Text(
                                          (user?.fullName ?? user?.email ?? 'P')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: isNarrow ? 32 : 36,
                                            fontWeight: FontWeight.bold,
                                            color: ChiromoColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Patient Name',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.role.label ?? 'Patient',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: ChiromoColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user?.email ?? 'patient@example.com',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: ChiromoColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_pickedImageBytes != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _saveAvatar,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                                    label: Text(_isSaving ? 'Saving...' : 'Save Photo'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _pickedImage = null;
                                            _pickedImageBytes = null;
                                          });
                                        },
                                  child: const Text('Discard'),
                                ),
                              ],
                            ),
                          ],
                          if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              user.bio!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ChiromoColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            title: 'Phone',
                            subtitle: user?.phone ?? '+254 700 000000',
                            onTap: () => _editPhone(user?.phone ?? ''),
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            icon: Icons.calendar_today_outlined,
                            title: 'Date of Birth',
                            subtitle: user?.dateOfBirth != null
                                ? user!.dateOfBirth!
                                      .toLocal()
                                      .toIso8601String()
                                      .split('T')
                                      .first
                                : 'Not provided',
                            onTap: () async {
                              await _showEditProfileDialog(context, user);
                            },
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            subtitle: 'Nairobi, Kenya',
                            onTap: () async {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Address editing not implemented yet',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('Settings & Preferences'),
                          _buildProfileTile(
                            Icons.notifications_outlined,
                            'Notifications',
                            'Manage alerts & reminders',
                            onTap: _showNotificationsSettings,
                          ),
                          const Divider(height: 32),
                          _buildProfileTile(
                            Icons.security_outlined,
                            'Privacy & Terms',
                            'Read our policies & terms of service',
                            onTap: _showPrivacyPolicy,
                          ),
                          const Divider(height: 32),
                          _buildProfileTile(
                            Icons.help_outline,
                            'Help & Support',
                            'Contact us or view FAQs',
                            onTap: _showHelpSupport,
                          ),
                          const SizedBox(height: 20),
                          ChiromoButton(
                            label: 'Sign Out',
                            variant: ChiromoButtonVariant.outline,
                            icon: Icons.logout,
                            onPressed: () {
                              ref.read(authNotifierProvider.notifier).signOut();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    dynamic user,
  ) async {
    if (user == null) return;

    final nameParts = (user.fullName ?? '').split(' ');
    final firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    final lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    final phoneController = TextEditingController(text: user.phone ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    DateTime? selectedDob = user?.dateOfBirth as DateTime?;

    final isNarrow = MediaQuery.of(context).size.width < 600;
    if (isNarrow) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final dobText = selectedDob != null
              ? selectedDob!.toLocal().toIso8601String().split('T').first
              : 'Not set';
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Date of birth:'),
                        const SizedBox(width: 12),
                        Expanded(child: Text(dobText)),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDob ?? DateTime(1990, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              selectedDob = picked;
                              (ctx as Element).markNeedsBuild();
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              try {
                                final updatedUser = await ref
                                    .read(authRepositoryProvider)
                                    .updateProfile(
                                      firstName:
                                          firstNameController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : firstNameController.text.trim(),
                                      lastName:
                                          lastNameController.text.trim().isEmpty
                                          ? null
                                          : lastNameController.text.trim(),
                                      phone: phoneController.text.trim().isEmpty
                                          ? null
                                          : phoneController.text.trim(),
                                      dateOfBirth: selectedDob,
                                      bio: bioController.text.trim().isEmpty
                                          ? null
                                          : bioController.text.trim(),
                                    );
                                ref
                                    .read(authNotifierProvider.notifier)
                                    .updateCurrentUser(updatedUser);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update profile'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final dobText = selectedDob != null
              ? selectedDob!.toLocal().toIso8601String().split('T').first
              : 'Not set';
          return AlertDialog(
            title: const Text('Edit profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Date of birth:'),
                      const SizedBox(width: 12),
                      Expanded(child: Text(dobText)),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDob ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            selectedDob = picked;
                            // Force rebuild of the dialog
                            (ctx as Element).markNeedsBuild();
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final updatedUser = await ref
                        .read(authRepositoryProvider)
                        .updateProfile(
                          firstName: firstNameController.text.trim().isEmpty
                              ? null
                              : firstNameController.text.trim(),
                          lastName: lastNameController.text.trim().isEmpty
                              ? null
                              : lastNameController.text.trim(),
                          phone: phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                          dateOfBirth: selectedDob,
                          bio: bioController.text.trim().isEmpty
                              ? null
                              : bioController.text.trim(),
                        );
                    ref
                        .read(authNotifierProvider.notifier)
                        .updateCurrentUser(updatedUser);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update profile')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showNotificationsSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notification Preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Receive alerts for appointments and messages'),
              value: true,
              activeColor: ChiromoColors.primary,
              onChanged: (val) {
                // Future integration: update user preferences
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Email Updates', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Weekly check-in summaries and tips'),
              value: false,
              activeColor: ChiromoColors.primary,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Privacy & Terms',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chiromo Hospital Group Data Policy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'At Chiromo Hospital Group (CHG), your privacy and mental health records are treated with the highest degree of confidentiality in accordance with the Data Protection Act of Kenya and international healthcare ethics. Our staff are mandated to protect patient privacy as part of their professional responsibilities.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Terms of Service',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By using this application, you agree to CHG\'s operational and administrative guidelines when accessing services, scheduling appointments, or making payments. This platform serves as an extension of our in-patient, out-patient, and virtual center services.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: ChiromoColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get in touch with Chiromo Hospital Group Client Services.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(Icons.phone, color: ChiromoColors.primary),
              ),
              title: const Text('+254 0750 927 232', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('24/7 Helpline'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(Icons.email, color: ChiromoColors.primary),
              ),
              title: const Text('clientservices@chiromohg.co.ke', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Email Support'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(Icons.location_on, color: ChiromoColors.primary),
              ),
              title: const Text('37 Muthangari Road', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Nairobi, Kenya'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ChiromoColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      minLeadingWidth: 0,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ChiromoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: ChiromoColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: ChiromoColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ChiromoColors.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ChiromoColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: ChiromoColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ChiromoColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: ChiromoColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditFieldSheet({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: title),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final value = controller.text.trim();
                          Navigator.of(ctx).pop();
                          try {
                            await onSave(value);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Saved')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Failed to save')),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPhone(String current) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    await _showEditFieldSheet(
      title: 'Phone',
      initialValue: current,
      onSave: (val) async {
        if (user == null) throw StateError('Not signed in');
        final updated = await ref
            .read(authRepositoryProvider)
            .updateProfile(phone: val.isEmpty ? null : val);
        ref.read(authNotifierProvider.notifier).updateCurrentUser(updated);
      },
    );
  }
}
