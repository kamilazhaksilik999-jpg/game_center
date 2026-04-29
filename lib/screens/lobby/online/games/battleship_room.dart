// lobby/online/games/battleship/battleship_room.dart
<<<<<<< HEAD

=======
//
// Стиль: точно как BattleshipAIScreen
// Код комнаты: только цифры, 6 знаков
import 'tank_room.dart';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const int _kSize = 10;
const int _kTotal = 100;
const List<int> _kShips = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
const int _water = 0, _ship = 1, _miss = 2, _hit = 3;

<<<<<<< HEAD
// ── Экран выбора ──────────────────────────────────────────────────────────────
=======
// ── Экран выбора комнаты ──────────────────────────────────────────────────────
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761

class BattleshipRoomScreen extends StatefulWidget {
  const BattleshipRoomScreen({super.key});

  @override
  State<BattleshipRoomScreen> createState() => _BattleshipRoomScreenState();
}

class _BattleshipRoomScreenState extends State<BattleshipRoomScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  /// Генерирует 6-значный цифровой код
  String _generateCode() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10).toString()).join();
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final code = _generateCode();

    await FirebaseFirestore.instance.collection('bs_rooms').doc(code).set({
<<<<<<< HEAD
      'p1_board': List.filled(_kTotal, _water),
      'p2_board': List.filled(_kTotal, _water),
      'p1_ready': false,
      'p2_ready': false,
      'p2_joined': false,
      'turn': 1,
      'status': 'waiting',
      'created_at': FieldValue.serverTimestamp(),
=======
      'p1_board'   : List.filled(_kTotal, _water),
      'p2_board'   : List.filled(_kTotal, _water),
      'p1_ready'   : false,
      'p2_ready'   : false,
      'p2_joined'  : false,
      'turn'       : 1,
      'status'     : 'waiting',
      'created_at' : FieldValue.serverTimestamp(),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => _BSWaitingScreen(code: code, isHost: true),
    ));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim();
<<<<<<< HEAD
    if (code.length != 6 || !RegExp(r'^\d+$').hasMatch(code)) {
=======

    // Только цифры, ровно 6 знаков
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      setState(() => _error = 'Введи 6-значный цифровой код');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(code)
        .get();

    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() {
<<<<<<< HEAD
        _error = 'Комната не найдена или занята';
=======
        _error   = 'Комната не найдена или уже занята';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        _loading = false;
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(code)
        .update({'p2_joined': true});

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => BattleshipOnlineGame(roomId: code, isHost: false),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
<<<<<<< HEAD
        leading: BackButton(color: Colors.white54),
        title: const Text('Морской бой с другом',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
=======
        leading: const BackButton(color: Colors.white54),
        title: const Text(
          'Морской бой с другом',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        centerTitle: true,
        elevation: 0,
      ),
<<<<<<< HEAD
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(children: [
          const SizedBox(height: 24),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8DEF).withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('⚓', style: TextStyle(fontSize: 46))),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: const Icon(Icons.add_circle_outline),
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
          const SizedBox(height: 24),

          Row(children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('или',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
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
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 24, letterSpacing: 6),
              filled: true,
              fillColor: const Color(0xFF0D2137),
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Color(0xFF5B8DEF), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Color(0xFF5B8DEF), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Colors.white54, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _joinRoom,
              icon: const Icon(Icons.login_rounded),
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
              child: CircularProgressIndicator(color: Color(0xFF5B8DEF)),
            ),
        ]),
=======
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Иконка
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8DEF).withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⚓', style: TextStyle(fontSize: 46)),
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка «Создать комнату»
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _createRoom,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Создать комнату',
                    style: TextStyle(fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8DEF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF5B8DEF).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Разделитель «или»
              Row(children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'или',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ]),
              const SizedBox(height: 28),

              // Поле ввода кода (только цифры)
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 28,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D2137),
                  errorText: _error,
                  errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Только цифры, 6 знаков',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Кнопка «Войти в комнату»
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _joinRoom,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Войти в комнату',
                    style: TextStyle(fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF00C896).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: CircularProgressIndicator(color: Color(0xFF5B8DEF)),
                ),
            ],
          ),
        ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      ),
    );
  }
}

// ── Экран ожидания гостя ─────────────────────────────────────────────────────

class _BSWaitingScreen extends StatefulWidget {
  final String code;
  final bool   isHost;
  const _BSWaitingScreen({required this.code, required this.isHost});

  @override
  State<_BSWaitingScreen> createState() => _BSWaitingScreenState();
}

class _BSWaitingScreenState extends State<_BSWaitingScreen> {
  StreamSubscription? _sub;
  bool _guestJoined = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('bs_rooms')
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
                  BattleshipOnlineGame(roomId: widget.code, isHost: true),
            ));
          }
        });
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _cancelRoom() async {
    await FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(widget.code)
        .delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
<<<<<<< HEAD
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⚓', style: TextStyle(fontSize: 64)),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2137),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: const Color(0xFF5B8DEF), width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                    )),
                const SizedBox(width: 10),
                const Icon(Icons.copy, color: Colors.white38, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Нажми чтобы скопировать',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 40),

          if (!_guestJoined) ...[
            const CircularProgressIndicator(color: Color(0xFF5B8DEF)),
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

          const SizedBox(height: 32),
          TextButton(
            onPressed: _cancelRoom,
            child: const Text('Отмена',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ]),
=======
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        leading: const BackButton(color: Colors.white54),
        title: const Text(
          'Морской бой с другом',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚓', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),

              // Заголовок
              const Text(
                'Твоя комната',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Блок с кодом — нажать чтобы скопировать
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Код скопирован!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF5B8DEF), width: 2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      widget.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy, color: Colors.white38, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Нажми, чтобы скопировать',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 40),

              // Статус ожидания / подтверждения
              if (!_guestJoined) ...[
                const CircularProgressIndicator(color: Color(0xFF5B8DEF)),
                const SizedBox(height: 20),
                const Text(
                  'Ожидаем друга...',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Поделись кодом с другом',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ] else ...[
                const Icon(Icons.check_circle,
                    color: Color(0xFF00C896), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Друг подключился! Начинаем...',
                  style: TextStyle(
                      color: Color(0xFF00C896), fontSize: 16),
                ),
              ],

              const SizedBox(height: 36),

              // Статус-бар в стиле AI-экрана
              _StatusBar(
                message: _guestJoined
                    ? '✅ Соединение установлено'
                    : '🔵 Ожидание подключения по коду',
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: _cancelRoom,
                child: const Text(
                  'Отмена',
                  style: TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
              ),
            ]),
          ),
        ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      ),
    );
  }
}

// ── Онлайн игра ───────────────────────────────────────────────────────────────

class BattleshipOnlineGame extends StatefulWidget {
  final String roomId;
  final bool   isHost;

  const BattleshipOnlineGame(
      {super.key, required this.roomId, required this.isHost});

  @override
  State<BattleshipOnlineGame> createState() => _BattleshipOnlineGameState();
}

enum _OPhase { placing, battle, gameOver }

class _BattleshipOnlineGameState extends State<BattleshipOnlineGame> {
<<<<<<< HEAD
  _OPhase _phase = _OPhase.placing;
  bool _isReady = false;
  bool _finished = false;
  String _message = 'Расставь флот';
=======
  _OPhase _phase   = _OPhase.placing;
  bool    _isReady = false;
  bool    _finished = false;
  String  _message = 'Расставь флот';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761

  List<int> _myBoard = List.filled(_kTotal, _water);
  List<int> _oppBoard = List.filled(_kTotal, _water);

<<<<<<< HEAD
  int _shipIdx = 0;
=======
  int  _shipIdx  = 0;
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
  int? _firstCell;

  final Random _rng = Random();
  StreamSubscription? _sub;

  String get _myPrefix => widget.isHost ? 'p1' : 'p2';
  String get _oppPrefix => widget.isHost ? 'p2' : 'p1';
<<<<<<< HEAD
  int get _myTurnNum => widget.isHost ? 1 : 2;
=======
  int    get _myTurnNum => widget.isHost ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _listenRoom();
  }

  void _listenRoom() {
    _sub = FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || _finished) return;
      final d = snap.data()!;

      final rawOpp = d['${_oppPrefix}_board'] as List<dynamic>?;
      if (rawOpp != null) {
        final oppBoard = rawOpp.cast<int>();
        final status   = d['status'] as String? ?? 'playing';
        final turn     = d['turn']   as int?    ?? 1;
        final myReady  = d['${_myPrefix}_ready']  as bool? ?? false;
        final oppReady = d['${_oppPrefix}_ready'] as bool? ?? false;

        setState(() {
          if (_phase == _OPhase.battle) {
            for (int i = 0; i < _kTotal; i++) {
              if (oppBoard[i] == _miss || oppBoard[i] == _hit) {
                _oppBoard[i] = oppBoard[i];
              }
            }
            final myTurn = turn == _myTurnNum;
            if (status == 'done') {
              _phase   = _OPhase.gameOver;
              _message = d['winner'] == _myPrefix
                  ? 'Ты победил! 🏆'
                  : 'Противник победил 💀';
              _finished = true;
            } else {
              _message = myTurn ? 'Твой ход!' : 'Ход противника...';
            }
          } else if (_phase == _OPhase.placing) {
            if (myReady && oppReady) {
              _phase   = _OPhase.battle;
              _message = turn == _myTurnNum ? 'Твой ход!' : 'Ход противника...';
            } else if (myReady && !oppReady) {
              _message = 'Ждём противника...';
            }
          }
        });
      }
    });
  }
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761

  void _onMyBoardTap(int idx) {
    if (_isReady || _phase != _OPhase.placing) return;
    final size = _kShips[_shipIdx];

    if (size == 1) {
      if (_myBoard[idx] == _ship) {
        setState(() => _myBoard[idx] = _water);
        _pushMyBoard();
        return;
      }
      if (_canPlace(_myBoard, [idx])) {
        setState(() {
          _myBoard[idx] = _ship;
          _shipIdx++;
          _message = _shipIdx < _kShips.length
              ? 'Поставь ${_kShips[_shipIdx]}-палубный'
              : 'Нажми "Готов!"';
        });
        _pushMyBoard();
      }
      return;
    }

    if (_firstCell == null) {
      setState(() {
        _firstCell = idx;
<<<<<<< HEAD
        _message = 'Вторая клетка корабля';
=======
        _message   = 'Вторая клетка корабля';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      });
    } else {
      final cells = _buildCells(_firstCell!, idx, size);
      if (cells != null && _canPlace(_myBoard, cells)) {
        setState(() {
          for (final c in cells) _myBoard[c] = _ship;
          _firstCell = null;
          _shipIdx++;
          _message = _shipIdx < _kShips.length
              ? 'Поставь ${_kShips[_shipIdx]}-палубный'
              : 'Нажми "Готов!"';
        });
        _pushMyBoard();
      } else {
        setState(() {
          _firstCell = null;
<<<<<<< HEAD
          _message = 'Неверно! Попробуй снова';
=======
          _message   = 'Неверно! Попробуй снова';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        });
      }
    }
  }

  void _onEnemyTap(int idx) {
    if (_phase != _OPhase.battle) return;
    // Ход разрешён только в свой ход — проверяем через Firestore turn
    FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(widget.roomId)
        .get()
        .then((snap) {
      if (!snap.exists) return;
      final d    = snap.data()!;
      final turn = d['turn'] as int? ?? 1;
      if (turn != _myTurnNum) return;

      final oppBoard = (d['${_oppPrefix}_board'] as List).cast<int>();
      if (oppBoard[idx] == _miss || oppBoard[idx] == _hit) return;

      final isHit = oppBoard[idx] == _ship;
      oppBoard[idx] = isHit ? _hit : _miss;

      final allSunk = !oppBoard.contains(_ship);
      final update  = <String, dynamic>{
        '${_oppPrefix}_board': oppBoard,
        'turn'               : isHit ? _myTurnNum : (3 - _myTurnNum),
      };
      if (allSunk) {
        update['status'] = 'done';
        update['winner'] = _myPrefix;
      }
      FirebaseFirestore.instance
          .collection('bs_rooms')
          .doc(widget.roomId)
          .update(update);

      setState(() {
        _oppBoard[idx] = isHit ? _hit : _miss;
        _message = isHit
            ? (allSunk ? 'Ты победил! 🏆' : '🔥 Попал! Стреляй снова!')
            : 'Мимо. Ход противника...';
      });
    });
  }

  List<int>? _buildCells(int a, int b, int size) {
    final rA = a ~/ _kSize, cA = a % _kSize;
    final rB = b ~/ _kSize, cB = b % _kSize;
    if (rA == rB) {
      final mn = min(cA, cB), mx = max(cA, cB);
      if (mx - mn + 1 == size)
        return List.generate(size, (k) => rA * _kSize + mn + k);
    } else if (cA == cB) {
      final mn = min(rA, rB), mx = max(rA, rB);
      if (mx - mn + 1 == size)
        return List.generate(size, (k) => (mn + k) * _kSize + cA);
    }
    return null;
  }

  bool _canPlace(List<int> board, List<int> cells) {
    for (final c in cells) {
      if (board[c] != _water) return false;
      final r = c ~/ _kSize, col = c % _kSize;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = r + dr, nc = col + dc;
          if (nr < 0 || nr >= _kSize || nc < 0 || nc >= _kSize) continue;
          if (board[nr * _kSize + nc] == _ship) return false;
        }
      }
    }
    return true;
  }

  void _autoPlace() {
    final board = List.filled(_kTotal, _water);
    for (final size in _kShips) {
      bool placed = false;
      int  tries  = 0;
      while (!placed && tries < 1000) {
        tries++;
        final horiz = _rng.nextBool();
        final row   = _rng.nextInt(_kSize - (horiz ? 0 : size - 1));
        final col   = _rng.nextInt(_kSize - (horiz ? size - 1 : 0));
        final cells = List.generate(
            size,
                (k) => horiz
                ? row * _kSize + col + k
                : (row + k) * _kSize + col);
        if (_canPlace(board, cells)) {
          for (final c in cells) board[c] = _ship;
          placed = true;
        }
      }
    }
    setState(() {
<<<<<<< HEAD
      _myBoard = board;
      _shipIdx = _kShips.length;
      _message = 'Нажми "Готов"!';
=======
      _myBoard   = board;
      _shipIdx   = _kShips.length;
      _firstCell = null;
      _message   = 'Нажми "Готов!"';
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
    });
    _pushMyBoard();
  }

  void _pushMyBoard() {
    FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(widget.roomId)
        .update({'${_myPrefix}_board': _myBoard});
  }

<<<<<<< HEAD
  void _confirmReady() {
    setState(() {
      _isReady = true;
      _message = 'Ждём соперника...';
    });
    FirebaseFirestore.instance
=======
  Future<void> _confirmReady() async {
    setState(() {
      _isReady = true;
      _message = 'Ждём противника...';
    });
    await FirebaseFirestore.instance
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        .collection('bs_rooms')
        .doc(widget.roomId)
        .update({'${_myPrefix}_ready': true});
  }

<<<<<<< HEAD
  void _shoot(int idx, List<int> opp, int turn, String status) {
    if (status != 'playing' || turn != _myTurnNum) return;
    if (opp[idx] == _miss || opp[idx] == _hit) return;

    final newVal = opp[idx] == _ship ? _hit : _miss;
    opp[idx] = newVal;
    final nextTurn = (newVal == _hit) ? turn : (turn == 1 ? 2 : 1);

    FirebaseFirestore.instance
        .collection('bs_rooms')
        .doc(widget.roomId)
        .update({'${_oppPrefix}_board': opp, 'turn': nextTurn});
  }

  void _checkWinner(List<int> p1, List<int> p2) {
    if (_finished) return;
    if (!p1.contains(_ship) && p1.any((v) => v == _hit)) {
      _endGame(widget.isHost ? 'Гость победил' : 'Ты победил!');
    } else if (!p2.contains(_ship) && p2.any((v) => v == _hit)) {
      _endGame(widget.isHost ? 'Ты победил!' : 'Гость победил');
    }
  }

  void _endGame(String result) {
    if (_finished) return;
    _finished = true;
    setState(() {
      _phase = _OPhase.gameOver;
      _message = result;
    });
  }
=======
  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761

  @override
  Widget build(BuildContext context) {
    if (_phase == _OPhase.gameOver) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: _OnlineGameOver(
          result: _message,
          onExit: () => Navigator.pop(context),
        ),
      );
    }

    final wide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
<<<<<<< HEAD
        leading: BackButton(color: Colors.white54),
        title: Text('⚓ Комната: ${widget.roomId}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
=======
        leading: const BackButton(color: Colors.white54),
        title: const Text(
          'Морской бой',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        centerTitle: true,
        elevation: 0,
      ),
<<<<<<< HEAD
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bs_rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
                child:
                CircularProgressIndicator(color: Colors.tealAccent));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          final p1Board = List<int>.from(
              d['p1_board'] ?? List.filled(_kTotal, _water));
          final p2Board = List<int>.from(
              d['p2_board'] ?? List.filled(_kTotal, _water));
          final p1Ready = d['p1_ready'] ?? false;
          final p2Ready = d['p2_ready'] ?? false;
          final turn = d['turn'] ?? 1;
          final status =
          (p1Ready && p2Ready) ? 'playing' : 'waiting';

          _checkWinner(p1Board, p2Board);

          final myBoard = widget.isHost ? p1Board : p2Board;
          final oppBoard = widget.isHost ? p2Board : p1Board;
          _myBoard = myBoard;
          _oppBoard = oppBoard;

          if (status == 'playing' && _phase == _OPhase.placing) {
            _phase = _OPhase.battle;
          }

          final statusMsg = _phase == _OPhase.gameOver
              ? _message
              : status == 'waiting'
              ? (_isReady ? 'Ждём соперника...' : _message)
              : (turn == _myTurnNum
              ? '🎯 Твой ход!'
              : '⏳ Ход соперника');

          if (_phase == _OPhase.gameOver) {
            return _OnlineGameOver(
              result: _message,
              onExit: () => Navigator.pop(context),
            );
          }

          return LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return isWide
                ? _buildWide(constraints, myBoard, oppBoard, status,
                turn, statusMsg)
                : _buildNarrow(
                myBoard, oppBoard, status, turn, statusMsg);
          });
        },
=======
      body: SafeArea(
        child: wide ? _buildWide() : _buildNarrow(),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildWide(BoxConstraints constraints, List<int> myBoard,
      List<int> oppBoard, String status, int turn, String statusMsg) {
    const hPad = 16.0;
    const gap = 24.0;
    final availW = constraints.maxWidth - hPad * 2 - gap;
    final gridSize = (availW / 2).clamp(0.0, 420.0);

    return Column(children: [
      _StatusBar(message: statusMsg),
      const SizedBox(height: 6),
      if (status == 'waiting' && !_isReady)
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
          child: Row(children: [
            ElevatedButton.icon(
              onPressed: _autoPlace,
              icon: const Icon(Icons.shuffle, size: 16),
              label: const Text('Случайно'),
              style: _btnStyle(const Color(0xFF5B8DEF)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed:
              _shipIdx >= _kShips.length ? _confirmReady : null,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Готов!'),
              style: _btnStyle(const Color(0xFF00C896)),
            ),
          ]),
        )
      else
        const SizedBox(height: 44),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoardPanel(
              label: status == 'waiting'
                  ? '🔧 Мой флот'
                  : '⚓ Мой флот',
              labelColor: Colors.greenAccent,
              size: gridSize,
              board: myBoard,
              hideShips: false,
              enabled: status == 'waiting' && !_isReady,
              onTap: _onMyBoardTap,
              firstSelected: _firstCell,
            ),
            const SizedBox(width: gap),
            _BoardPanel(
              label: '🎯 Поле соперника',
              labelColor: Colors.redAccent,
              size: gridSize,
              board: oppBoard,
              hideShips: true,
              enabled: status == 'playing' && turn == _myTurnNum,
              onTap: (i) =>
                  _shoot(i, List<int>.from(oppBoard), turn, status),
=======
  // ── Широкий layout (планшет/ноутбук) ─────────────────────────────────────

  Widget _buildWide() {
    const boardSize = 280.0;
    return Column(children: [
      _StatusBar(message: _message),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BoardPanel(
              label      : 'МОЙ ФЛОТ',
              labelColor : const Color(0xFF00C896),
              size       : boardSize,
              board      : _myBoard,
              hideShips  : false,
              enabled    : _phase == _OPhase.placing && !_isReady,
              onTap      : _onMyBoardTap,
              firstSelected: _firstCell,
            ),
            _BoardPanel(
              label      : 'ПОЛЕ ВРАГА',
              labelColor : const Color(0xFFFF6B6B),
              size       : boardSize,
              board      : _oppBoard,
              hideShips  : true,
              enabled    : _phase == _OPhase.battle,
              onTap      : _onEnemyTap,
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
              firstSelected: null,
            ),
          ],
        ),
      ),
<<<<<<< HEAD
    ]);
  }

  Widget _buildNarrow(List<int> myBoard, List<int> oppBoard,
      String status, int turn, String statusMsg) {
=======
      if (_phase == _OPhase.placing) _buildPlacingButtons(),
      const SizedBox(height: 12),
    ]);
  }

  // ── Узкий layout (телефон) ───────────────────────────────────────────────

  Widget _buildNarrow() {
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
    return SingleChildScrollView(
      child: Column(children: [
<<<<<<< HEAD
        _StatusBar(message: statusMsg),
        const SizedBox(height: 8),
        _SectionLabel(label: '🎯 Поле соперника', color: Colors.redAccent),
        _Grid(
          board: oppBoard,
          hideShips: true,
          onTap: (i) =>
              _shoot(i, List<int>.from(oppBoard), turn, status),
          enabled: status == 'playing' && turn == _myTurnNum,
          firstSelected: null,
        ),
        const SizedBox(height: 12),
        _SectionLabel(
          label: status == 'waiting'
              ? '🔧 Мой флот (расстановка)'
              : '⚓ Мой флот',
          color: Colors.greenAccent,
        ),
        _Grid(
          board: myBoard,
          hideShips: false,
          onTap: _onMyBoardTap,
          enabled: status == 'waiting' && !_isReady,
          firstSelected: _firstCell,
        ),
        if (status == 'waiting' && !_isReady) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
              onPressed: _autoPlace,
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('Случайно'),
              style: _btnStyle(const Color(0xFF5B8DEF)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed:
              _shipIdx >= _kShips.length ? _confirmReady : null,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Готов!'),
              style: _btnStyle(const Color(0xFF00C896)),
            ),
          ]),
=======
        _StatusBar(message: _message),
        if (_phase == _OPhase.placing) ...[
          const _SectionLabel(label: 'МОЙ ФЛОТ', color: Color(0xFF00C896)),
          _Grid(
            board     : _myBoard,
            hideShips : false,
            enabled   : !_isReady,
            onTap     : _onMyBoardTap,
            firstSelected: _firstCell,
          ),
          _buildPlacingButtons(),
        ] else ...[
          const _SectionLabel(label: 'МОЙ ФЛОТ',   color: Color(0xFF00C896)),
          _Grid(
            board     : _myBoard,
            hideShips : false,
            enabled   : false,
            onTap     : (_) {},
            firstSelected: null,
          ),
          const _SectionLabel(label: 'ПОЛЕ ВРАГА', color: Color(0xFFFF6B6B)),
          _Grid(
            board     : _oppBoard,
            hideShips : true,
            enabled   : true,
            onTap     : _onEnemyTap,
            firstSelected: null,
          ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildPlacingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton.icon(
          onPressed: _isReady ? null : _autoPlace,
          icon : const Icon(Icons.shuffle, size: 18),
          label: const Text('Случайно'),
          style: _btnStyle(const Color(0xFF5B8DEF)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: (_shipIdx >= _kShips.length && !_isReady) ? _confirmReady : null,
          icon : const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Готов!'),
          style: _btnStyle(const Color(0xFF00C896)),
        ),
      ]),
    );
  }

  ButtonStyle _btnStyle(Color bg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: Colors.white,
<<<<<<< HEAD
    padding:
    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
  );
}

// ── Общие виджеты ─────────────────────────────────────────────────────────────
=======
    disabledBackgroundColor: bg.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ── Общие виджеты (идентичны AI-экрану) ──────────────────────────────────────
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761

class _BoardPanel extends StatelessWidget {
  final String   label;
  final Color    labelColor;
  final double   size;
  final List<int> board;
  final bool     hideShips, enabled;
  final Function(int) onTap;
  final int?     firstSelected;

  const _BoardPanel({
    required this.label,
    required this.labelColor,
    required this.size,
    required this.board,
    required this.hideShips,
    required this.enabled,
    required this.onTap,
    required this.firstSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
<<<<<<< HEAD
        height: 26,
        child: Text(label,
            style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.8)),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: size,
        height: size,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _kSize),
          itemCount: _kTotal,
          itemBuilder: (_, i) => _Cell(
            value: board[i],
            hideShip: hideShips,
            isSelected: firstSelected == i,
            onTap: enabled ? () => onTap(i) : null,
          ),
        ),
      ),
=======
        height: 28,
        child: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: size, height: size,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _kSize),
          itemCount: _kTotal,
          itemBuilder: (_, i) => _Cell(
            value       : board[i],
            hideShip    : hideShips,
            isSelected  : firstSelected == i,
            onTap       : enabled ? () => onTap(i) : null,
          ),
        ),
      ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
    ]);
  }
}

class _Grid extends StatelessWidget {
  final List<int>     board;
  final bool          hideShips, enabled;
  final Function(int) onTap;
  final int?          firstSelected;

  const _Grid({
    required this.board,
    required this.hideShips,
    required this.enabled,
    required this.onTap,
    required this.firstSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width - 32;
    return SizedBox(
      width: size,
      height: size,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _kSize),
        itemCount: _kTotal,
        itemBuilder: (_, i) => _Cell(
          value      : board[i],
          hideShip   : hideShips,
          isSelected : firstSelected == i,
          onTap      : enabled ? () => onTap(i) : null,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int          value;
  final bool         hideShip, isSelected;
  final VoidCallback? onTap;

  const _Cell({
    required this.value,
    required this.hideShip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color  bg    = const Color(0xFF1A3A5C);
    Widget child = const SizedBox();

    if (value == _ship && !hideShip) {
      bg = const Color(0xFF4A5568);
    } else if (value == _hit) {
<<<<<<< HEAD
      bg = const Color(0xFFE53E3E);
=======
      bg    = const Color(0xFFE53E3E);
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
      child = const Icon(Icons.local_fire_department,
          color: Colors.white, size: 10);
    } else if (value == _miss) {
      bg    = const Color(0xFF2D5A8E);
      child = const Icon(Icons.close, color: Colors.white54, size: 8);
    }

    if (isSelected) bg = const Color(0xFF48BB78);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.7),
        decoration: BoxDecoration(
          color        : bg,
          borderRadius : BorderRadius.circular(1.5),
          border       : Border.all(
            color: isSelected ? Colors.greenAccent : Colors.black26,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String message;
  const _StatusBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color        : const Color(0xFF0D2137),
          borderRadius : BorderRadius.circular(12),
          border       : Border.all(color: Colors.white12),
        ),
        child: Text(message,
            textAlign: TextAlign.center,
            style:
            const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color  color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
<<<<<<< HEAD
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1)),
=======
      child: Text(
        label,
        style: TextStyle(
          color      : color,
          fontWeight : FontWeight.bold,
          fontSize   : 15,
          letterSpacing: 1,
        ),
      ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
    );
  }
}

<<<<<<< HEAD
=======
// ── Game Over ─────────────────────────────────────────────────────────────────

>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
class _OnlineGameOver extends StatelessWidget {
  final String       result;
  final VoidCallback onExit;

  const _OnlineGameOver({required this.result, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final iWon = result.contains('Ты победил');
    return Container(
      color: const Color(0xFF0A1628),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(iWon ? '🏆' : '💀',
              style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
<<<<<<< HEAD
          Text(result,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: iWon
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF3D3D))),
=======
          Text(
            iWon ? 'Победа!' : 'Поражение',
            style: TextStyle(
              fontSize   : 36,
              fontWeight : FontWeight.w900,
              color      : iWon
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF3D3D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
<<<<<<< HEAD
            ),
            child: const Text('В меню',
                style: TextStyle(fontSize: 18, color: Colors.white)),
=======
            ),
            child: const Text(
              'В меню',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
>>>>>>> 618ce7ee981c0d20f2ff4661020287d78909d761
          ),
        ]),
      ),
    );
  }
}