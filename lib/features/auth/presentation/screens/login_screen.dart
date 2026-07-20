import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../widgets/inputs/chiromo_text_field.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return AppScaffold(
      title: 'Login',
      showBack: false,
      body: Row(
        children: [
          // ── Left hero panel (desktop only) ──
          if (isWide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: ChiromoColors.heroGradient,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Chiromo Hospital\nGroup',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Mental Health Partner',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: ChiromoColors.goldLight,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Secure & HIPAA Compliant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Right form panel ──
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWide) ...[
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ChiromoColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
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
                          ],
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to Chiromo Hospital Management',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ChiromoColors.textSecondary),
                          ),
                          const SizedBox(height: 36),

                          // Error message
                          if (authState is AsyncError)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: ChiromoColors.error.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ChiromoColors.error.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: ChiromoColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${authState.error}',
                                      style: const TextStyle(
                                        color: ChiromoColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email
                          ChiromoTextField(
                            controller: _emailCtrl,
                            label: 'Email address',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          ChiromoTextField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign in button
                          ChiromoButton(
                            label: 'Sign In',
                            isLoading: isLoading,
                            onPressed: _signIn,
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: ChiromoColors.textTertiary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => ref
                                      .read(authNotifierProvider.notifier)
                                      .signInWithGoogle(),
                                  icon: const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                  ),
                                  label: const Text('Google'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => ref
                                      .read(authNotifierProvider.notifier)
                                      .signInWithMagicLink(
                                        _emailCtrl.text.trim(),
                                      ),
                                  icon: const Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('Magic Link'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: ChiromoColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Sign Up'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
