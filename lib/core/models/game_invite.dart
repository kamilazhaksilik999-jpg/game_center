class GameInvite {
  final String id;
  final String fromUid;
  final String toUid;
  final String roomCode;
  final String gameType;
  final String status; // pending | accepted | declined
  final DateTime createdAt;

  GameInvite({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.roomCode,
    required this.gameType,
    required this.status,
    required this.createdAt,
  });

  factory GameInvite.fromMap(String id, Map<String, dynamic> data) {
    return GameInvite(
      id: id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      roomCode: data['roomCode'] ?? '',
      gameType: data['gameType'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}