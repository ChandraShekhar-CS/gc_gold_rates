class RateCard {
  final int uniqueId;
  final String title;
  final String apiSymbol;
  String buyRate = "0.0";
  String sellRate = "0.0";
  String high = "0.0";
  String low = "0.0";
  String previousBuyRate = "0.0";
  String previousSellRate = "0.0";
  RateCard({
    required this.uniqueId,
    required this.title,
    required this.apiSymbol,
  });
}
