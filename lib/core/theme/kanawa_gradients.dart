// KANAWA - Gradientes oficiais

import 'package:flutter/material.dart';

import 'kanawa_colors.dart';

class KanawaGradients {
  KanawaGradients._();

  // Gradiente do topo dos cards principais (fino, 3px)
  static const LinearGradient topAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      KanawaColors.brand,
      KanawaColors.brand,
      KanawaColors.info,
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // Gradiente do botão principal
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      KanawaColors.brand,
      KanawaColors.brandHover,
    ],
  );

  // Gradiente para ecrãs de auth (splash, login)
  static LinearGradient authBackground(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFEF2F2),   // topo: vermelho muito claro
        Color(0xFFF5F5F7),   // base: cinza claro
      ],
    );
  }
}