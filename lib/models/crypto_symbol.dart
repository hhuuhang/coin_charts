class CryptoSymbol {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  double price;
  double priceChangePercent;

  CryptoSymbol({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    this.price = 0.0,
    this.priceChangePercent = 0.0,
  });

  factory CryptoSymbol.fromJson(Map<String, dynamic> json) {
    return CryptoSymbol(
      symbol: json['symbol'],
      baseAsset: json['baseAsset'],
      quoteAsset: json['quoteAsset'],
    );
  }
}
