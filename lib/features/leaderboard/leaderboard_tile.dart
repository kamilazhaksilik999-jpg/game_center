import 'package:flutter/material.dart';

class LeaderboardTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final int index;
  final bool isCurrentUser;

  const LeaderboardTile({
    super.key,
    required this.player,
    required this.index,
    this.isCurrentUser = false,
  });

  Color get _medalColor {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey.shade400;
    if (index == 2) return Colors.deepOrange;
    return Colors.blueGrey;
  }

  String get _medal {
    if (index == 0) return '🥇';
    if (index == 1) return '🥈';
    if (index == 2) return '🥉';
    return '#${index + 1}';
  }

  String get _initials {
    final name = (player['name'] ?? 'P').toString().trim();
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name    = (player['name']       ?? 'Player').toString();
    final rating  = player['rating']      ?? 0;
    final wins    = player['wins']        ?? 0;
    final total   = player['totalGames']  ?? 0;
    final winRate = total > 0
        ? ((wins / total) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentUser
              ? [Colors.orange.withOpacity(0.2), const Color(0xFF0F172A)]
              : index < 3
              ? [_medalColor.withOpacity(0.15), const Color(0xFF0F172A)]
              : [const Color(0xFF1E293B), const Color(0xFF020617)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentUser
              ? Colors.orange.withOpacity(0.8)
              : _medalColor.withOpacity(0.4),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? Colors.orange.withOpacity(0.2)
                : _medalColor.withOpacity(index < 3 ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _medal,
              style: TextStyle(
                color: _medalColor,
                fontSize: index < 3 ? 24 : 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: isCurrentUser
                ? Colors.orange.withOpacity(0.4)
                : _medalColor.withOpacity(0.25),
            child: Text(
              _initials,
              style: TextStyle(
                color: isCurrentUser ? Colors.orange : _medalColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.orange : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(Вы)',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ]
                  ],
                ),
                Text(
                  "Игр: $total  •  Побед: $winRate%",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$rating",
                style: TextStyle(
                  color: isCurrentUser ? Colors.orange : _medalColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "rating",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}