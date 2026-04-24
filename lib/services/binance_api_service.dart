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
        };
      }
      return tickerMap;
    } else {
      throw Exception('Failed to load ticker data');
    }
  }

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
