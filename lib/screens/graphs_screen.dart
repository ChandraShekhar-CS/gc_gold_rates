import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

const Map<String, int> _seriesIndexMap = {
  'golddollar': 0,
  'silverdollar': 1,
  'dollarinr': 2,
  'goldfuture': 3,
  'silverfuture': 4,
  'gold': 5,
  'goldrefine': 6,
  'goldrtgs': 7,
};

class GraphsScreen extends StatefulWidget {
  final String? initialSeriesSymbol;
  const GraphsScreen({super.key, this.initialSeriesSymbol});
  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

enum TimeRange { day, week, month, year, custom }

class _ChartData {
  _ChartData(this.x, this.y);
  final DateTime x;
  final double y;
}

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
  late ZoomPanBehavior _zoomPanBehavior;
  final List<String> _seriesOptions = const [
    "gold",
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
    _selectedSeries = widget.initialSeriesSymbol ?? _seriesOptions[0];
    if (!_seriesOptions.contains(_selectedSeries)) {
      _selectedSeries = _seriesOptions[0];
    }
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: false,
      enableSelectionZooming: false,
      enableMouseWheelZooming: true,
      enableDoubleTapZooming: true,
    );
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
        _apiResponse = ApiResponse.fromJson(data, _selectedSeries);
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      developer.log(
        'Error in _fetchData: $e',
        name: 'GraphsScreen',
        error: e,
        stackTrace: stacktrace,
      );
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSeriesSelector(),
          const SizedBox(height: 16),
          _buildBuySellToggle(),
          const SizedBox(height: 16),
          _buildTimeRangeToggle(),
          const SizedBox(height: 20),
          _buildHighLowDisplay(),
          const SizedBox(height: 8),
          _buildChartContainer(),
        ],
      ),
    );
  }

  Widget _buildSeriesSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedSeries,
      decoration: InputDecoration(
        labelText: 'Select Commodity',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
    final theme = Theme.of(context);
    return Center(
      child: ToggleButtons(
        isSelected: [_isBuySelected, !_isBuySelected],
        onPressed: (index) {
          if ((index == 0 && !_isBuySelected) ||
              (index == 1 && _isBuySelected)) {
            setState(() => _isBuySelected = index == 0);
          }
        },
        borderRadius: BorderRadius.circular(12),
        selectedBorderColor: theme.colorScheme.primary,
        selectedColor: theme.colorScheme.onPrimary,
        fillColor: theme.colorScheme.primary,
        color: theme.colorScheme.onSurface,
        constraints: const BoxConstraints(minHeight: 44.0, minWidth: 120.0),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up),
                SizedBox(width: 8),
                Text('BUY'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_down),
                SizedBox(width: 8),
                Text('SELL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeToggle() {
    final theme = Theme.of(context);
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
          borderRadius: BorderRadius.circular(12),
          selectedBorderColor: theme.colorScheme.primary,
          selectedColor: theme.colorScheme.onPrimary,
          fillColor: theme.colorScheme.primary.withOpacity(0.8),
          color: theme.colorScheme.onSurface,
          constraints: const BoxConstraints(minHeight: 40.0),
          children: TimeRange.values
              .map(
                (range) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
      _customEndDate = pickedEndDate.add(const Duration(days: 1));
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
        _buildStatPill('Lowest', formatter.format(price.low), Colors.red),
        _buildStatPill('Highest', formatter.format(price.high), Colors.green),
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: textTheme.labelMedium?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
        child: SizedBox(
          height: 320,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'An error occurred:\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                )
              : _getChartData().isEmpty
              ? const Center(child: Text('No data available for this range.'))
              : _buildChart(),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        dateFormat: _getDateFormat(),
        intervalType: _getIntervalType(),
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compactCurrency(
          locale: 'en_IN',
          symbol: '₹',
        ),
        majorGridLines: const MajorGridLines(width: 0.5),
      ),
      series: <LineSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          dataSource: _getChartData(),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: _selectedSeries.toUpperCase(),
          color: Theme.of(context).colorScheme.primary,
          width: 2.5,
        ),
      ],
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        lineColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        lineWidth: 2,
        markerSettings: const TrackballMarkerSettings(
          markerVisibility: TrackballVisibilityMode.visible,
          height: 8,
          width: 8,
          borderWidth: 2,
        ),
        tooltipSettings: const InteractiveTooltip(
          enable: false,
        ),
        builder: (BuildContext context, TrackballDetails trackballDetails) {
          final point = trackballDetails.point;

          if (point == null || point.y == null) {
            return const SizedBox.shrink();
          }

          final currencyFormatter = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 2,
          );
          final String formattedRate = currencyFormatter.format(point.y);
          final String formattedDate =
              DateFormat('dd MMM, hh:mm a').format(point.x as DateTime);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedRate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      onTrackballPositionChanging: (TrackballArgs args) {
        args.chartPointInfo.header = '';
      },
    );
  }

  List<_ChartData> _getChartData() {
    if (_apiResponse == null) return [];
    final data = <_ChartData>[];
    for (final dataItem in _apiResponse!.data) {
      final value = _isBuySelected ? dataItem.buy : dataItem.sell;
      if (value > 0) {
        data.add(_ChartData(dataItem.createdAt, value));
      }
    }
    return data;
  }

  DateFormat _getDateFormat() {
    switch (_selectedTimeRange) {
      case TimeRange.day:
        return DateFormat.jm();
      case TimeRange.week:
      case TimeRange.month:
      case TimeRange.custom:
        return DateFormat('dd/MM');
      case TimeRange.year:
        return DateFormat('MMM yy');
    }
  }

  DateTimeIntervalType _getIntervalType() {
    switch (_selectedTimeRange) {
      case TimeRange.day:
        return DateTimeIntervalType.hours;
      case TimeRange.week:
        return DateTimeIntervalType.days;
      case TimeRange.month:
        return DateTimeIntervalType.days;
      case TimeRange.year:
        return DateTimeIntervalType.months;
      case TimeRange.custom:
        return DateTimeIntervalType.auto;
    }
  }
}

class ApiResponse {
  final List<DataItem> data;
  final Stats? stats;
  ApiResponse({required this.data, this.stats});
  factory ApiResponse.fromJson(Map<String, dynamic> json, String series) {
    Stats? seriesStats;
    if (json['stats'] != null &&
        json['stats'] is Map<String, dynamic> &&
        (json['stats'] as Map<String, dynamic>)[series] != null) {
      seriesStats = Stats.fromJson(
        (json['stats'] as Map<String, dynamic>)[series] as Map<String, dynamic>,
      );
    }
    List<DataItem> parsedData = [];
    if (json['data'] is List) {
      parsedData = (json['data'] as List<dynamic>)
          .map(
            (item) => DataItem.fromJson(item as Map<String, dynamic>, series),
          )
          .toList();
    }
    parsedData.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ApiResponse(data: parsedData, stats: seriesStats);
  }
}

class DataItem {
  final double buy;
  final double sell;
  final DateTime createdAt;
  DataItem({required this.buy, required this.sell, required this.createdAt});
  factory DataItem.fromJson(Map<String, dynamic> json, String series) {
    double buy = 0.0;
    double sell = 0.0;
    if (json['data'] is String) {
      try {
        final List<dynamic> allSeriesData = jsonDecode(json['data']);
        final int? seriesIndex = _seriesIndexMap[series];
        if (seriesIndex != null && seriesIndex < allSeriesData.length) {
          final List<dynamic> specificSeriesData = allSeriesData[seriesIndex];
          if (specificSeriesData.length > 1) {
            buy = double.tryParse(specificSeriesData[0].toString()) ?? 0.0;
            sell = double.tryParse(specificSeriesData[1].toString()) ?? 0.0;
          }
        }
      } catch (e) {
        developer.log(
          'Error decoding DataItem data string: ${json['data']}',
          name: 'DataItem',
          error: e,
        );
      }
    }
    return DataItem(
      buy: buy,
      sell: sell,
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
      buy: json['buy'] != null
          ? Price.fromJson(json['buy'] as Map<String, dynamic>)
          : Price(high: 0, low: 0),
      sell: json['sell'] != null
          ? Price.fromJson(json['sell'] as Map<String, dynamic>)
          : Price(high: 0, low: 0),
    );
  }
}

class Price {
  final double high;
  final double low;
  Price({required this.high, required this.low});
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
    );
  }
}