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

  /// 🎨 ОБНОВЛЕННЫЕ ГРАНИЦЫ
  Border buildBorder(int row, int col) {
    return Border(
      top: BorderSide(
        width: row % 3 == 0 ? 2.5 : 0.5,
        color: Colors.white.withOpacity(0.3),
      ),
      left: BorderSide(
        width: col % 3 == 0 ? 2.5 : 0.5,
        color: Colors.white.withOpacity(0.3),
      ),
      right: BorderSide(
        width: col == 8 ? 2.5 : 0.5,
        color: Colors.white.withOpacity(0.3),
      ),
      bottom: BorderSide(
        width: row == 8 ? 2.5 : 0.5,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        title: const Text("Судоку"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          /// 🔥 ЗАГОЛОВОК
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 20,
                )
              ],
            ),
            child: const Center(
              child: Text(
                "Заполни поле",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// 🔲 СЕТКА
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),

              child: AspectRatio(
                aspectRatio: 1,

                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
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

                      return GestureDetector(
                        onTap: () => selectCell(row, col),

                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF1E293B),

                            border: buildBorder(row, col),
                          ),

                          child: Center(
                            child: Text(
                              board[row][col] == 0
                                  ? ""
                                  : board[row][col].toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: fixed[row][col]
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: fixed[row][col]
                                    ? Colors.white
                                    : Colors.greenAccent,
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

          /// 🔢 КНОПКИ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(9, (index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => setNumber(index + 1),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}