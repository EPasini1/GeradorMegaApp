import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history.dart';

class GameHistoryService {
  static const String _storageKey = 'mega_sena_game_history';
  
  // Save game history to persistent storage
  static Future<bool> saveGameHistory(GameHistory history) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_storageKey, history.toJson());
    } catch (e) {
      print('Error saving game history: $e');
      return false;
    }
  }
  
  // Load game history from persistent storage
  static Future<GameHistory> loadGameHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_storageKey);
      
      if (historyJson != null && historyJson.isNotEmpty) {
        return GameHistory.fromJson(historyJson);
      }
    } catch (e) {
      print('Error loading game history: $e');
    }
    
    // Return empty history if nothing is saved or error occurred
    return GameHistory(games: []);
  }
  
  // Save a single game result
  static Future<bool> saveGameResult(GameResult result) async {
    final GameHistory history = await loadGameHistory();
    history.addGame(result);
    return await saveGameHistory(history);
  }
  
  // Clear all game history
  static Future<bool> clearGameHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing game history: $e');
      return false;
    }
  }
}
