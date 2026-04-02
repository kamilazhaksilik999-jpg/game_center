import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // темный фон вместо серого
      appBar: AppBar(
        title: const Text("🌐 Лобби Онлайн-игр"),
        backgroundColor: const Color(0xFF1E293B), // красивый темно-синий
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            "Здесь будет список онлайн-игр!",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white, // белый текст на темном фоне
            ),
          ),
        ),
      ),
    );
  }
}