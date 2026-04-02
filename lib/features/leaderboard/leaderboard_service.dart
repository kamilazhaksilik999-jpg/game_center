import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  /// 📡 Получение leaderboard (топ 100)
  Stream<QuerySnapshot<Map<String, dynamic>>> leaderboardStream() {

    return firestore

        .collection('users')

        .where(
        'leaderboardEligible',
        isEqualTo: true
    )

        .orderBy(
        'rating',
        descending: true
    )

        .limit(100)

        .snapshots();

  }

  /// 🎮 Обновление после матча (с безопасной транзакцией)
  Future<void> updateAfterMatch({

    required String userId,
    required bool win,

  }) async {

    final ref =
    firestore.collection('users')
        .doc(userId);

    await firestore.runTransaction((transaction) async {

      final snapshot =
      await transaction.get(ref);

      if (!snapshot.exists) {
        return;
      }

      final data =
          snapshot.data() ?? {};

      int currentRating =
      (data['rating'] ?? 0) as int;

      int change =
      win ? 30 : -5;

      int newRating =
          currentRating + change;

      if (newRating < 0) {
        newRating = 0;
      }

      transaction.update(ref, {

        'totalGames':
        FieldValue.increment(1),

        'wins':
        win
            ? FieldValue.increment(1)
            : FieldValue.increment(0),

        'losses':
        win
            ? FieldValue.increment(0)
            : FieldValue.increment(1),

        'rating':
        newRating,

        'coins':
        win
            ? FieldValue.increment(50)
            : FieldValue.increment(10),

        'leaderboardEligible':
        true,

        'lastGame':
        FieldValue.serverTimestamp(),

      });

    });

  }

}