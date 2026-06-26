import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:candlesticks/candlesticks.dart';
import '../models/crypto_symbol.dart';

class BinanceApiService {
  static const String baseUrl = 'https://api.binance.com/api/v3';

  // Fetch Exchange Info (Symbols)
  Future<List<CryptoSymbol>> fetchSymbols() async {
    final response = await http.get(Uri.parse('$baseUrl/exchangeInfo'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final symbols = (data['symbols'] as List)
          .where((s) => s['quoteAsset'] == 'USDT' && s['status'] == 'TRADING')
          .map((s) => CryptoSymbol.fromJson(s))
          .toList();
      return symbols;
    } else {
      throw Exception('Failed to load symbols');
    }
  }

  // Fetch 24hr Ticker Price Change Statistics
  Future<Map<String, dynamic>> fetch24hTicker() async {
    final response = await http.get(Uri.parse('$baseUrl/ticker/24hr'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      Map<String, dynamic> tickerMap = {};
      for (var item in data) {
        tickerMap[item['symbol']] = {
          'price': double.tryParse(item['lastPrice'] ?? '0.0') ?? 0.0,
          'priceChangePercent': double.tryParse(item['priceChangePercent'] ?? '0.0') ?? 0.0,
          'volume': double.tryParse(item['quoteVolume'] ?? '0.0') ?? 0.0, // volume in USDT
        };
      }
      return tickerMap;
    } else {
      throw Exception('Failed to load ticker data');
    }
  }

  // Fetch Market Caps from CoinGecko (with fallback for reliability)
  Future<Map<String, double>> fetchMarketCaps() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&sparkline=false'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, double> marketCapMap = {};
        for (var item in data) {
          final symbol = (item['symbol'] as String).toUpperCase();
          final mCap = double.tryParse(item['market_cap']?.toString() ?? '0.0') ?? 0.0;
          if (mCap > 0) {
            marketCapMap[symbol] = mCap;
          }
        }
        return marketCapMap;
      }
    } catch (e) {
      // Fail silently to use fallback
    }
    return fallbackMarketCaps;
  }

  // Static fallback market caps (approximate values in USD for top coins, updated regularly or used as default ratios)
  static const Map<String, double> fallbackMarketCaps = {
    'BTC': 1200000000000.0,
    'ETH': 400000000000.0,
    'BNB': 85000000000.0,
    'SOL': 65000000000.0,
    'XRP': 30000000000.0,
    'ADA': 15000000000.0,
    'DOGE': 18000000000.0,
    'SHIB': 11000000000.0,
    'AVAX': 14000000000.0,
    'DOT': 8000000000.0,
    'LINK': 9000000000.0,
    'TRX': 10500000000.0,
    'MATIC': 6000000000.0,
    'NEAR': 6500000000.0,
    'LTC': 6000000000.0,
    'BCH': 9000000000.0,
    'UNI': 4500000000.0,
    'APT': 4000000000.0,
    'FIL': 3500000000.0,
    'ATOM': 3200000000.0,
    'ETC': 4200000000.0,
    'IMX': 3000000000.0,
    'OP': 2800000000.0,
    'GRT': 2500000000.0,
    'RNDR': 2700000000.0,
    'SUI': 3200000000.0,
    'PEPE': 4500000000.0,
    'WIF': 3000000000.0,
    'BONK': 2000000000.0,
    'FLOKI': 1800000000.0,
    'FTM': 2200000000.0,
    'THETA': 2000000000.0,
    'LDO': 1700000000.0,
    'AR': 1800000000.0,
    'ALGO': 1500000000.0,
    'VET': 2100000000.0,
    'ICP': 4200000000.0,
    'STX': 2800000000.0,
    'EGLD': 1200000000.0,
    'GALA': 1300000000.0,
    'MKR': 2400000000.0,
    'AAVE': 1800000000.0,
    'INJ': 2200000000.0,
    'TIA': 1500000000.0,
    'FET': 2100000000.0,
    'RUNE': 2300000000.0,
  };

  // Fetch Klines (Candlestick data)
  Future<List<Candle>> fetchKlines(String symbol, String interval) async {
    final response = await http.get(
        Uri.parse('$baseUrl/klines?symbol=$symbol&interval=$interval&limit=1000'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Candle(
            date: DateTime.fromMillisecondsSinceEpoch(e[0]),
            open: double.parse(e[1].toString()),
            high: double.parse(e[2].toString()),
            low: double.parse(e[3].toString()),
            close: double.parse(e[4].toString()),
            volume: double.parse(e[5].toString()),
          )).toList().reversed.toList();
    } else {
      throw Exception('Failed to load klines');
    }
  }
}
