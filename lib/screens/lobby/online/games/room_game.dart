// lobby/online/games/room_game.dart
// Онлайн игра с другом — создание/вход в комнату по коду

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ВАЖНО: Здесь используется Firebase Firestore для синхронизации.
// Добавь в pubspec.yaml:
//   firebase_core: ^2.27.0F
//   cloud_firestore: ^4.17.0
// И настрой Firebase проект через flutterfire configure.
// ─────────────────────────────────────────────────────────────────────────────

// Заглушка Firestore для демонстрации структуры.
// Замени на реальный import 'package:cloud_firestore/cloud_firestore.dart';
// и убери класс _FakeFirestore ниже.

// ── Экран выбора: создать или войти ──────────────────────────────────────────

class RoomGameScreen extends StatefulWidget {
  const RoomGameScreen({super.key});

  @override
  State<RoomGameScreen> createState() => _RoomGameScreenState();
}

class _RoomGameScreenState extends State<RoomGameScreen> {
  final _codeController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Генерируем 6-значный код комнаты
  String _generateCode() {
    const chars = '123456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    // ── Firebase: создать документ комнаты ──
    // await FirebaseFirestore.instance.collection('tank_rooms').doc(code).set({
    //   'host': 'player1',
    //   'guest': null,
    //   'status': 'waiting',       // waiting | playing | finished
    //   'host_x': 0.5, 'host_y': 0.75,   'host_angle': -pi/2, 'host_hp': 3,
    //   'guest_x': 0.5, 'guest_y': 0.25, 'guest_angle': pi/2,  'guest_hp': 3,
    //   'bullets': [],
    //   'created_at': FieldValue.serverTimestamp(),
    // });

    await Future.delayed(const Duration(milliseconds: 600)); // симуляция
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _WaitingRoomScreen(code: code, isHost: true),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Введи 6-значный код комнаты');
      return;
    }
    setState(() { _loading = true; _error = null; });

    // ── Firebase: проверить и обновить комнату ──
    // final doc = await FirebaseFirestore.instance.collection('tank_rooms').doc(code).get();
    // if (!doc.exists || doc['status'] != 'waiting') {
    //   setState(() { _error = 'Комната не найдена или уже занята'; _loading = false; });
    //   return;
    // }
    // await FirebaseFirestore.instance.collection('tank_rooms').doc(code).update({
    //   'guest': 'player2',
    //   'status': 'playing',
    // });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OnlineTankGame(code: code, isHost: false),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white54),
        title: const Text('Играть с другом',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Иконка
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8DEF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🎮', style: TextStyle(fontSize: 44))),
            ),

            const SizedBox(height: 28),

            // Кнопка: создать комнату
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createRoom,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text('Создать комнату', style: TextStyle(fontSize: 17)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8DEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Разделитель
            Row(children: [
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('или', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ]),

            const SizedBox(height: 28),

            // Поле ввода кода
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 24, letterSpacing: 6),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white54, width: 2),
                ),
                errorText: _error,
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка: войти в комнату
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _joinRoom,
                icon: const Icon(Icons.login_rounded, size: 22),
                label: const Text('Войти в комнату', style: TextStyle(fontSize: 17)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(color: Color(0xFF5B8DEF)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Экран ожидания (хост ждёт гостя) ─────────────────────────────────────────

class _WaitingRoomScreen extends StatefulWidget {
  final String code;
  final bool isHost;

  const _WaitingRoomScreen({required this.code, required this.isHost});

  @override
  State<_WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<_WaitingRoomScreen> {
  bool _guestJoined = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _listenForGuest();
  }

  void _listenForGuest() {
    // ── Firebase: слушаем статус комнаты ──
    // _sub = FirebaseFirestore.instance
    //     .collection('tank_rooms')
    //     .doc(widget.code)
    //     .snapshots()
    //     .listen((snap) {
    //   if (snap['status'] == 'playing') {
    //     setState(() => _guestJoined = true);
    //     Future.delayed(const Duration(seconds: 1), () {
    //       if (mounted) Navigator.pushReplacement(context,
    //         MaterialPageRoute(builder: (_) => OnlineTankGame(code: widget.code, isHost: true)));
    //     });
    //   }
    // });

    // Симуляция для демонстрации — убери в реальном приложении
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _guestJoined = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => OnlineTankGame(code: widget.code, isHost: true)));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            const Text('Твоя комната', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 12),

            // Код комнаты
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Код скопирован!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5B8DEF), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.copy, color: Colors.white38, size: 22),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text('Нажми на код чтобы скопировать',
                style: TextStyle(color: Colors.white24, fontSize: 12)),

            const SizedBox(height: 40),

            if (!_guestJoined) ...[
              const CircularProgressIndicator(color: Color(0xFF5B8DEF)),
              const SizedBox(height: 20),
              const Text('Ожидаем друга...', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ] else ...[
              const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 48),
              const SizedBox(height: 16),
              const Text('Друг подключился! Начинаем...', style: TextStyle(color: Color(0xFF00C896), fontSize: 16)),
            ],

            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Онлайн игра (синхронизация через Firestore) ───────────────────────────────

class OnlineTankGame extends StatefulWidget {
  final String code;
  final bool isHost; // true = хост (зелёный, снизу), false = гость (красный, сверху)

  const OnlineTankGame({super.key, required this.code, required this.isHost});

  @override
  State<OnlineTankGame> createState() => _OnlineTankGameState();
}

class _OnlineTankGameState extends State<OnlineTankGame> {
  // Позиции и HP
  double myX = 0.5, myY = 0.75, myAngle = -pi / 2;
  double oppX = 0.5, oppY = 0.25, oppAngle = pi / 2;
  int myHp = 3, oppHp = 3;

  // Пули — список Map для Firestore
  final List<_OBullet> _bullets = [];

  Offset _joystick = Offset.zero;
  Timer? _gameLoop;
  StreamSubscription? _sub;

  bool _gameOver = false;
  bool? _iWon;

  static const double speed = 0.004;
  static const double bulletSpeed = 0.012;

  @override
  void initState() {
    super.initState();
    if (!widget.isHost) {
      myY = 0.25; myAngle = pi / 2;
      oppY = 0.75; oppAngle = -pi / 2;
    }
    _listenFirestore();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), _tick);
  }

  void _listenFirestore() {
    // ── Firebase: подписка на изменения состояния комнаты ──
    // _sub = FirebaseFirestore.instance
    //     .collection('tank_rooms')
    //     .doc(widget.code)
    //     .snapshots()
    //     .listen((snap) {
    //   if (!mounted) return;
    //   setState(() {
    //     final String myPrefix  = widget.isHost ? 'host' : 'guest';
    //     final String oppPrefix = widget.isHost ? 'guest' : 'host';
    //     myHp  = snap['${myPrefix}_hp']  ?? 3;
    //     oppHp = snap['${oppPrefix}_hp'] ?? 3;
    //     oppX  = snap['${oppPrefix}_x']  ?? 0.5;
    //     oppY  = snap['${oppPrefix}_y']  ?? 0.25;
    //     oppAngle = snap['${oppPrefix}_angle'] ?? pi/2;
    //     // Разбор пуль из Firestore
    //     final raw = snap['bullets'] as List? ?? [];
    //     _bullets
    //       ..clear()
    //       ..addAll(raw.map((b) => _OBullet.fromMap(b)));
    //     if (myHp <= 0)  _endGame(false);
    //     if (oppHp <= 0) _endGame(true);
    //   });
    // });
  }

  void _tick(Timer _) {
    if (_gameOver) return;
    setState(() {
      // Движение
      if (_joystick != Offset.zero) {
        myAngle = atan2(_joystick.dy, _joystick.dx);
        myX = (myX + cos(myAngle) * speed).clamp(0.05, 0.95);
        myY = (myY + sin(myAngle) * speed).clamp(0.05, 0.95);
      }

      // Движение пуль
      for (final b in _bullets) {
        b.x += b.vx;
        b.y += b.vy;
      }
      _bullets.removeWhere((b) => b.x < 0 || b.x > 1 || b.y < 0 || b.y > 1);

      // Пуля от оппонента попала?
      _bullets.removeWhere((b) {
        if (b.fromHost == widget.isHost) return false; // своя пуля
        final dx = b.x - myX;
        final dy = b.y - myY;
        if (sqrt(dx*dx+dy*dy) < 0.05) {
          myHp--;
          if (myHp <= 0) _endGame(false);
          return true;
        }
        return false;
      });

      // Пуля моя попала?
      _bullets.removeWhere((b) {
        if (b.fromHost != widget.isHost) return false;
        final dx = b.x - oppX;
        final dy = b.y - oppY;
        if (sqrt(dx*dx+dy*dy) < 0.05) {
          oppHp--;
          if (oppHp <= 0) _endGame(true);
          return true;
        }
        return false;
      });

      // Отправляем своё состояние в Firestore
      _pushState();
    });
  }

  void _pushState() {
    // ── Firebase: обновляем своё положение ──
    // final prefix = widget.isHost ? 'host' : 'guest';
    // FirebaseFirestore.instance.collection('tank_rooms').doc(widget.code).update({
    //   '${prefix}_x': myX,
    //   '${prefix}_y': myY,
    //   '${prefix}_angle': myAngle,
    //   '${prefix}_hp': myHp,
    //   'bullets': _bullets.map((b) => b.toMap()).toList(),
    // });
  }

  void _shoot() {
    if (_gameOver) return;
    _bullets.add(_OBullet(
      x: myX, y: myY,
      vx: cos(myAngle) * bulletSpeed,
      vy: sin(myAngle) * bulletSpeed,
      fromHost: widget.isHost,
    ));
  }

  void _endGame(bool won) {
    _gameOver = true;
    _iWon = won;
    _gameLoop?.cancel();
    // FirebaseFirestore.instance.collection('tank_rooms').doc(widget.code).update({'status': 'finished'});
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myColor = widget.isHost ? const Color(0xFF00C896) : const Color(0xFFFF3D3D);
    final oppColor = widget.isHost ? const Color(0xFFFF3D3D) : const Color(0xFF00C896);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight * 0.65;
          return Stack(
            children: [
              // Арена
              Positioned(
                top: 0, left: 0, right: 0, height: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8945A),
                    border: Border.all(color: const Color(0xFF8B6914), width: 8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: _OnlinePainter(
                      myX: myX, myY: myY, myAngle: myAngle, myColor: myColor,
                      oppX: oppX, oppY: oppY, oppAngle: oppAngle, oppColor: oppColor,
                      bullets: _bullets,
                    ),
                  ),
                ),
              ),

              // HUD
              Positioned(
                top: 12, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hpWidget('ВЫ', myHp, myColor),
                    Text('КОМНАТА: ${widget.code}',
                        style: const TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2)),
                    _hpWidget('OPP', oppHp, oppColor),
                  ],
                ),
              ),

              // Джойстик
              Positioned(
                bottom: 40, left: 30,
                child: _OJoystick(onChanged: (v) => setState(() => _joystick = v)),
              ),

              // Кнопка огня
              Positioned(
                bottom: 60, right: 40,
                child: GestureDetector(
                  onTapDown: (_) => _shoot(),
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF3D3D).withOpacity(0.9),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 18)],
                    ),
                    child: const Icon(Icons.circle, color: Colors.white, size: 32),
                  ),
                ),
              ),

              // Game Over
              if (_gameOver) _GameOverOnline(
                won: _iWon ?? false,
                onExit: () => Navigator.pop(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _hpWidget(String label, int hp, Color color) {
    return Row(children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(width: 4),
      for (int i = 0; i < 3; i++)
        Icon(i < hp ? Icons.favorite : Icons.favorite_border, color: color, size: 18),
    ]);
  }
}

// ── Пуля для онлайн режима ────────────────────────────────────────────────────

class _OBullet {
  double x, y, vx, vy;
  bool fromHost;

  _OBullet({required this.x, required this.y, required this.vx, required this.vy, required this.fromHost});

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'vx': vx, 'vy': vy, 'fromHost': fromHost};

  factory _OBullet.fromMap(Map m) => _OBullet(
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    vx: (m['vx'] as num).toDouble(),
    vy: (m['vy'] as num).toDouble(),
    fromHost: m['fromHost'] as bool,
  );
}

// ── Painter для онлайн ────────────────────────────────────────────────────────

class _OnlinePainter extends CustomPainter {
  final double myX, myY, myAngle, oppX, oppY, oppAngle;
  final Color myColor, oppColor;
  final List<_OBullet> bullets;

  _OnlinePainter({
    required this.myX, required this.myY, required this.myAngle, required this.myColor,
    required this.oppX, required this.oppY, required this.oppAngle, required this.oppColor,
    required this.bullets,
  });

  void _drawTank(Canvas c, Size s, double x, double y, double angle, Color color) {
    final cx = x * s.width, cy = y * s.height;
    c.save();
    c.translate(cx, cy);
    c.rotate(angle + pi / 2);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -18, 28, 36), const Radius.circular(5)),
        Paint()..color = color);
    c.drawRect(const Rect.fromLTWH(-4, -30, 8, 18), Paint()..color = color.withOpacity(0.85));
    c.drawCircle(Offset.zero, 10, Paint()..color = color.withOpacity(0.7));
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawTank(canvas, size, myX, myY, myAngle, myColor);
    _drawTank(canvas, size, oppX, oppY, oppAngle, oppColor);
    for (final b in bullets) {
      canvas.drawCircle(
        Offset(b.x * size.width, b.y * size.height),
        5,
        Paint()..color = b.fromHost ? const Color(0xFF00C896) : const Color(0xFFFF3D3D),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OnlinePainter old) => true;
}

// ── Джойстик (копия из ai_game) ───────────────────────────────────────────────

class _OJoystick extends StatefulWidget {
  final ValueChanged<Offset> onChanged;
  const _OJoystick({required this.onChanged});
  @override
  State<_OJoystick> createState() => _OJoystickState();
}

class _OJoystickState extends State<_OJoystick> {
  Offset _delta = Offset.zero;
  static const double _r = 50;

  void _upd(Offset local) {
    final d = local - const Offset(_r, _r);
    final clamped = d.distance > _r ? d / d.distance * _r : d;
    setState(() => _delta = clamped);
    widget.onChanged(clamped / _r);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _upd(d.localPosition),
      onPanUpdate: (d) => _upd(d.localPosition),
      onPanEnd: (_) { setState(() => _delta = Offset.zero); widget.onChanged(Offset.zero); },
      child: SizedBox(
        width: _r * 2, height: _r * 2,
        child: Stack(children: [
          Container(decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white24),
          )),
          Center(child: Transform.translate(
            offset: _delta,
            child: Container(width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3))),
          )),
        ]),
      ),
    );
  }
}

// ── Game Over онлайн ──────────────────────────────────────────────────────────

class _GameOverOnline extends StatelessWidget {
  final bool won;
  final VoidCallback onExit;

  const _GameOverOnline({required this.won, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            won ? '🏆 ВЫ ПОБЕДИЛИ!' : '💀 ВЫ ПРОИГРАЛИ',
            style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w900,
              color: won ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('В меню', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}