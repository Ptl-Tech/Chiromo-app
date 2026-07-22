import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../doctor/presentation/providers/doctor_providers.dart';

class BrowseDoctorsScreen extends ConsumerStatefulWidget {
  const BrowseDoctorsScreen({super.key});

  @override
  ConsumerState<BrowseDoctorsScreen> createState() =>
      _BrowseDoctorsScreenState();
}

class _BrowseDoctorsScreenState extends ConsumerState<BrowseDoctorsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Our Specialists',
      showBack: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or specialty...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ChiromoColors.surfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ref
                .watch(allDoctorsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                  data: (doctors) {
                    final filteredDoctors = doctors.where((doc) {
                      final name = doc.userProfile?.fullName ?? '';
                      final specialty = doc.specialty;
                      final query = _searchQuery.toLowerCase();
                      return name.toLowerCase().contains(query) ||
                          specialty.toLowerCase().contains(query);
                    }).toList();

                    if (filteredDoctors.isEmpty) {
                      return const Center(child: Text('No specialists found.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDoctors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = filteredDoctors[index];
                        return _buildDoctorCard(
                          theme: theme,
                          name: doc.userProfile?.fullName ?? 'Unknown',
                          specialty: doc.specialty,
                          qualifications: doc.qualifications,
                          fee: doc.consultationFee,
                          isAvailable: doc.isAvailable,
                          imageUrl:
                              doc.userProfile?.avatarUrl ??
                              'https://i.pravatar.cc/150?u=${doc.id}',
                          onChat: () {
                            context.pushNamed(
                              'patient-chat',
                              pathParameters: {'doctorId': doc.id},
                              queryParameters: {
                                'doctorName':
                                    doc.userProfile?.fullName ?? 'Doctor',
                                'specialty': doc.specialty,
                                if (doc.userProfile?.avatarUrl != null)
                                  'avatarUrl': doc.userProfile!.avatarUrl!,
                              },
                            );
                          },
                          onBook: () {
                            context.push('/patient/book');
                          },
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required ThemeData theme,
    required String name,
    required String specialty,
    required String qualifications,
    required double fee,
    required bool isAvailable,
    required String imageUrl,
    required VoidCallback onChat,
    required VoidCallback onBook,
  }) {
    final displayName = name.toLowerCase().startsWith('dr') ? name : 'Dr. $name';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ChiromoColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChiromoColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: ChiromoColors.surfaceVariant,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: ChiromoColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? ChiromoColors.successLight
                                    : ChiromoColors.errorLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? ChiromoColors.success
                                          : ChiromoColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAvailable ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: isAvailable
                                          ? ChiromoColors.success
                                          : ChiromoColors.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: const TextStyle(
                            color: ChiromoColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 14,
                              color: ChiromoColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                qualifications,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ChiromoColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ChiromoColors.surfaceVariant.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: ChiromoColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consultation Fee',
                        style: TextStyle(
                          fontSize: 11,
                          color: ChiromoColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'KES ${fee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ChiromoColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onBook,
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: const Text('Book'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChiromoColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
