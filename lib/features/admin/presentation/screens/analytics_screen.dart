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
              ShimmerCard(height: 320),
              SizedBox(height: 40),
              ShimmerCard(height: 320),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Revenue Analytics', 'Monthly income overview in KES'),
                const SizedBox(height: 20),
                _buildRevenueChart(context, revenueData),
                const SizedBox(height: 40),
                _buildSectionHeader('Department Performance', 'Distribution of appointments'),
                const SizedBox(height: 20),
                _buildDepartmentChart(context, appointmentData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: ChiromoColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context, List<ChartData> data) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
        ),
        primaryYAxis: const NumericAxis(
          numberFormat: null,
          labelFormat: '{value}k',
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000), // very light gray
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: Colors.white,
          textStyle: const TextStyle(color: ChiromoColors.primary, fontWeight: FontWeight.bold),
          elevation: 10,
        ),
        series: <CartesianSeries>[
          SplineAreaSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            gradient: LinearGradient(
              colors: [
                ChiromoColors.primary.withValues(alpha: 0.5),
                ChiromoColors.primaryLight.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: ChiromoColors.primary,
            borderWidth: 3,
            markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, borderColor: ChiromoColors.primary),
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart(BuildContext context, List<ChartData> data) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.gold.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.right,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CircularSeries>[
          DoughnutSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            innerRadius: '65%',
            animationDuration: 1500,
            explode: true,
            explodeIndex: 0,
          ),
        ],
      ),
    );
  }
}

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
