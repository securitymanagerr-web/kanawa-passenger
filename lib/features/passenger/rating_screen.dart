// KANAWA - Avaliar viagem
// v1.3 — Envia avaliação ao backend com authenticated: true

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFD97706);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFF0F0F12);
  static const bgCard = Color(0xFF1A1A1F);
  static const bgInput = Color(0xFF141418);
  static const border = Color(0xFF27272A);
}

class RatingScreen extends StatefulWidget {
  final String? tripId;
  final String driverName;
  final String driverPlate;
  final String destinationName;
  final int priceKz;

  const RatingScreen({
    super.key,
    this.tripId,
    required this.driverName,
    required this.driverPlate,
    required this.destinationName,
    required this.priceKz,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  final List<String> _tags = [
    'Motorista simpático',
    'Carro limpo',
    'Condução segura',
    'Chegou rápido',
    'Boa conversa',
    'Motorista educado',
    'Carro confortável',
    'Pontual',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final tagsText = _selectedTags.join(', ');
    final comment = _commentController.text.trim();
    final fullComment = [
      if (tagsText.isNotEmpty) tagsText,
      if (comment.isNotEmpty) comment,
    ].join(' · ');

    if (widget.tripId == null || widget.tripId!.startsWith('mock-')) {
      debugPrint('⚠️ Sem tripId real — não envia avaliação');
      _showSuccess();
      return;
    }

    try {
      final body = {
        'rating': _rating,
        'comment': fullComment,
      };

      final response = await ApiClient.post(
        '/trips/${widget.tripId}/rate/',
        body: body,
        authenticated: true,
      );

      if (response.success) {
        debugPrint('✅ Avaliação gravada');
      } else {
        debugPrint('⚠️ Falha ao gravar avaliação: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao gravar avaliação: $e');
    }

    if (mounted) _showSuccess();
  }

  void _showSuccess() {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Obrigado pela avaliação! ⭐',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1:
        return 'Muito mau';
      case 2:
        return 'Mau';
      case 3:
        return 'Razoável';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente!';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Como foi a viagem?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A tua opinião ajuda a melhorar o KANAWA',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _C.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _C.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.driverPlate,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.priceKz} Kz',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _C.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          i < _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 44,
                          color: i < _rating ? _C.amber : _C.textSubtle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getRatingLabel(),
                  key: ValueKey(_rating),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _rating >= 4 ? _C.green : _C.amber,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'O que gostaste?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _C.blue.withOpacity(0.15)
                            : _C.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _C.blue : _C.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: _C.blue,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? _C.blue : _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comentário (opcional)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _C.bgInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  enabled: true,
                  autofocus: false,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  minLines: 4,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                  cursorColor: _C.red,
                  cursorWidth: 2.5,
                  cursorRadius: const Radius.circular(2),
                  decoration: InputDecoration(
                    hintText: 'Escreve aqui o teu comentário...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: _C.textSubtle,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'A ENVIAR...' : 'ENVIAR AVALIAÇÃO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Saltar',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}