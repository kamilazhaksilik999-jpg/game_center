import 'package:flutter/material.dart';

class DiffStartScreen extends StatelessWidget {
  const DiffStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// 🖼 КАРТИНКА НА ВЕСЬ ЭКРАН
          Positioned.fill(
            child: Image.asset(
              "assets/diff.png",
              fit: BoxFit.cover,
            ),
          ),

          /// 🔲 затемнение (как в топ играх)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          /// 🎮 КНОПКА
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/find_diff");
              },
              child: const Text(
                "ИГРАТЬ",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}