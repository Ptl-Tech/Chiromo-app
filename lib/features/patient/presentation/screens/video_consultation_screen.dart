import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';

class VideoConsultationScreen extends ConsumerWidget {
  final AppointmentEntity appointment;

  const VideoConsultationScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorName = appointment.doctor?.userProfile?.fullName ?? 'Doctor';
    final appointmentDate =
        '${appointment.scheduledAt.day}/${appointment.scheduledAt.month}/${appointment.scheduledAt.year}';
    final appointmentTime =
        '${appointment.scheduledAt.hour.toString().padLeft(2, '0')}:${appointment.scheduledAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Video Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF7FF), Color(0xFFDCEEFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ChiromoColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live video session',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ChiromoColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join your session with $doctorName now.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(appointmentDate),
                      const SizedBox(width: 24),
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(appointmentTime),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    backgroundColor: ChiromoColors.primary.withValues(
                      alpha: 0.14,
                    ),
                    label: const Text('Telemedicine'),
                    labelStyle: const TextStyle(
                      color: ChiromoColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ChiromoColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.videocam_outlined,
                          size: 58,
                          color: ChiromoColors.primary,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'You are ready to join the session.',
                          style: TextStyle(
                            fontSize: 16,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting the video session...'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
