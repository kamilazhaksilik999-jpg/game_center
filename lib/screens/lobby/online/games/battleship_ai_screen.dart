// lobby/online/games/battleship/battleship_ai.dart
//
// Layout: поля рядом — слева «Мой флот», справа «Поле врага»
// Адаптивно: если ширина < 600 — вертикально (телефон), иначе горизонтально (планшет/ноутбук)

import 'dart:math';
import 'package:flutter/material.dart';

// ── Константы ──────────────────────────────────────────────────────────────────
const int _kSize  = 10;
const int _kTotal = 100;
const List<int> _kShips = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
const int _water = 0, _ship = 1, _miss = 2, _hit = 3;

// ── Экран игры против ИИ ──────────────────────────────────────────────────────

class BattleshipAIScreen extends StatefulWidget {
  const BattleshipAIScreen({super.key});

  @override
  State<BattleshipAIScreen> createState() => _BattleshipAIScreenState();
}

enum _Phase { placing, battle, gameOver }

class _BattleshipAIScreenState extends State<BattleshipAIScreen> {
  late List<int> _myBoard;
  late List<int> _aiBoard;

  _Phase _phase = _Phase.placing;
  bool _myTurn = true;
  String _message = 'Расставь корабли';
  String? _winner;

  int _shipIdx = 0;
  int? _firstCell;

  final List<int> _aiHits = [];
  final Set<int> _aiShot = {};
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _resetBoards();
  }

  void _resetBoards() {
    _myBoard  = List.filled(_kTotal, _water);
    _aiBoard  = _placeShipsRandom();
    _phase    = _Phase.placing;
    _myTurn   = true;
    _shipIdx  = 0;
    _firstCell = null;
    _aiHits.clear();
    _aiShot.clear();
    _message = 'Расставь корабли (${_kShips[0]}-палубный)';
    _winner  = null;
  }

  // ── Расстановка ИИ ────────────────────────────────────────────────────────

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
        final cells = List.generate(
          size,
              (k) => horiz ? row * _kSize + col + k : (row + k) * _kSize + col,
        );
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

  // ── Расстановка игрока ────────────────────────────────────────────────────

  void _onMyBoardTap(int idx) {
    if (_phase != _Phase.placing) return;
    final size = _kShips[_shipIdx];

    if (size == 1) {
      if (_myBoard[idx] == _ship) {
        setState(() => _myBoard[idx] = _water);
        return;
      }
      if (_canPlace(_myBoard, [idx])) {
        setState(() {
          _myBoard[idx] = _ship;
          _shipIdx++;
          _firstCell = null;
          _message = _shipIdx >= _kShips.length
              ? 'Отлично! Атакуй поле врага →'
              : 'Поставь ${_kShips[_shipIdx]}-палубный корабль';
          if (_shipIdx >= _kShips.length) _phase = _Phase.battle;
        });
      }
      return;
    }

    if (_firstCell == null) {
      setState(() {
        _firstCell = idx;
        _message = 'Теперь выбери вторую клетку';
      });
    } else {
      final a = _firstCell!, b = idx;
      final rowA = a ~/ _kSize, colA = a % _kSize;
      final rowB = b ~/ _kSize, colB = b % _kSize;

      List<int> cells = [];
      if (rowA == rowB) {
        final mn = min(colA, colB), mx = max(colA, colB);
        if (mx - mn + 1 == size) {
          cells = List.generate(size, (k) => rowA * _kSize + mn + k);
        }
      } else if (colA == colB) {
        final mn = min(rowA, rowB), mx = max(rowA, rowB);
        if (mx - mn + 1 == size) {
          cells = List.generate(size, (k) => (mn + k) * _kSize + colA);
        }
      }

      if (cells.isNotEmpty && _canPlace(_myBoard, cells)) {
        setState(() {
          for (final c in cells) _myBoard[c] = _ship;
          _firstCell = null;
          _shipIdx++;
          _message = _shipIdx >= _kShips.length
              ? 'Отлично! Атакуй поле врага →'
              : 'Поставь ${_kShips[_shipIdx]}-палубный корабль';
          if (_shipIdx >= _kShips.length) _phase = _Phase.battle;
        });
      } else {
        setState(() {
          _firstCell = null;
          _message = 'Неверно! Поставь ${size}-палубный заново';
        });
      }
    }
  }

  void _autoPlace() {
    setState(() {
      _myBoard   = _placeShipsRandom();
      _shipIdx   = _kShips.length;
      _phase     = _Phase.battle;
      _message   = 'Атакуй поле врага →';
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
        if (!_aiBoard.contains(_ship)) { _endGame('Ты'); return; }
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
      idx = _aiHuntShot();
    } else {
      do {
        idx = _rng.nextInt(_kTotal);
      } while (_aiShot.contains(idx));
    }
    _aiShot.add(idx);

    setState(() {
      if (_myBoard[idx] == _ship) {
        _myBoard[idx] = _hit;
        _aiHits.add(idx);
        if (!_myBoard.contains(_ship)) { _endGame('ИИ'); return; }
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
    final candidates = <int>{};
    for (final h in _aiHits) {
      final row = h ~/ _kSize, col = h % _kSize;
      for (final d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
        final nr = row + d[0], nc = col + d[1];
        if (nr < 0 || nr >= _kSize || nc < 0 || nc >= _kSize) continue;
        final ni = nr * _kSize + nc;
        if (!_aiShot.contains(ni)) candidates.add(ni);
      }
    }
    if (candidates.isEmpty) {
      _aiHits.clear();
      int idx;
      do {
        idx = _rng.nextInt(_kTotal);
      } while (_aiShot.contains(idx));
      return idx;
    }
    final list = candidates.toList();
    return list[_rng.nextInt(list.length)];
  }

  void _endGame(String winner) {
    setState(() {
      _phase  = _Phase.gameOver;
      _winner = winner;
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.gameOver) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: _GameOverScreen(
          winner: _winner!,
          onRestart: () => setState(_resetBoards),
          onExit: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        leading: BackButton(color: Colors.white54),
        title: const Text(
          '🚢 Морской бой — ИИ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return isWide
              ? _buildWideLayout(constraints)
              : _buildNarrowLayout();
        },
      ),
    );
  }

  // ── Широкий layout (ноутбук): поля рядом ─────────────────────────────────

  Widget _buildWideLayout(BoxConstraints constraints) {
    // Оставляем отступы по бокам и между полями, вычисляем размер сетки
    const hPad    = 16.0;
    const gap     = 24.0;
    const labelH  = 32.0;
    const btnAreaH = 52.0;
    final availW  = constraints.maxWidth - hPad * 2 - gap;
    final gridSize = (availW / 2).clamp(0.0, 400.0);

    return Column(
      children: [
        // Статус-бар
        _StatusBar(message: _message),

        const SizedBox(height: 8),

        // Кнопки (в фазе расстановки)
        if (_phase == _Phase.placing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _autoPlace,
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Случайно'),
                  style: _btnStyle(const Color(0xFF5B8DEF)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ставь ${_shipIdx < _kShips.length ? _kShips[_shipIdx] : 0}-палубный',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          )
        else
          SizedBox(height: btnAreaH),

        const SizedBox(height: 4),

        // Два поля рядом
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Слева — МОЙ флот
              _BoardPanel(
                label: _phase == _Phase.placing ? '🔧 Мой флот' : '⚓ Мой флот',
                labelColor: Colors.greenAccent,
                size: gridSize,
                board: _myBoard,
                hideShips: false,
                enabled: _phase == _Phase.placing,
                onTap: _onMyBoardTap,
                firstSelected: _firstCell,
              ),

              const SizedBox(width: gap),

              // Справа — ПОЛЕ ВРАГА
              _BoardPanel(
                label: '🎯 Поле врага',
                labelColor: Colors.redAccent,
                size: gridSize,
                board: _aiBoard,
                hideShips: true,
                enabled: _phase == _Phase.battle && _myTurn,
                onTap: _onEnemyTap,
                firstSelected: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Узкий layout (телефон): поля стопкой ─────────────────────────────────

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _StatusBar(message: _message),
          const SizedBox(height: 8),

          // Поле врага сверху
          _SectionLabel(label: '🎯 Поле врага', color: Colors.redAccent),
          _Grid(
            board: _aiBoard,
            hideShips: true,
            onTap: _onEnemyTap,
            enabled: _phase == _Phase.battle && _myTurn,
            firstSelected: null,
          ),

          const SizedBox(height: 12),

          // Моё поле снизу
          _SectionLabel(
            label: _phase == _Phase.placing ? '🔧 Расставь флот' : '⚓ Мой флот',
            color: Colors.greenAccent,
          ),
          _Grid(
            board: _myBoard,
            hideShips: false,
            onTap: _onMyBoardTap,
            enabled: _phase == _Phase.placing,
            firstSelected: _firstCell,
          ),

          if (_phase == _Phase.placing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: _autoPlace,
                icon: const Icon(Icons.shuffle),
                label: const Text('Расставить случайно'),
                style: _btnStyle(const Color(0xFF5B8DEF)),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle(Color bg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ── Панель с полем (label + сетка) ───────────────────────────────────────────

class _BoardPanel extends StatelessWidget {
  final String label;
  final Color labelColor;
  final double size;
  final List<int> board;
  final bool hideShips, enabled;
  final Function(int) onTap;
  final int? firstSelected;

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
    return Column(
      children: [
        SizedBox(
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
          width: size,
          height: size,
          child: _GridFixed(
            board: board,
            hideShips: hideShips,
            enabled: enabled,
            onTap: onTap,
            firstSelected: firstSelected,
          ),
        ),
      ],
    );
  }
}

// ── Сетка с фиксированным размером (для панели) ───────────────────────────────

class _GridFixed extends StatelessWidget {
  final List<int> board;
  final bool hideShips, enabled;
  final Function(int) onTap;
  final int? firstSelected;

  const _GridFixed({
    required this.board,
    required this.hideShips,
    required this.enabled,
    required this.onTap,
    required this.firstSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kSize,
      ),
      itemCount: _kTotal,
      itemBuilder: (_, i) => _Cell(
        value: board[i],
        hideShip: hideShips,
        isSelected: firstSelected == i,
        onTap: enabled ? () => onTap(i) : null,
      ),
    );
  }
}

// ── Сетка с авторазмером (для узкого layout) ─────────────────────────────────

class _Grid extends StatelessWidget {
  final List<int> board;
  final bool hideShips, enabled;
  final Function(int) onTap;
  final int? firstSelected;

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
          crossAxisCount: _kSize,
        ),
        itemCount: _kTotal,
        itemBuilder: (_, i) => _Cell(
          value: board[i],
          hideShip: hideShips,
          isSelected: firstSelected == i,
          onTap: enabled ? () => onTap(i) : null,
        ),
      ),
    );
  }
}

// ── Отдельная клетка ─────────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final int value;
  final bool hideShip, isSelected;
  final VoidCallback? onTap;

  const _Cell({
    required this.value,
    required this.hideShip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget child = const SizedBox();

    if (value == _ship && !hideShip) {
      bg = const Color(0xFF4A5568);
    } else if (value == _hit) {
      bg = const Color(0xFFE53E3E);
      child = const Icon(Icons.local_fire_department, color: Colors.white, size: 10);
    } else if (value == _miss) {
      bg = const Color(0xFF2D5A8E);
      child = const Icon(Icons.close, color: Colors.white54, size: 8);
    } else {
      bg = const Color(0xFF1A3A5C);
    }

    if (isSelected) bg = const Color(0xFF48BB78);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(1.5),
          border: Border.all(
            color: isSelected ? Colors.greenAccent : Colors.black26,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Статус-бар ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String message;
  const _StatusBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
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
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Game Over ─────────────────────────────────────────────────────────────────

class _GameOverScreen extends StatelessWidget {
  final String winner;
  final VoidCallback onRestart, onExit;

  const _GameOverScreen({
    required this.winner,
    required this.onRestart,
    required this.onExit,
  });

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
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: iWon ? const Color(0xFFFFD700) : const Color(0xFFFF3D3D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$winner потопил весь флот!',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Играть снова',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text(
                'В меню',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}