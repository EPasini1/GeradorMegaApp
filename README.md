# Gerador Mega Sena

Um aplicativo Flutter para gerar números para jogos da Mega Sena usando estratégias inteligentes baseadas em dados históricos.

## Funcionalidades

### Geração de Números Inteligentes

O aplicativo oferece diversas estratégias para gerar números para a Mega Sena:

1. **Baseado em frequência** - Seleciona números com base na frequência com que apareceram em sorteios anteriores
2. **Números atrasados** - Inclui números frequentes que não aparecem há algum tempo
3. **Padrões de jogos recentes** - Analisa padrões de sorteios recentes
4. **Abordagem híbrida** - Combina frequência, números atrasados e aleatoriedade
5. **Aleatório** - Geração completamente aleatória (quando dados históricos não estão disponíveis)

### Análise de Desempenho

O aplicativo inclui uma seção de análise de desempenho das estratégias:

- Acompanhe quais estratégias geram os melhores resultados
- Visualize taxa de acerto para cada estratégia
- Veja detalhes específicos sobre como cada estratégia funciona
- Compare o desempenho entre diferentes abordagens

### Outros Recursos

- Carregue resultados históricos da Mega Sena via API oficial
- Salve seus jogos gerados com informação da estratégia utilizada
- Compartilhamento dos números gerados
- Visualização de resultados oficiais de sorteios recentes
- Animações fluidas e interface amigável

## Requisitos

- Flutter 3.32.0 ou superior
- Dart 3.8.0 ou superior

## Executando o Aplicativo

Para executar o aplicativo, você pode usar o seguinte comando:

```bash
flutter run
```

Ou usar o arquivo batch incluído:

```
run_mega_sena.bat
```

## Estrutura do Projeto

### Arquitetura

- **Services**: Classes responsáveis pela lógica de negócios
  - `lib/services/mega_sena_generator_service.dart` - Implementa as diferentes estratégias de geração
  - `lib/services/mega_sena_api_service.dart` - Comunica-se com a API da Mega Sena
  - `lib/services/game_history_service.dart` - Gerencia o histórico de jogos
  - `lib/services/strategy_analytics_service.dart` - Rastreia o desempenho das estratégias
  - `lib/services/mega_sena_analytics_helper.dart` - Ajuda na comparação com resultados reais

- **Models**: Classes para representação de dados
  - `lib/models/game_history.dart` - Representa jogos gerados e histórico de jogos

- **Screens**: Telas da aplicação
  - `lib/main.dart` - Tela principal (gerador)
  - `lib/screens/results_screen.dart` - Tela de resultados oficiais
  - `lib/screens/strategy_analytics_screen.dart` - Tela de análise de estratégias
  - `lib/screens/strategy_detail_screen.dart` - Tela de detalhes de estratégias

## Como Funciona

### Geração Inteligente de Números

O aplicativo utiliza múltiplas estratégias para gerar números para jogos da Mega Sena:

1. **Estratégia baseada em frequência**: Analisa os últimos 30 resultados e atribui maior peso aos números que aparecem com mais frequência.

2. **Estratégia de números atrasados**: Busca números que historicamente aparecem com frequência mas não têm sido sorteados recentemente.

3. **Estratégia de padrões recentes**: Analisa padrões dos jogos mais recentes e seleciona alguns números desses jogos para incluir no novo jogo.

4. **Estratégia híbrida**: Combina as abordagens anteriores - 40% dos números são baseados na frequência, 30% são números "atrasados" e 30% são completamente aleatórios.

### Análise de Estratégias

O sistema rastreia o desempenho de cada estratégia comparando os números gerados com resultados reais da Mega Sena. Isso permite que o usuário identifique quais estratégias estão gerando os melhores resultados ao longo do tempo.

### Interface do Usuário

O aplicativo possui quatro telas principais:
1. **Gerador** - Onde você pode gerar novos jogos usando estratégias selecionadas
2. **Histórico** - Onde você pode visualizar todos os jogos já gerados
3. **Resultados Oficiais** - Onde você pode consultar resultados oficiais recentes
4. **Análise de Estratégias** - Onde você pode verificar o desempenho das diferentes estratégias

## Screenshots

(Screenshots serão adicionados futuramente)

## Licença

Este projeto é distribuído sob a licença MIT.
