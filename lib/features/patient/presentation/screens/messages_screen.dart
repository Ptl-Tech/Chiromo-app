import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final summariesAsync = ref.watch(patientChatSummaryProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Messages',
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your Care Conversations',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Talk to your doctor, review shared data, and keep your care team updated.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.monitor_heart_outlined),
                          label: const Text('Health Summary'),
                          onPressed: () => context.go('/patient/health'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.history_edu_outlined),
                          label: const Text('Session Notes'),
                          onPressed: () => context.go('/patient/history'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_shared_outlined,
                          size: 28,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared Data',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'View care notes, assessment reports and your provider updates.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.go('/patient/history'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  summariesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Unable to load messages: $error',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    data: (summaries) {
                      if (summaries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No conversations yet.',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation by booking an appointment with a provider.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/patient/book'),
                                child: const Text('Book a Appointment'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summaries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final summary = summaries[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.14,
                                ),
                              ),
                            ),
                            tileColor: theme.cardColor,
                            leading: CircleAvatar(
                              radius: 26,
                              foregroundImage: summary.avatarUrl != null
                                  ? NetworkImage(summary.avatarUrl!)
                                  : null,
                              child: summary.avatarUrl == null
                                  ? const Icon(Icons.person, size: 28)
                                  : null,
                            ),
                            title: Text(
                              summary.doctorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  summary.specialty,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  summary.latestMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            trailing: summary.unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      summary.unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              context.goNamed(
                                'patient-chat',
                                pathParameters: {'doctorId': summary.doctorId},
                                queryParameters: {
                                  'doctorName': summary.doctorName,
                                  'specialty': summary.specialty,
                                  if (summary.avatarUrl != null)
                                    'avatarUrl': summary.avatarUrl!,
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/patient/doctors'),
              icon: const Icon(Icons.chat),
              label: const Text('Start Chat'),
              tooltip: 'Find a doctor to chat with',
            ),
    );
  }
}
