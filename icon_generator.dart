import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

// Script para gerar um ícone para o aplicativo da Mega Sena
void main() async {
  // Configura um tamanho de ícone adequado
  const size = 1024.0;
  
  // Criar o recorder para desenhar
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Configurar a pintura
  final paint = Paint()
    ..color = Colors.green.shade700
    ..style = PaintingStyle.fill;
  
  // Desenhar círculo de fundo
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
  
  // Desenhar bolas da Mega Sena
  drawMegaSenaBalls(canvas, size);
  
  // Finalizar a gravação e converter para imagem
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Salvar a imagem
  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(buffer);
  
  // Criar versão adaptativa (foreground)
  final adaptiveFile = File('assets/icon/app_icon_adaptive.png');
  await adaptiveFile.writeAsBytes(buffer);
  
  print('Ícones gerados com sucesso em assets/icon/');
  exit(0);
}

void drawMegaSenaBalls(Canvas canvas, double size) {
  final whitePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
    
  final textStyle = TextStyle(
    color: Colors.green.shade700,
    fontSize: size / 12,
    fontWeight: FontWeight.bold,
  );
  
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  
  // Desenhar 6 bolas em formato circular
  final center = Offset(size / 2, size / 2);
  final radius = size / 3.2;
  final ballRadius = size / 10;
  
  for (int i = 0; i < 6; i++) {
    final angle = i * (2 * pi / 6);
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    
    canvas.drawCircle(Offset(x, y), ballRadius, whitePaint);
    
    // Adicionar um número em cada bola
    final number = (i + 1).toString();
    textPainter.text = TextSpan(text: number, style: textStyle);
    textPainter.layout();
    
    final textX = x - textPainter.width / 2;
    final textY = y - textPainter.height / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }
}
