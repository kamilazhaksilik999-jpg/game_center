import 'package:flutter/material.dart';
import 'dart:math';

class MiniFootballScreen extends StatefulWidget {
  const MiniFootballScreen({super.key});

  @override
  State<MiniFootballScreen> createState() => _MiniFootballScreenState();
}

class _MiniFootballScreenState extends State<MiniFootballScreen> {
  double ballX = 0;
  double ballY = 0.8;
  int score = 0;
  bool goal = false;
  Random rand = Random();

  void _kickBall() {
    setState(() {
      ballX = rand.nextDouble() * 2 - 1; // от -1 до 1
      ballY = 0; // летит к воротам
    });

    // Проверка гола через 1 секунду
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        if (ballX.abs() < 0.3) {
          score++;
          goal = true;
        } else {
          goal = false;
        }
        // возвращаем мяч вниз
        ballX = 0;
        ballY = 0.8;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Мини-футбол"),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.green[700],
      body: Stack(
        children: [
          // Ворота
          Positioned(
            top: 50,
            left: MediaQuery.of(context).size.width / 2 - 75,
            child: Container(
              width: 150,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
              ),
            ),
          ),

          // Мяч
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            bottom: MediaQuery.of(context).size.height * ballY,
            left: MediaQuery.of(context).size.width / 2 + ballX * 150,
            child: const Icon(Icons.sports_soccer, size: 40, color: Colors.white),
          ),

          // Кнопка удар
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ElevatedButton(
              onPressed: _kickBall,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("УДАР"),
            ),
          ),

          // Счёт
          Positioned(
            top: 10,
            left: 20,
            child: Text(
              "Счёт: $score",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Гол
          if (goal)
            Center(
              child: Text(
                "GOAL! ⚽",
                style: TextStyle(
                  color: Colors.yellowAccent[400],
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}