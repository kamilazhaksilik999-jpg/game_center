import 'package:shared_preferences/shared_preferences.dart';

class CoinService {
  static int coins = 0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt("coins") ?? 0;
  }

  static Future<void> addCoins(int amount) async {
    coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("coins", coins);
  }

  static int getCoins() {
    return coins;
  }
}