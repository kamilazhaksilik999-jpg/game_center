// lobby/online/games/tug_of_war/tug_of_war_room.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Константы ──────────────────────────────────────────────────────────────
const int _kMaxPos  = 10;
const int _kGameSec = 30;

// ── Экран создания / входа ────────────────────────────────────────────────

class TugOfWarRoomScreen extends StatefulWidget {
  const TugOfWarRoomScreen({super.key});

  @override
  State<TugOfWarRoomScreen> createState() => _TugOfWarRoomScreenState();
}

class _TugOfWarRoomScreenState extends State<TugOfWarRoomScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    await FirebaseFirestore.instance.collection('tow_rooms').doc(code).set({
      'rope_pos':   0,          // -10..+10; отрицательное = победа p1
      'p1_taps':    0,
      'p2_taps':    0,
      'p1_ready':   false,
      'p2_ready':   false,
      'status':     'waiting',  // waiting | countdown | playing | finished
      'winner':     '',
      'start_at':   null,
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _TowWaitingScreen(code: code)));
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

    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() {
        _error = 'Комната не найдена или уже занята';
        _loading = false;
      });
      return;
    }

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) =>
            TugOfWarOnlineGame(roomId: code, isHost: false)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        leading: BackButton(color: Colors.white54),
        title: const Text('Перетяни канат с другом',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(children: [
          const SizedBox(height: 24),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF7B5DEF).withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🪢', style: TextStyle(fontSize: 46))),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Создать комнату', style: TextStyle(fontSize: 17)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5DEF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
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

          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 24, letterSpacing: 6),
              filled: true,
              fillColor: const Color(0xFF2D1B4E),
              errorText: _error,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7B5DEF), width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7B5DEF), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white54, width: 2)),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _joinRoom,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Войти в комнату', style: TextStyle(fontSize: 17)),
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
              child: CircularProgressIndicator(color: Color(0xFF7B5DEF)),
            ),
        ]),
      ),
    );
  }
}

// ── Экран ожидания (только для хоста) ────────────────────────────────────

class _TowWaitingScreen extends StatefulWidget {
  final String code;
  const _TowWaitingScreen({required this.code});

  @override
  State<_TowWaitingScreen> createState() => _TowWaitingScreenState();
}

class _TowWaitingScreenState extends State<_TowWaitingScreen> {
  StreamSubscription? _sub;
  bool _joined = false;

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
      // Гость пометит p2_ready=false (он вошёл в BattleshipOnlineGame)
      // Для простоты: при первом снапшоте переходим в игру
      if (!_joined) {
        setState(() => _joined = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) =>
                    TugOfWarOnlineGame(roomId: widget.code, isHost: true)));
          }
        });
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🪢', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text('Твоя комната',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Код скопирован!')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1B4E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7B5DEF), width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10)),
                const SizedBox(width: 10),
                const Icon(Icons.copy, color: Colors.white38, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Нажми чтобы скопировать',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 40),

          if (!_joined) ...[
            const CircularProgressIndicator(color: Color(0xFF7B5DEF)),
            const SizedBox(height: 20),
            const Text('Ожидаем друга...',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ] else ...[
            const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 48),
            const SizedBox(height: 12),
            const Text('Друг подключился!',
                style: TextStyle(color: Color(0xFF00C896), fontSize: 16)),
          ],

          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена',
                style: TextStyle(color: Colors.white38)),
          ),
        ]),
      ),
    );
  }
}

// ── Онлайн игра ───────────────────────────────────────────────────────────

class TugOfWarOnlineGame extends StatefulWidget {
  final String roomId;
  final bool isHost;

  const TugOfWarOnlineGame(
      {super.key, required this.roomId, required this.isHost});

  @override
  State<TugOfWarOnlineGame> createState() => _TugOfWarOnlineGameState();
}

enum _TOWPhase { waiting, countdown, playing, gameOver }

class _TugOfWarOnlineGameState extends State<TugOfWarOnlineGame>
    with SingleTickerProviderStateMixin {

  _TOWPhase _localPhase = _TOWPhase.waiting;
  bool _ready = false;
  bool _finished = false;

  // Локально кэшируем данные из Firestore
  double _ropePos = 0;
  int _p1Taps = 0, _p2Taps = 0;
  int _countdown = 3;
  int _timeLeft = _kGameSec;
  String _winner = '';

  Timer? _countdownTimer;
  Timer? _gameTimer;

  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  String get _myTapsField  => widget.isHost ? 'p1_taps' : 'p2_taps';
  String get _myReadyField => widget.isHost ? 'p1_ready' : 'p2_ready';

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    // Пометить себя как готового
    FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(widget.roomId)
        .update({_myReadyField: true});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _tapCtrl.dispose();
    super.dispose();
  }

  // ── Обработка снапшота ────────────────────────────────────────────────────

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
      FirebaseFirestore.instance
          .collection('tow_rooms')
          .doc(widget.roomId)
          .update({'status': 'countdown'});
    }

    if (status == 'countdown' && _localPhase == _TOWPhase.waiting) {
      setState(() => _localPhase = _TOWPhase.countdown);
      _startCountdown();
    }

    if (status == 'playing' && _localPhase == _TOWPhase.countdown) {
      setState(() { _localPhase = _TOWPhase.playing; });
      _startGameTimer();
    }

    if (status == 'finished' && !_finished) {
      _finished = true;
      setState(() { _localPhase = _TOWPhase.gameOver; });
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (widget.isHost) {
          FirebaseFirestore.instance
              .collection('tow_rooms')
              .doc(widget.roomId)
              .update({'status': 'playing'});
        }
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
    // Хост определяет победителя по rope_pos
    FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(widget.roomId)
        .get()
        .then((snap) {
      if (!snap.exists) return;
      final pos = (snap['rope_pos'] as num).toDouble();
      final winner = pos < 0
          ? 'p1'
          : pos > 0
          ? 'p2'
          : 'draw';
      FirebaseFirestore.instance
          .collection('tow_rooms')
          .doc(widget.roomId)
          .update({'status': 'finished', 'winner': winner});
    });
  }

  // ── Тап игрока ───────────────────────────────────────────────────────────

  void _onTap() {
    if (_localPhase != _TOWPhase.playing) return;

    _tapCtrl.forward(from: 0).then((_) => _tapCtrl.reverse());

    // Изменение rope_pos: p1 (хост) тянет влево (−1), p2 тянет вправо (+1)
    final delta = widget.isHost ? -1 : 1;

    FirebaseFirestore.instance
        .collection('tow_rooms')
        .doc(widget.roomId)
        .update({
      'rope_pos': FieldValue.increment(delta),
      _myTapsField: FieldValue.increment(1),
    }).then((_) {
      // Проверяем победу
      FirebaseFirestore.instance
          .collection('tow_rooms')
          .doc(widget.roomId)
          .get()
          .then((snap) {
        if (!snap.exists || _finished) return;
        final pos = (snap['rope_pos'] as num).toDouble();
        if (pos <= -_kMaxPos) {
          _finished = true;
          FirebaseFirestore.instance
              .collection('tow_rooms')
              .doc(widget.roomId)
              .update({'status': 'finished', 'winner': 'p1'});
        } else if (pos >= _kMaxPos) {
          _finished = true;
          FirebaseFirestore.instance
              .collection('tow_rooms')
              .doc(widget.roomId)
              .update({'status': 'finished', 'winner': 'p2'});
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
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        leading: BackButton(color: Colors.white54),
        title: Text('🪢 Комната: ${widget.roomId}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tow_rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          _handleSnapshot(d);

          if (_localPhase == _TOWPhase.gameOver) {
            return _OnlineGameOver(
              result: _resolveWinnerLabel(_winner),
              onExit: () => Navigator.pop(context),
            );
          }

          return Column(
            children: [
              // Верхняя панель
              _OnlineTopBar(
                timeLeft: _timeLeft,
                phase: _localPhase,
                countdown: _countdown,
                p1Taps: _p1Taps,
                p2Taps: _p2Taps,
              ),

              const Spacer(),

              // Статус
              if (_localPhase == _TOWPhase.waiting)
                const _StatusChip(text: '⏳ Ждём соперника...')
              else if (_localPhase == _TOWPhase.countdown)
                _CountdownBig(value: _countdown)
              else ...[
                  // Канат
                  _RopeWidget(position: _ropePos, maxPos: _kMaxPos),
                ],

              const Spacer(),

              // Кнопка
              ScaleTransition(
                scale: _tapScale,
                child: GestureDetector(
                  onTapDown: (_) => _onTap(),
                  child: _BigTapButton(
                    enabled: _localPhase == _TOWPhase.playing,
                    isHost: widget.isHost,
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }
}

// ── Вспомогательные виджеты ──────────────────────────────────────────────────

class _OnlineTopBar extends StatelessWidget {
  final int timeLeft, countdown, p1Taps, p2Taps;
  final _TOWPhase phase;

  const _OnlineTopBar({
    required this.timeLeft,
    required this.phase,
    required this.countdown,
    required this.p1Taps,
    required this.p2Taps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: const Color(0xFF2D1B4E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(children: [
            const Text('👤 P1',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            Text('$p1Taps 👊',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          phase == _TOWPhase.playing
              ? Row(children: [
            const Icon(Icons.timer, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text('$timeLeft с',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ])
              : const Text('🪢',
              style: TextStyle(fontSize: 28)),
          Column(children: [
            const Text('👤 P2',
                style: TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold)),
            Text('$p2Taps 👊',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ],
      ),
    );
  }
}

class _CountdownBig extends StatelessWidget {
  final int value;
  const _CountdownBig({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 96,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Color(0xFF7B5DEF), blurRadius: 30)],
      ),
    );
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
        color: const Color(0xFF2D1B4E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }
}

class _BigTapButton extends StatelessWidget {
  final bool enabled, isHost;
  const _BigTapButton({required this.enabled, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final color = isHost ? Colors.redAccent : const Color(0xFF00C896);
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: enabled
              ? [color.withOpacity(0.9), color.withOpacity(0.5)]
              : [Colors.grey.shade700, Colors.grey.shade900],
        ),
        boxShadow: enabled
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 28, spreadRadius: 4)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(
            enabled ? 'ТЯН И!' : 'Жди...',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
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
    final norm = (position + maxPos) / (2 * maxPos);
    final markerX = norm * (width - 60) + 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [
                Color(0xFFFF3D3D),
                Color(0xFF1A0A2E),
                Color(0xFF00C896),
              ]),
            ),
          ),
          Positioned(
            left: (width - 64) / 2,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: Colors.white24),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            left: markerX - 22,
            top: -8,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF7B5DEF), width: 3),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: const Center(child: Text('🪢', style: TextStyle(fontSize: 20))),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('← P1 (красные)',
              style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 12)),
          Text('P2 (зелёные) →',
              style: TextStyle(color: const Color(0xFF00C896).withOpacity(0.7), fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _OnlineGameOver extends StatelessWidget {
  final String result;
  final VoidCallback onExit;
  const _OnlineGameOver({required this.result, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final iWon = result.contains('Ты победил');
    final isDraw = result.contains('Ничья');
    return Container(
      color: const Color(0xFF1A0A2E),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isDraw ? '🤝' : iWon ? '🏆' : '💀',
              style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(result,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDraw
                      ? Colors.orange
                      : iWon
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF3D3D))),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B5DEF),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('В меню',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}