// lobby/online/games/tank_room.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../features/leaderboard/leaderboard_provider.dart'; // ← НОВОЕ

// ─── Константы ───────────────────────────────────────────────────────────────

const int    kTCols   = 13;
const int    kTRows   = 13;
const double kTCell   = 40.0;
const double kTTank   = 28.0;
const double kTBullet = 7.0;
const double kTMove   = 2.5;
const double kTBSpeed = 5.0;
const int    kTSyncMs = 50;

const double kLerp = 0.3;

// ─── Направления ─────────────────────────────────────────────────────────────

enum TDir { up, down, left, right }

Offset tDirOff(TDir d) => switch (d) {
  TDir.up    => const Offset(0, -1),
  TDir.down  => const Offset(0,  1),
  TDir.left  => const Offset(-1, 0),
  TDir.right => const Offset( 1, 0),
};

double tDirAngle(TDir d) => switch (d) {
  TDir.up    => 0,
  TDir.down  => pi,
  TDir.left  => -pi / 2,
  TDir.right =>  pi / 2,
};

int  tDirToInt(TDir d)  => TDir.values.indexOf(d);
TDir tDirFromInt(int i) => TDir.values[i % 4];

// ─── Лабиринт ─────────────────────────────────────────────────────────────────

List<List<bool>> tGenMaze(int cols, int rows, Random rng) {
  final w = List.generate(rows, (_) => List.filled(cols, true));

  void carve(int cx, int cy) {
    w[cy][cx] = false;
    final dirs = [[0, -2], [0, 2], [-2, 0], [2, 0]]..shuffle(rng);
    for (final d in dirs) {
      final nx = cx + d[0], ny = cy + d[1];
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && w[ny][nx]) {
        w[cy + d[1] ~/ 2][cx + d[0] ~/ 2] = false;
        carve(nx, ny);
      }
    }
  }

  carve(1, 1);
  for (int i = 0; i < (cols * rows) ~/ 8; i++) {
    w[rng.nextInt(rows - 2) + 1][rng.nextInt(cols - 2) + 1] = false;
  }
  w[1][1] = w[1][2] = w[2][1] = false;
  w[rows - 2][cols - 2] = w[rows - 2][cols - 3] = w[rows - 3][cols - 2] = false;
  return w;
}

List<int> tWallsFlat(List<List<bool>> w) =>
    w.expand((r) => r.map((c) => c ? 1 : 0)).toList();

List<List<bool>> tWallsFrom(List<dynamic> flat) =>
    List.generate(kTRows, (y) =>
        List.generate(kTCols, (x) => flat[y * kTCols + x] == 1));

// ─── Пуля ─────────────────────────────────────────────────────────────────────

class TBullet {
  Offset pos;
  TDir   dir;
  bool   mine;

  TBullet({required this.pos, required this.dir, required this.mine});

  Map<String, dynamic> toMap() =>
      {'px': pos.dx, 'py': pos.dy, 'd': tDirToInt(dir)};

  static TBullet fromMap(Map<String, dynamic> m, {required bool mine}) =>
      TBullet(
        pos : Offset((m['px'] as num).toDouble(), (m['py'] as num).toDouble()),
        dir : tDirFromInt(m['d'] as int),
        mine: mine,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Экран создания / входа
// ═══════════════════════════════════════════════════════════════════════════════

class TankRoomScreen extends StatefulWidget {
  const TankRoomScreen({super.key});

  @override
  State<TankRoomScreen> createState() => _TankRoomScreenState();
}

class _TankRoomScreenState extends State<TankRoomScreen> {
  final _ctrl   = TextEditingController();
  String? _error;
  bool _loading = false;

  String _genCode() {
    final r = Random();
    return List.generate(6, (_) => r.nextInt(10).toString()).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code  = _genCode();
    final walls = tGenMaze(kTCols, kTRows, Random());

    await FirebaseFirestore.instance
        .collection('tank_pvp_rooms')
        .doc(code)
        .set({
      'walls'      : tWallsFlat(walls),
      'p1_x'       : 1.0,       'p1_y': 1.0,
      'p1_dir'     : tDirToInt(TDir.right),
      'p1_hp'      : 3,         'p1_score': 0,
      'p1_bullets' : <Map>[],   'p1_moving': false,
      'p2_x'       : (kTCols - 2).toDouble(),
      'p2_y'       : (kTRows - 2).toDouble(),
      'p2_dir'     : tDirToInt(TDir.left),
      'p2_hp'      : 3,         'p2_score': 0,
      'p2_bullets' : <Map>[],   'p2_moving': false,
      'p2_joined'  : false,
      'status'     : 'waiting',
      'winner'     : '',
      'created_at' : FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => _TankWaitScreen(code: code),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Введи ровно 6 цифр');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance
        .collection('tank_pvp_rooms').doc(code).get();

    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() {
        _error   = 'Комната не найдена или уже занята';
        _loading = false;
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('tank_pvp_rooms').doc(code)
        .update({'p2_joined': true, 'status': 'playing'});

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => TankOnlineGame(roomId: code, isHost: false),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF8888AA)),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('Танки — онлайн',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 17)),
              ),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 32),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withOpacity(0.13),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00C896).withOpacity(0.3), width: 2),
              ),
              child: const Center(child: Text('🎮', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createRoom,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Создать комнату',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF00C896).withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('или',
                    style: TextStyle(
                        color: const Color(0xFF8888AA).withOpacity(0.5),
                        fontSize: 14)),
              ),
              const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
            ]),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                  color: Colors.white, fontSize: 24,
                  fontWeight: FontWeight.bold, letterSpacing: 6),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(
                    color: Color(0xFF444466), fontSize: 24, letterSpacing: 6),
                filled: true, fillColor: const Color(0xFF16213E),
                errorText: _error,
                errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white54, width: 2)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _joinRoom,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Войти в комнату',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  foregroundColor: const Color(0xFF00C896),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFF00C896), width: 1.5),
                  elevation: 0,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: CircularProgressIndicator(color: Color(0xFF00C896)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Экран ожидания
// ═══════════════════════════════════════════════════════════════════════════════

class _TankWaitScreen extends StatefulWidget {
  final String code;
  const _TankWaitScreen({required this.code});

  @override
  State<_TankWaitScreen> createState() => _TankWaitScreenState();
}

class _TankWaitScreenState extends State<_TankWaitScreen> {
  StreamSubscription? _sub;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('tank_pvp_rooms')
        .doc(widget.code)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data()!;
      if ((d['p2_joined'] as bool? ?? false) && !_joined) {
        setState(() => _joined = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => TankOnlineGame(roomId: widget.code, isHost: true),
            ));
          }
        });
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _cancel() async {
    await FirebaseFirestore.instance
        .collection('tank_pvp_rooms').doc(widget.code).delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎮', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text('Твоя комната',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Код скопирован!'),
                      duration: Duration(seconds: 2)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF00C896), width: 2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.code,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 36,
                            fontWeight: FontWeight.w900, letterSpacing: 10)),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy, color: Colors.white38, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Нажми, чтобы скопировать',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
              const SizedBox(height: 40),
              if (!_joined) ...[
                const CircularProgressIndicator(color: Color(0xFF00C896)),
                const SizedBox(height: 20),
                const Text('Ожидаем друга...',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Поделись кодом с другом',
                    style: TextStyle(color: Colors.white24, fontSize: 13)),
              ] else ...[
                const Icon(Icons.check_circle,
                    color: Color(0xFF00C896), size: 48),
                const SizedBox(height: 12),
                const Text('Друг подключился! Начинаем...',
                    style: TextStyle(color: Color(0xFF00C896), fontSize: 16)),
              ],
              const SizedBox(height: 36),
              TextButton(
                onPressed: _cancel,
                child: const Text('Отмена',
                    style: TextStyle(color: Colors.redAccent, fontSize: 15)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Онлайн игра с dead reckoning
// ═══════════════════════════════════════════════════════════════════════════════

class TankOnlineGame extends StatefulWidget {
  final String roomId;
  final bool   isHost;
  const TankOnlineGame({super.key, required this.roomId, required this.isHost});

  @override
  State<TankOnlineGame> createState() => _TankOnlineGameState();
}

class _TankOnlineGameState extends State<TankOnlineGame> {

  // ← НОВОЕ
  final _leaderboard = LeaderboardProvider();

  // ── Лабиринт ────────────────────────────────────────────────────────────────
  List<List<bool>> _walls = [];
  bool _ready = false;

  // ── Мой танк ────────────────────────────────────────────────────────────────
  late Offset _myPos;
  TDir _myDir       = TDir.right;
  int  _myHp        = 3;
  int  _myScore     = 0;
  bool _myMoving    = false;
  final List<TBullet> _myBullets = [];

  // ── Соперник ─────────────────────────────────────────────────────────────────
  late Offset _oppPosRemote;
  TDir        _oppDirRemote  = TDir.left;
  bool        _oppMoving     = false;

  late Offset _oppPosLocal;
  TDir        _oppDirLocal   = TDir.left;
  int         _oppHp         = 3;
  int         _oppScore      = 0;
  final List<TBullet> _oppBullets = [];

  // ── Таймеры ─────────────────────────────────────────────────────────────────
  Timer? _physTimer;
  Timer? _syncTimer;
  StreamSubscription? _sub;

  // ── Управление ──────────────────────────────────────────────────────────────
  final Set<LogicalKeyboardKey> _keys = {};
  bool    _shootTapped = false;
  Offset? _joyOrigin;
  Offset? _joyCurrent;

  bool _gameOver = false;
  bool _iWon     = false;

  String get _myPfx  => widget.isHost ? 'p1' : 'p2';
  String get _oppPfx => widget.isHost ? 'p2' : 'p1';

  // ← НОВОЕ: сохранение результата в рейтинг
  Future<void> _onGameFinished(bool win) async {
    final userId = _leaderboard.currentUserId;
    if (userId != null) {
      await _leaderboard.updateAfterMatch(userId: userId, win: win);
    }
  }

  @override
  void initState() {
    super.initState();
    _initFromFirestore();
  }

  Future<void> _initFromFirestore() async {
    final snap = await FirebaseFirestore.instance
        .collection('tank_pvp_rooms').doc(widget.roomId).get();
    if (!mounted) return;

    final d = snap.data()!;
    _walls = tWallsFrom(d['walls'] as List);

    _myPos = widget.isHost
        ? const Offset(1, 1)
        : Offset((kTCols - 2).toDouble(), (kTRows - 2).toDouble());

    _oppPosRemote = widget.isHost
        ? Offset((kTCols - 2).toDouble(), (kTRows - 2).toDouble())
        : const Offset(1, 1);
    _oppPosLocal  = _oppPosRemote;

    _myDir         = widget.isHost ? TDir.right : TDir.left;
    _oppDirRemote  = widget.isHost ? TDir.left  : TDir.right;
    _oppDirLocal   = _oppDirRemote;

    setState(() => _ready = true);
    _startTimers();
    _listenRoom();
  }

  void _startTimers() {
    _physTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_gameOver && _ready) _physTick();
    });
    _syncTimer = Timer.periodic(Duration(milliseconds: kTSyncMs), (_) {
      if (!_gameOver && _ready) _publishMyState();
    });
  }

  void _publishMyState() {
    FirebaseFirestore.instance
        .collection('tank_pvp_rooms')
        .doc(widget.roomId)
        .update({
      '${_myPfx}_x'      : _myPos.dx,
      '${_myPfx}_y'      : _myPos.dy,
      '${_myPfx}_dir'    : tDirToInt(_myDir),
      '${_myPfx}_hp'     : _myHp,
      '${_myPfx}_score'  : _myScore,
      '${_myPfx}_moving' : _myMoving,
      '${_myPfx}_bullets': _myBullets.map((b) => b.toMap()).toList(),
    });
  }

  void _listenRoom() {
    _sub = FirebaseFirestore.instance
        .collection('tank_pvp_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || _gameOver) return;
      final d = snap.data()!;

      final ox = (d['${_oppPfx}_x'] as num?)?.toDouble() ?? _oppPosRemote.dx;
      final oy = (d['${_oppPfx}_y'] as num?)?.toDouble() ?? _oppPosRemote.dy;
      _oppPosRemote  = Offset(ox, oy);
      _oppDirRemote  = tDirFromInt(d['${_oppPfx}_dir']    as int? ?? tDirToInt(_oppDirRemote));
      _oppMoving     = d['${_oppPfx}_moving'] as bool? ?? false;

      final oh = d['${_oppPfx}_hp']    as int? ?? _oppHp;
      final os = d['${_oppPfx}_score'] as int? ?? _oppScore;

      final rawB = d['${_oppPfx}_bullets'] as List? ?? [];
      final newOppB = rawB
          .map((m) => TBullet.fromMap(
          Map<String, dynamic>.from(m as Map), mine: false))
          .toList();

      final status = d['status'] as String? ?? 'playing';
      final winner = d['winner'] as String? ?? '';

      _oppHp    = oh;
      _oppScore = os;
      _oppBullets
        ..clear()
        ..addAll(newOppB);
      _oppDirLocal = _oppDirRemote;

      if (status == 'done' && !_gameOver) {
        final iWon = winner == _myPfx;
        setState(() {
          _gameOver = true;
          _iWon     = iWon;
        });
        _onGameFinished(iWon); // ← НОВОЕ
      }
    });
  }

  // ── Физика ──────────────────────────────────────────────────────────────────

  void _physTick() {
    setState(() {
      _handleMove();
      _handleShoot();
      _applyDeadReckoning();
      _smoothOppPosition();
      _moveBullets();
      _checkHits();
    });
  }

  void _handleMove() {
    TDir? dir;
    if (_keys.contains(LogicalKeyboardKey.arrowUp)    || _keys.contains(LogicalKeyboardKey.keyW)) dir = TDir.up;
    if (_keys.contains(LogicalKeyboardKey.arrowDown)  || _keys.contains(LogicalKeyboardKey.keyS)) dir = TDir.down;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft)  || _keys.contains(LogicalKeyboardKey.keyA)) dir = TDir.left;
    if (_keys.contains(LogicalKeyboardKey.arrowRight) || _keys.contains(LogicalKeyboardKey.keyD)) dir = TDir.right;

    if (_joyOrigin != null && _joyCurrent != null) {
      final delta = _joyCurrent! - _joyOrigin!;
      if (delta.distance > 12) {
        final a = atan2(delta.dy, delta.dx);
        if (a.abs() < pi / 4)                                      dir = TDir.right;
        else if ((a - pi).abs() < pi / 4 || (a + pi).abs() < pi / 4) dir = TDir.left;
        else if (a > 0)                                             dir = TDir.down;
        else                                                        dir = TDir.up;
      }
    }

    if (dir != null) {
      _myDir    = dir;
      _myMoving = true;
      final next = _myPos + tDirOff(dir) * (kTMove / kTCell);
      if (_canMove(next)) _myPos = next;
    } else {
      _myMoving = false;
    }
  }

  bool _canMove(Offset pos) {
    const r = 0.35;
    for (final c in [
      pos + const Offset(-r, -r), pos + const Offset( r, -r),
      pos + const Offset(-r,  r), pos + const Offset( r,  r),
    ]) {
      final cx = c.dx.round(), cy = c.dy.round();
      if (cx < 0 || cy < 0 || cx >= kTCols || cy >= kTRows) return false;
      if (_walls[cy][cx]) return false;
    }
    return true;
  }

  void _applyDeadReckoning() {
    if (!_oppMoving) return;
    final next = _oppPosLocal + tDirOff(_oppDirLocal) * (kTMove / kTCell);
    if (_canMove(next)) _oppPosLocal = next;
  }

  void _smoothOppPosition() {
    final diff = _oppPosRemote - _oppPosLocal;
    if (diff.distance > 1.5) {
      _oppPosLocal = _oppPosRemote;
    } else {
      _oppPosLocal = Offset(
        _oppPosLocal.dx + diff.dx * kLerp,
        _oppPosLocal.dy + diff.dy * kLerp,
      );
    }
  }

  void _handleShoot() {
    if (_shootTapped || _keys.contains(LogicalKeyboardKey.space)) {
      _shootTapped = false;
      if (_myBullets.length < 3) {
        _myBullets.add(TBullet(pos: _myPos, dir: _myDir, mine: true));
      }
    }
  }

  void _moveBullets() {
    void move(List<TBullet> list) {
      list.removeWhere((b) {
        b.pos = b.pos + tDirOff(b.dir) * (kTBSpeed / kTCell);
        final bx = b.pos.dx.round(), by = b.pos.dy.round();
        if (bx < 0 || by < 0 || bx >= kTCols || by >= kTRows) return true;
        if (_walls[by][bx]) return true;
        return false;
      });
    }
    move(_myBullets);
    move(_oppBullets);
  }

  void _checkHits() {
    _myBullets.removeWhere((b) {
      if ((b.pos - _oppPosLocal).distance < 0.6) {
        _oppHp--;
        if (_oppHp <= 0) { _oppHp = 0; _myScore++; _endGame(iWon: true); }
        return true;
      }
      return false;
    });

    _oppBullets.removeWhere((b) {
      if ((b.pos - _myPos).distance < 0.6) {
        _myHp--;
        if (_myHp <= 0) { _myHp = 0; _oppScore++; _endGame(iWon: false); }
        return true;
      }
      return false;
    });
  }

  void _endGame({required bool iWon}) {
    if (_gameOver) return;
    _gameOver = true;
    _iWon     = iWon;
    FirebaseFirestore.instance
        .collection('tank_pvp_rooms')
        .doc(widget.roomId)
        .update({
      'status'         : 'done',
      'winner'         : iWon ? _myPfx : _oppPfx,
      '${_myPfx}_score': _myScore,
      '${_myPfx}_hp'   : _myHp,
    });
    _onGameFinished(iWon); // ← НОВОЕ
  }

  @override
  void dispose() {
    _physTimer?.cancel();
    _syncTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) _keys.add(event.logicalKey);
          if (event is KeyUpEvent)   _keys.remove(event.logicalKey);
          return KeyEventResult.handled;
        },
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(child: _buildGameArea()),
            _buildControls(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final myColor  = widget.isHost ? const Color(0xFF00C896) : const Color(0xFFEF5B5B);
    final oppColor = widget.isHost ? const Color(0xFFEF5B5B) : const Color(0xFF00C896);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF8888AA)),
            onPressed: () => Navigator.pop(context),
          ),
          _buildHpRow(color: myColor,  hp: _myHp,  label: 'ВЫ'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$_myScore : $_oppScore',
                style: const TextStyle(color: Color(0xFFFFD700),
                    fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3)),
          ),
          _buildHpRow(color: oppColor, hp: _oppHp, label: 'ОПП', reversed: true),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHpRow({required Color color, required int hp,
    required String label, bool reversed = false}) {
    final hearts = List.generate(3, (i) => Icon(
      i < hp ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: i < hp ? color : const Color(0xFF444466), size: 16,
    ));
    return Column(children: [
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      Row(children: reversed ? hearts.reversed.toList() : hearts),
    ]);
  }

  Widget _buildGameArea() {
    final mazeW = kTCols * kTCell;
    final mazeH = kTRows * kTCell;

    return Center(
      child: Stack(children: [
        Container(
          width: mazeW, height: mazeH,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(
                color: const Color(0xFF00C896).withOpacity(0.08),
                blurRadius: 40, spreadRadius: 5)],
          ),
        ),
        SizedBox(
          width: mazeW, height: mazeH,
          child: CustomPaint(
            painter: _TankPainter(
              walls      : _walls,
              myPos      : _myPos,
              myDir      : _myDir,
              myColor    : widget.isHost ? const Color(0xFF00C896) : const Color(0xFFEF5B5B),
              oppPos     : _oppPosLocal,
              oppDir     : _oppDirLocal,
              oppColor   : widget.isHost ? const Color(0xFFEF5B5B) : const Color(0xFF00C896),
              myBullets  : _myBullets,
              oppBullets : _oppBullets,
            ),
          ),
        ),
        if (_gameOver) Positioned.fill(child: _buildGameOverOverlay()),
      ]),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _iWon ? '🏆 ПОБЕДА!' : '💀 ПОРАЖЕНИЕ',
            style: TextStyle(
              color: _iWon ? const Color(0xFFFFD700) : const Color(0xFFEF5B5B),
              fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4,
              shadows: [Shadow(
                  color: (_iWon ? const Color(0xFFFFD700) : const Color(0xFFEF5B5B)).withOpacity(0.6),
                  blurRadius: 20)],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _iWon ? 'Соперник уничтожен!' : 'Твой танк уничтожен!',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          const SizedBox(height: 20),
          // ← НОВОЕ: отображение изменения рейтинга
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _iWon
                  ? const Color(0xFFFFD700).withOpacity(0.15)
                  : const Color(0xFFEF5B5B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _iWon
                    ? const Color(0xFFFFD700).withOpacity(0.4)
                    : const Color(0xFFEF5B5B).withOpacity(0.4),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _iWon ? Icons.trending_up : Icons.trending_down,
                color: _iWon ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _iWon ? '+30 рейтинга' : '-5 рейтинга',
                style: TextStyle(
                  color: _iWon ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF00C896).withOpacity(0.4),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: const Text('В МЕНЮ',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onPanStart:  (d) => setState(() {
              _joyOrigin = d.localPosition; _joyCurrent = d.localPosition;
            }),
            onPanUpdate: (d) => setState(() => _joyCurrent = d.localPosition),
            onPanEnd:    (_) => setState(() {
              _joyOrigin = null; _joyCurrent = null;
            }),
            child: _TankJoystick(origin: _joyOrigin, current: _joyCurrent),
          ),
          GestureDetector(
            onTapDown: (_) => setState(() => _shootTapped = true),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF5B5B),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFEF5B5B).withOpacity(0.45),
                    blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Джойстик
// ═══════════════════════════════════════════════════════════════════════════════

class _TankJoystick extends StatelessWidget {
  final Offset? origin;
  final Offset? current;
  const _TankJoystick({this.origin, this.current});

  @override
  Widget build(BuildContext context) {
    Offset thumb = Offset.zero;
    if (origin != null && current != null) {
      final d = current! - origin!;
      thumb = d.distance > 36 ? d / d.distance * 36 : d;
    }
    return SizedBox(
      width: 110, height: 110,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF16213E),
            border: Border.all(
                color: const Color(0xFF00C896).withOpacity(0.3), width: 2),
          ),
        ),
        Transform.translate(
          offset: thumb,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C896).withOpacity(0.85),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.4),
                  blurRadius: 12)],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CustomPainter
// ═══════════════════════════════════════════════════════════════════════════════

class _TankPainter extends CustomPainter {
  final List<List<bool>> walls;
  final Offset myPos, oppPos;
  final TDir   myDir, oppDir;
  final Color  myColor, oppColor;
  final List<TBullet> myBullets, oppBullets;

  const _TankPainter({
    required this.walls,
    required this.myPos,  required this.myDir,  required this.myColor,
    required this.oppPos, required this.oppDir, required this.oppColor,
    required this.myBullets, required this.oppBullets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWalls(canvas);
    _drawTank(canvas, myPos,  myDir,  myColor);
    _drawTank(canvas, oppPos, oppDir, oppColor);
    _drawBullets(canvas, myBullets,  const Color(0xFFFFFF88));
    _drawBullets(canvas, oppBullets, const Color(0xFFFF6666));
  }

  void _drawWalls(Canvas canvas) {
    final fill = Paint()..color = const Color(0xFF2A2A4A);
    final str  = Paint()
      ..color = const Color(0xFF3A3A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int y = 0; y < walls.length; y++) {
      for (int x = 0; x < walls[y].length; x++) {
        if (walls[y][x]) {
          final r = Rect.fromLTWH(x * kTCell, y * kTCell, kTCell, kTCell);
          canvas.drawRect(r, fill);
          canvas.drawRect(r, str);
        }
      }
    }
  }

  void _drawTank(Canvas canvas, Offset gp, TDir dir, Color color) {
    final cx = gp.dx * kTCell + kTCell / 2;
    final cy = gp.dy * kTCell + kTCell / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tDirAngle(dir));

    final body  = Paint()..color = color;
    final dark  = Paint()..color = color.withOpacity(0.6);
    final track = Paint()..color = color.withOpacity(0.4);
    final gun   = Paint()
      ..color = color..strokeWidth = 4
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    const half = kTTank / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero,
              width: kTTank * 0.85, height: kTTank * 0.7),
          const Radius.circular(4),
        ), body);
    canvas.drawCircle(Offset.zero, kTTank * 0.22, dark);
    canvas.drawLine(Offset.zero, Offset(0, -half), gun);
    canvas.drawRect(Rect.fromLTWH(-half * 0.95, -kTTank * 0.32,
        kTTank * 0.15, kTTank * 0.64), track);
    canvas.drawRect(Rect.fromLTWH( half * 0.70, -kTTank * 0.32,
        kTTank * 0.15, kTTank * 0.64), track);
    canvas.restore();
  }

  void _drawBullets(Canvas canvas, List<TBullet> bullets, Color color) {
    final fill = Paint()..style = PaintingStyle.fill;
    final glow = Paint()..style = PaintingStyle.fill;
    for (final b in bullets) {
      final cx = b.pos.dx * kTCell + kTCell / 2;
      final cy = b.pos.dy * kTCell + kTCell / 2;
      fill.color = color;
      glow.color = color.withOpacity(0.3);
      canvas.drawCircle(Offset(cx, cy), kTBullet,     glow);
      canvas.drawCircle(Offset(cx, cy), kTBullet / 2, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TankPainter old) => true;
}