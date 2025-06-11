// lib/providers/rates_provider.dart
import 'dart:async';
import 'dart:developer' as developer; // Import for logging
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/rate_card.dart';
import '../services/api_service.dart';


// --- WIDGET HELPER FUNCTION ---
// This function formats the data and sends it to the native home screen widget.
void updateHomeWidget(RateCard? goldCard, RateCard? silverCard) {
  // Format the current time
  final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  // Save all the data we need for the new widget design
  HomeWidget.saveWidgetData<String>('gold_rate', "₹ ${goldCard?.buyRate ?? '...'}");
  HomeWidget.saveWidgetData<String>('silver_rate', "₹ ${silverCard?.buyRate ?? '...'}");
  HomeWidget.saveWidgetData<String>('widget_timestamp', formattedTime);

  // Trigger the widget update
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

  // Defines the configuration for each card, including the key for API lookups.
  final List<Map<String, dynamic>> _cardConfigs = [
    {'title': 'Gold 995', 'uniqueId': 0, 'apiSymbol': 'gold'},
    {'title': 'Gold Future', 'uniqueId': 2, 'apiSymbol': 'goldfuture'},
    {'title': 'Silver Future', 'uniqueId': 3, 'apiSymbol': 'silverfuture'}, // This will be used for the widget
    {'title': 'USD / INR', 'uniqueId': 4, 'apiSymbol': 'dollarinr'},
    {'title': 'Gold / USD', 'uniqueId': 5, 'apiSymbol': 'golddollar'},
    {'title': 'Silver / USD', 'uniqueId': 6, 'apiSymbol': 'silverdollar'},
    {'title': 'Gold / Refiner', 'uniqueId': 7, 'apiSymbol': 'goldrefine'},
    {'title': 'Gold / RTGS', 'uniqueId': 8, 'apiSymbol': 'goldrtgs'},
    // Add other cards as needed, matching the symbols from the live API response
  ];

  RatesProvider() {
    _initializeCards();
    startAutoRefresh();
  }

  /// Sets up the initial list of cards based on saved order or default.
  void _initializeCards() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedOrderIds = prefs.getStringList('cardOrder');

    // Use saved order, or default to the config order
    List<int> order =
        savedOrderIds?.map(int.parse).toList() ??
        _cardConfigs.map<int>((c) => c['uniqueId']).toList();

    Map<int, Map<String, dynamic>> configMap = {
      for (var c in _cardConfigs) c['uniqueId']: c,
    };

    // Create the list of RateCard objects in the correct order
    rateCards = order
        .map(
          (id) => RateCard(
            uniqueId: id,
            title: configMap[id]!['title'],
            apiSymbol: configMap[id]!['apiSymbol'],
          ),
        )
        .toList();

    await fetchRates(); // Initial fetch
  }

  /// Fetches the latest rates and updates the cards.
  Future<void> fetchRates() async {
    if (isLoading) return;
    isLoading = true;

    // Only show the loading spinner on the very first load.
    if (rateCards.isNotEmpty && rateCards.first.buyRate == "0.0") {
      notifyListeners();
    }

    try {
      final data = await _apiService.fetchLiveRates();

      // DEBUG: Print the raw API response to the console to see its structure.
      developer.log('API Response Data: $data', name: 'RatesProvider');

      Map<String, dynamic>? ratesData;

      // New parsing logic:
      if (data.containsKey('rates') && data['rates'] is Map<String, dynamic>) {
        ratesData = data['rates'] as Map<String, dynamic>;
      }
      else if (data.isNotEmpty) {
        ratesData = data;
      }

      if (ratesData != null) {
        // --- ADDED FOR WIDGET ---
        // Variables to hold the specific cards for the widget
        RateCard? goldCardForWidget;
        RateCard? silverCardForWidget;
        // -------------------------

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
            
            // --- ADDED FOR WIDGET ---
            // Find the cards for Gold and Silver to send their data to the widget
            if (card.apiSymbol == 'gold') {
              goldCardForWidget = card;
            }
            if (card.apiSymbol == 'silverfuture') {
               silverCardForWidget = card;
            }
            // -------------------------
          }
        }
        errorMessage = null;

        // --- ADDED FOR WIDGET ---
        // After successfully updating all cards, send data to the home widget
        updateHomeWidget(goldCardForWidget, silverCardForWidget);
        // -------------------------

      } else {
        // If we still can't find any rate data, throw a specific error.
        throw Exception('Could not parse rates from the API response.');
      }
    } catch (e) {
      errorMessage = e.toString();
      // DEBUG: Print any error that occurs during the process.
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

  /// Starts a periodic timer to auto-refresh rates.
  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchRates();
    });
  }

  /// Reorders the cards in the list and saves the new order.
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