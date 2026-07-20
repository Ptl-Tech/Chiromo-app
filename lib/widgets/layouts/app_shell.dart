import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../theme/chiromo_colors.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/auth/domain/entities/user_entity.dart';

/// Responsive shell providing NavigationRail (desktop/tablet) or
/// BottomNavigationBar (mobile) with branded Chiromo styling.
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final role = user?.role ?? UserRole.patient;

    final navItems = _navItemsForRole(role);
    final currentIndex = _currentIndex(context, navItems);

    if (context.isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              user: user,
              navItems: navItems,
              selectedIndex: currentIndex,
              onSignOut: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    if (context.isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => context.go(navItems[i].route),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: ChiromoColors.primary,
                  size: 32,
                ),
              ),
              destinations: navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: _buildIcon(item, selected: false),
                      selectedIcon: _buildIcon(item, selected: true),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: ChiromoColors.primary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(navItems[i].route),
          destinations: navItems
              .map(
                (item) => NavigationDestination(
                  icon: _buildIcon(item, selected: false),
                  selectedIcon: _buildIcon(item, selected: true),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildIcon(_NavItem item, {required bool selected}) {
    if (item.imageAsset != null) {
      if (selected) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ChiromoColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(item.imageAsset!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ChiromoColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      } else {
        return Opacity(
          opacity: 0.45,
          child: Image.asset(item.imageAsset!, width: 28, height: 28),
        );
      }
    }
    return Icon(selected ? item.activeIcon : item.icon);
  }

  int _currentIndex(BuildContext context, List<_NavItem> items) {
    var location = GoRouterState.of(context).uri.toString();
    location = location.split('?').first;
    if (location.endsWith('/')) {
      location = location.substring(0, location.length - 1);
    }

    int bestMatchIndex = 0;
    int longestMatch = 0;

    for (var i = 0; i < items.length; i++) {
      final route = items[i].route;
      if (location == route || location.startsWith('$route/')) {
        if (route.length > longestMatch) {
          longestMatch = route.length;
          bestMatchIndex = i;
        }
      }
    }
    return bestMatchIndex;
  }

  List<_NavItem> _navItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return const [
          _NavItem('Home', Icons.home_outlined, Icons.home, '/patient', 'assets/images/nav/home.png'),
          _NavItem('Appointments', Icons.event_outlined, Icons.event, '/patient/history', 'assets/images/nav/appointments.png'),
          _NavItem('My Health', Icons.favorite_outlined, Icons.favorite, '/patient/health', 'assets/images/nav/health.png'),
          _NavItem('Messages', Icons.chat_outlined, Icons.chat, '/patient/messages', 'assets/images/nav/messages.png'),
          _NavItem('Profile', Icons.person_outline, Icons.person, '/patient/profile', 'assets/images/nav/profile.png'),
        ];
      case UserRole.doctor:
      case UserRole.psychiatrist:
      case UserRole.psychologist:
      case UserRole.therapist:
        return const [
          _NavItem(
            'Dashboard',
            Icons.dashboard_outlined,
            Icons.dashboard,
            '/doctor',
          ),
          _NavItem(
            'Calendar',
            Icons.calendar_today_outlined,
            Icons.calendar_today,
            '/doctor/calendar',
          ),
          _NavItem(
            'Patients',
            Icons.people_outline,
            Icons.people,
            '/doctor/patients',
          ),
          _NavItem(
            'Notes',
            Icons.note_alt_outlined,
            Icons.note_alt,
            '/doctor/notes',
          ),
          _NavItem(
            'Profile',
            Icons.person_outline,
            Icons.person,
            '/doctor/profile',
          ),
        ];
      case UserRole.superAdmin:
      case UserRole.hospitalAdmin:
      case UserRole.branchManager:
        return const [
          _NavItem(
            'Dashboard',
            Icons.dashboard_outlined,
            Icons.dashboard,
            '/admin',
          ),
          _NavItem(
            'Users',
            Icons.manage_accounts_outlined,
            Icons.manage_accounts,
            '/admin/users',
          ),
          _NavItem(
            'Branches',
            Icons.business_outlined,
            Icons.business,
            '/admin/branches',
          ),
          _NavItem(
            'Analytics',
            Icons.analytics_outlined,
            Icons.analytics,
            '/analytics',
          ),
          _NavItem(
            'Settings',
            Icons.settings_outlined,
            Icons.settings,
            '/admin/settings',
          ),
        ];
      case UserRole.receptionist:
      case UserRole.nurse:
      case UserRole.laboratory:
        return const [
          _NavItem(
            'Dashboard',
            Icons.dashboard_outlined,
            Icons.dashboard,
            '/reception',
          ),
          _NavItem(
            'Queue',
            Icons.queue_outlined,
            Icons.queue,
            '/reception/queue',
          ),
          _NavItem(
            'Analytics',
            Icons.analytics_outlined,
            Icons.analytics,
            '/analytics',
          ),
        ];
      case UserRole.cashier:
        return const [
          _NavItem(
            'Cashier',
            Icons.point_of_sale_outlined,
            Icons.point_of_sale,
            '/cashier',
          ),
          _NavItem(
            'Analytics',
            Icons.analytics_outlined,
            Icons.analytics,
            '/analytics',
          ),
        ];
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? imageAsset;

  const _NavItem(this.label, this.icon, this.activeIcon, this.route, [this.imageAsset]);
}

/// Expanded sidebar used on desktop breakpoints.
class _DesktopSidebar extends StatelessWidget {
  final UserEntity? user;
  final List<_NavItem> navItems;
  final int selectedIndex;
  final VoidCallback onSignOut;

  const _DesktopSidebar({
    required this.user,
    required this.navItems,
    required this.selectedIndex,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // ── Brand header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: ChiromoColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chiromo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ChiromoColors.primary,
                            ),
                      ),
                      Text(
                        'Hospital Group',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ChiromoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Nav items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                final selected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: selected
                        ? ChiromoColors.primarySurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => GoRouter.of(context).go(item.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (item.imageAsset != null)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: ColorFiltered(
                                  colorFilter: selected
                                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                      : const ColorFilter.matrix(<double>[
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0,      0,      0,      1, 0,
                                        ]),
                                  child: Opacity(
                                    opacity: selected ? 1.0 : 0.6,
                                    child: Image.asset(item.imageAsset!),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                selected ? item.activeIcon : item.icon,
                                size: 22,
                                color: selected
                                    ? ChiromoColors.primary
                                    : ChiromoColors.textSecondary,
                              ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected
                                    ? ChiromoColors.primary
                                    : ChiromoColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── User footer ──
          if (user != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ChiromoColors.primarySurface,
                    child: Text(
                      (user!.fullName ?? user!.email)[0].toUpperCase(),
                      style: const TextStyle(
                        color: ChiromoColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user!.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user!.role.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: ChiromoColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    onPressed: onSignOut,
                    tooltip: 'Sign out',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
