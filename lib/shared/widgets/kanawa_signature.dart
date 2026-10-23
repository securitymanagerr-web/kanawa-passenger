// KANAWA - Assinatura do autor
// Aparece em todas as telas de autenticação

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kanawa_colors.dart';

class KanawaSignature extends StatelessWidget {
  const KanawaSignature({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'MBSoft · Benvindo Mersh',
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: KanawaColors.textSubtle,
      ),
    );
  }
}