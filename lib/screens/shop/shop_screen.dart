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
    _controller.loadShop(); // ✅ было loadCoins() — теперь грузит из Firebase
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void buyItem(ShopItem item) async {
    final success = await _controller.buyItem(item);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Куплено! 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    // ⏳ Пока грузится Firebase — показываем спиннер
    if (_controller.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1220),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),

      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text(
          "🛒 Магазин",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, size: 18),
                const SizedBox(width: 4),
                Text(
                  "${_controller.coins}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),

      body: Column(
        children: [

          /// 🔥 СЕТКА ТОВАРОВ
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _controller.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = _controller.items[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.isBought ? Colors.green : Colors.white12,
                      width: item.isBought ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      /// КАРТИНКА
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            item.image,
                            height: 95,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                color: Colors.white38,
                                size: 30,
                              );
                            },
                          ),
                        ),
                      ),

                      /// ТЕКСТ
                      Column(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            item.desc,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// КНОПКА — зеленеет если куплено
                      GestureDetector(
                        onTap: () => buyItem(item),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: item.isBought ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.isBought ? "✅ Куплено" : "${item.price} 🪙",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// 📦 УЖЕ КУПЛЕНО
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📦 Уже куплено",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _controller.boughtItems.isEmpty
                        ? const Center(
                      child: Text(
                        "Пока ничего не приобретено",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                        : ListView(
                      children: _controller.boughtItems.map((e) {
                        return ListTile(
                          leading: Image.asset(
                            e.image,
                            width: 30,
                            errorBuilder: (c, err, s) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.white38,
                            ),
                          ),
                          title: Text(
                            e.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            e.desc,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: e.isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.isActive ? "✅ Активно" : "❌ Истекло",
                              style: TextStyle(
                                color: e.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}