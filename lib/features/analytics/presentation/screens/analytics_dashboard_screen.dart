import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../theme/chiromo_colors.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {},
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                              if (value.toInt() >= 0 && value.toInt() < months.length) {
                                return Text(months[value.toInt()], style: const TextStyle(fontSize: 12));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 4),
                            FlSpot(2, 3.5),
                            FlSpot(3, 5),
                            FlSpot(4, 4.5),
                            FlSpot(5, 6),
                            FlSpot(6, 7),
                          ],
                          isCurved: true,
                          color: ChiromoColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: ChiromoColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Patient Demographics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: ChiromoColors.primary,
                                value: 40,
                                title: '40%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: ChiromoColors.gold,
                                value: 30,
                                title: '30%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: ChiromoColors.accent,
                                value: 15,
                                title: '15%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: ChiromoColors.warning,
                                value: 15,
                                title: '15%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Anxiety', ChiromoColors.primary),
                          _buildLegendItem('Depression', ChiromoColors.gold),
                          _buildLegendItem('Substance Abuse', ChiromoColors.accent),
                          _buildLegendItem('Other', ChiromoColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

