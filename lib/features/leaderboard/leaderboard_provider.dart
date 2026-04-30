import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_service.dart';

class LeaderboardProvider {
  final LeaderboardService _service = LeaderboardService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboard() {
    return _service.leaderboardStream();
  }

  Future<void> updateAfterMatch({
    required String userId,
    required bool win,
  }) {
    return _service.updateAfterMatch(userId: userId, win: win);
  }

  Future<void> initUser({
    required String userId,
    required String displayName,
  }) {
    return _service.initUserProfile(userId: userId, displayName: displayName);
  }

  String? get currentUserId => _service.currentUserId;
}