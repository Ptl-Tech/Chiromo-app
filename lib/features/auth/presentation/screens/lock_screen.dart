import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../theme/chiromo_colors.dart';
import '../providers/security_provider.dart';
import 'package:go_router/go_router.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometrics();
    });
  }

  Future<void> _tryBiometrics() async {
    final success = await ref.read(securityNotifierProvider.notifier).authenticateWithBiometrics();
    if (success && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _verifyPin(String pin) async {
    final success = await ref.read(securityNotifierProvider.notifier).verifyPin(pin);
    if (success && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } else {
      setState(() {
        _isError = true;
      });
      pinController.clear();
      focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityNotifierProvider).valueOrNull;
    final isBiometricEnabled = securityState?.isBiometricEnabled ?? false;

    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        color: ChiromoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: _isError ? ChiromoColors.error.withValues(alpha: 0.1) : ChiromoColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isError ? ChiromoColors.error : Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock,
                size: 80,
                color: ChiromoColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isError ? 'Incorrect PIN, please try again.' : 'App is locked for your security.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _isError ? ChiromoColors.error : ChiromoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Pinput(
                  controller: pinController,
                  focusNode: focusNode,
                  length: 4,
                  obscureText: true,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: _isError ? ChiromoColors.error : ChiromoColors.primary),
                    ),
                  ),
                  onCompleted: _verifyPin,
                  onChanged: (v) {
                    if (_isError) setState(() => _isError = false);
                  },
                ),
              ),
              const SizedBox(height: 64),
              if (isBiometricEnabled)
                IconButton(
                  iconSize: 64,
                  icon: const Icon(Icons.fingerprint, size: 48, color: ChiromoColors.primary),
                  onPressed: _tryBiometrics,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
