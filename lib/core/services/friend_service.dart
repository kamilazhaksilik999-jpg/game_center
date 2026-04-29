import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _myUid => _auth.currentUser?.uid ?? '';

  // ID дружбы — всегда сортируем чтобы был уникальный
  String _friendshipId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ── Отправить заявку ──
  Future<void> sendRequest(String toUid) async {
    final reqId = _friendshipId(_myUid, toUid);

    await _db.collection('friend_requests').doc(reqId).set({
      'fromUid': _myUid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Уведомление получателю
    await _db
        .collection('notifications')
        .doc(toUid)
        .collection('items')
        .add({
      'type': 'friend_request',
      'fromUid': _myUid,
      'text': 'Отправил тебе заявку в друзья',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Принять заявку ──
  Future<void> acceptRequest(String fromUid) async {
    final reqId = _friendshipId(_myUid, fromUid);

    // Обновляем статус заявки
    await _db
        .collection('friend_requests')
        .doc(reqId)
        .update({'status': 'accepted'});

    // Создаём дружбу
    await _db.collection('friendships').doc(reqId).set({
      'users': [_myUid, fromUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Уведомление отправителю
    await _db
        .collection('notifications')
        .doc(fromUid)
        .collection('items')
        .add({
      'type': 'friend_accepted',
      'fromUid': _myUid,
      'text': 'Принял твою заявку в друзья',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Отклонить заявку ──
  Future<void> declineRequest(String fromUid) async {
    final reqId = _friendshipId(_myUid, fromUid);
    await _db
        .collection('friend_requests')
        .doc(reqId)
        .update({'status': 'declined'});
  }

  // ── Отменить отправленную заявку ──
  Future<void> cancelRequest(String toUid) async {
    final reqId = _friendshipId(_myUid, toUid);
    await _db.collection('friend_requests').doc(reqId).delete();
  }

  // ── Удалить из друзей ──
  Future<void> removeFriend(String friendUid) async {
    final id = _friendshipId(_myUid, friendUid);
    await _db.collection('friendships').doc(id).delete();
    await _db.collection('friend_requests').doc(id).delete();
  }

  // ── Заблокировать ──
  Future<void> blockUser(String targetUid) async {
    await removeFriend(targetUid);
    await _db.collection('blocked').doc(_myUid).set({
      'blockedUsers': FieldValue.arrayUnion([targetUid]),
    }, SetOptions(merge: true));
  }

  // ── Разблокировать ──
  Future<void> unblockUser(String targetUid) async {
    await _db.collection('blocked').doc(_myUid).update({
      'blockedUsers': FieldValue.arrayRemove([targetUid]),
    });
  }

  // ── Проверить статус между двумя юзерами ──
  Future<String> getRelationStatus(String otherUid) async {
    // Заблокирован?
    final blocked = await _db.collection('blocked').doc(_myUid).get();
    if (blocked.exists) {
      final list = List<String>.from(blocked.data()?['blockedUsers'] ?? []);
      if (list.contains(otherUid)) return 'blocked';
    }

    // Друзья?
    final friendship = await _db
        .collection('friendships')
        .doc(_friendshipId(_myUid, otherUid))
        .get();
    if (friendship.exists) return 'friends';

    // Заявка?
    final req = await _db
        .collection('friend_requests')
        .doc(_friendshipId(_myUid, otherUid))
        .get();
    if (req.exists && req.data()?['status'] == 'pending') {
      if (req.data()?['fromUid'] == _myUid) return 'request_sent';
      return 'request_received';
    }

    return 'none';
  }

  // ── Список друзей (стрим) ──
  Stream<QuerySnapshot> friendsStream() {
    return _db
        .collection('friendships')
        .where('users', arrayContains: _myUid)
        .snapshots();
  }

  // ── Входящие заявки (стрим) ──
  Stream<QuerySnapshot> incomingRequestsStream() {
    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ── Исходящие заявки (стрим) ──
  Stream<QuerySnapshot> outgoingRequestsStream() {
    return _db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ── Поиск пользователя по ID ──
  Future<Map<String, dynamic>?> findUserById(String gameId) async {
    final query = await _db
        .collection('users')
        .where('id', isEqualTo: gameId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return {'uid': query.docs.first.id, ...query.docs.first.data()};
  }
}