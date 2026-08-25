import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/inputs/chiromo_text_field.dart';
import '../providers/auth_providers.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// Business Central resets passwords via an emailed OTP code rather than a
/// reset link, so this flow has three steps: request the OTP, enter the
/// OTP + a new password, then confirmation.
enum _ForgotPasswordStep { request, confirm, done }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;
  _ForgotPasswordStep _step = _ForgotPasswordStep.request;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(email);
      setState(() => _step = _ForgotPasswordStep.confirm);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    final otp = _otpCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (otp.isEmpty) {
      setState(() => _error = 'Enter the code sent to your email');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Minimum 6 characters');
      return;
    }
    if (password != _confirmPasswordCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).confirmPasswordReset(
            email: _emailCtrl.text.trim(),
            otpCode: otp,
            newPassword: password,
          );
      setState(() => _step = _ForgotPasswordStep.done);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reset Password',
      showBack: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: switch (_step) {
              _ForgotPasswordStep.request => _buildRequestForm(),
              _ForgotPasswordStep.confirm => _buildConfirmForm(),
              _ForgotPasswordStep.done => _buildSuccess(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, size: 64, color: ChiromoColors.primary),
        const SizedBox(height: 24),
        Text(
          'Forgot your password?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we will send you a code to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ChiromoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_error!, style: const TextStyle(color: ChiromoColors.error)),
          ),
        ChiromoTextField(
          controller: _emailCtrl,
          label: 'Email address',
          hint: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 32),
        ChiromoButton(
          label: 'Send Reset Code',
          isLoading: _isLoading,
          onPressed: _requestOtp,
        ),
      ],
    );
  }

  Widget _buildConfirmForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: ChiromoColors.primary),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the code we sent to ${_emailCtrl.text} along with your new password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ChiromoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_error!, style: const TextStyle(color: ChiromoColors.error)),
          ),
        ChiromoTextField(
          controller: _otpCtrl,
          label: 'Reset code',
          hint: '123456',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ChiromoTextField(
          controller: _passwordCtrl,
          label: 'New password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 16),
        ChiromoTextField(
          controller: _confirmPasswordCtrl,
          label: 'Confirm new password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure,
        ),
        const SizedBox(height: 32),
        ChiromoButton(
          label: 'Reset Password',
          isLoading: _isLoading,
          onPressed: _confirmReset,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _step = _ForgotPasswordStep.request;
                    _error = null;
                  }),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: ChiromoColors.success),
        const SizedBox(height: 24),
        Text(
          'Password reset',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been reset successfully. Sign in with your new password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ChiromoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ChiromoButton(
          label: 'Back to Sign In',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
