import 'package:flutter/material.dart';

import '../../widgets/game_card.dart';
import '../../core/services/coin_service.dart';

/// 🎮 ЭКРАНЫ ИГР
import '../../games/solo/memory/memory_screen.dart';
import '../../games/solo/math/math_screen.dart';
import '../../games/solo/clicker/clicker_screen.dart';
import '../../games/solo/tic_tac_toe/tic_tac_toe_screen.dart';
import '../../games/solo/sudoku/sudoku_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  /// 🏆 POPUP РЕЙТИНГА
  void showLeaderboard() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "🏆 Мировой рейтинг",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                ListTile(title: Text("1. Player1 - 1200")),
                ListTile(title: Text("2. Player2 - 1000")),
                ListTile(title: Text("3. Player3 - 800")),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔄 ОБНОВЛЕНИЕ ПОСЛЕ ВОЗВРАТА
  Future<void> openGame(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    setState(() {}); // обновляем монеты
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      /// 🔵 APPBAR
      appBar: AppBar(
        title: const Text("Game Center"),
        centerTitle: true,
        backgroundColor: Colors.blue,

        /// 🏆 рейтинг
        leading: IconButton(
          icon: const Icon(Icons.emoji_events),
          onPressed: showLeaderboard,
        ),

        /// 🪙 монеты + иконки
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                "${CoinService.getCoins()} 🪙",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.store), onPressed: () {}),
          IconButton(icon: const Icon(Icons.wifi), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),

      /// 🎮 СЕТКА ИГР
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,

          children: [

            GameCard(
              title: "ПАМЯТЬ",
              image: "assets/memory.png",
              gradient: const [Colors.blue, Colors.lightBlueAccent],
              onTap: () => openGame(const MemoryScreen()),
            ),

            GameCard(
              title: "МАТЕМАТИКА",
              image: "assets/math.png",
              gradient: const [Colors.green, Colors.lightGreen],
              onTap: () => openGame(const MathScreen()),
            ),

            GameCard(
              title: "КЛИКЕР",
              image: "assets/clicker.png",
              gradient: const [Colors.teal, Colors.greenAccent],
              onTap: () => openGame(const ClickerScreen()),
            ),

            GameCard(
              title: "КРЕСТИКИ-НОЛИКИ",
              image: "assets/tic.png",
              gradient: const [Colors.orange, Colors.deepOrange],
              onTap: () => openGame(const TicTacToeScreen()),
            ),

            GameCard(
              title: "СУДОКУ",
              image: "assets/sudoku.png",
              gradient: const [Colors.blueGrey, Colors.grey],
              onTap: () => openGame(const SudokuScreen()),
            ),

            GameCard(
              title: "Найди отличия",
              image: "assets/diff.png",
              gradient: const [Colors.deepPurple, Colors.pinkAccent],
              onTap: () => Navigator.pushNamed(context, "/diff_start"),
            ),
          ],
        ),
      ),
    );
  }
}