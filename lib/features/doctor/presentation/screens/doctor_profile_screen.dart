import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/storage_providers.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../presentation/providers/doctor_providers.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
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
      // refresh related providers
      ref.invalidate(currentDoctorProfileProvider);

      setState(() {
        _pickedImage = null;
        _pickedImageBytes = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e, st) {
      debugPrint('Avatar upload error: $e\n$st');
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ChiromoColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
            if (onTap != null)
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

  Widget _buildProfileTile(IconData icon, String title, String subtitle) {
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
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final doctorProfileAsync = ref.watch(currentDoctorProfileProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Doctor Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit profile dialog not implemented yet')),
            );
          },
        ),
      ],
      body: doctorProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doctor) {
          return LayoutBuilder(
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
                              _buildSectionHeader('Professional Profile'),
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
                                      child: _pickedImageBytes == null && user?.avatarUrl == null
                                          ? Text(
                                              (user?.fullName ?? user?.email ?? 'D')
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
                                          user?.fullName ?? 'Doctor Name',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor?.specialty ?? user?.role.label ?? 'Doctor',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: ChiromoColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          user?.email ?? 'doctor@example.com',
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
                                icon: Icons.medical_services_outlined,
                                title: 'Specialty',
                                subtitle: doctor?.specialty ?? 'Not specified',
                              ),
                              const Divider(height: 1),
                              _buildInfoRow(
                                icon: Icons.school_outlined,
                                title: 'Qualifications',
                                subtitle: doctor?.qualifications ?? 'Not specified',
                              ),
                              const Divider(height: 1),
                              _buildInfoRow(
                                icon: Icons.payments_outlined,
                                title: 'Consultation Fee',
                                subtitle: doctor?.consultationFee != null ? 'KES ${doctor!.consultationFee}' : 'Not specified',
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                activeTrackColor: ChiromoColors.primary,
                                contentPadding: EdgeInsets.zero,
                                secondary: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ChiromoColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.event_available_outlined, size: 20, color: ChiromoColors.primary),
                                ),
                                title: const Text(
                                  'Availability',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  (doctor?.isAvailable ?? false) ? 'Available for booking' : 'Not available',
                                  style: const TextStyle(color: ChiromoColors.textSecondary, fontSize: 13),
                                ),
                                value: doctor?.isAvailable ?? false,
                                onChanged: doctor == null ? null : (value) async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await ref.read(doctorRepositoryProvider).updateDoctorAvailability(doctor.id, value);
                                    ref.invalidate(currentDoctorProfileProvider);
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(value ? 'You are now available for booking' : 'You are no longer available')),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Failed to update availability: $e')),
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
                                'Enabled',
                              ),
                              const Divider(height: 32),
                              _buildProfileTile(
                                Icons.security_outlined,
                                'Privacy & Security',
                                'Manage passwords and data',
                              ),
                              const Divider(height: 32),
                              _buildProfileTile(
                                Icons.help_outline,
                                'Help & Support',
                                'Contact us or view FAQs',
                              ),
                              const SizedBox(height: 20),
                              ChiromoButton(
                                label: 'Sign Out',
                                onPressed: () async {
                                  await ref.read(authNotifierProvider.notifier).signOut();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
