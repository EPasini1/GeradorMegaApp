import 'package:flutter/material.dart';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'models/game_history.dart';
import 'services/game_history_service.dart';
import 'services/mega_sena_api_service.dart';
import 'services/mega_sena_generator_service.dart';
import 'services/strategy_analytics_service.dart';
import 'services/mega_sena_analytics_helper.dart';
import 'screens/results_screen.dart';
import 'screens/strategy_analytics_screen.dart';
import 'screens/strategy_detail_screen.dart';

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
  bool _useHistoricalData = true; // Option to use historical data
  bool _isLoadingHistoricalData = false; // Flag for loading state
  
  // Strategy selection flags
  bool _useFrequencyStrategy = true;
  bool _useOverdueStrategy = true;
  bool _usePatternsStrategy = true;
  bool _useHybridStrategy = true;
  
  GameHistory _gameHistory = GameHistory(games: []);
  late AnimationController _animationController;
  List<GameResult> _latestGames = []; // Store latest generated games for display
  
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
  
  Future<void> _fetchPreviousResults() async {
    setState(() {
      _isLoadingHistoricalData = true;
    });

    try {
      final results = await MegaSenaApiService.getLastResults();
      if (results.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Resultados Oficiais'),
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sorteio: ${result.drawDate}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Números: ${result.numbers.join(', ')}',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum resultado disponível.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error fetching previous results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao buscar resultados anteriores. Verifique sua conexão.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingHistoricalData = false;
      });
    }
  }

  void _generateNumbers() async {
    setState(() {
      _isGenerating = true;
      _generatedNumbers.clear();
      _animationController.reset();
    });

    List<GameResult> newGames = [];
    
    try {
      if (_useHistoricalData) {
        List<int> selectedStrategies = [];
        if (_useFrequencyStrategy) {
          selectedStrategies.add(MegaSenaGeneratorService.STRATEGY_FREQUENCY);
        }
        if (_useOverdueStrategy) {
          selectedStrategies.add(MegaSenaGeneratorService.STRATEGY_OVERDUE);
        }
        if (_usePatternsStrategy) {
          selectedStrategies.add(MegaSenaGeneratorService.STRATEGY_PATTERNS);
        }
        if (_useHybridStrategy) {
          selectedStrategies.add(MegaSenaGeneratorService.STRATEGY_HYBRID);
        }
        
        newGames = await MegaSenaGeneratorService.generateIntelligentNumbers(
          quantityOfGames: _quantityOfGames,
          numbersPerGame: _numbersPerGame,
          useHistoricalData: true,
          selectedStrategies: selectedStrategies.isEmpty ? null : selectedStrategies,
        );
      } else {
        final random = Random();
        
        for (var gameIndex = 0; gameIndex < _quantityOfGames; gameIndex++) {
          Set<int> numbers = {};
          
          while (numbers.length < _numbersPerGame) {
            int randomNumber = random.nextInt(60) + 1;
            numbers.add(randomNumber);
          }
          
          List<int> sortedNumbers = numbers.toList()..sort();
          
          final gameResult = GameResult(
            numbers: sortedNumbers,
            dateGenerated: DateTime.now(),
            numbersPerGame: _numbersPerGame,
            generationStrategy: 'Aleatório',
          );
          newGames.add(gameResult);
        }
      }
      
      _generatedNumbers.clear();
      for (var game in newGames) {
        _generatedNumbers.addAll(game.numbers);
      }
      setState(() {
        _latestGames = newGames;
      });
      
      for (var game in newGames) {
        await GameHistoryService.saveGameResult(game);
        
        if (game.generationStrategy != null) {
          await StrategyAnalyticsService.recordGameGenerated(game.generationStrategy!);
          
          await MegaSenaAnalyticsHelper.compareWithActualResults(
            gameResult: game,
            historyResultsToCheck: 5,
          );
        }
      }
      
      await _loadGameHistory();
      
    } catch (e) {
      print('Error generating numbers: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao gerar números. Tente novamente mais tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _animationController.forward();
      });
    }
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
  
  void _showStrategyDetails(BuildContext context, String? strategy) {
    if (strategy == null) return;
    
    String description = '';
    
    switch (strategy) {
      case 'Baseado em frequência':
        description = 'Esta estratégia seleciona números com base na frequência com que eles apareceram nos últimos 30 sorteios. '
                     'Números que aparecem mais frequentemente têm maior chance de serem escolhidos.';
        break;
      case 'Incluindo números atrasados':
        description = 'Esta estratégia busca números que apareceram bastante no passado, mas que não têm sido sorteados recentemente. '
                     'A ideia é que estes números "atrasados" possuem maior probabilidade de serem sorteados em breve.';
        break;
      case 'Padrões de jogos recentes':
        description = 'Esta estratégia analisa padrões dos jogos mais recentes e seleciona alguns números desses jogos, '
                     'baseando-se na ideia de que certos padrões tendem a se repetir ao longo do tempo.';
        break;
      case 'Abordagem híbrida':
        description = 'Uma combinação de múltiplas estratégias: 40% dos números são escolhidos com base na frequência, '
                     '30% são números "atrasados" e 30% são completamente aleatórios, criando um equilíbrio entre padrões históricos e aleatoriedade.';
        break;
      case 'Aleatório':
        description = 'Números selecionados completamente ao acaso, sem considerar dados históricos ou padrões anteriores.';
        break;
      default:
        description = 'Estratégia personalizada para geração de números.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estratégia: $strategy'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  void _showAllStrategiesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Estratégias de Geração'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrategyInfoSection(
                'Baseado em frequência',
                'Esta estratégia seleciona números com base na frequência com que eles apareceram nos últimos 30 sorteios. '
                'Números que aparecem mais frequentemente têm maior chance de serem escolhidos.',
                Icons.bar_chart,
              ),
              const Divider(),
              _buildStrategyInfoSection(
                'Números atrasados',
                'Esta estratégia busca números que apareceram bastante no passado, mas que não têm sido sorteados recentemente. '
                'A ideia é que estes números "atrasados" possuem maior probabilidade de serem sorteados em breve.',
                Icons.update,
              ),
              const Divider(),
              _buildStrategyInfoSection(
                'Padrões de jogos recentes',
                'Esta estratégia analisa padrões dos jogos mais recentes e seleciona alguns números desses jogos, '
                'baseando-se na ideia de que certos padrões tendem a se repetir ao longo do tempo.',
                Icons.auto_graph,
              ),
              const Divider(),
              _buildStrategyInfoSection(
                'Abordagem híbrida',
                'Uma combinação de múltiplas estratégias: 40% dos números são escolhidos com base na frequência, '
                '30% são números "atrasados" e 30% são completamente aleatórios, criando um equilíbrio entre padrões históricos e aleatoriedade.',
                Icons.shuffle,
              ),
              const Divider(),
              _buildStrategyInfoSection(
                'Aleatório',
                'Números selecionados completamente ao acaso, sem considerar dados históricos ou padrões anteriores.',
                Icons.casino,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStrategyInfoSection(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
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
                              children: [
                                Column(
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
                            
                            if (game.generationStrategy != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, 
                                         size: 16, 
                                         color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showStrategyDetails(context, game.generationStrategy),
                                      child: Text(
                                        'Estratégia: ${game.generationStrategy}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[700],
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            Wrap(
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
    Widget _buildGeneratorView() {
    // Mostra a tela de histórico se _showHistory for true, caso contrário, mostra o gerador
    return _showHistory ? _buildHistoryView() : Column(
      children: [
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
                    items: List.generate(10, (index) => index + 6)
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
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Usar dados históricos:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _useHistoricalData,
                        onChanged: (value) {
                          setState(() {
                            _useHistoricalData = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (!_useHistoricalData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, 
                                   color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Geração aleatória selecionada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Com os dados históricos desativados, os números serão gerados completamente ao acaso, sem considerar os resultados anteriores da Mega Sena.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_useHistoricalData) 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingHistoricalData ? null : _fetchPreviousResults,
                          icon: _isLoadingHistoricalData 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2)
                              ) 
                            : const Icon(Icons.update),
                          label: Text(_isLoadingHistoricalData 
                            ? 'Carregando...' 
                            : 'Atualizar dados dos últimos 30 sorteios'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        Expanded(
          child: _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : _latestGames.isEmpty
                  ? const Center(
                      child: Text(
                        'Clique no botão abaixo para gerar números da Mega Sena',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _latestGames.length + 1,
                      itemBuilder: (context, gameIndex) {
                        if (gameIndex == _latestGames.length) {
                          return const SizedBox(height: 60);
                        }

                        final game = _latestGames[gameIndex];
                        
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
                                    (gameIndex / _latestGames.length),
                                    ((gameIndex + 1) / _latestGames.length),
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
                                    children: [
                                      Column(
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
                                            '${game.numbers.length} números',
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
                                            'Meus números da Mega Sena - Jogo ${gameIndex + 1}: ${game.numbers.join(' - ')}',
                                          );
                                        },
                                        tooltip: 'Compartilhar',
                                      ),
                                    ],
                                  ),
                                  
                                  if (game.generationStrategy != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline, 
                                               size: 16, 
                                               color: Colors.amber.shade700),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => _showStrategyDetails(context, game.generationStrategy),
                                            child: Text(
                                              'Estratégia: ${game.generationStrategy}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[700],
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 12),
                                  Wrap(
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
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStrategyAnalysisInfo() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Estratégias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore as estratégias utilizadas para gerar números da Mega Sena. '
              'Cada estratégia é baseada em dados históricos e padrões de sorteios anteriores.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAllStrategiesInfo(context),
              child: const Text('Ver Detalhes das Estratégias'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Baseado em frequência'),
                    subtitle: const Text('Usa números que aparecem mais frequentemente'),
                    secondary: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                    value: _useFrequencyStrategy,
                    onChanged: (value) {
                      setState(() {
                        _useFrequencyStrategy = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  CheckboxListTile(
                    title: const Text('Números atrasados'),
                    subtitle: const Text('Usa números que não foram sorteados recentemente'),
                    secondary: Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
                    value: _useOverdueStrategy,
                    onChanged: (value) {
                      setState(() {
                        _useOverdueStrategy = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  CheckboxListTile(
                    title: const Text('Padrões de jogos recentes'),
                    subtitle: const Text('Analisa padrões dos jogos mais recentes'),
                    secondary: Icon(Icons.auto_graph, color: Theme.of(context).colorScheme.primary),
                    value: _usePatternsStrategy,
                    onChanged: (value) {
                      setState(() {
                        _usePatternsStrategy = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  CheckboxListTile(
                    title: const Text('Abordagem híbrida'),
                    subtitle: const Text('Combina múltiplas estratégias'),
                    secondary: Icon(Icons.shuffle, color: Theme.of(context).colorScheme.primary),
                    value: _useHybridStrategy,
                    onChanged: (value) {
                      setState(() {
                        _useHybridStrategy = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          _buildStrategyAnalysisInfo(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Análise de Estratégias',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StrategyAnalyticsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Ver Histórico',
              onPressed: () {
                setState(() {
                  _showHistory = !_showHistory;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.update),
              tooltip: 'Ver Resultados Oficiais',
              onPressed: _fetchPreviousResults,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Gerador'),
              Tab(text: 'Configurações'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneratorView(),
            _buildConfigurationView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isGenerating ? null : _generateNumbers,
          label: _isGenerating ? const Text('Gerando...') : const Text('Gerar Jogos'),
          icon: _isGenerating
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : const Icon(Icons.casino),
        ),
      ),
    );
  }
}
