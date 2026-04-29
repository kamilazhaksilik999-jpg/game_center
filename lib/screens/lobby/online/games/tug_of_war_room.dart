// lobby/online/games/tug_of_war/tug_of_war_room.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/services/coin_service.dart';
import '../../../../../core/services/user_service.dart';
import '../../../../../features/leaderboard/leaderboard_provider.dart';
import '../../../../../widgets/win_dialog.dart';

// ── Константы ──────────────────────────────────────────────────────────────
const int _kMaxPos    = 12;   // тапов до победы в раунде
const int _kGameSec   = 35;   // длительность раунда
const int _kMaxRounds = 3;    // раундов до победы в матче (best of 5 → first to 3)
const int _kBoostAt   = 6;    // тапов подряд для активации буста
const int _kBoostSec  = 4;    // длительность буста (сек)

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
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    await FirebaseFirestore.instance.collection('tow_rooms').doc(code).set({
      'rope_pos':      0,
      'p1_taps':       0,
      'p2_taps':       0,
      'p1_score':      0,   // победы в раундах
      'p2_score':      0,
      'p1_ready':      false,
      'p2_ready':      false,
      'p2_joined':     false,
      'p1_boost':      false,
      'p2_boost':      false,
      'current_round': 1,
      'status':        'waiting',
      'winner':        '',
      'created_at':    FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => _TowWaitingScreen(code: code),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) { setState(() => _error = 'Введи 6-значный код'); return; }

    setState(() { _loading = true; _error = null; });
    final doc = await FirebaseFirestore.instance.collection('tow_rooms').doc(code).get();

    if (!doc.exists) {
      setState(() { _error = 'Комната не найдена'; _loading = false; }); return;
    }
    final data = doc.data() as Map<String, dynamic>;
    if (data['status'] != 'waiting') {
      setState(() { _error = 'Игра уже началась или завершена'; _loading = false; }); return;
    }
    if (data['p2_joined'] == true) {
      setState(() { _error = 'Комната уже заполнена'; _loading = false; }); return;
    }

    await FirebaseFirestore.instance.collection('tow_rooms').doc(code)
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
          _AnimatedBackground(),
          SafeArea(
            child: Column(children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('ПЕРЕТЯНИ КАНАТ', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w900, letterSpacing: 3)),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [Color(0xFF9B6DFF), Color(0xFF5B2DEF)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF7B4DEF).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 4)],
                        ),
                        child: const Center(child: Text('🪢', style: TextStyle(fontSize: 50))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('First to $_kMaxRounds rounds wins!',
                        style: TextStyle(color: Color(0xFF9B6DFF), fontSize: 13, letterSpacing: 1)),
                    const SizedBox(height: 28),

                    _TowButton(
                      label: 'СОЗДАТЬ КОМНАТУ',
                      icon: Icons.add_circle_outline_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF9B6DFF), Color(0xFF5B2DEF)]),
                      glowColor: const Color(0xFF7B4DEF),
                      onTap: _loading ? null : _createRoom,
                    ),
                    const SizedBox(height: 24),

                    Row(children: [
                      const Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('или', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ),
                      const Expanded(child: Divider(color: Colors.white12)),
                    ]),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1040),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7B4DEF).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(color: Colors.white, fontSize: 28,
                            fontWeight: FontWeight.w900, letterSpacing: 8),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'XXXXXX',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 28, letterSpacing: 8),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 14),

                    _TowButton(
                      label: 'ВОЙТИ В КОМНАТУ',
                      icon: Icons.login_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF00D4A0), Color(0xFF009B78)]),
                      glowColor: const Color(0xFF00C896),
                      onTap: _loading ? null : _joinRoom,
                    ),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(color: Color(0xFF9B6DFF)),
                      ),

                    const SizedBox(height: 24),
                    const Text(
                      'Первый до $_kMaxRounds побед выигрывает матч!\nКомбо-тапы дают БУСТ ⚡',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.6),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ЭКРАН ОЖИДАНИЯ
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
        .collection('tow_rooms').doc(widget.code).snapshots().listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      if ((d['p2_joined'] as bool? ?? false) && !_guestJoined) {
        setState(() => _guestJoined = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => TugOfWarOnlineGame(roomId: widget.code, isHost: true),
          ));
        });
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _cancelRoom() async {
    await FirebaseFirestore.instance.collection('tow_rooms').doc(widget.code).delete();
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🪢', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                const Text('Твоя комната', style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован!')));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1040),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF9B6DFF), width: 2.5),
                      boxShadow: [BoxShadow(color: const Color(0xFF7B4DEF).withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.code, style: const TextStyle(
                          color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 10)),
                      const SizedBox(width: 14),
                      const Icon(Icons.copy, color: Colors.white38, size: 22),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Нажми чтобы скопировать',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                const SizedBox(height: 44),

                if (!_guestJoined) ...[
                  const CircularProgressIndicator(color: Color(0xFF9B6DFF)),
                  const SizedBox(height: 20),
                  const Text('Ожидаем друга...', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Поделись кодом с другом', style: TextStyle(color: Colors.white24, fontSize: 13)),
                ] else ...[
                  const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 52),
                  const SizedBox(height: 12),
                  const Text('Друг подключился! Начинаем...', style: TextStyle(color: Color(0xFF00C896), fontSize: 16)),
                ],

                const SizedBox(height: 36),
                TextButton(onPressed: _cancelRoom,
                    child: const Text('Отмена', style: TextStyle(color: Colors.redAccent))),
              ]),
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

  const TugOfWarOnlineGame({super.key, required this.roomId, required this.isHost});

  @override
  State<TugOfWarOnlineGame> createState() => _TugOfWarOnlineGameState();
}

enum _TOWPhase { waiting, countdown, playing, roundOver, gameOver }

class _TugOfWarOnlineGameState extends State<TugOfWarOnlineGame>
    with TickerProviderStateMixin {

  _TOWPhase _localPhase = _TOWPhase.waiting;
  bool _finished = false;

  double _ropePos = 0;
  int _p1Taps = 0, _p2Taps = 0;
  int _p1Score = 0, _p2Score = 0;
  int _currentRound = 1;
  int _countdown = 3;
  int _timeLeft = _kGameSec;
  String _winner = '';

  // Комбо-система
  int _myCombo          = 0;
  DateTime? _lastMyTap;
  bool _myBoostActive   = false;
  bool _oppBoostActive  = false;
  Timer? _myBoostTimer;

  Timer? _countdownTimer;
  Timer? _gameTimer;

  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;
  late AnimationController _boostCtrl;
  late Animation<double> _boostPulse;
  late AnimationController _cdCtrl;
  late Animation<double> _cdScale;
  late AnimationController _roundCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreScale;

  String get _myTapsField   => widget.isHost ? 'p1_taps'  : 'p2_taps';
  String get _myReadyField  => widget.isHost ? 'p1_ready' : 'p2_ready';
  String get _myBoostField  => widget.isHost ? 'p1_boost' : 'p2_boost';

  DocumentReference get _roomRef =>
      FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId);

  @override
  void initState() {
    super.initState();

    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _tapAnim = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    _boostCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _boostPulse = Tween<double>(begin: 1.0, end: 1.07)
        .animate(CurvedAnimation(parent: _boostCtrl, curve: Curves.easeInOut));

    _cdCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _cdScale = Tween<double>(begin: 1.6, end: 1.0)
        .animate(CurvedAnimation(parent: _cdCtrl, curve: Curves.elasticOut));

    _roundCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scoreScale = Tween<double>(begin: 1.5, end: 1.0)
        .animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut));

    _roomRef.update({_myReadyField: true});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _myBoostTimer?.cancel();
    _tapCtrl.dispose();
    _boostCtrl.dispose();
    _cdCtrl.dispose();
    _roundCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  // ── Обработка снапшота ──────────────────────────────────────────────────

  void _handleSnapshot(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'waiting';
    final p1Ready = d['p1_ready'] as bool? ?? false;
    final p2Ready = d['p2_ready'] as bool? ?? false;

    _ropePos      = (d['rope_pos'] as num?)?.toDouble() ?? 0;
    _p1Taps       = (d['p1_taps'] as num?)?.toInt() ?? 0;
    _p2Taps       = (d['p2_taps'] as num?)?.toInt() ?? 0;
    _p1Score      = (d['p1_score'] as num?)?.toInt() ?? 0;
    _p2Score      = (d['p2_score'] as num?)?.toInt() ?? 0;
    _currentRound = (d['current_round'] as num?)?.toInt() ?? 1;
    _winner       = d['winner'] as String? ?? '';

    // Буст соперника
    final oppBoostField = widget.isHost ? 'p2_boost' : 'p1_boost';
    _oppBoostActive = d[oppBoostField] as bool? ?? false;

    if (p1Ready && p2Ready && status == 'waiting' && widget.isHost) {
      _roomRef.update({'status': 'countdown'});
    }

    if (status == 'countdown' &&
        (_localPhase == _TOWPhase.waiting || _localPhase == _TOWPhase.roundOver)) {
      setState(() => _localPhase = _TOWPhase.countdown);
      _startCountdown();
    }

    if (status == 'playing' &&
        (_localPhase == _TOWPhase.countdown || _localPhase == _TOWPhase.roundOver)) {
      _countdownTimer?.cancel();
      setState(() => _localPhase = _TOWPhase.playing);
      _startGameTimer();
    }

    if (status == 'round_over' && _localPhase == _TOWPhase.playing) {
      _gameTimer?.cancel();
      setState(() => _localPhase = _TOWPhase.roundOver);
      _scoreCtrl.forward(from: 0);
      if (widget.isHost) {
        Future.delayed(const Duration(seconds: 3), _startNextRound);
      }
    }

    if (status == 'finished' && !_finished) {
      _finished = true;
      _gameTimer?.cancel();
      setState(() => _localPhase = _TOWPhase.gameOver);
      _handleMatchEnd(d['winner'] as String? ?? '');
    }
  }

  // ── Награды по итогам матча ─────────────────────────────────────────────

  Future<void> _handleMatchEnd(String winner) async {
    final myId   = widget.isHost ? 'p1' : 'p2';
    final iWon   = winner == myId;
    final isDraw = winner == 'draw';

    final userId = await UserService.getOrCreateUser();

    if (iWon) {
      CoinService.addCoins(15);
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: true);
      if (mounted) showWinDialog(context);
    } else if (isDraw) {
      CoinService.addCoins(5);
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: false);
    } else {
      await LeaderboardProvider().updateAfterMatch(userId: userId, win: false);
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _cdCtrl.forward(from: 0);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (widget.isHost) _roomRef.update({'status': 'playing'});
      } else {
        setState(() => _countdown--);
        _cdCtrl.forward(from: 0);
      }
    });
  }

  void _startGameTimer() {
    _timeLeft = _kGameSec;
    _myCombo  = 0;
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
      if (pos < 0) {
        _endRound('p1');
      } else if (pos > 0) {
        _endRound('p2');
      } else {
        _endRound('draw');
      }
    });
  }

  void _endRound(String roundWinner) {
    if (_localPhase == _TOWPhase.roundOver || _finished) return;

    final p1s = _p1Score + (roundWinner == 'p1' ? 1 : 0);
    final p2s = _p2Score + (roundWinner == 'p2' ? 1 : 0);

    if (p1s >= _kMaxRounds || p2s >= _kMaxRounds) {
      // Матч окончен
      final matchWinner = p1s >= _kMaxRounds ? 'p1' : 'p2';
      _roomRef.update({
        'status': 'finished',
        'winner': matchWinner,
        'p1_score': p1s,
        'p2_score': p2s,
      });
    } else {
      _roomRef.update({
        'status': 'round_over',
        'winner': roundWinner,
        'p1_score': p1s,
        'p2_score': p2s,
      });
    }
  }

  void _startNextRound() {
    if (!widget.isHost || _finished) return;
    // Сбрасываем в waiting сначала, чтобы оба игрока поймали countdown
    _roomRef.update({
      'status':        'countdown',
      'rope_pos':      0,
      'p1_taps':       0,
      'p2_taps':       0,
      'p1_ready':      true,
      'p2_ready':      true,
      'p1_boost':      false,
      'p2_boost':      false,
      'current_round': _currentRound + 1,
      'winner':        '',
    });
  }

  // ── Тап ─────────────────────────────────────────────────────────────────

  void _onTap() {
    if (_localPhase != _TOWPhase.playing) return;

    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0).then((_) => _tapCtrl.reverse());

    // Комбо
    final now = DateTime.now();
    final quick = _lastMyTap != null && now.difference(_lastMyTap!).inMilliseconds < 550;
    _lastMyTap = now;

    if (quick) {
      _myCombo++;
    } else {
      _myCombo = 0;
    }

    // Буст при комбо >= _kBoostAt
    if (_myCombo >= _kBoostAt && !_myBoostActive) {
      _myBoostActive = true;
      HapticFeedback.heavyImpact();
      _roomRef.update({_myBoostField: true});
      _myBoostTimer?.cancel();
      _myBoostTimer = Timer(const Duration(seconds: _kBoostSec), () {
        if (mounted) {
          setState(() => _myBoostActive = false);
          _roomRef.update({_myBoostField: false});
        }
      });
    }

    final delta = (widget.isHost ? -1 : 1) * (_myBoostActive ? 1.5 : 1.0);

    _roomRef.update({
      'rope_pos':   FieldValue.increment(delta),
      _myTapsField: FieldValue.increment(1),
    }).then((_) {
      _roomRef.get().then((snap) {
        if (!snap.exists || _finished || _localPhase != _TOWPhase.playing) return;
        final pos = (snap['rope_pos'] as num).toDouble();
        if (widget.isHost) {
          if (pos <= -_kMaxPos) _endRound('p1');
          else if (pos >= _kMaxPos) _endRound('p2');
        }
      });
    });

    setState(() {});
  }

  String _resolveWinnerLabel(String winner) {
    if (winner == 'draw') return '🤝 Ничья!';
    final myId = widget.isHost ? 'p1' : 'p2';
    return winner == myId ? '🏆 Победа!' : '💀 Поражение!';
  }

  String _resolveRoundLabel(String winner) {
    if (winner == 'draw') return 'Ничья в раунде';
    final myId = widget.isHost ? 'p1' : 'p2';
    return winner == myId ? '✅ Ты выиграл раунд!' : '❌ Соперник выиграл раунд';
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF9B6DFF)));
                }

                final d = snap.data!.data() as Map<String, dynamic>;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _handleSnapshot(d);
                });

                if (_localPhase == _TOWPhase.gameOver) return _buildGameOver();
                if (_localPhase == _TOWPhase.roundOver) return _buildRoundOver();

                return Column(children: [
                  _buildTopBar(),
                  Expanded(child: _buildBody()),
                  _buildTapButton(),
                  const SizedBox(height: 32),
                ]);
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1040).withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: const Color(0xFF9B6DFF).withValues(alpha: 0.2))),
      ),
      child: Column(children: [
        // Счёт матча
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ScoreDots(score: _p1Score, maxScore: _kMaxRounds, color: const Color(0xFFFF5E78), reversed: true),
          const SizedBox(width: 12),
          Text('Раунд $_currentRound',
              style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
          const SizedBox(width: 12),
          _ScoreDots(score: _p2Score, maxScore: _kMaxRounds, color: const Color(0xFF00D4A0)),
        ]),
        const SizedBox(height: 8),

        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),

          _PlayerTapCounter(
            emoji: '🔴', label: 'P1', taps: _p1Taps,
            color: const Color(0xFFFF5E78), isMe: widget.isHost,
            boostActive: widget.isHost ? _myBoostActive : _oppBoostActive,
          ),

          const Spacer(),

          if (_localPhase == _TOWPhase.playing)
            _TimerBadge(seconds: _timeLeft)
          else if (_localPhase == _TOWPhase.countdown)
            const Icon(Icons.timer, color: Colors.white38, size: 22)
          else
            const Text('🪢', style: TextStyle(fontSize: 22)),

          const Spacer(),

          _PlayerTapCounter(
            emoji: '🟢', label: 'P2', taps: _p2Taps,
            color: const Color(0xFF00D4A0), isMe: !widget.isHost,
            boostActive: widget.isHost ? _oppBoostActive : _myBoostActive,
          ),

          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.roomId));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Код скопирован!')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1850),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF9B6DFF).withValues(alpha: 0.4)),
              ),
              child: Text(widget.roomId, style: const TextStyle(
                  color: Color(0xFF9B6DFF), fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Центральная часть ────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (_localPhase == _TOWPhase.waiting) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1040).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: const Column(children: [
            Text('⏳', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('Ждём соперника...', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Оба игрока должны открыть игру', style: TextStyle(color: Colors.white30, fontSize: 12)),
          ]),
        ),
      ] else if (_localPhase == _TOWPhase.countdown) ...[
        ScaleTransition(
          scale: _cdScale,
          child: Text('$_countdown', style: const TextStyle(
              color: Colors.white, fontSize: 120, fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Color(0xFF9B6DFF), blurRadius: 40)])),
        ),
        const SizedBox(height: 12),
        const Text('Готовься!', style: TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 4)),
      ] else ...[
        const SizedBox(height: 16),
        _buildRope(),
        const SizedBox(height: 20),
        _buildComboBar(),
      ],
    ]);
  }

  Widget _buildComboBar() {
    if (_myCombo < 2 && !_myBoostActive) return const SizedBox(height: 44);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _myBoostActive
            ? const Color(0xFFFFB347).withValues(alpha: 0.15)
            : const Color(0xFF9B6DFF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _myBoostActive ? const Color(0xFFFFB347).withValues(alpha: 0.5) : const Color(0xFF9B6DFF).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _myBoostActive ? '⚡ БУСТ АКТИВЕН!' : '🔥 КОМБО x$_myCombo  →  Ещё ${_kBoostAt - _myCombo} до буста',
        style: TextStyle(
          color: _myBoostActive ? const Color(0xFFFFB347) : const Color(0xFF9B6DFF),
          fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1,
        ),
      ),
    );
  }

  // ── Канат ────────────────────────────────────────────────────────────────

  Widget _buildRope() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(children: [
          _SideLabel(label: 'P1', color: const Color(0xFFFF5E78), arrow: '←'),
          const Spacer(),
          _SideLabel(label: 'P2', color: const Color(0xFF00D4A0), arrow: '→', reversed: true),
        ]),
        const SizedBox(height: 12),

        LayoutBuilder(builder: (context, constraints) {
          final width   = constraints.maxWidth;
          final norm    = (_ropePos + _kMaxPos) / (2 * _kMaxPos);
          final markerX = norm.clamp(0.0, 1.0) * width;

          return SizedBox(
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Полоска
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF5E78), Color(0xFF4A2080), Color(0xFF00D4A0),
                    ]),
                  ),
                ),
                // Центр
                Center(child: Container(
                  width: 3, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                // Маркер
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  left: markerX - 28, top: 10,
                  child: _RopeKnot(pos: _ropePos, maxPos: _kMaxPos.toDouble()),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),
        Row(children: [
          _WinZone(label: '← Победа P1', color: const Color(0xFFFF5E78)),
          const Spacer(),
          Text(
            _ropePos == 0 ? 'Ровно!' : _ropePos < 0 ? 'P1 тянет!' : 'P2 тянет!',
            style: TextStyle(
              color: _ropePos == 0 ? Colors.white54
                  : _ropePos < 0 ? const Color(0xFFFF5E78)
                  : const Color(0xFF00D4A0),
              fontSize: 13, fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _WinZone(label: 'Победа P2 →', color: const Color(0xFF00D4A0)),
        ]),
      ]),
    );
  }

  // ── Кнопка тапа ─────────────────────────────────────────────────────────

  Widget _buildTapButton() {
    final enabled  = _localPhase == _TOWPhase.playing;
    final myColor  = widget.isHost ? const Color(0xFFFF5E78) : const Color(0xFF00D4A0);
    final boostCol = const Color(0xFFFFB347);
    final activeColor = _myBoostActive ? boostCol : myColor;

    return GestureDetector(
      onTapDown: enabled ? (_) => _onTap() : null,
      child: ScaleTransition(
        scale: _tapAnim,
        child: AnimatedBuilder(
          animation: _boostPulse,
          builder: (_, child) => Transform.scale(
            scale: (_myBoostActive && enabled) ? _boostPulse.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 190, height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled
                  ? RadialGradient(colors: [
                activeColor.withValues(alpha: 0.95),
                activeColor.withValues(alpha: 0.55),
              ])
                  : const RadialGradient(colors: [Color(0xFF2A1850), Color(0xFF1A0A2E)]),
              boxShadow: enabled ? [
                BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 8),
                BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 80, spreadRadius: 16),
              ] : [],
              border: Border.all(
                color: enabled ? activeColor.withValues(alpha: 0.6) : Colors.white12,
                width: 2.5,
              ),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(enabled ? (_myBoostActive ? '⚡' : '💪') : '⏳',
                  style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 8),
              Text(
                enabled ? (_myBoostActive ? 'БУСТ!' : 'ТЯНИ!') : 'Жди...',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Экран конца раунда ───────────────────────────────────────────────────

  Widget _buildRoundOver() {
    final label = _resolveRoundLabel(_winner);
    final won   = label.contains('✅');
    final color = won ? const Color(0xFF00D4A0) : Colors.redAccent;

    return Stack(children: [
      _AnimatedBackground(),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(won ? '✅' : '❌', style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
            color: color, letterSpacing: 1)),
        const SizedBox(height: 28),

        // Текущий счёт матча
        ScaleTransition(
          scale: _scoreScale,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _BigScore(score: _p1Score, color: const Color(0xFFFF5E78), label: 'P1',
                isMe: widget.isHost),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(':', style: TextStyle(color: Colors.white54, fontSize: 36, fontWeight: FontWeight.w900)),
            ),
            _BigScore(score: _p2Score, color: const Color(0xFF00D4A0), label: 'P2',
                isMe: !widget.isHost),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Первый до $_kMaxRounds побед',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 32),
        const CircularProgressIndicator(color: Color(0xFF9B6DFF), strokeWidth: 2),
        const SizedBox(height: 12),
        const Text('Следующий раунд...', style: TextStyle(color: Colors.white54, fontSize: 14)),
      ])),
    ]);
  }

  // ── Экран победы матча ───────────────────────────────────────────────────

  Widget _buildGameOver() {
    final label  = _resolveWinnerLabel(_winner);
    final iWon   = label.contains('Победа');
    final isDraw = label.contains('Ничья');
    final color  = isDraw ? Colors.orange : iWon ? const Color(0xFFFFD700) : const Color(0xFFFF5E78);

    return Stack(children: [
      _AnimatedBackground(),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isDraw ? '🤝' : iWon ? '🏆' : '💀', style: const TextStyle(fontSize: 88)),
        const SizedBox(height: 20),
        Text(label, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color,
            letterSpacing: 2, shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 30)])),
        const SizedBox(height: 20),

        Row(mainAxisSize: MainAxisSize.min, children: [
          _BigScore(score: _p1Score, color: const Color(0xFFFF5E78), label: 'P1', isMe: widget.isHost),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(':', style: TextStyle(color: Colors.white54, fontSize: 36, fontWeight: FontWeight.w900)),
          ),
          _BigScore(score: _p2Score, color: const Color(0xFF00D4A0), label: 'P2', isMe: !widget.isHost),
        ]),

        const SizedBox(height: 12),
        Text('P1: $_p1Taps тапов  •  P2: $_p2Taps тапов',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 48),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _TowButton(
            label: 'В МЕНЮ',
            icon: Icons.home_rounded,
            gradient: const LinearGradient(colors: [Color(0xFF9B6DFF), Color(0xFF5B2DEF)]),
            glowColor: const Color(0xFF7B4DEF),
            onTap: () => Navigator.pop(context),
          ),
        ),
      ])),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// ══════════════════════════════════════════════════════════════════════════════

class _ScoreDots extends StatelessWidget {
  final int score, maxScore;
  final Color color;
  final bool reversed;

  const _ScoreDots({
    required this.score, required this.maxScore,
    required this.color, this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(maxScore, (i) {
      final filled = reversed ? (i < score) : (i < score);
      return Container(
        width: 12, height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : color.withValues(alpha: 0.2),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
      );
    });

    return Row(mainAxisSize: MainAxisSize.min, children: reversed ? dots.reversed.toList() : dots);
  }
}

class _BigScore extends StatelessWidget {
  final int score;
  final Color color;
  final String label;
  final bool isMe;

  const _BigScore({required this.score, required this.color, required this.label, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$score', style: TextStyle(color: color, fontSize: 52, fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 20)])),
      Text('$label${isMe ? ' (ты)' : ''}',
          style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _PlayerTapCounter extends StatelessWidget {
  final String emoji, label;
  final int taps;
  final Color color;
  final bool isMe;
  final bool boostActive;

  const _PlayerTapCounter({
    required this.emoji, required this.label, required this.taps,
    required this.color, required this.isMe, required this.boostActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          label + (isMe ? ' (ты)' : ''),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        if (boostActive) ...[
          const SizedBox(width: 4),
          const Text('⚡', style: TextStyle(fontSize: 12)),
        ],
      ]),
      const SizedBox(height: 2),
      Text('$taps 👊', style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
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
        color: urgent ? const Color(0xFFFF5E78).withValues(alpha: 0.15) : const Color(0xFF2A1850),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgent ? const Color(0xFFFF5E78).withValues(alpha: 0.6) : Colors.white12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer, color: urgent ? const Color(0xFFFF5E78) : Colors.white54, size: 16),
        const SizedBox(width: 4),
        Text('$seconds с', style: TextStyle(
            color: urgent ? const Color(0xFFFF5E78) : Colors.white,
            fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _RopeKnot extends StatelessWidget {
  final double pos, maxPos;
  const _RopeKnot({required this.pos, required this.maxPos});

  @override
  Widget build(BuildContext context) {
    final urgency  = pos.abs() / maxPos;
    final knobColor = pos < 0
        ? Color.lerp(Colors.white, const Color(0xFFFF5E78), urgency)!
        : pos > 0
        ? Color.lerp(Colors.white, const Color(0xFF00D4A0), urgency)!
        : Colors.white;

    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: knobColor,
        border: Border.all(color: const Color(0xFF9B6DFF), width: 3),
        boxShadow: [BoxShadow(color: knobColor.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 2)],
      ),
      child: const Center(child: Text('🪢', style: TextStyle(fontSize: 24))),
    );
  }
}

class _SideLabel extends StatelessWidget {
  final String label, arrow;
  final Color color;
  final bool reversed;
  const _SideLabel({required this.label, required this.color, required this.arrow, this.reversed = false});

  @override
  Widget build(BuildContext context) {
    final text = reversed ? '$label $arrow' : '$arrow $label';
    return Text(text, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12,
        fontWeight: FontWeight.w600, letterSpacing: 1));
  }
}

class _WinZone extends StatelessWidget {
  final String label;
  final Color color;
  const _WinZone({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 0.5));
}

// ── Кнопка меню ─────────────────────────────────────────────────────────────

class _TowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback? onTap;

  const _TowButton({
    required this.label, required this.icon, required this.gradient,
    required this.glowColor, required this.onTap,
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
      onTapUp: widget.onTap != null ? (_) { setState(() => _pressed = false); widget.onTap!(); } : null,
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
            boxShadow: [BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.45),
              blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 6),
            )],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(widget.label, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ]),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF0F0A1E), const Color(0xFF1A0A2E), _ctrl.value)!,
              Color.lerp(const Color(0xFF1A0A2E), const Color(0xFF0D0720), _ctrl.value)!,
            ],
          ),
        ),
        child: CustomPaint(painter: _BgPainter(_ctrl.value)),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final circles = [
      (Offset(size.width * 0.15, size.height * 0.2), 120.0, const Color(0xFF7B4DEF)),
      (Offset(size.width * 0.85, size.height * 0.35), 90.0, const Color(0xFFFF5E78)),
      (Offset(size.width * 0.5, size.height * 0.8), 100.0, const Color(0xFF00C896)),
    ];
    for (final (center, r, color) in circles) {
      canvas.drawCircle(center, r + sin(t * pi * 2) * 15,
          Paint()
            ..color = color.withValues(alpha: 0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.t != t;
}