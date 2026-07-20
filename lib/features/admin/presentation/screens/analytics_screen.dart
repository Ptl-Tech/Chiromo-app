import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/loading/shimmer_loading.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../providers/admin_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnalytics = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Executive Analytics',
      showBack: true,
      body: asyncAnalytics.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              ShimmerCard(height: 300),
              SizedBox(height: 32),
              ShimmerCard(height: 300),
            ],
          ),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: 'Unable to load analytics',
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
        data: (analytics) {
          final revenueData = analytics.revenueData
              .map((p) => ChartData(p.label, p.value))
              .toList();
          final appointmentData = analytics.departmentData
              .map((p) => ChartData(p.department, p.count.toDouble()))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue chart
                SizedBox(
                  height: 300,
                  child: Card(
                    elevation: 8,
                    shadowColor: ChiromoColors.primary.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: const NumericAxis(
                          numberFormat: null,
                          labelFormat: 'KES {value}',
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          SplineAreaSeries<ChartData, String>(
                            dataSource: revenueData,
                            xValueMapper: (ChartData data, _) => data.category,
                            yValueMapper: (ChartData data, _) => data.value,
                            gradient: LinearGradient(
                              colors: [
                                ChiromoColors.primary.withValues(alpha: 0.5),
                                ChiromoColors.primaryLight.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderColor: ChiromoColors.primary,
                            borderWidth: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Appointments by Department',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Appointments chart
                SizedBox(
                  height: 300,
                  child: Card(
                    elevation: 8,
                    shadowColor: ChiromoColors.gold.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SfCircularChart(
                        legend: const Legend(
                          isVisible: true,
                          position: LegendPosition.right,
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CircularSeries>[
                          DoughnutSeries<ChartData, String>(
                            dataSource: appointmentData,
                            xValueMapper: (ChartData data, _) => data.category,
                            yValueMapper: (ChartData data, _) => data.value,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
