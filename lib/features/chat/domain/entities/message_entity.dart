import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        content,
        attachmentUrl,
        isRead,
        createdAt,
      ];
}
