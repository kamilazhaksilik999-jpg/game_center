import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _myUid => _auth.currentUser!.uid;

  String _chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ── Отправить сообщение ──
  Future<void> sendMessage(String toUid, String text) async {
    final chatId = _chatId(_myUid, toUid);

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'fromUid': _myUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Обновляем мета-данные чата
    await _db.collection('chats').doc(chatId).set({
      'users': [_myUid, toUid],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageFrom': _myUid,
    }, SetOptions(merge: true));

    // Уведомление
    await _db
        .collection('notifications')
        .doc(toUid)
        .collection('items')
        .add({
      'type': 'message',
      'fromUid': _myUid,
      'text': text,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Стрим сообщений ──
  Stream<QuerySnapshot> messagesStream(String otherUid) {
    return _db
        .collection('chats')
        .doc(_chatId(_myUid, otherUid))
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ── Пометить как прочитанные ──
  Future<void> markAsRead(String otherUid) async {
    final chatId = _chatId(_myUid, otherUid);
    final msgs = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('fromUid', isEqualTo: otherUid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ── Список чатов ──
  Stream<QuerySnapshot> chatsStream() {
    return _db
        .collection('chats')
        .where('users', arrayContains: _myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}