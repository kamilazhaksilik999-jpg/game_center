import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isReady = false;
  bool _finished = false;
  Random _rand = Random();

  // ================= Поставить корабль =================
  void _placeShip(int i, List myBoard, String status, String roomId) {
    if (status != 'waiting' || _isReady) return;
    setState(() {
      myBoard[i] = (myBoard[i] == 1) ? 0 : 1;
    });
    String field = widget.isHost ? 'p1_board' : 'p2_board';
    FirebaseFirestore.instance.collection('rooms').doc(roomId).update({field: myBoard});
  }

  // ================= Готов =================
  void _confirmReady(String roomId) {
    setState(() => _isReady = true);
    String readyField = widget.isHost ? 'p1_ready' : 'p2_ready';
    FirebaseFirestore.instance.collection('rooms').doc(roomId).update({readyField: true});

    if (widget.isAi) Future.delayed(const Duration(milliseconds: 500), () => _aiPlay(roomId));
  }

  // ================= Выстрел =================
  void _shoot(int i, List enemyBoard, int turn, String status, String roomId) {
    int myTurn = widget.isHost ? 1 : 2;
    if (status != 'playing' || turn != myTurn) return;
    if (enemyBoard[i] > 1) return;

    enemyBoard[i] = (enemyBoard[i] == 1) ? 3 : 2;

    String field = widget.isHost ? 'p2_board' : 'p1_board';
    FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      field: enemyBoard,
      'turn': (enemyBoard[i] == 3) ? turn : (turn == 1 ? 2 : 1),
    });

    if (widget.isAi && turn == myTurn) {
      Future.delayed(const Duration(milliseconds: 700), () => _aiPlay(roomId));
    }
  }

  // ================= ИИ =================
  void _aiPlay(String roomId) async {
    DocumentSnapshot snap =
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    var d = snap.data() as Map<String, dynamic>;

    List p1Board = List.from(d['p1_board'] ?? List.filled(25, 0));
    List p2Board = List.from(d['p2_board'] ?? List.filled(25, 0));
    int turn = d['turn'] ?? 1;

    List enemyBoard = widget.isHost ? p2Board : p1Board;
    if ((widget.isHost && turn != 1) || (!widget.isHost && turn != 2)) return;

    int idx = _rand.nextInt(25);
    while (enemyBoard[idx] > 1) idx = _rand.nextInt(25);

    _shoot(idx, enemyBoard, turn, 'playing', roomId);
  }

  // ================= Победа =================
  void _checkWinner(List p1Board, List p2Board) {
    if (_finished) return;
    if (!p1Board.contains(1) && p1Board.contains(3)) _endGame("Гость");
    if (!p2Board.contains(1) && p2Board.contains(3)) _endGame("Хост");
  }

  void _endGame(String winner) {
    if (_finished) return;
    _finished = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
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
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId ?? '';
    if (roomId.isEmpty) return const Scaffold(body: Center(child: Text("Ошибка комнаты")));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3C72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return const Center(child: CircularProgressIndicator());

              var d = snap.data!.data() as Map<String, dynamic>;

              List p1Board = List.from(d['p1_board'] ?? List.filled(25, 0));
              List p2Board = List.from(d['p2_board'] ?? List.filled(25, 0));
              bool p1Ready = d['p1_ready'] ?? false;
              bool p2Ready = d['p2_ready'] ?? false;
              int turn = d['turn'] ?? 1;
              String gameStatus = (p1Ready && p2Ready) ? 'playing' : 'waiting';

              _checkWinner(p1Board, p2Board);

              List myBoard = widget.isHost ? p1Board : p2Board;
              List enemyBoard = widget.isHost ? p2Board : p1Board;

              return Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTitle("ПОЛЕ ВРАГА", Colors.redAccent),
                  _buildGrid(enemyBoard, (i) => _shoot(i, enemyBoard, turn, gameStatus, roomId), hideShips: true),
                  const Divider(color: Colors.white24, thickness: 2),
                  _buildTitle(gameStatus == 'waiting' ? "РАССТАВЬ КОРАБЛИ" : "ТВОЙ ФЛОТ", Colors.greenAccent),
                  _buildGrid(myBoard, (i) => _placeShip(i, myBoard, gameStatus, roomId), hideShips: false),
                  if (gameStatus == 'waiting')
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _isReady ? null : () => _confirmReady(roomId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent[700],
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                        ),
                        child: Text(_isReady ? "ЖДЕМ..." : "Я ГОТОВ",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (gameStatus == 'playing')
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        turn == (widget.isHost ? 1 : 2) ? "ТВОЙ ХОД!" : "ХОД ВРАГА",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2)],
      ),
    ),
  );

  Widget _buildGrid(List board, Function(int) onTap, {required bool hideShips}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: 25,
        itemBuilder: (c, i) {
          Color cellColor = Colors.blue[300]!;
          Widget icon = const SizedBox();

          if (board[i] == 1 && !hideShips) cellColor = Colors.grey[400]!;
          if (board[i] == 2) icon = const Icon(Icons.close, color: Colors.white, size: 18);
          if (board[i] == 3) icon = const Icon(Icons.whatshot, color: Colors.white, size: 18);

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: Center(child: icon),
            ),
          );
        },
      ),
    );
  }
}