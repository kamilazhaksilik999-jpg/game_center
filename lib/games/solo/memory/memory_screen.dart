import 'dart:math';
import 'package:flutter/material.dart';
import '../../../widgets/win_dialog.dart';
import '../../../core/services/coin_service.dart';
import '../../../widgets/win_dialog.dart';

void win(BuildContext context) {
  CoinService.addCoins(10);

  showWinDialog(context);
}
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<String> emojis = ["🍎","🍌","🍇","🍉","🍒","🍍"];
  late List<String> cards;

  List<bool> revealed = [];
  int? firstIndex;
  int? secondIndex;

  @override
  void initState() {
    super.initState();
    cards = [...emojis, ...emojis];
    cards.shuffle(Random());
    revealed = List.generate(cards.length, (_) => false);
  }

  void checkWin() {
    if (revealed.every((e) => e)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showWinDialog(context);
      });
    }
  }

  void onTap(int index) async {
    if (revealed[index]) return;

    setState(() => revealed[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      secondIndex = index;

      await Future.delayed(const Duration(milliseconds: 500));

      if (cards[firstIndex!] != cards[secondIndex!]) {
        setState(() {
          revealed[firstIndex!] = false;
          revealed[secondIndex!] = false;
        });
      } else {
        checkWin();
      }

      firstIndex = null;
      secondIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("ПАМЯТЬ"),
        backgroundColor: Colors.blue,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.builder(
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),

          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => onTap(index),

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),

                decoration: BoxDecoration(
                  gradient: revealed[index]
                      ? const LinearGradient(
                      colors: [Colors.white, Colors.grey])
                      : const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.2),
                    )
                  ],
                ),

                child: Center(
                  child: revealed[index]
                      ? Text(
                    cards[index],
                    style: const TextStyle(fontSize: 28),
                  )
                      : const Icon(Icons.help, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}