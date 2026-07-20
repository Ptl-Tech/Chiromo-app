import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          notificationsAsync.when(
            data: (notifs) {
              final unreadCount = notifs.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: ChiromoColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: ChiromoColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: ChiromoColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: theme.hintColor,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              padding: const EdgeInsets.all(3),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
              ],
            ),
          ),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 56, color: theme.hintColor),
              const SizedBox(height: 12),
              Text(
                'Unable to load notifications',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(notificationsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          final unread =
              notifications.where((n) => !n.isRead).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _NotificationList(
                notifications: notifications,
                onTap: _onNotificationTap,
                emptyMessage: 'No notifications yet',
                emptyIcon: Icons.notifications_none_rounded,
              ),
              _NotificationList(
                notifications: unread,
                onTap: _onNotificationTap,
                emptyMessage: 'All caught up! 🎉',
                emptyIcon: Icons.check_circle_outline_rounded,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onNotificationTap(NotificationEntity notification) async {
    if (!notification.isRead) {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
    }

    if (!mounted) return;

    // Navigate based on notification type
    if (notification.isAppointment) {
      context.go('/patient/history');
    } else if (notification.isDoctorMessage) {
      context.go('/patient/messages');
    } else if (notification.isCbtFeedback) {
      context.go('/patient/cbt');
    }
  }

  void _markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidate(notificationsProvider);
  }
}

// ─── Notification List ──────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<NotificationEntity> notifications;
  final void Function(NotificationEntity) onTap;
  final String emptyMessage;
  final IconData emptyIcon;

  const _NotificationList({
    required this.notifications,
    required this.onTap,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ChiromoColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon,
                  size: 48, color: ChiromoColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Group notifications by date
    final grouped = _groupByDate(notifications);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            // Date header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                group.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            // Notification cards
            ...group.notifications.map(
              (notif) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(
                  notification: notif,
                  onTap: () => onTap(notif),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_NotificationGroup> _groupByDate(
      List<NotificationEntity> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationEntity>> groups = {};
    final Map<String, String> labels = {};

    for (final notif in notifications) {
      final date =
          DateTime(notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);
      String key;
      if (date == today) {
        key = 'today';
        labels[key] = 'TODAY';
      } else if (date == yesterday) {
        key = 'yesterday';
        labels[key] = 'YESTERDAY';
      } else {
        key = '${date.day}/${date.month}/${date.year}';
        labels[key] = key;
      }
      groups.putIfAbsent(key, () => []).add(notif);
    }

    return groups.entries
        .map((e) =>
            _NotificationGroup(label: labels[e.key]!, notifications: e.value))
        .toList();
  }
}

class _NotificationGroup {
  final String label;
  final List<NotificationEntity> notifications;
  _NotificationGroup({required this.label, required this.notifications});
}

// ─── Single Notification Card ───────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread
          ? ChiromoColors.primarySurface
          : theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? ChiromoColors.primary.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _iconGradient(notification.type),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _iconGradient(notification.type)
                          .first
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: ChiromoColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'appointment_confirmed':
        return Icons.event_available_rounded;
      case 'appointment_reminder':
        return Icons.access_time_filled_rounded;
      case 'doctor_message':
        return Icons.chat_bubble_rounded;
      case 'cbt_feedback':
        return Icons.psychology_rounded;
      case 'system':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  List<Color> _iconGradient(String type) {
    switch (type) {
      case 'appointment_confirmed':
        return [ChiromoColors.success, const Color(0xFF00C853)];
      case 'appointment_reminder':
        return [ChiromoColors.warning, ChiromoColors.goldDark];
      case 'doctor_message':
        return [ChiromoColors.info, const Color(0xFF2979FF)];
      case 'cbt_feedback':
        return [ChiromoColors.crimson, const Color(0xFFE91E63)];
      case 'system':
        return [ChiromoColors.primaryDark, ChiromoColors.primary];
      default:
        return [ChiromoColors.primary, ChiromoColors.primaryLight];
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
