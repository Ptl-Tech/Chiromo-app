import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../providers/cbt_providers.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';

class PatientChatScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? avatarUrl;
  final String specialty;

  const PatientChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    this.avatarUrl,
  });

  @override
  ConsumerState<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends ConsumerState<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final user = SupabaseService.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send messages.')),
        );
      }
      setState(() => _isSending = false);
      return;
    }

    try {
      // Look up the doctor's profile user_id
      final doctorRow = await SupabaseService.client
          .from('doctors')
          .select('user_id')
          .eq('id', widget.doctorId)
          .maybeSingle();
      final doctorProfileId = doctorRow?['user_id'] as String?;

      // Find the latest appointment between patient and doctor
      final appointmentRow = await SupabaseService.client
          .from('appointments')
          .select('id')
          .eq('patient_id', user.id)
          .eq('doctor_id', widget.doctorId)
          .order('scheduled_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final appointmentId = appointmentRow?['id'] as String?;

      if (doctorProfileId == null || appointmentId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You need an appointment before you can chat with this doctor.',
              ),
            ),
          );
        }
        setState(() => _isSending = false);
        return;
      }

      // Insert the message — .insert() returns void on success
      await SupabaseService.client.from('chat_messages').insert({
        'appointment_id': appointmentId,
        'sender_id': user.id,
        'receiver_id': doctorProfileId,
        'content': text,
        'is_read': false,
      });

      // Success — clear input and refresh messages
      _messageController.clear();
      ref.invalidate(patientChatMessagesProvider(widget.doctorId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildHealthTrendCard(BuildContext context, List<double> data) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                foregroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctorName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.specialty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ChiromoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ChiromoColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: ChiromoColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Weekly wellbeing trend',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ChiromoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty || data.length < 2)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                data.isEmpty
                    ? 'No recent check-in data to display'
                    : 'Not enough data for a trend line',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              'D${value.toInt() + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                FlSpot(entry.key.toDouble(), entry.value),
                          )
                          .toList(),
                      isCurved: true,
                      barWidth: 4,
                      color: ChiromoColors.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ChiromoColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(
      patientChatMessagesProvider(widget.doctorId),
    );

    final recentProgress = ref.watch(cbtRecentProgressProvider);
    final List<double> chartData = recentProgress.when(
      data: (exercises) {
        final checkins = exercises
            .where((e) => e.type == CbtExerciseType.dailyCheckin)
            .toList();
        return checkins.reversed
            .take(7)
            .map((e) => (e.data['mood'] as num?)?.toDouble() ?? 0.0)
            .toList()
            .reversed
            .toList();
      },
      loading: () => [],
      error: (_, _) => [],
    );

    return AppScaffold(
      title: 'Chat with ${widget.doctorName}',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHealthTrendCard(context, chartData),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ChiromoColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: messagesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(
                            child: Text(
                              'Unable to load chat: $error',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          data: (messages) {
                            if (messages.isEmpty) {
                              return Center(
                                child: Text(
                                  'No chat history yet. Say hello to ${widget.doctorName}.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: ChiromoColors.textSecondary,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isDoctor =
                                    message.senderId !=
                                    SupabaseService.auth.currentUser?.id;
                                return Align(
                                  alignment: isDoctor
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.75,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDoctor
                                          ? ChiromoColors.surfaceVariant
                                          : ChiromoColors.primary,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(
                                          isDoctor ? 4 : 20,
                                        ),
                                        bottomRight: Radius.circular(
                                          isDoctor ? 20 : 4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      message.content,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDoctor
                                                ? ChiromoColors.textPrimary
                                                : ChiromoColors.white,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _messageController,
                                textInputAction: TextInputAction.send,
                                maxLines: 4,
                                minLines: 1,
                                style: theme.textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(
                                    color: ChiromoColors.textSecondary
                                        .withValues(alpha: 0.5),
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: ChiromoColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ChiromoColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 20),
                              color: Colors.white,
                              onPressed: _isSending ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
