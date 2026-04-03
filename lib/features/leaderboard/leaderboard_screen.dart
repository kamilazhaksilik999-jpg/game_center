import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'leaderboard_provider.dart';
import 'leaderboard_tile.dart';

class LeaderboardScreen extends StatelessWidget {

  LeaderboardScreen({super.key});

  final LeaderboardProvider provider =
  LeaderboardProvider();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xff020617),

      appBar: AppBar(

        title:
        const Text("Global Ranking"),

        backgroundColor:
        Colors.transparent,

        elevation: 0,

      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

        stream:
        provider.getLeaderboard(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Нет игроков 😢"));
          }
          /// ⏳ Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );

          }

          /// ❌ Error
          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );

          }

          /// 📭 Empty
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                "No players yet",
                style: TextStyle(color: Colors.white),
              ),
            );

          }

          final players =
              snapshot.data!.docs;

          return ListView.builder(

            itemCount:
            players.length,

            itemBuilder:
                (context, index) {

              final player =
              players[index].data();

              return LeaderboardTile(

                player:
                player,

                index:
                index,

              );

            },

          );

        },

      ),

    );

  }

}