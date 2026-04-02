import 'package:flutter/material.dart';

class BattleshipScreen extends StatelessWidget {
  const BattleshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Морской бой")),
      body: const Center(
        child: Text(
          "Здесь будет поле Морского боя и сплит экран",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}