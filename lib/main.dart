import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🏠 главный экран
import 'screens/home/home_screen.dart';
import 'screens/diff_start_screen.dart';

/// 🪙 СЕРВИС МОНЕТ
import 'core/services/coin_service.dart';
import 'games/solo/memory/memory_screen.dart';
import 'games/solo/math/math_screen.dart';
import 'games/solo/clicker/clicker_screen.dart';
import 'games/solo/tic_tac_toe/tic_tac_toe_screen.dart';
import 'games/solo/sudoku/sudoku_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/spin_wheel_screen.dart';

/// 🛒 ДОБАВИЛ МАГАЗИН
import 'screens/shop/shop_screen.dart';

/// 🔥 FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/auth_screen.dart'; // ← добавили

/// 🔥 MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Center',

      initialRoute: "/",

      routes: {
        "/": (context) => const HomeScreen(),

        /// 🧭 меню
        "/shop": (context) => const ShopScreen(),
        "/lobby": (context) =>
        const Scaffold(body: Center(child: Text("Lobby"))),

        /// 🔥 ПРОФИЛЬ — проверяет авторизацию
        "/profile": (context) => StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF1A1A2E),
                body: Center(
                    child: CircularProgressIndicator(color: Colors.orange)),
              );
            }
            // Если вошёл — показываем профиль, иначе — экран входа
            if (snapshot.hasData) return const ProfileScreen();
            return const AuthScreen();
          },
        ),

        /// 🎮 ИГРЫ
        "/diff_start": (context) => const DiffStartScreen(),
        "/find_diff": (context) => const LevelSelectScreen(),
        "/memory": (context) => const MemoryScreen(),
        "/math": (context) => const MathScreen(),
        "/clicker": (context) => const ClickerScreen(),
        "/tic_tac_toe": (context) => const TicTacToeScreen(),
        "/sudoku": (context) => const SudokuScreen(),

        "/spin": (context) => const SpinWheelScreen(),
      },
    );
  }
}