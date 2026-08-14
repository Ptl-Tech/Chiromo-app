import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/features/appointments/domain/entities/appointment_entity.dart';
import 'package:chiromo/widgets/buttons/chiromo_button.dart';
import 'package:chiromo/features/doctor/domain/entities/doctor_review_entity.dart';
import 'package:chiromo/features/doctor/presentation/providers/doctor_review_providers.dart';
import 'package:chiromo/features/appointments/presentation/providers/appointment_providers.dart';

class DoctorReviewDialog extends ConsumerStatefulWidget {
  final AppointmentEntity appointment;

  const DoctorReviewDialog({super.key, required this.appointment});

  @override
  ConsumerState<DoctorReviewDialog> createState() => _DoctorReviewDialogState();
}

class _DoctorReviewDialogState extends ConsumerState<DoctorReviewDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(doctorReviewRepositoryProvider);
      final review = DoctorReviewEntity(
        id: '',
        appointmentId: widget.appointment.id,
        patientId: widget.appointment.patientId,
        doctorId: widget.appointment.doctor!.userId,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
        createdAt: DateTime.now(),
      );
      
      await repository.createReview(review);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        ref.invalidate(patientAppointmentsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: ChiromoColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctorName = widget.appointment.doctor?.userProfile?.fullName ?? 'your doctor';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Rate your Session',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How was your session with $doctorName?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? Colors.orange : Colors.grey.shade400,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ChiromoButton(
                    label: 'Submit',
                    onPressed: _isSubmitting ? null : _submitReview,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
