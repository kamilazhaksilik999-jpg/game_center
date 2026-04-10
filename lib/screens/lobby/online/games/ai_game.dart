// lobby/online/games/ai_game.dart
// Игра против ИИ — Маленькие Танки

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ─── Модели ───────────────────────────────────────────────────────────────────

class TankState {
  double x, y;       // позиция (0..1 нормализованная)
  double angle;      // угол поворота в радианах
  int hp;
  bool isPlayer;

  TankState({
    required this.x,
    required this.y,
    required this.angle,
    required this.hp,
    required this.isPlayer,
  });
}

class Bullet {
  double x, y;
  double vx, vy;
  bool fromPlayer;

  Bullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.fromPlayer,
  });
}

// ─── Экран игры против ИИ ─────────────────────────────────────────────────────

class AIGameScreen extends StatefulWidget {
  const AIGameScreen({super.key});

  @override
  State<AIGameScreen> createState() => _AIGameScreenState();
}

class _AIGameScreenState extends State<AIGameScreen> {
  static const int maxHp = 3;
  static const double speed = 0.004;
  static const double bulletSpeed = 0.012;
  static const double bulletRadius = 6;
  static const double tankRadius = 22;

  late TankState player;
  late TankState ai;
  final List<Bullet> bullets = [];

  // Управление игроком
  Offset _joystick = Offset.zero;
  bool _shooting = false;

  Timer? _gameLoop;
  Timer? _aiTimer;
  Timer? _shootTimer;

  bool _gameOver = false;
  bool _playerWon = false;

  final Random _rng = Random();
  double _aiShootCooldown = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    player = TankState(x: 0.5, y: 0.75, angle: -pi / 2, hp: maxHp, isPlayer: true);
    ai     = TankState(x: 0.5, y: 0.25, angle: pi / 2,  hp: maxHp, isPlayer: false);
    bullets.clear();
    _gameOver = false;
    _playerWon = false;

    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 33), _tick); // ~30fps
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _aiTimer?.cancel();
    _shootTimer?.cancel();
    super.dispose();
  }

  // ── Главный игровой цикл ──────────────────────────────────────────────────

  void _tick(Timer _) {
    if (_gameOver) return;
    setState(() {
      _movePlayer();
      _moveAI();
      _moveBullets();
      _checkCollisions();
      _aiShootCooldown -= 0.033;
      if (_aiShootCooldown <= 0) _aiShoot();
    });
  }

  void _movePlayer() {
    if (_joystick == Offset.zero) return;
    final angle = atan2(_joystick.dy, _joystick.dx);
    player.angle = angle;
    player.x = (player.x + cos(angle) * speed).clamp(0.05, 0.95);
    player.y = (player.y + sin(angle) * speed).clamp(0.05, 0.95);
  }

  void _moveAI() {
    // ИИ: двигаться к игроку с небольшим отклонением
    final dx = player.x - ai.x;
    final dy = player.y - ai.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > 0.2) {
      // Приближаемся
      final angle = atan2(dy, dx);
      ai.angle = angle;
      ai.x = (ai.x + cos(angle) * speed * 0.7).clamp(0.05, 0.95);
      ai.y = (ai.y + sin(angle) * speed * 0.7).clamp(0.05, 0.95);
    } else {
      // Стреляем и уходим по кругу
      final strafe = atan2(dy, dx) + pi / 2;
      ai.x = (ai.x + cos(strafe) * speed * 0.5).clamp(0.05, 0.95);
      ai.y = (ai.y + sin(strafe) * speed * 0.5).clamp(0.05, 0.95);
    }

    // Прицел всегда на игрока
    ai.angle = atan2(player.y - ai.y, player.x - ai.x);
  }

  void _aiShoot() {
    bullets.add(Bullet(
      x: ai.x,
      y: ai.y,
      vx: cos(ai.angle) * bulletSpeed,
      vy: sin(ai.angle) * bulletSpeed,
      fromPlayer: false,
    ));
    _aiShootCooldown = 1.5 + _rng.nextDouble(); // стреляет каждые 1.5–2.5 сек
  }

  void _playerShoot() {
    if (_gameOver) return;
    bullets.add(Bullet(
      x: player.x,
      y: player.y,
      vx: cos(player.angle) * bulletSpeed,
      vy: sin(player.angle) * bulletSpeed,
      fromPlayer: true,
    ));
  }

  void _moveBullets() {
    for (final b in bullets) {
      b.x += b.vx;
      b.y += b.vy;
    }
    bullets.removeWhere((b) => b.x < 0 || b.x > 1 || b.y < 0 || b.y > 1);
  }

  void _checkCollisions() {
    final toRemove = <Bullet>[];
    for (final b in bullets) {
      if (b.fromPlayer) {
        // Попал в ИИ?
        final dx = b.x - ai.x;
        final dy = b.y - ai.y;
        if (sqrt(dx*dx + dy*dy) < (tankRadius + bulletRadius) / 500) {
          ai.hp--;
          toRemove.add(b);
          if (ai.hp <= 0) _endGame(playerWon: true);
        }
      } else {
        // Попал в игрока?
        final dx = b.x - player.x;
        final dy = b.y - player.y;
        if (sqrt(dx*dx + dy*dy) < (tankRadius + bulletRadius) / 500) {
          player.hp--;
          toRemove.add(b);
          if (player.hp <= 0) _endGame(playerWon: false);
        }
      }
    }
    bullets.removeWhere(toRemove.contains);
  }

  void _endGame({required bool playerWon}) {
    _gameOver = true;
    _playerWon = playerWon;
    _gameLoop?.cancel();
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Игровое поле
            LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight * 0.65;
              return SizedBox(
                width: w,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    // Арена
                    Positioned(
                      top: 0, left: 0, right: 0,
                      height: h,
                      child: _Arena(
                        player: player,
                        ai: ai,
                        bullets: bullets,
                        width: w,
                        height: h,
                      ),
                    ),

                    // HUD: HP
                    Positioned(
                      top: 12, left: 16, right: 16,
                      child: _HUD(player: player, ai: ai, maxHp: maxHp),
                    ),

                    // Управление — джойстик
                    Positioned(
                      bottom: 40, left: 30,
                      child: _Joystick(
                        onChanged: (v) => setState(() => _joystick = v),
                      ),
                    ),

                    // Кнопка выстрела
                    Positioned(
                      bottom: 60, right: 40,
                      child: GestureDetector(
                        onTapDown: (_) => _playerShoot(),
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF3D3D).withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.circle, color: Colors.white, size: 32),
                        ),
                      ),
                    ),

                    // Game Over overlay
                    if (_gameOver) _GameOverOverlay(
                      won: _playerWon,
                      onRestart: () => setState(_resetGame),
                      onExit: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Виджет Арены ─────────────────────────────────────────────────────────────

class _Arena extends StatelessWidget {
  final TankState player, ai;
  final List<Bullet> bullets;
  final double width, height;

  const _Arena({
    required this.player,
    required this.ai,
    required this.bullets,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFB8945A),
        border: Border.all(color: const Color(0xFF8B6914), width: 8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _TankPainter(player: player, ai: ai, bullets: bullets),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  final TankState player, ai;
  final List<Bullet> bullets;

  _TankPainter({required this.player, required this.ai, required this.bullets});

  @override
  void paint(Canvas canvas, Size size) {
    _drawTank(canvas, size, player, const Color(0xFF00C896));
    _drawTank(canvas, size, ai, const Color(0xFFFF3D3D));
    for (final b in bullets) {
      _drawBullet(canvas, size, b);
    }
  }

  void _drawTank(Canvas canvas, Size size, TankState t, Color color) {
    final cx = t.x * size.width;
    final cy = t.y * size.height;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(t.angle + pi / 2);

    // Корпус
    final bodyPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -18, 28, 36),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Дуло
    final gunPaint = Paint()..color = color.withOpacity(0.85);
    canvas.drawRect(const Rect.fromLTWH(-4, -30, 8, 18), gunPaint);

    // Башня
    canvas.drawCircle(Offset.zero, 10, Paint()..color = color.withOpacity(0.7));

    canvas.restore();
  }

  void _drawBullet(Canvas canvas, Size size, Bullet b) {
    final paint = Paint()
      ..color = b.fromPlayer ? const Color(0xFFFFFF00) : const Color(0xFFFF8800);
    canvas.drawCircle(
      Offset(b.x * size.width, b.y * size.height),
      5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TankPainter old) => true;
}

// ── HUD ──────────────────────────────────────────────────────────────────────

class _HUD extends StatelessWidget {
  final TankState player, ai;
  final int maxHp;

  const _HUD({required this.player, required this.ai, required this.maxHp});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HpRow(label: 'ВЫ', hp: player.hp, max: maxHp, color: const Color(0xFF00C896)),
        _HpRow(label: 'ИИ', hp: ai.hp, max: maxHp, color: const Color(0xFFFF3D3D)),
      ],
    );
  }
}

class _HpRow extends StatelessWidget {
  final String label;
  final int hp, max;
  final Color color;

  const _HpRow({required this.label, required this.hp, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        for (int i = 0; i < max; i++)
          Icon(
            i < hp ? Icons.favorite : Icons.favorite_border,
            color: color,
            size: 20,
          ),
      ],
    );
  }
}

// ── Джойстик ─────────────────────────────────────────────────────────────────

class _Joystick extends StatefulWidget {
  final ValueChanged<Offset> onChanged;

  const _Joystick({required this.onChanged});

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  Offset _delta = Offset.zero;
  static const double _radius = 50;

  void _update(Offset local) {
    final delta = local - const Offset(_radius, _radius);
    final dist = delta.distance;
    final clamped = dist > _radius ? delta / dist * _radius : delta;
    setState(() => _delta = clamped);
    widget.onChanged(clamped / _radius);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) {
        setState(() => _delta = Offset.zero);
        widget.onChanged(Offset.zero);
      },
      child: SizedBox(
        width: _radius * 2,
        height: _radius * 2,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white24),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: _delta,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game Over ─────────────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final bool won;
  final VoidCallback onRestart, onExit;

  const _GameOverOverlay({required this.won, required this.onRestart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🏆 ВЫ ПОБЕДИЛИ!' : '💀 ВЫ ПРОИГРАЛИ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: won ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Играть снова', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('В меню', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}