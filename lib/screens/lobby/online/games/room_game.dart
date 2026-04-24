// lobby/online/games/room_game.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const int _kMaxPos = 10;
const int _kGameSec = 30;

// ── Экран создания / входа ────────────────────────────────────────────────

class RoomGameScreen extends StatefulWidget {
  const RoomGameScreen({super.key});

  @override
  State<RoomGameScreen> createState() => _RoomGameScreenState();
}

class _RoomGameScreenState extends State<RoomGameScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  String _generateCode() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10).toString()).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    await FirebaseFirestore.instance.collection('tow_rooms').doc(code).set({
      'rope_pos': 0, 'p1_taps': 0, 'p2_taps': 0,
      'p1_ready': false, 'p2_ready': false, 'p2_joined': false,
      'status': 'waiting', 'winner': '', 'start_at': null,
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _RoomWaitingScreen(code: code, isHost: true)));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim();

    // Строгая проверка: ТОЛЬКО 6 цифр, ничего больше
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Введи ровно 6 цифр');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance.collection('tow_rooms').doc(code).get();

    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() { _error = 'Комната не найдена или уже занята'; _loading = false; });
      return;
    }

    // Гость ставит метку и идет в экран ожидания (НЕ в игру!)
    await FirebaseFirestore.instance.collection('tow_rooms').doc(code).update({'p2_joined': true});

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _RoomWaitingScreen(code: code, isHost: false)));
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
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF8888AA)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Гонка по лабиринту с другом',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withOpacity(0.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00C896).withOpacity(0.3), width: 2),
                ),
                child: const Center(child: Text('🌀', style: TextStyle(fontSize: 46))),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _createRoom,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Создать комнату', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('или', style: TextStyle(color: const Color(0xFF8888AA).withOpacity(0.5), fontSize: 14)),
                ),
                const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
              ]),
              const SizedBox(height: 24),

              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number, // Только цифры на клавиатуре
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Блокируем буквы на уровне ввода
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: const TextStyle(color: Color(0xFF444466), fontSize: 24, letterSpacing: 6),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white54, width: 2)),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _joinRoom,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Войти в комнату', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    foregroundColor: const Color(0xFF00C896),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
                    elevation: 0,
                  ),
                ),
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(color: Color(0xFF00C896)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Экран жесткой синхронизации (Ожидание) ─────────────────────────────────

class _RoomWaitingScreen extends StatefulWidget {
  final String code;
  final bool isHost;
  const _RoomWaitingScreen({required this.code, required this.isHost});

  @override
  State<_RoomWaitingScreen> createState() => _RoomWaitingScreenState();
}

class _RoomWaitingScreenState extends State<_RoomWaitingScreen> {
  StreamSubscription? _sub;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance.collection('tow_rooms').doc(widget.code).snapshots().listen((snap) {
      if (!snap.exists || _isSyncing) return;
      final d = snap.data() as Map<String, dynamic>;

      if (widget.isHost) {
        // ХОСТ: Ждет пока зайдет гость
        final joined = d['p2_joined'] as bool? ?? false;
        if (joined) {
          _isSyncing = true;
          // Шаг 1 синхронизации: Хост говорит "Я готов к старту"
          FirebaseFirestore.instance.collection('tow_rooms').doc(widget.code).update({'p1_ready': true});

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => RoomOnlineGame(roomId: widget.code, isHost: true),
              ));
            }
          });
        }
      } else {
        // ГОСТЬ: Ждет ответный сигнал от хоста
        final p1Ready = d['p1_ready'] as bool? ?? false;
        if (p1Ready) {
          _isSyncing = true;
          // Шаг 2 синхронизации: Гость говорит "Тоже готов"
          FirebaseFirestore.instance.collection('tow_rooms').doc(widget.code).update({'p2_ready': true});

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => RoomOnlineGame(roomId: widget.code, isHost: false),
              ));
            }
          });
        }
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
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌀', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text('Твоя комната', style: TextStyle(color: Color(0xFF8888AA), fontSize: 16)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Код скопирован!'), backgroundColor: Color(0xFF16213E)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00C896), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.code, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 10)),
                const SizedBox(width: 10),
                const Icon(Icons.copy, color: Color(0xFF8888AA), size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Нажми чтобы скопировать', style: TextStyle(color: Color(0xFF444466), fontSize: 12)),
          const SizedBox(height: 40),

          // Разные тексты для хоста и гостя
          if (!_isSyncing) ...[
            const CircularProgressIndicator(color: Color(0xFF00C896)),
            const SizedBox(height: 20),
            Text(
              widget.isHost ? 'Ожидаем друга...' : 'Синхронизация с хостом...',
              style: const TextStyle(color: Color(0xFF8888AA), fontSize: 16),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 48),
            const SizedBox(height: 12),
            const Text('Подключено! Запуск...', style: TextStyle(color: Color(0xFF00C896), fontSize: 16, fontWeight: FontWeight.bold)),
          ],

          const SizedBox(height: 32),
          TextButton(onPressed: _cancelRoom, child: const Text('Отмена', style: TextStyle(color: Color(0xFFEF5B5B), fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}

// ── Онлайн игра ───────────────────────────────────────────────────────────────

class RoomOnlineGame extends StatefulWidget {
  final String roomId;
  final bool isHost;
  const RoomOnlineGame({super.key, required this.roomId, required this.isHost});

  @override
  State<RoomOnlineGame> createState() => _RoomOnlineGameState();
}

enum _Phase { waiting, countdown, playing, gameOver }

class _RoomOnlineGameState extends State<RoomOnlineGame> with SingleTickerProviderStateMixin {
  _Phase _localPhase = _Phase.waiting;
  bool _finished = false;

  double _ropePos = 0;
  int _p1Taps = 0, _p2Taps = 0;
  int _countdown = 3;
  int _timeLeft = _kGameSec;
  String _winner = '';

  Timer? _countdownTimer;
  Timer? _gameTimer;

  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  // Поля ready больше не трогаем в initState, так как они выставились в комнате ожидания!
  String get _myTapsField => widget.isHost ? 'p1_taps' : 'p2_taps';

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleSnapshot(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'waiting';
    final p1Ready = d['p1_ready'] as bool? ?? false;
    final p2Ready = d['p2_ready'] as bool? ?? false;
    _ropePos = (d['rope_pos'] as num?)?.toDouble() ?? 0;
    _p1Taps = (d['p1_taps'] as num?)?.toInt() ?? 0;
    _p2Taps = (d['p2_taps'] as num?)?.toInt() ?? 0;
    _winner = d['winner'] as String? ?? '';

    // Запуск отсчета ТОЛЬКО когда оба в игре и статус waiting
    if (p1Ready && p2Ready && status == 'waiting' && widget.isHost) {
      FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({'status': 'countdown'});
    }
    if (status == 'countdown' && _localPhase == _Phase.waiting) {
      setState(() => _localPhase = _Phase.countdown);
      _startCountdown();
    }
    if (status == 'playing' && _localPhase == _Phase.countdown) {
      setState(() => _localPhase = _Phase.playing);
      _startGameTimer();
    }
    if (status == 'finished' && !_finished) {
      _finished = true;
      setState(() => _localPhase = _Phase.gameOver);
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (widget.isHost) FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({'status': 'playing'});
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _startGameTimer() {
    _timeLeft = _kGameSec;
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        if (widget.isHost) _resolveTimeout();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _resolveTimeout() {
    FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).get().then((snap) {
      if (!snap.exists) return;
      final pos = (snap['rope_pos'] as num).toDouble();
      final winner = pos < 0 ? 'p1' : pos > 0 ? 'p2' : 'draw';
      FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({'status': 'finished', 'winner': winner});
    });
  }

  void _onTap() {
    if (_localPhase != _Phase.playing) return;
    _tapCtrl.forward(from: 0).then((_) => _tapCtrl.reverse());
    final delta = widget.isHost ? -1 : 1;

    FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({
      'rope_pos': FieldValue.increment(delta),
      _myTapsField: FieldValue.increment(1),
    }).then((_) {
      FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).get().then((snap) {
        if (!snap.exists || _finished) return;
        final pos = (snap['rope_pos'] as num).toDouble();
        if (pos <= -_kMaxPos) {
          _finished = true;
          FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({'status': 'finished', 'winner': 'p1'});
        } else if (pos >= _kMaxPos) {
          _finished = true;
          FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).update({'status': 'finished', 'winner': 'p2'});
        }
      });
    });
  }

  String _resolveWinnerLabel(String winner) {
    if (winner == 'draw') return '🤝 Ничья!';
    final myId = widget.isHost ? 'p1' : 'p2';
    return winner == myId ? 'Ты вышел из лабиринта!' : 'Соперник вышел первым!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tow_rooms').doc(widget.roomId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00C896)));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          _handleSnapshot(d);

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildGameHeader(),
                    const Spacer(),
                    if (_localPhase == _Phase.waiting)
                      const _StatusChip(text: '⏳ Синхронизация игроков...')
                    else if (_localPhase == _Phase.countdown)
                      _CountdownBig(value: _countdown)
                    else
                      _MazeWidget(position: _ropePos, maxPos: _kMaxPos, isHost: widget.isHost),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Center(
                        child: ScaleTransition(
                          scale: _tapScale,
                          child: GestureDetector(
                            onTapDown: (_) => _onTap(),
                            child: _BigTapButton(enabled: _localPhase == _Phase.playing, isHost: widget.isHost),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_localPhase == _Phase.gameOver)
                  Positioned.fill(
                    child: _OnlineGameOver(
                      result: _resolveWinnerLabel(_winner),
                      isWin: _winner == (widget.isHost ? 'p1' : 'p2'),
                      onExit: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF8888AA)),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              const Text('P1', style: TextStyle(color: Color(0xFFEF5B5B), fontSize: 11, fontWeight: FontWeight.bold)),
              Text('$_p1Taps', style: const TextStyle(color: Color(0xFFEF5B5B), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(12)),
            child: _localPhase == _Phase.playing
                ? Row(children: [
              const Icon(Icons.timer, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 6),
              Text('$_timeLeft', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ])
                : Text('${widget.roomId}', style: const TextStyle(color: Color(0xFF8888AA), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3)),
          ),
          Column(
            children: [
              const Text('P2', style: TextStyle(color: Color(0xFF00C896), fontSize: 11, fontWeight: FontWeight.bold)),
              Text('$_p2Taps', style: const TextStyle(color: Color(0xFF00C896), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────────

class _CountdownBig extends StatelessWidget {
  final int value;
  const _CountdownBig({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$value', style: const TextStyle(
      color: Colors.white, fontSize: 96, fontWeight: FontWeight.w900,
      shadows: [Shadow(color: Color(0xFF00C896), blurRadius: 40)],
    ));
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF00C896).withOpacity(0.3)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF8888AA), fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

class _MazeWidget extends StatelessWidget {
  final double position;
  final int maxPos;
  final bool isHost;

  const _MazeWidget({required this.position, required this.maxPos, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final norm = (position + maxPos) / (2 * maxPos);
    final markerX = norm * (width - 80) + 40;
    final mySteps = isHost ? (position < 0 ? (-position).toInt() : 0) : (position > 0 ? position.toInt() : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A4A).withOpacity(0.5), width: 1),
            ),
          ),
          FractionallySizedBox(
            widthFactor: norm.clamp(0.0, 1.0), heightFactor: 1.0, alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0x3300C896), Color(0xFF00C896)]),
              ),
            ),
          ),
          Positioned(left: (width - 64) / 2, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white.withOpacity(0.2))),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut,
            left: markerX - 24, top: -10,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: const Color(0xFF16213E),
                border: Border.all(color: const Color(0xFF00C896), width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.4), blurRadius: 15, spreadRadius: 1)],
              ),
              child: const Center(child: Text('🧩', style: TextStyle(fontSize: 22))),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('← P1', style: TextStyle(color: const Color(0xFFEF5B5B).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
            Text('P2 →', style: TextStyle(color: const Color(0xFF00C896).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          position == 0 ? 'Нажимай — беги по лабиринту!' : position < 0 ? 'P1 впереди на ${(-position).toInt()} шагов!' : 'P2 впереди на ${position.toInt()} шагов!',
          style: TextStyle(
            color: position < 0 ? const Color(0xFFEF5B5B) : position > 0 ? const Color(0xFF00C896) : const Color(0xFF8888AA),
            fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text('Твои шаги: $mySteps / $maxPos', style: const TextStyle(color: Color(0xFF444466), fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _BigTapButton extends StatelessWidget {
  final bool enabled, isHost;
  const _BigTapButton({required this.enabled, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final color = isHost ? const Color(0xFFEF5B5B) : const Color(0xFF00C896);
    final currentColor = enabled ? color : const Color(0xFF16213E);
    return Container(
      width: 180, height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: currentColor,
        border: Border.all(color: enabled ? currentColor.withOpacity(0.5) : const Color(0xFF2A2A4A), width: 4),
        boxShadow: enabled ? [BoxShadow(color: currentColor.withOpacity(0.45), blurRadius: 30, spreadRadius: 4)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run_rounded, color: enabled ? Colors.white : const Color(0xFF444466), size: 52),
          const SizedBox(height: 8),
          Text(enabled ? 'БЕГИ!' : 'Жди...', style: TextStyle(color: enabled ? Colors.white : const Color(0xFF444466), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _OnlineGameOver extends StatelessWidget {
  final String result;
  final bool isWin;
  final VoidCallback onExit;
  const _OnlineGameOver({required this.result, required this.isWin, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final titleColor = result.contains('Ничья') ? const Color(0xFFFFD700) : isWin ? const Color(0xFFFFD700) : const Color(0xFFEF5B5B);
    final title = result.contains('Ничья') ? '🤝 НИЧЬЯ!' : isWin ? '🏆 ПОБЕДА!' : '💀 ПОРАЖЕНИЕ';

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: TextStyle(
            color: titleColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4,
            shadows: [Shadow(color: titleColor.withOpacity(0.6), blurRadius: 20)],
          )),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(result, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8))),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onExit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: const Text('В МЕНЮ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
        ]),
      ),
    );
  }
}