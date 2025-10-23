import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:trackify/theme/app_theme.dart';

enum TrendsViewType { monthly, annual }
enum SpendingType { total, debitOnly, creditOnly }
enum MonthlyViewType { daily, weekly }

class TrendsView extends StatefulWidget {
  final List<SmsMessage> transactions;

  const TrendsView({
    super.key,
    required this.transactions,
  });

  @override
  State<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends State<TrendsView> {
  TrendsViewType _viewType = TrendsViewType.monthly;
  SpendingType _spendingType = SpendingType.total;
  MonthlyViewType _monthlyViewType = MonthlyViewType.daily;
  
  // For monthly view - select which month to show
  String? _selectedMonthForDaily;
  List<String> _availableMonths = [];
  
  // For annual view - select which year to show
  String? _selectedYear;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _calculateAvailableMonths();
    _calculateAvailableYears();
  }

  void _calculateAvailableMonths() {
    final Set<String> months = {};
    for (final msg in widget.transactions) {
      final date = msg.date ?? DateTime.now();
      final monthKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
      months.add(monthKey);
    }
    _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));
    if (_availableMonths.isNotEmpty) {
      _selectedMonthForDaily = _availableMonths.first;
    }
  }

  void _calculateAvailableYears() {
    final Set<String> years = {};
    for (final msg in widget.transactions) {
      final date = msg.date ?? DateTime.now();
      years.add(date.year.toString());
    }
    _availableYears = years.toList()..sort((a, b) => b.compareTo(a));
    if (_availableYears.isNotEmpty) {
      _selectedYear = _availableYears.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearlySummaries = _calculateYearlySummaries();
    final annualMonthData = _calculateAnnualMonthData();
    final monthlyDailyData = _calculateMonthlyDailyData();

    // Get the selected year's summary
    final selectedYearSummary = _selectedYear != null && yearlySummaries.containsKey(_selectedYear)
        ? yearlySummaries[_selectedYear]!
        : (yearlySummaries.isNotEmpty ? yearlySummaries.values.first : null);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year Selector
            Row(
              children: [
                const Text(
                  'Year: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        isDense: true,
                        isExpanded: true,
                        hint: const Text('Select Year'),
                        items: _availableYears.map((year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: Text(
                              year,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Yearly Summary Cards - Show only selected year
            if (selectedYearSummary != null) ...[
              const Text(
                'Yearly Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Debit',
                      '₹${_formatAmount(selectedYearSummary['totalDebit'] ?? 0.0)}',
                      Colors.red.shade100,
                      Colors.red.shade700,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Credit',
                      '₹${_formatAmount(selectedYearSummary['totalCredit'] ?? 0.0)}',
                      Colors.green.shade100,
                      Colors.green.shade700,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Net Spend',
                      '₹${_formatAmount(selectedYearSummary['netSpend'] ?? 0.0)}',
                      Colors.orange.shade100,
                      Colors.orange.shade700,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Avg/Month',
                      '₹${_formatAmount(selectedYearSummary['avgPerMonth'] ?? 0.0)}',
                      Colors.blue.shade100,
                      Colors.blue.shade700,
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // View Type Toggle
            Row(
              children: [
                Expanded(
                  child: _buildViewTypeSelector(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // For Monthly view - show month selector and daily/weekly toggle
            if (_viewType == TrendsViewType.monthly) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonthForDaily,
                          isDense: true,
                          isExpanded: true,
                          hint: const Text('Select Month'),
                          items: _availableMonths.map((monthKey) {
                            return DropdownMenuItem<String>(
                              value: monthKey,
                              child: Text(
                                _formatMonthLabel(monthKey).replaceAll('\n', ' '),
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedMonthForDaily = value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildMonthlyViewButton('Daily', MonthlyViewType.daily, Icons.calendar_today),
                        const SizedBox(width: 4),
                        _buildMonthlyViewButton('Weekly', MonthlyViewType.weekly, Icons.view_week),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Spending Type Filter
            _buildSpendingTypeFilter(),
            const SizedBox(height: 16),

            // Chart Section
            Text(
              _viewType == TrendsViewType.monthly
                  ? 'Daily/Weekly Trends - ${_selectedMonthForDaily != null ? _formatMonthLabel(_selectedMonthForDaily!).replaceAll('\n', ' ') : ''}'
                  : 'Annual Overview - ${_selectedYear ?? ''} (All Months)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              height: 300,
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
              child: _viewType == TrendsViewType.monthly
                  ? _buildMonthlyDailyChart(monthlyDailyData)
                  : _buildAnnualMonthsChart(annualMonthData),
            ),

            const SizedBox(height: 24),

            // Additional Details Section
            const Text(
              'Spending Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (selectedYearSummary != null) ...[
              _buildDetailRow(
                'Total Transactions',
                '${selectedYearSummary['totalTransactions'] ?? 0}',
                '',
                Colors.blue,
              ),
              _buildDetailRow(
                'Debit Transactions',
                '${selectedYearSummary['debitCount'] ?? 0}',
                '${selectedYearSummary['debitPercent']?.toStringAsFixed(1) ?? 0}%',
                Colors.red,
              ),
              _buildDetailRow(
                'Credit Transactions',
                '${selectedYearSummary['creditCount'] ?? 0}',
                '${selectedYearSummary['creditPercent']?.toStringAsFixed(1) ?? 0}%',
                Colors.green,
              ),
              _buildDetailRow(
                'Highest Month',
                selectedYearSummary['highestMonth'] ?? 'N/A',
                '₹${_formatAmount(selectedYearSummary['highestAmount'] ?? 0.0)}',
                Colors.red,
              ),
              _buildDetailRow(
                'Lowest Month',
                selectedYearSummary['lowestMonth'] ?? 'N/A',
                '₹${_formatAmount(selectedYearSummary['lowestAmount'] ?? 0.0)}',
                Colors.green,
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildViewButton(
              'Monthly',
              TrendsViewType.monthly,
              Icons.show_chart,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildViewButton(
              'Annual',
              TrendsViewType.annual,
              Icons.bar_chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, TrendsViewType type, IconData icon) {
    final isSelected = _viewType == type;
    return GestureDetector(
      onTap: () => setState(() => _viewType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.linkPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTypeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Total', SpendingType.total, Colors.purple),
          const SizedBox(width: 8),
          _buildFilterChip('Debit Only', SpendingType.debitOnly, Colors.red),
          const SizedBox(width: 8),
          _buildFilterChip('Credit Only', SpendingType.creditOnly, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SpendingType type, Color color) {
    final isSelected = _spendingType == type;
    return GestureDetector(
      onTap: () => setState(() => _spendingType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyViewButton(String label, MonthlyViewType type, IconData icon) {
    final isSelected = _monthlyViewType == type;
    return GestureDetector(
      onTap: () => setState(() => _monthlyViewType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.linkPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // New chart for Annual view - showing all 12 months
  Widget _buildAnnualMonthsChart(Map<int, Map<String, Map<String, double>>> data) {
    if (data.isEmpty) {
      return _buildEmptyChart('No annual data available');
    }

    // Get all years
    final years = data.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Use selected year or default to the most recent year
    final selectedYearInt = _selectedYear != null ? int.tryParse(_selectedYear!) : null;
    final yearToShow = selectedYearInt != null && data.containsKey(selectedYearInt)
        ? selectedYearInt
        : years.first;
    
    final monthlyData = data[yearToShow]!;
    
    final barGroups = <BarChartGroupData>[];
    double maxY = 0.0;
    double minY = 0.0;

    // First pass: calculate min and max values
    for (int month = 1; month <= 12; month++) {
      final monthKey = month.toString();
      final monthData = monthlyData[monthKey] ?? {'debit': 0.0, 'credit': 0.0};
      final debit = monthData['debit'] ?? 0.0;
      final credit = monthData['credit'] ?? 0.0;
      final total = debit - credit;

      double value = 0.0;
      switch (_spendingType) {
        case SpendingType.total:
          value = total;
          break;
        case SpendingType.debitOnly:
          value = debit;
          break;
        case SpendingType.creditOnly:
          value = credit;
          break;
      }

      if (value > maxY) maxY = value;
      if (value < minY) minY = value;
    }

    // Add padding to min/max
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : 100;
    maxY = maxY + padding;
    minY = minY - padding;
    
    // Ensure we have reasonable bounds
    if (maxY <= 0) maxY = 1000;
    if (minY >= 0) minY = 0;

    // Second pass: create bar groups
    for (int month = 1; month <= 12; month++) {
      final monthKey = month.toString();
      final monthData = monthlyData[monthKey] ?? {'debit': 0.0, 'credit': 0.0};
      final debit = monthData['debit'] ?? 0.0;
      final credit = monthData['credit'] ?? 0.0;
      final total = debit - credit;

      double value = 0.0;
      switch (_spendingType) {
        case SpendingType.total:
          value = total;
          break;
        case SpendingType.debitOnly:
          value = debit;
          break;
        case SpendingType.creditOnly:
          value = credit;
          break;
      }

      barGroups.add(
        BarChartGroupData(
          x: month - 1,
          barRods: [
            BarChartRodData(
              toY: value,
              fromY: 0,
              color: _getColorForSpendingType(),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: minY,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              final month = months[group.x.toInt()];
              final value = rod.toY;
              final formattedValue = _formatAmount(value.abs());
              final displayValue = value >= 0 ? '₹$formattedValue' : '-₹$formattedValue';
              
              String type = '';
              switch (_spendingType) {
                case SpendingType.total:
                  type = 'Net';
                  break;
                case SpendingType.debitOnly:
                  type = 'Debit';
                  break;
                case SpendingType.creditOnly:
                  type = 'Credit';
                  break;
              }
              
              return BarTooltipItem(
                '$month\n$type: $displayValue',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${_formatAxisAmount(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                if (value.toInt() >= 0 && value.toInt() < 12) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
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
          getDrawingHorizontalLine: (value) {
            // Draw a darker line at zero for total spending view
            if (value == 0 && _spendingType == SpendingType.total && minY < 0) {
              return FlLine(
                color: Colors.grey.shade600,
                strokeWidth: 2,
                dashArray: [5, 5],
              );
            }
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
      ),
    );
  }

  // New chart for Monthly view - showing daily/weekly trends for selected month
  Widget _buildMonthlyDailyChart(Map<String, double> data) {
    if (data.isEmpty) {
      return _buildEmptyChart('No data for selected month');
    }

    final sortedKeys = data.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final value = data[sortedKeys[i]] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // Calculate proper min and max values
    if (spots.isEmpty) {
      return _buildEmptyChart('No data for selected month');
    }

    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    // Add padding to the range
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.15 : 100;
    
    maxY = maxY + padding;
    minY = minY - padding;

    // Ensure reasonable bounds
    if (maxY <= 0) maxY = 1000;
    if (minY >= 0) minY = 0;
    
    // For Total view, we might have negative values, so don't clamp minY to 0
    // For Debit/Credit only, minY should be 0
    if (_spendingType != SpendingType.total && minY < 0) {
      minY = 0;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getColorForSpendingType(),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getColorForSpendingType(),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getColorForSpendingType().withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${_formatAxisAmount(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _monthlyViewType == MonthlyViewType.daily ? 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final key = sortedKeys[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      key,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                }
                return const Text('');
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
          getDrawingHorizontalLine: (value) {
            // Draw a darker line at zero for total spending view
            if (value == 0 && _spendingType == SpendingType.total && minY < 0) {
              return FlLine(
                color: Colors.grey.shade600,
                strokeWidth: 2,
                dashArray: [5, 5],
              );
            }
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final value = spot.y;
                final formattedValue = _formatAmount(value.abs());
                final displayValue = value >= 0 ? '₹$formattedValue' : '-₹$formattedValue';
                return LineTooltipItem(
                  displayValue,
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _getColorForSpendingType() {
    switch (_spendingType) {
      case SpendingType.total:
        return AppTheme.linkPurple;
      case SpendingType.debitOnly:
        return Colors.red.shade400;
      case SpendingType.creditOnly:
        return Colors.green.shade400;
    }
  }

  String _formatMonthLabel(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMM\nyy').format(DateTime(year, month));
      }
    } catch (_) {}
    return monthKey;
  }

  String _formatAxisAmount(double value) {
    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();
    
    if (absValue >= 100000) {
      return '$sign${(absValue / 100000).toStringAsFixed(1)}L';
    } else if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  // Calculate yearly summaries - separate summary for each year
  Map<String, Map<String, dynamic>> _calculateYearlySummaries() {
    final Map<String, Map<String, dynamic>> yearlySummaries = {};

    // Group transactions by year
    final Map<String, List<SmsMessage>> transactionsByYear = {};
    for (final msg in widget.transactions) {
      final date = msg.date ?? DateTime.now();
      final yearKey = date.year.toString();
      (transactionsByYear[yearKey] ??= []).add(msg);
    }

    // Calculate summary for each year
    for (final entry in transactionsByYear.entries) {
      final year = entry.key;
      final transactions = entry.value;

      double totalDebit = 0.0;
      double totalCredit = 0.0;
      int debitCount = 0;
      int creditCount = 0;
      final Map<String, double> monthlyDebits = {};
      final Set<String> months = {};

      for (final msg in transactions) {
        final body = (msg.body ?? '').toLowerCase();
        final date = msg.date ?? DateTime.now();
        final amount = _extractAmountFromBody(msg.body ?? '');

        if (amount != null && amount > 0) {
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          months.add(monthKey);

          if (_isDebitTransaction(body)) {
            totalDebit += amount;
            debitCount++;
            monthlyDebits[monthKey] = (monthlyDebits[monthKey] ?? 0.0) + amount;
          } else if (_isCreditTransaction(body)) {
            totalCredit += amount;
            creditCount++;
          }
        }
      }

      // Find highest and lowest months
      String? highestMonth;
      double highestAmount = 0.0;
      String? lowestMonth;
      double lowestAmount = double.infinity;

      for (final entry in monthlyDebits.entries) {
        if (entry.value > highestAmount) {
          highestAmount = entry.value;
          highestMonth = entry.key;
        }
        if (entry.value < lowestAmount && entry.value > 0) {
          lowestAmount = entry.value;
          lowestMonth = entry.key;
        }
      }

      final avgPerMonth = months.isEmpty ? 0.0 : totalDebit / months.length;
      final totalTransactions = debitCount + creditCount;

      yearlySummaries[year] = {
        'totalDebit': totalDebit,
        'totalCredit': totalCredit,
        'netSpend': totalDebit - totalCredit,
        'avgPerMonth': avgPerMonth,
        'monthCount': months.length,
        'totalTransactions': totalTransactions,
        'debitCount': debitCount,
        'creditCount': creditCount,
        'debitPercent': totalTransactions > 0 ? (debitCount / totalTransactions) * 100 : 0.0,
        'creditPercent': totalTransactions > 0 ? (creditCount / totalTransactions) * 100 : 0.0,
        'highestMonth': highestMonth != null ? _formatMonthLabel(highestMonth).replaceAll('\n', ' ') : 'N/A',
        'highestAmount': highestAmount,
        'lowestMonth': lowestMonth != null ? _formatMonthLabel(lowestMonth).replaceAll('\n', ' ') : 'N/A',
        'lowestAmount': lowestAmount == double.infinity ? 0.0 : lowestAmount,
      };
    }

    // Sort by year (newest first)
    final sortedEntries = yearlySummaries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  // Helper method to check if transaction is debit
  bool _isDebitTransaction(String body) {
    return body.contains('debited') || 
           body.contains('sent') || 
           body.contains('paid') ||
           body.contains('payment') ||
           body.contains('withdrawn') ||
           body.contains('withdrawal') ||
           body.contains('transferred') ||
           body.contains('spent') ||
           body.contains('purchase') ||
           body.contains('charged') ||
           body.contains('deducted');
  }

  // Helper method to check if transaction is credit
  bool _isCreditTransaction(String body) {
    return body.contains('credited') || 
           body.contains('received') || 
           body.contains('deposited') ||
           body.contains('deposit') ||
           body.contains('refund') ||
           body.contains('refunded') ||
           body.contains('cashback');
  }

  // Calculate annual month data - for showing all 12 months in a year
  Map<int, Map<String, Map<String, double>>> _calculateAnnualMonthData() {
    final Map<int, Map<String, Map<String, double>>> annualData = {};

    for (final msg in widget.transactions) {
      final body = (msg.body ?? '').toLowerCase();
      final date = msg.date ?? DateTime.now();
      final year = date.year;
      final month = date.month;

      if (!annualData.containsKey(year)) {
        annualData[year] = {};
        // Initialize all 12 months
        for (int m = 1; m <= 12; m++) {
          annualData[year]![m.toString()] = {'debit': 0.0, 'credit': 0.0};
        }
      }

      final amount = _extractAmountFromBody(msg.body ?? '');
      if (amount != null && amount > 0) {
        final monthKey = month.toString();
        final monthData = annualData[year]![monthKey]!;

        if (_isDebitTransaction(body)) {
          monthData['debit'] = (monthData['debit'] ?? 0.0) + amount;
        } else if (_isCreditTransaction(body)) {
          monthData['credit'] = (monthData['credit'] ?? 0.0) + amount;
        }
      }
    }

    return annualData;
  }

  // Calculate monthly daily/weekly data - for showing daily trends within a month
  Map<String, double> _calculateMonthlyDailyData() {
    if (_selectedMonthForDaily == null) return {};

    final Map<String, double> dailyData = {};
    final parts = _selectedMonthForDaily!.split('-');
    
    if (parts.length != 2) return {};
    
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    
    if (year == null || month == null) return {};

    // Filter transactions for selected month
    final monthTransactions = widget.transactions.where((msg) {
      final date = msg.date;
      if (date == null) return false;
      return date.year == year && date.month == month;
    }).toList();

    if (_monthlyViewType == MonthlyViewType.daily) {
      // Group by day
      for (final msg in monthTransactions) {
        final body = (msg.body ?? '').toLowerCase();
        final date = msg.date!;
        final dayKey = date.day.toString().padLeft(2, '0');

        final amount = _extractAmountFromBody(msg.body ?? '');
        if (amount != null && amount > 0) {
          if (_spendingType == SpendingType.total) {
            if (_isDebitTransaction(body)) {
              dailyData[dayKey] = (dailyData[dayKey] ?? 0.0) + amount;
            } else if (_isCreditTransaction(body)) {
              dailyData[dayKey] = (dailyData[dayKey] ?? 0.0) - amount;
            }
          } else if (_spendingType == SpendingType.debitOnly) {
            if (_isDebitTransaction(body)) {
              dailyData[dayKey] = (dailyData[dayKey] ?? 0.0) + amount;
            }
          } else if (_spendingType == SpendingType.creditOnly) {
            if (_isCreditTransaction(body)) {
              dailyData[dayKey] = (dailyData[dayKey] ?? 0.0) + amount;
            }
          }
        }
      }
    } else {
      // Group by week
      for (final msg in monthTransactions) {
        final body = (msg.body ?? '').toLowerCase();
        final date = msg.date!;
        final weekNumber = ((date.day - 1) / 7).floor() + 1;
        final weekKey = 'W$weekNumber';

        final amount = _extractAmountFromBody(msg.body ?? '');
        if (amount != null && amount > 0) {
          if (_spendingType == SpendingType.total) {
            if (_isDebitTransaction(body)) {
              dailyData[weekKey] = (dailyData[weekKey] ?? 0.0) + amount;
            } else if (_isCreditTransaction(body)) {
              dailyData[weekKey] = (dailyData[weekKey] ?? 0.0) - amount;
            }
          } else if (_spendingType == SpendingType.debitOnly) {
            if (_isDebitTransaction(body)) {
              dailyData[weekKey] = (dailyData[weekKey] ?? 0.0) + amount;
            }
          } else if (_spendingType == SpendingType.creditOnly) {
            if (_isCreditTransaction(body)) {
              dailyData[weekKey] = (dailyData[weekKey] ?? 0.0) + amount;
            }
          }
        }
      }
    }

    return dailyData;
  }

  double? _extractAmountFromBody(String body) {
    // Comprehensive list of transaction keywords
    final transactionKeywords = [
      'debited', 'credited',
      'sent', 'received',
      'paid', 'payment',
      'paid thru', 'paid through',
      'withdrawn', 'withdrawal',
      'transferred', 'transfer',
      'deposited', 'deposit',
      'spent', 'purchase', 'purchased',
      'refund', 'refunded',
      'charged',
    ];
    
    // Build dynamic patterns
    final keywordPattern = transactionKeywords.join('|');
    
    final patterns = [
      // Pattern 1: keyword + optional "with/to/from/for" + amount
      // Examples: "debited Rs. 500", "paid to Rs 1000", "sent Rs. 250"
      RegExp(
        r'(?:' + keywordPattern + r')\s+(?:with|to|from|for|via|thru|through)?\s*(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:' + keywordPattern + r')\s+(?:with|to|from|for|via|thru|through)?\s*(?:rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 2: amount + optional "is/has been" + keyword
      // Examples: "Rs. 500 debited", "1000 is paid", "Rs 250 sent"
      RegExp(
        r'(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s+(?:is|has been|was)?\s*(?:' + keywordPattern + r')',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)\s+(?:is|has been|was)?\s*(?:' + keywordPattern + r')',
        caseSensitive: false,
      ),
      
      // Pattern 3: UPI specific patterns
      // Examples: "sent via upi Rs. 500", "received upi 1000", "paid thru upi Rs. 250"
      RegExp(
        r'(?:sent|received|paid)\s+(?:via|thru|through)?\s*(?:upi|gpay|paytm|phonepe)\s+(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s+(?:sent|received|paid)\s+(?:via|thru|through)?\s*(?:upi|gpay|paytm|phonepe)',
        caseSensitive: false,
      ),
      
      // Pattern 4: Standard Rs/INR patterns (fallback)
      RegExp(
        r'(?:rs\.?|inr|rupees?)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr|rupees?)\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 5: Amount with amount/amt keyword
      // Examples: "Amount: Rs. 500", "Amt 1000"
      RegExp(
        r'(?:amount|amt|value)[\s:]+(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:amount|amt|value)[\s:]+(?:rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 6: Transaction-specific formats
      // Examples: "of Rs. 500", "for Rs 1000"
      RegExp(
        r'(?:of|for)\s+(?:rs\.?|inr)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 7: Generic comma-separated numbers (last resort)
      RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?)\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final rawAmount = match.group(1) ?? '';
        final normalized = rawAmount.replaceAll(',', '');
        try {
          final amount = double.parse(normalized);
          // Skip unreasonably small or large amounts
          // Also skip common false positives like dates or phone numbers
          if (amount > 0 && amount < 10000000) {
            return amount;
          }
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
    IconData icon,
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
          Row(
            children: [
              Icon(icon, size: 16, color: textColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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

  Widget _buildDetailRow(String label, String value, String trailing, Color accentColor) {
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
                    color: accentColor,
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
