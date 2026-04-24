import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_provider.dart';
import 'leaderboard_tile.dart';
<<<<<<< HEAD
//ст
=======

>>>>>>> 6542301c3be05368ece585f9b0435e4c38613b56
class LeaderboardScreen extends StatelessWidget {
  LeaderboardScreen({super.key});
  final LeaderboardProvider provider = LeaderboardProvider();

  @override
  Widget build(BuildContext context) {
    final currentUserId = provider.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "🌍 Мировой рейтинг",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.getLeaderboard(),

        builder: (context, snapshot) {

          // ⏳ Загрузка
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          // ❌ Ошибка
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "Ошибка загрузки\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          // 📭 Пусто
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("😢", style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    "Пока никого нет\nСыграй первую игру!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final players = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final data   = players[index].data();
              final userId = players[index].id;

              return LeaderboardTile(
                player:        data,
                index:         index,
                isCurrentUser: userId == currentUserId, // 👈 подсвечивает тебя
              );
            },
          );
        },
      ),
    );
  }
}