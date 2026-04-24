import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static int _coins  = 0; // локальный кэш

  static String? get _uid => _auth.currentUser?.uid;

  // 🔄 Загрузить монеты из Firebase
  static Future<void> load() async {
    if (_uid == null) return;
    final doc = await _db.collection('users').doc(_uid).get();
    _coins = (doc.data()?['coins'] ?? 0) as int;
  }

  // 📥 Получить текущий кэш (без запроса)
  static int getCoins() => _coins;

  // ➕ Добавить монеты
  static Future<void> addCoins(int amount) async {
    if (_uid == null) return;
    _coins += amount;
    await _db.collection('users').doc(_uid).update({
      'coins': FieldValue.increment(amount),
    });
  }

  // ➖ Убрать монеты
  static Future<void> removeCoins(int amount) async {
    if (_uid == null) return;
    _coins -= amount;
    await _db.collection('users').doc(_uid).update({
      'coins': FieldValue.increment(-amount),
    });
  }

  // 🔥 Установить монеты напрямую
  static Future<void> setCoins(int value) async {
    if (_uid == null) return;
    _coins = value;
    await _db.collection('users').doc(_uid).update({'coins': value});
  }
}