// lobby/online/games/tug_of_war/tug_of_war_room.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Константы ──────────────────────────────────────────────────────────────
const int _kMaxPos  = 12;   // сколько тапов нужно до победы
const int _kGameSec = 30;

// ══════════════════════════════════════════════════════════════════════════════
// ЭКРАН СОЗДАНИЯ / ВХОДА
// ══════════════════════════════════════════════════════════════════════════════

class TugOfWarRoomScreen extends StatefulWidget {
  const TugOfWarRoomScreen({super.key});

  @override
  State<TugOfWarRoomScreen> createState() => _TugOfWarRoomScreenState();
}

class _TugOfWarRoomScreenState extends State<TugOfWarRoomScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    await FirebaseFirestore.instance.collection('tow_rooms').doc(code).set({
      'rope_pos':    0,
      'p1_taps':     0,
      'p2_taps':     0,
      'p1_ready':    false,
      'p2_ready':    false,
      'p2_joined':   false,   // ← явный флаг входа гостя (как в battleship/football)
      'status':      'waiting',
      'winner':      '',
      'start_at':    null,
      'created_at':  FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => _TowWaitingScreen(code: code),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Введи 6-значный код');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(code)
        .get();

    if (!doc.exists) {
      setState(() { _error = 'Комната не найдена'; _loading = false; });
      return;
    }
    final data = doc.data() as Map<String, dynamic>;
    if (data['status'] != 'waiting') {
      setState(() { _error = 'Игра уже началась или завершена'; _loading = false; });
      return;
    }
    if (data['p2_joined'] == true) {
      setState(() { _error = 'Комната уже заполнена'; _loading = false; });
      return;
    }

    // Пометить гостя как вошедшего
    await FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(code)
        .update({'p2_joined': true});

    setState(() => _loading = false);
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => TugOfWarOnlineGame(roomId: code, isHost: false),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          // Фон — анимированные круги
          _AnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'ПЕРЕТЯНИ КАНАТ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Column(children: [
                      const SizedBox(height: 20),

                      // Логотип
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(colors: [
                              Color(0xFF9B6DFF),
                              Color(0xFF5B2DEF),
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B4DEF).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                              child: Text('🪢', style: TextStyle(fontSize: 50))),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Создать
                      _TowButton(
                        label: 'СОЗДАТЬ КОМНАТУ',
                        icon: Icons.add_circle_outline_rounded,
                        gradient: const LinearGradient(colors: [
                          Color(0xFF9B6DFF), Color(0xFF5B2DEF)
                        ]),
                        glowColor: const Color(0xFF7B4DEF),
                        onTap: _loading ? null : _createRoom,
                      ),
                      const SizedBox(height: 24),

                      Row(children: [
                        const Expanded(child: Divider(color: Colors.white12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('или',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14)),
                        ),
                        const Expanded(child: Divider(color: Colors.white12)),
                      ]),
                      const SizedBox(height: 24),

                      // Поле кода
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1040),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF7B4DEF).withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'XXXXXX',
                            hintStyle: const TextStyle(
                                color: Colors.white24,
                                fontSize: 28,
                                letterSpacing: 8),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Войти
                      _TowButton(
                        label: 'ВОЙТИ В КОМНАТУ',
                        icon: Icons.login_rounded,
                        gradient: const LinearGradient(colors: [
                          Color(0xFF00D4A0), Color(0xFF009B78)
                        ]),
                        glowColor: const Color(0xFF00C896),
                        onTap: _loading ? null : _joinRoom,
                      ),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(
                              color: Color(0xFF9B6DFF)),
                        ),

                      const SizedBox(height: 24),
                      const Text(
                        'Один создаёт комнату, второй вводит код\nи жмёт как можно быстрее!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            height: 1.6),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ЭКРАН ОЖИДАНИЯ ХОСТА  (как _FootballWaitingScreen / _BSWaitingScreen)
// ══════════════════════════════════════════════════════════════════════════════

class _TowWaitingScreen extends StatefulWidget {
  final String code;
  const _TowWaitingScreen({required this.code});

  @override
  State<_TowWaitingScreen> createState() => _TowWaitingScreenState();
}

class _TowWaitingScreenState extends State<_TowWaitingScreen> {
  StreamSubscription? _sub;
  bool _guestJoined = false;

  @override
  void initState() {
    super.initState();

    _sub = FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(widget.code)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      final joined = d['p2_joined'] as bool? ?? false;

      if (joined && !_guestJoined) {
        setState(() => _guestJoined = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) =>
                  TugOfWarOnlineGame(roomId: widget.code, isHost: true),
            ));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancelRoom() async {
    await FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(widget.code)
        .delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          _AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪢', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 24),
                  const Text(
                    'Твоя комната',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Код — нажми чтобы скопировать
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован!')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1040),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF9B6DFF), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B4DEF).withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 10,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.copy,
                              color: Colors.white38, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Нажми чтобы скопировать',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                  const SizedBox(height: 44),

                  if (!_guestJoined) ...[
                    const CircularProgressIndicator(
                        color: Color(0xFF9B6DFF)),
                    const SizedBox(height: 20),
                    const Text(
                      'Ожидаем друга...',
                      style:
                      TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Поделись кодом с другом',
                      style: TextStyle(
                          color: Colors.white24, fontSize: 13),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00C896), size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Друг подключился! Начинаем...',
                      style: TextStyle(
                          color: Color(0xFF00C896), fontSize: 16),
                    ),
                  ],

                  const SizedBox(height: 36),
                  TextButton(
                    onPressed: _cancelRoom,
                    child: const Text('Отмена',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ОНЛАЙН ИГРА
// ══════════════════════════════════════════════════════════════════════════════

class TugOfWarOnlineGame extends StatefulWidget {
  final String roomId;
  final bool isHost;

  const TugOfWarOnlineGame(
      {super.key, required this.roomId, required this.isHost});

  @override
  State<TugOfWarOnlineGame> createState() =>
      _TugOfWarOnlineGameState();
}

enum _TOWPhase { waiting, countdown, playing, gameOver }

class _TugOfWarOnlineGameState extends State<TugOfWarOnlineGame>
    with TickerProviderStateMixin {

  _TOWPhase _localPhase = _TOWPhase.waiting;
  bool _finished = false;

  double _ropePos = 0;
  int _p1Taps = 0, _p2Taps = 0;
  int _countdown = 3;
  int _timeLeft = _kGameSec;
  String _winner = '';

  Timer? _countdownTimer;
  Timer? _gameTimer;

  // Анимация кнопки
  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;

  // Анимация встряски канат при тапе
  late AnimationController _ropeShakeCtrl;
  late Animation<double> _ropeShake;

  // Анимация пульса кнопки
  late AnimationController _btnPulseCtrl;
  late Animation<double> _btnPulse;

  // Анимация счётчика обратного отсчёта
  late AnimationController _cdCtrl;
  late Animation<double> _cdScale;

  String get _myTapsField  => widget.isHost ? 'p1_taps' : 'p2_taps';
  String get _myReadyField => widget.isHost ? 'p1_ready' : 'p2_ready';
  DocumentReference get _roomRef =>
      FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId);

  @override
  void initState() {
    super.initState();

    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _tapAnim = Tween<double>(begin: 1.0, end: 0.82).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    _ropeShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _ropeShake = Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: _ropeShakeCtrl, curve: Curves.elasticOut));

    _btnPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _btnPulseCtrl, curve: Curves.easeInOut));

    _cdCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cdScale = Tween<double>(begin: 1.5, end: 1.0).animate(
        CurvedAnimation(parent: _cdCtrl, curve: Curves.elasticOut));

    // Пометить себя готовым
    _roomRef.update({_myReadyField: true});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _tapCtrl.dispose();
    _ropeShakeCtrl.dispose();
    _btnPulseCtrl.dispose();
    _cdCtrl.dispose();
    super.dispose();
  }

  // ── Обработка снапшота ──────────────────────────────────────────────────

  void _handleSnapshot(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'waiting';
    final p1Ready = d['p1_ready'] as bool? ?? false;
    final p2Ready = d['p2_ready'] as bool? ?? false;

    _ropePos = (d['rope_pos'] as num?)?.toDouble() ?? 0;
    _p1Taps  = (d['p1_taps'] as num?)?.toInt() ?? 0;
    _p2Taps  = (d['p2_taps'] as num?)?.toInt() ?? 0;
    _winner  = d['winner'] as String? ?? '';

    // Оба готовы → хост запускает обратный отсчёт
    if (p1Ready && p2Ready && status == 'waiting' && widget.isHost) {
      _roomRef.update({'status': 'countdown'});
    }

    if (status == 'countdown' && _localPhase == _TOWPhase.waiting) {
      setState(() => _localPhase = _TOWPhase.countdown);
      _startCountdown();
    }

    if (status == 'playing' && _localPhase == _TOWPhase.countdown) {
      _countdownTimer?.cancel();
      setState(() {
        _localPhase = _TOWPhase.playing;
        _btnPulseCtrl.stop();
      });
      _startGameTimer();
    }

    if (status == 'finished' && !_finished) {
      _finished = true;
      _gameTimer?.cancel();
      setState(() => _localPhase = _TOWPhase.gameOver);
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _cdCtrl.forward(from: 0);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (widget.isHost) {
          _roomRef.update({'status': 'playing'});
        }
      } else {
        setState(() => _countdown--);
        _cdCtrl.forward(from: 0);
      }
    });
  }

  void _startGameTimer() {
    _timeLeft = _kGameSec;
    _btnPulseCtrl.repeat(reverse: true);
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        if (widget.isHost) _resolveTimeout();
      } else {
        if (mounted) setState(() => _timeLeft--);
      }
    });
  }

  void _resolveTimeout() {
    _roomRef.get().then((snap) {
      if (!snap.exists) return;
      final pos = (snap['rope_pos'] as num).toDouble();
      final winner = pos < 0 ? 'p1' : pos > 0 ? 'p2' : 'draw';
      _roomRef.update({'status': 'finished', 'winner': winner});
    });
  }

  // ── Тап ─────────────────────────────────────────────────────────────────

  void _onTap() {
    if (_localPhase != _TOWPhase.playing) return;

    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0).then((_) => _tapCtrl.reverse());
    _ropeShakeCtrl.forward(from: 0);

    final delta = widget.isHost ? -1 : 1;

    _roomRef.update({
      'rope_pos': FieldValue.increment(delta),
      _myTapsField: FieldValue.increment(1),
    }).then((_) {
      _roomRef.get().then((snap) {
        if (!snap.exists || _finished) return;
        final pos = (snap['rope_pos'] as num).toDouble();
        if (pos <= -_kMaxPos) {
          _finished = true;
          _roomRef.update({'status': 'finished', 'winner': 'p1'});
        } else if (pos >= _kMaxPos) {
          _finished = true;
          _roomRef.update({'status': 'finished', 'winner': 'p2'});
        }
      });
    });
  }

  String _resolveWinnerLabel(String winner) {
    if (winner == 'draw') return '🤝 Ничья!';
    final myId = widget.isHost ? 'p1' : 'p2';
    return winner == myId ? '🏆 Ты победил!' : '💀 Соперник победил!';
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          _AnimatedBackground(),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _roomRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF9B6DFF)));
                }

                final d = snap.data!.data() as Map<String, dynamic>;
                _handleSnapshot(d);

                if (_localPhase == _TOWPhase.gameOver) {
                  return _buildGameOver();
                }

                return Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildBody()),
                    _buildTapButton(),
                    const SizedBox(height: 36),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Верхняя панель ──────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1040).withOpacity(0.9),
        border: Border(
            bottom: BorderSide(
                color: const Color(0xFF9B6DFF).withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white38, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),

          // P1
          _PlayerTapCounter(
            emoji: '🔴',
            label: 'P1',
            taps: _p1Taps,
            color: const Color(0xFFFF5E78),
            isMe: widget.isHost,
          ),

          const Spacer(),

          // Таймер / обратный отсчёт
          if (_localPhase == _TOWPhase.playing)
            _TimerBadge(seconds: _timeLeft)
          else if (_localPhase == _TOWPhase.countdown)
            const Icon(Icons.timer, color: Colors.white38, size: 22)
          else
            const Text('🪢', style: TextStyle(fontSize: 22)),

          const Spacer(),

          // P2
          _PlayerTapCounter(
            emoji: '🟢',
            label: 'P2',
            taps: _p2Taps,
            color: const Color(0xFF00D4A0),
            isMe: !widget.isHost,
          ),

          const SizedBox(width: 8),
          // Код комнаты
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.roomId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1850),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF9B6DFF).withOpacity(0.4)),
              ),
              child: Text(
                widget.roomId,
                style: const TextStyle(
                    color: Color(0xFF9B6DFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Центральная часть ────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_localPhase == _TOWPhase.waiting) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1040).withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Text('⏳', style: TextStyle(fontSize: 40)),
                SizedBox(height: 10),
                Text('Ждём соперника...',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Оба игрока должны открыть игру',
                    style: TextStyle(
                        color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
        ] else if (_localPhase == _TOWPhase.countdown) ...[
          ScaleTransition(
            scale: _cdScale,
            child: Text(
              '$_countdown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                      color: Color(0xFF9B6DFF), blurRadius: 40),
                  Shadow(
                      color: Color(0xFF9B6DFF), blurRadius: 80),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Готовься!',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                letterSpacing: 4),
          ),
        ] else ...[
          // Канат с маркером
          const SizedBox(height: 20),
          _buildRope(),
          const SizedBox(height: 32),
          // Мини-инфо
          _buildMiniProgress(),
        ],
      ],
    );
  }

  // ── Канат ────────────────────────────────────────────────────────────────

  Widget _buildRope() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Метки сторон
          Row(
            children: [
              _SideLabel(label: 'P1', color: const Color(0xFFFF5E78), arrow: '←'),
              const Spacer(),
              _SideLabel(label: 'P2', color: const Color(0xFF00D4A0), arrow: '→', reversed: true),
            ],
          ),
          const SizedBox(height: 12),

          // Сам канат
          AnimatedBuilder(
            animation: _ropeShake,
            builder: (context, child) {
              final shake = sin(_ropeShake.value * pi) *
                  (widget.isHost ? -1 : 1) * 2;
              return Transform.translate(
                offset: Offset(0, shake),
                child: child,
              );
            },
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final norm = (_ropePos + _kMaxPos) / (2 * _kMaxPos);
              final markerX = norm.clamp(0.0, 1.0) * width;

              return SizedBox(
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Полоска канат
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5E78),
                            Color(0xFF4A2080),
                            Color(0xFF00D4A0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF9B6DFF)
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2),
                        ],
                      ),
                    ),

                    // Центральная линия
                    Center(
                      child: Container(
                        width: 3,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Маркер (узел канат)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      left: markerX - 28,
                      top: 10,
                      child: _RopeKnot(
                          pos: _ropePos, maxPos: _kMaxPos.toDouble()),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 10),
          // Победные зоны
          Row(
            children: [
              _WinZone(label: '← Победа P1', color: const Color(0xFFFF5E78)),
              const Spacer(),
              _WinZone(label: 'Победа P2 →', color: const Color(0xFF00D4A0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgress() {
    final norm = (_ropePos + _kMaxPos) / (2 * _kMaxPos);
    return Column(
      children: [
        Text(
          _ropePos == 0
              ? 'Равно!'
              : _ropePos < 0
              ? 'P1 тянет сильнее!'
              : 'P2 тянет сильнее!',
          style: TextStyle(
            color: _ropePos == 0
                ? Colors.white54
                : _ropePos < 0
                ? const Color(0xFFFF5E78)
                : const Color(0xFF00D4A0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Позиция: ${_ropePos.toInt() > 0 ? "+" : ""}${_ropePos.toInt()}',
          style: const TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ],
    );
  }

  // ── Кнопка тапа ─────────────────────────────────────────────────────────

  Widget _buildTapButton() {
    final enabled = _localPhase == _TOWPhase.playing;
    final myColor =
    widget.isHost ? const Color(0xFFFF5E78) : const Color(0xFF00D4A0);

    return GestureDetector(
      onTapDown: enabled ? (_) => _onTap() : null,
      child: ScaleTransition(
        scale: _tapAnim,
        child: AnimatedBuilder(
          animation: _btnPulse,
          builder: (context, child) => Transform.scale(
            scale: enabled ? _btnPulse.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled
                  ? RadialGradient(colors: [
                myColor.withOpacity(0.95),
                myColor.withOpacity(0.55),
              ])
                  : const RadialGradient(colors: [
                Color(0xFF2A1850),
                Color(0xFF1A0A2E),
              ]),
              boxShadow: enabled
                  ? [
                BoxShadow(
                    color: myColor.withOpacity(0.55),
                    blurRadius: 40,
                    spreadRadius: 8),
                BoxShadow(
                    color: myColor.withOpacity(0.25),
                    blurRadius: 80,
                    spreadRadius: 16),
              ]
                  : [],
              border: Border.all(
                color: enabled
                    ? myColor.withOpacity(0.6)
                    : Colors.white12,
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  enabled ? '💪' : '⏳',
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(height: 8),
                Text(
                  enabled ? 'ТЯНИ!' : 'Жди...',
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Экран победы ─────────────────────────────────────────────────────────

  Widget _buildGameOver() {
    final label = _resolveWinnerLabel(_winner);
    final iWon = label.contains('Ты победил');
    final isDraw = label.contains('Ничья');
    final color = isDraw
        ? Colors.orange
        : iWon
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF5E78);

    return Stack(
      children: [
        _AnimatedBackground(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDraw ? '🤝' : iWon ? '🏆' : '💀',
                style: const TextStyle(fontSize: 88),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: color.withOpacity(0.5), blurRadius: 30)
                    ]),
              ),
              const SizedBox(height: 12),
              Text(
                'P1: $_p1Taps тапов  •  P2: $_p2Taps тапов',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 48),
              _TowButton(
                label: 'В МЕНЮ',
                icon: Icons.home_rounded,
                gradient: const LinearGradient(colors: [
                  Color(0xFF9B6DFF), Color(0xFF5B2DEF)
                ]),
                glowColor: const Color(0xFF7B4DEF),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// ══════════════════════════════════════════════════════════════════════════════

class _PlayerTapCounter extends StatelessWidget {
  final String emoji, label;
  final int taps;
  final Color color;
  final bool isMe;

  const _PlayerTapCounter({
    required this.emoji,
    required this.label,
    required this.taps,
    required this.color,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label + (isMe ? ' (ты)' : ''),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$taps 👊',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int seconds;
  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFF5E78).withOpacity(0.15)
            : const Color(0xFF2A1850),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: urgent
              ? const Color(0xFFFF5E78).withOpacity(0.6)
              : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer,
              color: urgent ? const Color(0xFFFF5E78) : Colors.white54,
              size: 16),
          const SizedBox(width: 4),
          Text(
            '$seconds с',
            style: TextStyle(
              color: urgent ? const Color(0xFFFF5E78) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RopeKnot extends StatelessWidget {
  final double pos, maxPos;
  const _RopeKnot({required this.pos, required this.maxPos});

  @override
  Widget build(BuildContext context) {
    final urgency = pos.abs() / maxPos;
    final knobColor = pos < 0
        ? Color.lerp(Colors.white, const Color(0xFFFF5E78), urgency)!
        : pos > 0
        ? Color.lerp(Colors.white, const Color(0xFF00D4A0), urgency)!
        : Colors.white;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: knobColor,
        border: Border.all(color: const Color(0xFF9B6DFF), width: 3),
        boxShadow: [
          BoxShadow(
            color: knobColor.withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
          child: Text('🪢', style: TextStyle(fontSize: 24))),
    );
  }
}

class _SideLabel extends StatelessWidget {
  final String label, arrow;
  final Color color;
  final bool reversed;

  const _SideLabel({
    required this.label,
    required this.color,
    required this.arrow,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = reversed ? '$label $arrow' : '$arrow $label';
    return Text(
      text,
      style: TextStyle(
        color: color.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _WinZone extends StatelessWidget {
  final String label;
  final Color color;
  const _WinZone({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          color: color.withOpacity(0.5), fontSize: 11, letterSpacing: 0.5),
    );
  }
}

// ── Кнопка меню ─────────────────────────────────────────────────────────────

class _TowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback? onTap;

  const _TowButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_TowButton> createState() => _TowButtonState();
}

class _TowButtonState extends State<_TowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
        setState(() => _pressed = false);
        widget.onTap!();
      }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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

// ── Анимированный фон ────────────────────────────────────────────────────────

class _AnimatedBackground extends StatefulWidget {
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF0F0A1E), const Color(0xFF1A0A2E),
                    _ctrl.value)!,
                Color.lerp(const Color(0xFF1A0A2E), const Color(0xFF0D0720),
                    _ctrl.value)!,
              ],
            ),
          ),
          child: CustomPaint(painter: _BgPainter(_ctrl.value)),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final circles = [
      (Offset(size.width * 0.15, size.height * 0.2), 120.0,
      const Color(0xFF7B4DEF)),
      (Offset(size.width * 0.85, size.height * 0.35), 90.0,
      const Color(0xFFFF5E78)),
      (Offset(size.width * 0.5, size.height * 0.8), 100.0,
      const Color(0xFF00C896)),
    ];

    for (final (center, r, color) in circles) {
      final animR = r + sin(t * pi * 2) * 15;
      canvas.drawCircle(
        center,
        animR,
        Paint()
          ..color = color.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.t != t;
}