import 'dart:math';
import '../models/game_history.dart';
import 'mega_sena_api_service.dart';

class MegaSenaGeneratorService {
  // Strategy constants for better reference
  static const int STRATEGY_FREQUENCY = 0;
  static const int STRATEGY_OVERDUE = 1;
  static const int STRATEGY_PATTERNS = 2;
  static const int STRATEGY_HYBRID = 3;
  static const int STRATEGY_RANDOM = 4;
  
  // List of strategy names for better display
  static const Map<int, String> strategyNames = {
    STRATEGY_FREQUENCY: 'Baseado em frequência',
    STRATEGY_OVERDUE: 'Incluindo números atrasados',
    STRATEGY_PATTERNS: 'Padrões de jogos recentes',
    STRATEGY_HYBRID: 'Abordagem híbrida',
    STRATEGY_RANDOM: 'Aleatório'
  };
  
  // Generate numbers considering historical data
  static Future<List<GameResult>> generateIntelligentNumbers({
    required int quantityOfGames,
    required int numbersPerGame,
    bool useHistoricalData = true,
    List<int>? selectedStrategies,
  }) async {
    final List<GameResult> results = [];
    
    // Get historical data if needed
    List<int> frequencyMap = List.filled(61, 0); // Index 0 won't be used (numbers are 1-60)
    List<List<int>> historicalNumbers = [];
    Map<int, int> lastAppearanceMap = {}; // Track when a number last appeared
    
    if (useHistoricalData) {
      try {
        final historicalResults = await MegaSenaApiService.getLastResults(quantity: 30);
        int contestCount = historicalResults.length;
        
        // Build frequency map and track patterns from historical results
        for (int i = 0; i < contestCount; i++) {
          var result = historicalResults[i];
          final numbers = MegaSenaApiService.convertNumbersToInt(result.numbers);
          historicalNumbers.add(numbers);
          
          for (var number in numbers) {
            frequencyMap[number]++;
            lastAppearanceMap[number] = i; // Lower index means more recent appearance
          }
        }
      } catch (e) {
        print('Error fetching historical data: $e');
        // If there's an error, we'll just use random generation
        useHistoricalData = false;
      }
    }
    
    final random = Random();
    
    List<int> availableStrategies = [];
    
    // Determine which strategies to use
    if (useHistoricalData && historicalNumbers.isNotEmpty) {
      if (selectedStrategies != null && selectedStrategies.isNotEmpty) {
        // Use only the selected strategies
        availableStrategies = selectedStrategies;
      } else {
        // Use all strategies by default
        availableStrategies = [
          STRATEGY_FREQUENCY, 
          STRATEGY_OVERDUE, 
          STRATEGY_PATTERNS, 
          STRATEGY_HYBRID
        ];
      }
    } else {
      // If historical data is not available or not used, only random strategy is available
      availableStrategies = [STRATEGY_RANDOM];
    }
    
    for (var gameIndex = 0; gameIndex < quantityOfGames; gameIndex++) {
      Set<int> selectedNumbers = {};
      String? strategyUsed;
      
      if (useHistoricalData && historicalNumbers.isNotEmpty) {
        // Choose strategy from available ones for this game
        int strategyIndex = random.nextInt(availableStrategies.length);
        int strategy = availableStrategies[strategyIndex];
        strategyUsed = strategyNames[strategy];
        
        switch (strategy) {
          case STRATEGY_FREQUENCY:
            // Strategy 1: Balanced selection based on frequency
            _generateWithFrequencyWeighting(
              selectedNumbers,
              frequencyMap,
              numbersPerGame,
              random
            );
            break;
            
          case STRATEGY_OVERDUE:
            // Strategy 2: Include some "overdue" numbers
            // (numbers that haven't appeared recently but were common before)
            _generateWithOverdueNumbers(
              selectedNumbers,
              frequencyMap,
              lastAppearanceMap,
              numbersPerGame,
              random
            );
            break;
            
          case STRATEGY_PATTERNS:
            // Strategy 3: Use patterns from recent games
            _generateWithPatternsFromRecentGames(
              selectedNumbers,
              historicalNumbers,
              numbersPerGame,
              random
            );
            break;
            
          case STRATEGY_HYBRID:
            // Strategy 4: Hybrid approach with some fully random numbers
            _generateWithHybridApproach(
              selectedNumbers,
              frequencyMap,
              lastAppearanceMap,
              numbersPerGame,
              random
            );
            break;
            
          default:
            // Fallback to random if somehow an invalid strategy is selected
            while (selectedNumbers.length < numbersPerGame) {
              int randomNumber = random.nextInt(60) + 1;
              selectedNumbers.add(randomNumber);
            }
            strategyUsed = strategyNames[STRATEGY_RANDOM];
            break;
        }
      } else {
        // Use completely random selection if historical data isn't available
        while (selectedNumbers.length < numbersPerGame) {
          int randomNumber = random.nextInt(60) + 1;
          selectedNumbers.add(randomNumber);
        }
        strategyUsed = strategyNames[STRATEGY_RANDOM];
      }
      
      // Sort the selected numbers
      List<int> sortedNumbers = selectedNumbers.toList()..sort();
      
      // Create and add the result
      results.add(GameResult(
        numbers: sortedNumbers,
        dateGenerated: DateTime.now(),
        numbersPerGame: numbersPerGame,
        generationStrategy: strategyUsed,
      ));
    }
    
    return results;
  }
  
  // Strategy 1: Generate numbers based on frequency weighting
  static void _generateWithFrequencyWeighting(
    Set<int> selectedNumbers,
    List<int> frequencyMap,
    int numbersPerGame,
    Random random
  ) {
    // Create a weighted list where numbers with higher frequency appear more often
    List<int> weightedPool = [];
    for (int i = 1; i <= 60; i++) {
      // Add number to pool frequency+1 times (ensure even 0 frequency has a chance)
      for (int j = 0; j < frequencyMap[i] + 1; j++) {
        weightedPool.add(i);
      }
    }
    
    // Pick numbers from the weighted pool
    while (selectedNumbers.length < numbersPerGame) {
      int selectedNumber = weightedPool[random.nextInt(weightedPool.length)];
      selectedNumbers.add(selectedNumber);
    }
  }
  
  // Strategy 2: Include overdue numbers that are likely to appear soon
  static void _generateWithOverdueNumbers(
    Set<int> selectedNumbers,
    List<int> frequencyMap,
    Map<int, int> lastAppearanceMap,
    int numbersPerGame,
    Random random
  ) {
    // Select some numbers that have high frequency but haven't appeared recently
    List<MapEntry<int, double>> scoredNumbers = [];
    
    for (int i = 1; i <= 60; i++) {
      // Calculate a score based on frequency and recency
      // High frequency but not recent = high score (good candidates)
      double frequencyScore = frequencyMap[i] / 5.0; // Normalize frequency
      double recencyPenalty = lastAppearanceMap.containsKey(i) ? lastAppearanceMap[i]! * 0.5 : 0;
      double finalScore = frequencyScore - recencyPenalty;
      
      scoredNumbers.add(MapEntry(i, finalScore));
    }
    
    // Sort by score (descending)
    scoredNumbers.sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 60% from scored numbers
    int topCount = (numbersPerGame * 0.6).round();
    for (int i = 0; i < topCount && i < scoredNumbers.length; i++) {
      selectedNumbers.add(scoredNumbers[i].key);
    }
    
    // Fill the rest with random numbers
    while (selectedNumbers.length < numbersPerGame) {
      int randomNumber = random.nextInt(60) + 1;
      selectedNumbers.add(randomNumber);
    }
  }
  
  // Strategy 3: Use patterns from recent games
  static void _generateWithPatternsFromRecentGames(
    Set<int> selectedNumbers,
    List<List<int>> historicalNumbers,
    int numbersPerGame,
    Random random
  ) {
    if (historicalNumbers.isEmpty) return;
    
    // Get 2-3 random recent games
    List<List<int>> recentGameSamples = [];
    int samplesToTake = min(3, historicalNumbers.length);
    
    for (int i = 0; i < samplesToTake; i++) {
      int gameIndex = random.nextInt(min(10, historicalNumbers.length));
      recentGameSamples.add(historicalNumbers[gameIndex]);
    }
    
    // Take some numbers directly from these samples
    for (var game in recentGameSamples) {
      if (selectedNumbers.length >= numbersPerGame) break;
      
      // Take 1-2 random numbers from each sampled game
      int numbersToTake = min(1 + random.nextInt(2), 
                              min(game.length, numbersPerGame - selectedNumbers.length));
      
      List<int> shuffled = List.from(game)..shuffle(random);
      for (int i = 0; i < numbersToTake; i++) {
        selectedNumbers.add(shuffled[i]);
      }
    }
    
    // Fill the rest with random numbers
    while (selectedNumbers.length < numbersPerGame) {
      int randomNumber = random.nextInt(60) + 1;
      selectedNumbers.add(randomNumber);
    }
  }
  
  // Strategy 4: Hybrid approach
  static void _generateWithHybridApproach(
    Set<int> selectedNumbers,
    List<int> frequencyMap,
    Map<int, int> lastAppearanceMap,
    int numbersPerGame,
    Random random
  ) {
    // 40% based on frequency
    int frequencyBasedCount = (numbersPerGame * 0.4).round();
    // 30% based on "overdue" numbers
    int overdueCount = (numbersPerGame * 0.3).round();
    // 30% random numbers
    int randomCount = numbersPerGame - frequencyBasedCount - overdueCount;
    
    // Add frequent numbers
    List<MapEntry<int, int>> sortedByFrequency = [];
    for (int i = 1; i <= 60; i++) {
      sortedByFrequency.add(MapEntry(i, frequencyMap[i]));
    }
    sortedByFrequency.sort((a, b) => b.value.compareTo(a.value));
    
    // Get some from the most frequent
    for (int i = 0; i < min(frequencyBasedCount, sortedByFrequency.length); i++) {
      if (random.nextDouble() < 0.7) { // 70% chance to pick from top frequency
        selectedNumbers.add(sortedByFrequency[i].key);
      } else {
        // Choose a random position from top half
        int pos = random.nextInt(30);
        selectedNumbers.add(sortedByFrequency[pos].key);
      }
    }
    
    // Add some overdue numbers
    List<MapEntry<int, int>> sortedByOverdue = [];
    for (int i = 1; i <= 60; i++) {
      if (!selectedNumbers.contains(i) && frequencyMap[i] > 0) {
        // High value = appeared less recently (more overdue)
        int overdueScore = lastAppearanceMap.containsKey(i) ? lastAppearanceMap[i]! : 0;
        sortedByOverdue.add(MapEntry(i, overdueScore));
      }
    }
    sortedByOverdue.sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < min(overdueCount, sortedByOverdue.length); i++) {
      selectedNumbers.add(sortedByOverdue[i].key);
    }
    
    // Fill the rest with completely random numbers
    while (selectedNumbers.length < numbersPerGame) {
      int randomNumber = random.nextInt(60) + 1;
      selectedNumbers.add(randomNumber);
    }
  }
}
