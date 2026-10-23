// KANAWA - Formatação de telefone angolano

import 'package:flutter/services.dart';

class AngolaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limita a 9 dígitos (formato angolano)
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;

    // Formata: 923 456 789
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 2 || i == 5) {
        if (i != limited.length - 1) buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Converte "923 456 789" para "+244923456789"
String normalizeAngolaPhone(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  return '+244$digits';
}