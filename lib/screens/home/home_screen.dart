import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_center/screens/lobby/lobby_screen.dart';
import '../../data/levels.dart';
import '../../features/leaderboard/leaderboard_provider.dart';
import '../../features/leaderboard/leaderboard_screen.dart'; // ✅ импорт
import '../../core/services/coin_service.dart';
import '../../core/services/user_service.dart';

/// 🎮 ЭКРАНЫ ИГР
import '../../games/solo/memory/memory_screen.dart';
import '../../games/solo/math/math_screen.dart';
import '../../games/solo/clicker/clicker_screen.dart';
import '../../games/solo/tic_tac_toe/tic_tac_toe_screen.dart';
import '../../games/solo/sudoku/sudoku_screen.dart';
import '../../screens/find_diff_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> openGame(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    UserService.getOrCreateUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              /// 🔝 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // Название
                    const Text(
                      "🎮 GameZone",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Все кнопки справа
                    Row(
                      children: [

                        // 🏆 РЕЙТИНГ — ведёт на LeaderboardScreen
                        _topButton(
                          Icons.emoji_events,
                          Colors.amber,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeaderboardScreen(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 🎰 КОЛЕСО УДАЧИ — отдельная кнопка с градиентом
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/spin"),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rotate_right,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 🛒 МАГАЗИН
                        _topButton(Icons.store, Colors.orange, () {
                          Navigator.pushNamed(context, "/shop");
                        }),

                        const SizedBox(width: 8),

                        // 📡 ЛОББИ
                        _topButton(Icons.wifi, Colors.green, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LobbyScreen()),
                          );
                        }),

                        const SizedBox(width: 8),

                        // 👤 ПРОФИЛЬ
                        _topButton(Icons.person, Colors.pink, () async {
                          await Navigator.pushNamed(context, "/profile");
                          setState(() {});
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// 🪙 МОНЕТЫ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.yellow),
                      const SizedBox(width: 8),
                      Text(
                        "${CoinService.getCoins()} монет",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🎮 СЕТКА ИГР
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _gameCard("Память", "assets/memory.png", Colors.purple,
                              () => openGame(const MemoryScreen())),
                      _gameCard("Математика", "assets/math.png", Colors.blue,
                              () => openGame(const MathScreen())),
                      _gameCard("Кликер", "assets/clicker.png", Colors.orange,
                              () => openGame(const ClickerScreen())),
                      _gameCard("Крестики", "assets/tic.png", Colors.green,
                              () => openGame(const TicTacToeScreen())),
                      _gameCard("Судоку", "assets/sudoku.png", Colors.teal,
                              () => openGame(const SudokuScreen())),
                      _gameCard("Найди", "assets/diff.png", Colors.blueGrey,
                              () => openGame(FindDiffScreen(level: levels[0]))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _gameCard(String title, String image, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}