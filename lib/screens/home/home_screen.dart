import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/leaderboard/leaderboard_provider.dart';
import '../../widgets/game_card.dart';
import '../../core/services/coin_service.dart';
import '../../core/services/user_service.dart';

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
    final provider = LeaderboardProvider();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5), // ✅ NEW API
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95), // ✅ NEW API
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🏆 Мировой рейтинг",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                /// 🔥 ЖИВОЙ РЕЙТИНГ
                SizedBox(
                  height: 250,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: provider.getLeaderboard(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Ошибка: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Нет игроков"));
                      }

                      final players = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final data = players[index].data();
                          final name = data['name'] ?? 'Player';
                          final rating = data['rating'] ?? 0;

                          return ListTile(
                            leading: Text("${index + 1}"),
                            title: Text(name),
                            trailing: Text("$rating 🏆"),
                          );
                        },
                      );
                    },
                  ),
                ),
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

  /// 🔥 СОЗДАЕМ ПОЛЬЗОВАТЕЛЯ ПРИ ЗАПУСКЕ
  @override
  void initState() {
    super.initState();
    UserService.getOrCreateUser();
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

        leading: IconButton(
          icon: const Icon(Icons.emoji_events),
          onPressed: showLeaderboard,
        ),

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
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () => Navigator.pushNamed(context, "/shop"),
          ),
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () {},
          ),

          /// 👤 ПРОФИЛЬ
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, "/profile");
              setState(() {});
            },
          ),
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