import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_provider.dart';
import 'leaderboard_tile.dart';
//ст
class LeaderboardScreen extends StatelessWidget {
  LeaderboardScreen({super.key});
  final LeaderboardProvider provider = LeaderboardProvider();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff020617),

      appBar: AppBar(
        title: const Text("🌍 Global Ranking"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

        stream: provider.getLeaderboard(),

        builder: (context, snapshot) {

          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Ошибка: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          /// 📭 Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Нет игроков 😢",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final players = snapshot.data!.docs;

          return ListView.builder(

            padding: const EdgeInsets.all(12),

            itemCount: players.length,

            itemBuilder: (context, index) {

              final player = players[index].data();

              final name = player['name'] ?? 'Player';
              final rating = player['rating'] ?? 0;

              /// 🎨 Цвет топа
              Color color;
              if (index == 0) color = Colors.amber;
              else if (index == 1) color = Colors.grey;
              else if (index == 2) color = Colors.deepOrange;
              else color = Colors.blueGrey;

              /// 👤 инициалы
              String initials = "";
              final parts = name.toString().split(" ");
              for (var p in parts) {
                if (p.isNotEmpty) initials += p[0];
              }

              return Container(

                margin: const EdgeInsets.only(bottom: 12),

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),

                child: Row(
                  children: [

                    /// 🏆 МЕСТО
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// 👤 АВАТАР
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// 🧑 ИМЯ
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    /// 💰 ОЧКИ
                    Text(
                      "$rating",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}