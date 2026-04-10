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
    _Segment('10',   10,  Color(0xFFFF6B6B), '🪙'),
    _Segment('50',   50,  Color(0xFFFFB347), '💰'),
    _Segment('5',    5,   Color(0xFF4ECDC4), '🪙'),
    _Segment('100',  100, Color(0xFF45B7D1), '💎'),
    _Segment('25',   25,  Color(0xFF96CEB4), '🪙'),
    _Segment('500',  500, Color(0xFFDDA0DD), '👑'),
    _Segment('15',   15,  Color(0xFFFF9FF3), '🪙'),
    _Segment('200',  200, Color(0xFF54A0FF), '💰'),
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

    // Загружаем монеты из Firebase
    if (_userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        if (doc.exists) {
          setState(() {
            _currentCoins = doc.data()?['coins'] ?? 0;
          });
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
      if (roll < 0) {
        winIndex = i;
        break;
      }
    }

    final segAngle = (2 * pi) / _segments.length;
    // Стрелка сверху — вычисляем куда нужно повернуть
    final targetAngle = 2 * pi - (segAngle * winIndex + segAngle / 2);
    final spins = 5 + random.nextInt(3);
    final endAngle = _currentAngle + spins * 2 * pi + targetAngle - (_currentAngle % (2 * pi));

    _controller.duration = const Duration(milliseconds: 4500);
    _rotationAnim = Tween<double>(
      begin: _currentAngle,
      end: endAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0).then((_) async {
      _currentAngle = endAngle % (2 * pi);
      final won = _segments[winIndex].coins;

      // ✅ Сохраняем дату — больше нельзя крутить сегодня
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_spin_date', _today());

      // ✅ Начисляем монеты в Firebase
      if (_userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({'coins': FieldValue.increment(won)});

        // Обновляем локально
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        setState(() {
          _currentCoins = doc.data()?['coins'] ?? 0;
        });
      }

      setState(() {
        _isSpinning = false;
        _canSpin = false;
      });

      if (mounted) _showResult(won, _segments[winIndex]);
    });
  }

  void _showResult(int coins, _Segment segment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: segment.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: segment.color.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(segment.emoji,
                  style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text('🎉 Поздравляем!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ты выиграл',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: segment.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: segment.color),
                ),
                child: Text(
                  '$coins 🪙',
                  style: TextStyle(
                      color: segment.color,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Монет на счету: $_currentCoins 🪙',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Следующий спин через ${_timeLeft()}',
                style:
                const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: segment.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Забрать! 🎉',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('🎰 Колесо удачи',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$_currentCoins 🪙',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── Статус ──────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: _canSpin
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                _canSpin ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _canSpin ? Icons.check_circle : Icons.timer,
                  color:
                  _canSpin ? Colors.greenAccent : Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _canSpin
                      ? 'Доступно! Крути прямо сейчас 🎉'
                      : 'Следующий спин через ${_timeLeft()}',
                  style: TextStyle(
                    color: _canSpin
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Стрелка ──────────────────────────
          const Icon(Icons.arrow_drop_down,
              color: Colors.orange, size: 48),

          // ── КОЛЕСО через Transform.rotate ───
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Свечение
                  Container(
                    width: 310,
                    height: 310,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.orange.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  // Золотое кольцо
                  Container(
                    width: 308,
                    height: 308,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.amber, width: 5),
                    ),
                  ),

                  // Колесо — сегменты через AnimatedBuilder
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final angle = _isSpinning
                          ? _rotationAnim.value
                          : _currentAngle;
                      return Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: 295,
                          height: 295,
                          child: _buildWheelWidget(),
                        ),
                      );
                    },
                  ),

                  // Центральная кнопка
                  GestureDetector(
                    onTap: _canSpin && !_isSpinning ? _spin : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canSpin
                            ? Colors.orange
                            : const Color(0xFF334155),
                        boxShadow: _canSpin
                            ? [
                          BoxShadow(
                            color: Colors.orange
                                .withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                            : [],
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSpinning
                                ? Icons.autorenew
                                : Icons.rotate_right,
                            color: Colors.white,
                            size: 22,
                          ),
                          Text(
                            _isSpinning ? '...' : 'SPIN',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Призы ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _segments
                  .map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: s.color.withValues(alpha: 0.5)),
                ),
                child: Text('${s.coins} 🪙',
                    style: TextStyle(
                        color: s.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Кнопка ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                _canSpin && !_isSpinning ? _spin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  disabledBackgroundColor:
                  Colors.grey.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: _canSpin ? 8 : 0,
                  shadowColor:
                  Colors.orange.withValues(alpha: 0.5),
                ),
                child: Text(
                  _isSpinning
                      ? '🎰  Крутится...'
                      : _canSpin
                      ? '🎰  КРУТИТЬ!'
                      : '⏳  Завтра можно снова',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Колесо через Stack + Transform ──────────
  Widget _buildWheelWidget() {
    final segCount = _segments.length;
    final segAngle = 360 / segCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Круг-фон
        Container(
          width: 295,
          height: 295,
          decoration: const BoxDecoration(shape: BoxShape.circle),
        ),

        // Сегменты через ClipPath
        ...List.generate(segCount, (i) {
          return Transform.rotate(
            angle: (segAngle * i) * pi / 180,
            child: ClipPath(
              clipper: _SegmentClipper(segAngle),
              child: Container(
                width: 295,
                height: 295,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _segments[i].color,
                ),
                child: Align(
                  alignment: const Alignment(0.2, -1), // 👉 сдвиг вправо
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28),
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
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4)
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

        // Белые разделительные линии
        ...List.generate(segCount, (i) {
          return Transform.rotate(
            angle: (segAngle * i) * pi / 180,
            child: Container(
              width: 2,
              height: 147,
              margin: const EdgeInsets.only(bottom: 147),
              color: Colors.white.withValues(alpha: 0.4),
            ),
          );
        }),
      ],
    );
  }
}

// ── Clipper для сегмента ─────────────────────
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

// ── Модель ───────────────────────────────────
class _Segment {
  final String label;
  final int coins;
  final Color color;
  final String emoji;
  const _Segment(this.label, this.coins, this.color, this.emoji);
} //рофиль