import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_service.dart';

class LeaderboardProvider {
  final LeaderboardService service = LeaderboardService();

  // 📡 Живой поток таблицы
  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboard() {
    return service.leaderboardStream();
  }

  // 🎮 После матча
  Future<void> updateAfterMatch({
    required String userId,
    required bool win,
  }) {
    return service.updateAfterMatch(userId: userId, win: win);
  }

  // 🆕 При регистрации пользователя
  Future<void> initUser({
    required String userId,
    required String displayName,
  }) {
    return service.initUserProfile(userId: userId, displayName: displayName);
  }

  // 👤 Текущий userId
  String? get currentUserId => service.currentUserId;
}