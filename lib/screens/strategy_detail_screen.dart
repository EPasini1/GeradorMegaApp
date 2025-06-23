import 'package:flutter/material.dart';
import '../services/strategy_analytics_service.dart';
import '../services/mega_sena_generator_service.dart';

class StrategyDetailScreen extends StatefulWidget {
  final String strategy;
  
  const StrategyDetailScreen({Key? key, required this.strategy}) : super(key: key);

  @override
  _StrategyDetailScreenState createState() => _StrategyDetailScreenState();
}

class _StrategyDetailScreenState extends State<StrategyDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _strategyDetails = {};
  
  @override
  void initState() {
    super.initState();
    _loadStrategyDetails();
  }
  
  Future<void> _loadStrategyDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await StrategyAnalyticsService.getAllStats();
      
      if (stats.containsKey(widget.strategy)) {
        final stat = stats[widget.strategy]!;
        
        double matchRate = 0;
        if (stat.gamesGenerated > 0) {
          matchRate = stat.matchedNumbers / stat.gamesGenerated;
        }
        
        setState(() {
          _strategyDetails = {
            'gamesGenerated': stat.gamesGenerated,
            'matchedNumbers': stat.matchedNumbers,
            'matchRate': matchRate,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _strategyDetails = {
            'gamesGenerated': 0,
            'matchedNumbers': 0,
            'matchRate': 0.0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading strategy details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildStrategyDescription() {
    String description = '';
    IconData icon = Icons.auto_awesome;
    
    // Get strategy description
    switch (widget.strategy) {
      case 'Baseado em frequência':
        description = 'Esta estratégia seleciona números com base na frequência com que eles apareceram nos últimos 30 sorteios. '
                     'Números que aparecem mais frequentemente têm maior chance de serem escolhidos.\n\n'
                     'A ideia por trás desta estratégia é que certos números tendem a aparecer mais frequentemente do que outros ao longo do tempo.';
        icon = Icons.bar_chart;
        break;
      case 'Incluindo números atrasados':
        description = 'Esta estratégia busca números que apareceram bastante no passado, mas que não têm sido sorteados recentemente. '
                     'A ideia é que estes números "atrasados" possuem maior probabilidade de serem sorteados em breve.\n\n'
                     'A estratégia calcula uma pontuação para cada número baseada na frequência histórica e no tempo desde a última aparição.';
        icon = Icons.update;
        break;
      case 'Padrões de jogos recentes':
        description = 'Esta estratégia analisa padrões dos jogos mais recentes e seleciona alguns números desses jogos, '
                     'baseando-se na ideia de que certos padrões tendem a se repetir ao longo do tempo.\n\n'
                     'O algoritmo seleciona aleatoriamente 2-3 jogos recentes e escolhe alguns números desses jogos para incluir no novo jogo gerado.';
        icon = Icons.auto_graph;
        break;
      case 'Abordagem híbrida':
        description = 'Uma combinação de múltiplas estratégias: 40% dos números são escolhidos com base na frequência, '
                     '30% são números "atrasados" e 30% são completamente aleatórios, criando um equilíbrio entre padrões históricos e aleatoriedade.\n\n'
                     'Esta é uma das estratégias mais sofisticadas, pois combina múltiplas abordagens para aumentar as chances de acerto.';
        icon = Icons.shuffle;
        break;
      case 'Aleatório':
        description = 'Números selecionados completamente ao acaso, sem considerar dados históricos ou padrões anteriores.\n\n'
                     'Esta é a estratégia mais simples e é equivalente à forma como muitas pessoas jogam na Mega Sena, simplesmente escolhendo números aleatoriamente.';
        icon = Icons.casino;
        break;
      default:
        description = 'Estratégia personalizada para geração de números.';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.green.shade700, size: 36),
          title: Text(
            widget.strategy,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Estratégia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildStrategyDescription(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Performance Estatística',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPerformanceItem(
                            'Jogos gerados',
                            '${_strategyDetails['gamesGenerated']}',
                            Icons.casino_outlined,
                          ),
                          const Divider(),
                          _buildPerformanceItem(
                            'Números acertados',
                            '${_strategyDetails['matchedNumbers']}',
                            Icons.check_circle_outline,
                          ),
                          const Divider(),
                          _buildPerformanceItem(
                            'Taxa de acerto',
                            '${(_strategyDetails['matchRate'] * 100).toStringAsFixed(1)}%',
                            Icons.percent_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lembre-se: A Mega Sena é um jogo de sorte! Estas estatísticas servem apenas para referência e não garantem resultados futuros.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildPerformanceItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
