import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/crypto_symbol.dart';
import '../services/binance_api_service.dart';

enum SortCriteria {
  marketCap,
  volume,
  gainers,
  losers,
}

class CryptoProvider with ChangeNotifier {
  final _apiService = BinanceApiService();
  
  List<CryptoSymbol> _symbols = [];
  List<CryptoSymbol> get symbols => _symbols;
  
  List<CryptoSymbol> _filteredSymbols = [];
  List<CryptoSymbol> get filteredSymbols => _filteredSymbols;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  
  SortCriteria _currentSort = SortCriteria.marketCap;
  SortCriteria get currentSort => _currentSort;

  WebSocketChannel? _tickerChannel;

  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final fetchedSymbols = await _apiService.fetchSymbols();
      final tickerData = await _apiService.fetch24hTicker();
      final marketCaps = await _apiService.fetchMarketCaps();

      for (var symbol in fetchedSymbols) {
        if (tickerData.containsKey(symbol.symbol)) {
          symbol.price = tickerData[symbol.symbol]['price'];
          symbol.priceChangePercent = tickerData[symbol.symbol]['priceChangePercent'];
          symbol.volume = tickerData[symbol.symbol]['volume'];
        }
        final baseUpper = symbol.baseAsset.toUpperCase();
        symbol.marketCap = marketCaps[baseUpper] ?? (symbol.volume > 0 ? symbol.volume * 5.2 : symbol.price * 150000.0);
      }

      _symbols = fetchedSymbols;
      _applySorting();
      
      _connectTickerWebSocket();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applySorting() {
    switch (_currentSort) {
      case SortCriteria.marketCap:
        _symbols.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
      case SortCriteria.volume:
        _symbols.sort((a, b) => b.volume.compareTo(a.volume));
        break;
      case SortCriteria.gainers:
        _symbols.sort((a, b) => b.priceChangePercent.compareTo(a.priceChangePercent));
        break;
      case SortCriteria.losers:
        _symbols.sort((a, b) => a.priceChangePercent.compareTo(b.priceChangePercent));
        break;
    }
    _filterSymbolsList();
  }

  void changeSortCriteria(SortCriteria criteria) {
    if (_currentSort != criteria) {
      _currentSort = criteria;
      _applySorting();
      notifyListeners();
    }
  }

  void searchSymbols(String query) {
    _searchQuery = query.toLowerCase();
    _filterSymbolsList();
    notifyListeners();
  }

  void _filterSymbolsList() {
    if (_searchQuery.isEmpty) {
      _filteredSymbols = List.from(_symbols);
    } else {
      _filteredSymbols = _symbols
          .where((s) =>
              s.symbol.toLowerCase().contains(_searchQuery) ||
              s.baseAsset.toLowerCase().contains(_searchQuery))
          .toList();
    }
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
