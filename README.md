# Gerador Mega Sena

Um aplicativo Flutter para gerar números para jogos da Mega Sena.

## Funcionalidades

- Geração de números aleatórios para jogos da Mega Sena (6 números entre 1 e 60)
- Opção para gerar múltiplos jogos de uma vez (até 10 jogos)
- Histórico de jogos gerados com data e hora
- Compartilhamento dos números gerados
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

- `lib/main.dart` - Ponto de entrada principal do aplicativo
- `lib/models/game_history.dart` - Modelo para armazenar o histórico de jogos
- `lib/services/game_history_service.dart` - Serviço para persistência dos dados

## Como Funciona

O gerador utiliza o algoritmo de números aleatórios do Dart para gerar 6 números únicos entre 1 e 60 para cada jogo da Mega Sena. Os números são então ordenados em ordem crescente e exibidos na interface.

O aplicativo possui duas telas principais:
1. **Gerador** - Onde você pode gerar novos jogos
2. **Histórico** - Onde você pode visualizar todos os jogos já gerados

## Screenshots

(Screenshots serão adicionados futuramente)

## Licença

Este projeto é distribuído sob a licença MIT.
