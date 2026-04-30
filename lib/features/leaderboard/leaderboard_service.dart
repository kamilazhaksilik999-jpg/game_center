import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> leaderboardStream() {
    return _db
        .collection('leaderboard')
        .orderBy('rating', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> updateAfterMatch({
    required String userId,
    required bool win,
  }) async {
    final ref = _db.collection('leaderboard').doc(userId);

    // Получаем displayName из Auth на случай если документа ещё нет
    final user = _auth.currentUser;
    final displayName =
        user?.displayName ?? user?.email ?? 'Игрок';

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final int ratingDelta = win ? 30 : -5;

      if (!snap.exists) {
        // ← ИСПРАВЛЕНИЕ: создаём документ если его нет
        tx.set(ref, {
          'displayName'     : displayName,
          'rating'          : win ? 30 : 0,
          'totalGames'      : 1,
          'wins'            : win ? 1 : 0,
          'losses'          : win ? 0 : 1,
          'winStreak'       : win ? 1 : 0,
          'bestStreak'      : win ? 1 : 0,
          'lastRatingChange': ratingDelta,
          'lastGame'        : FieldValue.serverTimestamp(),
        });
        return;
      }

      final data           = snap.data() ?? {};
      final currentRating  = (data['rating']    ?? 0) as int;
      final currentStreak  = (data['winStreak'] ?? 0) as int;
      final newRating      = (currentRating + ratingDelta).clamp(0, 99999);
      final newStreak      = win ? currentStreak + 1 : 0;
      final bestStreak     = data['bestStreak'] ?? 0;

      tx.update(ref, {
        'displayName'     : displayName, // обновляем имя при каждой игре
        'rating'          : newRating,
        'totalGames'      : FieldValue.increment(1),
        'wins'            : FieldValue.increment(win ? 1 : 0),
        'losses'          : FieldValue.increment(win ? 0 : 1),
        'winStreak'       : newStreak,
        'bestStreak'      : newStreak > bestStreak ? newStreak : bestStreak,
        'lastRatingChange': ratingDelta,
        'lastGame'        : FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> initUserProfile({
    required String userId,
    required String displayName,
  }) async {
    final ref  = _db.collection('leaderboard').doc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'displayName'     : displayName,
        'rating'          : 0,
        'totalGames'      : 0,
        'wins'            : 0,
        'losses'          : 0,
        'winStreak'       : 0,
        'bestStreak'      : 0,
        'lastRatingChange': 0,
        'lastGame'        : null,
      });
    } else {
      await ref.update({'displayName': displayName});
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;
}