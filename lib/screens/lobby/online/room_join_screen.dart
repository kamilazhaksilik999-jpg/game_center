import 'package:flutter/material.dart';

class RoomJoinScreen extends StatelessWidget {
  final String gameName;
  const RoomJoinScreen({super.key, required this.gameName});

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text("Присоединиться к $gameName")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Введите код комнаты",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: проверка кода и переход к игре
              },
              child: const Text("Присоединиться"),
            )
          ],
        ),
      ),
    );
  }
}