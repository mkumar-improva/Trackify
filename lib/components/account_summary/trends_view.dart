import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackify/theme/app_theme.dart';

class TrendsView extends StatelessWidget {
  const TrendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Spent',
                    '₹45,280',
                    Colors.red.shade100,
                    Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Avg/Month',
                    '₹7,547',
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart Section
            const Text(
              'Monthly Spending',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10000,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '₹${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  barGroups: _getBarGroups(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Details
            const Text(
              'Spending Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Highest Month', 'August', '₹9,450'),
            _buildDetailRow('Lowest Month', 'April', '₹5,120'),
            _buildDetailRow('Total Transactions', '142', ''),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    // Sample data - replace with actual transaction data later
    final data = [5120.0, 6840.0, 7230.0, 8150.0, 9450.0, 8490.0];

    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            color: AppTheme.linkPurple,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
