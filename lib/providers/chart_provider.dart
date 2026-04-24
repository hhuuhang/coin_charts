import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/binance_api_service.dart';

class ChartProvider with ChangeNotifier {
  final _apiService = BinanceApiService();
  
  List<Candle> _candles = [];
  List<Candle> get candles => _candles;

  String _currentSymbol = 'BTCUSDT';
  String get currentSymbol => _currentSymbol;

  String _currentInterval = '1h';
  String get currentInterval => _currentInterval;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  WebSocketChannel? _klineChannel;
  double _currentPrice = 0.0;
  double get currentPrice => _currentPrice;

  Future<void> loadChart(String symbol, [String? interval]) async {
    _currentSymbol = symbol;
    if (interval != null) {
      _currentInterval = interval;
    }
    _isLoading = true;
    notifyListeners();

    try {
      _candles = await _apiService.fetchKlines(_currentSymbol, _currentInterval);
      if (_candles.isNotEmpty) {
        _currentPrice = _candles.first.close;
      }
      _connectKlineWebSocket();
    } catch (e) {
      debugPrint('Error loading chart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeInterval(String interval) {
    if (_currentInterval != interval) {
      loadChart(_currentSymbol, interval);
    }
  }

  void _connectKlineWebSocket() {
    _klineChannel?.sink.close();
    final symbolLower = _currentSymbol.toLowerCase();
    _klineChannel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/$symbolLower@kline_$_currentInterval'),
    );

    _klineChannel!.stream.listen((message) {
      final data = json.decode(message);
      final kline = data['k'];
      
      final candle = Candle(
        date: DateTime.fromMillisecondsSinceEpoch(kline['t']),
        open: double.parse(kline['o']),
        high: double.parse(kline['h']),
        low: double.parse(kline['l']),
        close: double.parse(kline['c']),
        volume: double.parse(kline['v']),
      );

      _currentPrice = candle.close;

      if (_candles.isNotEmpty && _candles.first.date.millisecondsSinceEpoch == candle.date.millisecondsSinceEpoch) {
        _candles[0] = candle;
      } else if (_candles.isNotEmpty && candle.date.isAfter(_candles.first.date)) {
        _candles.insert(0, candle);
      }
      
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _klineChannel?.sink.close();
    super.dispose();
  }
}
