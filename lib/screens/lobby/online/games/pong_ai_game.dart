// lobby/online/games/pong_ai_game.dart
// Pong против ИИ — адаптивный компьютерный противник

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Константы ────────────────────────────────────────────────────────────────

const double kFieldW    = 400.0;
const double kFieldH    = 600.0;
const double kPaddleW   = 14.0;
const double kPaddleH   = 80.0;
const double kPaddleMrg = 18.0;
const double kBallR     = 10.0;
const double kInitSpeed = 5.5;
const double kMaxSpeed  = 14.0;
const double kSpeedUp   = 0.25;
const int    kWinScore  = 7;

enum PongAIPhase { countdown, playing, scored, gameOver }

class PongAIGameScreen extends StatefulWidget {
  const PongAIGameScreen({super.key});

  @override
  State<PongAIGameScreen> createState() => _PongAIGameScreenState();
}

class _PongAIGameScreenState extends State<PongAIGameScreen>
    with TickerProviderStateMixin {
  final _rng = Random();

  // Позиции
  double _ballX = kFieldW / 2, _ballY = kFieldH / 2;
  double _ballVx = 0, _ballVy = 0;
  double _playerY = kFieldH / 2; // левая ракетка — игрок
  double _aiY     = kFieldH / 2; // правая ракетка — ИИ
  double _touchY  = kFieldH / 2;
  bool   _touching = false;

  int _playerScore = 0, _aiScore = 0;
  int _hitCount = 0;
  PongAIPhase _phase = PongAIPhase.countdown;
  int _countdown = 3;

  Timer? _physicsTimer;
  Timer? _countdownTimer;

  late AnimationController _bgPulse;
  late AnimationController _flashCtrl;
  late Animation<double>   _flashAnim;

  @override
  void initState() {
    super.initState();
    _bgPulse = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat(reverse: true);
    _flashCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    _flashAnim = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut);
    _startCountdown();
  }

  @override
  void dispose() {
    _physicsTimer?.cancel();
    _countdownTimer?.cancel();
    _bgPulse.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  // ── Отсчёт ────────────────────────────────────────────────────────────────

  void _startCountdown() {
    _phase = PongAIPhase.countdown;
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) { t.cancel(); _launchBall(); }
      });
    });
  }

  void _launchBall() {
    _ballX = kFieldW / 2; _ballY = kFieldH / 2;
    final angle = (_rng.nextDouble() * pi / 2 - pi / 4) +
        (_rng.nextBool() ? 0 : pi);
    _ballVx = cos(angle) * kInitSpeed;
    _ballVy = sin(angle) * kInitSpeed;
    _phase = PongAIPhase.playing;
    _hitCount = 0;
    _startPhysics();
  }

  // ── Физика ────────────────────────────────────────────────────────────────

  void _startPhysics() {
    _physicsTimer?.cancel();
    _physicsTimer = Timer.periodic(
        const Duration(milliseconds: 16), _tick);
  }

  void _tick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    if (_phase != PongAIPhase.playing) return;

    setState(() {
      // Игрок (касание пальцем)
      if (_touching) {
        final dy = _touchY - _playerY;
        _playerY += dy.sign * min(9.0, dy.abs());
      }
      _playerY = _playerY.clamp(kPaddleH / 2, kFieldH - kPaddleH / 2);

      // ИИ: следит за мячом с небольшой задержкой и погрешностью
      final aiDiff = _ballY - _aiY;
      // скорость ИИ чуть меньше максимальной — можно обыграть
      final aiSpeed = 6.5;
      _aiY += aiDiff.sign * min(aiSpeed, aiDiff.abs());
      _aiY = _aiY.clamp(kPaddleH / 2, kFieldH - kPaddleH / 2);

      // Мяч
      _ballX += _ballVx;
      _ballY += _ballVy;

      // Верх/низ
      if (_ballY - kBallR <= 0) {
        _ballY = kBallR; _ballVy = _ballVy.abs();
      } else if (_ballY + kBallR >= kFieldH) {
        _ballY = kFieldH - kBallR; _ballVy = -_ballVy.abs();
      }

      // Удар по ракетке игрока (левая)
      final p1X = kPaddleMrg + kPaddleW;
      if (_ballX - kBallR <= p1X &&
          _ballX - kBallR >= kPaddleMrg &&
          (_ballY - _playerY).abs() < kPaddleH / 2 + kBallR) {
        _hitCount++;
        final relY = (_ballY - _playerY) / (kPaddleH / 2);
        final angle = relY * (pi / 3);
        final speed = min(kInitSpeed + _hitCount * kSpeedUp, kMaxSpeed);
        _ballVx = cos(angle) * speed;
        _ballVy = sin(angle) * speed;
        _ballX = p1X + kBallR + 1;
        _flashCtrl.forward(from: 0);
        HapticFeedback.lightImpact();
      }

      // Удар по ракетке ИИ (правая)
      final p2X = kFieldW - kPaddleMrg - kPaddleW;
      if (_ballX + kBallR >= p2X &&
          _ballX + kBallR <= kFieldW - kPaddleMrg &&
          (_ballY - _aiY).abs() < kPaddleH / 2 + kBallR) {
        _hitCount++;
        final relY = (_ballY - _aiY) / (kPaddleH / 2);
        final angle = pi - relY * (pi / 3);
        final speed = min(kInitSpeed + _hitCount * kSpeedUp, kMaxSpeed);
        _ballVx = cos(angle) * speed;
        _ballVy = sin(angle) * speed;
        _ballX = p2X - kBallR - 1;
        _flashCtrl.forward(from: 0);
        HapticFeedback.lightImpact();
      }

      // Очко
      if (_ballX + kBallR < 0) {
        t.cancel(); _aiScore++; _onScore();
      } else if (_ballX - kBallR > kFieldW) {
        t.cancel(); _playerScore++; _onScore();
      }
    });
  }

  void _onScore() {
    HapticFeedback.mediumImpact();
    _touching = false;
    if (_playerScore >= kWinScore || _aiScore >= kWinScore) {
      setState(() => _phase = PongAIPhase.gameOver);
    } else {
      setState(() => _phase = PongAIPhase.scored);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _startCountdown();
      });
    }
  }

  void _resetGame() {
    setState(() {
      _playerScore = 0; _aiScore = 0;
      _playerY = kFieldH / 2; _aiY = kFieldH / 2;
    });
    _startCountdown();
  }

  // ── Касания ───────────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    final local = _toField(e.position);
    if (local == null) return;
    if (local.dx < kFieldW / 2) { // только левая половина
      _touching = true;
      setState(() => _touchY = local.dy);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_touching) return;
    final local = _toField(e.position);
    if (local == null) return;
    setState(() => _touchY = local.dy);
  }

  void _onPointerUp(PointerUpEvent e) => _touching = false;
  void _onPointerCancel(PointerCancelEvent e) => _touching = false;

  Offset? _toField(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final screenW = box.size.width;
    final screenH = box.size.height;
    final offX = (screenW - kFieldW) / 2;
    final offY = (screenH - kFieldH) / 2 + 56;
    return local - Offset(offX, offY);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Listener(
        onPointerDown:   _onPointerDown,
        onPointerMove:   _onPointerMove,
        onPointerUp:     _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildField(),
                    if (_phase == PongAIPhase.countdown) _buildCountdown(),
                    if (_phase == PongAIPhase.gameOver)  _buildGameOver(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF8888AA), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _scoreBlock('ТЫ', _playerScore,
                      const Color(0xFF00E5FF), true),
                  Text('vs',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14)),
                  _scoreBlock('ИИ', _aiScore,
                      const Color(0xFFFF4081), false),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _scoreBlock(String label, int score, Color color, bool isLeft) {
    return Row(
      children: isLeft
          ? [
        Text(label,
            style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13, letterSpacing: 2)),
        const SizedBox(width: 8),
        Text('$score',
            style: TextStyle(
                color: color, fontSize: 30,
                fontWeight: FontWeight.w900)),
      ]
          : [
        Text('$score',
            style: TextStyle(
                color: color, fontSize: 30,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildField() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bgPulse, _flashAnim]),
      builder: (_, __) => CustomPaint(
        size: const Size(kFieldW, kFieldH),
        painter: _PongAIPainter(
          ballX: _ballX, ballY: _ballY,
          playerY: _playerY, aiY: _aiY,
          bgPulse: _bgPulse.value,
          flashAnim: _flashAnim.value,
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _countdown > 0 ? '$_countdown' : 'GO!',
          key: ValueKey(_countdown),
          style: const TextStyle(
            color: Colors.white, fontSize: 96,
            fontWeight: FontWeight.w900, letterSpacing: -2,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final playerWon = _playerScore >= kWinScore;
    final color = playerWon
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFF4081);
    return Container(
      width: kFieldW, height: kFieldH,
      color: Colors.black.withOpacity(0.78),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            playerWon ? '🏆 ПОБЕДА!' : '🤖 ИИ ПОБЕДИЛ!',
            style: TextStyle(
              color: color, fontSize: 36,
              fontWeight: FontWeight.w900, letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_playerScore : $_aiScore',
            style: const TextStyle(
                color: Colors.white54, fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn('СНОВА', color, _resetGame),
              const SizedBox(width: 16),
              _actionBtn('МЕНЮ', const Color(0xFF444466),
                      () => Navigator.pop(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4),
                blurRadius: 18, spreadRadius: 1)
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('◀  ТВОЯ СТОРОНА',
                style: TextStyle(
                    color: const Color(0xFF00E5FF).withOpacity(0.45),
                    fontSize: 11, letterSpacing: 2)),
            Text('до $kWinScore очков',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11)),
            Text('СТОРОНА ИИ  ▶',
                style: TextStyle(
                    color: const Color(0xFFFF4081).withOpacity(0.45),
                    fontSize: 11, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _PongAIPainter extends CustomPainter {
  final double ballX, ballY, playerY, aiY, bgPulse, flashAnim;

  const _PongAIPainter({
    required this.ballX, required this.ballY,
    required this.playerY, required this.aiY,
    required this.bgPulse, required this.flashAnim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Фон
    final rect = Rect.fromLTWH(0, 0, kFieldW, kFieldH);
    canvas.drawRect(rect, Paint()
      ..shader = RadialGradient(
        center: Alignment.center, radius: 1.0,
        colors: [
          Color.lerp(const Color(0xFF0D1B2A),
              const Color(0xFF111827), bgPulse)!,
          const Color(0xFF050508),
        ],
      ).createShader(rect));

    canvas.drawRect(rect, Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Зоны
    canvas.drawRect(
      Rect.fromLTWH(0, 0, kFieldW / 2, kFieldH),
      Paint()..color = const Color(0xFF00E5FF)
          .withOpacity(0.018 + bgPulse * 0.01),
    );
    canvas.drawRect(
      Rect.fromLTWH(kFieldW / 2, 0, kFieldW / 2, kFieldH),
      Paint()..color = const Color(0xFFFF4081)
          .withOpacity(0.018 + bgPulse * 0.01),
    );

    // Центральная линия
    _drawCenterLine(canvas);

    // Ракетки
    _drawPaddle(canvas, kPaddleMrg, playerY, const Color(0xFF00E5FF));
    _drawPaddle(canvas, kFieldW - kPaddleMrg - kPaddleW, aiY,
        const Color(0xFFFF4081));

    // Мяч
    _drawBall(canvas);
  }

  void _drawCenterLine(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2 ..style = PaintingStyle.stroke;
    const dashH = 16.0, gapH = 10.0;
    double y = 0;
    while (y < kFieldH) {
      canvas.drawLine(Offset(kFieldW / 2, y),
          Offset(kFieldW / 2, (y + dashH).clamp(0, kFieldH)), paint);
      y += dashH + gapH;
    }
    canvas.drawCircle(const Offset(kFieldW / 2, kFieldH / 2), 40,
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
  }

  void _drawPaddle(Canvas canvas, double x, double centerY, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, centerY - kPaddleH / 2, kPaddleW, kPaddleH),
      const Radius.circular(kPaddleW / 2),
    );
    canvas.drawRRect(rect, Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawRRect(rect, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(
          x, centerY - kPaddleH / 2, kPaddleW, kPaddleH)));
  }

  void _drawBall(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ballX, ballY + kBallR + 2),
          width: kBallR * 2.2, height: kBallR * 0.5),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    canvas.drawCircle(Offset(ballX, ballY), kBallR + 6, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(ballX, ballY), kBallR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white, const Color(0xFFCCCCCC),
          const Color(0xFF888888)],
      ).createShader(Rect.fromCircle(
          center: Offset(ballX, ballY), radius: kBallR)));
    canvas.drawCircle(
      Offset(ballX - kBallR * 0.3, ballY - kBallR * 0.3),
      kBallR * 0.3,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _PongAIPainter old) => true;
}