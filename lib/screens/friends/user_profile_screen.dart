import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../core/services/friend_service.dart';
import '../../core/services/notification_service.dart';
import '../chat/chat_screen.dart';
import '../lobby/online/games/room_game.dart';
import '../lobby/online/games/battleship_room.dart';
import '../lobby/online/games/tug_of_war_room.dart';
import '../lobby/online/games/pong_room.dart';
import '../lobby/online/games/tank_room.dart';
class UserProfileScreen extends StatefulWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _friendService = FriendService();
  final _notifService = NotificationService();
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _relationStatus = 'none';
  bool _loading = true;

  final List<Map<String, dynamic>> _games = [
    {
      'name': 'Танки',
      'type': 'tanks',
      'icon': '🎮',
      'color': Colors.green,
    },
    {
      'name': 'Морской бой',
      'type': 'seabattle',
      'icon': '⚓',
      'color': Colors.blue,
    },
    {
      'name': 'Перетяни канат',
      'type': 'tug',
      'icon': '🪢',
      'color': Colors.orange,
    },
    {
      'name': 'Понг',
      'type': 'football',
      'icon': '🏓',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _listenForInvites();
  }

  Future<void> _loadStatus() async {
    final status = await _friendService.getRelationStatus(widget.uid);
    if (mounted) {
      setState(() {
        _relationStatus = status;
        _loading = false;
      });
    }
  }

  void _listenForInvites() {
    FirebaseFirestore.instance
        .collection('game_invites')
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        if (mounted) {
          _showInviteDialog(
            inviteId: doc.id,
            fromUid: data['fromUid'] ?? '',
            roomCode: data['roomCode'] ?? '',
            gameType: data['gameType'] ?? 'tanks',
          );
        }
      }
    });
  }

  void _showInviteDialog({
    required String inviteId,
    required String fromUid,
    required String roomCode,
    required String gameType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(fromUid)
            .get(),
        builder: (context, snap) {
          final name = snap.hasData && snap.data!.exists
              ? (snap.data!.data() as Map<String, dynamic>)['name'] ??
              'Игрок'
              : 'Игрок';
          final gameInfo = _games.firstWhere(
                (g) => g['type'] == gameType,
            orElse: () => {'name': 'Игра', 'icon': '🎮'},
          );

          return AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: Row(
              children: [
                Text(gameInfo['icon'] as String,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                const Text('Приглашение!',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              '$name приглашает тебя в "${gameInfo['name']}"\nКод: $roomCode',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _notifService.respondToInvite(inviteId, false);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Отклонить',
                    style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  await _notifService.respondToInvite(inviteId, true);
                  if (mounted) {
                    Navigator.pop(context);
                    _joinGame(roomCode: roomCode, gameType: gameType);
                  }
                },
                child: const Text('Принять',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _joinGame({required String roomCode, required String gameType}) {
    Widget screen;
    switch (gameType) {
      case 'tanks':
        screen = TankOnlineGame(
          roomId: roomCode,
          isHost: false,
        );
        break;
      case 'seabattle':
        screen = const BattleshipRoomScreen();
        break;
      case 'tug':
        screen = const TugOfWarRoomScreen();
        break;
      case 'football':
        screen = const PongRoomScreen();
        break;
      default:
        screen = TankOnlineGame(
          roomId: roomCode,
          isHost: true,
        );
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showGameSelector() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выбери игру',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._games.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: game['color'] as Color,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _sendGameInvite(
                      gameType: game['type'] as String,
                      gameName: game['name'] as String,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(game['icon'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        game['name'] as String,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendGameInvite({
    required String gameType,
    required String gameName,
  }) async {
    final seed = Random().nextInt(999999);
    final roomCode =
    (100000 + Random().nextInt(900000)).toString();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: Color(0xFF16213E),
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(width: 16),
              Text('Создаём комнату...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    try {
      await _notifService.sendGameInvite(
        toUid: widget.uid,
        roomCode: roomCode,
        gameType: gameType,
      );

      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Приглашение отправлено ✅',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ждём пока друг примет приглашение в "$gameName"...',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Код: ',
                          style: TextStyle(color: Colors.white54)),
                      Text(
                        roomCode,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена',
                    style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange),
                onPressed: () {
                  Navigator.pop(context);
                  Widget screen;
                  switch (gameType) {
                    case 'tanks':
                      screen = TankOnlineGame(
                        roomId: roomCode,
                        isHost: true,
                      );
                      break;
                    case 'seabattle':
                      screen = const BattleshipRoomScreen();
                      break;
                    case 'tug':
                      screen = const TugOfWarRoomScreen();
                      break;
                    case 'football':
                      screen = const PongRoomScreen();
                      break;
                    default:
                      screen = TankOnlineGame(
                        roomId: roomCode,
                        isHost: true,
                      );
                  }
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => screen));
                },
                child: const Text('Войти в комнату',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
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
                child:
                CircularProgressIndicator(color: Colors.orange));
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
                        colors: [
                          Color(0xFF833AB4),
                          Color(0xFFE1306C)
                        ],
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
                              style:
                              const TextStyle(fontSize: 40)),
                        ),
                        const SizedBox(height: 8),
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin:
                              const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status == 'online'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              status == 'online'
                                  ? 'онлайн'
                                  : 'оффлайн',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat(
                                '$coins', 'монет', Colors.yellow),
                            _divider(),
                            _stat('$wins', 'побед',
                                Colors.greenAccent),
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
                            const Icon(Icons.star,
                                color: Colors.orange),
                            const SizedBox(width: 10),
                            Text('Ранг: $rank',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (!_loading) _buildActions(name),
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

  Widget _buildActions(String friendName) {
    if (widget.uid == _myUid) return const SizedBox();

    return Column(
      children: [
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
          _actionButton('Написать', Colors.blue, Icons.message,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(otherUid: widget.uid)),
                );
              }),
          const SizedBox(height: 8),
          _actionButton('Пригласить в игру', Colors.purple,
              Icons.sports_esports,
                  () => _showGameSelector()),
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
            color: c,
            fontSize: 22,
            fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(l,
        style: const TextStyle(
            color: Colors.white38, fontSize: 12)),
  ]);

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white12);
}