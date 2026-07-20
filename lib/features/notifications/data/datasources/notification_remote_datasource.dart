import '../../../../core/services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final _client = SupabaseService.client;
  static List<NotificationModel>? _cachedDummyNotifications;

  /// Fetch all notifications for the current user, newest first.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _getDummyNotifications();

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (list.isEmpty) return _getDummyNotifications();
      return list;
    } catch (e) {
      return _getDummyNotifications();
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update dummy data locally
      if (_cachedDummyNotifications != null) {
        final idx = _cachedDummyNotifications!.indexWhere((n) => n.id == notificationId);
        if (idx != -1) {
          final old = _cachedDummyNotifications![idx];
          _cachedDummyNotifications![idx] = NotificationModel(
            id: old.id,
            userId: old.userId,
            title: old.title,
            body: old.body,
            type: old.type,
            isRead: true, // marked read
            metadata: old.metadata,
            createdAt: old.createdAt,
          );
        }
      }

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  /// Mark all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    try {
      // Update dummy data locally
      if (_cachedDummyNotifications != null) {
        _cachedDummyNotifications = _cachedDummyNotifications!.map((old) => NotificationModel(
            id: old.id,
            userId: old.userId,
            title: old.title,
            body: old.body,
            type: old.type,
            isRead: true, // marked read
            metadata: old.metadata,
            createdAt: old.createdAt,
          )).toList();
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  /// Fallback notifications for demo / offline mode.
  List<NotificationModel> _getDummyNotifications() {
    if (_cachedDummyNotifications != null) return _cachedDummyNotifications!;
    
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDay = weekdays[tomorrow.weekday - 1];
    
    _cachedDummyNotifications = [
      NotificationModel(
        id: 'notif-1',
        userId: 'demo',
        title: 'Appointment Confirmed',
        body: 'Your session with Dr. Angela Wambui on $tomorrowDay at 10:00 AM has been confirmed. Please arrive 15 minutes early.',
        type: 'appointment_confirmed',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      NotificationModel(
        id: 'notif-2',
        userId: 'demo',
        title: 'Dr. David Omondi',
        body: 'Hi there! I\'ve reviewed your mood logs from this week. Your progress is encouraging - let\'s discuss during our next session.',
        type: 'doctor_message',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      NotificationModel(
        id: 'notif-3',
        userId: 'demo',
        title: 'Thought Record Reviewed',
        body: 'Dr. Njeri has left feedback on your thought record from ${weekdays[(now.weekday - 2) % 7]}. Tap to view her notes and suggestions.',
        type: 'cbt_feedback',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 4, minutes: 20)),
      ),
      NotificationModel(
        id: 'notif-6',
        userId: 'demo',
        title: 'Daily Check-in Reminder',
        body: 'Don\'t forget to log your mood today! Consistent tracking helps your care team provide better support.',
        type: 'system',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      NotificationModel(
        id: 'notif-4',
        userId: 'demo',
        title: 'Upcoming Session',
        body: 'Reminder: You have a therapy session with Dr. Sarah Chen $tomorrowDay at 2:00 PM. Prepare any topics you\'d like to discuss.',
        type: 'appointment_reminder',
        isRead: true,
        metadata: {},
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      NotificationModel(
        id: 'notif-7',
        userId: 'demo',
        title: 'New CBT Exercise Available',
        body: 'A new behavioral activation worksheet has been assigned to you. Complete it before your next session for best results.',
        type: 'cbt_feedback',
        isRead: true,
        metadata: {},
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      NotificationModel(
        id: 'notif-5',
        userId: 'demo',
        title: 'Welcome to Chiromo!',
        body: 'Thank you for joining Chiromo Hospital Group. Start by booking your first appointment or exploring our CBT self-help tools.',
        type: 'system',
        isRead: true,
        metadata: {},
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    return _cachedDummyNotifications!;
  }
}
