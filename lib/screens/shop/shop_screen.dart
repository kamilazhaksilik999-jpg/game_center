// lib/screens/shop/shop_screen.dart

import 'package:flutter/material.dart';
import 'shop_controller.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _controller = ShopController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _controller.loadShop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void buyItem(ShopItem item) async {
    final success = await _controller.buyItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: success ? const Color(0xFF34D399) : const Color(0xFFF43F5E),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              success ? "Куплено! 🎉" : _controller.message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D1B35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: success
                ? const Color(0xFF34D399).withValues(alpha: 0.5)
                : const Color(0xFFF43F5E).withValues(alpha: 0.5),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF060B1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    color: Color(0xFFF97316),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Загружаем магазин...",
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      // ── AppBar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,

        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "SHOP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Магазин",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    size: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "${_controller.coins}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFF97316),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [

          // ── Секция товаров ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "ДОСТУПНЫЕ ТОВАРЫ",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Сетка товаров ─────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _controller.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final item = _controller.items[index];
                return _ShopCard(item: item, onBuy: () => buyItem(item));
              },
            ),
          ),

          // ── Разделитель ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF06B6D4)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "УЖЕ КУПЛЕНО",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          // ── Купленные товары ──────────────────────────────────────────
          Expanded(
            child: _controller.boughtItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Пока ничего не приобретено",
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: _controller.boughtItems.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: e.isActive
                          ? [
                        const Color(0xFF059669).withValues(alpha: 0.15),
                        const Color(0xFF0D1B35).withValues(alpha: 0.5),
                      ]
                          : [
                        const Color(0xFF7F1D1D).withValues(alpha: 0.15),
                        const Color(0xFF0D1B35).withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: e.isActive
                          ? const Color(0xFF34D399).withValues(alpha: 0.35)
                          : const Color(0xFFF43F5E).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Image.asset(
                          e.image,
                          width: 32,
                          errorBuilder: (c, err, s) => const Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white24,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              e.desc,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: e.isActive
                              ? const Color(0xFF059669).withValues(alpha: 0.2)
                              : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: e.isActive
                                ? const Color(0xFF34D399).withValues(alpha: 0.5)
                                : const Color(0xFFF43F5E).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          e.isActive ? "✅ Активно" : "❌ Истекло",
                          style: TextStyle(
                            color: e.isActive
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF43F5E),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Карточка товара ───────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onBuy;

  const _ShopCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final bought = item.isBought;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bought
              ? [
            const Color(0xFF059669).withValues(alpha: 0.15),
            const Color(0xFF0D1B35).withValues(alpha: 0.8),
          ]
              : [
            const Color(0xFF0D1B35).withValues(alpha: 0.9),
            const Color(0xFF111827).withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bought
              ? const Color(0xFF34D399).withValues(alpha: 0.5)
              : const Color(0xFFF97316).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: bought
            ? [
          BoxShadow(
            color: const Color(0xFF34D399).withValues(alpha: 0.1),
            blurRadius: 10,
          )
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Картинка
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
              child: Center(
                child: Image.asset(
                  item.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.white24,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Название + описание
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Кнопка купить
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: GestureDetector(
              onTap: onBuy,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: bought
                      ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF34D399)],
                  )
                      : const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (bought
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF97316))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  bought ? "✅ Куплено" : "${item.price} 🪙",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}