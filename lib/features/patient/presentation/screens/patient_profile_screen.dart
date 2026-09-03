import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    // Business Central serialises an unset date as 0001-01-01. Treated as a
    // real birthday it renders as '2025 years', so anything implausibly old
    // is read as missing rather than shown.
    int? age;
    if (_hasRealDob(user?.dateOfBirth)) {
      final dob = user!.dateOfBirth!.toLocal();
      final now = DateTime.now();
      var years = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        years--;
      }
      age = years;
    }

    return AppScaffold(
      title: 'My Profile',

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
                          // Header follows the agreed design: one centred
                          // identity block, and a single 'View Full Profile'
                          // action that also opens editing - two separate
                          // affordances for looking at and changing the same
                          // information is a distinction users do not make.
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 52,
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
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: ChiromoColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 2,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: ChiromoColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.cardColor,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user?.fullName ?? 'Patient Name',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ChiromoColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'patient@example.com',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ChiromoColors.textSecondary,
                            ),
                          ),
                          _buildFactPills(age, user?.gender),
                          const SizedBox(height: 16),
                          Center(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showEditProfileDialog(context, user),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ChiromoColors.primary,
                                side: const BorderSide(
                                  color: ChiromoColors.border,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'View Full Profile',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
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
                                        : const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isSaving ? 'Saving...' : 'Save Photo',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                          // Shortcuts, not the canonical home - both land on
                          // My Records, which is the single place this lives.
                          // Deliberately no 'Clinician Shared Data' row yet:
                          // nothing currently reads the share flag, so it
                          // would promise the patient a control that does not
                          // exist.
                          _buildSectionHeader('Health & Information'),
                          _buildProfileTile(
                            Icons.contact_phone_outlined,
                            'Emergency Contact',
                            'Who we call if something happens',
                            onTap: () =>
                                context.push('/patient/emergency/contact'),
                          ),
                          const Divider(height: 32),
                          _buildProfileTile(
                            Icons.medication_outlined,
                            'Medications',
                            'What your doctor has you taking',
                            onTap: () => context.push('/patient/records?tab=0'),
                          ),
                          const Divider(height: 32),
                          _buildProfileTile(
                            Icons.description_outlined,
                            'Notes from your visits',
                            'What your doctor wrote for you',
                            onTap: () => context.push('/patient/records?tab=1'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          const Divider(height: 32),
                          _buildSectionHeader('Account & Security'),
                          if (user != null && !user.emailVerified) ...[
                            _buildProfileTile(
                              Icons.mark_email_unread_outlined,
                              'Verify Email',
                              'Your email address is not confirmed yet',
                              onTap: () => _showVerifyEmailSheet(user.email),
                            ),
                            const Divider(height: 32),
                          ],
                          _buildProfileTile(
                            Icons.lock_outline,
                            'Change Password',
                            'Update the password you sign in with',
                            onTap: _showChangePasswordSheet,
                          ),
                          const Divider(height: 32),
                          _buildProfileTile(
                            Icons.person_off_outlined,
                            'Deactivate Account',
                            'Close your account and sign out',
                            onTap: _confirmDeactivateAccount,
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
    final idNumberController = TextEditingController(text: user.idNumber ?? '');
    // BC's blank date arrives as 0001-01-01; carrying that into the picker
    // would open it a couple of millennia ago.
    DateTime? selectedDob = _hasRealDob(user?.dateOfBirth as DateTime?)
        ? user?.dateOfBirth as DateTime?
        : null;
    String? selectedGender = (user.gender as String?)?.trim().toLowerCase();
    if (selectedGender != 'male' && selectedGender != 'female') {
      selectedGender = null;
    }

    await showModalBottomSheet<void>(
      context: context,
      // Pushed on the root navigator so the sheet covers the shell's bottom
      // nav bar - a tab strip showing through an edit form invites someone
      // to navigate away mid-edit.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final dobText = selectedDob != null
                ? selectedDob!.toLocal().toIso8601String().split('T').first
                : 'Select your date of birth';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernTextField(
                                controller: lastNameController,
                                label: 'Last Name',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: bioController,
                          label: 'Bio',
                          icon: Icons.info_outline,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDob ?? DateTime(1990, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: ChiromoColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDob = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: ChiromoColors.surfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: ChiromoColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dobText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: selectedDob != null
                                          ? Colors.black87
                                          : ChiromoColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar,
                                  color: ChiromoColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ChiromoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final option in const ['male', 'female'])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(_titleCase(option)),
                                  selected: selectedGender == option,
                                  onSelected: (_) => setState(
                                    () => selectedGender =
                                        selectedGender == option
                                        ? null
                                        : option,
                                  ),
                                  selectedColor: ChiromoColors.primary,
                                  labelStyle: TextStyle(
                                    color: selectedGender == option
                                        ? Colors.white
                                        : ChiromoColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: idNumberController,
                          label: 'ID Number',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  try {
                                    final updatedUser = await ref
                                        .read(authRepositoryProvider)
                                        .updateProfile(
                                          firstName: firstNameController.text
                                              .trim(),
                                          lastName: lastNameController.text
                                              .trim(),
                                          phone: phoneController.text.trim(),
                                          dateOfBirth: selectedDob,
                                          gender: selectedGender ?? '',
                                          idNumber: idNumberController.text
                                              .trim(),
                                          bio: bioController.text.trim(),
                                        );
                                    ref
                                        .read(authNotifierProvider.notifier)
                                        .updateCurrentUser(updatedUser);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile updated successfully',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to update profile: $e',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: ChiromoColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: ChiromoColors.textSecondary, size: 20)
                : null,
            filled: true,
            fillColor: ChiromoColors.surfaceVariant.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: ChiromoColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotificationsSettings() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
              title: const Text(
                'Push Notifications',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Receive alerts for appointments and messages',
              ),
              value: true,
              activeThumbColor: ChiromoColors.primary,
              onChanged: (val) {
                // Future integration: update user preferences
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Email Updates',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Weekly check-in summaries and tips'),
              value: false,
              activeThumbColor: ChiromoColors.primary,
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
      useRootNavigator: true,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'At Chiromo Hospital Group (CHG), your privacy and mental health records are treated with the highest degree of confidentiality in accordance with the Data Protection Act of Kenya and international healthcare ethics. Our staff are mandated to protect patient privacy as part of their professional responsibilities.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By using this application, you agree to CHG\'s operational and administrative guidelines when accessing services, scheduling appointments, or making payments. This platform serves as an extension of our in-patient, out-patient, and virtual center services.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
      useRootNavigator: true,
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
              title: const Text(
                '+254 0750 927 232',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('24/7 Helpline'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(Icons.email, color: ChiromoColors.primary),
              ),
              title: const Text(
                'clientservices@chiromohg.co.ke',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Email Support'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(Icons.location_on, color: ChiromoColors.primary),
              ),
              title: const Text(
                '37 Muthangari Road',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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

  /// The age and gender chips beneath the name.
  ///
  /// Each half is dropped when the underlying value is missing, rather than
  /// printing a placeholder - a profile that says 'Gender: not set' is worse
  /// than one that simply does not mention it.
  /// Whether a date of birth is a real one rather than BC's blank sentinel.
  static bool _hasRealDob(DateTime? dob) => dob != null && dob.year > 1900;

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _buildFactPills(int? age, String? gender) {
    // Trimmed, because BC returns a blank option as whitespace rather than an
    // empty string - which rendered the pill as a bare icon with no label.
    final genderLabel = _titleCase((gender ?? '').trim());
    final hasAge = age != null;
    final hasGender = genderLabel.isNotEmpty;

    if (!hasAge && !hasGender) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: ChiromoColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasAge) _buildFactPill(Icons.cake_outlined, '$age years'),
              if (hasAge && hasGender)
                Container(width: 1, height: 16, color: ChiromoColors.border),
              if (hasGender) _buildFactPill(Icons.person_outline, genderLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactPill(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ChiromoColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ChiromoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
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

  /// Strips the "Exception: " prefix Dart adds when an [Exception] carrying a
  /// server message is stringified, so the API's own wording reaches the user.
  String _errorText(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Future<void> _showChangePasswordSheet() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      // Pushed on the root navigator so the sheet covers the shell's bottom
      // nav bar - a tab strip showing through an edit form invites someone
      // to navigate away mid-edit.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              setSheetState(() => submitting = true);
              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                setSheetState(() => submitting = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(_errorText(e)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: currentController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your current password'
                            : null,
                      ),
                      TextFormField(
                        controller: newController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          helperText:
                              'At least 8 characters, with upper and lower '
                              'case, a number and a symbol',
                          helperMaxLines: 2,
                        ),
                        validator: _validateNewPassword,
                      ),
                      TextFormField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                        validator: (v) => v != newController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: submitting ? null : submit,
                              child: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Update'),
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
      },
    );
  }

  /// Mirrors the API's password rule so the user is told what is wrong before
  /// a round trip, rather than getting the server validator's raw output.
  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include an upper case letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Include a lower case letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Include a number';
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      return 'Include a symbol';
    }
    return null;
  }

  Future<void> _showVerifyEmailSheet(String email) async {
    final otpController = TextEditingController();
    var submitting = false;
    var sending = false;

    await showModalBottomSheet<void>(
      context: context,
      // Pushed on the root navigator so the sheet covers the shell's bottom
      // nav bar - a tab strip showing through an edit form invites someone
      // to navigate away mid-edit.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final notifier = ref.read(authNotifierProvider.notifier);
            final messenger = ScaffoldMessenger.of(context);

            Future<void> sendCode() async {
              setSheetState(() => sending = true);
              try {
                await notifier.sendVerificationOtp(email);
                setSheetState(() => sending = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Verification code sent to $email'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                setSheetState(() => sending = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(_errorText(e)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            Future<void> submit() async {
              final code = otpController.text.trim();
              if (code.isEmpty) return;
              setSheetState(() => submitting = true);
              try {
                await notifier.verifyEmail(email: email, otpCode: code);
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email verified'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                setSheetState(() => submitting = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(_errorText(e)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verify Email',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    Text(
                      'Send a code to $email, then enter it below.',
                      style: const TextStyle(
                        color: ChiromoColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Verification code',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: sending ? null : sendCode,
                        child: Text(sending ? 'Sending...' : 'Send me a code'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeactivateAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate account?'),
        content: const Text(
          'You will be signed out and will no longer be able to sign in. '
          'Your clinical records are kept by the hospital. To come back, '
          'contact Client Services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authNotifierProvider.notifier).deactivateAccount();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your account has been deactivated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_errorText(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
