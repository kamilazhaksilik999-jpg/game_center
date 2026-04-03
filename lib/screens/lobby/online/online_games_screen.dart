import 'package:flutter/material.dart';
import 'games/battleship_screen.dart';
import 'games/mini_football_screen.dart';
import 'games/rope_pull_screen.dart';
class OnlineGamesScreen extends StatelessWidget {
  final String? selectedMode;
  const OnlineGamesScreen({super.key, this.selectedMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          selectedMode != null ? "Онлайн: $selectedMode" : "Онлайн игры",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _gameCard(
              context,
              "Морской бой",
              Colors.teal,
              const BattleshipScreen(isAi: true), // запускаем ИИ-режим
            ),
            _gameCard(
              context,
              "Мини-футбол",
              Colors.green,
              const MiniFootballScreen(),
            ),
            _gameCard(context, "Танк", Colors.orange, null),
            _gameCard(
              context,
              "Перетяни канат",
              Colors.redAccent,
              const RopePullScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, String title, Color color, Widget? screen) {
    return GestureDetector(
      onTap: () {
        if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2,2))],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}