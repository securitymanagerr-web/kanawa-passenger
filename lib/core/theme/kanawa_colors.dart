// KANAWA - Paleta de cores oficial
// Extraída do logotipo + princípios de teoria da cor
// Última atualização: 2026

import 'package:flutter/material.dart';

class KanawaColors {
  KanawaColors._(); // Construtor privado (só métodos estáticos)

  // ═══════════════════════════════════════════════════════
  // MARCA (do logotipo)
  // ═══════════════════════════════════════════════════════
  static const Color brand = Color(0xFFDC2626);        // Vermelho KANAWA
  static const Color brandHover = Color(0xFFB91C1C);   // Vermelho escuro (hover/pressed)
  static const Color brandSoft = Color(0xFFFEF2F2);    // Vermelho muito claro (backgrounds)

  // ═══════════════════════════════════════════════════════
  // FUNDO
  // ═══════════════════════════════════════════════════════
  static const Color bgApp = Color(0xFFF5F5F7);        // Fundo geral
  static const Color bgCard = Color(0xFFFFFFFF);       // Cards
  static const Color bgMuted = Color(0xFFF4F4F5);      // Zonas neutras
  static const Color bgHover = Color(0xFFF8F8F9);      // Hover subtil

  // ═══════════════════════════════════════════════════════
  // TEXTO
  // ═══════════════════════════════════════════════════════
  static const Color textStrong = Color(0xFF18181B);   // Títulos
  static const Color textBase = Color(0xFF3F3F46);     // Corpo
  static const Color textMuted = Color(0xFF71717A);    // Secundário
  static const Color textSubtle = Color(0xFFA1A1AA);   // Labels
  static const Color textDisabled = Color(0xFFD4D4D8); // Desativado

  // ═══════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  // ═══════════════════════════════════════════════════════
  // BORDAS
  // ═══════════════════════════════════════════════════════
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderStrong = Color(0xFFD4D4D8);
}