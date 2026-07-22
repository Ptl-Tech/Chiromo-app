import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.createdAt,
    required super.updatedAt,
    super.patientName,
    super.patientAvatarUrl,
    super.doctorName,
    super.doctorAvatarUrl,
    super.lastMessageContent,
    super.lastMessageAt,
    super.unreadCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      patientName: json['patient_name'] as String?,
      patientAvatarUrl: json['patient_avatar_url'] as String?,
      doctorName: json['doctor_name'] as String?,
      doctorAvatarUrl: json['doctor_avatar_url'] as String?,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String) 
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatModel.fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      patientId: entity.patientId,
      doctorId: entity.doctorId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      patientName: entity.patientName,
      patientAvatarUrl: entity.patientAvatarUrl,
      doctorName: entity.doctorName,
      doctorAvatarUrl: entity.doctorAvatarUrl,
      lastMessageContent: entity.lastMessageContent,
      lastMessageAt: entity.lastMessageAt,
      unreadCount: entity.unreadCount,
    );
  }
}
