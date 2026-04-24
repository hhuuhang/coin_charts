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
          Padding(
            padding: const EdgeInsets.all(16.0),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 3, child: Text('Pair / Vol', style: TextStyle(color: Colors.grey, fontSize: 12))),
                Expanded(flex: 3, child: Text('Last Price', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                Expanded(flex: 2, child: Text('24h Chg%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ),
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

class CryptoListItem extends StatelessWidget {
  final CryptoSymbol symbol;

  const CryptoListItem({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final isPositive = symbol.priceChangePercent >= 0;
    final color = isPositive ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);

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
                child: Container(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
