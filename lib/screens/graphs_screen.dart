import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class GraphsScreen extends StatefulWidget {
  final int initialSeriesIndex;
  const GraphsScreen({super.key, this.initialSeriesIndex = 0});
  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

enum TimeRange { day, week, month, year, custom }

class _GraphsScreenState extends State<GraphsScreen> {
  bool _isLoading = true;
  String? _error;
  ApiResponse? _apiResponse;
  late String _selectedSeries;
  bool _isBuySelected = true;
  TimeRange _selectedTimeRange = TimeRange.day;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final ApiService _apiService = ApiService();
  final List<String> _seriesOptions = const [
    "gold",
    "silver",
    "goldfuture",
    "silverfuture",
    "dollarinr",
    "golddollar",
    "silverdollar",
    "goldrefine",
    "goldrtgs",
  ];
  @override
  void initState() {
    super.initState();
    _selectedSeries = _seriesOptions[widget.initialSeriesIndex];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final queryParams = _buildApiQuery();
      final data = await _apiService.fetchGraphData(
        _selectedSeries,
        queryParams,
      );
      setState(() {
        _apiResponse = ApiResponse.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _buildApiQuery() {
    final sdf = DateFormat('yyyy-MM-dd');
    String startDate, endDate, resolution;
    if (_selectedTimeRange == TimeRange.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      startDate = sdf.format(_customStartDate!);
      endDate = sdf.format(_customEndDate!);
      resolution = 'hour';
    } else {
      final now = DateTime.now();
      endDate = sdf.format(now);
      DateTime startDateTime;
      switch (_selectedTimeRange) {
        case TimeRange.day:
          startDateTime = now.subtract(const Duration(days: 1));
          resolution = '15min';
          break;
        case TimeRange.week:
          startDateTime = now.subtract(const Duration(days: 7));
          resolution = 'hour';
          break;
        case TimeRange.month:
          startDateTime = now.subtract(const Duration(days: 30));
          resolution = '4hour';
          break;
        case TimeRange.year:
          startDateTime = now.subtract(const Duration(days: 365));
          resolution = 'week';
          break;
        case TimeRange.custom:
          startDateTime = now.subtract(const Duration(days: 7));
          resolution = 'hour';
          break;
      }
      startDate = sdf.format(startDateTime);
    }
    return '?startDate=$startDate&endDate=$endDate&resolution=$resolution';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Trends Graph')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _buildSeriesSelector(),
          const SizedBox(height: 12),
          _buildBuySellToggle(),
          const SizedBox(height: 12),
          _buildTimeRangeToggle(),
          const SizedBox(height: 16),
          _buildHighLowDisplay(),
          const SizedBox(height: 16),
          _buildChartContainer(),
        ],
      ),
    );
  }

  Widget _buildSeriesSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedSeries,
      decoration: const InputDecoration(
        labelText: 'Select Commodity',
        border: OutlineInputBorder(),
      ),
      items: _seriesOptions.map((series) {
        return DropdownMenuItem(
          value: series,
          child: Text(series.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedSeries = value);
          _fetchData();
        }
      },
    );
  }

  Widget _buildBuySellToggle() {
    return Center(
      child: ToggleButtons(
        isSelected: [_isBuySelected, !_isBuySelected],
        onPressed: (index) {
          setState(() => _isBuySelected = index == 0);
        },
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
        children: const [Text('BUY'), Text('SELL')],
      ),
    );
  }

  Widget _buildTimeRangeToggle() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ToggleButtons(
          isSelected: TimeRange.values
              .map((range) => _selectedTimeRange == range)
              .toList(),
          onPressed: (index) {
            final selectedRange = TimeRange.values[index];
            if (selectedRange == TimeRange.custom) {
              _showCustomDatePicker();
            } else {
              setState(() => _selectedTimeRange = selectedRange);
              _fetchData();
            }
          },
          borderRadius: BorderRadius.circular(8),
          children: TimeRange.values
              .map(
                (range) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(range.name.toUpperCase()),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showCustomDatePicker() async {
    final now = DateTime.now();
    final pickedStartDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now.subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (pickedStartDate == null) return;
    final pickedEndDate = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? now,
      firstDate: pickedStartDate,
      lastDate: now,
    );
    if (pickedEndDate == null) return;
    setState(() {
      _selectedTimeRange = TimeRange.custom;
      _customStartDate = pickedStartDate;
      _customEndDate = pickedEndDate;
    });
    _fetchData();
  }

  Widget _buildHighLowDisplay() {
    if (_apiResponse?.stats == null) return const SizedBox.shrink();
    final stats = _apiResponse!.stats!;
    final price = _isBuySelected ? stats.buy : stats.sell;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          'Lowest: ${formatter.format(price.low)}',
          style: const TextStyle(color: Colors.red),
        ),
        Text(
          'Highest: ${formatter.format(price.high)}',
          style: const TextStyle(color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildChartContainer() {
    return SizedBox(
      height: 300,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _apiResponse == null || _apiResponse!.data.isEmpty
          ? const Center(child: Text('No data available for this range.'))
          : LineChart(_buildChartData()),
    );
  }

  LineChartData _buildChartData() {
    List<FlSpot> spots = [];
    if (_apiResponse == null) return LineChartData();
    for (var i = 0; i < _apiResponse!.data.length; i++) {
      final dataItem = _apiResponse!.data[i];
      final value = _isBuySelected ? dataItem.buy : dataItem.sell;
      spots.add(FlSpot(i.toDouble(), value));
    }
    if (spots.isEmpty) return LineChartData();
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (spots.length / 4).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _apiResponse!.data.length) {
                return const SizedBox();
              }
              final date = _apiResponse!.data[index].createdAt;
              String label = (_selectedTimeRange == TimeRange.day)
                  ? DateFormat.jm().format(date)
                  : DateFormat('dd/MM').format(date);
              return SideTitleWidget(
                meta: meta,
                child: Text(label, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ApiResponse {
  final List<DataItem> data;
  final Stats? stats;
  ApiResponse({required this.data, this.stats});
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => DataItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      stats: json['stats'] != null
          ? Stats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DataItem {
  final double buy;
  final double sell;
  final DateTime createdAt;
  DataItem({required this.buy, required this.sell, required this.createdAt});
  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
      buy: (json['buy'] as num).toDouble(),
      sell: (json['sell'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Stats {
  final Price buy;
  final Price sell;
  Stats({required this.buy, required this.sell});
  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      buy: Price.fromJson(json['buy']),
      sell: Price.fromJson(json['sell']),
    );
  }
}

class Price {
  final double high;
  final double low;
  Price({required this.high, required this.low});
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
    );
  }
}
