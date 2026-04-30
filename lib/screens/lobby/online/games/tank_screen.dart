// lobby/online/games/tank_screen.dart
// Главный экран выбора режима игры в танки

import 'package:flutter/material.dart';
import 'ai_game.dart';
import 'room_game.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen>
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
      MaterialPageRoute(builder: (_) => const AIGameScreen()),
    );
  }

  void _goToRoom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoomGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Заголовок
              const Text(
                '🚀 ТАНКИ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD700),
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFF6B00),
                      blurRadius: 20,
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

              // Кнопка: Против ИИ
              _ModeCard(
                icon: '🤖',
                title: 'Против ИИ',
                subtitle: 'Сражайся с умным противником',
                color: const Color(0xFF00C896),
                onTap: () => _goToAI(context),
              ),

              const SizedBox(height: 20),

              // Кнопка: Играть с другом
              _ModeCard(
                icon: '🎮',
                title: 'Играть с другом',
                subtitle: 'Создай комнату или войди по коду',
                color: const Color(0xFF5B8DEF),
                onTap: () => _goToRoom(context),
              ),

              const Spacer(),

              // Версия
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'v1.0.0 · Маленькие Танки',
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
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
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
                    child: Text(widget.icon, style: const TextStyle(fontSize: 28)),
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
                Icon(Icons.arrow_forward_ios_rounded, color: widget.color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}