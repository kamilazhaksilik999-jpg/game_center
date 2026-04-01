import 'package:flutter/material.dart';
import '../data/levels.dart';
import 'find_diff_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Выбери уровень")),

      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),

        itemBuilder: (_, i) {

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FindDiffScreen(level: levels[i]),
                ),
              );
            },

            child: Container(
              color: Colors.grey[300],
              child: Center(
                child: Text("Уровень ${i + 1}"),
              ),
            ),
          );
        },
      ),
    );
  }
}