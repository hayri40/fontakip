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
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  State<EnhancedFundHistoryChart> createState() =>
      _EnhancedFundHistoryChartState();
}

class _EnhancedFundHistoryChartState extends State<EnhancedFundHistoryChart> {
  late String _selectedPeriod;
  late List<HistoryPoint> _filteredHistory;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = '1Y';
    _filterDataByPeriod();
  }

  @override
  void didUpdateWidget(EnhancedFundHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _filterDataByPeriod();
    }
  }

  void _filterDataByPeriod() {
    if (widget.history.isEmpty) {
      _filteredHistory = [];
      return;
    }

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedPeriod) {
      case '1A':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3A':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case '6A':
        cutoffDate = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case '3Y':
        cutoffDate = now.subtract(const Duration(days: 1095));
        break;
      case 'Tümü':
        cutoffDate = DateTime(1970);
        break;
      default:
        cutoffDate = now.subtract(const Duration(days: 365));
    }

    _filteredHistory = widget.history
        .where((point) => point.date.isAfter(cutoffDate))
        .toList();

    // Sort by date ascending for chart
    _filteredHistory.sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final chartHeight = MediaQuery.of(context).size.height * 0.38;

    if (widget.isLoading) {
      return _buildLoadingSkeleton(isMobile, chartHeight);
    }

    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (_filteredHistory.isEmpty) {
      return _buildEmptyWidget();
    }

    final minPrice =
        _filteredHistory.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        _filteredHistory.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final lastPrice = _filteredHistory.last.price;
    final firstPrice = _filteredHistory.first.price;
    final priceChange = lastPrice - firstPrice;
    final percentageChange = (priceChange / firstPrice) * 100;

    // High and low prices
    final highPrice = maxPrice;
    final lowPrice = minPrice;

    return Column(
      children: [
        // Time period selector
        _buildTimePeriodSelector(isMobile),
        const SizedBox(height: 16),
        // Chart card
        Card(
          elevation: 8,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.cyan,
              width: 0.5,
            ),
          ),
          color: const Color(0xFF1a1a2e),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price header
                _buildPriceHeader(lastPrice, percentageChange, highPrice,
                    lowPrice, isMobile),
                const SizedBox(height: 24),
                // Chart
                SizedBox(
                  height: chartHeight,
                  child: _buildChart(minPrice, maxPrice, lastPrice),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector(bool isMobile) {
    final periods = ['1A', '3A', '6A', '1Y', '3Y', 'Tümü'];
    final buttonSize = isMobile ? 36.0 : 40.0;
    final fontSize = isMobile ? 10.0 : 11.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                    _filterDataByPeriod();
                  });
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.cyan
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.cyan
                          : Colors.grey[700]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.black
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriceHeader(double lastPrice, double percentageChange,
      double highPrice, double lowPrice, bool isMobile) {
    final priceColor = percentageChange >= 0 ? Colors.green : Colors.red;
    final priceIcon =
        percentageChange >= 0 ? Icons.trending_up : Icons.trending_down;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.currencyValue(lastPrice),
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(priceIcon, color: priceColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.signedPercentValue(percentageChange),
                      style: TextStyle(
                        fontSize: 14,
                        color: priceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // High/Low display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        'H: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        AppFormatters.currencyValue(highPrice),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'L: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        AppFormatters.currencyValue(lowPrice),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(double minPrice, double maxPrice, double lastPrice) {
    if (_filteredHistory.length < 2) {
      return Center(
        child: Text(
          'Insufficient data for chart',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    // Create FlSpot list
    final spots = List<FlSpot>.generate(
      _filteredHistory.length,
      (index) => FlSpot(
        index.toDouble(),
        _filteredHistory[index].price,
      ),
    );

    // Margin for padding
    const leftChartMargin = 60.0;
    const bottomChartMargin = 40.0;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Colors.cyan,
            dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight last point
                if (index == spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.cyan,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.cyan.withOpacity(0.15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.cyan.withOpacity(0.15),
                  Colors.cyan.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: (maxPrice - minPrice) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[800]!,
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftChartMargin,
              getTitlesWidget: (value, meta) {
                return Text(
                  AppFormatters.currencyValue(value),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: bottomChartMargin,
              interval: (_filteredHistory.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _filteredHistory.length) {
                  return const SizedBox();
                }
                final date = _filteredHistory[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey[800]!, width: 1),
            bottom: BorderSide(color: Colors.grey[800]!, width: 1),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
          ),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minPrice - (maxPrice - minPrice) * 0.1,
        maxY: maxPrice + (maxPrice - minPrice) * 0.1,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = _filteredHistory[spot.x.toInt()].date;
                return LineTooltipItem(
                  '${AppFormatters.currencyValue(spot.y)}\n${date.day}/${date.month}/${date.year}',
                  TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isMobile, double chartHeight) {
    return Column(
      children: [
        // Period buttons skeleton
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: isMobile ? 36 : 44,
                    height: isMobile ? 36 : 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Chart skeleton
        Card(
          elevation: 8,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF1a1a2e),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price skeleton
                Container(
                  width: 150,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                // Chart area skeleton
                Container(
                  height: chartHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      color: const Color(0xFF1a1a2e),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              widget.errorMessage ?? 'Error loading chart',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[300]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      color: const Color(0xFF1a1a2e),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No data available for this period',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
