import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _myUid => _auth.currentUser?.uid ?? '';

  // Вызывай при запуске приложения
  Future<void> setOnline() async {
    await _db.collection('users').doc(_myUid).update({
      'status': 'online',
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Вызывай при выходе или сворачивании
  Future<void> setOffline() async {
    await _db.collection('users').doc(_myUid).update({
      'status': 'offline',
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Стрим статуса конкретного пользователя
  Stream<DocumentSnapshot> userStatusStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}