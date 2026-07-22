import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class MockWelcomeDoctor {
  final String name;
  final String specialty;
  final String qualifications;
  final double rating;
  final String imagePath; // local asset
  final String quote;

  const MockWelcomeDoctor({
    required this.name,
    required this.specialty,
    required this.qualifications,
    required this.rating,
    required this.imagePath,
    required this.quote,
  });
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<MockWelcomeDoctor> _doctors = const [
    MockWelcomeDoctor(
      name: 'Dr. Angela Wambui',
      specialty: 'Lead Psychiatrist',
      qualifications: 'MD, MMed (Psychiatry)',
      rating: 4.9,
      imagePath: 'assets/images/doctors/doctor_female_1.png',
      quote: 'Recovery is a path of restoration and dignity. Let\'s walk it together.',
    ),
    MockWelcomeDoctor(
      name: 'Dr. David Omondi',
      specialty: 'Clinical Psychologist',
      qualifications: 'PhD in Clinical Psychology',
      rating: 4.8,
      imagePath: 'assets/images/doctors/doctor_male_1.png',
      quote: 'Understanding your emotional wellness is the first step towards healing.',
    ),
    MockWelcomeDoctor(
      name: 'Dr. Sarah Chen',
      specialty: 'Therapist & Counselor',
      qualifications: 'MA in Counseling Psychology',
      rating: 4.9,
      imagePath: 'assets/images/doctors/doctor_female_2.png',
      quote: 'Providing a safe space for growth, resilience, and positive change.',
    ),
    MockWelcomeDoctor(
      name: 'Dr. James Musembi',
      specialty: 'Addiction Specialist',
      qualifications: 'MMed, Specialist in Recovery Care',
      rating: 4.7,
      imagePath: 'assets/images/doctors/doctor_male_2.png',
      quote: 'Empowering you to reclaim control and thrive in daily life.',
    ),
  ];

  late final _autoSlideTimer = _startAutoSlide();

  @override
  void initState() {
    super.initState();
    // _autoSlideTimer is already initialised above
  }

  @override
  void dispose() {
    _autoSlideTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Auto-slide every 4 seconds, looping back to the first card.
  _AutoSlideTimer _startAutoSlide() {
    return _AutoSlideTimer(
      duration: const Duration(seconds: 4),
      onTick: () {
        if (!mounted || !_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % _doctors.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Welcome',
      showAppBar: false,
      showBack: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    ChiromoColors.darkBackground,
                    ChiromoColors.darkSurface.withValues(alpha: 0.8),
                    ChiromoColors.darkBackground,
                  ]
                : [
                    ChiromoColors.white,
                    ChiromoColors.primarySurface.withValues(alpha: 0.6),
                    ChiromoColors.white,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // App Brand Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/app_icon.png',
                      height: 48,
                      width: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: ChiromoColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chiromo Hospital Group',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Recovery In Dignity',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ChiromoColors.crimson,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Welcome Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Text(
                      'Your Mental Health Partner',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? ChiromoColors.darkTextPrimary : ChiromoColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with leading psychiatrists, psychologists, and specialists. Access tools and guidance to support your recovery.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? ChiromoColors.darkTextSecondary : ChiromoColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Doctor Carousel Section – NO auto-slide
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _doctors[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? ChiromoColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? ChiromoColors.darkBorder
                                    : ChiromoColors.border.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          doctor.imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: ChiromoColors.primarySurface,
                                              child: const Icon(
                                                Icons.person,
                                                size: 80,
                                                color: ChiromoColors.primary,
                                              ),
                                            );
                                          },
                                        ),
                                        // Gradient overlay for readability
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: 60,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  (isDark ? ChiromoColors.darkSurface : Colors.white).withValues(alpha: 0.8),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: ChiromoColors.gold,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  doctor.rating.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            doctor.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${doctor.specialty} • ${doctor.qualifications}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: ChiromoColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '"${doctor.quote}"',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: isDark
                                                  ? ChiromoColors.darkTextSecondary
                                                  : ChiromoColors.textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Left Arrow
                    if (_currentPage > 0)
                      Positioned(
                        left: 4,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _goToPage(_currentPage - 1),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Right Arrow
                    if (_currentPage < _doctors.length - 1)
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _goToPage(_currentPage + 1),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Page Indicator + Counter
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _doctors.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? ChiromoColors.primary
                          : (isDark ? ChiromoColors.darkBorder : ChiromoColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_currentPage + 1} of ${_doctors.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? ChiromoColors.darkTextSecondary : ChiromoColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  children: [
                    ChiromoButton(
                      label: 'Get Started',
                      onPressed: () {
                        context.go('/login');
                      },
                    ),
                    const SizedBox(height: 8),
                    ChiromoButton(
                      label: 'Create Account',
                      variant: ChiromoButtonVariant.outline,
                      onPressed: () {
                        context.go('/register');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple periodic timer wrapper for the auto-slide carousel.
class _AutoSlideTimer {
  late final _ticker = Stream.periodic(duration).listen((_) => onTick());
  final Duration duration;
  final VoidCallback onTick;

  _AutoSlideTimer({required this.duration, required this.onTick});

  void cancel() => _ticker.cancel();
}
