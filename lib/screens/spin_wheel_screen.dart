import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _rotationAnim;

  bool _isSpinning = false;
  bool _canSpin = true;
  double _currentAngle = 0;
  String? _userId;
  int _currentCoins = 0;

  final List<_Segment> _segments = [
    _Segment('10',   10,  Color(0xFFEF4444), '🪙'),
    _Segment('50',   50,  Color(0xFFF97316), '💰'),
    _Segment('5',    5,   Color(0xFF06B6D4), '🪙'),
    _Segment('100',  100, Color(0xFF3B82F6), '💎'),
    _Segment('25',   25,  Color(0xFF34D399), '🪙'),
    _Segment('500',  500, Color(0xFFA855F7), '👑'),
    _Segment('15',   15,  Color(0xFFF43F5E), '🪙'),
    _Segment('200',  200, Color(0xFF818CF8), '💰'),
  ];

  final List<int> _weights = [30, 20, 35, 5, 25, 1, 28, 8];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpin = prefs.getString('last_spin_date');
    final today = _today();
    _userId = prefs.getString('user_id');

    if (_userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        if (doc.exists) {
          setState(() => _currentCoins = doc.data()?['coins'] ?? 0);
        }
      } catch (_) {}
    }

    setState(() => _canSpin = lastSpin != today);
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  String _timeLeft() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    return '${diff.inHours}ч ${diff.inMinutes % 60}м';
  }

  Future<void> _spin() async {
    if (_isSpinning || !_canSpin) return;
    setState(() => _isSpinning = true);

    final random = Random();
    final total = _weights.reduce((a, b) => a + b);
    int roll = random.nextInt(total);
    int winIndex = 0;
    for (int i = 0; i < _weights.length; i++) {
      roll -= _weights[i];
      if (roll < 0) { winIndex = i; break; }
    }

    final segAngle = (2 * pi) / _segments.length;
    final targetAngle = 2 * pi - (segAngle * winIndex + segAngle / 2);
    final spins = 5 + random.nextInt(3);
    final endAngle = _currentAngle + spins * 2 * pi + targetAngle - (_currentAngle % (2 * pi));

    _controller.duration = const Duration(milliseconds: 4500);
    _rotationAnim = Tween<double>(begin: _currentAngle, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward(from: 0).then((_) async {
      _currentAngle = endAngle % (2 * pi);
      final won = _segments[winIndex].coins;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_spin_date', _today());

      if (_userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({'coins': FieldValue.increment(won)});

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        setState(() => _currentCoins = doc.data()?['coins'] ?? 0);
      }

      setState(() { _isSpinning = false; _canSpin = false; });
      if (mounted) _showResult(won, _segments[winIndex]);
    });
  }

  void _showResult(int coins, _Segment segment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1B35), Color(0xFF060B1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: segment.color.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: segment.color.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Эмодзи с свечением
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: segment.color.withValues(alpha: 0.15),
                  border: Border.all(color: segment.color.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: segment.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(segment.emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                '🎉 Поздравляем!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ты выиграл',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Сумма выигрыша
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      segment.color.withValues(alpha: 0.25),
                      segment.color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: segment.color.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: segment.color.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  '$coins 🪙',
                  style: TextStyle(
                    color: segment.color,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'На счету: $_currentCoins 🪙',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Следующий спин через ${_timeLeft()}',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(height: 20),

              // Кнопка
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [segment.color, segment.color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: segment.color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Забрать! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      // ── AppBar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,

        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
          ).createShader(b),
          child: const Text(
            '🎰 Колесо удачи',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ),
        centerTitle: true,

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$_currentCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFFBBF24), Colors.transparent],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height: 14),

          // ── Статус доступности ──────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _canSpin
                    ? [
                  const Color(0xFF059669).withValues(alpha: 0.2),
                  const Color(0xFF065F46).withValues(alpha: 0.1),
                ]
                    : [
                  const Color(0xFF7F1D1D).withValues(alpha: 0.2),
                  const Color(0xFF450A0A).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _canSpin
                    ? const Color(0xFF34D399).withValues(alpha: 0.5)
                    : const Color(0xFFF43F5E).withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_canSpin
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _canSpin ? Icons.check_circle_rounded : Icons.timer_rounded,
                  color: _canSpin
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF43F5E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _canSpin
                      ? 'Доступно! Крути прямо сейчас 🎉'
                      : 'Следующий спин через ${_timeLeft()}',
                  style: TextStyle(
                    color: _canSpin
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF43F5E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Стрелка-указатель ───────────────────────────────────────
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 4),

          // ── КОЛЕСО ──────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // Внешнее свечение
                  Container(
                    width: 322,
                    height: 322,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.2),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  // Внешнее кольцо (градиент)
                  Container(
                    width: 316,
                    height: 316,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFFBBF24),
                          Color(0xFFF97316),
                          Color(0xFFEF4444),
                          Color(0xFFA855F7),
                          Color(0xFF3B82F6),
                          Color(0xFF06B6D4),
                          Color(0xFF34D399),
                          Color(0xFFFBBF24),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF060B1A),
                      ),
                    ),
                  ),

                  // Само колесо
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final angle = _isSpinning
                          ? _rotationAnim.value
                          : _currentAngle;
                      return Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: 298,
                          height: 298,
                          child: _buildWheelWidget(),
                        ),
                      );
                    },
                  ),

                  // Центральная кнопка SPIN
                  GestureDetector(
                    onTap: _canSpin && !_isSpinning ? _spin : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _canSpin
                            ? const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                        boxShadow: _canSpin
                            ? [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.55),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ]
                            : [],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSpinning
                                ? Icons.autorenew_rounded
                                : Icons.rotate_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          Text(
                            _isSpinning ? '...' : 'SPIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Призы-пилюли ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _segments.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      s.color.withValues(alpha: 0.2),
                      s.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: s.color.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: s.color.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${s.coins}',
                      style: TextStyle(
                        color: s.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Кнопка КРУТИТЬ ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _canSpin && !_isSpinning ? _spin : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: _canSpin
                      ? const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF97316)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                      : const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _canSpin
                      ? [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🎰", style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      _isSpinning
                          ? 'Крутится...'
                          : _canSpin
                          ? 'КРУТИТЬ!'
                          : '⏳  Завтра можно снова',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _canSpin ? Colors.white : Colors.white30,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWheelWidget() {
    final segCount = _segments.length;
    final segAngle = 360 / segCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 298, height: 298,
          decoration: const BoxDecoration(shape: BoxShape.circle),
        ),
        ...List.generate(segCount, (i) {
          return Transform.rotate(
            angle: (segAngle * i) * pi / 180,
            child: ClipPath(
              clipper: _SegmentClipper(segAngle),
              child: Container(
                width: 298, height: 298,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _segments[i].color.withValues(alpha: 0.9),
                      _segments[i].color.withValues(alpha: 0.6),
                    ],
                    center: Alignment.center,
                    radius: 0.9,
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0.2, -1),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Transform.rotate(
                      angle: (segAngle / 2) * pi / 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_segments[i].emoji,
                              style: const TextStyle(fontSize: 14)),
                          Text(
                            '${_segments[i].coins}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        // Разделительные линии
        ...List.generate(segCount, (i) {
          return Transform.rotate(
            angle: (segAngle * i) * pi / 180,
            child: Container(
              width: 1.5, height: 149,
              margin: const EdgeInsets.only(bottom: 149),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SegmentClipper extends CustomClipper<Path> {
  final double angleDeg;
  _SegmentClipper(this.angleDeg);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angleDeg * pi / 180,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Segment {
  final String label;
  final int coins;
  final Color color;
  final String emoji;
  const _Segment(this.label, this.coins, this.color, this.emoji);
}