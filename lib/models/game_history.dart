import 'dart:convert';

class GameResult {
  final List<int> numbers;
  final DateTime dateGenerated;
  final int numbersPerGame;
  final String? generationStrategy; // New field to track how the game was generated
  
  GameResult({
    required this.numbers,
    required this.dateGenerated,
    this.numbersPerGame = 6,
    this.generationStrategy,
  });
  
  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'numbers': numbers,
      'dateGenerated': dateGenerated.toIso8601String(),
      'numbersPerGame': numbersPerGame,
      'generationStrategy': generationStrategy,
    };
  }
    // Create from Map for JSON deserialization
  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      numbers: List<int>.from(map['numbers']),
      dateGenerated: DateTime.parse(map['dateGenerated']),
      numbersPerGame: map['numbersPerGame'] ?? 6,
      generationStrategy: map['generationStrategy'],
    );
  }
  
  // JSON serialization methods
  String toJson() => json.encode(toMap());
  
  factory GameResult.fromJson(String source) => 
      GameResult.fromMap(json.decode(source));
}

class GameHistory {
  final List<GameResult> games;
  
  GameHistory({required this.games});
  
  // Add a new game result
  void addGame(GameResult game) {
    games.add(game);
  }
  
  // Get all games
  List<GameResult> getAllGames() {
    return List.from(games);
  }
  
  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'games': games.map((x) => x.toMap()).toList(),
    };
  }
  
  // Create from Map for JSON deserialization
  factory GameHistory.fromMap(Map<String, dynamic> map) {
    return GameHistory(
      games: List<GameResult>.from(
        map['games']?.map((x) => GameResult.fromMap(x)) ?? const [],
      ),
    );
  }
  
  // JSON serialization methods
  String toJson() => json.encode(toMap());
  
  factory GameHistory.fromJson(String source) => 
      GameHistory.fromMap(json.decode(source));
}
