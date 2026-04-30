class PlayerModel {
  final String name;
  final String id;
  final int coins;
  final int wins;
  final int gamesPlayed;
  final String rank; // Новичок / Медиум / Профи / Легенда
  final String avatar; // emoji строка
  final List<String> friends;

  PlayerModel({
    required this.name,
    required this.id,
    required this.coins,
    required this.wins,
    required this.gamesPlayed,
    required this.rank,
    required this.avatar,
    required this.friends,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      name: map['name'] ?? 'Player',
      id: map['id'] ?? '0000',
      coins: map['coins'] ?? 0,
      wins: map['wins'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      rank: map['rank'] ?? 'Новичок',
      avatar: map['avatar'] ?? '😊',
      friends: List<String>.from(map['friends'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'coins': coins,
      'wins': wins,
      'gamesPlayed': gamesPlayed,
      'rank': rank,
      'avatar': avatar,
      'friends': friends,
    };
  }
}