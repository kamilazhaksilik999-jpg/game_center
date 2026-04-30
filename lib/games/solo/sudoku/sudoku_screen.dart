import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> fixed = List.generate(9, (_) => List.filled(9, false));

  int selectedRow = -1;
  int selectedCol = -1;

  @override
  void initState() {
    super.initState();
    generateSudoku();
  }

  void generateSudoku() {
    final random = Random();
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (random.nextDouble() < 0.4) {
          int num = random.nextInt(9) + 1;
          board[i][j] = num;
          fixed[i][j] = true;
        }
      }
    }
  }

  void selectCell(int r, int c) {
    if (fixed[r][c]) return;
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
  }

  void setNumber(int number) {
    if (selectedRow == -1) return;
    setState(() {
      board[selectedRow][selectedCol] = number;
    });
    checkWin();
  }

  void checkWin() {
    for (var row in board) {
      if (row.contains(0)) return;
    }
    CoinService.addCoins(10);
    showWinDialog(context);
  }

  Border buildBorder(int row, int col) {
    return Border(
      top: BorderSide(
        width: row % 3 == 0 ? 2.0 : 0.5,
        color: row % 3 == 0
            ? const Color(0xFF6366F1).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
      ),
      left: BorderSide(
        width: col % 3 == 0 ? 2.0 : 0.5,
        color: col % 3 == 0
            ? const Color(0xFF6366F1).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
      ),
      right: BorderSide(
        width: col == 8 ? 2.0 : 0.5,
        color: col == 8
            ? const Color(0xFF6366F1).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
      ),
      bottom: BorderSide(
        width: row == 8 ? 2.0 : 0.5,
        color: row == 8
            ? const Color(0xFF6366F1).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int filled = board.expand((r) => r).where((v) => v != 0).length;
    final int total = 81;
    final double progress = filled / total;

    return Scaffold(
      backgroundColor: const Color(0xFF060B1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B35),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("9×9",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
            const SizedBox(width: 8),
            const Text("Судоку",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                Color(0xFFA855F7),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // ── Прогресс ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("ПРОГРЕСС",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3)),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFFA855F7)],
                  ).createShader(b),
                  child: Text(
                    "$filled / $total",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Прогресс-бар ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.5)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 10,
                  width: (MediaQuery.of(context).size.width - 40) * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFC084FC)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                          blurRadius: 8)
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Инфо-карточки ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _infoCard("Заполнено", "$filled", const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                _infoCard("Осталось", "${total - filled}", const Color(0xFFA855F7)),
                const SizedBox(width: 10),
                _infoCard("Награда", "10 🪙", const Color(0xFFFBBF24)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Сетка ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 81,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ 9;
                      int col = index % 9;
                      bool isSelected =
                          row == selectedRow && col == selectedCol;
                      bool isSameBlock =
                      (row ~/ 3 == selectedRow ~/ 3 &&
                          col ~/ 3 == selectedCol ~/ 3);
                      bool isSameRowCol =
                      (row == selectedRow || col == selectedCol);

                      Color cellBg;
                      if (isSelected) {
                        cellBg = const Color(0xFF6366F1).withValues(alpha: 0.7);
                      } else if (selectedRow != -1 && (isSameRowCol || isSameBlock)) {
                        cellBg = const Color(0xFF6366F1).withValues(alpha: 0.08);
                      } else {
                        cellBg = Colors.transparent;
                      }

                      return GestureDetector(
                        onTap: () => selectCell(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cellBg,
                            border: buildBorder(row, col),
                          ),
                          child: Center(
                            child: board[row][col] == 0
                                ? null
                                : Text(
                              board[row][col].toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: fixed[row][col]
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: fixed[row][col]
                                    ? Colors.white
                                    : const Color(0xFF34D399),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Кнопки цифр ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(9, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setNumber(index + 1),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                              const Color(0xFFA855F7).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                            ).createShader(b),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05)
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}