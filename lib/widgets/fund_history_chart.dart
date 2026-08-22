import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/formatters/app_formatters.dart';
import '../models/history_point.dart';

class EnhancedFundHistoryChart extends StatefulWidget {
  final List<HistoryPoint> history;
  final bool isLoading;
  final String? errorMessage;

  const EnhancedFundHistoryChart({
    super.key,
    required this.history,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<EnhancedFundHistoryChart> createState() =>
      _EnhancedFundHistoryChartState();
}

class _EnhancedFundHistoryChartState extends State<EnhancedFundHistoryChart> {
  late String _selectedPeriod = '1Y';
  late List<HistoryPoint> _filteredHistory;

  @override
  void initState() {
    super.initState();
    _updateFilteredHistory();
  }

  @override
  void didUpdateWidget(EnhancedFundHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _updateFilteredHistory();
    }
  }

  void _updateFilteredHistory() {
    final now = DateTime.now();
    final data = widget.history;

    List<HistoryPoint> filtered;

    switch (_selectedPeriod) {
      case '1D':
        filtered = data
            .where((p) => p.date.isAfter(now.subtract(const Duration(days: 1))))
            .toList();
        break;
      case '3D':
        filtered = data
            .where((p) => p.date.isAfter(now.subtract(const Duration(days: 3))))
            .toList();
        break;
      case '6D':
        filtered = data
            .where((p) => p.date.isAfter(now.subtract(const Duration(days: 6))))
            .toList();
        break;
      case '1Y':
        filtered = data
            .where((p) =>
                p.date.isAfter(now.subtract(const Duration(days: 365))))
            .toList();
        break;
      case 'All':
        filtered = data;
        break;
      default:
        filtered = data;
    }

    setState(() {
      _filteredHistory = filtered;
    });
  }

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _updateFilteredHistory();
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.history.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 16),
        _buildChartCard(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['1D', '3D', '6D', '1Y', 'All']
              .map((period) => _buildPeriodButton(period))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isActive = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _setPeriod(period),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive ? Colors.cyan : const Color(0xFF2A2D34),
          foregroundColor: isActive ? Colors.black : Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isActive ? Colors.cyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    if (_filteredHistory.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFF1A1D24),
        elevation: 8,
        child: SizedBox(
          height: 400,
          child: const Center(
            child: Text(
              'No data available for this period',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final minPrice =
        _filteredHistory.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        _filteredHistory.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final lastPrice = _filteredHistory.last.price;
    final firstPrice = _filteredHistory.first.price;
    final changePercent = ((lastPrice - firstPrice) / firstPrice) * 100;
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.15;

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Price Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.currencyValue(lastPrice),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.signedPercentValue(changePercent),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: changePercent >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'H: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          AppFormatters.currencyValue(maxPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'L: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          AppFormatters.currencyValue(minPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart
            SizedBox(
              height: 400,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxPrice - minPrice) / 5,
                    verticalInterval: _filteredHistory.length > 1
                        ? (_filteredHistory.length - 1) / 5
                        : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.08),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (_filteredHistory.length - 1) / 4,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= _filteredHistory.length) {
                            return const Text('');
                          }
                          final date =
                              _filteredHistory[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatDate(date),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        interval: (maxPrice - minPrice) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            AppFormatters.currencyValue(value),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (_filteredHistory.length - 1).toDouble(),
                  minY: minPrice - padding,
                  maxY: maxPrice + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _filteredHistory.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          _filteredHistory[index].price,
                        ),
                      ),
                      isCurved: true,
                      color: Colors.cyan,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isLastPoint =
                              index == _filteredHistory.length - 1;
                          return FlDotCirclePainter(
                            radius: isLastPoint ? 6 : 3,
                            color: Colors.cyan,
                            strokeWidth: isLastPoint ? 3 : 2,
                            strokeColor: isLastPoint
                                ? Colors.white
                                : Colors.transparent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.cyan.withOpacity(0.15),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    enabled: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 8,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyan),
              SizedBox(height: 16),
              Text(
                'Loading chart...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 8,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorMessage ?? 'Error loading chart',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 8,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: const Center(
          child: Text(
            'No history data available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
