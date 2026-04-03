import 'package:flutter/material.dart';
import '../../core/services/coin_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class ShopItem {
  String name;
  String desc;
  int price;
  String image; // 👉 путь к картинке

  bool isBought;
  bool isActive;

  ShopItem({
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
    this.isBought = false,
    this.isActive = false,
  });
}

class _ShopScreenState extends State<ShopScreen> {
  int coins = 0;

  List<ShopItem> items = [
    ShopItem(
        name: "Новая тема",
        desc: "Темная галактика",
        price: 300,
        image: "assets/palette.png"),
    ShopItem(
        name: "VIP статус",
        desc: "7 дней",
        price: 500,
        image: "assets/crown.png"),
    ShopItem(
        name: "Буст XP x2",
        desc: "24 часа",
        price: 200,
        image: "assets/rocket.png"),
    ShopItem(
        name: "Аватар рамка",
        desc: "Золотая",
        price: 150,
        image: "assets/mask.png"),
  ];

  @override
  void initState() {
    super.initState();
    loadCoins();
  }

  void loadCoins() async {
    await CoinService.load();
    setState(() {
      coins = CoinService.getCoins();
    });
  }

  void buyItem(ShopItem item) async {
    if (item.isBought) return;

    if (coins >= item.price) {
      await CoinService.removeCoins(item.price);

      setState(() {
        coins = CoinService.getCoins();
        item.isBought = true;
        item.isActive = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Недостаточно монет")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boughtItems = items.where((e) => e.isBought).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),

      /// 🟡 APPBAR КАК НА МАКЕТЕ
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
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, size: 18),
                const SizedBox(width: 4),
                Text("$coins"),
              ],
            ),
          )
        ],
      ),

      body: Column(
        children: [

          /// 🔥 СЕТКА ТОВАРОВ (КАК НА ФОТО)
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 🔥 2 в ряд
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1, // 🔥 квадрат
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [

                      /// 🔥 КАРТИНКА ПО ЦЕНТРУ
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            item.image,
                            height: 85, // 🔥 почти половина
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

                      /// 📝 ТЕКСТ
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

                      /// 💰 КНОПКА КАК НА ФОТО
                      GestureDetector(
                        onTap: () => buyItem(item),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${item.price} 🪙",
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
                border: Border(
                  top: BorderSide(color: Colors.white12),
                ),
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
                    child: boughtItems.isEmpty
                        ? const Center(
                      child: Text(
                        "Пока ничего не приобретено",
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    )
                        : ListView(
                      children: boughtItems.map((e) {
                        return ListTile(
                          leading: Image.asset(
                            e.image,
                            width: 30,
                          ),
                          title: Text(
                            e.name,
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                          trailing: Text(
                            e.isActive
                                ? "Активно"
                                : "Истекло",
                            style: TextStyle(
                              color: e.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}