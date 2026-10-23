// KANAWA - Ecrã de Verificação de Código
// Design: MBSoft · Benvindo Mersh

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';
import '../passenger/home_screen.dart';
import 'login_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String phone;
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.phone,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const int _resendDelaySeconds = 30 * 60;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = _resendDelaySeconds;

  @override
  void initState() {
    super.initState();

    ApiClient.savePendingVerification(
      phone: widget.phone,
      email: widget.email,
    );

    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════════
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendDelaySeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsRemaining = 0);
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════
  // CÓDIGO
  // ═══════════════════════════════════════════════════════
  String get _fullCode => _controllers.map((c) => c.text).join();

  // ✅ FIX: apenas verifica o comprimento
  bool get _isCodeComplete => _fullCode.length == 6;

  void _onDigitChanged(int index, String value) {
    setState(() {});

    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isCodeComplete && !_isLoading) {
        _verifyCode();
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  // VERIFICAR
  // ═══════════════════════════════════════════════════════
  Future<void> _verifyCode() async {
    if (_isLoading) return;

    final code = _fullCode;
    if (code.length != 6) return;

    debugPrint('[VERIFY] verify code=$code');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final response = await ApiClient.post(
        '/auth/verify-email/',
        body: {
          'phone': widget.phone,
          'code': code,
        },
      );

      debugPrint('[VERIFY] response success=${response.success} '
          'status=${response.statusCode}');

      if (!mounted) return;

      if (response.success) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];

        if (access != null && refresh != null) {
          await ApiClient.saveTokens(access: access, refresh: refresh);
        }

        await ApiClient.clearPendingVerification();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final errMsg = response.errorMessage;

        // Caso especial: conta já verificada
        if (errMsg.toLowerCase().contains('já está verificada')) {
          await ApiClient.clearPendingVerification();
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conta já verificada. Entra com a tua password.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }

        setState(() {
          _errorMessage = errMsg;
          _isLoading = false;
        });
        _clearCode();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado. Tenta novamente.';
        _isLoading = false;
      });
      _clearCode();
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {});
    _focusNodes[0].requestFocus();
  }

  // ═══════════════════════════════════════════════════════
  // REENVIAR
  // ═══════════════════════════════════════════════════════
  Future<void> _resendCode() async {
    if (_isResending || _secondsRemaining > 0) return;

    setState(() => _isResending = true);

    try {
      final response = await ApiClient.post(
        '/auth/resend-verification/',
        body: {'phone': widget.phone},
      );

      if (!mounted) return;

      if (response.success) {
        _startTimer();
        _clearCode();
        setState(() => _errorMessage = null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Novo código enviado para ${widget.email}',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = response.errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erro ao reenviar. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  // IR PARA LOGIN
  // ═══════════════════════════════════════════════════════
  Future<void> _goToLogin() async {
    await ApiClient.clearPendingVerification();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                const KanawaLogoPin(size: 72, showShadow: true),

                const SizedBox(height: 20),

                Text(
                  'Verifica o teu email',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18181B),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF71717A),
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Enviámos um código de 6 dígitos para\n'),
                      TextSpan(
                        text: widget.email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return _CodeInputBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      isFilled: _controllers[index].text.isNotEmpty,
                      hasError: _errorMessage != null,
                      onChanged: (value) => _onDigitChanged(index, value),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isCodeComplete && !_isLoading)
                        ? _verifyCode
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE01818),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE4E4E7),
                      disabledForegroundColor: const Color(0xFFA1A1AA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'VERIFICAR',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_rounded, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                if (!_isLoading) ...[
                  Center(
                    child: _secondsRemaining > 0
                        ? Column(
                            children: [
                              Text(
                                'Reenviar código em',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFA1A1AA),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _timerText,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF18181B),
                                  letterSpacing: 2,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: _isResending ? null : _resendCode,
                            child: _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFE01818),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Reenviar código',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE01818),
                                    ),
                                  ),
                          ),
                  ),
                ],

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF71717A),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'O código é verificado automaticamente quando preenches os 6 dígitos. Também podes usar o botão VERIFICAR.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF71717A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Já verifiquei noutro dispositivo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E5FE0),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Cancelar registo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA1A1AA),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Center(child: KanawaSignature()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CAIXA DE DÍGITO
// ═══════════════════════════════════════════════════════
class _CodeInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFilled;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _CodeInputBox({
    required this.controller,
    required this.focusNode,
    required this.isFilled,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFDC2626)
        : isFilled
            ? const Color(0xFFE01818)
            : const Color(0xFFD4D4D8);

    return SizedBox(
      width: 48,
      height: 60,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF18181B),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled ? const Color(0xFFFEF2F2) : Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE01818), width: 2),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}