import 'package:shared_preferences/shared_preferences.dart';

class CoinService {
  static int coins = 0;

  /// 🔄 загрузка при старте
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt("coins") ?? 1250;
  }

  /// ➕ добавить монеты
  static Future<void> addCoins(int amount) async {
    coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("coins", coins);
  }

  /// ➖ НОВОЕ — убрать монеты
  static Future<void> removeCoins(int amount) async {
    coins -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("coins", coins);
  }

  /// 📥 получить монеты (оставляем как есть)
  static int getCoins() {
    return coins;
  }

  /// 🔥 НОВОЕ — установить монеты (чтобы не было ошибки)
  static Future<void> setCoins(int value) async {
    coins = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("coins", coins);
  }
}