import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

void win(BuildContext context) {
  CoinService.addCoins(10);

  showWinDialog(context);
}
class MathScreen extends StatefulWidget {
  const MathScreen({super.key});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  int a = 0;
  int b = 0;
  int correct = 0;

  List<int> options = [];

  void generate() {
    final rnd = Random();

    a = rnd.nextInt(20);
    b = rnd.nextInt(20);
    correct = a + b;

    options = [
      correct,
      correct + rnd.nextInt(5) + 1,
      correct - rnd.nextInt(5) - 1,
      correct + rnd.nextInt(10),
    ];

    options.shuffle();
  }

  @override
  void initState() {
    super.initState();
    generate();
  }

  void answer(int value) {
    if (value == correct) {
      showWinDialog(context); // 🎉 победа

      generate();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Неправильно")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("МАТЕМАТИКА"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// ВОПРОС
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "$a + $b = ?",
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ОТВЕТЫ
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5, // 👈 ВОТ ЭТО ГЛАВНОЕ

                children: options.map((e) {
                  return GestureDetector(
                    onTap: () => answer(e),

                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.2),
                          )
                        ],
                      ),

                      child: Center(
                        child: Text(
                          "$e",
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}