import 'package:flutter/material.dart';

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

/// 🔥 ДОБАВИЛ FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/spin_wheel_screen.dart';

/// 🔥 ДОБАВИЛ MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyABnMg83_sAmB5MqqSVFqTEKmxXKJh072s",
      appId: "1:984380938437:web:925a2e63c5f8f0005978ac",
      messagingSenderId: "984380938437",
      projectId: "game-center-b4d5c",
      storageBucket: "game-center-b4d5c.firebasestorage.app",
    ),
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
        "/shop": (context) => const ShopScreen(), // ✅ РАБОЧИЙ МАГАЗИН
        "/lobby": (context) =>
        const Scaffold(body: Center(child: Text("Lobby"))),
        "/profile": (context) => const ProfileScreen(),

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