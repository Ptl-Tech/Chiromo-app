import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/inputs/chiromo_text_field.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    return AppScaffold(
      title: 'Create Account',
      showBack: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ChiromoColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Join Chiromo Hospital Group',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a patient account to book appointments and manage your health records.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: ChiromoColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  if (authState is AsyncError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ChiromoColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: ChiromoColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${authState.error}',
                        style: const TextStyle(
                            color: ChiromoColors.error, fontSize: 13),
                      ),
                    ),

                  ChiromoTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    hint: 'John Doe',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  ChiromoTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '+254 700 000000',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  ChiromoTextField(
                    controller: _emailCtrl,
                    label: 'Email address',
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  ChiromoTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  ChiromoButton(
                    label: 'Create Account',
                    isLoading: isLoading,
                    onPressed: _signUp,
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: TextStyle(color: ChiromoColors.textSecondary)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
