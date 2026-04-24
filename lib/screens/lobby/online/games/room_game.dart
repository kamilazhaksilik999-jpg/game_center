// lobby/online/games/room_game.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Константы ───────────────────────────────────────────────────────────────

const int kOnlineCols = 13;
const int kOnlineRows = 13;
const double kOnlineCell = 40.0;
const double kOnlineTankSize = 28.0;
const double kOnlineBulletSize = 7.0;
const double kOnlineMoveSpeed = 2.5;
const double kOnlineBulletSpeed = 5.0;

// ─── Направления ─────────────────────────────────────────────────────────────

enum OnlineDir { up, down, left, right }

Offset onlineDirOffset(OnlineDir d) => switch (d) {
  OnlineDir.up    => const Offset(0, -1),
  OnlineDir.down  => const Offset(0, 1),
  OnlineDir.left  => const Offset(-1, 0),
  OnlineDir.right => const Offset(1, 0),
};

double onlineDirAngle(OnlineDir d) => switch (d) {
  OnlineDir.up    => 0,
  OnlineDir.down  => pi,
  OnlineDir.left  => -pi / 2,
  OnlineDir.right => pi / 2,
};

// ─── Генерация лабиринта ──────────────────────────────────────────────────────

List<List<bool>> generateOnlineMaze(int cols, int rows, Random rng) {
  final walls = List.generate(rows, (_) => List.filled(cols, true));

  void carve(int cx, int cy) {
    walls[cy][cx] = false;
    final dirs = [
      [0, -2], [0, 2], [-2, 0], [2, 0],
    ]..shuffle(rng);
    for (final d in dirs) {
      final nx = cx + d[0];
      final ny = cy + d[1];
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && walls[ny][nx]) {
        walls[cy + d[1] ~/ 2][cx + d[0] ~/ 2] = false;
        carve(nx, ny);
      }
    }
  }

  carve(1, 1);

  for (int i = 0; i < (cols * rows) ~/ 8; i++) {
    final rx = rng.nextInt(cols - 2) + 1;
    final ry = rng.nextInt(rows - 2) + 1;
    walls[ry][rx] = false;
  }

  // Стартовые позиции
  walls[1][1] = false;
  walls[1][2] = false;
  walls[2][1] = false;
  walls[rows - 2][cols - 2] = false;
  walls[rows - 2][cols - 3] = false;
  walls[rows - 3][cols - 2] = false;

  return walls;
}

// ─── Пуля ────────────────────────────────────────────────────────────────────

class OnlineBullet {
  double x, y, vx, vy;
  bool fromHost;

  OnlineBullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.fromHost,
  });

  Map<String, dynamic> toMap() =>
      {'x': x, 'y': y, 'vx': vx, 'vy': vy, 'fromHost': fromHost};

  factory OnlineBullet.fromMap(Map m) => OnlineBullet(
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    vx: (m['vx'] as num).toDouble(),
    vy: (m['vy'] as num).toDouble(),
    fromHost: m['fromHost'] as bool,
  );
}

// ─── Экран выбора комнаты ─────────────────────────────────────────────────────

class RoomGameScreen extends StatefulWidget {
  const RoomGameScreen({super.key});

  @override
  State<RoomGameScreen> createState() => _RoomGameScreenState();
}

class _RoomGameScreenState extends State<RoomGameScreen> {
  final _codeController = TextEditingController();
  String? _error;
  bool _loading = false;
  final _rng = Random();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = '123456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  // Генерируем seed лабиринта чтобы у обоих был одинаковый
  int _generateSeed() => _rng.nextInt(999999);

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();
    final seed = _generateSeed();

    // ── Firebase: создать документ комнаты ──
    // await FirebaseFirestore.instance.collection('tank_rooms').doc(code).set({
    //   'host': 'player1',
    //   'guest': null,
    //   'status': 'waiting',
    //   'maze_seed': seed,   // ← seed для одинакового лабиринта
    //   'host_x': 1.0, 'host_y': 1.0, 'host_angle': 0.0, 'host_hp': 3,
    //   'guest_x': 11.0, 'guest_y': 11.0, 'guest_angle': 3.14, 'guest_hp': 3,
    //   'bullets': [],
    //   'created_at': FieldValue.serverTimestamp(),
    // });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _WaitingRoomScreen(code: code, isHost: true, seed: seed),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Введи 6-значный код комнаты');
      return;
    }
    setState(() { _loading = true; _error = null; });

    // ── Firebase: получить seed лабиринта из комнаты ──
    // final doc = await FirebaseFirestore.instance.collection('tank_rooms').doc(code).get();
    // if (!doc.exists || doc['status'] != 'waiting') {
    //   setState(() { _error = 'Комната не найдена или уже занята'; _loading = false; });
    //   return;
    // }
    // final seed = doc['maze_seed'] as int;
    // await FirebaseFirestore.instance.collection('tank_rooms').doc(code).update({
    //   'guest': 'player2', 'status': 'playing',
    // });

    final seed = 42; // заглушка — заменить на seed из Firebase
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OnlineTankGame(code: code, isHost: false, seed: seed),
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
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8DEF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('🎮', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createRoom,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text('Создать комнату',
                    style: TextStyle(fontSize: 17)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8DEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(children: [
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('или',
                    style:
                    TextStyle(color: Colors.white38, fontSize: 14)),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ]),
            const SizedBox(height: 28),
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
                hintStyle: TextStyle(
                    color: Colors.white24, fontSize: 24, letterSpacing: 6),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF5B8DEF), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF5B8DEF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: Colors.white54, width: 2),
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _joinRoom,
                icon: const Icon(Icons.login_rounded, size: 22),
                label: const Text('Войти в комнату',
                    style: TextStyle(fontSize: 17)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child:
                CircularProgressIndicator(color: Color(0xFF5B8DEF)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Экран ожидания ───────────────────────────────────────────────────────────

class _WaitingRoomScreen extends StatefulWidget {
  final String code;
  final bool isHost;
  final int seed;

  const _WaitingRoomScreen({
    required this.code,
    required this.isHost,
    required this.seed,
  });

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
    //         MaterialPageRoute(builder: (_) => OnlineTankGame(
    //           code: widget.code, isHost: true, seed: widget.seed)));
    //     });
    //   }
    // });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _guestJoined = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => OnlineTankGame(
                code: widget.code, isHost: true, seed: widget.seed)));
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
            const Text('Твоя комната',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Код скопирован!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF5B8DEF), width: 2),
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
              const Text('Ожидаем друга...',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 16)),
            ] else ...[
              const Icon(Icons.check_circle,
                  color: Color(0xFF00C896), size: 48),
              const SizedBox(height: 16),
              const Text('Друг подключился! Начинаем...',
                  style: TextStyle(
                      color: Color(0xFF00C896), fontSize: 16)),
            ],
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Онлайн игра с лабиринтом ─────────────────────────────────────────────────

class OnlineTankGame extends StatefulWidget {
  final String code;
  final bool isHost;
  final int seed;

  const OnlineTankGame({
    super.key,
    required this.code,
    required this.isHost,
    required this.seed,
  });

  @override
  State<OnlineTankGame> createState() => _OnlineTankGameState();
}

class _OnlineTankGameState extends State<OnlineTankGame> {
  late List<List<bool>> _walls;

  // Позиции в клетках лабиринта
  double myX = 1, myY = 1;
  double oppX = 11, oppY = 11;
  OnlineDir myDir = OnlineDir.right;
  OnlineDir oppDir = OnlineDir.left;
  int myHp = 3, oppHp = 3;

  final List<OnlineBullet> _bullets = [];

  Offset _joystickOrigin = Offset.zero;
  Offset _joystickCurrent = Offset.zero;
  bool _shootPressed = false;

  Timer? _gameLoop;
  StreamSubscription? _sub;

  bool _gameOver = false;
  bool? _iWon;
  int myScore = 0;
  int oppScore = 0;

  @override
  void initState() {
    super.initState();
    // Оба игрока используют одинаковый seed → одинаковый лабиринт
    _walls = generateOnlineMaze(kOnlineCols, kOnlineRows, Random(widget.seed));

    if (!widget.isHost) {
      myX = 11; myY = 11; myDir = OnlineDir.left;
      oppX = 1; oppY = 1; oppDir = OnlineDir.right;
    }

    _listenFirestore();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  void _listenFirestore() {
    // ── Firebase: подписка ──
    // _sub = FirebaseFirestore.instance
    //     .collection('tank_rooms')
    //     .doc(widget.code)
    //     .snapshots()
    //     .listen((snap) {
    //   if (!mounted) return;
    //   setState(() {
    //     final myPrefix  = widget.isHost ? 'host' : 'guest';
    //     final oppPrefix = widget.isHost ? 'guest' : 'host';
    //     myHp  = snap['${myPrefix}_hp']  ?? 3;
    //     oppHp = snap['${oppPrefix}_hp'] ?? 3;
    //     oppX  = (snap['${oppPrefix}_x']  as num).toDouble();
    //     oppY  = (snap['${oppPrefix}_y']  as num).toDouble();
    //     final raw = snap['bullets'] as List? ?? [];
    //     _bullets..clear()..addAll(raw.map((b) => OnlineBullet.fromMap(b)));
    //     if (myHp <= 0)  _endGame(false);
    //     if (oppHp <= 0) _endGame(true);
    //   });
    // });
  }

  void _tick(Timer _) {
    if (_gameOver) return;
    setState(() {
      _moveMe();
      _moveBullets();
      _checkCollisions();
      _pushState();
    });
  }

  bool _canMoveFull(double nx, double ny) {
    const r = 0.35;
    for (final corner in [
      [nx - r, ny - r], [nx + r, ny - r],
      [nx - r, ny + r], [nx + r, ny + r],
    ]) {
      final cx = corner[0].round();
      final cy = corner[1].round();
      if (cx < 0 || cy < 0 || cx >= kOnlineCols || cy >= kOnlineRows) return false;
      if (_walls[cy][cx]) return false;
    }
    return true;
  }

  void _moveMe() {
    OnlineDir? moveDir;

    // Джойстик
    if (_joystickOrigin != Offset.zero && _joystickCurrent != Offset.zero) {
      final delta = _joystickCurrent - _joystickOrigin;
      if (delta.distance > 12) {
        final angle = atan2(delta.dy, delta.dx);
        if (angle.abs() < pi / 4) moveDir = OnlineDir.right;
        else if ((angle - pi).abs() < pi / 4 || (angle + pi).abs() < pi / 4)
          moveDir = OnlineDir.left;
        else if (angle > 0) moveDir = OnlineDir.down;
        else moveDir = OnlineDir.up;
      }
    }

    if (moveDir != null) {
      myDir = moveDir;
      final step = onlineDirOffset(moveDir) * (kOnlineMoveSpeed / kOnlineCell);
      final nx = myX + step.dx;
      final ny = myY + step.dy;
      if (_canMoveFull(nx, ny)) {
        myX = nx;
        myY = ny;
      }
    }

    if (_shootPressed) {
      _shootPressed = false;
      _shoot();
    }
  }

  void _shoot() {
    if (_gameOver) return;
    if (_bullets.where((b) => b.fromHost == widget.isHost).length >= 3) return;
    final dir = onlineDirOffset(myDir);
    _bullets.add(OnlineBullet(
      x: myX, y: myY,
      vx: dir.dx * kOnlineBulletSpeed / kOnlineCell,
      vy: dir.dy * kOnlineBulletSpeed / kOnlineCell,
      fromHost: widget.isHost,
    ));
  }

  void _moveBullets() {
    for (final b in _bullets) {
      b.x += b.vx;
      b.y += b.vy;
    }
    _bullets.removeWhere((b) {
      final bx = b.x.round();
      final by = b.y.round();
      if (bx < 0 || by < 0 || bx >= kOnlineCols || by >= kOnlineRows) return true;
      return _walls[by][bx];
    });
  }

  void _checkCollisions() {
    final toRemove = <OnlineBullet>[];
    for (final b in _bullets) {
      if (b.fromHost == widget.isHost) {
        // Моя пуля — попала в оппонента?
        final dx = b.x - oppX;
        final dy = b.y - oppY;
        if (sqrt(dx * dx + dy * dy) < 0.6) {
          oppHp--;
          toRemove.add(b);
          if (oppHp <= 0) _endGame(true);
        }
      } else {
        // Чужая пуля — попала в меня?
        final dx = b.x - myX;
        final dy = b.y - myY;
        if (sqrt(dx * dx + dy * dy) < 0.6) {
          myHp--;
          toRemove.add(b);
          if (myHp <= 0) _endGame(false);
        }
      }
    }
    _bullets.removeWhere(toRemove.contains);
  }

  void _pushState() {
    // ── Firebase: отправляем своё состояние ──
    // final prefix = widget.isHost ? 'host' : 'guest';
    // FirebaseFirestore.instance.collection('tank_rooms').doc(widget.code).update({
    //   '${prefix}_x': myX,
    //   '${prefix}_y': myY,
    //   '${prefix}_hp': myHp,
    //   'bullets': _bullets.map((b) => b.toMap()).toList(),
    // });
  }

  void _endGame(bool won) {
    _gameOver = true;
    _iWon = won;
    if (won) myScore++; else oppScore++;
    _gameLoop?.cancel();
  }

  void _restartGame() {
    _gameLoop?.cancel();
    setState(() {
      _walls = generateOnlineMaze(kOnlineCols, kOnlineRows, Random());
      _bullets.clear();
      _gameOver = false;
      _iWon = null;
      myHp = 3; oppHp = 3;
      if (widget.isHost) {
        myX = 1; myY = 1; myDir = OnlineDir.right;
        oppX = 11; oppY = 11; oppDir = OnlineDir.left;
      } else {
        myX = 11; myY = 11; myDir = OnlineDir.left;
        oppX = 1; oppY = 1; oppDir = OnlineDir.right;
      }
    });
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myColor = widget.isHost
        ? const Color(0xFF00C896)
        : const Color(0xFFFF3D3D);
    final oppColor = widget.isHost
        ? const Color(0xFFFF3D3D)
        : const Color(0xFF00C896);

    final mazeW = kOnlineCols * kOnlineCell;
    final mazeH = kOnlineRows * kOnlineCell;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── HUD ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF8888AA)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  _hpWidget('ВЫ', myHp, myColor),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$myScore : $oppScore',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  _hpWidget('OPP', oppHp, oppColor),
                  Text('${widget.code}',
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),

            // ── Арена ──
            Expanded(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: mazeW,
                      height: mazeH,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: myColor.withOpacity(0.08),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: mazeW,
                      height: mazeH,
                      child: CustomPaint(
                        painter: _OnlineMazePainter(
                          walls: _walls,
                          myX: myX, myY: myY, myDir: myDir, myColor: myColor,
                          oppX: oppX, oppY: oppY, oppDir: oppDir, oppColor: oppColor,
                          bullets: _bullets,
                        ),
                      ),
                    ),
                    if (_gameOver)
                      Positioned.fill(child: _buildGameOver()),
                  ],
                ),
              ),
            ),

            // ── Управление ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onPanStart: (d) => setState(() {
                      _joystickOrigin = d.localPosition;
                      _joystickCurrent = d.localPosition;
                    }),
                    onPanUpdate: (d) =>
                        setState(() => _joystickCurrent = d.localPosition),
                    onPanEnd: (_) => setState(() {
                      _joystickOrigin = Offset.zero;
                      _joystickCurrent = Offset.zero;
                    }),
                    child: _OnlineJoystick(
                      origin: _joystickOrigin == Offset.zero
                          ? null
                          : _joystickOrigin,
                      current: _joystickCurrent == Offset.zero
                          ? null
                          : _joystickCurrent,
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) =>
                        setState(() => _shootPressed = true),
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF5B5B),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF5B5B).withOpacity(0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hpWidget(String label, int hp, Color color) {
    return Column(children: [
      Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      Row(children: List.generate(3, (i) =>
          Icon(i < hp ? Icons.favorite : Icons.favorite_border,
              color: color, size: 18))),
    ]);
  }

  Widget _buildGameOver() {
    final won = _iWon ?? false;
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🏆 ВЫ ПОБЕДИЛИ!' : '💀 ВЫ ПРОИГРАЛИ',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: won
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF3D3D),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ещё раз',
                  style:
                  TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('В меню',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter лабиринта ────────────────────────────────────────────────────────

class _OnlineMazePainter extends CustomPainter {
  final List<List<bool>> walls;
  final double myX, myY, oppX, oppY;
  final OnlineDir myDir, oppDir;
  final Color myColor, oppColor;
  final List<OnlineBullet> bullets;

  _OnlineMazePainter({
    required this.walls,
    required this.myX, required this.myY,
    required this.myDir, required this.myColor,
    required this.oppX, required this.oppY,
    required this.oppDir, required this.oppColor,
    required this.bullets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWalls(canvas);
    _drawTank(canvas, myX, myY, myDir, myColor);
    _drawTank(canvas, oppX, oppY, oppDir, oppColor);
    _drawBullets(canvas);
  }

  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF3A3A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int y = 0; y < walls.length; y++) {
      for (int x = 0; x < walls[y].length; x++) {
        if (walls[y][x]) {
          final rect = Rect.fromLTWH(
              x * kOnlineCell, y * kOnlineCell,
              kOnlineCell, kOnlineCell);
          canvas.drawRect(rect, wallPaint);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }
  }

  void _drawTank(Canvas canvas, double gx, double gy,
      OnlineDir dir, Color color) {
    final cx = gx * kOnlineCell + kOnlineCell / 2;
    final cy = gy * kOnlineCell + kOnlineCell / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(onlineDirAngle(dir));

    final bodyPaint = Paint()..color = color;
    final darkPaint = Paint()..color = color.withOpacity(0.6);
    final barrelPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final trackPaint = Paint()..color = color.withOpacity(0.4);

    const half = kOnlineTankSize / 2;

    // Корпус
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset.zero,
            width: kOnlineTankSize * 0.85,
            height: kOnlineTankSize * 0.7),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    // Башня
    canvas.drawCircle(Offset.zero, kOnlineTankSize * 0.22, darkPaint);
    // Ствол
    canvas.drawLine(Offset.zero, Offset(0, -half), barrelPaint);
    // Гусеницы
    canvas.drawRect(
        Rect.fromLTWH(-half * 0.95, -kOnlineTankSize * 0.32,
            kOnlineTankSize * 0.15, kOnlineTankSize * 0.64),
        trackPaint);
    canvas.drawRect(
        Rect.fromLTWH(half * 0.7, -kOnlineTankSize * 0.32,
            kOnlineTankSize * 0.15, kOnlineTankSize * 0.64),
        trackPaint);

    canvas.restore();
  }

  void _drawBullets(Canvas canvas) {
    for (final b in bullets) {
      final cx = b.x * kOnlineCell + kOnlineCell / 2;
      final cy = b.y * kOnlineCell + kOnlineCell / 2;
      final color = b.fromHost
          ? const Color(0xFFFFFF88)
          : const Color(0xFFFF6666);

      canvas.drawCircle(
          Offset(cx, cy),
          kOnlineBulletSize / 2,
          Paint()..color = color);
      canvas.drawCircle(
          Offset(cx, cy),
          kOnlineBulletSize,
          Paint()..color = color.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _OnlineMazePainter old) => true;
}

// ─── Джойстик ────────────────────────────────────────────────────────────────

class _OnlineJoystick extends StatelessWidget {
  final Offset? origin;
  final Offset? current;

  const _OnlineJoystick({this.origin, this.current});

  @override
  Widget build(BuildContext context) {
    Offset thumbOffset = Offset.zero;
    if (origin != null && current != null) {
      final delta = current! - origin!;
      final clamped =
      delta.distance > 36 ? delta / delta.distance * 36 : delta;
      thumbOffset = clamped;
    }

    return SizedBox(
      width: 110, height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF16213E),
              border: Border.all(
                  color: const Color(0xFF00C896).withOpacity(0.3),
                  width: 2),
            ),
          ),
          Transform.translate(
            offset: thumbOffset,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C896).withOpacity(0.85),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.4),
                      blurRadius: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}