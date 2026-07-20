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
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qualifications,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? ChiromoColors.successLight
                                  : ChiromoColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAvailable ? 'Available' : 'Offline',
                              style: TextStyle(
                                color: isAvailable
                                    ? ChiromoColors.success
                                    : ChiromoColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'KES ${fee.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
