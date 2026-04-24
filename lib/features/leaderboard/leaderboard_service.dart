import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

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

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data          = snap.data() ?? {};
      final currentRating = (data['rating'] ?? 0) as int;
      final newRating     = (currentRating + (win ? 30 : -5)).clamp(0, 99999);

      tx.update(ref, {
        'rating':     newRating,
        'totalGames': FieldValue.increment(1),
        'wins':       FieldValue.increment(win ? 1 : 0),
        'losses':     FieldValue.increment(win ? 0 : 1),
        'lastGame':   FieldValue.serverTimestamp(),
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
        'name':       displayName,
        'rating':     0,
        'totalGames': 0,
        'wins':       0,
        'losses':     0,
        'lastGame':   null,
      });
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;
}