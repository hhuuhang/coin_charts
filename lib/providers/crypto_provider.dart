import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/crypto_symbol.dart';
import '../services/binance_api_service.dart';

class CryptoProvider with ChangeNotifier {
  final _apiService = BinanceApiService();
  
  List<CryptoSymbol> _symbols = [];
  List<CryptoSymbol> get symbols => _symbols;
  
  List<CryptoSymbol> _filteredSymbols = [];
  List<CryptoSymbol> get filteredSymbols => _filteredSymbols;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _searchQuery = '';

  WebSocketChannel? _tickerChannel;

  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final fetchedSymbols = await _apiService.fetchSymbols();
      final tickerData = await _apiService.fetch24hTicker();

      for (var symbol in fetchedSymbols) {
        if (tickerData.containsKey(symbol.symbol)) {
          symbol.price = tickerData[symbol.symbol]['price'];
          symbol.priceChangePercent = tickerData[symbol.symbol]['priceChangePercent'];
        }
      }

      // Sort by volume or name, here we sort by absolute price change as an example to show active coins
      fetchedSymbols.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()));

      _symbols = fetchedSymbols;
      _filteredSymbols = _symbols;
      
      _connectTickerWebSocket();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchSymbols(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredSymbols = _symbols;
    } else {
      _filteredSymbols = _symbols
          .where((s) =>
              s.symbol.toLowerCase().contains(_searchQuery) ||
              s.baseAsset.toLowerCase().contains(_searchQuery))
          .toList();
    }
    notifyListeners();
  }

  void _connectTickerWebSocket() {
    _tickerChannel?.sink.close();
    _tickerChannel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/!miniTicker@arr'),
    );

    _tickerChannel!.stream.listen((message) {
      final List<dynamic> data = json.decode(message);
      bool updated = false;
      for (var item in data) {
        final symbolStr = item['s'];
        final index = _symbols.indexWhere((s) => s.symbol == symbolStr);
        if (index != -1) {
          _symbols[index].price = double.tryParse(item['c'] ?? '0.0') ?? _symbols[index].price;
          updated = true;
        }
      }
      if (updated) {
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('WebSocket Ticker Error: $error');
    });
  }

  @override
  void dispose() {
    _tickerChannel?.sink.close();
    super.dispose();
  }
}
