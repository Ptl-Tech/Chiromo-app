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

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
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
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
            child: _sent ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );

  }

  Widget _buildForm() {
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
          'Enter your email address and we will send you a link to reset your password.',
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
          label: 'Send Reset Link',
          isLoading: _isLoading,
          onPressed: _reset,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: ChiromoColors.success),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We have sent a password reset link to ${_emailCtrl.text}',
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
