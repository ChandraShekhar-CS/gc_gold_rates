import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/rate_card.dart';
import '../services/api_service.dart';

void updateHomeWidget(RateCard? goldCard, RateCard? silverCard) {
  final formattedTime = DateFormat('hh:mm a').format(DateTime.now());
  HomeWidget.saveWidgetData<String>(
    'gold_rate',
    "₹ ${goldCard?.buyRate ?? '...'}",
  );
  HomeWidget.saveWidgetData<String>(
    'silver_rate',
    "₹ ${silverCard?.buyRate ?? '...'}",
  );
  HomeWidget.saveWidgetData<String>('widget_timestamp', formattedTime);
  HomeWidget.updateWidget(
    name: 'RatesWidgetProvider',
    androidName: 'RatesWidgetProvider',
    iOSName: 'RatesWidget',
  );
}

class RatesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<RateCard> rateCards = [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _timer;
  bool _isInitialized = false;
  bool _disposed = false;

  final List<Map<String, dynamic>> _cardConfigs = [
    {'title': 'Gold 995', 'uniqueId': 0, 'apiSymbol': 'gold'},
    {'title': 'Gold Future', 'uniqueId': 2, 'apiSymbol': 'goldfuture'},
    {'title': 'Silver Future', 'uniqueId': 3, 'apiSymbol': 'silverfuture'},
    {'title': 'USD / INR', 'uniqueId': 4, 'apiSymbol': 'dollarinr'},
    {'title': 'Gold / USD', 'uniqueId': 5, 'apiSymbol': 'golddollar'},
    {'title': 'Silver / USD', 'uniqueId': 6, 'apiSymbol': 'silverdollar'},
    {'title': 'Gold / Refine', 'uniqueId': 7, 'apiSymbol': 'goldrefine'},
    {'title': 'Gold / RTGS', 'uniqueId': 8, 'apiSymbol': 'goldrtgs'},
  ];

  RatesProvider();

  Future<void> initializeAndFetch() async {
    if (_isInitialized || _disposed) return;

    try {
      await _initializeCards();
      startAutoRefresh();
      _isInitialized = true;
    } catch (e) {
      developer.log(
        'Error during initialization: $e',
        name: 'RatesProvider',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> _initializeCards() async {
    if (_disposed) return;

    final prefs = await SharedPreferences.getInstance();
    List<String>? savedOrderIds = prefs.getStringList('cardOrder');
    List<int> order =
        savedOrderIds?.map(int.parse).toList() ??
        _cardConfigs.map<int>((c) => c['uniqueId']).toList();

    Map<int, Map<String, dynamic>> configMap = {
      for (var c in _cardConfigs) c['uniqueId']: c,
    };

    rateCards = order
        .map(
          (id) => RateCard(
            uniqueId: id,
            title: configMap[id]!['title'],
            apiSymbol: configMap[id]!['apiSymbol'],
          ),
        )
        .toList();

    await fetchRates();
  }

  Future<void> fetchRates() async {
    if (isLoading || _disposed) return;

    isLoading = true;
    if (rateCards.isNotEmpty &&
        rateCards.first.buyRate == "0.0" &&
        !_disposed) {
      notifyListeners();
    }

    try {
      final data = await _apiService.fetchLiveRates();
      if (_disposed) return;

      Map<String, dynamic>? ratesData;
      if (data.containsKey('rates') && data['rates'] is Map<String, dynamic>) {
        ratesData = data['rates'] as Map<String, dynamic>;
      } else if (data.isNotEmpty) {
        ratesData = data;
      }

      if (ratesData != null && !_disposed) {
        for (var card in rateCards) {
          if (ratesData.containsKey(card.apiSymbol)) {
            final rateInfo = ratesData[card.apiSymbol];
            card.previousBuyRate = card.buyRate;
            card.previousSellRate = card.sellRate;

            if (rateInfo != null) {
              if (rateInfo is Map<String, dynamic>) {
                card.buyRate = rateInfo['buy']?.toString() ?? "0.0";
                card.sellRate = rateInfo['sell']?.toString() ?? "0.0";
                
                if (rateInfo['high'] is Map<String, dynamic>) {
                  final highData = rateInfo['high'] as Map<String, dynamic>;
                  card.buyHigh = highData['buy']?.toString() ?? "0.0";
                  card.sellHigh = highData['sell']?.toString() ?? "0.0";
                } else {
                  card.buyHigh = rateInfo['high']?.toString() ?? "0.0";
                  card.sellHigh = rateInfo['high']?.toString() ?? "0.0";
                }
                
                if (rateInfo['low'] is Map<String, dynamic>) {
                  final lowData = rateInfo['low'] as Map<String, dynamic>;
                  card.buyLow = lowData['buy']?.toString() ?? "0.0";
                  card.sellLow = lowData['sell']?.toString() ?? "0.0";
                } else {
                  card.buyLow = rateInfo['low']?.toString() ?? "0.0";
                  card.sellLow = rateInfo['low']?.toString() ?? "0.0";
                }
              } else {
                final rateValue = rateInfo.toString();
                card.buyRate = rateValue;
                card.sellRate = rateValue;
                card.buyHigh = rateValue;
                card.sellHigh = rateValue;
                card.buyLow = rateValue;
                card.sellLow = rateValue;
              }
            }
          }
        }
        errorMessage = null;

        final goldCard = rateCards
            .where((card) => card.apiSymbol == 'gold')
            .firstOrNull;
        final silverCard = rateCards
            .where((card) => card.apiSymbol == 'silverfuture')
            .firstOrNull;
        updateHomeWidget(goldCard, silverCard);
      } else if (!_disposed) {
        throw Exception('Could not parse rates from the API response.');
      }
    } catch (e) {
      if (!_disposed) {
        errorMessage = e.toString();
        developer.log(
          'Error fetching rates: $e',
          name: 'RatesProvider',
          error: e,
        );
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void startAutoRefresh() {
    if (_disposed) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_disposed) {
        fetchRates();
      } else {
        timer.cancel();
      }
    });
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> reorderCards(int oldIndex, int newIndex) async {
    if (_disposed) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final RateCard item = rateCards.removeAt(oldIndex);
    rateCards.insert(newIndex, item);

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> newOrderIds = rateCards
          .map((c) => c.uniqueId.toString())
          .toList();
      await prefs.setStringList('cardOrder', newOrderIds);

      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        'Error saving card order: $e',
        name: 'RatesProvider',
        error: e,
      );
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}