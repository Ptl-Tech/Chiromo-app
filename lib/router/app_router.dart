import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/screens/analytics_screen.dart';
import '../features/patient/presentation/screens/patient_analytics_screen.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/lock_screen.dart';
import '../features/auth/presentation/screens/security_setup_screen.dart';
import '../features/auth/presentation/providers/security_provider.dart';
import '../features/patient/presentation/screens/patient_dashboard_screen.dart';
import '../features/patient/presentation/screens/book_appointment_screen.dart';
import '../features/patient/presentation/screens/browse_doctors_screen.dart';
import '../features/patient/presentation/screens/patient_profile_screen.dart';
import '../features/patient/presentation/screens/emergency_screen.dart';
import '../features/patient/presentation/screens/edit_safety_plan_screen.dart';
import '../features/patient/presentation/screens/edit_emergency_contact_screen.dart';
import '../features/patient/presentation/screens/patient_records_screen.dart';
import '../features/patient/presentation/screens/appointment_history_screen.dart';
import '../features/patient/presentation/screens/cbt_tools_screen.dart';
import '../features/patient/presentation/screens/thought_record_screen.dart';
import '../features/patient/presentation/screens/behavioral_activation_screen.dart';
import '../features/patient/presentation/screens/exposure_ladder_screen.dart';
import '../features/patient/presentation/screens/cbt_exercise_details_screen.dart';
import '../features/patient/domain/entities/cbt_exercise_entity.dart';
import '../features/patient/presentation/screens/health_screen.dart';
import '../features/patient/presentation/screens/messages_screen.dart';
import '../features/patient/presentation/screens/daily_checkin_screen.dart';
import '../features/patient/presentation/screens/patient_chat_screen.dart';
import '../features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../features/doctor/presentation/screens/doctor_calendar_screen.dart';
import '../features/doctor/presentation/screens/patient_list_screen.dart';
import '../features/doctor/presentation/screens/consultation_screen.dart';
import '../features/doctor/presentation/screens/consultation_notes_screen.dart';
import '../features/doctor/presentation/screens/doctor_profile_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/user_management_screen.dart';
import '../features/admin/presentation/screens/branch_management_screen.dart';
import '../features/admin/presentation/screens/settings_screen.dart';
import '../features/reception/presentation/screens/reception_dashboard_screen.dart';
import '../features/reception/presentation/screens/queue_management_screen.dart';
import '../features/cashier/presentation/screens/cashier_dashboard_screen.dart';

import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../features/notifications/domain/entities/notification_entity.dart';
import '../widgets/layouts/app_shell.dart';

/// GoRouter provider – rebuilds when auth state changes.
Page<dynamic> _fadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final securityState = ref.watch(securityNotifierProvider).valueOrNull;
  final user = authState.valueOrNull;

  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/welcome');

      if (!isLoggedIn && !isAuthRoute) return '/welcome';

      final isLocked = securityState?.isAppLocked ?? false;
      final isLockRoute = state.matchedLocation == '/lock';

      if (isLoggedIn) {
        if (isLocked && !isLockRoute) return '/lock';
        if (!isLocked && isLockRoute) return _homeForRole(user.role);
      }

      if (isLoggedIn && isAuthRoute) return _homeForRole(user.role);

      if (isLoggedIn && !isAuthRoute && !isLockRoute) {
        // Allow patient analytics and admin analytics routes
        if (state.matchedLocation.startsWith('/patient/analytics') ||
            state.matchedLocation.startsWith('/analytics')) {
          return null;
        }

        final allowedPrefix = _allowedPathPrefix(user.role);
        if (!state.matchedLocation.startsWith(allowedPrefix)) {
          return _homeForRole(user.role);
        }
      }

      return null;
    },
    routes: [
      // ── Auth routes (no shell) ────────────────────────────────
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (_, _) => _fadePage(const WelcomeScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, _) => _fadePage(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (_, _) => _fadePage(const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (_, _) => _fadePage(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        pageBuilder: (_, _) => _fadePage(const LockScreen()),
      ),
      GoRoute(
        path: '/security-setup',
        name: 'security-setup',
        pageBuilder: (_, _) => _fadePage(const SecuritySetupScreen()),
      ),

      // ── Authenticated routes (wrapped in AppShell) ────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Patient Main Tabs (contain BottomNavigationBar)
          GoRoute(
            path: '/patient',
            name: 'patient-dashboard',
            pageBuilder: (_, _) => _fadePage(const PatientDashboardScreen()),
          ),
          GoRoute(
            path: '/patient/history',
            name: 'appointment-history',
            pageBuilder: (_, _) => _fadePage(const AppointmentHistoryScreen()),
          ),
          GoRoute(
            path: '/patient/health',
            name: 'patient-health',
            pageBuilder: (_, _) => _fadePage(const HealthScreen()),
          ),
          GoRoute(
            path: '/patient/messages',
            name: 'patient-messages',
            pageBuilder: (_, _) => _fadePage(const MessagesScreen()),
          ),
          GoRoute(
            path: '/patient/analytics',
            name: 'patient-analytics-dashboard',
            pageBuilder: (_, _) => _fadePage(const PatientAnalyticsScreen()),
          ),
          GoRoute(
            path: '/patient/profile',
            name: 'patient-profile',
            pageBuilder: (_, _) => _fadePage(const PatientProfileScreen()),
          ),
          GoRoute(
            path: '/patient/emergency',
            name: 'patient-emergency',
            pageBuilder: (_, _) => _fadePage(const EmergencyScreen()),
          ),
          GoRoute(
            path: '/patient/records',
            name: 'patient-records',
            pageBuilder: (_, _) => _fadePage(const PatientRecordsScreen()),
          ),
          GoRoute(
            path: '/patient/emergency/safety-plan',
            name: 'patient-safety-plan',
            pageBuilder: (_, _) => _fadePage(const EditSafetyPlanScreen()),
          ),
          GoRoute(
            path: '/patient/emergency/contact',
            name: 'patient-emergency-contact',
            pageBuilder: (_, state) {
              final contact =
                  state.extra
                      as dynamic; // Can't easily import EmergencyContactEntity without adding import, let's just pass it or cast to dynamic
              return _fadePage(EditEmergencyContactScreen(contact: contact));
            },
          ),

          // Doctor
          GoRoute(
            path: '/doctor',
            name: 'doctor-dashboard',
            pageBuilder: (_, _) => _fadePage(DoctorDashboardScreen()),
            routes: [
              GoRoute(
                path: 'calendar',
                name: 'doctor-calendar',
                pageBuilder: (_, _) => _fadePage(DoctorCalendarScreen()),
              ),
              GoRoute(
                path: 'patients',
                name: 'doctor-patients',
                pageBuilder: (_, _) => _fadePage(PatientListScreen()),
              ),
              GoRoute(
                path: 'consultation/:appointmentId/:patientId',
                name: 'doctor-consultation',
                builder: (context, state) {
                  return ConsultationScreen(
                    appointmentId: state.pathParameters['appointmentId']!,
                    patientId: state.pathParameters['patientId']!,
                  );
                },
              ),
              GoRoute(
                path: 'notes',
                name: 'consultation-notes',
                pageBuilder: (_, _) => _fadePage(ConsultationNotesScreen()),
              ),
              GoRoute(
                path: 'profile',
                name: 'doctor-profile',
                pageBuilder: (_, _) => _fadePage(DoctorProfileScreen()),
              ),
            ],
          ),

          // Admin
          GoRoute(
            path: '/admin',
            name: 'admin-dashboard',
            pageBuilder: (_, _) => _fadePage(AdminDashboardScreen()),
            routes: [
              GoRoute(
                path: 'users',
                name: 'user-management',
                pageBuilder: (_, _) => _fadePage(UserManagementScreen()),
              ),
              GoRoute(
                path: 'branches',
                name: 'branch-management',
                pageBuilder: (_, _) => _fadePage(BranchManagementScreen()),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                pageBuilder: (_, _) => _fadePage(SettingsScreen()),
              ),
            ],
          ),

          // Reception
          GoRoute(
            path: '/reception',
            name: 'reception-dashboard',
            pageBuilder: (_, _) => _fadePage(ReceptionDashboardScreen()),
            routes: [
              GoRoute(
                path: 'queue',
                name: 'queue-management',
                pageBuilder: (_, _) => _fadePage(QueueManagementScreen()),
              ),
            ],
          ),

          // Cashier
          GoRoute(
            path: '/cashier',
            name: 'cashier-dashboard',
            pageBuilder: (_, _) => _fadePage(CashierDashboardScreen()),
          ),

          // Analytics (Admin)
          GoRoute(
            path: '/analytics',
            name: 'analytics-dashboard',
            pageBuilder: (_, _) => _fadePage(AnalyticsScreen()),
          ),
        ],
      ),

      // ── Patient Sub Routes (Full Screen, No Bottom Navigation) ──
      GoRoute(
        path: '/patient/book',
        name: 'book-appointment',
        pageBuilder: (_, _) => _fadePage(const BookAppointmentScreen()),
      ),
      GoRoute(
        path: '/patient/doctors',
        name: 'browse-doctors',
        pageBuilder: (_, _) => _fadePage(const BrowseDoctorsScreen()),
      ),
      GoRoute(
        path: '/patient/messages/chat/:doctorId',
        name: 'patient-chat',
        pageBuilder: (context, state) {
          final doctorId = state.pathParameters['doctorId']!;
          final doctorName =
              state.uri.queryParameters['doctorName'] ?? 'Doctor';
          final specialty =
              state.uri.queryParameters['specialty'] ?? 'General Practice';
          final avatarUrl = state.uri.queryParameters['avatarUrl'];
          return _fadePage(
            PatientChatScreen(
              doctorId: doctorId,
              doctorName: doctorName,
              specialty: specialty,
              avatarUrl: avatarUrl,
            ),
          );
        },
      ),
      GoRoute(
        path: '/patient/cbt',
        name: 'cbt-tools',
        pageBuilder: (_, _) => _fadePage(const CbtToolsScreen()),
      ),
      GoRoute(
        path: '/patient/cbt/thought-record',
        name: 'thought-record',
        pageBuilder: (_, _) => _fadePage(const ThoughtRecordScreen()),
      ),
      GoRoute(
        path: '/patient/cbt/behavioral-activation',
        name: 'behavioral-activation',
        pageBuilder: (_, _) => _fadePage(const BehavioralActivationScreen()),
      ),
      GoRoute(
        path: '/patient/cbt/exposure-ladder',
        name: 'exposure-ladder',
        builder: (_, _) => const ExposureLadderScreen(),
      ),
      GoRoute(
        path: '/patient/cbt/daily-checkin',
        name: 'daily-checkin',
        builder: (_, _) => const DailyCheckinScreen(),
      ),
      GoRoute(
        path: '/patient/cbt/exercise-details',
        name: 'exercise-details',
        builder: (context, state) {
          final exercise = state.extra as CbtExerciseEntity;
          return CbtExerciseDetailsScreen(exercise: exercise);
        },
      ),
      GoRoute(
        path: '/patient/notifications',
        name: 'patient-notifications',
        builder: (_, _) => const NotificationsScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            name: 'notification-detail',
            builder: (context, state) {
              final notification = state.extra as NotificationEntity;
              return NotificationDetailScreen(notification: notification);
            },
          ),
        ],
      ),
    ],
  );
});

/// Determine the initial route based on the user's role.
String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
    case UserRole.hospitalAdmin:
      return '/admin';
    case UserRole.branchManager:
      return '/admin';
    case UserRole.receptionist:
      return '/reception';
    case UserRole.doctor:
    case UserRole.psychiatrist:
    case UserRole.psychologist:
    case UserRole.therapist:
      return '/doctor';
    case UserRole.nurse:
      return '/reception';
    case UserRole.cashier:
      return '/cashier';
    case UserRole.laboratory:
      return '/reception';
    case UserRole.patient:
      return '/patient';
  }
}

String _allowedPathPrefix(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
    case UserRole.hospitalAdmin:
    case UserRole.branchManager:
      return '/admin';
    case UserRole.receptionist:
    case UserRole.nurse:
    case UserRole.laboratory:
      return '/reception';
    case UserRole.doctor:
    case UserRole.psychiatrist:
    case UserRole.psychologist:
    case UserRole.therapist:
      return '/doctor';
    case UserRole.cashier:
      return '/cashier';
    case UserRole.patient:
      return '/patient';
  }
}
