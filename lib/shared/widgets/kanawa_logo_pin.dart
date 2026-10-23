// KANAWA - Logotipo oficial
// Pin 3D vermelho com carro branco (vista frontal)
// Desenhado inteiramente em CustomPainter

import 'package:flutter/material.dart';

class KanawaLogoPin extends StatelessWidget {
  final double size;
  final bool showShadow;

  const KanawaLogoPin({
    super.key,
    this.size = 120,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _KanawaLogoPinPainter(showShadow: showShadow),
      ),
    );
  }
}

class _KanawaLogoPinPainter extends CustomPainter {
  final bool showShadow;

  _KanawaLogoPinPainter({required this.showShadow});

  // ─── Cores do logotipo ───
  static const Color _redBright = Color(0xFFFF2E2E);   // Vermelho claro (topo)
  static const Color _redMain = Color(0xFFE01818);     // Vermelho principal
  static const Color _redDark = Color(0xFF8B0A0A);     // Vermelho escuro (base)
  static const Color _redDeep = Color(0xFF5A0505);     // Vermelho muito escuro
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _darkInner = Color(0xFF0D0D0D);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final pinWidth = size.width;
    final pinHeight = size.height * 0.92;
    final pinTop = size.height * 0.02;

    // ═══════════════════════════════════════════════════════
    // 0. SOMBRA base (em baixo do pin)
    // ═══════════════════════════════════════════════════════
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = _redMain.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      final shadowRect = Rect.fromCenter(
        center: Offset(centerX, pinTop + pinHeight - 8),
        width: pinWidth * 0.5,
        height: pinWidth * 0.12,
      );
      canvas.drawOval(shadowRect, shadowPaint);
    }

    // ═══════════════════════════════════════════════════════
    // 1. PIN (teardrop shape) com gradiente 3D
    // ═══════════════════════════════════════════════════════
    final pinPath = _buildPinPath(
      centerX: centerX,
      top: pinTop,
      width: pinWidth,
      height: pinHeight,
    );

    // Gradiente vertical: claro em cima, escuro em baixo
    final pinGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _redBright,
        _redMain,
        _redDark,
        _redDeep,
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    final pinPaint = Paint()
      ..shader = pinGradient.createShader(
        Rect.fromLTWH(0, pinTop, pinWidth, pinHeight),
      )
      ..isAntiAlias = true;

    canvas.drawPath(pinPath, pinPaint);

    // ═══════════════════════════════════════════════════════
    // 2. HIGHLIGHT lateral esquerdo (efeito glossy 3D)
    // ═══════════════════════════════════════════════════════
    final highlightPath = _buildPinHighlightPath(
      centerX: centerX,
      top: pinTop,
      width: pinWidth,
      height: pinHeight,
    );

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, pinTop, pinWidth * 0.5, pinHeight),
      )
      ..isAntiAlias = true;

    canvas.drawPath(highlightPath, highlightPaint);

    // ═══════════════════════════════════════════════════════
    // 3. CÍRCULO ESCURO INTERIOR (fundo do carro)
    // ═══════════════════════════════════════════════════════
    final circleRadius = pinWidth * 0.335;
    final circleCenter = Offset(
      centerX,
      pinTop + pinWidth * 0.42,
    );

    // Sombra interior (dá profundidade)
    canvas.drawCircle(
      circleCenter,
      circleRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _darkInner,
            _dark,
          ],
        ).createShader(
          Rect.fromCircle(center: circleCenter, radius: circleRadius),
        ),
    );

    // ═══════════════════════════════════════════════════════
    // 4. ANEL BRANCO (borda do círculo interior)
    // ═══════════════════════════════════════════════════════
    final ringPaint = Paint()
      ..color = _white
      ..style = PaintingStyle.stroke
      ..strokeWidth = pinWidth * 0.035
      ..isAntiAlias = true;

    canvas.drawCircle(
      circleCenter,
      circleRadius - pinWidth * 0.0175,
      ringPaint,
    );

    // ═══════════════════════════════════════════════════════
    // 5. CARRO BRANCO (vista frontal) dentro do círculo
    // ═══════════════════════════════════════════════════════
    _drawCarFrontView(canvas, circleCenter, circleRadius * 0.75);
  }

  // ═══════════════════════════════════════════════════════
  // CONSTRUÇÃO DO PATH DO PIN (teardrop)
  // ═══════════════════════════════════════════════════════
  Path _buildPinPath({
    required double centerX,
    required double top,
    required double width,
    required double height,
  }) {
    final path = Path();

    final circleRadius = width * 0.42;
    final circleCenterY = top + circleRadius;

    // Ponta inferior do pin
    final tipY = top + height;

    // Círculo superior
    path.moveTo(centerX, tipY);

    // Lado esquerdo (curva suave do topo até à ponta)
    path.cubicTo(
      centerX - width * 0.42,
      top + height * 0.72,
      centerX - width * 0.50,
      circleCenterY + circleRadius * 0.2,
      centerX - circleRadius,
      circleCenterY,
    );

    // Arco superior (metade esquerda do círculo)
    path.arcToPoint(
      Offset(centerX + circleRadius, circleCenterY),
      radius: Radius.circular(circleRadius),
      clockwise: true,
    );

    // Lado direito (curva do topo até à ponta)
    path.cubicTo(
      centerX + width * 0.50,
      circleCenterY + circleRadius * 0.2,
      centerX + width * 0.42,
      top + height * 0.72,
      centerX,
      tipY,
    );

    path.close();
    return path;
  }

  // ═══════════════════════════════════════════════════════
  // HIGHLIGHT GLOSSY (brilho lateral esquerdo)
  // ═══════════════════════════════════════════════════════
  Path _buildPinHighlightPath({
    required double centerX,
    required double top,
    required double width,
    required double height,
  }) {
    final path = Path();
    final circleRadius = width * 0.42;
    final circleCenterY = top + circleRadius;

    path.moveTo(centerX - circleRadius * 0.7, circleCenterY - circleRadius * 0.6);

    path.cubicTo(
      centerX - circleRadius * 1.05,
      circleCenterY,
      centerX - width * 0.42,
      top + height * 0.72,
      centerX - width * 0.15,
      top + height * 0.85,
    );

    path.cubicTo(
      centerX - width * 0.20,
      top + height * 0.70,
      centerX - circleRadius * 0.85,
      circleCenterY + circleRadius * 0.3,
      centerX - circleRadius * 0.65,
      circleCenterY + circleRadius * 0.1,
    );

    path.close();
    return path;
  }

  // ═══════════════════════════════════════════════════════
  // CARRO FRONTAL (silhueta branca)
  // ═══════════════════════════════════════════════════════
  void _drawCarFrontView(Canvas canvas, Offset center, double radius) {
    final carPaint = Paint()
      ..color = _white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = radius * 1.85;
    final h = radius * 1.15;

    final cx = center.dx;
    final cy = center.dy + radius * 0.08;

    // ─── 1. TETO (pequeno trapézio em cima) ───
    final roofPath = Path()
      ..moveTo(cx - w * 0.28, cy - h * 0.48)
      ..lineTo(cx - w * 0.18, cy - h * 0.62)
      ..lineTo(cx + w * 0.18, cy - h * 0.62)
      ..lineTo(cx + w * 0.28, cy - h * 0.48)
      ..close();
    canvas.drawPath(roofPath, carPaint);

    // ─── 2. PARA-BRISAS (trapézio maior) ───
    final windshieldPath = Path()
      ..moveTo(cx - w * 0.32, cy - h * 0.30)
      ..lineTo(cx - w * 0.28, cy - h * 0.48)
      ..lineTo(cx + w * 0.28, cy - h * 0.48)
      ..lineTo(cx + w * 0.32, cy - h * 0.30)
      ..close();
    canvas.drawPath(windshieldPath, carPaint);

    // ─── 3. ESPELHOS LATERAIS ───
    final mirrorPaint = Paint()
      ..color = _white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Espelho esquerdo
    final mirrorLeft = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - w * 0.48, cy - h * 0.28),
        width: w * 0.14,
        height: h * 0.14,
      ),
      Radius.circular(h * 0.05),
    );
    canvas.drawRRect(mirrorLeft, mirrorPaint);

    // Espelho direito
    final mirrorRight = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + w * 0.48, cy - h * 0.28),
        width: w * 0.14,
        height: h * 0.14,
      ),
      Radius.circular(h * 0.05),
    );
    canvas.drawRRect(mirrorRight, mirrorPaint);

    // ─── 4. CORPO PRINCIPAL DO CARRO ───
    final bodyPath = Path()
      ..moveTo(cx - w * 0.42, cy - h * 0.28)
      ..lineTo(cx - w * 0.50, cy + h * 0.05)
      ..lineTo(cx - w * 0.48, cy + h * 0.38)
      ..lineTo(cx - w * 0.42, cy + h * 0.42)
      ..lineTo(cx - w * 0.30, cy + h * 0.42)
      ..lineTo(cx - w * 0.28, cy + h * 0.32)
      ..lineTo(cx + w * 0.28, cy + h * 0.32)
      ..lineTo(cx + w * 0.30, cy + h * 0.42)
      ..lineTo(cx + w * 0.42, cy + h * 0.42)
      ..lineTo(cx + w * 0.48, cy + h * 0.38)
      ..lineTo(cx + w * 0.50, cy + h * 0.05)
      ..lineTo(cx + w * 0.42, cy - h * 0.28)
      ..close();
    canvas.drawPath(bodyPath, carPaint);

    // ─── 5. GRELHA (retângulo escuro no meio) ───
    final grillePaint = Paint()
      ..color = _darkInner
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final grille = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + h * 0.05),
        width: w * 0.36,
        height: h * 0.12,
      ),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(grille, grillePaint);

    // ─── 6. FARÓIS (2 retângulos aos lados da grelha) ───
    final headlightPaint = Paint()
      ..color = _darkInner
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Farol esquerdo
    final headlightLeft = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - w * 0.36, cy + h * 0.05),
        width: w * 0.14,
        height: h * 0.11,
      ),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(headlightLeft, headlightPaint);

    // Farol direito
    final headlightRight = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + w * 0.36, cy + h * 0.05),
        width: w * 0.14,
        height: h * 0.11,
      ),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(headlightRight, headlightPaint);

    // ─── 7. Detalhes: linhas do capô ───
    final linePaint = Paint()
      ..color = _darkInner.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.015
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Linha central do capô
    canvas.drawLine(
      Offset(cx, cy - h * 0.18),
      Offset(cx, cy - h * 0.08),
      linePaint,
    );

    // Linhas laterais do capô
    canvas.drawLine(
      Offset(cx - w * 0.30, cy - h * 0.20),
      Offset(cx - w * 0.20, cy - h * 0.10),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.30, cy - h * 0.20),
      Offset(cx + w * 0.20, cy - h * 0.10),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KanawaLogoPinPainter oldDelegate) {
    return oldDelegate.showShadow != showShadow;
  }
}