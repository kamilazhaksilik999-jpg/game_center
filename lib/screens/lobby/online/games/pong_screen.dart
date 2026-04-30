// lobby/online/games/pong_screen.dart
// Главный экран выбора режима игры в Pong

import 'package:flutter/material.dart';
import 'pong_ai_game.dart';
import 'pong_room.dart';
import '../online_games_screen.dart'; // для RandomMatchmakingScreen

class PongScreen extends StatefulWidget {
  const PongScreen({super.key});

  @override
  State<PongScreen> createState() => _PongScreenState();
}

class _PongScreenState extends State<PongScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToAI(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PongAIGameScreen()),
    );
  }

  void _goToRandom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PongRandomMatchmakingScreen()),
    );
  }

  void _goToRoom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PongRoomScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Заголовок
              const Text(
                '🏓 PONG',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: Color(0xFF00E5FF),
                      blurRadius: 24,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Выбери режим игры',
                style: TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 60),

              // Против ИИ
              _ModeCard(
                icon: '🤖',
                title: 'Против ИИ',
                subtitle: 'Сражайся с умным компьютером',
                color: const Color(0xFF00C896),
                onTap: () => _goToAI(context),
              ),

              const SizedBox(height: 20),

              // Случайный соперник
              _ModeCard(
                icon: '🎲',
                title: 'Случайный соперник',
                subtitle: 'Найди соперника онлайн',
                color: const Color(0xFFFFD700),
                onTap: () => _goToRandom(context),
              ),

              const SizedBox(height: 20),

              // Комната с другом
              _ModeCard(
                icon: '🎮',
                title: 'Играть с другом',
                subtitle: 'Создай комнату или войди по коду',
                color: const Color(0xFF5B8DEF),
                onTap: () => _goToRoom(context),
              ),

              const Spacer(),

              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'до 7 очков · Настольный теннис',
                  style: TextStyle(
                    color: Color(0xFF444466),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Карточка режима ─────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: widget.color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(widget.icon,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8888AA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: widget.color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Поиск случайного соперника для Pong ─────────────────────────────────────

class PongRandomMatchmakingScreen extends StatefulWidget {
  const PongRandomMatchmakingScreen({super.key});

  @override
  State<PongRandomMatchmakingScreen> createState() =>
      _PongRandomMatchmakingScreenState();
}

class _PongRandomMatchmakingScreenState
    extends State<PongRandomMatchmakingScreen>
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

    // Обновляем точки каждые 500ms
    Stream.periodic(const Duration(milliseconds: 500)).listen((_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });

    // Через 3 сек — переходим к игре против ИИ (заглушка до реального матчмейкинга)
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PongAIGameScreen()),
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
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        leading: const BackButton(color: Colors.white54),
        title: const Text(
          'Поиск соперника',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF00E5FF)
                          .withOpacity(0.4 + _pulse.value * 0.4),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text('🏓', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Ищем соперника${'.' * _dots}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Скоро начнётся игра',
              style: TextStyle(color: Colors.white38, fontSize: 15),
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}