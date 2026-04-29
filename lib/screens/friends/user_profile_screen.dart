import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/friend_service.dart';
import '../../core/services/notification_service.dart';
import '../chat/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _friendService = FriendService();
  final _notifService = NotificationService();
  final _myUid = FirebaseAuth.instance.currentUser!.uid;
  String _relationStatus = 'none';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status =
    await _friendService.getRelationStatus(widget.uid);
    if (mounted) setState(() { _relationStatus = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          final data =
              snap.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Player';
          final avatar = data['avatar'] ?? '😊';
          final rank = data['rank'] ?? 'Новичок';
          final coins = data['coins'] ?? 0;
          final wins = data['wins'] ?? 0;
          final games = data['gamesPlayed'] ?? 0;
          final status = data['status'] ?? 'offline';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF833AB4),
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFE1306C)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.orange.shade300,
                          child: Text(avatar,
                              style: const TextStyle(fontSize: 40)),
                        ),
                        const SizedBox(height: 8),
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status == 'online'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              status == 'online' ? 'онлайн' : 'оффлайн',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Статистика
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat('$coins', 'монет', Colors.yellow),
                            _divider(),
                            _stat('$wins', 'побед', Colors.greenAccent),
                            _divider(),
                            _stat('$games', 'игр',
                                Colors.lightBlueAccent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Ранг
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange),
                            const SizedBox(width: 10),
                            Text('Ранг: $rank',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Кнопки действий
                      if (!_loading) _buildActions(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    if (widget.uid == _myUid) return const SizedBox();

    return Column(
      children: [
        // Кнопка в зависимости от статуса
        if (_relationStatus == 'none')
          _actionButton('Добавить в друзья', Colors.orange,
              Icons.person_add, () async {
                await _friendService.sendRequest(widget.uid);
                setState(() => _relationStatus = 'request_sent');
              }),

        if (_relationStatus == 'request_sent')
          _actionButton('Отменить заявку', Colors.grey,
              Icons.cancel, () async {
                await _friendService.cancelRequest(widget.uid);
                setState(() => _relationStatus = 'none');
              }),

        if (_relationStatus == 'request_received')
          Row(children: [
            Expanded(
              child: _actionButton('Принять', Colors.green,
                  Icons.check, () async {
                    await _friendService.acceptRequest(widget.uid);
                    setState(() => _relationStatus = 'friends');
                  }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton('Отклонить', Colors.red,
                  Icons.close, () async {
                    await _friendService.declineRequest(widget.uid);
                    setState(() => _relationStatus = 'none');
                  }),
            ),
          ]),

        if (_relationStatus == 'friends') ...[
          _actionButton('Написать', Colors.blue,
              Icons.message, () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(otherUid: widget.uid)));
              }),
          const SizedBox(height: 8),
          _actionButton('Пригласить в игру', Colors.purple,
              Icons.sports_esports, () async {
                await _notifService.sendGameInvite(
                  toUid: widget.uid,
                  roomCode: '123456',
                  gameType: 'tanks',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Приглашение отправлено! ✅')));
                }
              }),
          const SizedBox(height: 8),
          _actionButton('Удалить из друзей', Colors.red,
              Icons.person_remove, () async {
                await _friendService.removeFriend(widget.uid);
                setState(() => _relationStatus = 'none');
              }),
        ],

        if (_relationStatus == 'blocked')
          _actionButton('Разблокировать', Colors.grey,
              Icons.lock_open, () async {
                await _friendService.unblockUser(widget.uid);
                setState(() => _relationStatus = 'none');
              }),

        const SizedBox(height: 8),
        if (_relationStatus != 'blocked')
          _actionButton('Заблокировать', Colors.red.shade900,
              Icons.block, () async {
                await _friendService.blockUser(widget.uid);
                setState(() => _relationStatus = 'blocked');
              }),
      ],
    );
  }

  Widget _actionButton(
      String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _stat(String v, String l, Color c) => Column(children: [
    Text(v,
        style: TextStyle(
            color: c, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(l,
        style: const TextStyle(color: Colors.white38, fontSize: 12)),
  ]);

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white12);
}