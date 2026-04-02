class UserModel{

  String id;

  String name;

  int rating;

  int wins;

  int losses;

  int totalGames;

  int coins;

  bool leaderboardEligible;

  UserModel({

    required this.id,

    required this.name,

    required this.rating,

    required this.wins,

    required this.losses,

    required this.totalGames,

    required this.coins,

    required this.leaderboardEligible

  });

  factory UserModel.fromFirestore(data,id){

    return UserModel(

        id: id,

        name: data['displayName'],

        rating: data['rating'] ?? 0,

        wins: data['wins'] ?? 0,

        losses: data['losses'] ?? 0,

        totalGames: data['totalGames'] ?? 0,

        coins: data['coins'] ?? 0,

        leaderboardEligible:
        data['leaderboardEligible'] ?? false

    );

  }

}