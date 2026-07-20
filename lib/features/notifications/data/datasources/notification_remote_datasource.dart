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
    _cachedDummyNotifications = [
      NotificationModel(
        id: 'notif-1',
        userId: 'demo',
        title: 'Appointment Confirmed',
        body: 'Your appointment with Dr. Angela Wambui on Monday at 10:00 AM has been confirmed.',
        type: 'appointment_confirmed',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      NotificationModel(
        id: 'notif-2',
        userId: 'demo',
        title: 'New Message from Dr. David',
        body: 'Dr. David Omondi has sent you a new message regarding your recent check-in.',
        type: 'doctor_message',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif-3',
        userId: 'demo',
        title: 'CBT Exercise Feedback',
        body: 'Your therapist has reviewed your latest thought record and left feedback.',
        type: 'cbt_feedback',
        isRead: false,
        metadata: {},
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: 'notif-4',
        userId: 'demo',
        title: 'Appointment Reminder',
        body: 'Reminder: You have an appointment with Dr. Sarah Chen tomorrow at 2:00 PM.',
        type: 'appointment_reminder',
        isRead: true,
        metadata: {},
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'notif-5',
        userId: 'demo',
        title: 'Welcome to Chiromo!',
        body: 'Thank you for joining Chiromo Hospital Group. Start by booking your first appointment or exploring our CBT tools.',
        type: 'system',
        isRead: true,
        metadata: {},
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    return _cachedDummyNotifications!;
  }
}
