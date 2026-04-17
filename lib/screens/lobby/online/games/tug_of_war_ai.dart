// lobby/online/games/tug_of_war/tug_of_war_ai.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Константы ──────────────────────────────────────────────────────────────
const int _kMaxPos    = 10;   // победа при ±10
const int _kGameSec   = 30;   // длительность раунда (секунды)
const double _kAiBase = 0.9;  // средний интервал тапов ИИ (сек)

class TugOfWarAIScreen extends StatefulWidget {
  const TugOfWarAIScreen({super.key});

  @override
  State<TugOfWarAIScreen> createState() => _TugOfWarAIScreenState();
}

enum _AIPhase { countdown, playing, gameOver }

class _TugOfWarAIScreenState extends State<TugOfWarAIScreen>
    with TickerProviderStateMixin {

  // rope position: отрицательное — в сторону игрока, положительное — ИИ
  // диапазон: -_kMaxPos .. +_kMaxPos
  double _ropePos = 0;

  _AIPhase _phase = _AIPhase.countdown;
  int _countdown = 3;
  int _timeLeft  = _kGameSec;
  String? _winner;

  Timer? _countdownTimer;
  Timer? _gameTimer;
  Timer? _aiTimer;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _ropeCtrl;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);

    _ropeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    _shakeCtrl.dispose();
    _ropeCtrl.dispose();
    super.dispose();
  }

  // ── Обратный отсчёт ──────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() { _phase = _AIPhase.playing; });
        _startGame();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ── Игра ─────────────────────────────────────────────────────────────────

  void _startGame() {
    // Таймер игры
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _aiTimer?.cancel();
        _resolveTimeout();
      } else {
        setState(() => _timeLeft--);
      }
    });

    // ИИ тапает с небольшим разбросом
    _scheduleAiTap();
  }

  void _scheduleAiTap() {
    if (_phase != _AIPhase.playing) return;
    final delay = (_kAiBase + (_rng.nextDouble() - 0.5) * 0.4).clamp(0.3, 2.0);
    _aiTimer = Timer(Duration(milliseconds: (delay * 1000).round()), () {
      if (_phase != _AIPhase.playing) return;
      _aiTap();
      _scheduleAiTap();
    });
  }

  void _aiTap() {
    setState(() {
      _ropePos = (_ropePos + 1).clamp(-_kMaxPos.toDouble(), _kMaxPos.toDouble());
    });
    if (_ropePos >= _kMaxPos) _endGame('🤖 ИИ победил!');
  }

  void _playerTap() {
    if (_phase != _AIPhase.playing) return;
    setState(() {
      _ropePos = (_ropePos - 1).clamp(-_kMaxPos.toDouble(), _kMaxPos.toDouble());
    });
    _ropeCtrl.forward(from: 0);
    if (_ropePos <= -_kMaxPos) _endGame('🏆 Ты победил!');
  }

  void _resolveTimeout() {
    if (_phase == _AIPhase.gameOver) return;
    if (_ropePos < 0) {
      _endGame('🏆 Ты победил!');
    } else if (_ropePos > 0) {
      _endGame('🤖 ИИ победил!');
    } else {
      _endGame('🤝 Ничья!');
    }
  }

  void _endGame(String result) {
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    _shakeCtrl.forward(from: 0);
    setState(() {
      _phase = _AIPhase.gameOver;
      _winner = result;
    });
  }

  void _restart() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    setState(() {
      _ropePos   = 0;
      _phase     = _AIPhase.countdown;
      _countdown = 3;
      _timeLeft  = _kGameSec;
      _winner    = null;
    });
    _startCountdown();
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        leading: BackButton(color: Colors.white54),
        title: const Text('🪢 Против ИИ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _phase == _AIPhase.gameOver
          ? _GameOverScreen(
        result: _winner!,
        onRestart: _restart,
        onExit: () => Navigator.pop(context),
      )
          : Column(
        children: [
          // Таймер + счёт
          _TopBar(timeLeft: _timeLeft, phase: _phase, countdown: _countdown),

          const Spacer(),

          // Канат
          _RopeWidget(position: _ropePos, maxPos: _kMaxPos),

          const Spacer(),

          // Кнопка игрока
          _TapButton(onTap: _playerTap, enabled: _phase == _AIPhase.playing),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Общие виджеты ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int timeLeft, countdown;
  final _AIPhase phase;

  const _TopBar({required this.timeLeft, required this.phase, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFF2D1B4E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🤖 ИИ', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          phase == _AIPhase.countdown
              ? Text('$countdown', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))
              : Row(children: [
            const Icon(Icons.timer, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text('$timeLeft с', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const Text('💪 Ты', style: TextStyle(color: Color(0xFF00C896), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RopeWidget extends StatelessWidget {
  final double position;
  final int maxPos;

  const _RopeWidget({required this.position, required this.maxPos});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // нормализация: 0.0 (всё у игрока) .. 1.0 (всё у ИИ)
    final norm = (position + maxPos) / (2 * maxPos);
    // позиция маркера канат
    final markerX = norm * (width - 60) + 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Шкала
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Фон
              Container(
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    const Color(0xFF00C896),
                    const Color(0xFF1A0A2E),
                    const Color(0xFFFF3D3D),
                  ]),
                ),
              ),
              // Центральная метка
              Positioned(
                left: (width - 64) / 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              // Маркер
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                left: markerX - 22,
                top: -8,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF7B5DEF), width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Center(
                    child: Text('🪢', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Зоны победы
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('← Победа твоя',
                  style: TextStyle(color: const Color(0xFF00C896).withOpacity(0.7), fontSize: 12)),
              Text('Победа ИИ →',
                  style: TextStyle(color: const Color(0xFFFF3D3D).withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          // Счётчик тапов
          Text(
            position == 0
                ? 'Начни тапать!'
                : position < 0
                ? '💪 +${(-position).toInt()} в твою сторону'
                : '⚠️ ${position.toInt()} в сторону ИИ',
            style: TextStyle(
              color: position < 0 ? const Color(0xFF00C896) : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TapButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool enabled;
  const _TapButton({required this.onTap, required this.enabled});

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.enabled) return;
    _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: widget.enabled
                  ? [const Color(0xFF00C896), const Color(0xFF007A5E)]
                  : [Colors.grey.shade700, Colors.grey.shade900],
            ),
            boxShadow: widget.enabled
                ? [
              BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4),
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💪', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                widget.enabled ? 'ТЯН И!' : 'Жди...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final String result;
  final VoidCallback onRestart, onExit;

  const _GameOverScreen(
      {required this.result, required this.onRestart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final iWon = result.contains('Ты победил');
    final isDraw = result.contains('Ничья');

    return Container(
      color: const Color(0xFF1A0A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDraw ? '🤝' : (iWon ? '🏆' : '💀'),
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              result,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDraw
                    ? Colors.orange
                    : iWon
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF3D3D),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Играть снова',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('В меню',
                  style: TextStyle(color: Colors.white38, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}