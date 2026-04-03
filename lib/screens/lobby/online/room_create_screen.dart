import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RoomCreateScreen extends StatelessWidget {
  final String gameName;
  const RoomCreateScreen({super.key, required this.gameName});

  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    return String.fromCharCodes(
      Iterable.generate(
        5,
            (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String roomCode = generateCode();

    return Scaffold(
      appBar: AppBar(title: Text("Комната: $gameName")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Код комнаты:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomCode)
                    .set({
                  'game': gameName,
                  'player1': 'player1',
                  'player2': null,
                  'status': 'waiting',
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Комната создана")),
                );
              },
              child: const Text("Создать"),
            )
          ],
        ),
      ),
    );
  }
}