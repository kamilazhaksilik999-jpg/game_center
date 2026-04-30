import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/friend_service.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FriendService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Заявки в друзья',
            style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.incomingRequestsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text('Нет входящих заявок',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final fromUid = data['fromUid'] as String;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(fromUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final user = userSnap.data!.data()
                  as Map<String, dynamic>? ?? {};
                  final name = user['name'] ?? 'Player';
                  final avatar = user['avatar'] ?? '😊';
                  final rank = user['rank'] ?? 'Новичок';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade300,
                      child: Text(avatar,
                          style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(rank,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Принять
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () =>
                              service.acceptRequest(fromUid),
                        ),
                        // Отклонить
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red),
                          onPressed: () =>
                              service.declineRequest(fromUid),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}