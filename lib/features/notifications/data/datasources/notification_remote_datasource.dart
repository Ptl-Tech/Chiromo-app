import '../../../../core/services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final _client = SupabaseService.client;

  /// Fetch all notifications for the current user, newest first.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  /// Mark all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
