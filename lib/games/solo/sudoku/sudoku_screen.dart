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

  /// 🎲 генерация (простая)
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

  /// 🏆 ПРОВЕРКА ПОБЕДЫ
  void checkWin() {
    for (var row in board) {
      if (row.contains(0)) return;
    }

    CoinService.addCoins(10);
    showWinDialog(context);
  }

  /// 🎨 ГРАНИЦЫ СУДОКУ (ВАЖНО)
  Border buildBorder(int row, int col) {
    return Border(
      top: BorderSide(
        width: row % 3 == 0 ? 3 : 0.5,
        color: Colors.black,
      ),
      left: BorderSide(
        width: col % 3 == 0 ? 3 : 0.5,
        color: Colors.black,
      ),
      right: BorderSide(
        width: col == 8 ? 3 : 0.5,
        color: Colors.black,
      ),
      bottom: BorderSide(
        width: row == 8 ? 3 : 0.5,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Судоку"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// 🔲 СЕТКА
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),

              child: AspectRatio(
                aspectRatio: 1,

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
                              ? Colors.blue.shade100
                              : Colors.white,

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
                                  ? Colors.black
                                  : Colors.blue,
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

          /// 🔢 КНОПКИ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: List.generate(9, (index) {
                return ElevatedButton(
                  onPressed: () => setNumber(index + 1),
                  child: Text("${index + 1}"),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}