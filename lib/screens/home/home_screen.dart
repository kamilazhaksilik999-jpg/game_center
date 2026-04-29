import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_center/screens/lobby/lobby_screen.dart';
import '../../data/levels.dart';
import '../../features/leaderboard/leaderboard_provider.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
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

  // Данные игровых карточек
  final List<_GameData> _games = [
    _GameData(
      title: "Память",
      subtitle: "Найди пары",
      asset: "assets/memory.png",
      gradient: [Color(0xFF6D28D9), Color(0xFFDB2777)],
      glow: Color(0xFFDB2777),
    ),
    _GameData(
      title: "Математика",
      subtitle: "Реши задачи",
      asset: "assets/math.png",
      gradient: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
      glow: Color(0xFF06B6D4),
    ),
    _GameData(
      title: "Кликер",
      subtitle: "Кликай быстро",
      asset: "assets/clicker.png",
      gradient: [Color(0xFFD97706), Color(0xFFF43F5E)],
      glow: Color(0xFFF43F5E),
    ),
    _GameData(
      title: "Крестики",
      subtitle: "Три в ряд",
      asset: "assets/tic.png",
      gradient: [Color(0xFF059669), Color(0xFF34D399)],
      glow: Color(0xFF34D399),
    ),
    _GameData(
      title: "Судоку",
      subtitle: "Заполни поле",
      asset: "assets/sudoku.png",
      gradient: [Color(0xFF0F766E), Color(0xFF818CF8)],
      glow: Color(0xFF818CF8),
    ),
    _GameData(
      title: "Найди отличия",
      subtitle: "Сравни картинки",
      asset: "assets/diff.png",
      gradient: [Color(0xFF334155), Color(0xFF64748B)],
      glow: Color(0xFF94A3B8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060B1A), Color(0xFF0D1B35)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ─── HEADER ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // Лого
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "GAME",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF818CF8)],
                          ).createShader(b),
                          child: const Text(
                            "ZONE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Иконки справа
                    Row(
                      children: [
                        _headerIcon(
                          icon: Icons.emoji_events_rounded,
                          gradient: [Color(0xFFD97706), Color(0xFFFBBF24)],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => LeaderboardScreen())),
                        ),
                        const SizedBox(width: 8),
                        _headerIcon(
                          icon: Icons.rotate_right_rounded,
                          gradient: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                          onTap: () => Navigator.pushNamed(context, "/spin"),
                        ),
                        const SizedBox(width: 8),
                        _headerIcon(
                          icon: Icons.store_rounded,
                          gradient: [Color(0xFFD97706), Color(0xFFF97316)],
                          onTap: () => Navigator.pushNamed(context, "/shop"),
                        ),
                        const SizedBox(width: 8),
                        _headerIcon(
                          icon: Icons.wifi_rounded,
                          gradient: [Color(0xFF059669), Color(0xFF34D399)],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LobbyScreen())),
                        ),
                        const SizedBox(width: 8),
                        _headerIcon(
                          icon: Icons.person_rounded,
                          gradient: [Color(0xFFDB2777), Color(0xFFF9A8D4)],
                          onTap: () async {
                            await Navigator.pushNamed(context, "/profile");
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ─── МОНЕТЫ ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.monetization_on, color: Color(0xFF92400E), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${CoinService.getCoins()} монет",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.add_circle_outline, color: Color(0xFF93C5FD), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── ЗАГОЛОВОК СЕКЦИИ ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF818CF8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ОДИНОЧНЫЕ ИГРЫ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── СПИСОК ИГР ────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final g = _games[i];
                    return _buildGameCard(
                      data: g,
                      onTap: () {
                        switch (i) {
                          case 0: openGame(const MemoryScreen()); break;
                          case 1: openGame(const MathScreen()); break;
                          case 2: openGame(const ClickerScreen()); break;
                          case 3: openGame(const TicTacToeScreen()); break;
                          case 4: openGame(const SudokuScreen()); break;
                          case 5: openGame(FindDiffScreen(level: levels[0])); break;
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Карточка игры (горизонтальная, во всю ширину) ─────────────────────────
  Widget _buildGameCard({required _GameData data, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              data.gradient[0].withValues(alpha: 0.25),
              data.gradient[1].withValues(alpha: 0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: data.gradient[1].withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: data.glow.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [

            // Иконка/Изображение
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(17),
                  bottomLeft: Radius.circular(17),
                ),
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset(data.asset, fit: BoxFit.contain),
              ),
            ),

            const SizedBox(width: 16),

            // Текст
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: data.gradient[1].withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Стрелка
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: data.gradient),
                boxShadow: [
                  BoxShadow(
                    color: data.glow.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Кнопка в хедере ───────────────────────────────────────────────────────
  Widget _headerIcon({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Модель данных карточки ─────────────────────────────────────────────────
class _GameData {
  final String title;
  final String subtitle;
  final String asset;
  final List<Color> gradient;
  final Color glow;

  const _GameData({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.gradient,
    required this.glow,
  });
}