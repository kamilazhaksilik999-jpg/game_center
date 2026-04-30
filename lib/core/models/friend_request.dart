class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final String status; // pending | accepted | declined
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequest(
      id: id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'toUid': toUid,
    'status': status,
    'createdAt': createdAt,
  };
}