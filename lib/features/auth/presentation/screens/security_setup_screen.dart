import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../theme/chiromo_colors.dart';
import '../providers/security_provider.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  bool useBiometrics = false;

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN')),
      );
      return;
    }

    await ref
        .read(securityNotifierProvider.notifier)
        .setupSecurity(pinController.text, useBiometrics);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security settings updated successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityNotifierProvider).valueOrNull;
    final isBiometricAvailable = securityState?.isBiometricAvailable ?? false;

    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        color: ChiromoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: ChiromoColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return AppScaffold(
      title: 'Setup Security',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: ChiromoColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Secure Your Data',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a 4-digit PIN to protect your health records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Pinput(
                controller: pinController,
                focusNode: focusNode,
                length: 4,
                obscureText: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: ChiromoColors.primary),
                  ),
                ),
                onCompleted: (pin) {
                  // Ready
                },
              ),
            ),
            const SizedBox(height: 48),
            if (isBiometricAvailable) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Biometrics (Fingerprint/FaceID)'),
                subtitle: const Text('Unlock faster and securely'),
                value: useBiometrics,
                activeThumbColor: ChiromoColors.primary,
                onChanged: (value) {
                  setState(() {
                    useBiometrics = value;
                  });
                },
              ),
              const SizedBox(height: 32),
            ],
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChiromoColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Security Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
