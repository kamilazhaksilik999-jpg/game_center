import 'package:flutter/material.dart';
import 'dart:math';

class BattleshipScreen extends StatefulWidget {
  final String? roomId;
  final bool isHost;
  final bool isAi;

  const BattleshipScreen({
    super.key,
    this.roomId,
    this.isHost = true,
    this.isAi = false,
  });

  @override
  State<BattleshipScreen> createState() => _BattleshipScreenState();
}

class _BattleshipScreenState extends State<BattleshipScreen> {
  List<int> myBoard = List.filled(25, 0);
  List<int> enemyBoard = List.filled(25, 0);
  bool _isReady = false;
  bool _finished = false;
  int turn = 1;
  Random _rand = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isAi) {
      // расставляем случайно корабли ИИ
      for (int i = 0; i < 25; i++) {
        enemyBoard[i] = (_rand.nextBool() && i % 5 != 0) ? 1 : 0;
      }
    }
  }

  void _placeShip(int i) {
    if (_isReady) return;
    setState(() {
      myBoard[i] = (myBoard[i] == 1) ? 0 : 1;
    });
  }

  void _confirmReady() {
    setState(() => _isReady = true);
    if (widget.isAi) _aiPlay();
  }

  void _shoot(int i, List<int> board) {
    if (!_isReady || _finished) return;
    if (board[i] > 1) return;

    setState(() {
      board[i] = (board[i] == 1) ? 3 : 2;
    });

    _checkWinner();

    if (widget.isAi) {
      Future.delayed(const Duration(milliseconds: 500), _aiPlay);
    }
  }

  void _aiPlay() {
    int idx = _rand.nextInt(25);
    while (myBoard[idx] > 1) idx = _rand.nextInt(25);

    setState(() {
      myBoard[idx] = (myBoard[idx] == 1) ? 3 : 2;
    });

    _checkWinner();
  }

  void _checkWinner() {
    if (_finished) return;
    if (!myBoard.contains(1)) _endGame("ИИ");
    if (!enemyBoard.contains(1)) _endGame("Ты");
  }

  void _endGame(String winner) {
    if (_finished) return;
    _finished = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("ФЛОТ УНИЧТОЖЕН! ⚓"),
        content: Text("Победитель: $winner"),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text("В МЕНЮ"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Морской бой"),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("Поле врага", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            _buildGrid(enemyBoard, (i) => _shoot(i, enemyBoard), hideShips: true),
            const Divider(color: Colors.white24, thickness: 2),
            const Text("Твой флот", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            _buildGrid(myBoard, (i) => _placeShip(i), hideShips: false),
            if (!_isReady)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _confirmReady,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Я ГОТОВ"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<int> board, Function(int) onTap, {required bool hideShips}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 25,
        itemBuilder: (_, i) {
          Color cellColor = Colors.blue[300]!;
          Widget icon = const SizedBox();

          if (board[i] == 1 && !hideShips) cellColor = Colors.grey;
          if (board[i] == 2) icon = const Icon(Icons.close, color: Colors.white, size: 18);
          if (board[i] == 3) icon = const Icon(Icons.whatshot, color: Colors.white, size: 18);

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
              child: Center(child: icon),
            ),
          );
        },
      ),
    );
  }
}