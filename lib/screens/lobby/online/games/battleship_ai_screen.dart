// lobby/online/games/battleship/battleship_ai.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Константы ──────────────────────────────────────────────────────────────────
const int _kSize = 10;      // 10x10 сетка
const int _kTotal = 100;
// Корабли: [4-палубный x1, 3-палубный x2, 2-палубный x3, 1-палубный x4]
const List<int> _kShips = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

// Значения клеток
const int _water   = 0;  // вода (не видна врагу)
const int _ship    = 1;  // корабль (не видна врагу)
const int _miss    = 2;  // промах
const int _hit     = 3;  // попадание

// ── Экран игры против ИИ ──────────────────────────────────────────────────────

class BattleshipAIScreen extends StatefulWidget {
  const BattleshipAIScreen({super.key});

  @override
  State<BattleshipAIScreen> createState() => _BattleshipAIScreenState();
}

enum _Phase { placing, battle, gameOver }

class _BattleshipAIScreenState extends State<BattleshipAIScreen> {

  // Доски: 0=вода 1=корабль 2=промах 3=попадание
  late List<int> _myBoard;
  late List<int> _aiBoard;

  _Phase _phase = _Phase.placing;
  bool _myTurn = true;
  String _message = 'Расставь корабли';
  String? _winner;

  // Для расстановки кораблей
  int _shipIdx = 0;           // какой корабль сейчас ставим
  int? _firstCell;            // первая клетка при горизонтальной расстановке

  // ИИ — «охота»: после первого попадания запоминаем цель
  final List<int> _aiHits = [];
  final Set<int> _aiShot = {};
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _resetBoards();
  }

  void _resetBoards() {
    _myBoard = List.filled(_kTotal, _water);
    _aiBoard = _placeShipsRandom();
    _phase = _Phase.placing;
    _myTurn = true;
    _shipIdx = 0;
    _firstCell = null;
    _aiHits.clear();
    _aiShot.clear();
    _message = 'Расставь корабли (${_kShips[0]}-палубный)';
    _winner = null;
  }

  // ── Расстановка ИИ (рандом) ───────────────────────────────────────────────

  List<int> _placeShipsRandom() {
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
    return board;
  }

  bool _canPlace(List<int> board, List<int> cells) {
    for (final c in cells) {
      if (board[c] != _water) return false;
      // проверяем соседей
      final row = c ~/ _kSize, col = c % _kSize;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = row + dr, nc = col + dc;
          if (nr < 0 || nr >= _kSize || nc < 0 || nc >= _kSize) continue;
          if (board[nr * _kSize + nc] == _ship) return false;
        }
      }
    }
    return true;
  }

  // ── Расстановка игрока (тап) ──────────────────────────────────────────────

  void _onMyBoardTap(int idx) {
    if (_phase != _Phase.placing) return;
    final size = _kShips[_shipIdx];

    if (size == 1) {
      // 1-палубный — ставим сразу
      if (_myBoard[idx] == _ship) {
        setState(() { _myBoard[idx] = _water; });
        return;
      }
      if (_canPlace(_myBoard, [idx])) {
        setState(() {
          _myBoard[idx] = _ship;
          _shipIdx++;
          _firstCell = null;
          if (_shipIdx >= _kShips.length) {
            _phase = _Phase.battle;
            _message = 'Ты ходишь первым! Атакуй поле врага.';
          } else {
            _message = 'Поставь ${_kShips[_shipIdx]}-палубный корабль';
          }
        });
      }
      return;
    }

    if (_firstCell == null) {
      // Первая клетка
      setState(() { _firstCell = idx; _message = 'Теперь выбери вторую клетку'; });
    } else {
      // Вторая клетка — строим корабль между двумя точками
      final a = _firstCell!, b = idx;
      final rowA = a ~/ _kSize, colA = a % _kSize;
      final rowB = b ~/ _kSize, colB = b % _kSize;

      List<int> cells = [];
      if (rowA == rowB) {
        // горизонталь
        final minC = min(colA, colB), maxC = max(colA, colB);
        if (maxC - minC + 1 == size) {
          cells = List.generate(size, (k) => rowA * _kSize + minC + k);
        }
      } else if (colA == colB) {
        // вертикаль
        final minR = min(rowA, rowB), maxR = max(rowA, rowB);
        if (maxR - minR + 1 == size) {
          cells = List.generate(size, (k) => (minR + k) * _kSize + colA);
        }
      }

      if (cells.isNotEmpty && _canPlace(_myBoard, cells)) {
        setState(() {
          for (final c in cells) _myBoard[c] = _ship;
          _firstCell = null;
          _shipIdx++;
          if (_shipIdx >= _kShips.length) {
            _phase = _Phase.battle;
            _message = 'Ты ходишь первым! Атакуй поле врага.';
          } else {
            _message = 'Поставь ${_kShips[_shipIdx]}-палубный корабль';
          }
        });
      } else {
        setState(() {
          _firstCell = null;
          _message = 'Неверно! Поставь ${size}-палубный корабль заново';
        });
      }
    }
  }

  void _autoPlace() {
    setState(() {
      _myBoard = _placeShipsRandom();
      _shipIdx = _kShips.length;
      _phase = _Phase.battle;
      _message = 'Ты ходишь первым! Атакуй поле врага.';
      _firstCell = null;
    });
  }

  // ── Выстрел игрока ────────────────────────────────────────────────────────

  void _onEnemyTap(int idx) {
    if (_phase != _Phase.battle || !_myTurn) return;
    if (_aiBoard[idx] == _miss || _aiBoard[idx] == _hit) return;

    setState(() {
      if (_aiBoard[idx] == _ship) {
        _aiBoard[idx] = _hit;
        _message = '🔥 Попал! Стреляй снова!';
        if (_checkWin(_aiBoard)) { _endGame('Ты'); return; }
        // попал — ходишь снова
      } else {
        _aiBoard[idx] = _miss;
        _myTurn = false;
        _message = 'Мимо. Ход ИИ...';
        Future.delayed(const Duration(milliseconds: 800), _aiTurn);
      }
    });
  }

  // ── Ход ИИ ────────────────────────────────────────────────────────────────

  void _aiTurn() {
    if (_phase != _Phase.battle) return;

    int idx;
    if (_aiHits.isNotEmpty) {
      // «Охота»: стреляем рядом с последним попаданием
      idx = _aiHuntShot();
    } else {
      // Случайный
      do { idx = _rng.nextInt(_kTotal); } while (_aiShot.contains(idx));
    }

    _aiShot.add(idx);

    setState(() {
      if (_myBoard[idx] == _ship) {
        _myBoard[idx] = _hit;
        _aiHits.add(idx);
        if (_checkWin(_myBoard)) { _endGame('ИИ'); return; }
        _message = 'ИИ попал! Ход ИИ...';
        Future.delayed(const Duration(milliseconds: 900), _aiTurn);
      } else {
        _myBoard[idx] = _miss;
        _myTurn = true;
        _message = 'ИИ промахнулся. Твой ход!';
      }
    });
  }

  int _aiHuntShot() {
    // Ищем возможные клетки вокруг попаданий
    final candidates = <int>{};
    for (final h in _aiHits) {
      final row = h ~/ _kSize, col = h % _kSize;
      for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
        final nr = row + d[0], nc = col + d[1];
        if (nr < 0 || nr >= _kSize || nc < 0 || nc >= _kSize) continue;
        final ni = nr * _kSize + nc;
        if (!_aiShot.contains(ni)) candidates.add(ni);
      }
    }
    if (candidates.isEmpty) {
      _aiHits.clear();
      int idx;
      do { idx = _rng.nextInt(_kTotal); } while (_aiShot.contains(idx));
      return idx;
    }
    final list = candidates.toList();
    return list[_rng.nextInt(list.length)];
  }

  bool _checkWin(List<int> board) => !board.contains(_ship);

  void _endGame(String winner) {
    setState(() {
      _phase = _Phase.gameOver;
      _winner = winner;
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        leading: BackButton(color: Colors.white54),
        title: const Text('🚢 Морской бой — ИИ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _phase == _Phase.gameOver
          ? _GameOverScreen(winner: _winner!, onRestart: () => setState(_resetBoards), onExit: () => Navigator.pop(context))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Сообщение
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
                child: Text(_message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),

            const SizedBox(height: 8),

            // Поле врага
            _SectionLabel(label: '🎯 Поле врага', color: Colors.redAccent),
            _Grid(
              board: _aiBoard,
              hideShips: true,
              onTap: _onEnemyTap,
              firstSelected: null,
            ),

            const SizedBox(height: 16),

            // Поле игрока
            _SectionLabel(
              label: _phase == _Phase.placing ? '🔧 Расставь флот' : '⚓ Твой флот',
              color: Colors.greenAccent,
            ),
            _Grid(
              board: _myBoard,
              hideShips: false,
              onTap: _onMyBoardTap,
              firstSelected: _firstCell,
            ),

            // Кнопка авторасстановки
            if (_phase == _Phase.placing)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  onPressed: _autoPlace,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Расставить случайно'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8DEF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Виджеты ───────────────────────────────────────────────────────────────────

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

class _Grid extends StatelessWidget {
  final List<int> board;
  final bool hideShips;
  final Function(int) onTap;
  final int? firstSelected;

  const _Grid({
    required this.board,
    required this.hideShips,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _kSize),
        itemCount: _kTotal,
        itemBuilder: (_, i) {
          final val = board[i];
          Color bg;
          Widget child = const SizedBox();

          if (val == _ship && !hideShips) {
            bg = const Color(0xFF4A5568); // корабль виден
          } else if (val == _hit) {
            bg = const Color(0xFFE53E3E);
            child = const Icon(Icons.local_fire_department, color: Colors.white, size: 14);
          } else if (val == _miss) {
            bg = const Color(0xFF2D5A8E);
            child = const Icon(Icons.close, color: Colors.white54, size: 12);
          } else {
            bg = const Color(0xFF1A3A5C); // вода
          }

          final isSelected = firstSelected == i;
          if (isSelected) bg = const Color(0xFF48BB78);

          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isSelected ? Colors.greenAccent : Colors.black26,
                  width: isSelected ? 2 : 0.5,
                ),
              ),
              child: Center(child: child),
            ),
          );
        },
      ),
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final String winner;
  final VoidCallback onRestart, onExit;

  const _GameOverScreen({required this.winner, required this.onRestart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final iWon = winner == 'Ты';
    return Container(
      color: const Color(0xFF0A1628),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(iWon ? '🏆' : '💀', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              iWon ? 'Победа!' : 'Поражение',
              style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900,
                color: iWon ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D),
              ),
            ),
            const SizedBox(height: 8),
            Text('$winner потопил весь флот!',
                style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Играть снова', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('В меню', style: TextStyle(color: Colors.white38, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}