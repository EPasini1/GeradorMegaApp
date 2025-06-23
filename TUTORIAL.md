# Tutorial do Gerador Mega Sena com Estratégias Inteligentes

Este documento contém instruções para usar e continuar o desenvolvimento do Gerador Mega Sena com estratégias inteligentes.

## Índice
1. [Requisitos Técnicos](#requisitos-técnicos)
2. [Utilizando as Estratégias Inteligentes](#utilizando-as-estratégias-inteligentes)
3. [Análise de Desempenho das Estratégias](#análise-de-desempenho-das-estratégias)
4. [Atualizando Resultados e Estatísticas](#atualizando-resultados-e-estatísticas)
5. [Desenvolvimento Avançado](#desenvolvimento-avançado)

## Requisitos Técnicos

- Flutter 3.32.0 ou superior
- Dart 3.8.0 ou superior

### Dependências do Projeto

Este projeto utiliza as seguintes dependências:
- `shared_preferences` - Para salvar o histórico de jogos e estatísticas de desempenho
- `share_plus` - Para compartilhar os jogos gerados
- `animations` - Para animações de transição
- `intl` - Para formatação de data e hora
- `http` - Para requisições à API de resultados da Mega Sena

## Rodando a Aplicação

Para iniciar o aplicativo, você pode:

1. Usar o comando Flutter diretamente:
   ```
   flutter run
   ```

2. Ou usar o script batch:
   ```
   run_mega_sena.bat
   ```

## Utilizando as Estratégias Inteligentes

### Primeiros Passos
1. Ao abrir o aplicativo pela primeira vez, clique em "Buscar Resultados Recentes" para carregar os dados históricos da Mega Sena
2. Aguarde a confirmação de que os dados foram carregados com sucesso
3. Agora você está pronto para usar as estratégias inteligentes!

### Gerando Jogos com Estratégias
1. Escolha a quantidade de jogos que deseja gerar (1-10)
2. Na seção "Estratégias Inteligentes", selecione as estratégias que deseja utilizar:
   - **Baseado em frequência**: Favorece números que aparecem mais frequentemente
   - **Números atrasados**: Inclui números frequentes que não aparecem há algum tempo
   - **Padrões de jogos recentes**: Analisa padrões de sorteios recentes
   - **Abordagem híbrida**: Combina as diferentes estratégias

3. Clique em "Gerar Números"
4. Os jogos gerados aparecerão em cards, mostrando os números e a estratégia utilizada
5. Você pode clicar no nome da estratégia para ver uma explicação detalhada

## Análise de Desempenho das Estratégias

O aplicativo agora inclui uma poderosa ferramenta de análise de desempenho:

1. Clique no ícone de análise (gráfico) na barra superior
2. Na tela de análise, você verá estatísticas para cada estratégia:
   - **Jogos gerados**: Quantos jogos foram gerados com esta estratégia
   - **Números acertados**: Quantidade de números que coincidiram com sorteios reais
   - **Taxa de acerto**: Percentual de eficácia da estratégia

3. A estratégia com melhor desempenho será destacada
4. Clique em qualquer estratégia para ver detalhes mais aprofundados

## Atualizando Resultados e Estatísticas

Para manter suas estatísticas atualizadas:

1. Periodicamente, volte à tela principal e clique em "Buscar Resultados Recentes"
2. O aplicativo automaticamente:
   - Baixa os últimos resultados oficiais da Mega Sena
   - Compara seus jogos gerados com os resultados reais
   - Atualiza as estatísticas de desempenho das estratégias

## Desenvolvimento Avançado

### Estrutura do Aplicativo

O aplicativo possui as seguintes telas:

1. **Tela Principal (Gerador)**
   - Seletor de quantidade de jogos (1-10)
   - Seleção de estratégias inteligentes
   - Botão para gerar números
   - Exibição dos jogos gerados em cards
   - Botão de compartilhamento para cada jogo

2. **Tela de Histórico**
   - Lista de todos os jogos gerados anteriormente
   - Data, hora e estratégia de cada jogo
   - Botão para limpar o histórico

3. **Tela de Resultados Oficiais**
   - Exibe os resultados recentes da Mega Sena
   - Obtidos via API oficial da Caixa

4. **Tela de Análise de Estratégias**
   - Exibe estatísticas de desempenho de cada estratégia
   - Permite visualização detalhada por estratégia

5. **Tela de Detalhes de Estratégia**
   - Informações detalhadas sobre cada estratégia
   - Estatísticas de desempenho específicas

### Implementação de Novas Estratégias

Para desenvolvedores que desejam implementar novas estratégias:

1. Adicione uma nova constante em `MegaSenaGeneratorService`
2. Implemente a lógica da nova estratégia como um método privado
3. Atualize o switch no método `generateIntelligentNumbers`
4. Adicione a descrição da estratégia no mapa `strategyNames`
5. Atualize as UIs para incluir a nova estratégia
- Animações ao gerar novos jogos
- Compartilhamento de números via plataformas nativas
- Interface amigável com tema personalizável

## Próximas Melhorias Possíveis

1. Adicionar verificação para conferir resultados com jogos anteriores da Mega Sena
2. Implementar estatísticas de números mais/menos sorteados
3. Permitir salvar jogos favoritos
4. Adicionar notificações para os sorteios da Mega Sena
5. Implementar a possibilidade de escolher números manualmente

## Solução de Problemas

Se encontrar problemas ao executar o aplicativo no modo web, tente os seguintes passos:

1. Limpe o projeto:
   ```
   flutter clean
   ```

2. Instale as dependências novamente:
   ```
   flutter pub get
   ```

3. Execute o aplicativo em um dispositivo específico:
   ```
   flutter run -d [device-id]
   ```

Para ver a lista de dispositivos disponíveis:
```
flutter devices
```
