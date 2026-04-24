import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RoomCreateScreen extends StatefulWidget {
  final String gameName;
  const RoomCreateScreen({super.key, required this.gameName});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  late String roomCode;
  bool isCreated = false;
  bool opponentJoined = false;

  @override
  void initState() {
    super.initState();
    roomCode = generateCode();
  }

  String generateCode() {
    return String.fromCharCodes(
      Iterable.generate(
        6,
            (_) => '0123456789'.codeUnitAt(Random().nextInt(10)),
      ),
    );
  }

  Future<void> createRoom() async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .set({
      'game': widget.gameName,
      'player1': 'player1',
      'player2': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      isCreated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Комната: ${widget.gameName}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Код комнаты:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),

            const SizedBox(height: 20),

            if (!isCreated)
              ElevatedButton(
                onPressed: createRoom,
                child: const Text("Создать комнату"),
              ),

            if (isCreated) ...[
              const SizedBox(height: 20),

              // Слушаем Firestore — ждём пока player2 войдёт
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomCode)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final data =
                  snapshot.data!.data() as Map<String, dynamic>?;

                  final player2 = data?['player2'];

                  if (player2 != null) {
                    // Игрок зашёл — можно начинать
                    return Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 48),
                        const SizedBox(height: 10),
                        const Text(
                          "Противник подключился!",
                          style: TextStyle(
                              fontSize: 18, color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: переход к игре
                          },
                          child: const Text("Начать игру"),
                        ),
                      ],
                    );
                  }

                  // Ожидание с таймером
                  return Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        "Ожидание противника...",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Поделитесь кодом с другом",
                        style:
                        TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () async {
                          // Удаляем комнату если отменили
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomCode)
                              .delete();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          "Отменить",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}