import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../models/crypto_symbol.dart';
import 'chart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CryptoProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CryptoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2329),
        title: const Text('Markets', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              onChanged: provider.searchSymbols,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Coin Pairs',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E2329),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Sorting Selector chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SortChip(
                    label: 'Market Cap',
                    criteria: SortCriteria.marketCap,
                    activeCriteria: provider.currentSort,
                    onTap: () => provider.changeSortCriteria(SortCriteria.marketCap),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: '24h Vol',
                    criteria: SortCriteria.volume,
                    activeCriteria: provider.currentSort,
                    onTap: () => provider.changeSortCriteria(SortCriteria.volume),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Gainers',
                    criteria: SortCriteria.gainers,
                    activeCriteria: provider.currentSort,
                    onTap: () => provider.changeSortCriteria(SortCriteria.gainers),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Losers',
                    criteria: SortCriteria.losers,
                    activeCriteria: provider.currentSort,
                    onTap: () => provider.changeSortCriteria(SortCriteria.losers),
                  ),
                ],
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(flex: 3, child: Text('Pair / Vol', style: TextStyle(color: Colors.grey, fontSize: 12))),
                const Expanded(flex: 3, child: Text('Last Price', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                Expanded(
                  flex: 2,
                  child: Text(
                    provider.currentSort == SortCriteria.marketCap
                        ? 'Market Cap'
                        : provider.currentSort == SortCriteria.volume
                            ? '24h Vol'
                            : '24h Chg%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Main list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD535)))
                : ListView.builder(
                    itemCount: provider.filteredSymbols.length,
                    itemBuilder: (context, index) {
                      final symbol = provider.filteredSymbols[index];
                      return CryptoListItem(symbol: symbol);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final SortCriteria criteria;
  final SortCriteria activeCriteria;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.criteria,
    required this.activeCriteria,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = criteria == activeCriteria;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCD535) : const Color(0xFF1E2329),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFCD535) : const Color(0xFF2B3139),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class CryptoListItem extends StatelessWidget {
  final CryptoSymbol symbol;

  const CryptoListItem({super.key, required this.symbol});

  String _formatNumber(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = symbol.priceChangePercent >= 0;
    final color = isPositive ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);
    final sortCriteria = context.watch<CryptoProvider>().currentSort;

    Widget rightColumnWidget;

    if (sortCriteria == SortCriteria.marketCap) {
      rightColumnWidget = Text(
        _formatNumber(symbol.marketCap),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.right,
      );
    } else if (sortCriteria == SortCriteria.volume) {
      rightColumnWidget = Text(
        _formatNumber(symbol.volume),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.right,
      );
    } else {
      rightColumnWidget = Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${isPositive ? '+' : ''}${symbol.priceChangePercent.toStringAsFixed(2)}%',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChartScreen(symbol: symbol),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol.baseAsset,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '/${symbol.quoteAsset}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                symbol.price.toStringAsFixed(symbol.price < 1 ? 5 : 2),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: rightColumnWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
