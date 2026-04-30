// lib/core/models/shop_item.dart

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;        // цена в монетах
  final String type;      // 'skin', 'boost', 'lives' и т.д.
  final String imageUrl;
  final bool isPurchased;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.imageUrl,
    this.isPurchased = false,
  });

  // Из JSON (с сервера / Firebase)
  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      type: json['type'],
      imageUrl: json['imageUrl'] ?? '',
      isPurchased: json['isPurchased'] ?? false,
    );
  }

  // В JSON (для сохранения)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'type': type,
      'imageUrl': imageUrl,
      'isPurchased': isPurchased,
    };
  }
}