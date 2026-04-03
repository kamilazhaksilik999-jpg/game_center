import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'games/battleship_screen.dart';

class RoomJoinScreen extends StatelessWidget {
  final String gameName;
  const RoomJoinScreen({super.key, required this.gameName});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text("Вход в $gameName")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Введите код комнаты",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {

                final roomId = controller.text.trim();

                final doc = await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .get();

                // ❗ если комнаты нет
                if (!doc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Комната не найдена")),
                  );
                  return;
                }

                // ✅ подключаемся как player2
                await doc.reference.update({
                  'player2': 'player2',
                  'status': 'playing',
                });

                // 🚀 переход в игру
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BattleshipScreen(roomId: roomId),
                  ),
                );
              },
              child: const Text("Присоединиться"),
            )
          ],
        ),
      ),
    );
  }
}