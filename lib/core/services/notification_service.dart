import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _myUid => _auth.currentUser?.uid ?? '';

  // Стрим уведомлений
  Stream<QuerySnapshot> notificationsStream() {
    return _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Количество непрочитанных
  Stream<int> unreadCountStream() {
    return _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Пометить прочитанным
  Future<void> markRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .doc(notifId)
        .update({'read': true});
  }

  // Пометить все прочитанными
  Future<void> markAllRead() async {
    final docs = await _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in docs.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  // Отправить приглашение в игру
  Future<void> sendGameInvite({
    required String toUid,
    required String roomCode,
    required String gameType,
  }) async {
    final inviteRef = await _db.collection('game_invites').add({
      'fromUid': _myUid,
      'toUid': toUid,
      'roomCode': roomCode,
      'gameType': gameType,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('notifications')
        .doc(toUid)
        .collection('items')
        .add({
      'type': 'game_invite',
      'fromUid': _myUid,
      'inviteId': inviteRef.id,
      'roomCode': roomCode,
      'gameType': gameType,
      'text': 'Приглашает тебя в игру',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Принять/отклонить приглашение
  Future<void> respondToInvite(String inviteId, bool accept) async {
    await _db.collection('game_invites').doc(inviteId).update({
      'status': accept ? 'accepted' : 'declined',
    });
  }
}