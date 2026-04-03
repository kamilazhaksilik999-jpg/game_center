import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BattleshipScreen extends StatelessWidget {
  final String roomId;
  const BattleshipScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Морской бой")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [

              Text("Статус: ${data['status']}"),

              Expanded(
                child: GridView.builder(
                  itemCount: 100,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // логика выстрела
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        color: Colors.blue[200],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}