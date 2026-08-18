import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/loading/shimmer_loading.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../providers/admin_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnalytics = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Executive Analytics Dashboard',
      showBack: true,
      body: asyncAnalytics.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              ShimmerCard(height: 100),
              SizedBox(height: 20),
              ShimmerCard(height: 300),
              SizedBox(height: 20),
              ShimmerCard(height: 300),
            ],
          ),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: 'Unable to load analytics',
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
        data: (analytics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metrics Row 1
                _buildKPIGrid(context, analytics.kpiMetrics, row: 1),
                const SizedBox(height: 24),

                // KPI Metrics Row 2
                _buildKPIGrid(context, analytics.kpiMetrics, row: 2),
                const SizedBox(height: 32),

                // Revenue Analytics
                _buildSectionHeader(
                  '💰 Revenue Analytics',
                  'Weekly income overview in KES',
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(context, analytics.revenueData),
                const SizedBox(height: 32),

                // Appointment Trends
                _buildSectionHeader(
                  '📅 Appointment Trends',
                  'Weekly appointment volume',
                ),
                const SizedBox(height: 16),
                _buildAppointmentTrendChart(
                  context,
                  analytics.appointmentTrends,
                ),
                const SizedBox(height: 32),

                // Two Column Layout: Status & Department
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '✅ Appointment Status',
                            'Completion breakdown',
                          ),
                          const SizedBox(height: 16),
                          _buildAppointmentStatusChart(
                            context,
                            analytics.appointmentStatus,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '🏥 Department Performance',
                            'Appointments by dept',
                          ),
                          const SizedBox(height: 16),
                          _buildDepartmentChart(
                            context,
                            analytics.departmentData,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Top Doctors
                _buildSectionHeader(
                  '⭐ Top Performing Doctors',
                  'Based on appointment volume',
                ),
                const SizedBox(height: 16),
                _buildTopDoctorsChart(context, analytics.topDoctors),
                const SizedBox(height: 32),

                // Two Column Layout: Demographics & Queue Metrics
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '👥 Patient Demographics',
                            'Age distribution',
                          ),
                          const SizedBox(height: 16),
                          _buildDemographicsChart(
                            context,
                            analytics.patientDemographics,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '⏱️ Queue Metrics',
                            'Current wait times',
                          ),
                          const SizedBox(height: 16),
                          _buildQueueMetricsTable(
                            context,
                            analytics.queueMetrics,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPIGrid(
    BuildContext context,
    KPIMetrics metrics, {
    required int row,
  }) {
    late List<_KPICard> cards;

    if (row == 1) {
      cards = [
        _KPICard(
          title: 'Total Appointments',
          value: metrics.totalAppointments.toString(),
          icon: Icons.event,
          color: ChiromoColors.primary,
        ),
        _KPICard(
          title: 'Total Patients',
          value: metrics.totalPatients.toString(),
          icon: Icons.people,
          color: ChiromoColors.gold,
        ),
        _KPICard(
          title: 'Total Revenue',
          value: 'KES ${(metrics.totalRevenue / 1000).toStringAsFixed(0)}k',
          icon: Icons.money,
          color: ChiromoColors.crimson,
        ),
      ];
    } else {
      cards = [
        _KPICard(
          title: 'Avg Consultation',
          value: '${metrics.avgConsultationDuration.toInt()} min',
          icon: Icons.schedule,
          color: ChiromoColors.primaryLight,
        ),
        _KPICard(
          title: 'Available Doctors',
          value: metrics.availableDoctors.toString(),
          icon: Icons.person_4,
          color: ChiromoColors.success,
        ),
        _KPICard(
          title: 'Completion Rate',
          value: '${metrics.appointmentCompletionRate.toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: ChiromoColors.info,
        ),
      ];
    }

    return Row(
      children: List.generate(cards.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < cards.length - 1 ? 12 : 0),
            child: _buildKPICard(context, cards[index]),
          ),
        );
      }),
    );
  }

  Widget _buildKPICard(BuildContext context, _KPICard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            card.color.withValues(alpha: 0.12),
            card.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.color.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ChiromoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ChiromoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: ChiromoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context, List<RevenuePoint> data) {
    final chartData = data.map((p) => ChartData(p.label, p.value)).toList();

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
        ),
        primaryYAxis: const NumericAxis(
          numberFormat: null,
          labelFormat: '{value}k',
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: Colors.white,
          textStyle: const TextStyle(
            color: ChiromoColors.primary,
            fontWeight: FontWeight.bold,
          ),
          elevation: 10,
        ),
        series: <CartesianSeries>[
          SplineAreaSeries<ChartData, String>(
            dataSource: chartData,
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
            markerSettings: const MarkerSettings(
              isVisible: true,
              color: Colors.white,
              borderColor: ChiromoColors.primary,
              borderWidth: 2,
            ),
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTrendChart(
    BuildContext context,
    List<AppointmentTrendPoint> data,
  ) {
    final chartData = data
        .map((p) => ChartData(p.date, p.count.toDouble()))
        .toList();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.gold.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CartesianSeries>[
          ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: ChiromoColors.gold,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusChart(
    BuildContext context,
    List<AppointmentStatusPoint> data,
  ) {
    final chartData = data
        .map((p) => ChartData(p.status, p.count.toDouble()))
        .toList();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.crimson.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CircularSeries>[
          PieSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            animationDuration: 1500,
            explode: true,
            explodeIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart(
    BuildContext context,
    List<DepartmentPoint> data,
  ) {
    final chartData = data
        .map((p) => ChartData(p.department, p.count.toDouble()))
        .toList();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CircularSeries>[
          DoughnutSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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

  Widget _buildTopDoctorsChart(
    BuildContext context,
    List<DoctorPerformancePoint> data,
  ) {
    final chartData = data
        .map(
          (p) =>
              ChartData(p.name.split(' ').last, p.appointmentCount.toDouble()),
        )
        .toList();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.success.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 11,
          ),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CartesianSeries>[
          BarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: ChiromoColors.primary,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsChart(
    BuildContext context,
    List<DemographicPoint> data,
  ) {
    final chartData = data
        .map((p) => ChartData(p.category, p.count.toDouble()))
        .toList();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.info.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 12,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
        series: <CartesianSeries>[
          AreaSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: ChiromoColors.info.withValues(alpha: 0.3),
            borderColor: ChiromoColors.info,
            borderWidth: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
              color: ChiromoColors.info,
              borderColor: Colors.white,
              borderWidth: 2,
            ),
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueMetricsTable(
    BuildContext context,
    List<QueueMetricPoint> data,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.warning.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: ChiromoColors.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Department',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Wait Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Waiting',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(data.length, (index) {
              final item = data[index];
              final isLast = index == data.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.department,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: ChiromoColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Chip(
                            label: Text(
                              '${item.avgWaitTime.toInt()} min',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: ChiromoColors.warning.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: const TextStyle(
                              color: ChiromoColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.patientsWaiting} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: ChiromoColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: ChiromoColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KPICard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
