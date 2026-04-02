import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {

  static const String _userIdKey = 'user_id';

  /// 🔥 получить или создать пользователя
  static Future<String> getOrCreateUser() async {

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    /// ✅ если уже есть — вернуть
    if (userId != null) return userId;

    /// ❗ создаём нового
    final doc = FirebaseFirestore.instance.collection('users').doc();

    userId = doc.id;

    final random = Random();
    final nickname = "Player${random.nextInt(9999)}";

    await doc.set({
      "name": nickname,
      "rating": 0,
      "leaderboardEligible": true,
      "wins": 0,
      "losses": 0,
      "totalGames": 0,
    });

    /// 💾 сохраняем локально
    await prefs.setString(_userIdKey, userId);

    return userId;
  }
}