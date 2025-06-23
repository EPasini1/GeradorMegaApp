import 'package:flutter/material.dart';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'models/game_history.dart';
import 'services/game_history_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador Mega Sena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gerador Mega Sena'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final List<int> _generatedNumbers = [];
  int _quantityOfGames = 1;
  int _numbersPerGame = 6; // Default to 6 numbers per game
  bool _isGenerating = false;
  bool _showHistory = false;
  GameHistory _gameHistory = GameHistory(games: []);
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _loadGameHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGameHistory() async {
    final GameHistory history = await GameHistoryService.loadGameHistory();
    setState(() {
      _gameHistory = history;
    });
  }
    void _generateNumbers() async {
    setState(() {
      _isGenerating = true;
      _generatedNumbers.clear();
      _animationController.reset();
    });
    
    // Create a random number generator
    final random = Random();
    final List<GameResult> newGames = [];
    
    // Generate the specified number of games
    for (var gameIndex = 0; gameIndex < _quantityOfGames; gameIndex++) {
      // Generate unique numbers between 1 and 60
      Set<int> numbers = {};
      
      // Generate the specified number of unique random numbers
      while (numbers.length < _numbersPerGame) {
        int randomNumber = random.nextInt(60) + 1; // Random number between 1 and 60
        numbers.add(randomNumber);
      }
      
      List<int> sortedNumbers = numbers.toList()..sort();
      
      // Add the sorted numbers for this game to the results list
      _generatedNumbers.addAll(sortedNumbers);
      
      // Create a game result and add it to history
      final gameResult = GameResult(
        numbers: sortedNumbers,
        dateGenerated: DateTime.now(),
        numbersPerGame: _numbersPerGame,
      );
      newGames.add(gameResult);
    }
    
    // Save the new games to history
    for (var game in newGames) {
      await GameHistoryService.saveGameResult(game);
    }
    
    // Reload the game history
    await _loadGameHistory();
    
    setState(() {
      _isGenerating = false;
      _animationController.forward();
    });
  }
    void _shareResults() {
    if (_generatedNumbers.isEmpty) return;
    
    String shareText = 'Meus números da Mega Sena:\n\n';
    
    for (int i = 0; i < _quantityOfGames; i++) {
      List<int> gameNumbers = _generatedNumbers.sublist(i * _numbersPerGame, (i + 1) * _numbersPerGame);
      shareText += 'Jogo ${i + 1}: ${gameNumbers.join(' - ')}\n';
    }
    
    Share.share(shareText);
  }
  
  void _clearHistory() async {
    final bool success = await GameHistoryService.clearGameHistory();
    if (success) {
      setState(() {
        _gameHistory = GameHistory(games: []);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Histórico apagado com sucesso!')),
        );
      }
    }
  }
  
  // Build the history view
  Widget _buildHistoryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Histórico de Jogos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        _gameHistory.games.isEmpty
            ? const Expanded(
                child: Center(
                  child: Text(
                    'Nenhum jogo no histórico',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _gameHistory.games.length,
                  itemBuilder: (context, index) {
                    final game = _gameHistory.games[_gameHistory.games.length - index - 1];
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jogo ${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '(${game.numbers.length} números)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  dateFormat.format(game.dateGenerated),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: game.numbers.map((number) {
                                return Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      number.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _clearHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar Histórico'),
          ),
        ),
      ],
    );
  }
  
  // Build the generator view
  Widget _buildGeneratorView() {
    return Column(
      children: [        // Game quantity and numbers per game selectors
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Quantidade de jogos:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _quantityOfGames,
                    items: List.generate(10, (index) => index + 1)
                        .map((int value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _quantityOfGames = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Números por jogo:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _numbersPerGame,
                    items: List.generate(10, (index) => index + 6) // From 6 to 15
                        .map((int value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ))
                        .toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _numbersPerGame = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Results display
        Expanded(
          child: _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : _generatedNumbers.isEmpty
                  ? const Center(
                      child: Text(
                        'Clique no botão abaixo para gerar números da Mega Sena',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _quantityOfGames,                      itemBuilder: (context, gameIndex) {
                        // Get the numbers for this game
                        List<int> gameNumbers = _generatedNumbers.sublist(
                            gameIndex * _numbersPerGame, (gameIndex + 1) * _numbersPerGame);
                        
                        return AnimatedBuilder(
                          animation: _animationController, 
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _animationController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.5, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (gameIndex / _quantityOfGames),
                                    ((gameIndex + 1) / _quantityOfGames),
                                    curve: Curves.easeOut,
                                  ),
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Jogo ${gameIndex + 1}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${_numbersPerGame} números',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {
                                          Share.share(
                                            'Meus números da Mega Sena - Jogo ${gameIndex + 1}: ${gameNumbers.join(' - ')}',
                                          );
                                        },
                                        tooltip: 'Compartilhar',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: gameNumbers.map((number) {
                                      return Container(
                                        width: 35,
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            number.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.casino : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            tooltip: _showHistory ? 'Ver Gerador' : 'Ver Histórico',
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation, 
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _showHistory ? _buildHistoryView() : _buildGeneratorView(),
      ),
      floatingActionButton: _showHistory
          ? null
          : FloatingActionButton.extended(
              onPressed: _generateNumbers,
              label: const Text('Gerar'),
              icon: const Icon(Icons.casino),
              tooltip: 'Gerar Números',
            ),
    );
  }
}
