// football_game.dart
// Футбол: стрелки-прицел, мяч, вратарь-ИИ, счёт

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ─── Константы ────────────────────────────────────────────────────────────────

const double kFieldW = 400.0;
const double kFieldH = 600.0;

const double kGoalW = 200.0;
const double kGoalH = 60.0;
const double kGoalY = 40.0; // верхний край ворот от верха поля

const double kBallR = 16.0;
const double kBallStartX = kFieldW / 2;
const double kBallStartY = kFieldH - 100.0;

const double kKeeperW = 60.0;
const double kKeeperH = 60.0;
const double kKeeperY = kGoalY + kGoalH / 2; // центр вратаря по Y

const double kArrowMaxLen = 90.0;
const double kBallMaxSpeed = 22.0;
const double kGravity = 0.18; // замедление мяча
const double kKeeperSpeed = 4.5;

// ─── Состояния ────────────────────────────────────────────────────────────────

enum MatchPhase { aiming, shooting, scored, missed, saved, result }

// ─── Модель ──────────────────────────────────────────────────────────────────

class FootballGame {
  // Мяч
  Offset ball = const Offset(kBallStartX, kBallStartY);
  Offset ballVel = Offset.zero;
  double ballSpin = 0; // эффект кривизны
  double ballScale = 1.0;

  // Прицел
  Offset? dragStart;
  Offset? dragCurrent;

  // Вратарь
  double keeperX = kFieldW / 2;
  double keeperTargetX = kFieldW / 2;
  bool keeperDive = false;
  double keeperDiveAngle = 0;

  // Игра
  MatchPhase phase = MatchPhase.aiming;
  int playerScore = 0;
  int aiScore = 0;
  int round = 0;
  int maxRounds = 5;
  String? message;

  bool get isOver => round >= maxRounds && phase == MatchPhase.result;
}

// ─── Экран ────────────────────────────────────────────────────────────────────

class FootballGameScreen extends StatefulWidget {
  const FootballGameScreen({super.key});

  @override
  State<FootballGameScreen> createState() => _FootballGameScreenState();
}

class _FootballGameScreenState extends State<FootballGameScreen>
    with TickerProviderStateMixin {
  final _game = FootballGame();
  final _rng = Random();
  Timer? _physicsTimer;

  late AnimationController _bgController;
  late AnimationController _scorePopController;
  late Animation<double> _scorePopAnim;

  bool _showScorePop = false;
  String _scorePopText = '';
  Color _scorePopColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scorePopAnim = CurvedAnimation(
        parent: _scorePopController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _physicsTimer?.cancel();
    _bgController.dispose();
    _scorePopController.dispose();
    super.dispose();
  }

  // ── Ввод ──────────────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails d) {
    if (_game.phase != MatchPhase.aiming) return;
    final local = _toField(d.globalPosition, context);
    if (local == null) return;
    // Только если тащат от мяча
    if ((local - _game.ball).distance < 50) {
      setState(() {
        _game.dragStart = local;
        _game.dragCurrent = local;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_game.phase != MatchPhase.aiming || _game.dragStart == null) return;
    final local = _toField(d.globalPosition, context);
    if (local == null) return;
    setState(() => _game.dragCurrent = local);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_game.phase != MatchPhase.aiming || _game.dragStart == null) return;
    final ds = _game.dragStart!;
    final dc = _game.dragCurrent!;
    final delta = ds - dc; // противоположно тягу → мяч летит туда

    if (delta.distance < 10) {
      setState(() {
        _game.dragStart = null;
        _game.dragCurrent = null;
      });
      return;
    }

    // Нормализованный вектор броска
    final norm = delta / delta.distance;
    final power = (delta.distance / kArrowMaxLen).clamp(0.0, 1.0);
    final speed = power * kBallMaxSpeed;

    // Боковой эффект (spin) зависит от горизонтального смещения
    final spinFactor = delta.dx / kArrowMaxLen;

    setState(() {
      _game.ballVel = norm * speed;
      _game.ballSpin = spinFactor * 2.5;
      _game.phase = MatchPhase.shooting;
      _game.dragStart = null;
      _game.dragCurrent = null;
    });

    // Решение вратаря: куда прыгнуть
    _keeperDecide(norm, power);

    // Запуск физики
    _startPhysics();
  }

  Offset? _toField(Offset global, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    // Найти смещение поля внутри экрана
    // Поле центрировано — нужно вычесть отступ
    final screenW = box.size.width;
    final screenH = box.size.height;
    final fieldOffX = (screenW - kFieldW) / 2;
    final fieldOffY = (screenH - kFieldH) / 2 + 60; // 60 — высота хедера
    return local - Offset(fieldOffX, fieldOffY);
  }

  // ── ИИ вратаря ────────────────────────────────────────────────────────────

  void _keeperDecide(Offset shotDir, double power) {
    // Предсказываем куда летит мяч по X при Y = kGoalY + kGoalH/2
    // Упрощённо: экстраполяция прямой
    final dx = shotDir.dx;
    final dy = shotDir.dy;
    if (dy.abs() < 0.01) return;

    // Время полёта до ворот по Y
    final distY = _game.ball.dy - (kGoalY + kGoalH / 2);
    final t = distY / (shotDir.dy * kBallMaxSpeed * power + 0.001);
    double predictX = _game.ball.dx + shotDir.dx * kBallMaxSpeed * power * t;

    // Добавляем spin к предсказанию
    predictX += _game.ballSpin * 15;

    // Средний уровень: небольшая случайность ± 40px
    predictX += (_rng.nextDouble() - 0.5) * 80;
    predictX = predictX.clamp(
        kFieldW / 2 - kGoalW / 2 + kKeeperW / 2,
        kFieldW / 2 + kGoalW / 2 - kKeeperW / 2);

    _game.keeperTargetX = predictX;
    _game.keeperDive = power > 0.6;
    _game.keeperDiveAngle = predictX < kFieldW / 2 ? -0.4 : 0.4;
  }

  // ── Физика ────────────────────────────────────────────────────────────────

  void _startPhysics() {
    _physicsTimer?.cancel();
    _physicsTimer =
        Timer.periodic(const Duration(milliseconds: 16), _physicsTick);
  }

  void _physicsTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    setState(() {
      // Двигаем мяч
      _game.ballVel = Offset(
        _game.ballVel.dx + _game.ballSpin * 0.05, // spin кривизна
        _game.ballVel.dy,
      );
      _game.ball += _game.ballVel;
      _game.ballVel *= (1 - kGravity * 0.08); // трение воздуха
      _game.ballScale = 1.0 - (_game.ball.dy - kBallStartY).abs() /
          (kFieldH * 4); // перспектива

      // Двигаем вратаря
      final dx = _game.keeperTargetX - _game.keeperX;
      _game.keeperX += dx.sign * min(kKeeperSpeed, dx.abs());

      // Проверяем результат
      _checkBallState(t);
    });
  }

  void _checkBallState(Timer t) {
    final bx = _game.ball.dx;
    final by = _game.ball.dy;

    // Вышел за границу поля
    if (bx < -kBallR || bx > kFieldW + kBallR ||
        by < -kBallR * 2 || by > kFieldH + kBallR) {
      t.cancel();
      _endRound(false, false);
      return;
    }

    // Достиг зоны ворот по Y
    if (by <= kGoalY + kGoalH + kBallR) {
      // В воротах по X?
      final inGoalX = bx >= kFieldW / 2 - kGoalW / 2 + kBallR &&
          bx <= kFieldW / 2 + kGoalW / 2 - kBallR;
      // Вратарь поймал?
      final keeX = _game.keeperX;
      final caught = (bx - keeX).abs() < kKeeperW / 2 + kBallR &&
          by <= kKeeperY + kKeeperH / 2 + kBallR;

      if (caught) {
        t.cancel();
        _endRound(false, true); // сэйв
      } else if (inGoalX && by <= kGoalY + kGoalH) {
        t.cancel();
        _endRound(true, false); // гол!
      } else if (by < kGoalY - kBallR) {
        t.cancel();
        _endRound(false, false); // мимо
      }
    }
  }

  void _endRound(bool scored, bool saved) {
    _game.round++;
    if (scored) {
      _game.playerScore++;
      _game.message = '⚽ ГОЛ!';
      _showPop('⚽ ГОЛ!', const Color(0xFF00E676));
    } else if (saved) {
      _game.aiScore++;
      _game.message = '🧤 СЭЙВ!';
      _showPop('🧤 СЭЙВ!', const Color(0xFFFF5252));
    } else {
      _game.aiScore++;
      _game.message = '❌ МИМО!';
      _showPop('❌ МИМО', const Color(0xFFFFD740));
    }

    final phase =
    _game.round >= _game.maxRounds ? MatchPhase.result : MatchPhase.scored;
    _game.phase = scored ? MatchPhase.scored :
    saved ? MatchPhase.saved : MatchPhase.missed;

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        if (_game.round >= _game.maxRounds) {
          _game.phase = MatchPhase.result;
        } else {
          _resetBall();
        }
      });
    });
  }

  void _showPop(String text, Color color) {
    _scorePopText = text;
    _scorePopColor = color;
    _showScorePop = true;
    _scorePopController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showScorePop = false);
    });
  }

  void _resetBall() {
    _game.ball = const Offset(kBallStartX, kBallStartY);
    _game.ballVel = Offset.zero;
    _game.ballSpin = 0;
    _game.ballScale = 1.0;
    _game.keeperX = kFieldW / 2;
    _game.keeperTargetX = kFieldW / 2;
    _game.keeperDive = false;
    _game.phase = MatchPhase.aiming;
    _game.message = null;
  }

  void _restartGame() {
    setState(() {
      _game.ball = const Offset(kBallStartX, kBallStartY);
      _game.ballVel = Offset.zero;
      _game.ballSpin = 0;
      _game.ballScale = 1.0;
      _game.keeperX = kFieldW / 2;
      _game.keeperTargetX = kFieldW / 2;
      _game.keeperDive = false;
      _game.phase = MatchPhase.aiming;
      _game.playerScore = 0;
      _game.aiScore = 0;
      _game.round = 0;
      _game.message = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildField()),
            _buildHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF8899BB), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Раунды
          Text(
            'Раунд ${_game.round}/${_game.maxRounds}',
            style: const TextStyle(
                color: Color(0xFF8899BB), fontSize: 13, letterSpacing: 1),
          ),
          const Spacer(),
          // Счёт
          _buildScore(),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0D2240)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A5080), width: 1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00B4FF).withOpacity(0.15),
              blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_game.playerScore}',
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(':', style: TextStyle(color: Color(0xFF8899BB), fontSize: 22)),
          ),
          Text(
            '${_game.aiScore}',
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField() {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Поле
            SizedBox(
              width: kFieldW,
              height: kFieldH,
              child: CustomPaint(
                painter: _FieldPainter(
                  game: _game,
                ),
              ),
            ),
            // Pop-up текст гол/сейв
            if (_showScorePop)
              ScaleTransition(
                scale: _scorePopAnim,
                child: Text(
                  _scorePopText,
                  style: TextStyle(
                    color: _scorePopColor,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                          color: _scorePopColor.withOpacity(0.7),
                          blurRadius: 30),
                    ],
                  ),
                ),
              ),
            // Финальный экран
            if (_game.phase == MatchPhase.result) _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final win = _game.playerScore > _game.aiScore;
    final draw = _game.playerScore == _game.aiScore;
    final title = draw ? '🤝 НИЧЬЯ!' : win ? '🏆 ПОБЕДА!' : '😔 ПОРАЖЕНИЕ';
    final color = draw
        ? const Color(0xFFFFD740)
        : win
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);

    return Container(
      width: kFieldW,
      height: kFieldH,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: color.withOpacity(0.6), blurRadius: 24)
                  ])),
          const SizedBox(height: 12),
          Text(
            '${_game.playerScore} : ${_game.aiScore}',
            style: const TextStyle(
                color: Colors.white70, fontSize: 32, letterSpacing: 6),
          ),
          const SizedBox(height: 32),
          _GlowButton(
            label: 'ИГРАТЬ СНОВА',
            color: const Color(0xFF00B4FF),
            onTap: _restartGame,
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    if (_game.phase != MatchPhase.aiming) return const SizedBox(height: 48);
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        '👆 Тяни стрелку от мяча, чтобы ударить',
        style: TextStyle(
            color: Color(0xFF4A6A8A), fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }
}

// ─── CustomPainter поля ──────────────────────────────────────────────────────

class _FieldPainter extends CustomPainter {
  final FootballGame game;
  _FieldPainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);
    _drawGoal(canvas);
    _drawKeeper(canvas);
    _drawBall(canvas);
    if (game.phase == MatchPhase.aiming) _drawArrow(canvas);
    _drawShadows(canvas);
  }

  void _drawField(Canvas canvas, Size size) {
    // Зелёное поле с разметкой
    final fieldRect =
    RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));

    // Основной цвет поля
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(fieldRect, grassPaint);

    // Полоски травы
    final stripePaint = Paint()
      ..color = const Color(0xFF1A5C1E)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH(0, i * size.height / 8, size.width, size.height / 8),
            stripePaint);
      }
    }
    canvas.clipRRect(fieldRect);

    // Центральный круг
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.65), 60, linePaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), linePaint);

    // Штрафная зона
    final penaltyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 30),
      width: 200,
      height: 140,
    );
    canvas.drawRect(penaltyRect, linePaint);

    // Точка пенальти
    canvas.drawCircle(
        Offset(size.width / 2, kBallStartY), 4, Paint()..color = Colors.white30);
  }

  void _drawGoal(Canvas canvas) {
    final goalLeft = kFieldW / 2 - kGoalW / 2;
    final goalRect = Rect.fromLTWH(goalLeft, kGoalY, kGoalW, kGoalH);

    // Сетка
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = goalLeft; x <= goalLeft + kGoalW; x += 15) {
      canvas.drawLine(Offset(x, kGoalY), Offset(x, kGoalY + kGoalH), netPaint);
    }
    for (double y = kGoalY; y <= kGoalY + kGoalH; y += 12) {
      canvas.drawLine(
          Offset(goalLeft, y), Offset(goalLeft + kGoalW, y), netPaint);
    }

    // Штанги
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(goalLeft, kGoalY), Offset(goalLeft, kGoalY + kGoalH), postPaint);
    canvas.drawLine(Offset(goalLeft + kGoalW, kGoalY),
        Offset(goalLeft + kGoalW, kGoalY + kGoalH), postPaint);
    canvas.drawLine(
        Offset(goalLeft, kGoalY), Offset(goalLeft + kGoalW, kGoalY), postPaint);

    // Блик на штанге
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(goalLeft + 2, kGoalY + 4),
        Offset(goalLeft + 2, kGoalY + kGoalH - 4),
        glossPaint);

    // Тень ворот
    canvas.drawRect(
      goalRect,
      Paint()..color = Colors.black.withOpacity(0.15),
    );
  }

  void _drawKeeper(Canvas canvas) {
    final kx = game.keeperX;
    final ky = kKeeperY;

    canvas.save();
    canvas.translate(kx, ky);

    if (game.keeperDive &&
        game.phase == MatchPhase.shooting ||
        game.phase == MatchPhase.saved) {
      canvas.rotate(game.keeperDiveAngle);
    }

    // Тень
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, kKeeperH / 2 + 4), width: 40, height: 10),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Тело — жёлтая форма вратаря
    final bodyPaint = Paint()..color = const Color(0xFFFFD600);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 8), width: 32, height: 34),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Перчатки
    final glovePaint = Paint()..color = const Color(0xFFFF6F00);
    canvas.drawCircle(const Offset(-20, 6), 9, glovePaint);
    canvas.drawCircle(const Offset(20, 6), 9, glovePaint);

    // Голова
    final headPaint = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(const Offset(0, -16), 14, headPaint);

    // Волосы
    final hairPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -18), width: 28, height: 20),
      pi,
      pi,
      false,
      hairPaint,
    );

    // Глаза
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(const Offset(-5, -17), 2.5, eyePaint);
    canvas.drawCircle(const Offset(5, -17), 2.5, eyePaint);

    // Ноги
    final legPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-14, 24, 12, 20),
        const Radius.circular(4),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 24, 12, 20),
        const Radius.circular(4),
      ),
      legPaint,
    );

    // Бутсы
    final bootPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-16, 40, 14, 8),
        const Radius.circular(3),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 40, 14, 8),
        const Radius.circular(3),
      ),
      bootPaint,
    );

    canvas.restore();
  }

  void _drawBall(Canvas canvas) {
    final bx = game.ball.dx;
    final by = game.ball.dy;
    final scale = game.ballScale.clamp(0.4, 1.2);
    final r = kBallR * scale;

    canvas.save();
    canvas.translate(bx, by);

    // Тень мяча
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, r + 4), width: r * 2.2, height: r * 0.6),
      Paint()..color = Colors.black.withOpacity(0.22 * scale),
    );

    // Мяч
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white, const Color(0xFFDDDDDD), const Color(0xFF888888)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, ballPaint);

    // Пятиугольники мяча
    final pentPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    _drawBallPattern(canvas, r, pentPaint);

    // Блик
    canvas.drawCircle(
      Offset(-r * 0.3, -r * 0.35),
      r * 0.25,
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    canvas.restore();
  }

  void _drawBallPattern(Canvas canvas, double r, Paint paint) {
    // Упрощённый узор мяча — центральный гексагон + несколько угловых
    final path = Path();
    void hex(double cx, double cy, double size) {
      for (int i = 0; i < 6; i++) {
        final a = pi / 3 * i - pi / 6;
        final px = cx + cos(a) * size;
        final py = cy + sin(a) * size;
        i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      path.close();
    }

    hex(0, 0, r * 0.38);
    canvas.drawPath(path, paint);
    final path2 = Path();
    hex(r * 0.58, -r * 0.35, r * 0.22);
    hex(-r * 0.58, -r * 0.35, r * 0.22);
    hex(0, r * 0.6, r * 0.22);
    canvas.drawPath(path2, paint);
  }

  void _drawArrow(Canvas canvas) {
    if (game.dragStart == null || game.dragCurrent == null) return;
    final from = game.ball;
    final rawDelta = game.dragStart! - game.dragCurrent!;
    if (rawDelta.distance < 8) return;

    final clampedLen = rawDelta.distance.clamp(0.0, kArrowMaxLen);
    final dir = rawDelta / rawDelta.distance;
    final to = from + dir * clampedLen;

    // Цвет стрелки по мощности
    final power = clampedLen / kArrowMaxLen;
    final arrowColor = Color.lerp(
        const Color(0xFF00E676), const Color(0xFFFF5252), power)!;

    // Линия
    final arrowPaint = Paint()
      ..color = arrowColor.withOpacity(0.9)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Пунктир
    final dashes = <Offset>[];
    const dashLen = 10.0;
    const gapLen = 5.0;
    double d = 0;
    bool drawing = true;
    final total = (to - from).distance;
    final step = dir;
    Offset cur = from;
    while (d < total) {
      if (drawing) {
        final end = from + step * (d + dashLen).clamp(0.0, total);
        canvas.drawLine(cur, end, arrowPaint);
        cur = end;
        d += dashLen;
      } else {
        cur = from + step * d;
        d += gapLen;
      }
      drawing = !drawing;
    }

    // Наконечник стрелки
    final headLen = 18.0;
    final headAngle = pi / 5;
    final angle = atan2(dir.dy, dir.dx);
    final tipPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      to,
      to - Offset(cos(angle - headAngle), sin(angle - headAngle)) * headLen,
      tipPaint,
    );
    canvas.drawLine(
      to,
      to - Offset(cos(angle + headAngle), sin(angle + headAngle)) * headLen,
      tipPaint,
    );

    // Круг на конце стрелки
    canvas.drawCircle(to, 5, Paint()..color = arrowColor);

    // Мощность — дуга вокруг мяча
    final arcPaint = Paint()
      ..color = arrowColor.withOpacity(0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: from, radius: kBallR + 8),
      -pi / 2,
      2 * pi * power,
      false,
      arcPaint,
    );
  }

  void _drawShadows(Canvas canvas) {
    // Нижняя виньетка
    canvas.drawRect(
      Rect.fromLTWH(0, kFieldH - 60, kFieldW, 60),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.25)],
        ).createShader(Rect.fromLTWH(0, kFieldH - 60, kFieldW, 60)),
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}

// ─── Кнопка с свечением ───────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
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
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}