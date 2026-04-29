import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/friend_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = NotificationService();
    final friendService = FriendService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Уведомления',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: notifService.markAllRead,
            child: const Text('Все прочитано',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifService.notificationsStream(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text('Нет уведомлений',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? '';
              final fromUid = data['fromUid'] ?? '';
              final text = data['text'] ?? '';
              final read = data['read'] ?? false;
              final time =
              (data['createdAt'] as Timestamp?)?.toDate();

              IconData icon;
              Color color;
              switch (type) {
                case 'friend_request':
                  icon = Icons.person_add;
                  color = Colors.blue;
                  break;
                case 'friend_accepted':
                  icon = Icons.people;
                  color = Colors.green;
                  break;
                case 'game_invite':
                  icon = Icons.sports_esports;
                  color = Colors.purple;
                  break;
                case 'message':
                  icon = Icons.message;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.notifications;
                  color = Colors.white;
              }

              return Container(
                color: read
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.05),
                child: ListTile(
                  onTap: () async {
                    await notifService.markRead(doc.id);
                    // Принять заявку прямо из уведомления
                    if (type == 'friend_request') {
                      await friendService.acceptRequest(fromUid);
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(fromUid)
                        .get(),
                    builder: (context, userSnap) {
                      String name = '...';
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final userData = userSnap.data!.data();
                        if (userData != null) {
                          name = (userData as Map<String, dynamic>)['name'] ?? 'Player';
                        }
                      }
                      return Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  subtitle: Text(text,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!read)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange),
                        ),
                      if (time != null)
                        Text(
                          '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}