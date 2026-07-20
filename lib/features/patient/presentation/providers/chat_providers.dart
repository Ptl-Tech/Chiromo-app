import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  final user = SupabaseService.auth.currentUser;
  if (user == null) return 0;

  final response = await SupabaseService.client
      .from('chat_messages')
      .select()
      .eq('receiver_id', user.id)
      .eq('is_read', false);

  return (response as List).length;
});

class DoctorChatSummary {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String? avatarUrl;
  final String latestMessage;
  final int unreadCount;
  final DateTime lastUpdated;

  DoctorChatSummary({
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.avatarUrl,
    required this.latestMessage,
    required this.unreadCount,
    required this.lastUpdated,
  });
}

final patientChatSummaryProvider = FutureProvider<List<DoctorChatSummary>>((
  ref,
) async {
  final user = SupabaseService.auth.currentUser;
  if (user == null) return [];

  final messagesResponse = await SupabaseService.client
      .from('chat_messages')
      .select(
        'id, appointment_id, sender_id, receiver_id, content, is_read, created_at',
      )
      .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
      .order('created_at', ascending: false);

  final messages = (messagesResponse as List).cast<Map<String, dynamic>>();
  if (messages.isEmpty) return [];

  final appointmentIds = messages
      .map((row) => row['appointment_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final appointmentRows = await SupabaseService.client
      .from('appointments')
      .select('id, doctor_id')
      .inFilter('id', appointmentIds);

  final appointmentMap = <String, String>{};
  for (final row in (appointmentRows as List).cast<Map<String, dynamic>>()) {
    final id = row['id'] as String?;
    final doctorId = row['doctor_id'] as String?;
    if (id != null && doctorId != null) {
      appointmentMap[id] = doctorId;
    }
  }

  final doctorIds = appointmentMap.values.toSet().toList();
  if (doctorIds.isEmpty) return [];

  final doctorRows = await SupabaseService.client
      .from('doctors')
      .select('*, profiles(*)')
      .inFilter('id', doctorIds);

  final doctorMap = <String, Map<String, dynamic>>{};
  for (final row in (doctorRows as List).cast<Map<String, dynamic>>()) {
    final id = row['id'] as String?;
    if (id != null) {
      doctorMap[id] = row;
    }
  }

  final summaryByDoctor = <String, DoctorChatSummary>{};

  for (final message in messages) {
    final appointmentId = message['appointment_id'] as String?;
    final doctorId = appointmentId == null
        ? null
        : appointmentMap[appointmentId];
    if (doctorId == null) continue;

    final doctor = doctorMap[doctorId];
    if (doctor == null) continue;

    final profile = doctor['profiles'] as Map<String, dynamic>?;
    final fullName =
        '${(profile?['first_name'] ?? '').toString().trim()} ${(profile?['last_name'] ?? '').toString().trim()}'
            .trim();
    final doctorName = fullName.isEmpty ? 'Doctor' : fullName;
    final specialty = doctor['specialty'] as String? ?? 'General practice';
    final avatarUrl = profile?['avatar_url'] as String?;
    final content = message['content'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(message['created_at'] as String? ?? '') ??
        DateTime.now();
    final isUnread =
        message['receiver_id'] == user.id &&
        (message['is_read'] == false || message['is_read'] == 'false');

    final existing = summaryByDoctor[doctorId];
    if (existing == null) {
      summaryByDoctor[doctorId] = DoctorChatSummary(
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        avatarUrl: avatarUrl,
        latestMessage: content,
        unreadCount: isUnread ? 1 : 0,
        lastUpdated: createdAt,
      );
    } else {
      final unreadCount = existing.unreadCount + (isUnread ? 1 : 0);
      final lastUpdated = createdAt.isAfter(existing.lastUpdated)
          ? createdAt
          : existing.lastUpdated;
      summaryByDoctor[doctorId] = DoctorChatSummary(
        doctorId: existing.doctorId,
        doctorName: existing.doctorName,
        specialty: existing.specialty,
        avatarUrl: existing.avatarUrl,
        latestMessage: existing.latestMessage.isEmpty
            ? content
            : existing.latestMessage,
        unreadCount: unreadCount,
        lastUpdated: lastUpdated,
      );
    }
  }

  final summaries = summaryByDoctor.values.toList();
  summaries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  return summaries;
});

class ChatMessage {
  final String id;
  final String appointmentId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] == true || json['is_read'] == 'true',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final patientChatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, doctorId) async {
      final user = SupabaseService.auth.currentUser;
      if (user == null) return [];

      final doctorRow = await SupabaseService.client
          .from('doctors')
          .select('user_id')
          .eq('id', doctorId)
          .maybeSingle();
      if (doctorRow == null) return [];

      final doctorProfileId = doctorRow['user_id'] as String?;
      if (doctorProfileId == null) return [];

      final appointmentRow = await SupabaseService.client
          .from('appointments')
          .select('id')
          .eq('patient_id', user.id)
          .eq('doctor_id', doctorId)
          .order('scheduled_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (appointmentRow == null) return [];

      final appointmentId = appointmentRow['id'] as String?;
      if (appointmentId == null) return [];

      final response = await SupabaseService.client
          .from('chat_messages')
          .select()
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: true);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    });
