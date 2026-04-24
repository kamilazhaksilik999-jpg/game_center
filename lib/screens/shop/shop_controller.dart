import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopItem {
  final String id;
  final String name;
  final String desc;
  final int price;
  final String image;
  bool isBought;
  bool isActive;

  ShopItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
    this.isBought = false,
    this.isActive = false,
  });
}

class ShopController extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int coins     = 0;
  bool isLoading = false;
  String message = '';

  List<ShopItem> items = [
    ShopItem(id: 'theme_galaxy',  name: "Новая тема",    desc: "Темная галактика", price: 300, image: "assets/palette.png"),
    ShopItem(id: 'vip_7days',     name: "VIP статус",    desc: "7 дней",           price: 500, image: "assets/crown.png"),
    ShopItem(id: 'boost_xp',      name: "Буст XP x2",   desc: "24 часа",          price: 200, image: "assets/rocket.png"),
    ShopItem(id: 'avatar_golden', name: "Аватар рамка",  desc: "Золотая",          price: 150, image: "assets/mask.png"),
  ];

  String? get _uid => _auth.currentUser?.uid;

  // 🔄 Загрузить монеты и покупки из Firebase
  Future<void> loadShop() async {
    if (_uid == null) return;
    isLoading = true;
    notifyListeners();

    // 1. Монеты из профиля пользователя
    final userDoc = await _db.collection('users').doc(_uid).get();
    coins = (userDoc.data()?['coins'] ?? 0) as int;

    // 2. Купленные товары из подколлекции
    final purchasesSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('purchases')
        .get();

    final boughtIds = purchasesSnap.docs.map((e) => e.id).toSet();
    for (final item in items) {
      item.isBought = boughtIds.contains(item.id);
      item.isActive = item.isBought;
    }

    isLoading = false;
    notifyListeners();
  }

  // 🛒 Купить товар — транзакция в Firebase
  Future<bool> buyItem(ShopItem item) async {
    if (_uid == null)      { message = 'Не авторизован'; return false; }
    if (item.isBought)     { message = 'Уже куплено';    return false; }
    if (coins < item.price){ message = 'Недостаточно монет'; return false; }

    try {
      final userRef     = _db.collection('users').doc(_uid);
      final purchaseRef = userRef.collection('purchases').doc(item.id);

      await _db.runTransaction((tx) async {
        final snap          = await tx.get(userRef);
        final currentCoins  = (snap.data()?['coins'] ?? 0) as int;

        if (currentCoins < item.price) throw Exception('Недостаточно монет');

        // Списываем монеты в Firebase
        tx.update(userRef, {'coins': currentCoins - item.price});

        // Сохраняем покупку
        tx.set(purchaseRef, {
          'name':     item.name,
          'price':    item.price,
          'boughtAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      });

      // Обновляем локально
      coins        -= item.price;
      item.isBought = true;
      item.isActive = true;
      message       = 'Куплено! 🎉';
      notifyListeners();
      return true;

    } catch (e) {
      message = 'Ошибка: $e';
      return false;
    }
  }

  List<ShopItem> get boughtItems => items.where((e) => e.isBought).toList();
}