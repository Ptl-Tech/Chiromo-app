import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/loading/shimmer_loading.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../providers/admin_providers.dart';

class BranchManagementScreen extends ConsumerWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBranches = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () {},
          ),
        ],
      ),
      body: asyncBranches.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: ShimmerCard(height: 200),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: 'Unable to load branches',
          onRetry: () => ref.invalidate(branchesProvider),
        ),
        data: (branches) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Branches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.5 : 2.5,
                    children: branches.map((branch) =>
                      _buildBranchCard(branch.name, branch.type, branch.location, branch.isActive),
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchCard(String name, String type, String location, bool isActive) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChiromoColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: ChiromoColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? ChiromoColors.statusConfirmed.withValues(alpha: 0.1) : ChiromoColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? ChiromoColors.statusConfirmed : ChiromoColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(type, style: const TextStyle(color: ChiromoColors.primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: ChiromoColors.textSecondary),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(color: ChiromoColors.textSecondary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
