import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/binance_api_service.dart';

enum ChartMainState { ma, boll, none }
enum ChartSecondaryState { rsi, macd, kdj, wr, none }

class ChartProvider with ChangeNotifier {
  final _apiService = BinanceApiService();
  
  List<KLineEntity> _candles = [];
  List<KLineEntity> get candles => _candles;

  String _currentSymbol = 'BTCUSDT';
  String get currentSymbol => _currentSymbol;

  String _currentInterval = '1h';
  String get currentInterval => _currentInterval;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  WebSocketChannel? _klineChannel;
  double _currentPrice = 0.0;
  double get currentPrice => _currentPrice;

  // Indicator States
  ChartMainState _mainState = ChartMainState.none;
  ChartMainState get mainState => _mainState;

  ChartSecondaryState _secondaryState = ChartSecondaryState.none;
  ChartSecondaryState get secondaryState => _secondaryState;

  void changeMainState(ChartMainState state) {
    if (_mainState == state) {
      _mainState = ChartMainState.none; // Toggle off if clicked again
    } else {
      _mainState = state;
    }
    notifyListeners();
  }

  void changeSecondaryState(ChartSecondaryState state) {
    if (_secondaryState == state) {
      _secondaryState = ChartSecondaryState.none; // Toggle off if clicked again
    } else {
      _secondaryState = state;
    }
    notifyListeners();
  }

  List<MainIndicator> get activeMainIndicators {
    switch (_mainState) {
      case ChartMainState.ma:
        return [MAIndicator()];
      case ChartMainState.boll:
        return [BOLLIndicator()];
      default:
        return [];
    }
  }

  List<SecondaryIndicator> get activeSecondaryIndicators {
    switch (_secondaryState) {
      case ChartSecondaryState.macd:
        return [MACDIndicator()];
      case ChartSecondaryState.rsi:
        return [RSIIndicator()];
      case ChartSecondaryState.kdj:
        return [KDJIndicator()];
      case ChartSecondaryState.wr:
        return [WRIndicator()];
      default:
        return [];
    }
  }

  void _calculateIndicators() {
    if (_candles.isEmpty) return;
    // Calculate all indicators so that toggling them is instant
    DataUtil.calculateAll(
      _candles,
      [MAIndicator(), BOLLIndicator()],
      [RSIIndicator(), MACDIndicator(), KDJIndicator(), WRIndicator()],
    );
  }

  Future<void> loadChart(String symbol, [String? interval]) async {
    _currentSymbol = symbol;
    if (interval != null) {
      _currentInterval = interval;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedCandles = await _apiService.fetchKlines(_currentSymbol, _currentInterval);
      
      // Map Candle to KLineEntity and reverse to chronological order (oldest first)
      _candles = fetchedCandles.reversed.map((candle) {
        return KLineEntity.fromJson({
          'open': candle.open,
          'high': candle.high,
          'low': candle.low,
          'close': candle.close,
          'vol': candle.volume,
          'time': candle.date.millisecondsSinceEpoch,
        });
      }).toList();

      if (_candles.isNotEmpty) {
        _currentPrice = _candles.last.close;
        _calculateIndicators();
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
      
      final candle = KLineEntity.fromJson({
        'open': double.parse(kline['o']),
        'high': double.parse(kline['h']),
        'low': double.parse(kline['l']),
        'close': double.parse(kline['c']),
        'vol': double.parse(kline['v']),
        'time': kline['t'],
      });

      _currentPrice = candle.close;

      if (_candles.isNotEmpty) {
        final lastCandle = _candles.last;
        if (lastCandle.time == candle.time) {
          _candles[_candles.length - 1] = candle;
        } else if (candle.time! > lastCandle.time!) {
          _candles.add(candle);
        }
        
        _calculateIndicators();
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
