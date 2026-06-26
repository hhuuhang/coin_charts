import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
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

  Widget _buildDetailWindow(KLineEntity entity) {
    final isUp = entity.close >= entity.open;
    final color = isUp ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);
    final change = entity.open == 0
        ? 0.0
        : ((entity.close - entity.open) / entity.open * 100);

    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329).withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2B3139), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateTime.fromMillisecondsSinceEpoch(entity.time ?? 0).toString().substring(11, 16),
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildInfoRow('O:', entity.open.toStringAsFixed(2)),
          _buildInfoRow('H:', entity.high.toStringAsFixed(2)),
          _buildInfoRow('L:', entity.low.toStringAsFixed(2)),
          _buildInfoRow('C:', entity.close.toStringAsFixed(2)),
          _buildInfoRow('Chg:', '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', color),
          _buildInfoRow('Vol:', entity.vol.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChartProvider>();
    final isPositive = provider.candles.isNotEmpty 
        ? provider.candles.last.close >= provider.candles.last.open
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

          // Indicator Toolbar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2329),
              border: Border(bottom: BorderSide(color: Color(0xFF2B3139))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Main:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                ...[
                  {'label': 'MA', 'state': ChartMainState.ma},
                  {'label': 'BOLL', 'state': ChartMainState.boll},
                ].map((item) {
                  final state = item['state'] as ChartMainState;
                  final isSelected = provider.mainState == state;
                  return _IndicatorButton(
                    label: item['label'] as String,
                    isSelected: isSelected,
                    onTap: () => context.read<ChartProvider>().changeMainState(state),
                  );
                }),
                const VerticalDivider(color: Color(0xFF2B3139), indent: 10, endIndent: 10, width: 20),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Sub:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                ...[
                  {'label': 'RSI', 'state': ChartSecondaryState.rsi},
                  {'label': 'MACD', 'state': ChartSecondaryState.macd},
                  {'label': 'KDJ', 'state': ChartSecondaryState.kdj},
                  {'label': 'WR', 'state': ChartSecondaryState.wr},
                ].map((item) {
                  final state = item['state'] as ChartSecondaryState;
                  final isSelected = provider.secondaryState == state;
                  return _IndicatorButton(
                    label: item['label'] as String,
                    isSelected: isSelected,
                    onTap: () => context.read<ChartProvider>().changeSecondaryState(state),
                  );
                }),
              ],
            ),
          ),

          // Candlestick Chart
          Expanded(
            child: provider.isLoading && provider.candles.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD535)))
                : provider.candles.isEmpty
                    ? const Center(child: Text("No Data", style: TextStyle(color: Colors.white)))
                    : KChartWidget(
                        provider.candles,
                        const KChartStyle(),
                        const KChartColors(
                          bgColor: Color(0xFF0B0E11),
                          defaultTextColor: Colors.grey,
                          gridColor: Color(0xFF1E2329),
                          upColor: Color(0xFF0ECB81),
                          dnColor: Color(0xFFF6465D),
                          volUpColor: Color(0xFF0ECB81),
                          volDnColor: Color(0xFFF6465D),
                          nowPriceUpColor: Color(0xFF0ECB81),
                          nowPriceDnColor: Color(0xFFF6465D),
                          crossColor: Colors.white,
                          crossTextColor: Colors.white,
                          selectBorderColor: Color(0xFFFCD535),
                          selectFillColor: Color(0xFF1E2329),
                        ),
                        isLine: false,
                        mainIndicators: provider.activeMainIndicators,
                        secondaryIndicators: provider.activeSecondaryIndicators,
                        fixedLength: provider.currentPrice < 1 ? 5 : 2,
                        timeFormat: TimeFormat.YEAR_MONTH_DAY,
                        detailBuilder: (entity) => _buildDetailWindow(entity),
                        isTrendLine: false,
                      ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndicatorButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: isSelected ? const Color(0xFFFCD535) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
