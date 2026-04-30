import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/friend_service.dart';
import 'friend_requests_screen.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _friendService = FriendService();
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabs;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Друзья',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Кнопка заявок с счётчиком
          StreamBuilder<QuerySnapshot>(
            stream: _friendService.incomingRequestsStream(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const FriendRequestsScreen())),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                        child: Center(
                          child: Text('$count',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Все друзья'),
            Tab(text: 'Поиск'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildFriendsList(),
          _buildSearch(),
        ],
      ),
    );
  }

  // ── Список друзей ──
  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.friendsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Text('Пока нет друзей 😔',
                style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final users = List<String>.from(data['users'] ?? []);
            final friendUid = users.firstWhere((u) => u != _myUid);

            return _FriendTile(
              friendUid: friendUid,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => UserProfileScreen(uid: friendUid)),
              ),
              onRemove: () => _friendService.removeFriend(friendUid),
              onBlock: () => _friendService.blockUser(friendUid),
            );
          },
        );
      },
    );
  }

  // ── Поиск ──
  Widget _buildSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Введи ID игрока (#1234)',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
              const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF16213E),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                onPressed: _searchUser,
              ),
            ),
            onSubmitted: (_) => _searchUser(),
          ),
        ),
      ],
    );
  }

  Future<void> _searchUser() async {
    final id = _searchController.text.trim();
    if (id.isEmpty) return;
    final gameId = id.startsWith('#') ? id : '#$id';
    final user = await _friendService.findUserById(gameId);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Игрок не найден 😔')));
      return;
    }
    if (user['uid'] == _myUid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Это ты 😅')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => UserProfileScreen(uid: user['uid'])));
  }
}

// ── Плитка друга ──
class _FriendTile extends StatelessWidget {
  final String friendUid;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onBlock;

  const _FriendTile({
    required this.friendUid,
    required this.onTap,
    required this.onRemove,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Player';
        final avatar = data['avatar'] ?? '😊';
        final status = data['status'] ?? 'offline';
        final rank = data['rank'] ?? 'Новичок';
        final isOnline = status == 'online';

        return ListTile(
          onTap: onTap,
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple.shade300,
                child: Text(avatar,
                    style: const TextStyle(fontSize: 22)),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.grey,
                    border: Border.all(
                        color: const Color(0xFF1A1A2E), width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Text(name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('$rank • ${isOnline ? "онлайн" : "оффлайн"}',
              style: TextStyle(
                  color: isOnline ? Colors.green : Colors.white38,
                  fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white38),
            color: const Color(0xFF16213E),
            onSelected: (val) {
              if (val == 'remove') onRemove();
              if (val == 'block') onBlock();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'remove',
                  child: Text('Удалить из друзей',
                      style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'block',
                  child: Text('Заблокировать',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
    );
  }
}