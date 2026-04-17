import 'package:flutter/material.dart';
import 'games/ai_game.dart';
import 'games/room_game.dart';

import 'games/battleship_ai_screen.dart';
import 'games/battleship_room.dart';

import 'games/tug_of_war_ai.dart';
import 'games/tug_of_war_room.dart';

import 'games/mini_football_screen.dart';

class OnlineGamesScreen extends StatefulWidget {
  final String selectedGame; // "tank" | "football" | "tug" | "seabattle"
  final String selectedMode; // "ai"   | "random"   | "room"

  const OnlineGamesScreen({
    super.key,
    required this.selectedGame,
    required this.selectedMode,
  });

  @override
  State<OnlineGamesScreen> createState() => _OnlineGamesScreenState();
}

class _OnlineGamesScreenState extends State<OnlineGamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  void _navigate() {

    switch (widget.selectedGame) {

    /// 🟢 ТАНКИ
      case 'tank':
        switch (widget.selectedMode) {
          case 'ai':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AIGameScreen()),
            );
            break;

          case 'random':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RandomMatchmakingScreen()),
            );
            break;

          case 'room':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoomGameScreen()),
            );
            break;
        }
        break;

    /// 🔵 МОРСКОЙ БОЙ (ТВОЙ КОД)
      case 'seabattle':
        switch (widget.selectedMode) {
          case 'ai':
          case 'random':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BattleshipAIScreen()),
            );
            break;

          case 'room':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BattleshipRoomScreen()),
            );
            break;
        }
        break;

    /// 🪢 ПЕРЕТЯНИ КАНАТ
      case 'tug':
        switch (widget.selectedMode) {
          case 'ai':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TugOfWarAIScreen()),
            );
            break;

          case 'random':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TugOfWarAIScreen()),
            );
            break;

          case 'room':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TugOfWarRoomScreen()),
            );
            break;
        }
        break;

    /// ⚽ ФУТБОЛ
      case 'football':
        switch (widget.selectedMode) {
          case 'ai':
          case 'random':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FootballGameScreen()),
            );
            break;

          case 'room':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FootballGameScreen()),
            );
            break;
        }
        break;


    /// 🚧 ОСТАЛЬНЫЕ ИГРЫ
      default:
        _showComingSoon();
    }
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('🚧 Скоро!', style: TextStyle(color: Colors.white, fontSize: 22)),
        content: const Text(
          'Эта игра находится в разработке.\nСкоро будет доступна!',
          style: TextStyle(color: Colors.white60, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // закрыть диалог
              Navigator.pop(context); // вернуться в лобби
            },
            child: const Text('Ок', style: TextStyle(color: Colors.tealAccent, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
    );
  }
}

// ── Экран поиска случайного соперника ────────────────────────────────────────

class RandomMatchmakingScreen extends StatefulWidget {
  const RandomMatchmakingScreen({super.key});

  @override
  State<RandomMatchmakingScreen> createState() => _RandomMatchmakingScreenState();
}

class _RandomMatchmakingScreenState extends State<RandomMatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _dots = 0;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Анимация точек
    Stream.periodic(const Duration(milliseconds: 500)).listen((_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });

    // Через 3 сек — запуск игры против ИИ
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AIGameScreen()),
      );
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: BackButton(color: Colors.white54),
        title: const Text('Поиск соперника', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: 0.9 + _pulse.value * 0.15,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.4 + _pulse.value * 0.4),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text('🎲', style: TextStyle(fontSize: 56)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Ищем соперника${'.' * _dots}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Скоро начнётся игра', style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white38, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}