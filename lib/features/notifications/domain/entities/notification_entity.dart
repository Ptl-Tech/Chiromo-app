/// Domain entity representing an in-app notification.
class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.metadata,
    required this.createdAt,
  });

  /// Convenience getters for notification types
  bool get isAppointment => type.startsWith('appointment');
  bool get isDoctorMessage => type == 'doctor_message';
  bool get isCbtFeedback => type == 'cbt_feedback';
  bool get isSystem => type == 'system';
}
