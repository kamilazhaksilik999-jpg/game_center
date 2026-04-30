// lobby/online/games/pong_room.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const double kPFW    = 400.0;
const double kPFH    = 600.0;
const double kPPadW  = 14.0;
const double kPPadH  = 80.0;
const double kPPMrg  = 18.0;
const double kPBallR = 10.0;
const double kPInit  = 5.5;
const double kPMax   = 14.0;
const double kPAccel = 0.25;
const int    kPWin   = 7;
const int    kPSync  = 50;

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Экран создания / входа в комнату
// ═══════════════════════════════════════════════════════════════════════════════

class PongRoomScreen extends StatefulWidget {
  const PongRoomScreen({super.key});

  @override
  State<PongRoomScreen> createState() => _PongRoomScreenState();
}

class _PongRoomScreenState extends State<PongRoomScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  String _genCode() {
    final r = Random();
    return List.generate(6, (_) => r.nextInt(10).toString()).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _genCode();
    await FirebaseFirestore.instance.collection('pong_rooms').doc(code).set({
      'p1_y': kPFH / 2, 'p2_y': kPFH / 2,
      'ball_x': kPFW / 2, 'ball_y': kPFH / 2,
      'ball_vx': 0.0, 'ball_vy': 0.0,
      'score1': 0, 'score2': 0,
      'p2_joined': false, 'status': 'waiting', 'winner': '',
      'created_at': FieldValue.serverTimestamp(),
    });
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _PongWaitScreen(code: code)));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Введи ровно 6 цифр');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final doc = await FirebaseFirestore.instance
        .collection('pong_rooms').doc(code).get();
    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() {
        _error = 'Комната не найдена или уже занята';
        _loading = false;
      });
      return;
    }
    await FirebaseFirestore.instance.collection('pong_rooms').doc(code)
        .update({'p2_joined': true, 'status': 'playing'});
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => PongOnlineGame(roomId: code, isHost: false)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
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
                child: Text('Pong — онлайн',
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
                color: const Color(0xFF00E5FF).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
              ),
              child: const Center(child: Text('🏓', style: TextStyle(fontSize: 44))),
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
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
              style: const TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(
                    color: Color(0xFF444466), fontSize: 24, letterSpacing: 6),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                errorText: _error,
                errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF00E5FF), width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF00E5FF), width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Colors.white54, width: 2)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Colors.redAccent, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Colors.redAccent, width: 2)),
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
                  backgroundColor: const Color(0xFF0D0D1A),
                  foregroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                          color: Color(0xFF00E5FF), width: 1.5)),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Ожидание второго игрока
// ═══════════════════════════════════════════════════════════════════════════════

class _PongWaitScreen extends StatefulWidget {
  final String code;
  const _PongWaitScreen({required this.code});

  @override
  State<_PongWaitScreen> createState() => _PongWaitScreenState();
}

class _PongWaitScreenState extends State<_PongWaitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _sub = FirebaseFirestore.instance
        .collection('pong_rooms').doc(widget.code)
        .snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      if (snap['status'] == 'playing') {
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => PongOnlineGame(roomId: widget.code, isHost: true)));
      }
    });
  }

  @override
  void dispose() { _pulse.dispose(); _sub?.cancel(); super.dispose(); }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Код скопирован!',
          style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(child: Column(children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8888AA)),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pong_rooms').doc(widget.code).delete();
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ]),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: 0.92 + _pulse.value * 0.08,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                border: Border.all(
                    color: const Color(0xFF00E5FF)
                        .withOpacity(0.3 + _pulse.value * 0.4),
                    width: 2.5),
              ),
              child: const Center(
                  child: Text('🏓', style: TextStyle(fontSize: 50))),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text('Ожидание игрока...',
            style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Поделись кодом с другом',
            style: TextStyle(color: Color(0xFF8888AA), fontSize: 14)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _copyCode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.5),
            ),
            child: Column(children: [
              const Text('КОД КОМНАТЫ',
                  style: TextStyle(color: Color(0xFF8888AA),
                      fontSize: 11, letterSpacing: 3)),
              const SizedBox(height: 10),
              Text(widget.code,
                  style: const TextStyle(color: Color(0xFF00E5FF),
                      fontSize: 36, fontWeight: FontWeight.w900,
                      letterSpacing: 10)),
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.copy_rounded,
                    color: Color(0xFF8888AA), size: 14),
                const SizedBox(width: 4),
                Text('Нажми чтобы скопировать',
                    style: TextStyle(
                        color: const Color(0xFF8888AA).withOpacity(0.7),
                        fontSize: 12)),
              ]),
            ]),
          ),
        ),
        const Spacer(),
      ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Онлайн игра
// ═══════════════════════════════════════════════════════════════════════════════

class PongOnlineGame extends StatefulWidget {
  final String roomId;
  final bool   isHost;

  const PongOnlineGame({super.key, required this.roomId, required this.isHost});

  @override
  State<PongOnlineGame> createState() => _PongOnlineGameState();
}

class _PongOnlineGameState extends State<PongOnlineGame>
    with TickerProviderStateMixin {
  final _rng = Random();
  final _db  = FirebaseFirestore.instance;

  double _ballX = kPFW / 2, _ballY = kPFH / 2;
  double _ballVx = 0, _ballVy = 0;

  double _myY  = kPFH / 2;
  double _oppY = kPFH / 2;

  double _touchY  = kPFH / 2;
  bool   _touching = false;

  int _score1 = 0, _score2 = 0;
  int _hitCount = 0;

  bool _gameOver    = false;
  bool _iWon        = false;
  bool _playing     = false;
  int  _countdown   = 3;
  bool _inCountdown = true;

  // Тикер через AnimationController
  AnimationController? _tickerCtrl;
  late AnimationController _bgPulse;

  Timer? _syncTimer;
  Timer? _countdownTimer;
  StreamSubscription? _roomSub;

  // Данные для painter — обновляются напрямую без setState
  double _paintBallX = kPFW / 2, _paintBallY = kPFH / 2;
  double _paintP1Y   = kPFH / 2, _paintP2Y   = kPFH / 2;
  double _paintBg    = 0;

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _bgPulse = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat(reverse: true);
    _listenRoom();
    _startCountdown();
  }

  @override
  void dispose() {
    _tickerCtrl?.dispose();
    _syncTimer?.cancel();
    _countdownTimer?.cancel();
    _roomSub?.cancel();
    _bgPulse.dispose();
    super.dispose();
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

  void _listenRoom() {
    _roomSub = _db.collection('pong_rooms').doc(widget.roomId)
        .snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final d = snap.data()!;

      if (widget.isHost) {
        _oppY = (d['p2_y'] as num).toDouble();
      } else {
        _oppY = (d['p1_y'] as num).toDouble();
        _ballX = (d['ball_x'] as num).toDouble();
        _ballY = (d['ball_y'] as num).toDouble();
      }

      final s1 = (d['score1'] as num).toInt();
      final s2 = (d['score2'] as num).toInt();
      if (s1 != _score1 || s2 != _score2) {
        setState(() { _score1 = s1; _score2 = s2; });
      }

      final winner = d['winner'] as String? ?? '';
      if (winner.isNotEmpty && !_gameOver) {
        _tickerCtrl?.dispose();
        _tickerCtrl = null;
        _syncTimer?.cancel();
        setState(() {
          _gameOver = true;
          _iWon = widget.isHost ? winner == 'p1' : winner == 'p2';
        });
      }
    });
  }

  // ── Отсчёт ────────────────────────────────────────────────────────────────

  void _startCountdown() {
    _playing = false;
    _inCountdown = true;
    _countdown = 3;
    _tickerCtrl?.dispose();
    _tickerCtrl = null;
    _syncTimer?.cancel();
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _inCountdown = false;
          _playing = true;
          if (widget.isHost) _launchBall();
          _startTicker();
          _startSync();
        }
      });
    });
  }

  void _launchBall() {
    _ballX = kPFW / 2; _ballY = kPFH / 2;
    final angle = (_rng.nextDouble() * pi / 2 - pi / 4) +
        (_rng.nextBool() ? 0 : pi);
    _ballVx = cos(angle) * kPInit;
    _ballVy = sin(angle) * kPInit;
    _hitCount = 0;
  }

  // ── Тикер через AnimationController ──────────────────────────────────────

  void _startTicker() {
    _tickerCtrl?.dispose();
    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
      ..addListener(_tick)
      ..repeat();
  }

  // ── Физика ────────────────────────────────────────────────────────────────

  void _tick() {
    if (!_playing) return;

    // Двигаем свою ракетку локально мгновенно
    if (_touching) {
      final dy = _touchY - _myY;
      final step = dy.sign * min(9.0, dy.abs());
      _myY = (_myY + step).clamp(kPPadH / 2, kPFH - kPPadH / 2);
    }

    if (widget.isHost) {
      _ballX += _ballVx;
      _ballY += _ballVy;

      // Верх/низ
      if (_ballY - kPBallR <= 0) {
        _ballY = kPBallR; _ballVy = _ballVy.abs();
      } else if (_ballY + kPBallR >= kPFH) {
        _ballY = kPFH - kPBallR; _ballVy = -_ballVy.abs();
      }

      // P1 (хост = левая ракетка)
      final p1X = kPPMrg + kPPadW;
      if (_ballVx < 0 &&
          _ballX - kPBallR <= p1X &&
          _ballX - kPBallR >= kPPMrg - 2 &&
          (_ballY - _myY).abs() < kPPadH / 2 + kPBallR) {
        _hitCount++;
        final relY = (_ballY - _myY) / (kPPadH / 2);
        final speed = min(kPInit + _hitCount * kPAccel, kPMax);
        _ballVx = cos(relY * (pi / 3)) * speed;
        _ballVy = sin(relY * (pi / 3)) * speed;
        _ballX = p1X + kPBallR + 1;
        HapticFeedback.lightImpact();
      }

      // P2 (гость = правая ракетка) — хост считает за гостя по _oppY
      final p2X = kPFW - kPPMrg - kPPadW;
      if (_ballVx > 0 &&
          _ballX + kPBallR >= p2X &&
          _ballX + kPBallR <= kPFW - kPPMrg + 2 &&
          (_ballY - _oppY).abs() < kPPadH / 2 + kPBallR) {
        _hitCount++;
        final relY = (_ballY - _oppY) / (kPPadH / 2);
        final speed = min(kPInit + _hitCount * kPAccel, kPMax);
        final angle = pi - relY * (pi / 3);
        _ballVx = cos(angle) * speed;
        _ballVy = sin(angle) * speed;
        _ballX = p2X - kPBallR - 1;
      }

      // Очко
      if (_ballX + kPBallR < 0) {
        _playing = false;
        _score2++;
        _publishScore(_score1, _score2, winner: _score2 >= kPWin ? 'p2' : '');
        if (_score2 < kPWin) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _startCountdown();
          });
        }
      } else if (_ballX - kPBallR > kPFW) {
        _playing = false;
        _score1++;
        _publishScore(_score1, _score2, winner: _score1 >= kPWin ? 'p1' : '');
        if (_score1 < kPWin) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _startCountdown();
          });
        }
      }
    }

    // Обновляем данные для painter напрямую
    _paintBallX = _ballX;
    _paintBallY = _ballY;
    _paintP1Y   = widget.isHost ? _myY  : _oppY;
    _paintP2Y   = widget.isHost ? _oppY : _myY;
    _paintBg    = _bgPulse.value;

    (_repaintKey.currentContext?.findRenderObject())?.markNeedsPaint();
  }

  // ── Синхронизация ─────────────────────────────────────────────────────────

  void _startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(milliseconds: kPSync), (_) {
      if (!mounted) return;
      final key = widget.isHost ? 'p1_y' : 'p2_y';
      final update = <String, dynamic>{key: _myY};
      if (widget.isHost) {
        update['ball_x'] = _ballX;
        update['ball_y'] = _ballY;
      }
      _db.collection('pong_rooms').doc(widget.roomId).update(update);
    });
  }

  Future<void> _publishScore(int s1, int s2, {String winner = ''}) async {
    await _db.collection('pong_rooms').doc(widget.roomId).update({
      'score1': s1, 'score2': s2,
      if (winner.isNotEmpty) 'winner': winner,
    });
  }

  // ── Касания ───────────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    final local = _toField(e.position);
    if (local == null) return;
    final isMyZone = widget.isHost
        ? local.dx < kPFW / 2
        : local.dx > kPFW / 2;
    if (isMyZone) { _touching = true; _touchY = local.dy; }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_touching) return;
    final local = _toField(e.position);
    if (local != null) _touchY = local.dy;
  }

  void _onPointerUp(PointerUpEvent e)         => _touching = false;
  void _onPointerCancel(PointerCancelEvent e) => _touching = false;

  Offset? _toField(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final offX = (box.size.width - kPFW) / 2;
    final offY = (box.size.height - kPFH) / 2 + 56;
    return local - Offset(offX, offY);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myColor  = widget.isHost
        ? const Color(0xFF00E5FF) : const Color(0xFFFF4081);
    final oppColor = widget.isHost
        ? const Color(0xFFFF4081) : const Color(0xFF00E5FF);
    final myScore  = widget.isHost ? _score1 : _score2;
    final oppScore = widget.isHost ? _score2 : _score1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Listener(
        onPointerDown:   _onPointerDown,
        onPointerMove:   _onPointerMove,
        onPointerUp:     _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Column(children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8888AA)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreBlock('ТЫ', myScore, myColor, true),
                    Text('vs', style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 14)),
                    _scoreBlock('OPP', oppScore, oppColor, false),
                  ],
                )),
                const SizedBox(width: 48),
              ]),
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(alignment: Alignment.center, children: [
                RepaintBoundary(
                  child: CustomPaint(
                    key: _repaintKey,
                    size: const Size(kPFW, kPFH),
                    painter: _PongOnlinePainter(state: this),
                  ),
                ),
                if (_inCountdown)
                  Center(child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _countdown > 0 ? '$_countdown' : 'GO!',
                      key: ValueKey(_countdown),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 96,
                          fontWeight: FontWeight.w900),
                    ),
                  )),
                if (_gameOver) _buildGameOver(),
              ]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(widget.isHost ? '◀  ТЫ' : '◀  OPP',
                      style: TextStyle(
                          color: (widget.isHost ? myColor : oppColor)
                              .withOpacity(0.45),
                          fontSize: 11, letterSpacing: 2)),
                  Text('до $kPWin очков',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.2), fontSize: 11)),
                  Text(widget.isHost ? 'OPP  ▶' : 'ТЫ  ▶',
                      style: TextStyle(
                          color: (widget.isHost ? oppColor : myColor)
                              .withOpacity(0.45),
                          fontSize: 11, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _scoreBlock(String label, int score, Color color, bool left) {
    return Row(children: left
        ? [
      Text(label, style: TextStyle(color: color.withOpacity(0.7),
          fontSize: 13, letterSpacing: 2)),
      const SizedBox(width: 8),
      Text('$score', style: TextStyle(color: color, fontSize: 30,
          fontWeight: FontWeight.w900)),
    ] : [
      Text('$score', style: TextStyle(color: color, fontSize: 30,
          fontWeight: FontWeight.w900)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color.withOpacity(0.7),
          fontSize: 13, letterSpacing: 2)),
    ]);
  }

  Widget _buildGameOver() {
    final color = _iWon
        ? const Color(0xFF00E5FF) : const Color(0xFFFF4081);
    return Container(
      width: kPFW, height: kPFH,
      color: Colors.black.withOpacity(0.78),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_iWon ? '🏆 ПОБЕДА!' : '💀 ПОРАЖЕНИЕ',
            style: TextStyle(color: color, fontSize: 36,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 8),
        Text('$_score1 : $_score2',
            style: const TextStyle(color: Colors.white54,
                fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4),
                  blurRadius: 18, spreadRadius: 1)],
            ),
            child: const Text('В МЕНЮ',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ),
      ]),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _PongOnlinePainter extends CustomPainter {
  final _PongOnlineGameState state;

  const _PongOnlinePainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final ballX = state._paintBallX;
    final ballY = state._paintBallY;
    final p1Y   = state._paintP1Y;
    final p2Y   = state._paintP2Y;
    final bg    = state._paintBg;

    final rect = Rect.fromLTWH(0, 0, kPFW, kPFH);

    canvas.drawRect(rect, Paint()
      ..shader = RadialGradient(
        center: Alignment.center, radius: 1.0,
        colors: [
          Color.lerp(const Color(0xFF0D1B2A),
              const Color(0xFF111827), bg)!,
          const Color(0xFF050508),
        ],
      ).createShader(rect));

    canvas.drawRect(rect, Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke ..strokeWidth = 2);

    canvas.drawRect(Rect.fromLTWH(0, 0, kPFW / 2, kPFH),
        Paint()..color = const Color(0xFF00E5FF)
            .withOpacity(0.018 + bg * 0.01));
    canvas.drawRect(Rect.fromLTWH(kPFW / 2, 0, kPFW / 2, kPFH),
        Paint()..color = const Color(0xFFFF4081)
            .withOpacity(0.018 + bg * 0.01));

    final lp = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2 ..style = PaintingStyle.stroke;
    double y = 0;
    while (y < kPFH) {
      canvas.drawLine(Offset(kPFW / 2, y),
          Offset(kPFW / 2, (y + 16).clamp(0, kPFH)), lp);
      y += 26;
    }
    canvas.drawCircle(const Offset(kPFW / 2, kPFH / 2), 40,
        Paint()..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.stroke ..strokeWidth = 1.5);

    _pad(canvas, kPPMrg, p1Y, const Color(0xFF00E5FF));
    _pad(canvas, kPFW - kPPMrg - kPPadW, p2Y, const Color(0xFFFF4081));
    _ball(canvas, ballX, ballY);
  }

  void _pad(Canvas canvas, double x, double cy, Color color) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, cy - kPPadH / 2, kPPadW, kPPadH),
        const Radius.circular(kPPadW / 2));
    canvas.drawRRect(r, Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawRRect(r, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(
          x, cy - kPPadH / 2, kPPadW, kPPadH)));
  }

  void _ball(Canvas canvas, double bx, double by) {
    canvas.drawCircle(Offset(bx, by), kPBallR + 6, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(bx, by), kPBallR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white, const Color(0xFFCCCCCC),
          const Color(0xFF888888)],
      ).createShader(Rect.fromCircle(
          center: Offset(bx, by), radius: kPBallR)));
    canvas.drawCircle(
        Offset(bx - kPBallR * 0.3, by - kPBallR * 0.3),
        kPBallR * 0.3,
        Paint()..color = Colors.white.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant _PongOnlinePainter old) => true;
}