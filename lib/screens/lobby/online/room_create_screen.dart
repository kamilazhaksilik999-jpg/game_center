import 'package:flutter/material.dart';

class RoomCreateScreen extends StatelessWidget {
  final String gameName;
  const RoomCreateScreen({super.key, required this.gameName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Создать комнату: $gameName")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Комната для $gameName создана",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text(
              "Код для присоединения: ABC123",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Переход к игре
              },
              child: const Text("Начать игру"),
            ),
          ],
        ),
      ),
    );
  }
}