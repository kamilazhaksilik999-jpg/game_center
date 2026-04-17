// lobby/online/games/tug_of_war/tug_of_war_screen.dart

import 'package:flutter/material.dart';
import 'tug_of_war_ai.dart';
import 'tug_of_war_room.dart';

class TugOfWarScreen extends StatelessWidget {
  const TugOfWarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        leading: BackButton(color: Colors.white54),
        title: const Text(
          '🪢 Перетяни канат',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('🪢', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'Выбери режим',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажимай быстрее — перетяни канат!',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 48),

            _ModeCard(
              icon: '🤖',
              title: 'Против ИИ',
              subtitle: 'Тренируйся против бота',
              color: const Color(0xFF00C896),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TugOfWarAIScreen())),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: '🏠',
              title: 'Играть с другом',
              subtitle: 'Создай комнату или войди по коду',
              color: const Color(0xFF7B5DEF),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TugOfWarRoomScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String icon, title, subtitle;
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
    return GestureDetector(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1B4E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(widget.icon,
                        style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            color: widget.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: widget.color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}