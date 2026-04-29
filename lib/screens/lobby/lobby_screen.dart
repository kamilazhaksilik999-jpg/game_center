// lobby/lobby_screen.dart
import 'package:flutter/material.dart';
import 'online/online_games_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      // ─── AppBar с видимой кнопкой назад ──────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "ОНЛАЙН",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Лобби",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF06B6D4), Colors.transparent],
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 8),

            // ── Подзаголовок ───────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4, height: 16,
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
                  "ВЫБЕРИ ИГРУ",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Карточки игр ───────────────────────────────────────────
            _gameCard(context, "🚀 Танки",          Colors.teal,             [Color(0xFF0D9488), Color(0xFF134E4A)], "tank"),
            const SizedBox(height: 10),
            _gameCard(context, "⚽ Футбол",          Colors.green,            [Color(0xFF16A34A), Color(0xFF14532D)], "football"),
            const SizedBox(height: 10),
            _gameCard(context, "🪢 Перетяни канат",  const Color(0xFFD97706), [Color(0xFFD97706), Color(0xFF78350F)], "tug"),
            const SizedBox(height: 10),
            _gameCard(context, "🚢 Морской бой",     Colors.blue,             [Color(0xFF1D4ED8), Color(0xFF1E3A8A)], "seabattle"),

            const SizedBox(height: 20),

            // ── Онлайн игроки ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF06B6D4)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "АКТИВНЫЕ ИГРОКИ",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF34D399), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                            const Color(0xFF06B6D4).withValues(alpha: 0.3),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.people_outline_rounded, color: Color(0xFF93C5FD), size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Поиск игроков...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Выбери игру и режим выше",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, String title, Color accent,
      List<Color> gradColors, String game) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _ModeSheet(game: game, gameTitle: title, color: accent),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradColors[0].withValues(alpha: 0.2),
              gradColors[1].withValues(alpha: 0.35),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradColors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  title.split(' ').first,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title.split(' ').skip(1).join(' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: const Text(
                "Играть",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Нижний лист выбора режима ─────────────────────────────────────────────────
class _ModeSheet extends StatelessWidget {
  final String game;
  final String gameTitle;
  final Color color;

  const _ModeSheet({
    required this.game,
    required this.gameTitle,
    required this.color,
  });

  void _go(BuildContext context, String mode) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineGamesScreen(selectedGame: game, selectedMode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ручка
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Название игры с подсветкой
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                gameTitle,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Выбери режим игры",
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _modeCard(context, "🤖", "Против ИИ",           "Сыграй с компьютером",    const Color(0xFF0D9488), "ai"),
            const SizedBox(height: 10),
            _modeCard(context, "🎲", "Случайный соперник",   "Найди живого игрока",     const Color(0xFF16A34A), "random"),
            const SizedBox(height: 10),
            _modeCard(context, "🏠", "Создать комнату",      "Пригласи друга по коду",  const Color(0xFFD97706), "room"),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(BuildContext context, String emoji, String title,
      String sub, Color c, String mode) {
    return GestureDetector(
      onTap: () => _go(context, mode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.withValues(alpha: 0.18),
              const Color(0xFF060B1A).withValues(alpha: 0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: c.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: c, size: 22),
          ],
        ),
      ),
    );
  }
}