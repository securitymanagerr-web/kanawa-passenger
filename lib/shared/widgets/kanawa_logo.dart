// KANAWA - Logotipo reutilizável

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kanawa_colors.dart';

class KanawaLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showSubtitle;

  const KanawaLogo({
    super.key,
    this.size = 64,
    this.showWordmark = true,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin vermelho com carro dentro
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: KanawaColors.brand,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: KanawaColors.brand.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),

        if (showWordmark) ...[
          const SizedBox(height: 16),
          Text(
            'KANAWA',
            style: GoogleFonts.inter(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: KanawaColors.textStrong,
            ),
          ),
        ],

        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Plataforma de Transporte',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: KanawaColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}