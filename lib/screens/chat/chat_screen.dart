import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  const ChatScreen({super.key, required this.otherUid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _myUid = FirebaseAuth.instance.currentUser!.uid;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.otherUid);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _chatService.sendMessage(widget.otherUid, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUid)
              .get(),
          builder: (context, snap) {
            if (!snap.hasData) return const Text('...');
            final data =
                snap.data!.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] ?? 'Player';
            final avatar = data['avatar'] ?? '😊';
            final status = data['status'] ?? 'offline';
            return Row(children: [
              Text(avatar, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16)),
                  Text(
                    status == 'online' ? 'онлайн' : 'оффлайн',
                    style: TextStyle(
                        color: status == 'online'
                            ? Colors.green
                            : Colors.white54,
                        fontSize: 12),
                  ),
                ],
              ),
            ]);
          },
        ),
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.messagesStream(widget.otherUid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.orange));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Начни общение! 👋',
                        style: TextStyle(color: Colors.white38)),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data =
                    docs[i].data() as Map<String, dynamic>;
                    final isMe = data['fromUid'] == _myUid;
                    final text = data['text'] ?? '';
                    final time = (data['createdAt'] as Timestamp?)
                        ?.toDate();

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.orange
                              : const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(text,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15)),
                            if (time != null)
                              Text(
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Поле ввода
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: const Color(0xFF16213E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle:
                      const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor:
                      Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange),
                    child: const Icon(Icons.send,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}