// lobby/online/games/tug_of_war/tug_of_war_ai.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/services/coin_service.dart';
import '../../../../../core/services/user_service.dart';
import '../../../../../features/leaderboard/leaderboard_provider.dart';
import '../../../../../widgets/win_dialog.dart';

// ── Константы ──────────────────────────────────────────────────────────────
const int _kMaxPos   = 12;   // победа при ±12
const int _kGameSec  = 35;   // длительность раунда (секунды)

// Сложность ИИ
enum AIDifficulty {
  easy(label: 'Лёгкий', emoji: '😊', baseInterval: 1.4, adaptiveFactor: 0.0, color: Color(0xFF00C896)),
  normal(label: 'Нормал', emoji: '🤖', baseInterval: 0.85, adaptiveFactor: 0.3, color: Color(0xFFFFB347)),
  hard(label: 'Хардкор', emoji: '💀', baseInterval: 0.50, adaptiveFactor: 0.65, color: Color(0xFFFF3D3D));

  const AIDifficulty({
    required this.label,
    required this.emoji,
    required this.baseInterval,
    required this.adaptiveFactor,
    required this.color,
  });

  final String label;
  final String emoji;
  final double baseInterval;
  final double adaptiveFactor;
  final Color color;
}

class TugOfWarAIScreen extends StatefulWidget {
  const TugOfWarAIScreen({super.key});

  @override
  State<TugOfWarAIScreen> createState() => _TugOfWarAIScreenState();
}

enum _AIPhase { selectDifficulty, countdown, playing, gameOver }

class _TugOfWarAIScreenState extends State<TugOfWarAIScreen>
    with TickerProviderStateMixin {

  _AIPhase _phase = _AIPhase.selectDifficulty;
  AIDifficulty _difficulty = AIDifficulty.normal;

  double _ropePos   = 0;
  int _countdown    = 3;
  int _timeLeft     = _kGameSec;
  String? _winner;

  // Комбо-система игрока
  int _playerCombo    = 0;
  int _playerTaps     = 0;
  int _aiTaps         = 0;
  DateTime? _lastPlayerTap;
  bool _comboActive   = false;
  int _maxCombo       = 0;

  // Статистика ИИ-адаптации
  double _playerTapRate = 1.0; // тапов в секунду
  int _playerTapsWindow = 0;
  DateTime? _windowStart;

  // Бусты
  bool _playerBoostActive = false;
  bool _aiBoostActive     = false;
  Timer? _playerBoostTimer;
  Timer? _aiBoostTimer;

  Timer? _countdownTimer;
  Timer? _gameTimer;
  Timer? _aiTimer;
  Timer? _tapRateTimer;

  // Анимации
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _comboCtrl;
  late Animation<double> _comboScale;
  late AnimationController _boostCtrl;
  late Animation<double> _boostPulse;
  late AnimationController _ropeWaveCtrl;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: -8, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);

    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _comboScale = Tween<double>(begin: 0.5, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_comboCtrl);

    _boostCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _boostPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _boostCtrl, curve: Curves.easeInOut));

    _ropeWaveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    _tapRateTimer?.cancel();
    _playerBoostTimer?.cancel();
    _aiBoostTimer?.cancel();
    _shakeCtrl.dispose();
    _comboCtrl.dispose();
    _boostCtrl.dispose();
    _ropeWaveCtrl.dispose();
    super.dispose();
  }

  // ── Выбор сложности ──────────────────────────────────────────────────────

  void _selectDifficulty(AIDifficulty d) {
    setState(() {
      _difficulty = d;
      _phase = _AIPhase.countdown;
    });
    _startCountdown();
  }

  // ── Обратный отсчёт ──────────────────────────────────────────────────────

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _phase = _AIPhase.playing);
        _startGame();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ── Игра ─────────────────────────────────────────────────────────────────

  void _startGame() {
    _windowStart = DateTime.now();

    // Таймер игры
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _aiTimer?.cancel();
        _tapRateTimer?.cancel();
        _resolveTimeout();
      } else {
        setState(() => _timeLeft--);
      }
    });

    // Трекер скорости тапов игрока
    _tapRateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_windowStart != null) {
        final elapsed = DateTime.now().difference(_windowStart!).inMilliseconds / 1000.0;
        if (elapsed > 0) {
          _playerTapRate = _playerTapsWindow / elapsed;
          _playerTapsWindow = 0;
          _windowStart = DateTime.now();
        }
      }
    });

    _scheduleAiTap();
  }

  // Адаптивный ИИ: ускоряется если игрок быстро тапает
  void _scheduleAiTap() {
    if (_phase != _AIPhase.playing) return;

    double interval = _difficulty.baseInterval;

    // Адаптация к скорости игрока
    final adaptBoost = (_playerTapRate * _difficulty.adaptiveFactor * 0.15).clamp(0.0, 0.35);
    interval = (interval - adaptBoost).clamp(0.25, 2.5);

    // Ситуационная агрессия: ИИ ускоряется когда проигрывает
    if (_ropePos < -4) {
      interval *= 0.7;
    } else if (_ropePos < -2) {
      interval *= 0.85;
    }

    // Буст ИИ
    if (_aiBoostActive) interval *= 0.55;

    // Небольшой рандом
    final jitter = (_rng.nextDouble() - 0.5) * 0.3;
    interval = (interval + jitter).clamp(0.2, 2.5);

    _aiTimer = Timer(Duration(milliseconds: (interval * 1000).round()), () {
      if (_phase != _AIPhase.playing) return;
      _aiTap();
      _scheduleAiTap();
    });
  }

  void _aiTap() {
    // ИИ иногда делает мощный рывок (двойной тап)
    final isPowerPull = _rng.nextDouble() < 0.08 && _difficulty == AIDifficulty.hard;
    final delta = isPowerPull ? 2.0 : 1.0;

    setState(() {
      _aiTaps++;
      _ropePos = (_ropePos + delta).clamp(-_kMaxPos.toDouble(), _kMaxPos.toDouble());
    });

    // ИИ получает буст каждые 8 тапов подряд
    if (_aiTaps % 8 == 0 && !_aiBoostActive) {
      _aiBoostActive = true;
      _aiBoostTimer?.cancel();
      _aiBoostTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _aiBoostActive = false);
      });
    }

    if (_ropePos >= _kMaxPos) _endGame('🤖 ИИ победил!');
  }

  void _playerTap() {
    if (_phase != _AIPhase.playing) return;

    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final isQuickTap = _lastPlayerTap != null &&
        now.difference(_lastPlayerTap!).inMilliseconds < 600;

    _lastPlayerTap = now;
    _playerTapsWindow++;
    _playerTaps++;

    // Комбо-система
    if (isQuickTap) {
      _playerCombo++;
      if (_playerCombo > _maxCombo) _maxCombo = _playerCombo;
    } else {
      _playerCombo = 0;
    }

    _comboCtrl.forward(from: 0);

    // Буст при комбо >= 6
    if (_playerCombo >= 6 && !_playerBoostActive) {
      _playerBoostActive = true;
      _comboActive = true;
      HapticFeedback.heavyImpact();
      _playerBoostTimer?.cancel();
      _playerBoostTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() {
          _playerBoostActive = false;
          _comboActive = false;
        });
      });
    }

    // Мощный тап при активном бусте
    final delta = _playerBoostActive ? 1.5 : 1.0;

    setState(() {
      _ropePos = (_ropePos - delta).clamp(-_kMaxPos.toDouble(), _kMaxPos.toDouble());
    });

    _ropeWaveCtrl.forward(from: 0);

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
    _tapRateTimer?.cancel();
    _shakeCtrl.forward(from: 0);
    setState(() {
      _phase = _AIPhase.gameOver;
      _winner = result;
    });
    final iWon = result.contains('Ты победил');
    if (iWon) {
      HapticFeedback.heavyImpact();
      _handleReward(won: true);
    } else if (result.contains('Ничья')) {
      _handleReward(won: false, isDraw: true);
    } else {
      _handleReward(won: false);
    }
  }

  Future<void> _handleReward({required bool won, bool isDraw = false}) async {
    final userId = await UserService.getOrCreateUser();
    if (won) {
      CoinService.addCoins(10);
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: true);
      if (mounted) showWinDialog(context);
    } else if (isDraw) {
      CoinService.addCoins(3);
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: false);
    } else {
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: false);
    }
  }

  void _restart() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    _tapRateTimer?.cancel();
    _playerBoostTimer?.cancel();
    _aiBoostTimer?.cancel();
    setState(() {
      _ropePos          = 0;
      _phase            = _AIPhase.selectDifficulty;
      _countdown        = 3;
      _timeLeft         = _kGameSec;
      _winner           = null;
      _playerCombo      = 0;
      _playerTaps       = 0;
      _aiTaps           = 0;
      _maxCombo         = 0;
      _playerBoostActive = false;
      _aiBoostActive    = false;
      _playerTapRate    = 1.0;
      _playerTapsWindow = 0;
    });
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
      body: switch (_phase) {
        _AIPhase.selectDifficulty => _buildDifficultySelect(),
        _AIPhase.gameOver         => _GameOverScreen(
          result: _winner!,
          playerTaps: _playerTaps,
          aiTaps: _aiTaps,
          maxCombo: _maxCombo,
          difficulty: _difficulty,
          onRestart: _restart,
          onExit: () => Navigator.pop(context),
        ),
        _ => Column(
          children: [
            _TopBar(timeLeft: _timeLeft, phase: _phase, countdown: _countdown,
                aiBoostActive: _aiBoostActive),
            const Spacer(),
            _RopeWidget(position: _ropePos, maxPos: _kMaxPos),
            const SizedBox(height: 16),
            _ComboDisplay(combo: _playerCombo, boostActive: _playerBoostActive,
                scaleAnim: _comboScale),
            const Spacer(),
            _TapButton(
              onTap: _playerTap,
              enabled: _phase == _AIPhase.playing,
              boostActive: _playerBoostActive,
              boostPulse: _boostPulse,
            ),
            const SizedBox(height: 48),
          ],
        ),
      },
    );
  }

  Widget _buildDifficultySelect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🤖', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          const Text('Выбери сложность',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('ИИ адаптируется к твоей скорости!',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 40),
          ...AIDifficulty.values.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DifficultyCard(
              difficulty: d,
              onTap: () => _selectDifficulty(d),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Карточка сложности ────────────────────────────────────────────────────────

class _DifficultyCard extends StatefulWidget {
  final AIDifficulty difficulty;
  final VoidCallback onTap;
  const _DifficultyCard({required this.difficulty, required this.onTap});

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _pressed = false;

  String get _desc => switch (widget.difficulty) {
    AIDifficulty.easy   => 'Медленный ИИ • Идеально для новичков',
    AIDifficulty.normal => 'Адаптивный ИИ • Ускоряется когда ты тапаешь быстро',
    AIDifficulty.hard   => 'Безжалостный ИИ • Делает силовые рывки • Очень быстро',
  };

  @override
  Widget build(BuildContext context) {
    final d = widget.difficulty;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1B4E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: d.color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [BoxShadow(color: d.color.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.label, style: TextStyle(color: d.color, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: d.color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Комбо-дисплей ─────────────────────────────────────────────────────────────

class _ComboDisplay extends StatelessWidget {
  final int combo;
  final bool boostActive;
  final Animation<double> scaleAnim;

  const _ComboDisplay({required this.combo, required this.boostActive, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    if (combo < 2 && !boostActive) return const SizedBox(height: 40);

    return ScaleTransition(
      scale: scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: boostActive
              ? const Color(0xFFFFB347).withValues(alpha: 0.2)
              : const Color(0xFF00C896).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: boostActive ? const Color(0xFFFFB347).withValues(alpha: 0.6) : const Color(0xFF00C896).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(boostActive ? '⚡' : '🔥', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              boostActive ? 'БУСТ АКТИВЕН!' : 'КОМБО x$combo',
              style: TextStyle(
                color: boostActive ? const Color(0xFFFFB347) : const Color(0xFF00C896),
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Общие виджеты ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int timeLeft, countdown;
  final _AIPhase phase;
  final bool aiBoostActive;

  const _TopBar({required this.timeLeft, required this.phase,
    required this.countdown, required this.aiBoostActive});

  @override
  Widget build(BuildContext context) {
    final urgent = timeLeft <= 10 && phase == _AIPhase.playing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: urgent ? const Color(0xFF3D1B1B) : const Color(0xFF2D1B4E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('🤖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('ИИ', style: TextStyle(
                color: aiBoostActive ? const Color(0xFFFF3D3D) : Colors.redAccent,
                fontSize: 16, fontWeight: FontWeight.bold)),
            if (aiBoostActive) ...[
              const SizedBox(width: 4),
              const Text('⚡', style: TextStyle(fontSize: 14)),
            ],
          ]),
          phase == _AIPhase.countdown
              ? Text('$countdown', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))
              : Row(children: [
            Icon(Icons.timer, color: urgent ? const Color(0xFFFF3D3D) : Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text('$timeLeft с', style: TextStyle(
                color: urgent ? const Color(0xFFFF3D3D) : Colors.white,
                fontSize: 20, fontWeight: FontWeight.bold)),
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
    final norm  = (position + maxPos) / (2 * maxPos);
    final markerX = norm * (width - 60) + 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [
                    Color(0xFF00C896), Color(0xFF1A0A2E), Color(0xFFFF3D3D),
                  ]),
                ),
              ),
              // Опасные зоны
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: (width - 32) / 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                    color: const Color(0xFF00C896).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                right: 0, top: 0, bottom: 0,
                child: Container(
                  width: (width - 32) / 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                    color: const Color(0xFFFF3D3D).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                left: (width - 64) / 2, top: 0, bottom: 0,
                child: Container(width: 3, color: Colors.white.withValues(alpha: 0.5)),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                left: markerX - 22, top: -10,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: position < 0 ? const Color(0xFF00C896) : const Color(0xFFFF3D3D),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (position < 0 ? const Color(0xFF00C896) : const Color(0xFFFF3D3D)).withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(child: Text('🪢', style: TextStyle(fontSize: 22))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('← Победа',
                  style: TextStyle(color: const Color(0xFF00C896).withValues(alpha: 0.7), fontSize: 12)),
              Text(
                position == 0 ? 'Начни тапать!'
                    : position < 0 ? '💪 +${(-position).toInt()} в твою сторону'
                    : '⚠️ ${position.toInt()} в сторону ИИ',
                style: TextStyle(
                  color: position < 0 ? const Color(0xFF00C896) : Colors.redAccent,
                  fontSize: 14, fontWeight: FontWeight.bold,
                ),
              ),
              Text('Победа →',
                  style: TextStyle(color: const Color(0xFFFF3D3D).withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TapButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool enabled;
  final bool boostActive;
  final Animation<double> boostPulse;

  const _TapButton({
    required this.onTap,
    required this.enabled,
    required this.boostActive,
    required this.boostPulse,
  });

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTap() {
    if (!widget.enabled) return;
    _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.boostActive ? const Color(0xFFFFB347) : const Color(0xFF00C896);
    final darkColor = widget.boostActive ? const Color(0xFFCC8800) : const Color(0xFF007A5E);

    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedBuilder(
          animation: widget.boostPulse,
          builder: (_, child) => Transform.scale(
            scale: widget.boostActive && widget.enabled ? widget.boostPulse.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: widget.enabled
                    ? [baseColor, darkColor]
                    : [Colors.grey.shade700, Colors.grey.shade900],
              ),
              boxShadow: widget.enabled
                  ? [BoxShadow(
                color: baseColor.withValues(alpha: widget.boostActive ? 0.7 : 0.45),
                blurRadius: widget.boostActive ? 50 : 30,
                spreadRadius: widget.boostActive ? 8 : 4,
              )]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.boostActive ? '⚡' : '💪',
                    style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(
                  widget.enabled
                      ? (widget.boostActive ? 'БУСТ!' : 'ТЯН И!')
                      : 'Жди...',
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
      ),
    );
  }
}

// ── Экран конца игры ─────────────────────────────────────────────────────────

class _GameOverScreen extends StatelessWidget {
  final String result;
  final int playerTaps, aiTaps, maxCombo;
  final AIDifficulty difficulty;
  final VoidCallback onRestart, onExit;

  const _GameOverScreen({
    required this.result,
    required this.playerTaps,
    required this.aiTaps,
    required this.maxCombo,
    required this.difficulty,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final iWon  = result.contains('Ты победил');
    final isDraw = result.contains('Ничья');

    return Container(
      color: const Color(0xFF1A0A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isDraw ? '🤝' : (iWon ? '🏆' : '💀'),
                style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              result,
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: isDraw ? Colors.orange : iWon ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(difficulty.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(difficulty.label,
                    style: TextStyle(color: difficulty.color, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 28),

            // Статистика
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1B4E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _StatRow(label: '💪 Твои тапы', value: '$playerTaps'),
                  const SizedBox(height: 8),
                  _StatRow(label: '🤖 Тапы ИИ', value: '$aiTaps'),
                  const SizedBox(height: 8),
                  _StatRow(label: '🔥 Макс комбо', value: 'x$maxCombo'),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Играть снова',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('В меню', style: TextStyle(color: Colors.white38, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}