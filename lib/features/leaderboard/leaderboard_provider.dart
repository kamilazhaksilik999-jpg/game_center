import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_service.dart';
class LeaderboardProvider {
  final LeaderboardService service =
  LeaderboardService();

  /// 📡 Поток leaderboard
  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboard() {

    return service.leaderboardStream();

  }

  /// 🎮 Обновление после матча
  Future<void> updateAfterMatch({

    required String userId,
    required bool win,

  }) {

    return service.updateAfterMatch(
      userId: userId,
      win: win,
    );

  }

}