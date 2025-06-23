import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history.dart';

// Strategy stats model
class _StrategyStats {
  final String strategyName;
  int gamesGenerated = 0;
  int matchedNumbers = 0; // Count of numbers that matched with real draws
  
  _StrategyStats(this.strategyName);
  
  Map<String, dynamic> toMap() {
    return {
      'strategyName': strategyName,
      'gamesGenerated': gamesGenerated,
      'matchedNumbers': matchedNumbers,
    };
  }
  
  factory _StrategyStats.fromMap(Map<String, dynamic> map) {
    final stats = _StrategyStats(map['strategyName']);
    stats.gamesGenerated = map['gamesGenerated'] ?? 0;
    stats.matchedNumbers = map['matchedNumbers'] ?? 0;
    return stats;
  }
}

/// A service to track and analyze the performance of different strategies
class StrategyAnalyticsService {
  static const String _strategyStatsKey = 'strategy_stats';
    // Record that a game was generated using a specific strategy
  static Future<void> recordGameGenerated(String strategy) async {
    final prefs = await SharedPreferences.getInstance();
    final statsMap = await _getStatsMap(prefs);
    
    if (!statsMap.containsKey(strategy)) {
      statsMap[strategy] = _StrategyStats(strategy);
    }
    
    statsMap[strategy]!.gamesGenerated++;
    await _saveStatsMap(prefs, statsMap);
  }
    // Record when a game matches numbers with real draws
  static Future<void> recordMatchedNumbers(String strategy, int matchCount) async {
    final prefs = await SharedPreferences.getInstance();
    final statsMap = await _getStatsMap(prefs);
    
    if (!statsMap.containsKey(strategy)) {
      statsMap[strategy] = _StrategyStats(strategy);
    }
    
    statsMap[strategy]!.matchedNumbers += matchCount;
    await _saveStatsMap(prefs, statsMap);
  }
    // Get statistics for all strategies
  static Future<Map<String, _StrategyStats>> getAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    return await _getStatsMap(prefs);
  }
  
  // Get most successful strategy based on match rate
  static Future<String?> getMostSuccessfulStrategy() async {
    final stats = await getAllStats();
    if (stats.isEmpty) return null;
    
    String? bestStrategy;
    double bestRate = -1;
    
    stats.forEach((strategy, stat) {
      if (stat.gamesGenerated > 0) {
        double matchRate = stat.matchedNumbers / stat.gamesGenerated;
        if (matchRate > bestRate) {
          bestRate = matchRate;
          bestStrategy = strategy;
        }
      }
    });
    
    return bestStrategy;
  }
  
  // Reset all statistics
  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_strategyStatsKey);
  }
    // Helper methods for serialization
  static Future<Map<String, _StrategyStats>> _getStatsMap(SharedPreferences prefs) async {
    final String? statsJson = prefs.getString(_strategyStatsKey);
    if (statsJson == null) return {};
    
    final Map<String, dynamic> jsonMap = jsonDecode(statsJson);
    final Map<String, _StrategyStats> statsMap = {};
    
    jsonMap.forEach((key, value) {
      statsMap[key] = _StrategyStats.fromMap(value);
    });
    
    return statsMap;
  }
  
  static Future<void> _saveStatsMap(
      SharedPreferences prefs, Map<String, _StrategyStats> statsMap) async {
    final Map<String, dynamic> jsonMap = {};
    
    statsMap.forEach((key, value) {
      jsonMap[key] = value.toMap();
    });
    
    await prefs.setString(_strategyStatsKey, jsonEncode(jsonMap));
  }
}
