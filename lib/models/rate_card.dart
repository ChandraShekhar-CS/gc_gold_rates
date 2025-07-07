class RateCard {
  final int uniqueId;
  final String title;
  final String apiSymbol;
  String buyRate = "0.0";
  String sellRate = "0.0";
  String buyHigh = "0.0";
  String buyLow = "0.0";
  String sellHigh = "0.0";
  String sellLow = "0.0";
  String previousBuyRate = "0.0";
  String previousSellRate = "0.0";
  RateCard({
    required this.uniqueId,
    required this.title,
    required this.apiSymbol,
  });
}