import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/levels.dart';
import '../../features/leaderboard/leaderboard_provider.dart';
import '../../core/services/coin_service.dart';
import '../../core/services/user_service.dart';

/// 🎮 ЭКРАНЫ ИГР
import '../../games/solo/memory/memory_screen.dart';
import '../../games/solo/math/math_screen.dart';
import '../../games/solo/clicker/clicker_screen.dart';
import '../../games/solo/tic_tac_toe/tic_tac_toe_screen.dart';
import '../../games/solo/sudoku/sudoku_screen.dart';
import '../../screens/find_diff_screen.dart';

/// 📄 НОВЫЕ ЭКРАНЫ
import '../profile/profile_screen.dart'; import '../lobby/lobby_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  /// 🔥 ФЕЙКОВЫЕ ИГРОКИ (если нет базы)
  final List<Map<String, dynamic>> demoPlayers = [
    {"name": "Kamila", "rating": 1500},
    {"name": "ProGamer", "rating": 1400},
    {"name": "NoobMaster", "rating": 1200},
    {"name": "DarkKnight", "rating": 1100},
    {"name": "Ghost", "rating": 1000},
  ];

  void showLeaderboard() {

    final provider = LeaderboardProvider();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "🏆 Мировой рейтинг",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 250,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

                    stream: provider.getLeaderboard(),

                    builder: (context, snapshot) {

                      /// 🔥 ЕСЛИ НЕТ ДАННЫХ → ПОКАЗЫВАЕМ ФЕЙКОВЫХ
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return ListView.builder(
                          itemCount: demoPlayers.length,
                          itemBuilder: (context, index) {
                            final player = demoPlayers[index];

                            return ListTile(
                              leading: Text(
                                "${index + 1}",
                                style: const TextStyle(color: Colors.white),
                              ),
                              title: Text(
                                player['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                "${player['rating']}",
                                style: const TextStyle(color: Colors.yellow),
                              ),
                            );
                          },
                        );
                      }

                      final players = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {

                          final data = players[index].data();

                          final name = data['name'] ?? 'Player';
                          final rating = data['rating'] ?? 0;

                          return ListTile(
                            leading: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              "$rating",
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
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

      /// 🔥 ГРАДИЕНТ ФОН
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

                        _topButton(Icons.emoji_events, Colors.amber, showLeaderboard), // 🏆

                        const SizedBox(width: 8),

                        _topButton(Icons.store, Colors.orange, () {
                          Navigator.pushNamed(context, "/shop");
                        }),

                        const SizedBox(width: 8),

                        _topButton(Icons.wifi, Colors.green, () {
                          // ✅ Переход на локальные игры
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LobbyScreen()),
                          );
                        }),

                        const SizedBox(width: 8),

                        _topButton(Icons.person, Colors.pink, () {
                          // ✅ Переход на профиль
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        }),
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

              /// 🎮 СЕТКА
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
                              () => openGame(
                            FindDiffScreen(level: levels[0]),
                          )),
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