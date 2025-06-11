// lib/models/rate_card.dart

/// Represents a single card on the main screen, holding all its data.
class RateCard {
  final int uniqueId;
  final String title;
  final String apiSymbol; // Key to look up in the API response

  // Rate data - will be updated from the API
  String buyRate = "0.0";
  String sellRate = "0.0";
  String high = "0.0";
  String low = "0.0";

  // To track changes for color indicators
  String previousBuyRate = "0.0";
  String previousSellRate = "0.0";


  RateCard({
    required this.uniqueId,
    required this.title,
    required this.apiSymbol,
  });
}
