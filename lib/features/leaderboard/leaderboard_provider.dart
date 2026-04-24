import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_service.dart';

class LeaderboardProvider {
  final LeaderboardService service = LeaderboardService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboard() {
    return service.leaderboardStream();
  }

  Future<void> updateAfterMatch({
    required String userId,
    required bool win,
  }) {
    return service.updateAfterMatch(userId: userId, win: win);
  }

  Future<void> initUser({
    required String userId,
    required String displayName,
  }) {
    return service.initUserProfile(userId: userId, displayName: displayName);
  }

  String? get currentUserId => service.currentUserId;
}