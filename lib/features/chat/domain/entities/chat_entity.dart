import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional nested relationships for UI convenience
  final String? patientName;
  final String? patientAvatarUrl;
  final String? doctorName;
  final String? doctorAvatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.patientAvatarUrl,
    this.doctorName,
    this.doctorAvatarUrl,
    this.lastMessageContent,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        createdAt,
        updatedAt,
        patientName,
        patientAvatarUrl,
        doctorName,
        doctorAvatarUrl,
        lastMessageContent,
        lastMessageAt,
        unreadCount,
      ];
}
