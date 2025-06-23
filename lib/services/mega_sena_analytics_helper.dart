import 'dart:math';

import '../models/game_history.dart';
import 'mega_sena_api_service.dart';
import 'strategy_analytics_service.dart';

class MegaSenaAnalyticsHelper {
  /// Compare a generated game with a set of actual draw results
  static Future<void> compareWithActualResults({
    required GameResult gameResult,
    int historyResultsToCheck = 5,
  }) async {
    if (gameResult.generationStrategy == null) return;
    
    try {
      // Get the most recent draws to compare against
      final recentResults = await MegaSenaApiService.getLastResults(quantity: historyResultsToCheck);
      if (recentResults.isEmpty) return;
      
      int totalMatches = 0;
      
      // Compare with each recent result and count matching numbers
      for (var result in recentResults) {
        final actualNumbers = MegaSenaApiService.convertNumbersToInt(result.numbers);
        final matchCount = _countMatches(gameResult.numbers, actualNumbers);
        
        // Only count if there are at least 2 matches
        if (matchCount >= 2) {
          totalMatches += matchCount;
        }
      }
      
      // If we found any matches, record them for analytics
      if (totalMatches > 0) {
        await StrategyAnalyticsService.recordMatchedNumbers(
          gameResult.generationStrategy!,
          totalMatches
        );
      }
    } catch (e) {
      print('Error comparing results: $e');
    }
  }
  
  /// Compare two sets of games for scheduled analytics updates
  static Future<void> compareAllGamesHistory({
    required List<GameResult> generatedGames,
    int historyResultsToCheck = 5,
  }) async {
    if (generatedGames.isEmpty) return;
    
    // Limit to 50 most recent games for performance
    final games = generatedGames.length <= 50
        ? generatedGames
        : generatedGames.sublist(0, 50);
    
    try {
      // Get historical results once to compare against all games
      final recentResults = await MegaSenaApiService.getLastResults(quantity: historyResultsToCheck);
      if (recentResults.isEmpty) return;
      
      // Process each game
      for (var game in games) {
        if (game.generationStrategy == null) continue;
        
        int totalMatches = 0;
        // Compare with each recent result
        for (var result in recentResults) {
          final actualNumbers = MegaSenaApiService.convertNumbersToInt(result.numbers);
          final matchCount = _countMatches(game.numbers, actualNumbers);
          
          // Only count if there are at least 2 matches
          if (matchCount >= 2) {
            totalMatches += matchCount;
          }
        }
        
        // Record matches for this game's strategy
        if (totalMatches > 0) {
          await StrategyAnalyticsService.recordMatchedNumbers(
            game.generationStrategy!,
            totalMatches
          );
        }
      }
    } catch (e) {
      print('Error comparing all games: $e');
    }
  }
  
  /// Count how many numbers match between two sets
  static int _countMatches(List<int> generatedNumbers, List<int> actualNumbers) {
    int matches = 0;
    for (var num in generatedNumbers) {
      if (actualNumbers.contains(num)) {
        matches++;
      }
    }
    return matches;
  }
}
