import 'package:flutter/material.dart';
import '../services/strategy_analytics_service.dart';
import '../services/mega_sena_generator_service.dart';
import 'strategy_detail_screen.dart';

class StrategyAnalyticsScreen extends StatefulWidget {
  const StrategyAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _StrategyAnalyticsScreenState createState() => _StrategyAnalyticsScreenState();
}

class _StrategyAnalyticsScreenState extends State<StrategyAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statsData = {};
  String? _bestStrategy;
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }
  
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await StrategyAnalyticsService.getAllStats();
      final bestStrategy = await StrategyAnalyticsService.getMostSuccessfulStrategy();
      
      final Map<String, dynamic> processedStats = {};
      
      // Process stats for display
      stats.forEach((strategy, stat) {
        double matchRate = 0;
        if (stat.gamesGenerated > 0) {
          matchRate = stat.matchedNumbers / stat.gamesGenerated;
        }
        
        processedStats[strategy] = {
          'gamesGenerated': stat.gamesGenerated,
          'matchedNumbers': stat.matchedNumbers,
          'matchRate': matchRate,
        };
      });
      
      setState(() {
        _statsData = processedStats;
        _bestStrategy = bestStrategy;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading strategy analytics: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar os dados de análise. Tente novamente mais tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _resetStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Estatísticas'),
        content: const Text('Tem certeza que deseja apagar todas as estatísticas acumuladas? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resetar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await StrategyAnalyticsService.resetStats();
      await _loadAnalytics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estatísticas resetadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Widget _buildStrategyCard(String strategy, Map<String, dynamic> stats) {
    // Get the display name for the strategy from the service constants
    String displayName = strategy;
    int? strategyKey;
    
    MegaSenaGeneratorService.strategyNames.forEach((key, value) {
      if (value == strategy) {
        strategyKey = key;
      }
    });
    
    final Color cardColor = _bestStrategy == strategy 
        ? Colors.green.shade100 
        : Colors.white;
    
    final double matchRate = stats['matchRate'] * 100; // Convert to percentage
      return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrategyDetailScreen(strategy: strategy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStrategyIcon(strategyKey),
                    color: Colors.green.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_bestStrategy == strategy)
                    const Chip(
                      label: Text('Melhor'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildStatRow('Jogos gerados:', '${stats['gamesGenerated']}'),
              _buildStatRow('Números acertados:', '${stats['matchedNumbers']}'),
              _buildStatRow('Taxa de acerto:', '${matchRate.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Toque para detalhes >>',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getStrategyIcon(int? strategy) {
    if (strategy == null) return Icons.auto_awesome;
    
    switch (strategy) {
      case MegaSenaGeneratorService.STRATEGY_FREQUENCY:
        return Icons.bar_chart;
      case MegaSenaGeneratorService.STRATEGY_OVERDUE:
        return Icons.update;
      case MegaSenaGeneratorService.STRATEGY_PATTERNS:
        return Icons.auto_graph;
      case MegaSenaGeneratorService.STRATEGY_HYBRID:
        return Icons.shuffle;
      case MegaSenaGeneratorService.STRATEGY_RANDOM:
        return Icons.casino;
      default:
        return Icons.auto_awesome;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Estratégias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Atualizar dados',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _resetStats,
            tooltip: 'Resetar estatísticas',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _statsData.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum dado disponível',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gere alguns jogos e depois volte para ver as estatísticas de desempenho das estratégias.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.blue.shade50,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Análise de Desempenho',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Aqui você pode acompanhar o desempenho de cada estratégia ao longo do tempo. '
                                'Quanto mais jogos você gerar e comparar com resultados reais da Mega Sena, mais precisas serão essas estatísticas.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      ..._statsData.entries.map((entry) => _buildStrategyCard(entry.key, entry.value)).toList(),
                    ],
                  ),
      ),
    );
  }
}
