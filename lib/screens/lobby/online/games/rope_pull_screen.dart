import 'package:flutter/material.dart';
import 'dart:math';

class RopePullScreen extends StatefulWidget {
  const RopePullScreen({super.key});

  @override
  State<RopePullScreen> createState() => _RopePullScreenState();
}

class _RopePullScreenState extends State<RopePullScreen> {
  double ropePosition = 0; // 0 — центр, -1 — влево, 1 — вправо
  int score = 0;
  Random rand = Random();
  String winner = "";

  void _pull(String direction) {
    setState(() {
      double change = 0.1;
      if (direction == "left") ropePosition -= change;
      if (direction == "right") ropePosition += change;

      // ИИ противник случайно тянет
      ropePosition += (rand.nextDouble() - 0.5) * 0.05;

      // Ограничиваем позицию
      if (ropePosition < -1) ropePosition = -1;
      if (ropePosition > 1) ropePosition = 1;

      // Проверка победы
      if (ropePosition <= -1) {
        winner = "Игрок";
      } else if (ropePosition >= 1) {
        winner = "ИИ";
      }
    });
  }

  void _resetGame() {
    setState(() {
      ropePosition = 0;
      winner = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Перетяни канат"),
        backgroundColor: Colors.redAccent,
      ),
      backgroundColor: Colors.red[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Поле
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.brown[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Канат
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: 150 + ropePosition * 120 - 75,
                    top: 140,
                    child: Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            if (winner.isEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pull("left"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Тяни влево"),
                  ),
                  ElevatedButton(
                    onPressed: () => _pull("right"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Тяни вправо"),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    "$winner выиграл!",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Сыграть снова"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}