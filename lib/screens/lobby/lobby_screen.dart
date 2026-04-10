// lobby/lobby_screen.dart
import 'package:flutter/material.dart';
import 'online/online_games_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "🌐 Лобби Онлайн-игр",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _gameCard(context, "🚀 Танки",         Colors.teal,   "tank"),
            const SizedBox(height: 12),
            _gameCard(context, "⚽ Футбол",         Colors.green,  "football"),
            const SizedBox(height: 12),
            _gameCard(context, "🪢 Перетяни канат", Colors.orange, "tug"),
            const SizedBox(height: 12),
            _gameCard(context, "🚢 Морской бой",    Colors.blue,   "seabattle"),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 2))
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Здесь будет список онлайн-игр!",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, String title, Color color, String game) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _ModeSheet(game: game, gameTitle: title, color: color),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 2))
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 16),

          Text(
            gameTitle,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Выбери режим игры",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),

          _modeCard(context, "🤖 Против ИИ",         Colors.teal,   "ai"),
          const SizedBox(height: 10),
          _modeCard(context, "🎲 Случайный соперник", Colors.green,  "random"),
          const SizedBox(height: 10),
          _modeCard(context, "🏠 Создать комнату",    Colors.orange, "room"),
        ],
      ),
    );
  }

  Widget _modeCard(BuildContext context, String title, Color c, String mode) {
    return GestureDetector(
      onTap: () => _go(context, mode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c, width: 2),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}