import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/levels.dart';
import '../../features/leaderboard/leaderboard_provider.dart';
import '../../core/services/coin_service.dart';
import '../../core/services/user_service.dart';

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

  final provider = LeaderboardProvider();

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
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              /// 🔝 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "🎮 GameZone",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Row(
                      children: [

                        _topButton(Icons.store, Colors.orange, () {
                          Navigator.pushNamed(context, "/shop");
                        }),

                        const SizedBox(width: 8),

                        _topButton(Icons.wifi, Colors.green, () {}),

                        const SizedBox(width: 8),

                        _topButton(Icons.person, Colors.pink, () {}),
                      ],
                    )
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

              /// 🎮 СЕТКА + РЕЙТИНГ
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [

                      /// 🎮 ИГРЫ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                                    () => openGame(
                                  FindDiffScreen(level: levels[0]),
                                )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🌍 РЕЙТИНГ
                      _leaderboard(),

                      const SizedBox(height: 20),
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

  /// 🔥 РЕЙТИНГ (КРАСИВЫЙ)
  Widget _leaderboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🌍 Мировой рейтинг",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("ТОП 100"),
              )
            ],
          ),

          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: provider.getLeaderboard(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final players = snapshot.data!.docs;

              return Column(
                children: List.generate(players.length, (index) {

                  final data = players[index].data();
                  final name = data['name'] ?? 'Player';
                  final rating = data['rating'] ?? 0;

                  Color color;
                  if (index == 0) color = Colors.amber;
                  else if (index == 1) color = Colors.grey;
                  else if (index == 2) color = Colors.deepOrange;
                  else color = Colors.blueGrey;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [

                        /// место
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// аватар
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            name.toString().substring(0, 2).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// имя
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        /// очки
                        Text(
                          "$rating",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
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

  Widget _gameCard(
      String title,
      String image,
      Color color,
      VoidCallback onTap,
      ) {
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
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}