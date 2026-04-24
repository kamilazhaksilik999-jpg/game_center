import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Текущий пользователь
  User? get currentUser => _auth.currentUser;

  // Поток авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Регистрация
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String avatar,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Создаём профиль в Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'avatar': avatar,
      'email': email,
      'coins': 0,
      'wins': 0,
      'gamesPlayed': 0,
      'rank': 'Новичок',
      'friends': [],
      'id': '#${1000 + DateTime.now().millisecondsSinceEpoch % 9000}',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // Вход
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Выход
  Future<void> logout() async {
    await _auth.signOut();
  }
}