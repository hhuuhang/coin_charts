import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:candlesticks/candlesticks.dart';
import '../providers/chart_provider.dart';
import '../models/crypto_symbol.dart';

class ChartScreen extends StatelessWidget {
  final CryptoSymbol symbol;

  const ChartScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChartProvider()..loadChart(symbol.symbol),
      child: const _ChartScreenContent(),
    );
  }
}

class _ChartScreenContent extends StatelessWidget {
  const _ChartScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChartProvider>();
    final isPositive = provider.candles.isNotEmpty 
        ? provider.candles.first.close >= provider.candles.first.open
        : true;
    final color = isPositive ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2329),
        title: Text(
          provider.currentSymbol,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Price Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E2329),
            child: Row(
              children: [
                Text(
                  provider.currentPrice.toStringAsFixed(provider.currentPrice < 1 ? 5 : 2),
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Timeframe Selector
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2B3139))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['15m', '1h', '4h', '1d', '1w'].map((interval) {
                final isSelected = provider.currentInterval == interval;
                return InkWell(
                  onTap: () => context.read<ChartProvider>().changeInterval(interval),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? const Color(0xFFFCD535) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      interval.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFCD535) : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Candlestick Chart
          Expanded(
            child: provider.isLoading && provider.candles.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD535)))
                : provider.candles.isEmpty
                    ? const Center(child: Text("No Data", style: TextStyle(color: Colors.white)))
                    : Candlesticks(
                        candles: provider.candles,
                        onLoadMoreCandles: () async {
                          // Placeholder for loading more data
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
