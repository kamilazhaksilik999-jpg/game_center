// lobby/online/games/ai_game.dart
// Игра в танки против ИИ с лабиринтом

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Константы ───────────────────────────────────────────────────────────────

const int kCols = 13;
const int kRows = 13;
const double kCell = 40.0;
const double kTankSize = 28.0;
const double kBulletSize = 7.0;
const double kMoveSpeed = 2.5;
const double kBulletSpeed = 5.0;
const int kAiTickMs = 400; // пересчёт пути ИИ каждые N мс

// ─── Направления ─────────────────────────────────────────────────────────────

enum Dir { up, down, left, right }

Offset dirOffset(Dir d) => switch (d) {
  Dir.up => const Offset(0, -1),
  Dir.down => const Offset(0, 1),
  Dir.left => const Offset(-1, 0),
  Dir.right => const Offset(1, 0),
};

double dirAngle(Dir d) => switch (d) {
  Dir.up => 0,
  Dir.down => pi,
  Dir.left => -pi / 2,
  Dir.right => pi / 2,
};

// ─── Лабиринт (true = стена) ──────────────────────────────────────────────────
// 13×13, генерируется алгоритмом recursive backtracker

List<List<bool>> generateMaze(int cols, int rows, Random rng) {
  // Сетка стен: нечётные индексы — клетки, чётные — стены между ними
  // Используем упрощённую генерацию с заданными "комнатами"
  final w = cols;
  final h = rows;
  final walls = List.generate(h, (_) => List.filled(w, true));

  // Все нечётные позиции — проходимые клетки
  void carve(int cx, int cy) {
    walls[cy][cx] = false;
    final dirs = [
      [0, -2],
      [0, 2],
      [-2, 0],
      [2, 0],
    ]..shuffle(rng);
    for (final d in dirs) {
      final nx = cx + d[0];
      final ny = cy + d[1];
      if (nx >= 0 && nx < w && ny >= 0 && ny < h && walls[ny][nx]) {
        walls[cy + d[1] ~/ 2][cx + d[0] ~/ 2] = false;
        carve(nx, ny);
      }
    }
  }

  carve(1, 1);

  // Дополнительные проходы для удобства
  for (int i = 0; i < (cols * rows) ~/ 8; i++) {
    final rx = rng.nextInt(cols - 2) + 1;
    final ry = rng.nextInt(rows - 2) + 1;
    walls[ry][rx] = false;
  }

  // Игрок появляется в левом верхнем, ИИ — правом нижнем
  walls[1][1] = false;
  walls[1][2] = false;
  walls[2][1] = false;
  walls[rows - 2][cols - 2] = false;
  walls[rows - 2][cols - 3] = false;
  walls[rows - 3][cols - 2] = false;

  return walls;
}

// ─── Пуля ────────────────────────────────────────────────────────────────────

class Bullet {
  Offset pos;
  Dir dir;
  bool fromPlayer;

  Bullet({required this.pos, required this.dir, required this.fromPlayer});
}

// ─── Состояние игры ──────────────────────────────────────────────────────────

class GameState {
  final List<List<bool>> walls;
  Offset playerPos;
  Dir playerDir;
  int playerHp;

  Offset aiPos;
  Dir aiDir;
  int aiHp;

  List<Bullet> bullets = [];
  List<Offset> aiPath = [];

  bool gameOver = false;
  String? winner; // 'player' | 'ai'

  int playerScore = 0;
  int aiScore = 0;

  GameState({
    required this.walls,
    required this.playerPos,
    required this.aiPos,
  })  : playerDir = Dir.right,
        aiDir = Dir.left,
        playerHp = 3,
        aiHp = 3;
}

// ─── BFS для ИИ ──────────────────────────────────────────────────────────────

List<Offset> bfsPath(
    List<List<bool>> walls, Offset from, Offset to, int cols, int rows) {
  final start = Offset(from.dx.roundToDouble(), from.dy.roundToDouble());
  final end = Offset(to.dx.roundToDouble(), to.dy.roundToDouble());

  final queue = <Offset>[start];
  final visited = <String, Offset?>{_key(start): null};

  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    if (_key(cur) == _key(end)) {
      // восстановить путь
      final path = <Offset>[];
      Offset? node = end;
      while (node != null && _key(node) != _key(start)) {
        path.add(node);
        node = visited[_key(node)];
      }
      return path.reversed.toList();
    }
    for (final d in Dir.values) {
      final nb = cur + dirOffset(d);
      final nx = nb.dx.round();
      final ny = nb.dy.round();
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
      if (walls[ny][nx]) continue;
      final k = _key(nb);
      if (!visited.containsKey(k)) {
        visited[k] = cur;
        queue.add(nb);
      }
    }
  }
  return [];
}

String _key(Offset o) => '${o.dx.round()},${o.dy.round()}';

// ─── Экран игры ──────────────────────────────────────────────────────────────

class AIGameScreen extends StatefulWidget {
  const AIGameScreen({super.key});

  @override
  State<AIGameScreen> createState() => _AIGameScreenState();
}

class _AIGameScreenState extends State<AIGameScreen>
    with SingleTickerProviderStateMixin {
  late GameState _state;
  late Timer _gameTimer;
  late Timer _aiTimer;
  final _rng = Random();

  // Управление игроком
  final Set<LogicalKeyboardKey> _keys = {};
  bool _shootPressed = false;

  // Для дотиков на мобилке
  Offset? _joystickOrigin;
  Offset? _joystickCurrent;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final walls = generateMaze(kCols, kRows, _rng);
    _state = GameState(
      walls: walls,
      playerPos: const Offset(1, 1),
      aiPos: Offset((kCols - 2).toDouble(), (kRows - 2).toDouble()),
    );
    _gameTimer =
        Timer.periodic(const Duration(milliseconds: 16), _onTick);
    _aiTimer =
        Timer.periodic(Duration(milliseconds: kAiTickMs), _onAiTick);
  }

  void _restartGame() {
    _gameTimer.cancel();
    _aiTimer.cancel();
    final ps = _state.playerScore;
    final as_ = _state.aiScore;
    setState(() {
      final walls = generateMaze(kCols, kRows, _rng);
      _state = GameState(
        walls: walls,
        playerPos: const Offset(1, 1),
        aiPos: Offset((kCols - 2).toDouble(), (kRows - 2).toDouble()),
      )
        ..playerScore = ps
        ..aiScore = as_;
    });
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _onTick);
    _aiTimer = Timer.periodic(Duration(milliseconds: kAiTickMs), _onAiTick);
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _aiTimer.cancel();
    super.dispose();
  }

  // ── Тик физики ──────────────────────────────────────────────────────────────

  void _onTick(Timer _) {
    if (_state.gameOver) return;
    setState(() {
      _movePlayer();
      _moveAi();
      _moveBullets();
      _checkCollisions();
    });
  }

  bool _canMove(Offset pos, Dir dir) {
    final next = pos + dirOffset(dir);
    final nx = next.dx.round();
    final ny = next.dy.round();
    if (nx < 0 || ny < 0 || nx >= kCols || ny >= kRows) return false;
    return !_state.walls[ny][nx];
  }

  void _movePlayer() {
    Dir? moveDir;

    // Клавиатура
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) moveDir = Dir.up;
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) moveDir = Dir.down;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) moveDir = Dir.left;
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) moveDir = Dir.right;

    // Джойстик
    if (_joystickOrigin != null && _joystickCurrent != null) {
      final delta = _joystickCurrent! - _joystickOrigin!;
      if (delta.distance > 12) {
        final angle = atan2(delta.dy, delta.dx);
        if (angle.abs() < pi / 4) moveDir = Dir.right;
        else if ((angle - pi).abs() < pi / 4 || (angle + pi).abs() < pi / 4)
          moveDir = Dir.left;
        else if (angle > 0) moveDir = Dir.down;
        else moveDir = Dir.up;
      }
    }

    if (moveDir != null) {
      _state.playerDir = moveDir;
      final step = dirOffset(moveDir) * (kMoveSpeed / kCell);
      final next = _state.playerPos + step;
      // Проверяем центр и края танка
      if (_canMoveFull(next, _state.walls)) {
        _state.playerPos = next;
      }
    }

    // Выстрел по пробелу / тапу
    if (_shootPressed || _keys.contains(LogicalKeyboardKey.space)) {
      _shootPressed = false;
      _playerShoot();
    }
  }

  bool _canMoveFull(Offset pos, List<List<bool>> walls) {
    const r = 0.35;
    for (final corner in [
      pos + const Offset(-r, -r),
      pos + const Offset(r, -r),
      pos + const Offset(-r, r),
      pos + const Offset(r, r),
    ]) {
      final cx = corner.dx.round();
      final cy = corner.dy.round();
      if (cx < 0 || cy < 0 || cx >= kCols || cy >= kRows) return false;
      if (walls[cy][cx]) return false;
    }
    return true;
  }

  void _playerShoot() {
    // Не спамить (макс 3 пули игрока)
    if (_state.bullets.where((b) => b.fromPlayer).length >= 3) return;
    _state.bullets.add(Bullet(
      pos: _state.playerPos,
      dir: _state.playerDir,
      fromPlayer: true,
    ));
  }

  // ── ИИ движение ─────────────────────────────────────────────────────────────

  void _onAiTick(Timer _) {
    if (_state.gameOver) return;
    // Пересчитать путь к игроку
    final path = bfsPath(
      _state.walls,
      Offset(_state.aiPos.dx.round().toDouble(),
          _state.aiPos.dy.round().toDouble()),
      Offset(_state.playerPos.dx.round().toDouble(),
          _state.playerPos.dy.round().toDouble()),
      kCols,
      kRows,
    );
    _state.aiPath = path;

    // Стрелять если виден игрок (на одной линии без стен)
    if (_aiCanSeePlayer()) {
      if (_state.bullets.where((b) => !b.fromPlayer).length < 2) {
        _state.bullets.add(Bullet(
          pos: _state.aiPos,
          dir: _state.aiDir,
          fromPlayer: false,
        ));
      }
    }
  }

  bool _aiCanSeePlayer() {
    final ax = _state.aiPos.dx.round();
    final ay = _state.aiPos.dy.round();
    final px = _state.playerPos.dx.round();
    final py = _state.playerPos.dy.round();
    if (ax == px) {
      final minY = min(ay, py);
      final maxY = max(ay, py);
      for (int y = minY; y <= maxY; y++) {
        if (_state.walls[y][ax]) return false;
      }
      _state.aiDir = py < ay ? Dir.up : Dir.down;
      return true;
    }
    if (ay == py) {
      final minX = min(ax, px);
      final maxX = max(ax, px);
      for (int x = minX; x <= maxX; x++) {
        if (_state.walls[ay][x]) return false;
      }
      _state.aiDir = px < ax ? Dir.left : Dir.right;
      return true;
    }
    return false;
  }

  void _moveAi() {
    if (_state.aiPath.isEmpty) return;
    final target = _state.aiPath.first;
    final diff = target - _state.aiPos;
    if (diff.distance < kMoveSpeed / kCell) {
      _state.aiPos = target;
      _state.aiPath.removeAt(0);
    } else {
      final step = Offset(diff.dx.sign, diff.dy.sign) * (kMoveSpeed / kCell);
      final next = _state.aiPos + step;
      if (_canMoveFull(next, _state.walls)) {
        _state.aiPos = next;
        if (diff.dx.abs() > diff.dy.abs()) {
          _state.aiDir = diff.dx > 0 ? Dir.right : Dir.left;
        } else {
          _state.aiDir = diff.dy > 0 ? Dir.down : Dir.up;
        }
      }
    }
  }

  // ── Пули ────────────────────────────────────────────────────────────────────

  void _moveBullets() {
    final toRemove = <Bullet>[];
    for (final b in _state.bullets) {
      b.pos = b.pos + dirOffset(b.dir) * (kBulletSpeed / kCell);
      final bx = b.pos.dx.round();
      final by = b.pos.dy.round();
      if (bx < 0 || by < 0 || bx >= kCols || by >= kRows) {
        toRemove.add(b);
        continue;
      }
      if (_state.walls[by][bx]) toRemove.add(b);
    }
    _state.bullets.removeWhere(toRemove.contains);
  }

  void _checkCollisions() {
    final toRemove = <Bullet>[];
    for (final b in _state.bullets) {
      if (b.fromPlayer) {
        // Попадание в ИИ
        if ((b.pos - _state.aiPos).distance < 0.6) {
          _state.aiHp--;
          toRemove.add(b);
          if (_state.aiHp <= 0) {
            _state.gameOver = true;
            _state.winner = 'player';
            _state.playerScore++;
          }
        }
      } else {
        // Попадание в игрока
        if ((b.pos - _state.playerPos).distance < 0.6) {
          _state.playerHp--;
          toRemove.add(b);
          if (_state.playerHp <= 0) {
            _state.gameOver = true;
            _state.winner = 'ai';
            _state.aiScore++;
          }
        }
      }
    }
    _state.bullets.removeWhere(toRemove.contains);
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) _keys.add(event.logicalKey);
          if (event is KeyUpEvent) _keys.remove(event.logicalKey);
          return KeyEventResult.handled;
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGameArea()),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF8888AA)),
            onPressed: () => Navigator.pop(context),
          ),
          // HP игрока
          _buildHpRow(
            color: const Color(0xFF00C896),
            hp: _state.playerHp,
            label: 'ВЫ',
            icon: '🟢',
          ),
          // Счёт
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_state.playerScore} : ${_state.aiScore}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          // HP ИИ
          _buildHpRow(
            color: const Color(0xFFEF5B5B),
            hp: _state.aiHp,
            label: 'ИИ',
            icon: '🔴',
            reversed: true,
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHpRow(
      {required Color color,
        required int hp,
        required String label,
        required String icon,
        bool reversed = false}) {
    final hearts = List.generate(
        3,
            (i) => Icon(
          i < hp ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: i < hp ? color : const Color(0xFF444466),
          size: 16,
        ));
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        Row(children: reversed ? hearts.reversed.toList() : hearts),
      ],
    );
  }

  Widget _buildGameArea() {
    final mazeW = kCols * kCell;
    final mazeH = kRows * kCell;

    return Center(
      child: Stack(
        children: [
          // Фон
          Container(
            width: mazeW,
            height: mazeH,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Лабиринт + объекты
          SizedBox(
            width: mazeW,
            height: mazeH,
            child: CustomPaint(
              painter: _MazePainter(
                walls: _state.walls,
                playerPos: _state.playerPos,
                playerDir: _state.playerDir,
                aiPos: _state.aiPos,
                aiDir: _state.aiDir,
                bullets: _state.bullets,
              ),
            ),
          ),

          // Оверлей победы/поражения
          if (_state.gameOver)
            Positioned.fill(child: _buildGameOverOverlay()),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final win = _state.winner == 'player';
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              win ? '🏆 ПОБЕДА!' : '💀 ПОРАЖЕНИЕ',
              style: TextStyle(
                color: win ? const Color(0xFFFFD700) : const Color(0xFFEF5B5B),
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: (win
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFEF5B5B))
                        .withOpacity(0.6),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _restartGame,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'ИГРАТЬ СНОВА',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Виртуальный джойстик
          GestureDetector(
            onPanStart: (d) => setState(() {
              _joystickOrigin = d.localPosition;
              _joystickCurrent = d.localPosition;
            }),
            onPanUpdate: (d) =>
                setState(() => _joystickCurrent = d.localPosition),
            onPanEnd: (_) => setState(() {
              _joystickOrigin = null;
              _joystickCurrent = null;
            }),
            child: _JoystickWidget(
              origin: _joystickOrigin,
              current: _joystickCurrent,
            ),
          ),

          // Кнопка огня
          GestureDetector(
            onTapDown: (_) => setState(() => _shootPressed = true),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF5B5B),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF5B5B).withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
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

// ─── Джойстик ────────────────────────────────────────────────────────────────

class _JoystickWidget extends StatelessWidget {
  final Offset? origin;
  final Offset? current;

  const _JoystickWidget({this.origin, this.current});

  @override
  Widget build(BuildContext context) {
    Offset thumbOffset = Offset.zero;
    if (origin != null && current != null) {
      final delta = current! - origin!;
      final clamped =
      delta.distance > 36 ? delta / delta.distance * 36 : delta;
      thumbOffset = clamped;
    }

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Основание
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF16213E),
              border: Border.all(
                  color: const Color(0xFF00C896).withOpacity(0.3), width: 2),
            ),
          ),
          // Стик
          Transform.translate(
            offset: thumbOffset,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C896).withOpacity(0.85),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C896).withOpacity(0.4),
                    blurRadius: 12,
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

// ─── Рисование лабиринта и объектов ──────────────────────────────────────────

class _MazePainter extends CustomPainter {
  final List<List<bool>> walls;
  final Offset playerPos;
  final Dir playerDir;
  final Offset aiPos;
  final Dir aiDir;
  final List<Bullet> bullets;

  _MazePainter({
    required this.walls,
    required this.playerPos,
    required this.playerDir,
    required this.aiPos,
    required this.aiDir,
    required this.bullets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWalls(canvas);
    _drawTank(canvas, playerPos, playerDir, const Color(0xFF00C896));
    _drawTank(canvas, aiPos, aiDir, const Color(0xFFEF5B5B));
    _drawBullets(canvas);
  }

  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF3A3A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int y = 0; y < walls.length; y++) {
      for (int x = 0; x < walls[y].length; x++) {
        if (walls[y][x]) {
          final rect = Rect.fromLTWH(
              x * kCell, y * kCell, kCell, kCell);
          canvas.drawRect(rect, wallPaint);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }
  }

  void _drawTank(Canvas canvas, Offset gridPos, Dir dir, Color color) {
    final cx = gridPos.dx * kCell + kCell / 2;
    final cy = gridPos.dy * kCell + kCell / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(dirAngle(dir));

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final darkPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final barrelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const half = kTankSize / 2;

    // Корпус
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: kTankSize * 0.85, height: kTankSize * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, bodyPaint);

    // Башня
    canvas.drawCircle(Offset.zero, kTankSize * 0.22, darkPaint);

    // Ствол (вперёд = -y после rotate)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, -half),
      barrelPaint,
    );

    // Гусеницы
    final trackPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(-half * 0.95, -kTankSize * 0.32, kTankSize * 0.15, kTankSize * 0.64),
        trackPaint);
    canvas.drawRect(
        Rect.fromLTWH(half * 0.7, -kTankSize * 0.32, kTankSize * 0.15, kTankSize * 0.64),
        trackPaint);

    canvas.restore();
  }

  void _drawBullets(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final b in bullets) {
      paint.color = b.fromPlayer
          ? const Color(0xFFFFFF88)
          : const Color(0xFFFF6666);
      final cx = b.pos.dx * kCell + kCell / 2;
      final cy = b.pos.dy * kCell + kCell / 2;
      canvas.drawCircle(Offset(cx, cy), kBulletSize / 2, paint);

      // Свечение
      paint.color = (b.fromPlayer
          ? const Color(0xFFFFFF88)
          : const Color(0xFFFF6666))
          .withOpacity(0.3);
      canvas.drawCircle(Offset(cx, cy), kBulletSize, paint);
      paint.color = b.fromPlayer
          ? const Color(0xFFFFFF88)
          : const Color(0xFFFF6666);
    }
  }

  @override
  bool shouldRepaint(covariant _MazePainter old) => true;
}