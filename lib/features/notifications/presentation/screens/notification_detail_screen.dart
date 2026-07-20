import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationEntity notification;

  const NotificationDetailScreen({super.key, required this.notification});

  String _imageForType(NotificationEntity notification) {
    if (notification.type.startsWith('appointment')) {
      return 'assets/images/notifications/appointment.png';
    } else if (notification.type == 'doctor_message') {
      return 'assets/images/notifications/message.png';
    } else if (notification.type == 'cbt_feedback') {
      if (notification.title.toLowerCase().contains('thought')) {
        return 'assets/images/cbt_tools/thought_record.png';
      }
      return 'assets/images/notifications/cbt.png';
    } else {
      // Use app logo for system notifications
      return 'assets/images/app_icon.png';
    }
  }

  void _handleActionTap(BuildContext context) {
    // Determine the deep link destination based on notification type
    if (notification.isAppointment) {
      context.go('/patient/history');
    } else if (notification.isDoctorMessage) {
      context.go('/patient/messages');
    } else if (notification.isCbtFeedback) {
      context.push('/patient/cbt');
    } else {
      context.pop(); // System messages just dismiss
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Beautiful 3D Icon Header
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ChiromoColors.primarySurface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ChiromoColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  _imageForType(notification),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              // Notification Content Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Call to action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => _handleActionTap(context),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    notification.isSystem ? 'Dismiss' : 'View Related Details',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
