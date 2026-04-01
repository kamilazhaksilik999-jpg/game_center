import 'package:flutter/material.dart';

class GameCard extends StatefulWidget {
  final String title;
  final String image;
  final List<Color> gradient;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.title,
    required this.image,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  double scale = 1.0;

  void _onTapDown(_) => setState(() => scale = 0.95);
  void _onTapUp(_) {
    setState(() => scale = 1.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => scale = 1.0),

      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: scale,

        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// 🖼️ УВЕЛИЧЕННАЯ КАРТИНКА
              Transform.translate(
                offset: const Offset(0, -5),
                child: Image.asset(
                  widget.image,
                  height: MediaQuery.of(context).size.width * 0.25,
                  fit: BoxFit.contain, // 🔥 убирает фон эффект
                ),
              ),

              const SizedBox(height: 10),

              /// 🔤 ТЕКСТ
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}