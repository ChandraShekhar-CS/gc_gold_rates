
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
  
  final List<Map<String, dynamic>> _cardConfigs = [
    {'title': 'Gold 995', 'uniqueId': 0, 'apiSymbol': 'gold'},
    {'title': 'Gold Future', 'uniqueId': 2, 'apiSymbol': 'goldfuture'},
    {
      'title': 'Silver Future',
      'uniqueId': 3,
      'apiSymbol': 'silverfuture',
    }, 
    {'title': 'USD / INR', 'uniqueId': 4, 'apiSymbol': 'dollarinr'},
    {'title': 'Gold / USD', 'uniqueId': 5, 'apiSymbol': 'golddollar'},
    {'title': 'Silver / USD', 'uniqueId': 6, 'apiSymbol': 'silverdollar'},
    {'title': 'Gold / Refine', 'uniqueId': 7, 'apiSymbol': 'goldrefine'},
    {'title': 'Gold / RTGS', 'uniqueId': 8, 'apiSymbol': 'goldrtgs'},
    
  ];
  RatesProvider() {
    _initializeCards();
    startAutoRefresh();
  }
  /
  void _initializeCards() async {
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
  /
  Future<void> fetchRates() async {
    if (isLoading) return;
    isLoading = true;
    
    if (rateCards.isNotEmpty && rateCards.first.buyRate == "0.0") {
      notifyListeners();
    }
    try {
      final data = await _apiService.fetchLiveRates();
      
      developer.log('API Response Data: $data', name: 'RatesProvider');
      Map<String, dynamic>? ratesData;
      
      if (data.containsKey('rates') && data['rates'] is Map<String, dynamic>) {
        ratesData = data['rates'] as Map<String, dynamic>;
      } else if (data.isNotEmpty) {
        ratesData = data;
      }
      if (ratesData != null) {
        for (var card in rateCards) {
          if (ratesData.containsKey(card.apiSymbol)) {
            final rateInfo = ratesData[card.apiSymbol];
            card.previousBuyRate = card.buyRate;
            card.previousSellRate = card.sellRate;
            if (rateInfo != null) {
              if (rateInfo is Map<String, dynamic>) {
                card.buyRate = rateInfo['buy']?.toString() ?? "0.0";
                card.sellRate = rateInfo['sell']?.toString() ?? "0.0";
                card.high = rateInfo['high']?.toString() ?? "0.0";
                card.low = rateInfo['low']?.toString() ?? "0.0";
              } else {
                final rateValue = rateInfo.toString();
                card.buyRate = rateValue;
                card.sellRate = rateValue;
                card.high = rateValue;
                card.low = rateValue;
              }
            }
          }
        }
        errorMessage = null;
      } else {
        
        throw Exception('Could not parse rates from the API response.');
      }
    } catch (e) {
      errorMessage = e.toString();
      
      developer.log(
        'Error fetching rates: $e',
        name: 'RatesProvider',
        error: e,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  /
  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchRates();
    });
  }
  /
  void reorderCards(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final RateCard item = rateCards.removeAt(oldIndex);
    rateCards.insert(newIndex, item);
    final prefs = await SharedPreferences.getInstance();
    List<String> newOrderIds = rateCards
        .map((c) => c.uniqueId.toString())
        .toList();
    await prefs.setStringList('cardOrder', newOrderIds);
    notifyListeners();
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
