# Tutorial do Gerador Mega Sena - Flutter

Este documento contém instruções para rodar e continuar o desenvolvimento do Gerador Mega Sena.

## Requisitos

- Flutter 3.32.0 ou superior
- Dart 3.8.0 ou superior

## Dependências do Projeto

Este projeto utiliza as seguintes dependências:
- `shared_preferences` - Para salvar o histórico de jogos
- `share_plus` - Para compartilhar os jogos gerados
- `animations` - Para animações de transição
- `intl` - Para formatação de data e hora

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

## Estrutura do Aplicativo

O aplicativo possui as seguintes telas:

1. **Tela de Geração**
   - Seletor de quantidade de jogos (1-10)
   - Botão para gerar números
   - Exibição dos jogos gerados em cards
   - Botão de compartilhamento para cada jogo

2. **Tela de Histórico**
   - Lista de todos os jogos gerados anteriormente
   - Data e hora de cada jogo
   - Botão para limpar o histórico

## Principais Recursos Implementados

- Geração de números aleatórios exclusivos (6 números entre 1 e 60)
- Persistência de dados para salvar o histórico de jogos
- Animações de transição entre telas
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
