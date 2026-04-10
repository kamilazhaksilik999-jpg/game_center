// lobby/online/games/battleship/battleship_room.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Константы (те же что в battleship_ai.dart) ────────────────────────────────
const int _kSize  = 10;
const int _kTotal = 100;
const List<int> _kShips = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
const int _water = 0, _ship = 1, _miss = 2, _hit = 3;

// ── Экран выбора: создать / войти ─────────────────────────────────────────────

class BattleshipRoomScreen extends StatefulWidget {
  const BattleshipRoomScreen({super.key});

  @override
  State<BattleshipRoomScreen> createState() => _BattleshipRoomScreenState();
}

class _BattleshipRoomScreenState extends State<BattleshipRoomScreen> {
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

    await FirebaseFirestore.instance.collection('bs_rooms').doc(code).set({
      'p1_board':  List.filled(_kTotal, _water),
      'p2_board':  List.filled(_kTotal, _water),
      'p1_ready':  false,
      'p2_ready':  false,
      'turn':      1,
      'status':    'waiting',
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _BSWaitingScreen(code: code, isHost: true)));
  }

  Future<void> _joinRoom() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Введи 6-значный код');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final doc = await FirebaseFirestore.instance.collection('bs_rooms').doc(code).get();
    if (!doc.exists || doc['status'] != 'waiting') {
      setState(() { _error = 'Комната не найдена или занята'; _loading = false; });
      return;
    }

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => BattleshipOnlineGame(roomId: code, isHost: false)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        leading: BackButton(color: Colors.white54),
        title: const Text('Морской бой с другом',
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
              color: const Color(0xFF5B8DEF).withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('⚓', style: TextStyle(fontSize: 46))),
          ),
          const SizedBox(height: 28),

          // Создать
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Создать комнату', style: TextStyle(fontSize: 17)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8DEF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

          // Поле кода
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
                color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.bold, letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 24, letterSpacing: 6),
              filled: true, fillColor: const Color(0xFF0D2137),
              errorText: _error,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white54, width: 2)),
            ),
          ),
          const SizedBox(height: 14),

          // Войти
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(color: Color(0xFF5B8DEF)),
            ),
        ]),
      ),
    );
  }
}

// ── Ожидание гостя (хост) ─────────────────────────────────────────────────────

class _BSWaitingScreen extends StatefulWidget {
  final String code;
  final bool isHost;
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
      // Гость присоединился если кто-то обновил p2_ready
      // (логика: BattleshipOnlineGame при старте сразу открывает расстановку)
      // Здесь просто переходим в игру
      if (!_guestJoined) {
        setState(() => _guestJoined = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) =>
                    BattleshipOnlineGame(roomId: widget.code, isHost: true)));
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
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⚓', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text('Твоя комната', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),

          // Код
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Код скопирован!')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2137),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5B8DEF), width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.code, style: const TextStyle(
                    color: Colors.white, fontSize: 36,
                    fontWeight: FontWeight.w900, letterSpacing: 10)),
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
          ] else ...[
            const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 48),
            const SizedBox(height: 12),
            const Text('Друг подключился! Начинаем...',
                style: TextStyle(color: Color(0xFF00C896), fontSize: 16)),
          ],

          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
          ),
        ]),
      ),
    );
  }
}

// ── Онлайн игра ───────────────────────────────────────────────────────────────

class BattleshipOnlineGame extends StatefulWidget {
  final String roomId;
  final bool isHost;

  const BattleshipOnlineGame({super.key, required this.roomId, required this.isHost});

  @override
  State<BattleshipOnlineGame> createState() => _BattleshipOnlineGameState();
}

enum _OPhase { placing, battle, gameOver }

class _BattleshipOnlineGameState extends State<BattleshipOnlineGame> {
  _OPhase _phase = _OPhase.placing;
  bool _isReady = false;
  bool _finished = false;
  String _message = 'Расставь флот';

  List<int> _myBoard = List.filled(_kTotal, _water);
  List<int> _oppBoard = List.filled(_kTotal, _water);

  int _shipIdx = 0;
  int? _firstCell;

  final Random _rng = Random();

  String get _myPrefix  => widget.isHost ? 'p1' : 'p2';
  String get _oppPrefix => widget.isHost ? 'p2' : 'p1';
  int    get _myTurnNum => widget.isHost ? 1 : 2;

  // ── Расстановка ──────────────────────────────────────────────────────────

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
              : 'Нажми "Готов"!';
        });
        _pushMyBoard();
      }
      return;
    }

    if (_firstCell == null) {
      setState(() { _firstCell = idx; _message = 'Вторая клетка корабля'; });
    } else {
      final cells = _buildCells(_firstCell!, idx, size);
      if (cells != null && _canPlace(_myBoard, cells)) {
        setState(() {
          for (final c in cells) _myBoard[c] = _ship;
          _firstCell = null;
          _shipIdx++;
          _message = _shipIdx < _kShips.length
              ? 'Поставь ${_kShips[_shipIdx]}-палубный'
              : 'Нажми "Готов"!';
        });
        _pushMyBoard();
      } else {
        setState(() { _firstCell = null; _message = 'Неверно! Попробуй снова'; });
      }
    }
  }

  List<int>? _buildCells(int a, int b, int size) {
    final rA = a ~/ _kSize, cA = a % _kSize;
    final rB = b ~/ _kSize, cB = b % _kSize;
    if (rA == rB) {
      final mn = min(cA, cB), mx = max(cA, cB);
      if (mx - mn + 1 == size) return List.generate(size, (k) => rA * _kSize + mn + k);
    } else if (cA == cB) {
      final mn = min(rA, rB), mx = max(rA, rB);
      if (mx - mn + 1 == size) return List.generate(size, (k) => (mn + k) * _kSize + cA);
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
      int tries = 0;
      while (!placed && tries < 1000) {
        tries++;
        final horiz = _rng.nextBool();
        final row = _rng.nextInt(_kSize - (horiz ? 0 : size - 1));
        final col = _rng.nextInt(_kSize - (horiz ? size - 1 : 0));
        final cells = List.generate(size, (k) => horiz
            ? row * _kSize + col + k
            : (row + k) * _kSize + col);
        if (_canPlace(board, cells)) {
          for (final c in cells) board[c] = _ship;
          placed = true;
        }
      }
    }
    setState(() {
      _myBoard = board;
      _shipIdx = _kShips.length;
      _message = 'Нажми "Готов"!';
    });
    _pushMyBoard();
  }

  void _pushMyBoard() {
    FirebaseFirestore.instance.collection('bs_rooms').doc(widget.roomId).update({
      '${_myPrefix}_board': _myBoard,
    });
  }

  void _confirmReady() {
    setState(() { _isReady = true; _message = 'Ждём соперника...'; });
    FirebaseFirestore.instance.collection('bs_rooms').doc(widget.roomId).update({
      '${_myPrefix}_ready': true,
    });
  }

  // ── Выстрел ──────────────────────────────────────────────────────────────

  void _shoot(int idx, List<int> opp, int turn, String status) {
    if (status != 'playing' || turn != _myTurnNum) return;
    if (opp[idx] == _miss || opp[idx] == _hit) return;

    final newVal = opp[idx] == _ship ? _hit : _miss;
    opp[idx] = newVal;

    final nextTurn = (newVal == _hit) ? turn : (turn == 1 ? 2 : 1);

    FirebaseFirestore.instance.collection('bs_rooms').doc(widget.roomId).update({
      '${_oppPrefix}_board': opp,
      'turn': nextTurn,
    });
  }

  // ── Победа ───────────────────────────────────────────────────────────────

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
    setState(() { _phase = _OPhase.gameOver; _message = result; });
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        leading: BackButton(color: Colors.white54),
        title: Text('⚓ Комната: ${widget.roomId}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bs_rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          final p1Board = List<int>.from(d['p1_board'] ?? List.filled(_kTotal, _water));
          final p2Board = List<int>.from(d['p2_board'] ?? List.filled(_kTotal, _water));
          final p1Ready = d['p1_ready'] ?? false;
          final p2Ready = d['p2_ready'] ?? false;
          final turn    = d['turn'] ?? 1;
          final status  = (p1Ready && p2Ready) ? 'playing' : 'waiting';

          _checkWinner(p1Board, p2Board);

          final myBoard  = widget.isHost ? p1Board : p2Board;
          final oppBoard = widget.isHost ? p2Board : p1Board;

          // Обновляем локальные борды
          _myBoard  = myBoard;
          _oppBoard = oppBoard;

          if (status == 'playing' && _phase == _OPhase.placing) {
            _phase = _OPhase.battle;
          }

          final String statusMsg = _phase == _OPhase.gameOver
              ? _message
              : status == 'waiting'
              ? (_isReady ? 'Ждём соперника...' : _message)
              : (turn == _myTurnNum ? '🎯 Твой ход!' : '⏳ Ход соперника');

          if (_phase == _OPhase.gameOver) {
            return _OnlineGameOver(
              result: _message,
              onExit: () => Navigator.pop(context),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              // Статус
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(statusMsg, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              // Поле врага
              _SectionLabel(label: '🎯 Поле соперника', color: Colors.redAccent),
              _OnlineGrid(
                board: oppBoard,
                hideShips: true,
                onTap: (i) => _shoot(i, List<int>.from(oppBoard), turn, status),
                enabled: status == 'playing' && turn == _myTurnNum,
                firstSelected: null,
              ),

              const SizedBox(height: 12),

              // Моё поле
              _SectionLabel(
                label: status == 'waiting' ? '🔧 Мой флот (расстановка)' : '⚓ Мой флот',
                color: Colors.greenAccent,
              ),
              _OnlineGrid(
                board: myBoard,
                hideShips: false,
                onTap: _onMyBoardTap,
                enabled: status == 'waiting' && !_isReady,
                firstSelected: _firstCell,
              ),

              // Кнопки
              if (status == 'waiting' && !_isReady) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton.icon(
                    onPressed: _autoPlace,
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Случайно'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8DEF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _shipIdx >= _kShips.length ? _confirmReady : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Готов!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

// ── Сетка онлайн ─────────────────────────────────────────────────────────────

class _OnlineGrid extends StatelessWidget {
  final List<int> board;
  final bool hideShips, enabled;
  final Function(int) onTap;
  final int? firstSelected;

  const _OnlineGrid({
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
      width: size, height: size,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _kSize),
        itemCount: _kTotal,
        itemBuilder: (_, i) {
          final val = board[i];
          Color bg;
          Widget child = const SizedBox();

          if (val == _ship && !hideShips) {
            bg = const Color(0xFF4A5568);
          } else if (val == _hit) {
            bg = const Color(0xFFE53E3E);
            child = const Icon(Icons.local_fire_department, color: Colors.white, size: 12);
          } else if (val == _miss) {
            bg = const Color(0xFF2D5A8E);
            child = const Icon(Icons.close, color: Colors.white54, size: 10);
          } else {
            bg = const Color(0xFF1A3A5C);
          }

          final sel = firstSelected == i;
          if (sel) bg = const Color(0xFF48BB78);

          return GestureDetector(
            onTap: enabled ? () => onTap(i) : null,
            child: Container(
              margin: const EdgeInsets.all(0.8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(1),
                border: Border.all(
                    color: sel ? Colors.greenAccent : Colors.black26,
                    width: sel ? 1.5 : 0.5),
              ),
              child: Center(child: child),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
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
    return Container(
      color: const Color(0xFF0A1628),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(iWon ? '🏆' : '💀', style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(result, style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
              color: iWon ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D))),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('В меню', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}