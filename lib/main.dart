import 'package:flutter/material.dart';

/// 🏠 главный экран
import 'screens/home/home_screen.dart';
import 'screens/diff_start_screen.dart';
/// 🪙 СЕРВИС МОНЕТ
import 'core/services/coin_service.dart';

/// 🎮 ИГРЫ
import 'games/solo/memory/memory_screen.dart';
import 'games/solo/math/math_screen.dart';
import 'games/solo/clicker/clicker_screen.dart';
import 'games/solo/tic_tac_toe/tic_tac_toe_screen.dart';
import 'games/solo/sudoku/sudoku_screen.dart';
import 'screens/level_select_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 загружаем монеты
  await CoinService.load();

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
        "/shop": (context) =>
        const Scaffold(body: Center(child: Text("Shop"))),
        "/lobby": (context) =>
        const Scaffold(body: Center(child: Text("Lobby"))),
        "/profile": (context) =>
        const Scaffold(body: Center(child: Text("Profile"))),

        /// 🎮 ИГРЫ
        "/diff_start": (context) => const DiffStartScreen(),
        "/find_diff": (context) => const LevelSelectScreen(),
        "/memory": (context) => const MemoryScreen(),
        "/math": (context) => const MathScreen(),
        "/clicker": (context) => const ClickerScreen(),
        "/tic_tac_toe": (context) => const TicTacToeScreen(),
        "/sudoku": (context) => const SudokuScreen(),
      },
    );
  }
}